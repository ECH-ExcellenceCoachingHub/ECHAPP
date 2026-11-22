import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/push_notification_service.dart';

import '../data/repositories/auth_repository.dart';
import '../config/storage_manager.dart';

class FCMTokenService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final AuthRepository _authRepository = AuthRepository();
  static final StorageManager _storageManager = StorageManager();
  
  // Update FCM token on backend and Firestore.
  //
  // The two stores are written independently. They used to share one try block
  // with Firestore first, so when Firestore security rules denied the write the
  // exception skipped the MongoDB save as well and the token was stored nowhere
  // at all — leaving the user unreachable by push. MongoDB now goes first
  // because the backend push sender falls back to it, and neither failure can
  // take the other down.
  static Future<bool> updateFCMToken(String token) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('No authenticated user, skipping FCM token update');
      return false;
    }

    var storedSomewhere = false;

    // 1. Backend/MongoDB — the store the push sender falls back to.
    try {
      final accessToken = await _storageManager.getAccessToken();
      if (accessToken != null) {
        await _authRepository.updateFCMToken(accessToken, token);
        storedSomewhere = true;
        print('FCM token updated successfully in MongoDB');
      } else {
        print('No access token yet, skipping MongoDB FCM token update');
      }
    } catch (apiError) {
      print('Error updating FCM token in MongoDB: $apiError');
    }

    // 2. Firestore — preferred by the sender when present, but best-effort:
    // security rules can legitimately deny this without breaking push.
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
        'platform': _getPlatformName(),
      }, SetOptions(merge: true));
      storedSomewhere = true;
      print('FCM token updated successfully in Firestore');
    } catch (e) {
      print('Error updating FCM token in Firestore (rules may deny it): $e');
    }

    if (!storedSomewhere) {
      print('WARNING: FCM token could not be stored in either backend — push notifications will not reach this device');
    }
    return storedSomewhere;
  }

  static String _getPlatformName() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return 'android';
      case TargetPlatform.iOS: return 'ios';
      case TargetPlatform.macOS: return 'macos';
      case TargetPlatform.windows: return 'windows';
      case TargetPlatform.linux: return 'linux';
      default: return 'unknown';
    }
  }
  
  // Initialize and sync FCM token
  static Future<void> initializeAndSyncToken() async {
    try {
      // Listen for token refreshes
      PushNotificationService.onTokenRefresh((token) {
        updateFCMToken(token);
      });

      // Get current FCM token
      final token = await PushNotificationService.getFCMToken();
      
      if (token != null) {
        print('FCM token available: ${token != null}');
        await updateFCMToken(token);
        await _subscribeToTopics();
      }
    } catch (e) {
      print('Error initializing FCM token sync: $e');
    }
  }
  
  // Subscribe to relevant topics
  static Future<void> _subscribeToTopics() async {
    try {
      // Subscribe to general notifications
      await PushNotificationService.subscribeToTopic('general');
      
      // Subscribe to course-related notifications
      await PushNotificationService.subscribeToTopic('courses');
      
      // Subscribe to exam notifications
      await PushNotificationService.subscribeToTopic('exams');
      
      // Subscribe to payment notifications
      await PushNotificationService.subscribeToTopic('payments');
      
      print('Subscribed to notification topics');
    } catch (e) {
      print('Error subscribing to topics: $e');
    }
  }
  
  // Unsubscribe from topics
  static Future<void> unsubscribeFromTopics() async {
    try {
      await PushNotificationService.unsubscribeFromTopic('general');
      await PushNotificationService.unsubscribeFromTopic('courses');
      await PushNotificationService.unsubscribeFromTopic('exams');
      await PushNotificationService.unsubscribeFromTopic('payments');
      
      print('Unsubscribed from notification topics');
    } catch (e) {
      print('Error unsubscribing from topics: $e');
    }
  }
}