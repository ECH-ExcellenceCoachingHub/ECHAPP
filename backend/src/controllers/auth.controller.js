const User = require('../models/User');
const crypto = require('crypto');
const { generateToken, generateRefreshToken } = require('../utils/jwt.utils');
const { sendSuccess, sendError, sendUnauthorized, sendNotFound } = require('../utils/response.utils');
const { OAuth2Client } = require('google-auth-library');
const admin = require('../config/firebase');
const emailService = require('../services/email.service');
const { canLinkByEmail, sendVerificationIfNeeded, notVerifiedMessage } = require('../utils/firebaseAccountLink');

// Google OAuth is handled by Firebase, so we don't need separate Google OAuth client
// const CLIENT_ID = process.env.GOOGLE_CLIENT_ID;
// const client = new OAuth2Client(CLIENT_ID);

/**
 * Roles a person may choose for themselves. Never 'admin'. A self-chosen
 * teacher starts with an incomplete profile and must be approved by an admin.
 */
const SELF_SERVICE_ROLES = ['student', 'instructor'];
function normalizeSelfRole(role) {
  const r = String(role || '').trim().toLowerCase();
  if (r === 'teacher') return 'instructor';
  return SELF_SERVICE_ROLES.includes(r) ? r : null;
}
function roleFields(role) {
  return role === 'instructor'
    ? { role: 'instructor', teacherStatus: 'profile_incomplete' }
    : { role: 'student' };
}

// Register user
const register = async (req, res) => {
  try {
    const { fullName, email, password, phone } = req.body;
    const chosenRole = normalizeSelfRole(req.body.role) || 'student';

    // Either email or phone is required
    if (!email && !phone) {
      return sendError(res, 'Either email or phone number is required', 400);
    }

    // Check if user already exists by email or phone
    if (email) {
      const emailExists = await User.findOne({ email });
      if (emailExists) {
        return sendError(res, 'User already exists with this email', 400);
      }
    }
    if (phone) {
      const phoneExists = await User.findOne({ phone });
      if (phoneExists) {
        return sendError(res, 'User already exists with this phone number', 400);
      }
    }

    // Create user
    const user = await User.create({
      fullName,
      email,
      password,
      phone,
      ...roleFields(chosenRole)
    });

    if (user) {
      const token = generateToken({ id: user._id });
      const refreshToken = generateRefreshToken({ id: user._id });

      // Send welcome email to the new user
      try {
        await emailService.sendWelcomeEmail(user.email, user);
        console.log(`Welcome email sent to new user: ${user.email}`);
      } catch (emailError) {
        console.error('Error sending welcome email:', emailError);
        // Don't fail the registration if email sending fails
      }

      sendSuccess(res, {
        user: {
          id: user._id,
          fullName: user.fullName,
          email: user.email,
          role: user.role,
          teacherStatus: user.teacherStatus || null,
          needsRoleSelection: !!user.needsRoleSelection,
          phone: user.phone,
          avatar: user.avatar,
          createdAt: user.createdAt.getTime()
        },
        token,
        refreshToken
      }, 'User registered successfully', 201);
    } else {
      sendError(res, 'Invalid user data', 400);
    }
  } catch (error) {
    sendError(res, 'Registration failed', 500, error.message);
  }
};

// Login user
const login = async (req, res) => {
  try {
    const { email, emailOrPhone, password, deviceId } = req.body;
    const identifier = (emailOrPhone || email || '').trim();

    if (!identifier) {
      return sendError(res, 'Email or phone number is required', 400);
    }

    // Find user by email or phone and include password for comparison
    const isEmail = identifier.includes('@');
    const query = isEmail ? { email: identifier.toLowerCase() } : { phone: identifier };
    const user = await User.findOne(query).select('+password');

    if (user && (await user.comparePassword(password))) {
      if (!user.isActive) {
        return sendError(res, 'Account is deactivated', 401);
      }
      
      // Device binding logic - skip for admin and instructor users
      if (deviceId && user.role !== 'admin' && user.role !== 'instructor') {
        if (!user.deviceId) {
          // First login - bind account to device
          user.deviceId = deviceId;
          console.log(`Device bound to user ${user.email}: ${deviceId}`);
        } else if (user.deviceId !== deviceId) {
          // Different device - reject login
          return sendError(res, 'This account is already registered on another device.', 401);
        }
      }

      user.lastActive = new Date();
      await user.save();

      const token = generateToken({ id: user._id });
      const refreshToken = generateRefreshToken({ id: user._id });

      sendSuccess(res, {
        user: {
          id: user._id,
          fullName: user.fullName,
          email: user.email,
          role: user.role,
          teacherStatus: user.teacherStatus || null,
          needsRoleSelection: !!user.needsRoleSelection,
          phone: user.phone,
          avatar: user.avatar,
          hasCompletedOnboarding: user.hasCompletedOnboarding,
          interests: user.interests,
          shortTermGoal: user.shortTermGoal,
          midTermGoal: user.midTermGoal,
          longTermGoal: user.longTermGoal,
          createdAt: user.createdAt.getTime()
        },
        token,
        refreshToken
      }, 'Login successful');
    } else {
      sendUnauthorized(res, 'Invalid email/phone or password');
    }
  } catch (error) {
    sendError(res, 'Login failed', 500, error.message);
  }
};

// Refresh token
const refreshToken = async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return sendUnauthorized(res, 'Refresh token is required');
    }

    // Verify refresh token
    const decoded = require('../utils/jwt.utils').verifyRefreshToken(refreshToken);
    
    // Get user
    const user = await User.findById(decoded.id);
    
    if (!user || !user.isActive) {
      return sendUnauthorized(res, 'Invalid refresh token');
    }

    // Generate new tokens
    const newToken = generateToken({ id: user._id });
    const newRefreshToken = generateRefreshToken({ id: user._id });

    sendSuccess(res, {
      token: newToken,
      refreshToken: newRefreshToken
    }, 'Token refreshed successfully');
  } catch (error) {
    sendUnauthorized(res, 'Invalid refresh token');
  }
};

// Get user profile
const getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) {
      return sendError(res, 'User not found', 404);
    }
    
    sendSuccess(res, {
      id: user._id,
      fullName: user.fullName,
      email: user.email,
      role: user.role,
      teacherStatus: user.teacherStatus || null,
      needsRoleSelection: !!user.needsRoleSelection,
      phone: user.phone,
      avatar: user.avatar,
      createdAt: user.createdAt.getTime()
    }, 'Profile retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve profile', 500, error.message);
  }
};

// Update user profile
const updateProfile = async (req, res) => {
  try {
    const { fullName, email, phone, avatar, interests, shortTermGoal, midTermGoal, longTermGoal, hasCompletedOnboarding } = req.body;
    
    const user = await User.findById(req.user.id);
    if (!user) {
      return sendError(res, 'User not found', 404);
    }

    // Check phone uniqueness if being changed
    if (phone !== undefined && phone !== '' && phone !== user.phone) {
      const phoneExists = await User.findOne({ phone, _id: { $ne: user._id } });
      if (phoneExists) {
        return sendError(res, 'This phone number is already associated with another account', 409);
      }
    }

    // Check email uniqueness if being changed
    if (email !== undefined && email !== '' && email !== user.email) {
      const emailExists = await User.findOne({ email: email.toLowerCase(), _id: { $ne: user._id } });
      if (emailExists) {
        return sendError(res, 'This email address is already associated with another account', 409);
      }
    }
    
    if (fullName) user.fullName = fullName;
    if (email !== undefined && email !== '') user.email = email.toLowerCase();
    if (phone !== undefined) user.phone = phone || undefined;
    if (avatar !== undefined) user.avatar = avatar;
    if (interests !== undefined) user.interests = interests;
    if (shortTermGoal !== undefined) user.shortTermGoal = shortTermGoal;
    if (midTermGoal !== undefined) user.midTermGoal = midTermGoal;
    if (longTermGoal !== undefined) user.longTermGoal = longTermGoal;
    if (hasCompletedOnboarding !== undefined) user.hasCompletedOnboarding = hasCompletedOnboarding;
    
    await user.save();
    
    sendSuccess(res, {
      id: user._id,
      fullName: user.fullName,
      email: user.email,
      role: user.role,
      teacherStatus: user.teacherStatus || null,
      needsRoleSelection: !!user.needsRoleSelection,
      phone: user.phone,
      avatar: user.avatar,
      interests: user.interests,
      shortTermGoal: user.shortTermGoal,
      midTermGoal: user.midTermGoal,
      longTermGoal: user.longTermGoal,
      hasCompletedOnboarding: user.hasCompletedOnboarding,
      createdAt: user.createdAt.getTime()
    }, 'Profile updated successfully');
  } catch (error) {
    sendError(res, 'Failed to update profile', 500, error.message);
  }
};

// Logout user
const logout = async (req, res) => {
  // In a real application, you might want to blacklist the token
  sendSuccess(res, null, 'Logged out successfully');
};

// Called when the app becomes active (cold start, or resume from background) -
// marks the beginning of a new foreground session for "time spent in app" tracking.
const startSession = async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    if (!user) {
      return sendError(res, 'User not found', 404);
    }

    user.sessionCount = (user.sessionCount || 0) + 1;
    user.lastSessionStart = new Date();
    user.lastActive = new Date();
    await user.save();

    sendSuccess(res, { sessionCount: user.sessionCount }, 'Session started');
  } catch (error) {
    console.error('Start Session Error:', error);
    sendError(res, 'Failed to start session', 500, error.message);
  }
};

// Called periodically while the app is in the foreground, and once more when it
// backgrounds, reporting how many seconds of real foreground time elapsed since
// the last heartbeat. The client's own stopwatch is the only reliable source of
// "time spent in app" - it can't be reconstructed from login/logout timestamps
// alone since users rarely explicitly log out.
const recordSessionHeartbeat = async (req, res) => {
  try {
    const seconds = Number(req.body.seconds);
    if (!Number.isFinite(seconds) || seconds <= 0) {
      return sendError(res, 'A positive "seconds" value is required', 400);
    }
    // Clamp a single heartbeat so a stalled or long-backgrounded client can't
    // report a huge backlog as if it were active foreground time.
    const clampedSeconds = Math.min(Math.round(seconds), 300);

    const user = await User.findById(req.user._id);
    if (!user) {
      return sendError(res, 'User not found', 404);
    }

    user.totalSessionTime = (user.totalSessionTime || 0) + clampedSeconds;
    user.lastSessionStart = new Date();
    user.lastActive = new Date();
    await user.save();

    sendSuccess(res, { totalSessionTime: user.totalSessionTime }, 'Session heartbeat recorded');
  } catch (error) {
    console.error('Record Session Heartbeat Error:', error);
    sendError(res, 'Failed to record session heartbeat', 500, error.message);
  }
};

// Google Sign-In - Legacy method, may be deprecated in favor of Firebase auth
const googleSignIn = async (req, res) => {
  try {
    const { idToken } = req.body;
    const chosenRole = normalizeSelfRole(req.body.role);
    
    if (!idToken) {
      return sendError(res, 'ID token is required', 400);
    }
    
    // This would be for traditional Google OAuth flow
    // For Firebase Google auth, use firebaseLogin endpoint instead
    // Verify the ID token with Firebase
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    
    // Check if user already exists in our database
    let user = await User.findOne({ firebaseUid: decodedToken.uid });
    
    if (!user) {
      // Create new user from Google/Firebase auth
      console.log('Creating new user from Google/Firebase:', decodedToken.email);
      user = await User.create({
        firebaseUid: decodedToken.uid,
        email: decodedToken.email,
        fullName: decodedToken.name || 'Google User',
        ...roleFields(chosenRole || 'student'),
        needsRoleSelection: !chosenRole,
        provider: 'google',
        isVerified: decodedToken.email_verified || false,
        isActive: true,
        password: undefined // No password for Google auth users
      });
    }
    
    // Generate tokens
    const token = generateToken({ id: user._id });
    const refreshToken = generateRefreshToken({ id: user._id });
    
    sendSuccess(res, {
      user: {
        id: user._id,
        firebaseUid: user.firebaseUid,
        fullName: user.fullName,
        email: user.email,
        role: user.role,
        teacherStatus: user.teacherStatus || null,
        needsRoleSelection: !!user.needsRoleSelection,
        avatar: user.avatar,
        provider: user.provider,
        createdAt: user.createdAt.getTime()
      },
      token,
      refreshToken
    }, 'Google Sign-In successful', 200);
  } catch (error) {
    console.error('Google Sign-In Error:', error);
    sendError(res, 'Google authentication failed', 500, error.message);
  }
};

// Firebase login/signup - handles both new and existing users
const firebaseLogin = async (req, res) => {
  try {
    const { idToken, fullName, deviceId } = req.body;
    const chosenRole = normalizeSelfRole(req.body.role);
    
    // Debug logging
    console.log('=== Firebase Login Debug ===');
    console.log('Received idToken:', idToken ? 'Present (length: ' + idToken.length + ')' : 'Missing');
    console.log('Received fullName:', fullName || 'Not provided');
    console.log('Received deviceId:', deviceId || 'Not provided');
    // Safely log body without printing the entire token
    const logBody = { ...req.body };
    if (logBody.idToken) logBody.idToken = logBody.idToken.substring(0, 20) + '...';
    console.log('Request body (sanitized):', JSON.stringify(logBody, null, 2));
    
    if (!idToken) {
      return sendError(res, 'Authentication token is required', 400);
    }

    // Verify Firebase ID token
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    
    // Check if user already exists in our database
    let user = await User.findOne({ firebaseUid: decodedToken.uid });

    // Fallback: account may have been created directly in MongoDB (e.g. via admin createTeacher)
    // without a Firebase account. Link the firebaseUid now so their role is preserved.
    // Only with a VERIFIED email — otherwise anyone could register a Firebase
    // account with a teacher's/admin's address and take over their account.
    if (!user && decodedToken.email) {
      const existingByEmail = await User.findOne({ email: decodedToken.email.toLowerCase() });
      if (existingByEmail && !existingByEmail.firebaseUid) {
        if (!canLinkByEmail(decodedToken, existingByEmail)) {
          const sent = await sendVerificationIfNeeded(decodedToken, existingByEmail);
          return res.status(403).json({ success: false, code: 'EMAIL_NOT_VERIFIED', message: notVerifiedMessage(sent) });
        }
        console.log('Teacher/admin account found by verified email, linking firebaseUid:', decodedToken.uid);
        existingByEmail.firebaseUid = decodedToken.uid;
        await existingByEmail.save();
        user = existingByEmail;
      }
    }
    
    if (!user) {
      // Case 1: New user (signup) - create user in MongoDB
      console.log('Creating new user from Firebase:', decodedToken.email);
      console.log('Provided full name:', fullName);
      
      // Get user's display name and phone number from Firebase Auth
      let displayName = '';
      let phoneNumber = null;
      try {
        const firebaseUser = await admin.auth().getUser(decodedToken.uid);
        console.log('=== Firebase User Debug ===');
        console.log('Firebase UID:', firebaseUser.uid);
        console.log('Firebase Email:', firebaseUser.email);
        console.log('Firebase Display Name:', firebaseUser.displayName);
        console.log('Firebase Phone Number:', firebaseUser.phoneNumber);
        console.log('Provided fullName:', fullName);

        // Get phone number from Firebase (for phone auth users)
        phoneNumber = firebaseUser.phoneNumber;
        console.log('Phone number from Firebase:', phoneNumber);

        // Priority order for display name:
        // 1. Provided fullName (from frontend - for email registration)
        // 2. Firebase display name (if available - for Google auth)
        // 3. Email username (for email auth)
        // 4. Empty string for phone auth users (will trigger name collection screen)
        // Note: Phone auth users should go through name collection screen, so we don't set a default
        if (fullName) {
          displayName = fullName;
        } else if (firebaseUser.displayName) {
          displayName = firebaseUser.displayName;
        } else if (firebaseUser.email) {
          displayName = firebaseUser.email.split('@')[0];
        } else {
          // Phone auth users without email - leave empty to trigger name collection
          displayName = '';
        }
        console.log('Final displayName selected:', displayName);
      } catch (firebaseError) {
        console.log('Could not get user display name from Firebase Auth, using provided name or empty');
        displayName = fullName || '';
      }
      
      try {
        user = await User.create({
          firebaseUid: decodedToken.uid,
          ...(decodedToken.email && { email: decodedToken.email }),
          fullName: displayName,
          ...roleFields(chosenRole || 'student'),
          // Google / phone sign-up without a role choice: ask once in the app.
          needsRoleSelection: !chosenRole,
          provider: 'firebase',
          isVerified: decodedToken.email_verified || false,
          isActive: true,
          // Firebase users don't need password
          password: undefined,
          // Save phone number if available (from phone auth)
          ...(phoneNumber && { phone: phoneNumber }),
          // Bind device ID if provided
          ...(deviceId && { deviceId })
        });
      } catch (createError) {
        // Handle race condition or duplicate key on any unique field (firebaseUid, phone, email)
        if (createError.code === 11000) {
          console.log('Duplicate key on create, attempting recovery. Error:', createError.message);
          // Try finding by firebaseUid first (race condition on same user)
          user = await User.findOne({ firebaseUid: decodedToken.uid });
          if (!user && phoneNumber) {
            const existingByPhone = await User.findOne({ phone: phoneNumber });
            if (existingByPhone) {
              if (!existingByPhone.firebaseUid) {
                // Orphaned record (registered without Firebase) - safe to link
                console.log('Found orphaned user by phone, linking firebaseUid:', decodedToken.uid);
                existingByPhone.firebaseUid = decodedToken.uid;
                await existingByPhone.save();
                user = existingByPhone;
              } else if (existingByPhone.firebaseUid === decodedToken.uid) {
                // Same Firebase user (race condition) - just use it
                user = existingByPhone;
              } else {
                // Phone belongs to a DIFFERENT Firebase user - reject to prevent account takeover
                console.warn(`Phone ${phoneNumber} already belongs to firebaseUid ${existingByPhone.firebaseUid}, rejecting uid ${decodedToken.uid}`);
                return sendError(res, 'An account with this phone number already exists. Please sign in with your original method.', 409);
              }
            }
          }
          if (!user && decodedToken.email) {
            const existingByEmail = await User.findOne({ email: decodedToken.email });
            if (existingByEmail) {
              if (!existingByEmail.firebaseUid) {
                // Orphaned record - link only when the email is verified
                if (!canLinkByEmail(decodedToken, existingByEmail)) {
                  const sent = await sendVerificationIfNeeded(decodedToken, existingByEmail);
                  return res.status(403).json({ success: false, code: 'EMAIL_NOT_VERIFIED', message: notVerifiedMessage(sent) });
                }
                console.log('Found orphaned user by verified email, linking firebaseUid:', decodedToken.uid);
                existingByEmail.firebaseUid = decodedToken.uid;
                await existingByEmail.save();
                user = existingByEmail;
              } else if (existingByEmail.firebaseUid === decodedToken.uid) {
                user = existingByEmail;
              } else {
                // Email belongs to a DIFFERENT Firebase user - reject
                console.warn(`Email ${decodedToken.email} already belongs to firebaseUid ${existingByEmail.firebaseUid}, rejecting uid ${decodedToken.uid}`);
                return sendError(res, 'An account with this email address already exists. Please sign in with your original method.', 409);
              }
            }
          }
          if (!user) {
            throw createError;
          }
        } else {
          throw createError;
        }
      }

      // Send welcome email to the new user
      try {
        await emailService.sendWelcomeEmail(user.email, user);
        console.log(`Welcome email sent to new user: ${user.email}`);
      } catch (emailError) {
        console.error('Error sending welcome email:', emailError);
        // Don't fail the registration if email sending fails
      }
    } else {
      // Case 2: Existing user (login) - user already in MongoDB
      console.log('Existing user logging in:', user.email);
      
      // Device binding logic - skip for admin and instructor users
      if (deviceId && user.role !== 'admin' && user.role !== 'instructor') {
        if (!user.deviceId) {
          // First login - bind account to device
          user.deviceId = deviceId;
          await user.save();
          console.log(`Device bound to user ${user.email}: ${deviceId}`);
        } else if (user.deviceId !== deviceId) {
          // Different device - reject login
          return sendError(res, 'This account is already registered on another device.', 401);
        }
      }
      
      // Update user info from Firebase Auth
      try {
        const firebaseUser = await admin.auth().getUser(decodedToken.uid);
        const newDisplayName = firebaseUser.displayName || (firebaseUser.email && firebaseUser.email.split('@')[0]);
        const newPhoneNumber = firebaseUser.phoneNumber;
        
        let needsSave = false;
        
        // Update display name if changed
        if (newDisplayName && user.fullName !== newDisplayName) {
          user.fullName = newDisplayName;
          needsSave = true;
          console.log('Updated user display name to:', newDisplayName);
        }
        
        // Update phone number if available and different
        if (newPhoneNumber && user.phone !== newPhoneNumber) {
          user.phone = newPhoneNumber;
          needsSave = true;
          console.log('Updated user phone number to:', newPhoneNumber);
        }
        
        if (needsSave) {
          await user.save();
        }
      } catch (firebaseError) {
        console.log('Could not update user info from Firebase Auth');
      }

      // Update last active status
      user.lastActive = new Date();
      await user.save();
    }
    
    // Generate our own JWT token for subsequent requests
    const token = generateToken({ id: user._id });
    const refreshToken = generateRefreshToken({ id: user._id });
    
    sendSuccess(res, {
      user: {
        id: user._id,
        firebaseUid: user.firebaseUid,
        fullName: user.fullName,
        email: user.email,
        role: user.role,
        teacherStatus: user.teacherStatus || null,
        needsRoleSelection: !!user.needsRoleSelection,
        phone: user.phone,
        avatar: user.avatar,
        provider: user.provider,
        hasCompletedOnboarding: user.hasCompletedOnboarding,
        interests: user.interests,
        shortTermGoal: user.shortTermGoal,
        midTermGoal: user.midTermGoal,
        longTermGoal: user.longTermGoal,
        createdAt: user.createdAt.getTime()  // Convert to milliseconds for Dart DateTime
      },
      token,
      refreshToken
    }, 'Authentication successful');
    
  } catch (error) {
    console.error('Firebase login error:', error);
    if (error.code === 'auth/argument-error') {
      return sendError(res, 'Invalid authentication token', 401);
    }
    if (error.code === 11000) {
      const conflictField = error.keyValue ? Object.keys(error.keyValue)[0] : 'unknown field';
      const conflictValue = error.keyValue ? Object.values(error.keyValue)[0] : '';
      console.error(`Unrecoverable duplicate key on field "${conflictField}":`, conflictValue);
      return sendError(
        res,
        `An account with this ${conflictField === 'phone' ? 'phone number' : conflictField === 'email' ? 'email address' : conflictField} already exists. Please sign in instead.`,
        409,
        error.message
      );
    }
    return sendError(res, 'Authentication failed. Please try again.', 500, error.message);
  }
};

// Admin endpoint to reset user's device binding
const resetUserDevice = async (req, res) => {
  try {
    const { userId } = req.params;
    const { deviceId } = req.body;
    
    // Find the user by ID
    const user = await User.findById(userId);
    
    if (!user) {
      return sendError(res, 'User not found', 404);
    }
    
    // Reset the user's device ID
    const oldDeviceId = user.deviceId;
    user.deviceId = deviceId || null; // Allow setting to a new device ID or clearing it
    await user.save();
    
    console.log(`Admin ${req.user.id} reset device binding for user ${user.id}. Old device ID: ${oldDeviceId}, New device ID: ${deviceId || 'cleared'}`);
    
    sendSuccess(res, {
      userId: user._id,
      oldDeviceId,
      newDeviceId: user.deviceId
    }, 'User device binding reset successfully');
    
  } catch (error) {
    console.error('Reset user device error:', error);
    sendError(res, 'Failed to reset user device binding', 500, error.message);
  }
};

// Forgot password - send password reset email
const forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;

    // Validate email format
    if (!email || !/^\S+@\S+\.\S+$/.test(email)) {
      return sendError(res, 'Please provide a valid email address', 400);
    }

    // Find user by email
    const user = await User.findOne({ email });
    
    if (!user) {
      // For security reasons, return success even if user doesn't exist
      // This prevents user enumeration attacks
      return sendSuccess(res, null, 'Password reset email sent if user exists. Please check your inbox (including spam folder).');
    }

    // Try to generate a Firebase password reset link and send it via SendGrid.
    // If Firebase link generation fails (user not in Firebase), fall back to
    // the legacy custom-token flow so the reset still works.
    try {
      const actionCodeSettings = {
        url: `${process.env.FRONTEND_URL || 'http://localhost:3000'}/reset-password`,
        handleCodeInApp: false
      };

      const resetLink = await admin.auth().generatePasswordResetLink(user.email, actionCodeSettings);
      // Extract oobCode from the Firebase reset link and save it to the user record
      try {
        const urlObj = new URL(resetLink);
        const oobCode = urlObj.searchParams.get('oobCode');
        if (oobCode) {
          user.resetPasswordToken = oobCode;
          user.resetPasswordExpires = Date.now() + 60 * 60 * 1000; // 1 hour expiry
          await user.save();
        }
      } catch (_) {
        // Parsing failed; continue without logging debug info
      }

      try {
        await emailService.sendPasswordResetEmail(user.email, resetLink, user);
      } catch (_) {
        // Suppress email send errors here to avoid leaking debug info
      }

      return sendSuccess(res, null, 'Password reset email sent if user exists. Please check your inbox (including spam folder).');
    } catch (_) {
      // Legacy fallback: generate custom token and save to user
      const resetToken = crypto.randomBytes(32).toString('hex');
      const resetTokenExpiry = Date.now() + 60 * 60 * 1000; // 1 hour expiry

      user.resetPasswordToken = resetToken;
      user.resetPasswordExpires = resetTokenExpiry;
      await user.save();

      // Construct frontend link for legacy token so frontend can continue to use same flow
      const legacyResetUrl = `${process.env.FRONTEND_URL || 'http://localhost:3000'}/reset-password?oobCode=${resetToken}`;
      try {
        await emailService.sendPasswordResetEmail(user.email, legacyResetUrl, user);
      } catch (_) {
        // Suppress email send errors here as well
      }

      return sendSuccess(res, null, 'Password reset email sent if user exists. Please check your inbox (including spam folder).');
    }
  } catch (error) {
    console.error('Forgot password error:', error);
    sendError(res, 'Failed to send password reset email', 500, error.message);
  }
};

// Reset password using token
const resetPassword = async (req, res) => {
  try {
    const { token, newPassword } = req.body;

    // Validate inputs
    if (!token || !newPassword) {
      return sendError(res, 'Token and new password are required', 400);
    }

    // Validate password strength
    if (newPassword.length < 6) {
      return sendError(res, 'Password must be at least 6 characters long', 400);
    }

    // Find user with valid reset token
    const user = await User.findOne({
      resetPasswordToken: token,
      resetPasswordExpires: { $gt: Date.now() }
    });

    if (!user) {
      return sendError(res, 'Invalid or expired reset token', 400);
    }

    // Update user password
    user.password = newPassword;
    user.resetPasswordToken = undefined;
    user.resetPasswordExpires = undefined;
    await user.save();

    // Send confirmation email
    try {
      await emailService.sendPasswordResetConfirmationEmail(user.email, user);
      console.log(`Password reset confirmation email sent to: ${user.email}`);
    } catch (emailError) {
      console.error('Error sending password reset confirmation email:', emailError);
      // Don't fail the reset if email sending fails
    }

    sendSuccess(res, null, 'Password reset successfully');
  } catch (error) {
    console.error('Reset password error:', error);
    sendError(res, 'Failed to reset password', 500, error.message);
  }
};
// Verify reset token (used by frontend to validate code before submitting new password)
const verifyResetToken = async (req, res) => {
  try {
    const { token } = req.body;

    if (!token) {
      return sendError(res, 'Token is required', 400);
    }

    const user = await User.findOne({
      resetPasswordToken: token,
      resetPasswordExpires: { $gt: Date.now() }
    });

    if (!user) {
      return sendError(res, 'Invalid or expired reset token', 400);
    }

    return sendSuccess(res, null, 'Reset token is valid');
  } catch (error) {
    console.error('Verify reset token error:', error);
    return sendError(res, 'Failed to verify reset token', 500, error.message);
  }
};

// Delete user account
const deleteAccount = async (req, res) => {
  try {
    const userId = req.user.id;
    const user = await User.findById(userId);

    if (!user) {
      return sendError(res, 'User not found', 404);
    }

    // Delete from Firebase if applicable
    if (user.firebaseUid) {
      try {
        await admin.auth().deleteUser(user.firebaseUid);
        console.log(`Firebase user ${user.firebaseUid} deleted`);
      } catch (firebaseError) {
        console.error('Firebase user deletion error:', firebaseError.message);
        // Continue even if Firebase deletion fails (user might already be gone)
      }
    }

    // Delete related data
    const Enrollment = require('../models/Enrollment');
    const Payment = require('../models/Payment');
    const Result = require('../models/Result');

    await Enrollment.deleteMany({ userId: user._id });
    await Payment.deleteMany({ userId: user._id });
    await Result.deleteMany({ userId: user._id });

    // Delete user from MongoDB
    await User.findByIdAndDelete(userId);

    sendSuccess(res, null, 'Account deleted successfully');
  } catch (error) {
    console.error('Delete account error:', error);
    sendError(res, 'Failed to delete account', 500, error.message);
  }
};

// Choose the account role once, after a Google / phone sign-up (PUT /auth/role)
const chooseRole = async (req, res) => {
  try {
    const role = normalizeSelfRole(req.body?.role);
    if (!role) return sendError(res, 'Role must be "student" or "instructor"', 400);
    const user = await User.findById(req.user._id || req.user.id);
    if (!user) return sendNotFound(res, 'User not found');
    if (!user.needsRoleSelection) {
      return sendError(res, 'Your role has already been set. Contact support to change it.', 409);
    }
    Object.assign(user, roleFields(role));
    user.needsRoleSelection = false;
    await user.save();
    sendSuccess(res, {
      user: {
        id: user._id,
        fullName: user.fullName,
        email: user.email,
        phone: user.phone,
        role: user.role,
        teacherStatus: user.teacherStatus || null,
        needsRoleSelection: false,
        avatar: user.avatar,
        hasCompletedOnboarding: user.hasCompletedOnboarding,
        interests: user.interests,
        createdAt: user.createdAt.getTime()
      }
    }, 'Role saved');
  } catch (error) {
    sendError(res, 'Failed to save role', 500, error.message);
  }
};

module.exports = {
  chooseRole,
  register,
  login,
  refreshToken,
  getProfile,
  updateProfile,
  logout,
  startSession,
  recordSessionHeartbeat,
  googleSignIn,
  firebaseLogin,
  forgotPassword,
  resetPassword,
  verifyResetToken,
  resetUserDevice,
  deleteAccount
};