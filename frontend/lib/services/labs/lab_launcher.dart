import 'dart:io';

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import '../../models/lab_scenario.dart';

/// How a lab opens on this device.
enum LabLaunchKind {
  /// Flutter web: Unity WebGL build inside the app (iframe).
  embeddedWeb,

  /// Windows: native Unity build bundled in the MSIX (labs/ECHLabs.exe), best quality + PC VR.
  windowsApp,

  /// Android/iOS/macOS: the 3D lab runs full-screen INSIDE the app (in-app web view).
  inApp,

  /// Android/iOS (until the Unity library is embedded) and machines without the bundled
  /// build: the WebGL lab in the device browser, which keeps full touch + gyroscope support.
  browser,
}

/// The student's preferred way to experience the lab.
enum LabViewMode { screen, cardboard, headset }

class LabLauncher {
  static String? _windowsExeCache;
  static const _channel = MethodChannel('ech/labs');
  static bool? _nativeCache;

  /// Android: is the native 3D lab (Unity as a Library) built into this app and supported by the CPU?
  static Future<bool> nativeAvailable() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    if (_nativeCache != null) return _nativeCache!;
    try {
      _nativeCache = await _channel.invokeMethod<bool>('isNativeAvailable') ?? false;
    } catch (_) {
      _nativeCache = false;
    }
    return _nativeCache!;
  }

  /// Opens the native lab full-screen inside the app; completes when the student leaves it.
  /// Returns the lab's result (score, passed…) or null if they left early.
  static Future<Map<String, dynamic>?> launchNative(LabSessionTicket t, LabViewMode mode) async {
    final raw = await _channel.invokeMethod<String>('launch', {
      ...t.launch,
      'mode': modeParam(mode),
      if (t.resumeClientId != null) 'resume': t.resumeClientId,
    });
    if (raw == null || raw.isEmpty) return null;
    try {
      final data = jsonDecode(raw);
      return data is Map ? data.map((k, v) => MapEntry(k.toString(), v)) : null;
    } catch (_) {
      return null;
    }
  }

  /// labs/ECHLabs.exe next to the Flutter app executable (added to the MSIX by the installer scripts).
  static String? get windowsExe {
    if (kIsWeb || !Platform.isWindows) return null;
    if (_windowsExeCache != null) return _windowsExeCache;
    final dir = File(Platform.resolvedExecutable).parent.path;
    final exe = p.join(dir, 'labs', 'ECHLabs.exe');
    if (File(exe).existsSync()) _windowsExeCache = exe;
    return _windowsExeCache;
  }

  static LabLaunchKind get kind {
    if (kIsWeb) return LabLaunchKind.embeddedWeb;
    if (windowsExe != null) return LabLaunchKind.windowsApp;
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) return LabLaunchKind.inApp;
    return LabLaunchKind.browser;
  }

  static bool get canUseCardboard => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static String modeParam(LabViewMode m) => switch (m) {
        LabViewMode.screen => kIsWeb || (!Platform.isAndroid && !Platform.isIOS) ? 'desktop' : 'touch',
        LabViewMode.cardboard => 'cardboard',
        LabViewMode.headset => 'xr',
      };

  /// URL for web/browser launches, with the view mode added to the fragment.
  static String webUrlFor(LabSessionTicket t, LabViewMode mode) {
    final base = t.webUrl;
    if (base == null) throw StateError('The web version of ECH Labs is not available yet.');
    final sep = base.contains('#') ? '&' : '#';
    final resume = t.resumeClientId != null ? '&resume=${Uri.encodeComponent(t.resumeClientId!)}' : '';
    return '$base${sep}mode=${modeParam(mode)}$resume';
  }

  /// Starts the native Windows lab. Results go straight to the backend with the lab token.
  static Future<Process> launchWindows(LabSessionTicket t, LabViewMode mode) {
    final exe = windowsExe;
    if (exe == null) throw StateError('ECH Labs is not installed with this app');
    return Process.start(exe, [...t.cliArgs, '--mode=${modeParam(mode)}'], mode: ProcessStartMode.detached);
  }

  static Future<bool> openInBrowser(LabSessionTicket t, LabViewMode mode) =>
      launchUrl(Uri.parse(webUrlFor(t, mode)), mode: LaunchMode.externalApplication);
}
