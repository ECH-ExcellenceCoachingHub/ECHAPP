import 'package:flutter/material.dart';

class LabWebView extends StatelessWidget {
  final String url;
  final void Function(Map<String, dynamic> message) onMessage;
  const LabWebView({super.key, required this.url, required this.onMessage});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
