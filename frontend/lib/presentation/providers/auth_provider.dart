import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'dart:io';
import 'package:excellencecoachinghub/models/user.dart';
import 'package:excellencecoachinghub/config/storage_manager.dart';
import 'package:excellencecoachinghub/services/firebase_auth_service.dart';
import 'package:excellencecoachinghub/services/fcm_token_service.dart';
import 'package:excellencecoachinghub/data/repositories/auth_repository.dart';
import 'package:excellencecoachinghub/utils/device_id_utils.dart';
import 'package:excellencecoachinghub/utils/phone_validator.dart';
import 'package:excellencecoachinghub/config/api_config.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

final storageManagerProvider = Provider<StorageManager>((ref) => StorageManager());

class AuthState {
  final bool isLoading;
  final bool isEmailLoading;
  final bool isGoogleLoading;
  final bool isPhoneLoading;
  final User? user;
  final String? error;
  final String? verificationId;
  final bool isCodeSent;

  AuthState({
    bool? isLoading,
    bool? isEmailLoading,
    bool? isGoogleLoading,
    bool? isPhoneLoading,
    this.user,
    this.error,
    this.verificationId,
    bool? isCodeSent,
  })  : isLoading = isLoading ?? false,
        isEmailLoading = isEmailLoading ?? false,
        isGoogleLoading = isGoogleLoading ?? false,
        isPhoneLoading = isPhoneLoading ?? false,
        isCodeSent = isCodeSent ?? false;

  AuthState copyWith({
    bool? isLoading,
    bool? isEmailLoading,
    bool? isGoogleLoading,
    bool? isPhoneLoading,
    User? user,
    String? error,
    String? verificationId,
    bool? isCodeSent,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isEmailLoading: isEmailLoading ?? this.isEmailLoading,
      isGoogleLoading: isGoogleLoading ?? this.isGoogleLoading,
      isPhoneLoading: isPhoneLoading ?? this.isPhoneLoading,
      user: user ?? this.user,
      error: error ?? this.error,
      verificationId: verificationId ?? this.verificationId,
      isCodeSent: isCodeSent ?? this.isCodeSent,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository = AuthRepository();
  final StorageManager _storageManager = StorageManager();

  AuthNotifier() : super(AuthState()) {
    // Check auth status on initialization
    checkAuthStatus();
  }

  Future<void> login(String emailOrPhone, String password, {bool isEmailOrPhone = false}) async {
    debugPrint('AuthProvider: Starting email/password login');
    state = state.copyWith(isLoading: true, isEmailLoading: true, error: null);

    // Detect if user entered a phone number (no @ symbol)
    final isPhone = !emailOrPhone.contains('@');

    if (isPhone) {
      // Phone + password: use direct backend login (Firebase doesn't support phone+password)
      await _loginWithPhoneAndPassword(emailOrPhone, password);
      return;
    }
    
    try {
      // Get device ID for device binding
      String? deviceId;
      try {
        deviceId = await DeviceIdUtils.getAppDeviceId();
        debugPrint('AuthProvider: Retrieved device ID: $deviceId');
      } catch (e) {
        debugPrint('AuthProvider: Error getting device ID: $e');
        // Continue without device ID if it fails
      }
      
      // Step 1: Login with Firebase Auth
      // Note: On Windows desktop, Firebase email/password auth can fail with unknown-error.
      // We attempt Firebase first, then fall back to direct backend login on failure.
      debugPrint('AuthProvider: Step 1: Logging in with Firebase Auth...');
      final firebaseStartTime = DateTime.now();
      firebase_auth.UserCredential? userCredential;
      try {
        userCredential = await FirebaseAuthService.signInWithEmailAndPassword(
          email: emailOrPhone,
          password: password,
        );
      } catch (firebaseError) {
        final errMsg = firebaseError.toString().toLowerCase();
        final isFirebaseInternalError = errMsg.contains('unknown-error') ||
            errMsg.contains('internal-error') ||
            errMsg.contains('an internal error has occurred') ||
            errMsg.contains('wrong-password');
        if (isFirebaseInternalError && !Platform.isAndroid && !Platform.isIOS) {
          // Firebase failed on desktop — fall back to direct backend login
          debugPrint('AuthProvider: Firebase failed on desktop, falling back to backend login: $firebaseError');
          await _loginWithEmailAndPasswordBackend(emailOrPhone, password, deviceId: deviceId);
          return;
        }
        rethrow;
      }
      final firebaseEndTime = DateTime.now();
      debugPrint('AuthProvider: Firebase login took ${firebaseEndTime.difference(firebaseStartTime).inSeconds}s');
      
      if (userCredential?.user != null) {
        final firebaseUser = userCredential!.user!;
        debugPrint('AuthProvider: Firebase login successful for ${firebaseUser.email}');
        
        // Step 2: Get Firebase ID token
        debugPrint('AuthProvider: Step 2: Getting Firebase ID token...');
        final tokenStartTime = DateTime.now();
        final idToken = await firebaseUser.getIdToken();
        final tokenEndTime = DateTime.now();
        debugPrint('AuthProvider: Getting ID token took ${tokenEndTime.difference(tokenStartTime).inSeconds}s');
        
        if (idToken == null) {
          debugPrint('AuthProvider: ERROR - idToken is null after login');
          throw Exception('Failed to get authentication token after login');
        }
        
        // Step 3: Send token to backend for authentication
        debugPrint('AuthProvider: Step 3: Sending token to backend for authentication...');
        debugPrint('AuthProvider: Target backend: ${ApiConfig.baseUrl}/auth/firebase-login');
        final backendStartTime = DateTime.now();
        final authResponse = await _authRepository.firebaseLogin(idToken, deviceId: deviceId);
        final backendEndTime = DateTime.now();
        debugPrint('AuthProvider: Backend authentication successful, took ${backendEndTime.difference(backendStartTime).inSeconds}s');
        
        // Step 4: Save tokens and user data
        await _storageManager.saveAccessToken(authResponse.token);
        await _storageManager.saveRefreshToken(authResponse.refreshToken);
        await _storageManager.saveUserRole(authResponse.user.role);
        await _storageManager.saveUserId(authResponse.user.id);
        await _storageManager.saveUserPhone(authResponse.user.phone);
        await _storageManager.saveUserName(authResponse.user.fullName);
        await _storageManager.saveUserAvatar(authResponse.user.profilePicture);
        await _storageManager.saveUserInterests(authResponse.user.interests);
        await _storageManager.saveUserShortTermGoal(authResponse.user.shortTermGoal);
        await _storageManager.saveUserMidTermGoal(authResponse.user.midTermGoal);
        await _storageManager.saveUserLongTermGoal(authResponse.user.longTermGoal);
        await _storageManager.saveHasCompletedOnboarding(authResponse.user.hasCompletedOnboarding);
        
        debugPrint('AuthProvider: Login completed successfully');
        
        // Set the user state and ensure navigation triggers
        state = state.copyWith(
          isLoading: false, 
          isEmailLoading: false,
          user: authResponse.user, 
          error: 'Welcome back! Login successful.'
        );
        
        // Step 5: Initialize and sync FCM token for push notifications
        FCMTokenService.initializeAndSyncToken();
        
        // Small delay to ensure state is properly propagated
        await Future.delayed(const Duration(milliseconds: 50));
      } else {
        state = state.copyWith(isLoading: false, isEmailLoading: false, error: 'Login failed. Please try again.');
      }
    } catch (e) {
      debugPrint('Login Provider Error: $e');
      String errorMessage = e.toString();
      
      // Provide user-friendly error messages
      final msgLower = errorMessage.toLowerCase();
      if (msgLower.contains('invalid email or password') || 
          msgLower.contains('wrong-password') || 
          msgLower.contains('user-not-found') ||
          msgLower.contains('incorrect password') ||
          msgLower.contains('invalid-credential') ||
          msgLower.contains('an internal error has occurred')) {
        errorMessage = 'Oops! It looks like the email or password you entered isn\'t correct. If you\'ve forgotten your password, you can reset it using the "Forgot password?" link below.';
      } else if (msgLower.contains('account is deactivated') || msgLower.contains('user-disabled')) {
        errorMessage = 'Your account has been deactivated. Please contact support.';
      } else if (msgLower.contains('already registered on another device') || 
                 msgLower.contains('device binding') ||
                 msgLower.contains('registered on another device')) {
        errorMessage = 'This account is already registered on another device. For security, you can only use it on one device at a time. Please contact support if you need to reset your device.';
      } else if (msgLower.contains('network error') || 
                 msgLower.contains('connection failed') || 
                 msgLower.contains('socketexception') ||
                 msgLower.contains('internet connection') ||
                 msgLower.contains('host lookup')) {
        errorMessage = 'Network connection error. Please check your internet connection and try again.';
      } else if (msgLower.contains('login failed')) {
        errorMessage = 'Login failed. Please try again.';
      } else {
        // Remove technical prefixes and scrub Firebase mentions for cleaner user messages
        errorMessage = errorMessage.replaceFirst('Exception: ', '').replaceAll('Firebase', 'Authentication').replaceAll('firebase', 'authentication');
      }
      
      state = state.copyWith(isLoading: false, isEmailLoading: false, error: errorMessage);
    }
  }

  // Offline login using cached credentials
  Future<void> loginOffline() async {
    debugPrint('AuthProvider: Starting offline login');
    state = state.copyWith(isLoading: true, isEmailLoading: true, error: null);
    
    try {
      // Check if we have cached user data
      final userId = await _storageManager.getUserId();
      final userRole = await _storageManager.getUserRole();
      final userPhone = await _storageManager.getUserPhone();
      final hasCompletedOnboarding = await _storageManager.hasCompletedOnboarding();
      
      if (userId == null || userRole == null) {
        throw Exception('No cached credentials found. Please login with internet connection first.');
      }
      
      debugPrint('AuthProvider: Found cached credentials for user: $userId');
      
      // Create a minimal user object from cached data
      final cachedUser = User(
        id: userId,
        email: '', // Email not cached for privacy
        fullName: 'User',
        role: userRole,
        phone: userPhone,
        hasCompletedOnboarding: hasCompletedOnboarding,
        createdAt: DateTime.now(), // Use current time for offline login
      );
      
      state = state.copyWith(
        isLoading: false,
        isEmailLoading: false,
        user: cachedUser,
        error: 'You are offline. Using cached credentials. Some features may be limited.'
      );
      
      debugPrint('AuthProvider: Offline login successful');
    } catch (e) {
      debugPrint('AuthProvider: Offline login error: $e');
      state = state.copyWith(
        isLoading: false,
        isEmailLoading: false,
        error: 'No cached credentials found. Please connect to internet and login first.'
      );
    }
  }

  // Email + Password direct backend login — used as fallback when Firebase fails on desktop
  Future<void> _loginWithEmailAndPasswordBackend(String email, String password, {String? deviceId}) async {
    debugPrint('AuthProvider: Starting direct backend email+password login for $email');
    try {
      final authResponse = await _authRepository.login(email, password, deviceId: deviceId);

      await _storageManager.saveAccessToken(authResponse.token);
      await _storageManager.saveRefreshToken(authResponse.refreshToken);
      await _storageManager.saveUserRole(authResponse.user.role);
      await _storageManager.saveUserId(authResponse.user.id);
      await _storageManager.saveUserPhone(authResponse.user.phone);
      await _storageManager.saveUserName(authResponse.user.fullName);
      await _storageManager.saveUserAvatar(authResponse.user.profilePicture);
      await _storageManager.saveUserInterests(authResponse.user.interests);
      await _storageManager.saveUserShortTermGoal(authResponse.user.shortTermGoal);
      await _storageManager.saveUserMidTermGoal(authResponse.user.midTermGoal);
      await _storageManager.saveUserLongTermGoal(authResponse.user.longTermGoal);
      await _storageManager.saveHasCompletedOnboarding(authResponse.user.hasCompletedOnboarding);

      debugPrint('AuthProvider: Direct backend login successful for $email');
      state = state.copyWith(
        isLoading: false,
        isEmailLoading: false,
        user: authResponse.user,
        error: 'Welcome back! Login successful.',
      );
      FCMTokenService.initializeAndSyncToken();
      await Future.delayed(const Duration(milliseconds: 50));
    } catch (e) {
      debugPrint('AuthProvider: Direct backend login error: $e');
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      final msgLower = errorMessage.toLowerCase();
      if (msgLower.contains('invalid') || msgLower.contains('unauthorized') ||
          msgLower.contains('password') || msgLower.contains('email or password')) {
        errorMessage = 'Oops! It looks like the email or password you entered isn\'t correct. If you\'ve forgotten your password, you can reset it using the "Forgot password?" link below.';
      } else if (msgLower.contains('network') || msgLower.contains('connection') || msgLower.contains('socket')) {
        errorMessage = 'Network connection error. Please check your internet connection and try again.';
      } else if (msgLower.contains('deactivated') || msgLower.contains('disabled')) {
        errorMessage = 'Your account has been deactivated. Please contact support.';
      } else if (msgLower.contains('another device') || msgLower.contains('device binding')) {
        errorMessage = 'This account is already registered on another device. For security, you can only use it on one device at a time. Please contact support if you need to reset your device.';
      }
      state = state.copyWith(isLoading: false, isEmailLoading: false, error: errorMessage);
    }
  }

  // Phone + Password login — direct backend call, no Firebase
  Future<void> _loginWithPhoneAndPassword(String phone, String password) async {
    debugPrint('AuthProvider: Starting phone+password login for $phone');
    try {
      String? deviceId;
      try {
        deviceId = await DeviceIdUtils.getAppDeviceId();
      } catch (_) {}

      final authResponse = await _authRepository.login(phone, password, deviceId: deviceId);

      await _storageManager.saveAccessToken(authResponse.token);
      await _storageManager.saveRefreshToken(authResponse.refreshToken);
      await _storageManager.saveUserRole(authResponse.user.role);
      await _storageManager.saveUserId(authResponse.user.id);
      await _storageManager.saveUserPhone(authResponse.user.phone);
      await _storageManager.saveUserName(authResponse.user.fullName);
      await _storageManager.saveUserAvatar(authResponse.user.profilePicture);
      await _storageManager.saveUserInterests(authResponse.user.interests);
      await _storageManager.saveUserShortTermGoal(authResponse.user.shortTermGoal);
      await _storageManager.saveUserMidTermGoal(authResponse.user.midTermGoal);
      await _storageManager.saveUserLongTermGoal(authResponse.user.longTermGoal);
      await _storageManager.saveHasCompletedOnboarding(authResponse.user.hasCompletedOnboarding);

      debugPrint('AuthProvider: Phone+password login successful');
      state = state.copyWith(
        isLoading: false,
        isEmailLoading: false,
        user: authResponse.user,
        error: 'Welcome back! Login successful.',
      );
      FCMTokenService.initializeAndSyncToken();
    } catch (e) {
      debugPrint('AuthProvider: Phone+password login error: $e');
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      final msgLower = errorMessage.toLowerCase();
      if (msgLower.contains('invalid') || msgLower.contains('unauthorized') || msgLower.contains('password')) {
        errorMessage = 'Oops! It looks like the phone number or password you entered isn\'t correct.';
      } else if (msgLower.contains('network') || msgLower.contains('connection') || msgLower.contains('socket')) {
        errorMessage = 'Network connection error. Please check your internet connection and try again.';
      }
      state = state.copyWith(isLoading: false, isEmailLoading: false, error: errorMessage);
    }
  }

  // Phone Authentication - Send OTP
  Future<void> sendPhoneOTP(String phoneNumber) async {
    debugPrint('AuthProvider: Sending OTP to $phoneNumber');
    state = state.copyWith(isLoading: true, isPhoneLoading: true, error: null, verificationId: null, isCodeSent: false);
    
    try {
      await FirebaseAuthService.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('AuthProvider: OTP sent successfully, verificationId: $verificationId');
          state = state.copyWith(
            isLoading: false,
            isPhoneLoading: false,
            verificationId: verificationId,
            isCodeSent: true,
            error: null,
          );
        },
        verificationFailed: (firebase_auth.FirebaseAuthException e) {
          debugPrint('AuthProvider: OTP sending failed: ${e.code} - ${e.message}');
          
          // Use FirebaseAuthService's error mapping for consistent user-friendly messages
          String errorMessage;
          try {
            final mappedException = FirebaseAuthService.mapFirebaseAuthException(e);
            errorMessage = mappedException.toString().replaceFirst('Exception: ', '');
          } catch (_) {
            // Fallback if mapping fails
            errorMessage = e.message ?? 'Failed to send verification code';
          }
          
          // Additional scrubbing to ensure no Firebase references
          errorMessage = errorMessage.replaceAll('Firebase', 'Authentication').replaceAll('firebase', 'authentication');
          
          state = state.copyWith(
            isLoading: false,
            isPhoneLoading: false,
            error: errorMessage,
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('AuthProvider: Auto-retrieval timeout');
          // Don't update state here - let user manually enter code
        },
      );
    } catch (e) {
      debugPrint('AuthProvider: Send OTP Error: $e');
      state = state.copyWith(
        isLoading: false,
        isPhoneLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // Phone Authentication - Verify OTP and Sign In
  Future<void> verifyPhoneOTP(String smsCode) async {
    debugPrint('AuthProvider: Verifying OTP');
    state = state.copyWith(isLoading: true, isPhoneLoading: true, error: null);
    
    try {
      final verificationId = state.verificationId;
      if (verificationId == null) {
        throw Exception('No verification ID found. Please request a new code.');
      }
      
      // Create phone credential
      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      
      // Sign in with phone credential
      final userCredential = await FirebaseAuthService.signInWithPhoneCredential(credential);
      
      if (userCredential?.user != null) {
        final firebaseUser = userCredential!.user!;
        debugPrint('AuthProvider: Phone sign-in successful for ${firebaseUser.phoneNumber}');
        
        // Get device ID for device binding
        String? deviceId;
        try {
          deviceId = await DeviceIdUtils.getAppDeviceId();
          debugPrint('AuthProvider: Retrieved device ID: $deviceId');
        } catch (e) {
          debugPrint('AuthProvider: Error getting device ID: $e');
        }
        
        // Get Firebase ID token
        debugPrint('AuthProvider: Getting Firebase ID token...');
        final idToken = await firebaseUser.getIdToken();
        
        if (idToken == null) {
          throw Exception('Failed to get authentication token after phone sign-in');
        }
        
        // Send token to backend for authentication
        debugPrint('AuthProvider: Sending token to backend for authentication...');
        final authResponse = await _authRepository.firebaseLogin(idToken, deviceId: deviceId);
        debugPrint('AuthProvider: Backend authentication successful');
        
        // Save tokens and user data
        await _storageManager.saveAccessToken(authResponse.token);
        await _storageManager.saveRefreshToken(authResponse.refreshToken);
        await _storageManager.saveUserRole(authResponse.user.role);
        await _storageManager.saveUserId(authResponse.user.id);
        await _storageManager.saveUserPhone(authResponse.user.phone);
        await _storageManager.saveUserName(authResponse.user.fullName);
        await _storageManager.saveUserAvatar(authResponse.user.profilePicture);
        await _storageManager.saveUserInterests(authResponse.user.interests);
        await _storageManager.saveUserShortTermGoal(authResponse.user.shortTermGoal);
        await _storageManager.saveUserMidTermGoal(authResponse.user.midTermGoal);
        await _storageManager.saveUserLongTermGoal(authResponse.user.longTermGoal);
        await _storageManager.saveHasCompletedOnboarding(authResponse.user.hasCompletedOnboarding);
        
        debugPrint('AuthProvider: Phone sign-in completed successfully');
        
        state = state.copyWith(
          isLoading: false,
          isPhoneLoading: false,
          user: authResponse.user,
          verificationId: null,
          isCodeSent: false,
          error: 'Welcome! Phone sign-in successful.',
        );
        
        // Initialize FCM token for push notifications
        FCMTokenService.initializeAndSyncToken();
        
        await Future.delayed(const Duration(milliseconds: 50));
      } else {
        state = state.copyWith(
          isLoading: false,
          isPhoneLoading: false,
          error: 'Phone sign-in failed. Please try again.',
        );
      }
    } catch (e) {
      debugPrint('AuthProvider: Verify OTP Error: $e');
      String errorMessage = e.toString();
      
      // Provide user-friendly error messages
      final msgLower = errorMessage.toLowerCase();
      if (msgLower.contains('invalid-verification-code') || 
          msgLower.contains('invalid code') ||
          msgLower.contains('wrong code')) {
        errorMessage = 'The verification code is invalid. Please check and try again.';
      } else if (msgLower.contains('code-expired') || 
                 msgLower.contains('session-expired')) {
        errorMessage = 'The verification code has expired. Please request a new code.';
      } else if (msgLower.contains('network error') || 
                 msgLower.contains('connection failed') || 
                 msgLower.contains('socketexception')) {
        errorMessage = 'Network connection error. Please check your internet connection and try again.';
      } else {
        errorMessage = errorMessage.replaceFirst('Exception: ', '').replaceAll('Firebase', 'Authentication');
      }
      
      state = state.copyWith(
        isLoading: false,
        isPhoneLoading: false,
        error: errorMessage,
      );
    }
  }

  // Reset phone auth state
  void resetPhoneAuth() {
    state = state.copyWith(
      verificationId: null,
      isCodeSent: false,
      error: null,
    );
  }

  Future<void> register(String fullName, String? email, String password, String? phone) async {
    debugPrint('AuthProvider: Starting registration process');
    state = state.copyWith(isLoading: true, isEmailLoading: true, error: null);

    // Phone-only registration: bypass Firebase (requires email), use backend directly
    final hasEmail = email != null && email.trim().isNotEmpty;
    if (!hasEmail) {
      await _registerWithPhoneAndPassword(fullName, phone ?? '', password);
      return;
    }
    
    try {
      // Get device ID for device binding
      String? deviceId;
      try {
        deviceId = await DeviceIdUtils.getAppDeviceId();
        debugPrint('AuthProvider: Retrieved device ID: $deviceId');
      } catch (e) {
        debugPrint('AuthProvider: Error getting device ID: $e');
        // Continue without device ID if it fails
      }
      
      // Step 1: Register with Firebase Auth first
      debugPrint('AuthProvider: Registering with Firebase Auth');
      final userCredential = await FirebaseAuthService.registerWithEmailAndPassword(
        email: email,
        password: password,
        fullName: fullName,
      );
      
      if (userCredential?.user != null) {
        final firebaseUser = userCredential!.user!;
        debugPrint('AuthProvider: Firebase registration successful for ${firebaseUser.email}');
        
        // Ensure the display name is properly set and user is reloaded
        await firebaseUser.reload();
        final updatedUser = firebase_auth.FirebaseAuth.instance.currentUser;
        debugPrint('AuthProvider: User reloaded, display name: ${updatedUser?.displayName}');
        
        // Step 2: Get Firebase ID token
        debugPrint('AuthProvider: Getting Firebase ID token');
        final idToken = await updatedUser?.getIdToken() ?? await firebaseUser.getIdToken();
        debugPrint('AuthProvider: Got Firebase ID token');
        
        if (idToken == null) {
          debugPrint('AuthProvider: ERROR - idToken is null after registration');
          throw Exception('Failed to get authentication token after registration');
        }
        
        // Step 3: Send token to backend for user creation in MongoDB
        debugPrint('AuthProvider: Sending token to backend for authentication');
        var authResponse = await _authRepository.firebaseLogin(idToken, fullName: fullName, deviceId: deviceId);
        debugPrint('AuthProvider: Backend authentication successful');

        // Step 3b: firebase-login doesn't carry the phone, so persist the one the
        // user typed during registration — otherwise onboarding asks for it again.
        final hasPhone = phone != null && phone.trim().isNotEmpty;
        final backendHasPhone = authResponse.user.phone?.trim().isNotEmpty ?? false;
        if (hasPhone && !backendHasPhone) {
          try {
            final updatedUser = await _authRepository.updateProfile(
              authResponse.token,
              phone: PhoneValidator.formatPhoneNumber(phone.trim()),
            );
            authResponse = AuthResponse(
              user: updatedUser,
              token: authResponse.token,
              refreshToken: authResponse.refreshToken,
            );
          } catch (e) {
            // Non-fatal: the phone-collection step will ask for it instead.
            debugPrint('AuthProvider: Could not save registration phone: $e');
          }
        }

        // Step 4: Save tokens and user data
        await _storageManager.saveAccessToken(authResponse.token);
        await _storageManager.saveRefreshToken(authResponse.refreshToken);
        await _storageManager.saveUserRole(authResponse.user.role);
        await _storageManager.saveUserId(authResponse.user.id);
        await _storageManager.saveUserPhone(authResponse.user.phone);
        await _storageManager.saveUserName(authResponse.user.fullName);
        await _storageManager.saveUserAvatar(authResponse.user.profilePicture);
        await _storageManager.saveUserInterests(authResponse.user.interests);
        await _storageManager.saveUserShortTermGoal(authResponse.user.shortTermGoal);
        await _storageManager.saveUserMidTermGoal(authResponse.user.midTermGoal);
        await _storageManager.saveUserLongTermGoal(authResponse.user.longTermGoal);
        await _storageManager.saveHasCompletedOnboarding(authResponse.user.hasCompletedOnboarding);
        
        // Step 5: Initialize and sync FCM token for push notifications
        FCMTokenService.initializeAndSyncToken();
        
        debugPrint('AuthProvider: Registration completed successfully');
        state = state.copyWith(
          isLoading: false, 
          isEmailLoading: false,
          user: authResponse.user, 
          error: 'Registration successful! Welcome to ExcellenceCoachingHub.'
        );
      } else {
        state = state.copyWith(isLoading: false, isEmailLoading: false, error: 'Registration failed. Please try again.');
      }
    } catch (e) {
      debugPrint('Registration Provider Error: $e');
      String errorMessage = e.toString();
      
      // Provide user-friendly error messages
      final msgLower = errorMessage.toLowerCase();
      if (msgLower.contains('email-already-in-use')) {
        errorMessage = 'An account with this email already exists. Please try logging in instead.';
      } else if (msgLower.contains('invalid-email')) {
        errorMessage = 'Please enter a valid email address.';
      } else if (msgLower.contains('weak-password')) {
        errorMessage = 'Password is too weak. Please use a stronger password.';
      } else if (msgLower.contains('operation-not-allowed')) {
        errorMessage = 'Email/password registration is not enabled.';
      } else if (msgLower.contains('network error') || 
                 msgLower.contains('connection failed') || 
                 msgLower.contains('socketexception') ||
                 msgLower.contains('internet connection') ||
                 msgLower.contains('host lookup')) {
        errorMessage = 'Network connection error. Please check your internet connection and try again.';
      } else if (msgLower.contains('registration failed')) {
        errorMessage = 'Registration failed. Please try again or contact support.';
      } else {
        // Remove technical prefixes and scrub Firebase mentions for cleaner user messages
        errorMessage = errorMessage.replaceFirst('Exception: ', '').replaceAll('Firebase', 'Authentication').replaceAll('firebase', 'authentication');
      }
      
      state = state.copyWith(isLoading: false, isEmailLoading: false, error: errorMessage);
    }
  }

  // Phone-only registration — direct backend call, no Firebase
  Future<void> _registerWithPhoneAndPassword(String fullName, String phone, String password) async {
    debugPrint('AuthProvider: Starting phone-only registration for $phone');
    try {
      String? deviceId;
      try {
        deviceId = await DeviceIdUtils.getAppDeviceId();
      } catch (_) {}

      final authResponse = await _authRepository.register(fullName, null, password, phone);

      await _storageManager.saveAccessToken(authResponse.token);
      await _storageManager.saveRefreshToken(authResponse.refreshToken);
      await _storageManager.saveUserRole(authResponse.user.role);
      await _storageManager.saveUserId(authResponse.user.id);
      await _storageManager.saveUserPhone(authResponse.user.phone);
      await _storageManager.saveUserName(authResponse.user.fullName);
      await _storageManager.saveUserAvatar(authResponse.user.profilePicture);
      await _storageManager.saveUserInterests(authResponse.user.interests);
      await _storageManager.saveUserShortTermGoal(authResponse.user.shortTermGoal);
      await _storageManager.saveUserMidTermGoal(authResponse.user.midTermGoal);
      await _storageManager.saveUserLongTermGoal(authResponse.user.longTermGoal);
      await _storageManager.saveHasCompletedOnboarding(authResponse.user.hasCompletedOnboarding);

      FCMTokenService.initializeAndSyncToken();
      debugPrint('AuthProvider: Phone registration successful');
      state = state.copyWith(
        isLoading: false,
        isEmailLoading: false,
        user: authResponse.user,
        error: 'Registration successful! Welcome to ExcellenceCoachingHub.',
      );
    } catch (e) {
      debugPrint('AuthProvider: Phone registration error: $e');
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      final msgLower = errorMessage.toLowerCase();
      if (msgLower.contains('already exists')) {
        errorMessage = 'An account with this phone number already exists. Please sign in instead.';
      } else if (msgLower.contains('network') || msgLower.contains('connection') || msgLower.contains('socket')) {
        errorMessage = 'Network connection error. Please check your internet connection and try again.';
      }
      state = state.copyWith(isLoading: false, isEmailLoading: false, error: errorMessage);
    }
  }

  Future<String> _refreshBackendToken() async {
    debugPrint('AuthProvider: Refreshing backend token');
    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) throw Exception('No authenticated user found. Please login again.');
    
    final idToken = await firebaseUser.getIdToken(true);
    if (idToken == null) throw Exception('Failed to get fresh authentication token');
    
    String? deviceId;
    try {
      deviceId = await DeviceIdUtils.getAppDeviceId();
    } catch (e) {
      debugPrint('AuthProvider: Error getting device ID for refresh: $e');
    }
    
    final authResponse = await _authRepository.firebaseLogin(idToken, deviceId: deviceId);
    
    await _storageManager.saveAccessToken(authResponse.token);
    await _storageManager.saveRefreshToken(authResponse.refreshToken);
    
    return authResponse.token;
  }

  Future<String> _getOrRefreshAccessToken() async {
    String? token = await _storageManager.getAccessToken();
    if (token == null) {
      return await _refreshBackendToken();
    }
    return token;
  }

  Future<void> updateProfile({
    String? fullName,
    String? email,
    String? phone, 
    File? imageFile,
    List<String>? interests,
    String? shortTermGoal,
    String? midTermGoal,
    String? longTermGoal,
    bool? hasCompletedOnboarding,
  }) async {
    state = state.copyWith(isLoading: true, isEmailLoading: false, isGoogleLoading: false, error: null);
    try {
      String token = await _getOrRefreshAccessToken();

      String? avatarUrl;
      if (imageFile != null) {
        try {
          avatarUrl = await _authRepository.uploadImage(token, imageFile);
        } catch (uploadError) {
          // If upload fails with auth or connection error, try to refresh token once
          if (uploadError.toString().contains('Not authorized') || 
              uploadError.toString().contains('invalid token') ||
              uploadError.toString().contains('SocketException')) {
            debugPrint('AuthProvider: Upload failed, attempting token refresh and retry');
            token = await _refreshBackendToken();
            avatarUrl = await _authRepository.uploadImage(token, imageFile);
          } else {
            rethrow;
          }
        }
      }

      try {
        final updatedUser = await _authRepository.updateProfile(
          token,
          fullName: fullName,
          email: email,
          phone: phone,
          avatar: avatarUrl,
          interests: interests,
          shortTermGoal: shortTermGoal,
          midTermGoal: midTermGoal,
          longTermGoal: longTermGoal,
          hasCompletedOnboarding: hasCompletedOnboarding,
        );
        
        debugPrint('AuthProvider: Profile update returned user with hasCompletedOnboarding = ${updatedUser.hasCompletedOnboarding}');
        
        // Save updated phone number to storage
        if (phone != null) {
          await _storageManager.saveUserPhone(phone);
        }
        
        // Save interests to storage
        if (interests != null) {
          await _storageManager.saveUserInterests(interests);
        }
        
        // Save onboarding completion to storage for faster access
        if (hasCompletedOnboarding != null) {
          await _storageManager.saveHasCompletedOnboarding(hasCompletedOnboarding);
        }
        
        state = state.copyWith(isLoading: false, isEmailLoading: false, isGoogleLoading: false, user: updatedUser, error: 'Profile updated successfully!');
      } catch (updateError) {
        // If profile update fails with auth error, try to refresh token once
        if (updateError.toString().contains('Not authorized') || 
            updateError.toString().contains('invalid token')) {
          debugPrint('AuthProvider: Profile update failed, attempting token refresh and retry');
          token = await _refreshBackendToken();
          final updatedUser = await _authRepository.updateProfile(
            token,
            fullName: fullName,
            email: email,
            phone: phone,
            avatar: avatarUrl,
            interests: interests,
            shortTermGoal: shortTermGoal,
            midTermGoal: midTermGoal,
            longTermGoal: longTermGoal,
            hasCompletedOnboarding: hasCompletedOnboarding,
          );
          
          // Save updated phone number to storage
          if (phone != null) {
            await _storageManager.saveUserPhone(phone);
          }
          
          // Save interests to storage
          if (interests != null) {
            await _storageManager.saveUserInterests(interests);
          }
          
          // Save onboarding completion to storage for faster access
          if (hasCompletedOnboarding != null) {
            await _storageManager.saveHasCompletedOnboarding(hasCompletedOnboarding);
          }
          
          state = state.copyWith(isLoading: false, isEmailLoading: false, isGoogleLoading: false, user: updatedUser, error: 'Profile updated successfully!');
        } else {
          rethrow;
        }
      }
    } catch (e) {
      debugPrint('AuthProvider Update Profile Error: $e');
      state = state.copyWith(isLoading: false, isEmailLoading: false, isGoogleLoading: false, error: e.toString().replaceFirst('Exception: ', ''));
      rethrow;
    }
  }

  Future<void> updatePassword(String currentPassword, String newPassword) async {
    state = state.copyWith(isLoading: true, isEmailLoading: false, isGoogleLoading: false, error: null);
    try {
      await FirebaseAuthService.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false, isEmailLoading: false, isGoogleLoading: false, error: 'Password updated successfully!');
    } catch (e) {
      debugPrint('AuthProvider Update Password Error: $e');
      state = state.copyWith(isLoading: false, isEmailLoading: false, isGoogleLoading: false, error: e.toString().replaceFirst('Exception: ', ''));
      rethrow;
    }
  }

  Future<void> deleteAccount(String currentPassword) async {
    state = state.copyWith(isLoading: true, isEmailLoading: false, isGoogleLoading: false, error: null);
    try {
      final token = await _getOrRefreshAccessToken();

      // Step 1: Delete from backend
      try {
        await _authRepository.deleteAccount(token);
      } catch (e) {
        if (e.toString().contains('Not authorized') || e.toString().contains('invalid token')) {
          final newToken = await _refreshBackendToken();
          await _authRepository.deleteAccount(newToken);
        } else {
          rethrow;
        }
      }
      debugPrint('AuthProvider: Backend account deletion successful');

      // Step 2: Delete from Firebase
      await FirebaseAuthService.deleteAccount(currentPassword: currentPassword);
      debugPrint('AuthProvider: Firebase account deletion successful');

      // Step 3: Clear local storage and state
      await _storageManager.clearAll();
      state = AuthState();
      debugPrint('AuthProvider: Account deletion completed successfully');
    } catch (e) {
      debugPrint('AuthProvider Delete Account Error: $e');
      state = state.copyWith(isLoading: false, isEmailLoading: false, isGoogleLoading: false, error: e.toString().replaceFirst('Exception: ', ''));
      rethrow;
    }
  }

  Future<void> logout() async {
    debugPrint('AuthProvider: Starting logout process');
    state = state.copyWith(isLoading: true, isEmailLoading: false, isGoogleLoading: false, error: null);
    
    try {
      // Sign out from Firebase
      await FirebaseAuthService.signOut();
      debugPrint('AuthProvider: Firebase sign out successful');
    } catch (e) {
      debugPrint('AuthProvider: Firebase sign out error (continuing anyway): $e');
      // Don't throw error - we want to clear local data regardless
    }
    
    try {
      // Clear all local storage
      await _storageManager.clearAll();
      debugPrint('AuthProvider: Local storage cleared');
    } catch (e) {
      debugPrint('AuthProvider: Storage clear error: $e');
    }
    
    // Reset state
    final oldUser = state.user;
    state = AuthState();
    debugPrint('AuthProvider: Logout completed successfully - user was: ${oldUser?.email}, state reset to: user=${state.user}, isLoading=${state.isLoading}');
  }

  Future<void> signInWithGoogle() async {
    debugPrint('AuthProvider: Starting Google Sign-In');
    state = state.copyWith(isLoading: true, isGoogleLoading: true, isEmailLoading: false, error: null);
    
    try {
      // Get device ID for device binding - do this in background, don't block
      String? deviceId;
      DeviceIdUtils.getAppDeviceId().then((id) {
        deviceId = id;
        debugPrint('AuthProvider: Retrieved device ID in background: $deviceId');
      }).catchError((e) {
        debugPrint('AuthProvider: Error getting device ID in background: $e');
      });
      
      debugPrint('AuthProvider: Calling Firebase service');
      final userCredential = await FirebaseAuthService.signInWithGoogle();
      debugPrint('AuthProvider: Firebase service returned: ${userCredential?.user?.email}');
      
      if (userCredential?.user == null) {
        debugPrint('AuthProvider: Google Sign-In returned null - user cancelled');
        state = state.copyWith(isLoading: false, isGoogleLoading: false, isEmailLoading: false, error: 'Google Sign-In was cancelled. Please try again if you wish to proceed.');
        return;
      }

      final firebaseUser = userCredential!.user!;
      
      try {
        // Get Firebase ID token
        debugPrint('AuthProvider: About to call getIdToken()');
        final idToken = await firebaseUser.getIdToken();
        debugPrint('AuthProvider: Got Firebase ID token');
        
        if (idToken == null || idToken.toString().isEmpty) {
          throw Exception('Failed to get valid authentication token');
        }
        
        // Send token to backend for authentication
        debugPrint('AuthProvider: Sending token to backend');
        final authResponse = await _authRepository.firebaseLogin(idToken, deviceId: deviceId);
        debugPrint('AuthProvider: Backend authentication successful');
        
        // Save tokens for future API requests - do in parallel for speed
        await Future.wait([
          _storageManager.saveAccessToken(authResponse.token),
          _storageManager.saveRefreshToken(authResponse.refreshToken),
          _storageManager.saveUserRole(authResponse.user.role),
          _storageManager.saveUserId(authResponse.user.id),
          _storageManager.saveUserName(authResponse.user.fullName),
          _storageManager.saveUserAvatar(authResponse.user.profilePicture),
          _storageManager.saveUserInterests(authResponse.user.interests),
          _storageManager.saveUserShortTermGoal(authResponse.user.shortTermGoal),
          _storageManager.saveUserMidTermGoal(authResponse.user.midTermGoal),
          _storageManager.saveUserLongTermGoal(authResponse.user.longTermGoal),
          _storageManager.saveHasCompletedOnboarding(authResponse.user.hasCompletedOnboarding),
        ]);
        
        debugPrint('AuthProvider: Setting success state');
        state = state.copyWith(
          isLoading: false, 
          isGoogleLoading: false,
          isEmailLoading: false,
          user: authResponse.user,
          error: null
        );
        debugPrint('AuthProvider: State updated - User: ${authResponse.user.email}');
        
        // Initialize FCM token in background after user is already logged in
        FCMTokenService.initializeAndSyncToken();
      } catch (tokenError) {
        debugPrint('AuthProvider: Token/Backend Error: $tokenError');
        
        // Sign out from Firebase if backend auth fails
        try {
          await FirebaseAuthService.signOut();
        } catch (_) {}
        
        String errorMessage = tokenError.toString();
        if (errorMessage.contains('Network') || errorMessage.toLowerCase().contains('socket')) {
          errorMessage = 'Network connection failed. Please check your internet connection and try again.';
        } else if (errorMessage.contains('backend') || errorMessage.contains('firebase-login')) {
          errorMessage = 'Server authentication failed. Please try again.';
        }
        
        state = state.copyWith(isLoading: false, isGoogleLoading: false, isEmailLoading: false, error: errorMessage);
      }
    } catch (e) {
      debugPrint('AuthProvider Google Sign-In Error: $e');
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      
      // Handle specific error codes
      if (errorMessage.contains('ApiException: 10')) {
        errorMessage = 'Google Sign-In is not properly configured for this device. Please contact support.';
      } else if (errorMessage.contains('ApiException: 7') || errorMessage.contains('network_error')) {
        errorMessage = 'A network error occurred. Please check your internet connection and try again.';
      } else if (errorMessage.contains('sign_in_failed')) {
        errorMessage = 'Google Sign-In failed. Please check your account status and try again.';
      } else if (errorMessage.contains('account-exists-with-different-credential')) {
        errorMessage = 'An account already exists with this email but using a different sign-in method. Please use that method.';
      } else if (errorMessage.contains('user-disabled')) {
        errorMessage = 'This account has been disabled. Please contact support.';
      } else if (kIsWeb) {
        if (errorMessage.contains('popup_closed') || (errorMessage.toLowerCase().contains('popup') && errorMessage.toLowerCase().contains('closed'))) {
          errorMessage = 'The sign-in popup was closed before completion. Please try again.';
        } else if (errorMessage.contains('popup_blocked')) {
          errorMessage = 'The sign-in popup was blocked by your browser. Please allow popups for this site.';
        }
      }
      
      state = state.copyWith(isLoading: false, isGoogleLoading: false, isEmailLoading: false, error: errorMessage);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    state = state.copyWith(isLoading: true, isEmailLoading: false, isGoogleLoading: false, error: null);
    
    try {
      debugPrint('AuthProvider: Sending password reset email to $email via backend API');
      
      // Call backend API to send password reset email using SendGrid
      final response = await _authRepository.sendPasswordResetEmail(email);
      
      // Success - show confirmation message
      state = state.copyWith(
        isLoading: false, 
        isEmailLoading: false,
        isGoogleLoading: false,
        error: response.message ?? 'Password reset email sent successfully! Please check your inbox (including spam folder) and follow the instructions to reset your password.'
      );
          
      debugPrint('AuthProvider: Password reset email sent successfully via backend API');
    } catch (e) {
      debugPrint('AuthProvider: Password reset failed - $e');
      String errorMessage = e.toString();
      
      // Provide user-friendly error messages
      if (errorMessage.contains('Please enter a valid email address')) {
        errorMessage = 'Please enter a valid email address';
      } else if (errorMessage.contains('Too many requests')) {
        errorMessage = 'Too many requests. Please wait a few minutes before trying again.';
      } else if (errorMessage.contains('Network error')) {
        errorMessage = 'Network connection error. Please check your internet connection and try again.';
      } else if (errorMessage.contains('Failed to send')) {
        errorMessage = 'Unable to send password reset email. Please try again or contact support.';
      }
      
      // Check if the state is still valid before updating
      state = state.copyWith(isLoading: false, isEmailLoading: false, isGoogleLoading: false, error: errorMessage);
    }
  }

  Future<PasswordResetResponse> resetPassword(String token, String newPassword) async {
    try {
      debugPrint('AuthProvider: Resetting password with token: ${token.substring(0, math.min(10, token.length))}...');
      
      // Call backend API to reset password
      final response = await _authRepository.resetPassword(token, newPassword);
      
      debugPrint('AuthProvider: Password reset successfully');
      return response;
    } catch (e) {
      debugPrint('AuthProvider: Password reset failed - $e');
      rethrow;
    }
  }

  Future<bool> verifyResetToken(String token) async {
    try {
      state = state.copyWith(isLoading: true, isEmailLoading: false, isGoogleLoading: false, error: null);
      final result = await _authRepository.verifyResetToken(token);
      state = state.copyWith(isLoading: false, isEmailLoading: false, isGoogleLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, isEmailLoading: false, isGoogleLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> checkAuthStatus() async {
    // IMPORTANT: drive splash navigation using isLoading.
    state = state.copyWith(isLoading: true, error: null);
    try {
      final firebaseUser = FirebaseAuthService.getCurrentUser();

      if (firebaseUser != null) {
        debugPrint('AuthProvider: Firebase user found: ${firebaseUser.email}');

        // Check if we have stored tokens and user data
        final storedUserId = await _storageManager.getUserId();
        final storedUserRole = await _storageManager.getUserRole();
        final storedToken = await _storageManager.getAccessToken();
        final storedPhone = await _storageManager.getUserPhone();
        final storedUserName = await _storageManager.getUserName();
        final storedUserAvatar = await _storageManager.getUserAvatar();
        final storedUserInterests = await _storageManager.getUserInterests();
        final storedUserShortTermGoal = await _storageManager.getUserShortTermGoal();
        final storedUserMidTermGoal = await _storageManager.getUserMidTermGoal();
        final storedUserLongTermGoal = await _storageManager.getUserLongTermGoal();
        final hasCompletedOnboarding = await _storageManager.hasCompletedOnboarding();

        // If we have a valid token and role, restore the session
        // Note: storedUserId is backend MongoDB ID, firebaseUser.uid is Firebase UID
        // They may differ, so we check for presence of valid stored data instead
        if (storedUserRole != null && storedToken != null) {
          debugPrint('AuthProvider: Valid session found for user: ${firebaseUser.uid}');

          // Try to refresh user data from backend to ensure it's up to date
          try {
            final freshUser = await _fetchUserProfileFromBackend(storedToken);
            if (freshUser != null) {
              debugPrint('AuthProvider: Restored user from backend: ${freshUser.email}');
              await _storageManager.saveHasCompletedOnboarding(freshUser.hasCompletedOnboarding);
              state = state.copyWith(
                user: freshUser,
                isEmailLoading: false,
                isGoogleLoading: false,
              );
            } else {
              // Fallback: recreate user from stored data + Firebase data
              final user = User(
                id: storedUserId ?? firebaseUser.uid,
                fullName: storedUserName ?? firebaseUser.displayName ?? 'User',
                email: firebaseUser.email ?? '',
                profilePicture: storedUserAvatar,
                phone: storedPhone,
                role: storedUserRole,
                hasCompletedOnboarding: hasCompletedOnboarding,
                interests: storedUserInterests,
                shortTermGoal: storedUserShortTermGoal,
                midTermGoal: storedUserMidTermGoal,
                longTermGoal: storedUserLongTermGoal,
                createdAt: DateTime.fromMillisecondsSinceEpoch(
                  firebaseUser.metadata.creationTime?.millisecondsSinceEpoch ??
                      DateTime.now().millisecondsSinceEpoch,
                ),
              );
              state = state.copyWith(
                user: user,
                isEmailLoading: false,
                isGoogleLoading: false,
              );
            }
          } catch (e) {
            debugPrint('AuthProvider: Failed to fetch fresh user data, using cached: $e');
            // Use cached data if backend fetch fails (e.g., offline)
            final user = User(
              id: storedUserId ?? firebaseUser.uid,
              fullName: storedUserName ?? firebaseUser.displayName ?? 'User',
              email: firebaseUser.email ?? '',
              profilePicture: storedUserAvatar,
              phone: storedPhone,
              role: storedUserRole,
              hasCompletedOnboarding: hasCompletedOnboarding,
              interests: storedUserInterests,
              shortTermGoal: storedUserShortTermGoal,
              midTermGoal: storedUserMidTermGoal,
              longTermGoal: storedUserLongTermGoal,
              createdAt: DateTime.fromMillisecondsSinceEpoch(
                firebaseUser.metadata.creationTime?.millisecondsSinceEpoch ??
                    DateTime.now().millisecondsSinceEpoch,
              ),
            );
            state = state.copyWith(
              user: user,
              isEmailLoading: false,
              isGoogleLoading: false,
            );
          }

          // Initialize and sync FCM token in background
          FCMTokenService.initializeAndSyncToken();
        } else {
          debugPrint('AuthProvider: Incomplete session data. storedUserRole: $storedUserRole, storedToken: ${storedToken != null}');
          // User is signed in to Firebase but we don't have complete backend tokens
          // Clear the state and require re-authentication
          await _storageManager.clearAll();
          await FirebaseAuthService.signOut();
          state = AuthState();
        }
      } else {
        debugPrint('AuthProvider: No Firebase user found');
      }
    } catch (e) {
      debugPrint('AuthProvider: Error checking auth status: $e');
      // Clear storage if there's an error
      await _storageManager.clearAll();
      state = AuthState();
    } finally {
      // Always end loading so splash can route.
      state = state.copyWith(isLoading: false, isEmailLoading: false, isGoogleLoading: false, isPhoneLoading: false);
    }
  }


  /// Fetch fresh user profile from backend using stored token
  Future<User?> _fetchUserProfileFromBackend(String token) async {
    try {
      return await _authRepository.getUserProfile(token);
    } catch (e) {
      debugPrint('AuthProvider: Error fetching user profile: $e');
      // Do not force logout on profile fetch failure.
      return null;
    }
  }


  bool get isAuthenticated => state.user != null && FirebaseAuthService.isSignedIn();
  bool get isAdmin => state.user?.role == 'admin';
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
