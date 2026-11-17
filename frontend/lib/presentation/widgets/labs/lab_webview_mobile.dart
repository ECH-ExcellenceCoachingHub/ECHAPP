import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

/// The 3D lab (Unity WebGL build hosted at LAB_WEB_URL) running INSIDE the app.
/// Messages from the lab (ECHLabsBridge.jslib dispatches a window "ech-labs" event)
/// are forwarded to Flutter through the "ECHLabsHost" JavaScript channel.
class LabWebView extends StatefulWidget {
  final String url;
  final void Function(Map<String, dynamic> message) onMessage;
  const LabWebView({super.key, required this.url, required this.onMessage});

  @override
  State<LabWebView> createState() => _LabWebViewState();
}

class _LabWebViewState extends State<LabWebView> {
  late final WebViewController _controller;
  double _progress = 0;
  String? _error;

  static const _bridgeJs = '''
    (function () {
      if (window.__echBridge) return; window.__echBridge = true;
      window.addEventListener('ech-labs', function (e) {
        try { ECHLabsHost.postMessage(JSON.stringify(e.detail)); } catch (err) {}
      });
    })();
  ''';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0B0F14))
      ..addJavaScriptChannel('ECHLabsHost', onMessageReceived: (m) {
        try {
          final data = jsonDecode(m.message);
          if (data is Map) widget.onMessage(data.map((k, v) => MapEntry(k.toString(), v)));
        } catch (_) {}
      })
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) => mounted ? setState(() => _progress = p / 100) : null,
        onPageFinished: (_) async {
          // Only the real lab page has the Unity canvas. If the server returned something else
          // (e.g. the website because /lab/ is not deployed yet), never show it inside the app.
          final isLab = await _controller.runJavaScriptReturningResult("document.getElementById('unity-canvas') ? 1 : 0");
          if (isLab.toString() != '1') {
            if (mounted) setState(() => _error = 'The 3D lab is not available yet. Please try again later.');
            return;
          }
          await _controller.runJavaScript(_bridgeJs);
        },
        onWebResourceError: (e) {
          if (e.isForMainFrame == true && mounted) setState(() => _error = 'Could not load the lab (${e.description}). Check your internet connection.');
        },
        // Keep students inside the lab: block navigation to other sites.
        onNavigationRequest: (r) {
          final target = Uri.tryParse(r.url);
          final lab = Uri.parse(widget.url);
          return target != null && target.host == lab.host ? NavigationDecision.navigate : NavigationDecision.prevent;
        },
      ))
      ..loadRequest(Uri.parse(widget.url));

    final platform = _controller.platform;
    if (platform is AndroidWebViewController) {
      platform.setMediaPlaybackRequiresUserGesture(false); // Dr. ECH's voice
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned.fill(child: WebViewWidget(controller: _controller)),
      if (_progress < 1 && _error == null)
        Positioned(left: 0, right: 0, top: 0, child: LinearProgressIndicator(value: _progress == 0 ? null : _progress, minHeight: 3, color: const Color(0xFF10B981), backgroundColor: Colors.transparent)),
      if (_error != null)
        Positioned.fill(
          child: Container(
            color: const Color(0xFF0B0F14),
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.wifi_off_rounded, color: Colors.white70, size: 48),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  setState(() { _error = null; _progress = 0; });
                  _controller.loadRequest(Uri.parse(widget.url));
                },
                child: const Text('Try again'),
              ),
            ]),
          ),
        ),
    ]);
  }
}
