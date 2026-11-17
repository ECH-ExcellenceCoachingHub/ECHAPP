import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/l10n/app_localizations.dart';
import 'package:excellencecoachinghub/services/api/eexams_service.dart';

// Top-level background handler (MUST be outside class for FCM to work)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message: ${message.notification?.title}');
  
  // Initialize Flutter bindings for background execution
  // This is required for using Flutter plugins in background isolates
  // Note: On Android, this may not work properly due to OS limitations
  // For reliable background notifications, rely on FCM's system notifications
}

class PushNotificationService {
  static FirebaseMessaging get _firebaseMessaging => FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static BuildContext? _context;

  // Optional callback: set this to persist local notifications to the
  // backend so they appear on the Notifications page.
  static Future<void> Function({required String title, required String message, required String type})? onNotificationCreated;

  // Optional callback: called when a backend FCM message is received in
  // foreground so the Notifications page can reload its list immediately.
  static Future<void> Function()? onFcmMessageReceived;

  // Set context for navigation
  static void setContext(BuildContext context) {
    _context = context;
  }
  
  // Initialize push notifications
  static Future<void> initialize() async {
    // Only initialize if not on Windows
    if (defaultTargetPlatform == TargetPlatform.windows) {
      debugPrint('Push notifications not supported on Windows');
      return;
    }
    
    try {
      // 1. Request Permission
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        provisional: false,
        sound: true,
      );
      
      print('User granted permission: ${settings.authorizationStatus}');
      
      // 2. Create Android Notification Channel (Professional requirement)
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // title
        description: 'This channel is used for important notifications.', // description
        importance: Importance.max,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 3. Initialize local notifications
      await _initializeLocalNotifications(channel);
      
      // 4. Handle background messages (use top-level function)
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      
      // 5. Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message in foreground: ${message.notification?.title}');
        _showLocalNotification(message, channel);
        // Reload the in-app Notifications page so it reflects the new entry.
        onFcmMessageReceived?.call();
      });
      
      // 6. Handle when app is opened from terminated state
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('App opened from terminated state: ${message.notification?.title}');
        _handleNotificationTap(message);
      });
      
      // 7. Handle initial message when app is opened from notification
      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        print('App opened from notification: ${initialMessage.notification?.title}');
        _handleNotificationTap(initialMessage);
      }
      
      // 8. Schedule daily reminder
      await scheduleDailyReminder(_context);
      
    } catch (e) {
      print('Error initializing push notifications: $e');
    }
  }
  
  // Initialize local notifications
  static Future<void> _initializeLocalNotifications(AndroidNotificationChannel channel) async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle local notification tap
        if (response.payload != null && response.payload!.isNotEmpty) {
          _handleRouteNavigation(response.payload!);
        }
      },
    );
  }
  
  // Show local notification
  static Future<void> _showLocalNotification(RemoteMessage message, AndroidNotificationChannel channel) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && !kIsWeb) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data['route'] ?? '',
      );
    }
  }
  
  // Handle notification tap from FCM
  static void _handleNotificationTap(RemoteMessage message) {
    final route = message.data['route'];
    if (route != null) {
      _handleRouteNavigation(route, data: message.data);
    }
  }

  // Handle route navigation
  static void _handleRouteNavigation(String route, {Map<String, dynamic>? data}) {
    if (_context == null) {
      print('Cannot navigate: Context is null');
      return;
    }

    print('Navigating to route: $route with data: $data');

    try {
      // eexams.net result → open that result on eexams, already signed in.
      final reviewPath = data?['reviewPath'];
      if (data?['source'] == 'eexams' && reviewPath is String && reviewPath.startsWith('/')) {
        EexamsService().open(redirect: reviewPath).catchError((_) {
          _context?.push('/exams/history');
          return false;
        });
        return;
      }
      if (route.startsWith('/learning/') && data?['courseId'] != null) {
        _context!.push('/learning/${data!['courseId']}');
      } else if (route == '/notifications') {
        _context!.push('/notifications');
      } else if (route == '/my-courses') {
        _context!.push('/my-courses');
      } else if (route.startsWith('/course/') && data?['id'] != null) {
        _context!.push('/course/${data!['id']}');
      } else {
        // Fallback to direct route if possible
        _context!.push(route);
      }
    } catch (e) {
      print('Error during notification navigation: $e');
      // If push fails, try go
      _context!.go(route);
    }
  }

  // Get FCM token
  static Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  // Listen for token refresh
  static void onTokenRefresh(Function(String) onRefresh) {
    _firebaseMessaging.onTokenRefresh.listen(onRefresh);
  }
  
  // Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }
  
  // Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }

  // Schedule daily reminder (Duolingo style)
  static Future<void> scheduleDailyReminder([BuildContext? context]) async {
    if (defaultTargetPlatform == TargetPlatform.windows) return;

    // Create the daily reminder channel first
    const AndroidNotificationChannel reminderChannel = AndroidNotificationChannel(
      'daily_reminder_channel',
      'Daily Reminders',
      description: 'Notifications to remind you to keep learning',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(reminderChannel);

    final reminder = _getRandomReminder(context);
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_reminder_channel',
      'Daily Reminders',
      channelDescription: 'Notifications to remind you to keep learning',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: 1,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Using periodicallyShow as a simple way to schedule daily without timezone package
    // In a real app, you'd use tz.TZDateTime for specific time of day
    await _localNotifications.periodicallyShow(
      999, // Unique ID for daily reminder
      reminder['title'],
      reminder['body'],
      RepeatInterval.daily,
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: '/dashboard',
    );
    
    print('Daily reminder scheduled: ${reminder['title']}');
  }

  // Clear all notifications and badges
  static Future<void> clearNotifications() async {
    if (defaultTargetPlatform == TargetPlatform.windows) return;
    
    await _localNotifications.cancelAll();
    // For iOS/Android badges, FCM usually handles it or you need a plugin
    // But clearing notifications helps
    print('Notifications cleared');
  }

  // Send congratulatory notification for achievements
  static Future<void> sendCongratulatoryNotification(String title, String body) async {
    if (defaultTargetPlatform == TargetPlatform.windows) return;

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: 1,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch % 100000,
        title,
        body,
        platformDetails,
        payload: '/dashboard',
      );
      await onNotificationCreated?.call(
        title: title,
        message: body,
        type: 'achievement',
      );
    } catch (e) {
      print('Error sending congratulatory notification: $e');
    }
  }

  // ─── Live Session Notifications ──────────────────────────────────────────

  /// Call this after fetching upcoming/live sessions.
  /// - Schedules a "starting soon" notification 15 min before each scheduled session.
  /// - Fires an immediate "session is live" notification for any live session.
  /// - Fires "ready to start" notification for sessions where time has passed but not started.
  static Future<void> scheduleLiveSessionNotifications(
      List<dynamic> sessions, {bool isTeacher = false}) async {
    if (defaultTargetPlatform == TargetPlatform.windows) return;

    debugPrint('📅 Scheduling notifications for ${sessions.length} sessions (teacher: $isTeacher)');

    const AndroidNotificationChannel liveChannel = AndroidNotificationChannel(
      'live_session_channel',
      'Live Sessions',
      description: 'Notifications for scheduled and live class sessions',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(liveChannel);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'live_session_channel',
      'Live Sessions',
      channelDescription: 'Notifications for scheduled and live class sessions',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const NotificationDetails details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    // Initialize timezone once
    try {
      tz_data.initializeTimeZones();
    } catch (e) {
      debugPrint('Failed to initialize timezones: $e');
    }

    // Track which session IDs we have already notified to avoid duplicates
    final Set<String> fired = {};
    int scheduledCount = 0;
    int liveCount = 0;
    int readyToStartCount = 0;

    for (final session in sessions) {
      final String id = session.id as String;
      final String title = session.title as String;
      final bool isLive = session.isLive as bool;
      final bool isCancelled = session.isCancelled as bool;
      final DateTime scheduledAt = session.scheduledAt as DateTime;
      final notifId = id.hashCode.abs() % 100000;

      if (fired.contains(id)) continue;
      fired.add(id);

      // Skip cancelled sessions
      if (isCancelled) {
        debugPrint('⏭️ Skipping cancelled session: $title');
        continue;
      }

      final int duration = session.duration as int;
      final DateTime expectedEnd = scheduledAt.add(Duration(minutes: duration));
      final now = DateTime.now();

      if (isLive) {
        // Fire immediately — session is live right now
        debugPrint('🔴 Live session notification: $title');
        await _localNotifications.show(
          notifId,
          '🔴 Live Now: $title',
          isTeacher ? 'Your class is live! Start teaching now.' : 'Your class is live! Tap to join.',
          details,
          payload: isTeacher ? '/teacher/sessions' : '/dashboard',
        );
        liveCount++;
      } else if (expectedEnd.isBefore(now)) {
        // Session has fully ended and the student never joined (status never became live)
        // Only show if it ended recently (within last hour) to avoid spam
        final hoursSinceEnd = now.difference(expectedEnd).inHours;
        if (hoursSinceEnd < 1) {
          debugPrint('📺 Missed session notification: $title');
          await _localNotifications.show(
            notifId + 10000,
            'You missed a live session 📺',
            '"$title" has ended. Open the app to check for recordings or upcoming sessions.',
            details,
            payload: '/my-courses',
          );
        }
      } else if (isTeacher && scheduledAt.isBefore(now.add(const Duration(minutes: 5)))) {
        // Teacher: Ready to start notification (time has passed but session not live yet)
        debugPrint('⚡ Ready to start notification: $title');
        await _localNotifications.show(
          notifId + 20000,
          '⚡ Ready to Start: $title',
          'It\'s time to start your class! Tap to begin.',
          details,
          payload: '/teacher/sessions',
        );
        readyToStartCount++;
      } else {
        // Schedule 15 min before start (only if reminder time is still in the future)
        final remind = scheduledAt.subtract(const Duration(minutes: 15));
        if (remind.isAfter(now)) {
          try {
            final local = tz.local;
            final tzRemind = tz.TZDateTime.from(remind, local);
            await _localNotifications.zonedSchedule(
              notifId + 50000,
              '📅 Starting Soon: $title',
              'Your live class starts in 15 minutes.',
              tzRemind,
              details,
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              payload: '/dashboard',
            );
            debugPrint('⏰ Scheduled reminder for: $title at $remind');
            scheduledCount++;
          } catch (e) {
            debugPrint('Failed to schedule notification for $title: $e');
          }
        } else {
          debugPrint('⏭️ Skipping reminder for $title (reminder time has passed)');
        }
      }
    }

    debugPrint('✅ Notifications scheduled: $scheduledCount reminders, $liveCount live alerts');
  }

  // Get a random Duolingo-style reminder (translatable when context is available)
  static Map<String, String> _getRandomReminder([BuildContext? context]) {
    final l10n = context != null ? AppLocalizations.of(context) : null;
    final reminders = [
      {
        'title': l10n?.reminderDontBreakStreak ?? 'Don\'t break your streak! 🔥',
        'body': l10n?.reminderDontBreakStreakBody ?? 'Your brain misses learning. Just 5 minutes today?',
      },
      {
        'title': l10n?.reminderMissYou ?? 'Excellence Hub misses you 🥺',
        'body': l10n?.reminderMissYouBody ?? 'Ready to master that next lesson? Come on back!',
      },
      {
        'title': l10n?.reminderGoalWaiting ?? 'Your goal is waiting! 🎯',
        'body': l10n?.reminderGoalWaitingBody ?? 'Success doesn\'t happen by itself. Let\'s learn something new.',
      },
      {
        'title': l10n?.reminderQuick ?? 'Quick reminder... ⏰',
        'body': l10n?.reminderQuickBody ?? 'Consistency is the key to mastery. See you in the app!',
      },
      {
        'title': l10n?.reminderPsst ?? 'Psst... 🎓',
        'body': l10n?.reminderPsstBody ?? 'A little bird told me you haven\'t learned anything today.',
      },
      {
        'title': l10n?.reminderMomentum ?? 'Keep the momentum! 🚀',
        'body': l10n?.reminderMomentumBody ?? 'You were doing so well! Don\'t stop now.',
      },
    ];

    return reminders[DateTime.now().millisecond % reminders.length];
  }
}
