const sgMail = require('@sendgrid/mail');
const fs = require('fs').promises;
const path = require('path');

class EmailService {
  constructor() {
    sgMail.setApiKey(process.env.SENDGRID_API_KEY);
    this.sgMail = sgMail;
    
    this.fromEmail = process.env.FROM_EMAIL || 'info@excellencecoachinghub.com';
    this.fromName = process.env.FROM_NAME || 'excellencecoachinghub';
  }

  /**
   * Common responsive styles for email templates
   */
  _getCommonStyles() {
    return `
        <style>
            * { box-sizing: border-box; }
            body { 
                font-family: 'Segoe UI', Arial, sans-serif; 
                line-height: 1.6; 
                color: #333; 
                margin: 0; 
                padding: 0; 
                width: 100% !important; 
                -webkit-text-size-adjust: 100%; 
            }
            .container { width: 100%; max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #00b09b, #96c93d); padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
            .header h1 { color: white; margin: 0; font-size: 28px; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.05); }
            .button { 
                display: inline-block; 
                padding: 15px 30px; 
                background: #00b09b; 
                color: white !important; 
                text-decoration: none; 
                border-radius: 5px; 
                font-weight: bold;
                margin: 20px 0;
                text-align: center;
            }
            .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; border-top: 1px solid #eee; margin-top: 20px; }
            h2 { color: #2d3436; margin-top: 0; }
            h3 { color: #2d3436; }
            ul, ol { padding-left: 20px; }
            li { margin-bottom: 10px; }
            .details, .features, .status-box, .payment-details, .results-card, .result-details, .welcome-card, .course-info, .next-steps, .course-card {
                background: white;
                padding: 20px;
                border-radius: 8px;
                margin: 20px 0;
                border-left: 4px solid #00b09b;
                box-shadow: 0 2px 4px rgba(0,0,0,0.05);
            }
            .detail-row {
                display: flex;
                justify-content: space-between;
                padding: 10px 0;
                border-bottom: 1px solid #eee;
            }
            .detail-row:last-child { border-bottom: none; }
            
            /* Responsive Utilities */
            @media screen and (max-width: 600px) {
                .container { padding: 10px !important; }
                .header, .content { padding: 20px !important; }
                .header h1 { font-size: 22px !important; }
                .button { display: block !important; padding: 15px 10px !important; margin: 20px 0 !important; }
                .detail-row { flex-direction: column !important; align-items: flex-start !important; }
                .detail-row strong { margin-top: 4px; }
                .course-meta { flex-direction: column !important; gap: 10px !important; }
            }
        </style>
    `;
  }

  /**
   * Send password reset email
   */
  async sendPasswordResetEmail(email, resetTokenOrUrl, user) {
    try {
      // If caller provided a full URL (Firebase link or legacy constructed link), use it.
      // Otherwise, treat the value as a token and construct a frontend URL.
      let resetUrl = '';
      let resetToken = '';
      if (typeof resetTokenOrUrl === 'string' && resetTokenOrUrl.startsWith('http')) {
        resetUrl = resetTokenOrUrl;
      } else {
        resetToken = resetTokenOrUrl;
        resetUrl = `${process.env.FRONTEND_URL || 'http://localhost:3000'}/reset-password?oobCode=${resetToken}`;
      }

      const msg = {
        to: email,
        from: {
          email: this.fromEmail,
          name: this.fromName
        },
        subject: 'Password Reset Request - Excellence Coaching Hub',
        html: this.getPasswordResetTemplate(user.fullName, resetUrl, resetToken)
      };

      const response = await this.sgMail.send(msg);
      console.log('Password reset email sent:', response[0].headers['x-message-id']);
      return { success: true, messageId: response[0].headers['x-message-id'] };
    } catch (error) {
      console.error('Error sending password reset email:', error);
      throw new Error('Failed to send password reset email');
    }
  }

  /**
   * Send a Firebase email-verification link. Used when someone signs in with
   * an email that belongs to an existing ECH account: the account is only
   * connected once they prove they own the mailbox.
   */
  async sendEmailVerificationEmail(email, verifyUrl, fullName) {
    const name = String(fullName || '').replace(/[<>&"]/g, '') || 'there';
    const safeUrl = String(verifyUrl).replace(/"/g, '&quot;');
    const msg = {
      to: email,
      from: { email: this.fromEmail, name: this.fromName },
      subject: 'Verify your email - Excellence Coaching Hub',
      text: `Hi ${name},\n\nPlease verify your email address to finish signing in to Excellence Coaching Hub:\n${verifyUrl}\n\nThen sign in again. If you did not try to sign in, you can ignore this email.`,
      html: `<div style="font-family:Arial,sans-serif;max-width:560px;margin:0 auto;padding:24px;color:#1f2937">
  <h2 style="color:#047857;margin-top:0">Verify your email</h2>
  <p>Hi ${name},</p>
  <p>Please verify your email address to finish signing in to Excellence Coaching Hub.</p>
  <p style="margin:28px 0"><a href="${safeUrl}" style="background:#047857;color:#fff;padding:12px 22px;border-radius:8px;text-decoration:none;font-weight:bold">Verify email</a></p>
  <p>After verifying, sign in again.</p>
  <p style="color:#6b7280;font-size:13px">If you did not try to sign in, you can ignore this email — nobody can access your account without this link.</p>
</div>`,
    };
    const response = await this.sgMail.send(msg);
    return { success: true, messageId: response[0].headers['x-message-id'] };
  }

  /**
   * Send password reset confirmation email
   */
  async sendPasswordResetConfirmationEmail(email, user) {
    try {
      const loginUrl = `${process.env.FRONTEND_URL || 'http://localhost:3000'}/login`;
      
      const msg = {
        to: email,
        from: {
          email: this.fromEmail,
          name: this.fromName
        },
        subject: 'Password Successfully Reset - Excellence Coaching Hub',
        html: this.getPasswordResetConfirmationTemplate(user.fullName, loginUrl)
      };

      const response = await this.sgMail.send(msg);
      console.log('Password reset confirmation email sent:', response[0].headers['x-message-id']);
      return { success: true, messageId: response[0].headers['x-message-id'] };
    } catch (error) {
      console.error('Error sending password reset confirmation email:', error);
      throw new Error('Failed to send password reset confirmation email');
    }
  }

  /**
   * Send welcome email to new users
   */
  async sendWelcomeEmail(email, user) {
    try {
      const loginUrl = `${process.env.FRONTEND_URL || 'http://localhost:3000'}/login`;
      
      const msg = {
        to: email,
        from: {
          email: this.fromEmail,
          name: this.fromName
        },
        subject: 'Welcome to Excellence Coaching Hub!',
        html: this.getWelcomeTemplate(user.fullName, loginUrl)
      };

      const response = await this.sgMail.send(msg);
      console.log('Welcome email sent:', response[0].headers['x-message-id']);
      return { success: true, messageId: response[0].headers['x-message-id'] };
    } catch (error) {
      console.error('Error sending welcome email:', error);
      throw new Error('Failed to send welcome email');
    }
  }

  /**
   * Password reset email template
   */
  getPasswordResetTemplate(fullName, resetUrl, resetToken) {
    return `
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Password Reset</title>
        ${this._getCommonStyles()}
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🔑 Password Reset</h1>
            </div>
            <div class="content">
                <h2>Hello ${fullName},</h2>
                <p>We received a request to reset your password. To proceed, please click the button below:</p>
                
                <div style="text-align: center;">
                    <a href="${resetUrl}" class="button">Reset Password</a>
                </div>
                
                <p>If the button doesn't work, copy and paste this link into your browser:</p>
                <p style="word-break: break-all; color: #00b09b; background: #eee; padding: 10px; border-radius: 5px; font-family: monospace; font-size: 14px;">${resetUrl}</p>
                
                <p>If you didn't request this, you can safely ignore this email. Your password will remain unchanged.</p>
            </div>
            <div class="footer">
                <p>© ${new Date().getFullYear()} Excellence Coaching Hub. All rights reserved.</p>
            </div>
        </div>
    </body>
    </html>
    `;
  }

  /**
   * Password reset confirmation template
   */
  getPasswordResetConfirmationTemplate(fullName, loginUrl) {
    return `
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Password Reset Successful</title>
        ${this._getCommonStyles()}
        <style>
            .success { 
                background: #d4edda; 
                border: 1px solid #c3e6cb; 
                padding: 15px; 
                border-radius: 5px; 
                margin: 20px 0;
                text-align: center;
                color: #155724;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>✅ Password Reset Successful</h1>
            </div>
            <div class="content">
                <h2>Hello ${fullName},</h2>
                
                <div class="success">
                    <h3>🎉 Your password has been successfully reset!</h3>
                    <p>You can now log in with your new password.</p>
                </div>
                
                <p>If you did not make this change, please contact our support team immediately.</p>
                
                <p>To access your account, please open the Excellence Coaching Hub app or visit our website to log in.</p>
                
                <div style="text-align: center;">
                    <a href="${loginUrl}" class="button">Go to Login</a>
                </div>
                
                <p>Thank you for choosing Excellence Coaching Hub!</p>
            </div>
            <div class="footer">
                <p>© ${new Date().getFullYear()} Excellence Coaching Hub. All rights reserved.</p>
                <p>Stay secure and keep learning!</p>
            </div>
        </div>
    </body>
    </html>
    `;
  }

  /**
   * Welcome email template
   */
  getWelcomeTemplate(fullName, loginUrl) {
    return `
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Welcome to Excellence Coaching Hub</title>
        ${this._getCommonStyles()}
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🎓 Welcome to Excellence Coaching Hub!</h1>
            </div>
            <div class="content">
                <h2>Hello ${fullName},</h2>
                <p>Welcome to Excellence Coaching Hub! We're excited to have you join our learning community.</p>
                
                <p>Your account has been successfully created and you're ready to start your learning journey.</p>
                
                <div class="features">
                    <h3>✨ What you can do now:</h3>
                    <ul>
                        <li>Browse our comprehensive courses</li>
                        <li>Enroll in subjects that interest you</li>
                        <li>Access exclusive learning materials</li>
                        <li>Track your progress and achievements</li>
                    </ul>
                </div>
                
                <p>To start learning, please open the Excellence Coaching Hub app or visit our website to log in to your account.</p>
                
                <div style="text-align: center;">
                    <a href="${loginUrl}" class="button">Go to Dashboard</a>
                </div>
                
                <p>If you have any questions or need assistance, our support team is always here to help.</p>
                <p>Happy learning!</p>
            </div>
            <div class="footer">
                <p>© ${new Date().getFullYear()} Excellence Coaching Hub. All rights reserved.</p>
                <p>Start your educational journey with us today!</p>
            </div>
        </div>
    </body>
    </html>
    `;
  }

  /**
   * Verify email configuration
   */
  async verifyConfiguration() {
    try {
      // Send a test email to verify configuration
      const msg = {
        to: 'test@example.com',
        from: {
          email: this.fromEmail,
          name: this.fromName
        },
        subject: 'Test Email Configuration',
        html: '<p>This is a test email to verify SendGrid configuration.</p>'
      };
      
      await this.sgMail.send(msg);
      console.log('✅ Email service configured successfully');
      return true;
    } catch (error) {
      console.error('❌ Email service configuration failed:', error);
      return false;
    }
  }

  /**
   * Send payment status email to user
   */
  async sendPaymentStatusEmail(email, user, payment, status) {
    try {
      const subject = this.getPaymentEmailSubject(status);
      const html = this.getPaymentStatusTemplate(user.fullName, payment, status);

      const msg = {
        to: email,
        from: {
          email: this.fromEmail,
          name: this.fromName
        },
        subject: subject,
        html: html
      };

      const response = await this.sgMail.send(msg);
      console.log(`Payment ${status} email sent to ${email}:`, response[0].headers['x-message-id']);
      return { success: true, messageId: response[0].headers['x-message-id'] };
    } catch (error) {
      console.error(`Error sending payment ${status} email:`, error);
      throw new Error(`Failed to send payment ${status} email`);
    }
  }

  /**
   * Send notification to admin when a user requests payment
   */
  async sendAdminPaymentNotification(adminEmails, user, payment, course) {
    try {
      const subject = `📢 New Payment Request - ${user.fullName} - Excellence Coaching Hub`;
      const html = this.getAdminPaymentNotificationTemplate(user, payment, course);

      // Ensure adminEmails is an array and include the default info email
      const recipients = Array.isArray(adminEmails) ? [...adminEmails] : [adminEmails];
      if (!recipients.includes('info@excellencecoachinghub.com')) {
        recipients.push('info@excellencecoachinghub.com');
      }

      // Filter out any invalid emails
      const validRecipients = [...new Set(recipients.filter(email => email && email.includes('@')))];

      const msg = {
        to: validRecipients,
        from: {
          email: this.fromEmail,
          name: this.fromName
        },
        subject: subject,
        html: html
      };

      const response = await this.sgMail.sendMultiple(msg);
      console.log('Admin payment notification emails sent:', validRecipients);
      return { success: true };
    } catch (error) {
      console.error('Error sending admin payment notification:', error);
      // We don't throw here to avoid breaking the student's payment initiation flow
      return { success: false, error: error.message };
    }
  }

  /**
   * Admin payment notification template
   */
  getAdminPaymentNotificationTemplate(user, payment, course) {
    return `
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>New Payment Request</title>
        ${this._getCommonStyles()}
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>📢 New Payment Request</h1>
            </div>
            <div class="content">
                <p>A user has initiated a payment request that requires your review.</p>
                
                <div class="details">
                    <h3>👤 User Details:</h3>
                    <div class="detail-row">
                        <span>Name:</span>
                        <strong>${user.fullName}</strong>
                    </div>
                    <div class="detail-row">
                        <span>Email:</span>
                        <strong>${user.email}</strong>
                    </div>
                    <div class="detail-row">
                        <span>Phone:</span>
                        <strong>${user.phone || 'N/A'}</strong>
                    </div>
                </div>
                
                <div class="details">
                    <h3>💳 Payment Details:</h3>
                    <div class="detail-row">
                        <span>Course:</span>
                        <strong>${course.title}</strong>
                    </div>
                    <div class="detail-row">
                        <span>Amount:</span>
                        <strong>${payment.currency} ${payment.amount.toLocaleString()}</strong>
                    </div>
                    <div class="detail-row">
                        <span>Method:</span>
                        <strong>${payment.paymentMethod}</strong>
                    </div>
                    <div class="detail-row">
                        <span>Transaction ID:</span>
                        <strong>${payment.transactionId}</strong>
                    </div>
                    <div class="detail-row">
                        <span>Contact Info:</span>
                        <strong>${payment.contactInfo}</strong>
                    </div>
                </div>
                
                <p>Please log in to the admin dashboard to verify and approve this payment.</p>
                
                <div style="text-align: center;">
                    <a href="${process.env.FRONTEND_URL || 'http://localhost:3000'}/admin" class="button">Go to Admin Dashboard</a>
                </div>
            </div>
            <div class="footer">
                <p>© ${new Date().getFullYear()} Excellence Coaching Hub Admin System</p>
            </div>
        </div>
    </body>
    </html>
    `;
  }

  /**
   * Get payment email subject based on status
   */
  getPaymentEmailSubject(status) {
    switch(status.toLowerCase()) {
      case 'approved':
      case 'completed':
        return 'Payment Approved - Excellence Coaching Hub';
      case 'rejected':
      case 'failed':
        return 'Payment Update - Excellence Coaching Hub';
      case 'pending':
        return 'Payment Pending - Excellence Coaching Hub';
      default:
        return 'Payment Status Update - Excellence Coaching Hub';
    }
  }

  /**
   * Payment status email template
   */
  getPaymentStatusTemplate(fullName, payment, status) {
    const statusMessages = {
      'approved': 'approved',
      'completed': 'approved',
      'rejected': 'rejected',
      'failed': 'rejected',
      'pending': 'pending review'
    };

    const statusMessage = statusMessages[status.toLowerCase()] || 'updated';
    const statusColor = status.toLowerCase() === 'approved' || status.toLowerCase() === 'completed' 
      ? '#28a745' 
      : status.toLowerCase() === 'rejected' || status.toLowerCase() === 'failed' 
        ? '#dc3545' 
        : '#ffc107';

    const statusIcon = status.toLowerCase() === 'approved' || status.toLowerCase() === 'completed' 
      ? '✅' 
      : status.toLowerCase() === 'rejected' || status.toLowerCase() === 'failed' 
        ? '❌' 
        : '⏳';

    return `
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Payment Status Update</title>
        ${this._getCommonStyles()}
        <style>
            .status-box {
              background: ${statusColor}20;
              border: 2px solid ${statusColor};
              text-align: center;
              border-left: 4px solid ${statusColor};
            }
            .status-icon {
              font-size: 48px;
              display: block;
              margin-bottom: 10px;
            }
            .status-text {
                color: ${statusColor};
                font-weight: bold;
                text-transform: uppercase;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>${statusIcon} Payment Update</h1>
            </div>
            <div class="content">
                <h2>Hello ${fullName},</h2>
                
                <div class="status-box">
                    <span class="status-icon">${statusIcon}</span>
                    <h3>Your payment has been <span class="status-text">${statusMessage}</span></h3>
                    <p>${this.getPaymentStatusMessage(payment, status)}</p>
                </div>
                
                <div class="payment-details">
                    <h3>💳 Payment Details:</h3>
                    <div class="detail-row">
                        <span>Transaction ID:</span>
                        <strong>${payment.transactionId || 'N/A'}</strong>
                    </div>
                    <div class="detail-row">
                        <span>Amount:</span>
                        <strong>${payment.currency || 'RWF'} ${payment.amount ? payment.amount.toLocaleString() : '0'}</strong>
                    </div>
                    <div class="detail-row">
                        <span>Status:</span>
                        <strong style="color: ${statusColor}; text-transform: capitalize;">${status}</strong>
                    </div>
                    <div class="detail-row">
                        <span>Date:</span>
                        <strong>${payment.updatedAt ? new Date(payment.updatedAt).toLocaleDateString() : new Date().toLocaleDateString()}</strong>
                    </div>
                </div>
                
                ${this.getPaymentNextSteps(status)}
                
                <p>If you have any questions about your payment, please contact our support team.</p>
            </div>
            <div class="footer">
                <p>© ${new Date().getFullYear()} Excellence Coaching Hub. All rights reserved.</p>
                <p>Secure payment processing powered by Excellence Coaching Hub.</p>
            </div>
        </div>
    </body>
    </html>
    `;
  }

  /**
   * Get payment status message based on status
   */
  getPaymentStatusMessage(payment, status) {
    switch(status.toLowerCase()) {
      case 'approved':
      case 'completed':
        return 'Your payment has been successfully processed. You now have access to your enrolled course.';
      case 'rejected':
      case 'failed':
        return 'Unfortunately, your payment could not be processed. Please try again or contact support.';
      case 'pending':
        return 'Your payment is currently under review. We will notify you once it has been processed.';
      default:
        return 'There has been an update to your payment status.';
    }
  }

  /**
   * Get next steps based on payment status
   */
  getPaymentNextSteps(status) {
    switch(status.toLowerCase()) {
      case 'approved':
      case 'completed':
        return `
        <h3>Next Steps:</h3>
        <ul>
          <li>You now have access to your enrolled course</li>
          <li>Check your enrolled courses section to start learning</li>
          <li>Contact our support if you encounter any issues accessing your course</li>
        </ul>
        `;
      case 'rejected':
      case 'failed':
        return `
        <h3>Next Steps:</h3>
        <ul>
          <li>Please try making the payment again</li>
          <li>Check your payment method details</li>
          <li>Contact our support team if the issue persists</li>
        </ul>
        `;
      case 'pending':
        return `
        <h3>Next Steps:</h3>
        <ul>
          <li>Your payment is being reviewed by our team</li>
          <li>You will receive another email once the review is complete</li>
          <li>Processing typically takes 24-48 hours</li>
        </ul>
        `;
      default:
        return '';
    }
  }

  /**
   * Send new course notification email to users
   */
  async sendNewCourseEmail(users, course) {
    try {
      const promises = users.map(async (user) => {
        const msg = {
          to: user.email,
          from: {
            email: this.fromEmail,
            name: this.fromName
          },
          subject: `🎉 New Course Available: ${course.title} - Excellence Coaching Hub`,
          html: this.getNewCourseTemplate(user.fullName, course)
        };

        try {
          const response = await this.sgMail.send(msg);
          console.log(`New course email sent to ${user.email}:`, response[0].headers['x-message-id']);
          return { success: true, email: user.email, messageId: response[0].headers['x-message-id'] };
        } catch (error) {
          console.error(`Error sending new course email to ${user.email}:`, error);
          return { success: false, email: user.email, error: error.message };
        }
      });

      const results = await Promise.all(promises);
      const successful = results.filter(result => result.success).length;
      const failed = results.filter(result => !result.success).length;

      console.log(`New course email campaign completed: ${successful} successful, ${failed} failed`);
      return { successful, failed, results };
    } catch (error) {
      console.error('Error sending new course emails:', error);
      throw new Error('Failed to send new course emails');
    }
  }

  /**
   * Send exam score notification email to user
   */
  async sendExamScoreNotification(email, user, exam, result) {
    try {
      const subject = result.passed 
        ? `🎉 Exam Passed - ${exam.title} - Excellence Coaching Hub` 
        : `📊 Exam Results - ${exam.title} - Excellence Coaching Hub`;

      const html = this.getExamScoreTemplate(user.fullName, exam, result);

      const msg = {
        to: email,
        from: {
          email: this.fromEmail,
          name: this.fromName
        },
        subject: subject,
        html: html
      };

      const response = await this.sgMail.send(msg);
      console.log(`Exam score notification email sent to ${email}:`, response[0].headers['x-message-id']);
      return { success: true, messageId: response[0].headers['x-message-id'] };
    } catch (error) {
      console.error('Error sending exam score notification email:', error);
      throw new Error('Failed to send exam score notification email');
    }
  }

  /**
   * Exam score notification email template
   */
  getExamScoreTemplate(fullName, exam, result) {
    const statusMessage = result.passed ? 'PASSED' : 'DID NOT PASS';
    const statusColor = result.passed ? '#28a745' : '#dc3545';
    const statusIcon = result.passed ? '🎉' : '❌';

    return `
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Exam Results - ${exam.title}</title>
        ${this._getCommonStyles()}
        <style>
            .status-box {
              background: ${statusColor}20;
              border: 2px solid ${statusColor};
              text-align: center;
              border-left: 4px solid ${statusColor};
            }
            .status-icon {
              font-size: 48px;
              display: block;
              margin-bottom: 10px;
            }
            .score-display {
              text-align: center;
              margin: 20px 0;
              padding: 20px;
              background: #f8f9fa;
              border-radius: 10px;
            }
            .score-number {
              font-size: 48px;
              font-weight: bold;
              color: ${statusColor};
              display: block;
            }
            .score-label {
              font-size: 16px;
              color: #666;
              display: block;
              text-transform: uppercase;
              letter-spacing: 1px;
            }
            .score-percentage {
              font-size: 32px;
              font-weight: bold;
              color: ${statusColor};
              display: block;
              margin-top: 5px;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>${statusIcon} Exam Results</h1>
            </div>
            <div class="content">
                <h2>Hello ${fullName},</h2>
                
                <div class="status-box">
                    <span class="status-icon">${statusIcon}</span>
                    <h3>You ${statusMessage} the exam: <strong>${exam.title}</strong></h3>
                    <p>${result.message}</p>
                </div>
                
                <div class="results-card">
                    <div class="score-display">
                        <span class="score-label">Points Earned</span>
                        <span class="score-number">${result.score} / ${result.totalPoints}</span>
                        <span class="score-percentage">${result.percentage.toFixed(1)}%</span>
                    </div>
                    
                    <div class="result-details">
                        <h3>📊 Exam Details:</h3>
                        <div class="detail-row">
                            <span>Exam:</span>
                            <strong>${exam.title}</strong>
                        </div>
                        <div class="detail-row">
                            <span>Course:</span>
                            <strong>${exam.courseId?.title || 'N/A'}</strong>
                        </div>
                        <div class="detail-row">
                            <span>Total Points:</span>
                            <strong>${result.totalPoints}</strong>
                        </div>
                        <div class="detail-row">
                            <span>Your Score:</span>
                            <strong>${result.score}</strong>
                        </div>
                        <div class="detail-row">
                            <span>Status:</span>
                            <strong style="color: ${statusColor};">${result.passed ? 'PASSED' : 'FAILED'}</strong>
                        </div>
                    </div>
                    
                    ${result.passed ? `
                    <div class="next-steps">
                        <h3>✅ Next Steps:</h3>
                        <ul>
                            <li>Congratulations on your success!</li>
                            <li>Check your course progress in the app</li>
                            <li>Continue to the next modules</li>
                            <li>Explore additional resources</li>
                        </ul>
                    </div>
                    ` : `
                    <div class="next-steps">
                        <h3>📝 Next Steps:</h3>
                        <ul>
                            <li>Review the material covered in this exam</li>
                            <li>Use the study resources in the app</li>
                            <li>Retake the exam when you're ready</li>
                            <li>Contact your instructor if you need help</li>
                        </ul>
                    </div>
                    `}
                    
                    <p>To view your course progress, please open the Excellence Coaching Hub app or visit our website.</p>
                </div>
                
                <p>Keep up the great work on your educational journey!</p>
            </div>
            <div class="footer">
                <p>© ${new Date().getFullYear()} Excellence Coaching Hub. All rights reserved.</p>
                <p>Thank you for your dedication to learning and growth.</p>
            </div>
        </div>
    </body>
    </html>
    `;
  }

  /**
   * Send enrollment confirmation email to user
   */
  async sendEnrollmentConfirmation(email, user, course) {
    try {
      const msg = {
        to: email,
        from: {
          email: this.fromEmail,
          name: this.fromName
        },
        subject: `🎉 Enrollment Confirmation - ${course.title} - Excellence Coaching Hub`,
        html: this.getEnrollmentConfirmationTemplate(user.fullName, course)
      };

      const response = await this.sgMail.send(msg);
      console.log(`Enrollment confirmation email sent to ${email}:`, response[0].headers['x-message-id']);
      return { success: true, messageId: response[0].headers['x-message-id'] };
    } catch (error) {
      console.error('Error sending enrollment confirmation email:', error);
      throw new Error('Failed to send enrollment confirmation email');
    }
  }

  /**
   * Enrollment confirmation email template
   */
  getEnrollmentConfirmationTemplate(fullName, course) {
    return `
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Enrollment Confirmation - ${course.title}</title>
        ${this._getCommonStyles()}
        <style>
            .course-info {
              background: #e8f4fd;
              border-left: 4px solid #007bff;
              color: #0c5460;
            }
            .next-steps {
              background: #fff3cd;
              border-left: 4px solid #ffc107;
              color: #856404;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🎉 Enrollment Confirmed</h1>
            </div>
            <div class="content">
                <h2>Hello ${fullName},</h2>
                
                <div class="welcome-card">
                    <h3>Congratulations! You've been enrolled in:</h3>
                    <h2 style="color: #00b09b; margin: 15px 0; font-size: 24px;">${course.title}</h2>
                    <p>Your enrollment has been successfully processed. You now have access to all course materials, including video lectures, assignments, quizzes, and additional resources.</p>
                </div>
                
                <div class="course-info">
                    <h3>📚 Course Information:</h3>
                    <div class="detail-row">
                        <span>Course Title:</span>
                        <strong>${course.title}</strong>
                    </div>
                    <div class="detail-row">
                        <span>Enrollment Date:</span>
                        <strong>${new Date().toLocaleDateString()}</strong>
                    </div>
                    <div class="detail-row">
                        <span>Status:</span>
                        <strong style="color: #28a745;">Active</strong>
                    </div>
                </div>
                
                <div class="next-steps">
                    <h3>🚀 Next Steps:</h3>
                    <ol>
                        <li>Open the Excellence Coaching Hub app on your device</li>
                        <li>Navigate to the "My Courses" section</li>
                        <li>Find "${course.title}" in your course list</li>
                        <li>Begin with the first module or introduction section</li>
                        <li>Complete lessons at your own pace</li>
                    </ol>
                </div>
                
                <p>We're excited to have you join us in this learning journey! Our platform offers comprehensive educational resources designed to help you succeed.</p>
                
                <div style="text-align: center;">
                    <a href="${process.env.FRONTEND_URL || 'http://localhost:3000'}/my-courses" class="button">Go to My Courses</a>
                </div>
                
                <p>If you have any questions or need assistance, please don't hesitate to reach out to our support team.</p>
                
                <p>Happy learning!</p>
            </div>
            <div class="footer">
                <p>© ${new Date().getFullYear()} Excellence Coaching Hub. All rights reserved.</p>
                <p>You received this email because you enrolled in a course on Excellence Coaching Hub.</p>
            </div>
        </div>
    </body>
    </html>
    `;
  }

  /**
   * New course notification email template
   */
  getNewCourseTemplate(fullName, course) {
    const courseUrl = `${process.env.FRONTEND_URL || 'http://localhost:3000'}/courses/${course._id || course.id}`;

    return `
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>New Course Available - ${course.title}</title>
        ${this._getCommonStyles()}
        <style>
            .course-title {
              color: #00b09b;
              font-size: 24px;
              margin: 0 0 10px 0;
            }
            .course-meta {
              display: flex;
              gap: 20px;
              margin: 15px 0;
              flex-wrap: wrap;
              background: #f8f9fa;
              padding: 15px;
              border-radius: 8px;
            }
            .course-meta-item {
              display: flex;
              align-items: center;
              gap: 5px;
              font-size: 14px;
              color: #666;
            }
            .features { 
                background: white; 
                padding: 20px; 
                border-radius: 8px; 
                margin: 20px 0;
                border-left: 4px solid #96c93d;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>📚 New Course Available!</h1>
            </div>
            <div class="content">
                <h2>Hello ${fullName},</h2>
                
                <p>We're excited to announce a new course has been added to Excellence Coaching Hub that we think you'll love!</p>
                
                <div class="course-card">
                    <h2 class="course-title">${course.title}</h2>
                    
                    <p>${course.description || 'Join our newest course and enhance your skills!'}</p>
                    
                    <div class="course-meta">
                        <div class="course-meta-item">
                            <span>💰 Price:</span>
                            <strong>${course.currency || 'RWF'} ${course.price ? course.price.toLocaleString() : 'Free'}</strong>
                        </div>
                        <div class="course-meta-item">
                            <span>⏱️ Duration:</span>
                            <strong>${course.duration || 'N/A'} hours</strong>
                        </div>
                        <div class="course-meta-item">
                            <span>🎓 Level:</span>
                            <strong>${course.level || 'All Levels'}</strong>
                        </div>
                    </div>
                    
                    ${course.learningObjectives && course.learningObjectives.length > 0 ? `
                    <div class="features">
                        <h3>✨ What You'll Learn:</h3>
                        <ul>
                            ${course.learningObjectives.slice(0, 3).map(obj => `<li>${obj}</li>`).join('')}
                        </ul>
                    </div>
                    ` : ''}
                    
                    <div style="text-align: center;">
                        <a href="${courseUrl}" class="button">View Course Details</a>
                    </div>
                </div>
                
                <p>Stay ahead of the curve by enrolling in our latest offerings. New courses are added regularly, so keep checking back!</p>
                
                <p>Happy learning!</p>
            </div>
            <div class="footer">
                <p>© ${new Date().getFullYear()} Excellence Coaching Hub. All rights reserved.</p>
                <p>Continue your educational journey with us.</p>
            </div>
        </div>
    </body>
    </html>
    `;
  }
}

module.exports = new EmailService();