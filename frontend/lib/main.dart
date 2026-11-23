import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/presentation/router/app_router.dart';
import 'package:excellencecoachinghub/services/firebase_auth_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:excellencecoachinghub/l10n/app_localizations.dart';
import 'package:excellencecoachinghub/l10n/kinyarwanda_material_localizations.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/localization_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/notification_provider.dart';
import 'package:excellencecoachinghub/services/download_service.dart';
import 'package:excellencecoachinghub/services/push_notification_service.dart';
import 'package:excellencecoachinghub/services/fcm_token_service.dart';
import 'package:excellencecoachinghub/services/session_tracking_service.dart';
import 'package:excellencecoachinghub/services/connectivity_service.dart';
import 'package:excellencecoachinghub/presentation/screens/settings/settings_screen.dart';
import 'package:media_kit/media_kit.dart';

/// Error tracking: off unless the build passes --dart-define=SENTRY_DSN=...
const _sentryDsn = String.fromEnvironment('SENTRY_DSN');


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  
  // Enable gesture resampling for smoother touch interactions
  GestureBinding.instance.resamplingEnabled = true;
  
  // Set system UI mode to hide navigation buttons for mobile
  if (!kIsWeb) {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [],
    );
    
    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
  
  // Release builds never write logs: print/debugPrint output ends up in the
  // phone's system log, where tokens or personal data must not appear.
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  if (_sentryDsn.isNotEmpty) {
    // Sentry disabled: sentry_flutter dependency removed to allow Windows/MSIX builds.
  }

  // Use runZonedGuarded to catch any unhandled errors that might crash the app
  await runZonedGuarded(() async {
    try {
      debugPrint('Main: Starting app initialization...');

      // Initialize Firebase in the background — do not block first paint.
      // The splash screen shows immediately; Firebase-dependent auth restoration
      // awaits this future inside the auth provider.
      FirebaseAuthService.initializeFirebase().catchError((e, st) {
        debugPrint('Main: Firebase background init failed: $e');
      });

      // Automated UI tests (web): expose the semantics tree to the browser.
      if (const bool.fromEnvironment('ENABLE_SEMANTICS')) {
        SemanticsBinding.instance.ensureSemantics();
      }

      // Run the app immediately so the splash screen paints without waiting
      // on Firebase or any other service.
      runApp(
        const ProviderScope(
          child: ExcellenceCoachingHubApp(),
        ),
      );

      // Initialize remaining services in the background (non-blocking).
      _initializeBackgroundServices();
    } catch (e, stack) {
      // Handle startup errors gracefully
      debugPrint('FATAL ERROR during app startup: $e');
      debugPrint('Stack trace: $stack');
      
      _showErrorApp(e.toString());
    }
  }, (error, stack) {
    debugPrint('UNHANDLED ERROR: $error');
    debugPrint('Stack trace: $stack');
  }, zoneSpecification: ZoneSpecification(
    // Silence print() in release builds (see debugPrint above).
    print: (self, parent, zone, line) {
      if (!kReleaseMode) parent.print(zone, line);
    },
  ));
}

void _showErrorApp(String error) {
  runApp(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 64),
                const SizedBox(height: 20),
                const Text(
                  'App Failed to Start',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Text(
                  'Error: $error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => main(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

// Background initialization that does not block app startup
Future<void> _initializeBackgroundServices() async {
  try {
    // Must be ready before the router resolves its first route: the offline
    // guard redirects online-only screens to Downloads based on this state.
    await ConnectivityService.instance.initialize();

    // Initialize push notifications only on supported platforms (not Windows)
    if (defaultTargetPlatform != TargetPlatform.windows) {
      await PushNotificationService.initialize();
    }

    // Initialize FCM token sync only on supported platforms
    if (defaultTargetPlatform != TargetPlatform.windows) {
      await FCMTokenService.initializeAndSyncToken();
    }

    // Initialize download service (non-blocking)
    final downloadService = DownloadService();
    await downloadService.init();

    debugPrint('Background services initialized successfully');
  } catch (e) {
    debugPrint('Error initializing background services: $e');
    // Don't crash the app if background services fail
  }
}

class ExcellenceCoachingHubApp extends ConsumerWidget {
  const ExcellenceCoachingHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    // Signed out while using the app (session ended on the server, e.g. a school
    // student signed in on another device or the school day ended): leave the
    // current screen for the sign-in screen, which shows the reason.
    ref.listen(authProvider, (prev, next) {
      final was = prev?.user;
      if (was == null || next.user != null || next.isLoading) return;
      final schoolAccount = was.isSchoolStudent || was.role == 'parent';
      AppRouter.routerInstance.go(schoolAccount ? '/school-sign-in' : '/auth-selection');
    });

    // Wire static services so local notifications are also saved to the
    // backend and appear on the Notifications page.
    PushNotificationService.onNotificationCreated ??= ({
      required String title,
      required String message,
      required String type,
    }) async {
      try {
        await ref.read(notificationProvider.notifier).createAndSave(
          title: title,
          message: message,
          type: type,
        );
      } catch (_) {}
    };

    // When a backend FCM message arrives in the foreground, reload the
    // notifications list so the new entry immediately appears in the page.
    PushNotificationService.onFcmMessageReceived ??= () async {
      try {
        await ref.read(notificationProvider.notifier).loadNotifications();
      } catch (_) {}
    };
    
    return MaterialApp.router(
      title: 'ExcellenceCoachingHub',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: AppRouter.routerInstance,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: [
        AppLocalizations.delegate,
        const KinyarwandaMaterialLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Ensure localizations are loaded before showing content
        final localizations = AppLocalizations.of(context);
        if (localizations == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        return _SessionLifecycleObserver(child: child ?? const SizedBox.shrink());
      },
    );
  }
}

/// Starts/stops [SessionTrackingService]'s foreground stopwatch in step with
/// the app's lifecycle so "time spent in app" only counts real foreground time.
class _SessionLifecycleObserver extends StatefulWidget {
  final Widget child;
  const _SessionLifecycleObserver({required this.child});

  @override
  State<_SessionLifecycleObserver> createState() => _SessionLifecycleObserverState();
}

class _SessionLifecycleObserverState extends State<_SessionLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SessionTrackingService.instance.appResumed();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        SessionTrackingService.instance.appResumed();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        SessionTrackingService.instance.appPaused();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
