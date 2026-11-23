import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import 'package:excellencecoachinghub/config/api_config.dart';

/// App-wide reachability state.
///
/// "Offline" here means *the backend cannot be reached*, not merely that the
/// radio is off. Those are different things and the distinction matters: a
/// phone on a captive-portal WiFi, or one whose DNS is failing, reports a
/// perfectly healthy transport to connectivity_plus while every API call dies.
/// The screen the user actually sees in that case is "Failed to load courses",
/// so transport alone is the wrong signal to drive the offline guard.
///
/// Two independent inputs are combined:
///  * [_transportDown] — connectivity_plus. Fast, but only knows about
///    interfaces. Authoritative when it says *down*, unreliable when it says up.
///  * [_serverUnreachable] — real connection failures reported by the API
///    client, plus a probe against the backend health endpoint used to recover.
///
/// Exposed as a [ChangeNotifier] so it can be handed to GoRouter's
/// `refreshListenable`; every state flip re-runs the router redirect, which is
/// what pushes a user off an online-only screen the moment the network drops.
class ConnectivityService extends ChangeNotifier {
  ConnectivityService._internal();

  static final ConnectivityService instance = ConnectivityService._internal();

  static const Duration _probeTimeout = Duration(seconds: 6);
  static const Duration _recheckInterval = Duration(seconds: 15);

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _recoveryTimer;
  bool _initialized = false;
  bool _probeInFlight = false;

  bool _transportDown = false;
  bool _serverUnreachable = false;
  String? _blockedLocation;

  bool get isOffline => _transportDown || _serverUnreachable;
  bool get isOnline => !isOffline;

  /// The online-only location the offline guard last pushed the user away
  /// from, or null if they reached Downloads on their own.
  String? get blockedLocation => _blockedLocation;

  static String get _healthUrl =>
      '${ApiConfig.baseUrl.replaceFirst('/api', '')}/health';

  /// Reads the current state and starts listening for changes. Safe to call
  /// more than once; only the first call does any work.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      _transportDown = _isDown(await Connectivity().checkConnectivity());
    } catch (e) {
      // Fail open: if the platform can't report connectivity we must not trap
      // the user on the Downloads screen.
      debugPrint('ConnectivityService: initial check failed ($e), assuming up');
      _transportDown = false;
    }

    _subscription = Connectivity().onConnectivityChanged.listen(
      (results) => _onTransportChanged(_isDown(results)),
      onError: (Object e) {
        debugPrint('ConnectivityService: stream error ($e), assuming up');
        _onTransportChanged(false);
      },
    );

    // Confirm the backend is actually reachable rather than waiting for the
    // user's first navigation to fail. Without this the guard can't fire until
    // a screen has already loaded and shown its own error.
    if (!_transportDown) unawaited(_probe());

    _syncRecoveryTimer();
    notifyListeners();
  }

  /// Called by the API client when a request fails at the connection level —
  /// DNS failure, refused connection, dropped socket.
  ///
  /// Timeouts deliberately do *not* land here. The backend is on a host that
  /// cold-starts, so a slow first request is normal and must not be mistaken
  /// for being offline.
  void reportServerUnreachable() {
    if (_serverUnreachable) return;
    _serverUnreachable = true;
    _syncRecoveryTimer();
    _notifySoon();
  }

  /// Called by the API client whenever a request completes. Any response at
  /// all — including a 4xx or 5xx — proves the backend is reachable.
  void reportServerReachable() {
    if (!_serverUnreachable) return;
    _serverUnreachable = false;
    // Keep _blockedLocation: the router sends the user back there now that
    // the connection is back (see takeBlockedLocation).
    _syncRecoveryTimer();
    _notifySoon();
  }

  /// Records that the offline guard redirected the user away from [location].
  ///
  /// Deliberately does not notify listeners: this is called from inside the
  /// router's redirect callback, and notifying there would re-trigger the
  /// redirect through `refreshListenable` in a loop. The Downloads screen is
  /// built immediately after the redirect, so it reads the fresh value anyway.
  void recordBlockedLocation(String location) {
    _blockedLocation = location;
  }

  /// The page to return to after an outage, consumed once. Null when the
  /// user opened Downloads on their own.
  String? takeBlockedLocation() {
    final l = _blockedLocation;
    _blockedLocation = null;
    return l;
  }

  /// The user moved on by themselves: never pull them back later.
  void forgetBlockedLocation() {
    _blockedLocation = null;
  }

  void _onTransportChanged(bool down) {
    if (down == _transportDown) return;
    _transportDown = down;

    if (!down) {
      // The interface came back, but that says nothing about whether the
      // backend is actually reachable — verify before declaring recovery.
      unawaited(_probe());
    }

    _syncRecoveryTimer();
    _notifySoon();
  }

  /// Asks the backend health endpoint whether it is really reachable.
  Future<void> _probe() async {
    if (_probeInFlight) return;
    _probeInFlight = true;
    try {
      final response =
          await http.get(Uri.parse(_healthUrl)).timeout(_probeTimeout);
      // Any HTTP response proves reachability, whatever the status code.
      debugPrint('ConnectivityService: probe ok (${response.statusCode})');
      reportServerReachable();
    } on TimeoutException catch (e) {
      // Slow is not the same as unreachable. The backend cold-starts, so a
      // timeout here must leave the current state alone — flipping to offline
      // would strand a perfectly online user on the Downloads screen.
      debugPrint('ConnectivityService: probe timed out ($e), state unchanged');
    } catch (e) {
      debugPrint('ConnectivityService: probe failed ($e)');
      reportServerUnreachable();
    } finally {
      _probeInFlight = false;
    }
  }

  /// While offline, re-probe on a timer so the app recovers on its own instead
  /// of waiting for the user to trigger another failing request.
  void _syncRecoveryTimer() {
    final shouldRun = _serverUnreachable && !_transportDown;
    if (shouldRun) {
      _recoveryTimer ??= Timer.periodic(_recheckInterval, (_) => _probe());
    } else {
      _recoveryTimer?.cancel();
      _recoveryTimer = null;
    }
  }

  /// Notifies after the current frame. [reportServerUnreachable] is often
  /// reached from inside a widget build or a provider fetch, and notifying
  /// synchronously would re-enter the router redirect mid-build — which throws
  /// "markNeedsBuild() called during build". The explicit [scheduleFrame] makes
  /// sure the callback still runs when no frame happens to be pending.
  void _notifySoon() {
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) => notifyListeners());
    binding.scheduleFrame();
  }

  /// connectivity_plus reports a list of active transports. Down means no
  /// transport at all, or every reported transport is [ConnectivityResult.none].
  static bool _isDown(List<ConnectivityResult> results) =>
      results.isEmpty || results.every((r) => r == ConnectivityResult.none);

  @override
  void dispose() {
    _subscription?.cancel();
    _recoveryTimer?.cancel();
    super.dispose();
  }
}
