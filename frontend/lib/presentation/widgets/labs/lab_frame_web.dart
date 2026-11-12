import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Unity WebGL lab in an iframe. Messages from the lab (ECHLabsBridge.jslib) arrive via
/// window.postMessage with source "ech-labs"; only the lab's own origin is trusted.
class LabFrame extends StatefulWidget {
  final String url;
  final void Function(Map<String, dynamic> message) onMessage;
  const LabFrame({super.key, required this.url, required this.onMessage});

  @override
  State<LabFrame> createState() => _LabFrameState();
}

class _LabFrameState extends State<LabFrame> {
  static int _counter = 0;
  late final String _viewType = 'ech-lab-frame-${_counter++}';
  late final String _origin = Uri.parse(widget.url).origin;
  JSFunction? _listener;

  @override
  void initState() {
    super.initState();
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) {
      final frame = web.HTMLIFrameElement()
        ..src = widget.url
        ..allow = 'fullscreen; xr-spatial-tracking; gyroscope; accelerometer; magnetometer; autoplay'
        ..allowFullscreen = true;
      frame.style
        ..border = '0'
        ..width = '100%'
        ..height = '100%'
        ..backgroundColor = '#0b0f14';
      return frame;
    });
    _listener = ((web.MessageEvent e) {
      if (e.origin != _origin) return;
      final data = e.data.dartify();
      if (data is Map && data['source'] == 'ech-labs') {
        widget.onMessage(data.map((k, v) => MapEntry(k.toString(), v)));
      }
    }).toJS;
    web.window.addEventListener('message', _listener);
  }

  @override
  void dispose() {
    if (_listener != null) web.window.removeEventListener('message', _listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _viewType);
}
