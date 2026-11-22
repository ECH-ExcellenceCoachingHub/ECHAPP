# Push Notification System Implementation

## Overview
This document describes the complete push notification system implementation for the Excellence Coaching Hub app that sends notifications to users' mobile devices.

## System Architecture

### 1. Frontend (Flutter/Dart)
- **Firebase Messaging**: Handles receiving push notifications from FCM
- **Local Notifications**: Shows notifications when app is in foreground
- **Token Management**: Stores and syncs FCM tokens with backend

### 2. Backend (Node.js/Express)
- **Firebase Admin SDK**: Sends push notifications via FCM
- **Notification Controller**: Manages notification creation and delivery
- **User Model**: Stores FCM tokens for each user

## Key Components

### Frontend Services

#### 1. PushNotificationService (`lib/services/push_notification_service.dart`)
Handles all push notification functionality:
- Initialize Firebase Messaging
- Request notification permissions
- Handle foreground/background notifications
- Show local notifications
- Manage notification taps

#### 2. FCMTokenService (`lib/services/fcm_token_service.dart`)
Manages FCM token synchronization:
- Get current FCM token
- Update token on backend
- Subscribe to notification topics
- Handle token refresh

#### 3. Main App Integration (`lib/main.dart`)
- Initialize push notifications on app startup
- Sync FCM token with backend
- Subscribe to relevant topics

### Backend Components

#### 1. Notification Controller (`backend/src/controllers/notification.controller.js`)
Core notification logic:
- Create database notifications
- Send push notifications via FCM
- Send notifications to topics
- Helper methods for specific notification types

#### 2. Notification Routes (`backend/src/routes/notification.routes.js`)
API endpoints:
- `POST /api/notifications` - Create notification with optional push
- `POST /api/notifications/send-push` - Send push to specific user
- `POST /api/notifications/send-topic` - Send push to topic
- `PUT /api/notifications/fcm-token` - Update user's FCM token

#### 3. User Model (`backend/src/models/User.js`)
Extended to include:
- `fcmToken` field for storing user's device token

## Notification Types

### Automatic Push Notifications
The system automatically sends push notifications for:
- **Payment Notifications**: When payments are processed
- **Course Enrollment**: When users enroll in courses
- **Exam Results**: When exam results are available
- **Achievements**: When users unlock achievements

### Manual Push Notifications
Admins can send push notifications via:
- Direct user targeting
- Topic-based broadcasting
- Custom notification creation

## Topics System
Users are automatically subscribed to relevant topics:
- `general` - General announcements
- `courses` - Course-related notifications
- `exams` - Exam notifications
- `payments` - Payment notifications

## Implementation Flow

### 1. App Startup
1. Firebase is initialized
2. Push notification permissions are requested
3. FCM token is retrieved
4. Token is synced with backend
5. User subscribes to notification topics

### 2. Receiving Notifications
1. **Foreground**: Local notification is shown
2. **Background**: System notification is shown
3. **Terminated**: Notification appears in system tray

### 3. Notification Tap Handling
1. App opens from notification
2. Navigation data is extracted
3. User is directed to relevant screen

## API Usage Examples

### Send Push to Specific User
```javascript
POST /api/notifications/send-push
{
  "userId": "user123",
  "title": "New Message",
  "message": "You have a new message",
  "data": {
    "route": "/messages",
    "messageId": "msg456"
  }
}
```

### Send Push to Topic
```javascript
POST /api/notifications/send-topic
{
  "topic": "courses",
  "title": "New Course Available",
  "message": "Check out our new mathematics course",
  "data": {
    "route": "/courses",
    "courseId": "course789"
  }
}
```

### Create Notification with Push
```javascript
POST /api/notifications
{
  "userId": "user123",
  "title": "Payment Successful",
  "message": "Your payment has been processed",
  "type": "payment",
  "sendPush": true
}
```

## Testing

### Backend Testing
```bash
# Test notification controller
node -c backend/src/controllers/notification.controller.js

# Test notification routes
node -c backend/src/routes/notification.routes.js

# Test user model
node -c backend/src/models/User.js
```

### Frontend Testing
```bash
# Install dependencies
cd frontend
flutter pub get

# Run the app
flutter run
```

## Security Considerations

1. **Authentication**: All notification endpoints require valid JWT tokens
2. **Authorization**: Users can only access their own notifications
3. **Token Validation**: FCM tokens are validated before sending
4. **Rate Limiting**: Consider implementing rate limits for notification sending

## Future Enhancements

1. **Rich Notifications**: Add images and action buttons
2. **Notification Preferences**: Allow users to customize notification types
3. **Analytics**: Track notification delivery and engagement
4. **Scheduling**: Send scheduled notifications
5. **Localization**: Multi-language notification support

## Troubleshooting

### Common Issues

1. **Notifications not receiving**:
   - Check FCM token is properly stored
   - Verify Firebase configuration
   - Ensure proper topic subscriptions

2. **Permission Issues**:
   - Request permissions properly on iOS
   - Check Android manifest configuration
   - Verify notification settings in device

3. **Delivery Failures**:
   - Check Firebase project configuration
   - Verify server key permissions
   - Monitor Firebase console for errors

## Dependencies

### Frontend
- `firebase_messaging: ^15.1.3`
- `flutter_local_notifications: ^17.2.3`
- `firebase_core: ^3.6.0`
- `firebase_auth: ^5.3.1`

### Backend
- `firebase-admin: ^12.0.0` (already configured)
- `express` (existing)
- `mongoose` (existing)