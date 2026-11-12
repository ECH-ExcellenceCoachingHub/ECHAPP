import 'package:flutter/material.dart';

/// Non-web platforms open the lab natively or in the browser (see LabLauncher).
class LabFrame extends StatelessWidget {
  final String url;
  final void Function(Map<String, dynamic> message) onMessage;
  const LabFrame({super.key, required this.url, required this.onMessage});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
