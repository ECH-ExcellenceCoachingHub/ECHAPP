import 'package:flutter/material.dart';

/// Minimum the server accepts (Firebase + backend: 6 characters).
const int kMinPasswordLength = 6;

/// Live strength bar + checklist under a password field, so the person sees
/// exactly which rule is missing while typing.
class PasswordStrengthMeter extends StatelessWidget {
  final TextEditingController controller;
  const PasswordStrengthMeter({super.key, required this.controller});

  static List<(String, bool, bool)> rules(String p) => [
        // (label, met, required)
        ('At least $kMinPasswordLength characters', p.length >= kMinPasswordLength, true),
        ('8 or more characters', p.length >= 8, false),
        ('Upper and lower case letters', RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p), false),
        ('A number', RegExp(r'\d').hasMatch(p), false),
        ('A symbol (e.g. ! @ # ?)', RegExp(r'[^A-Za-z0-9]').hasMatch(p), false),
      ];

  /// 0 = empty, 1 too short, 2 weak, 3 fair, 4 good, 5 strong.
  static int score(String p) {
    if (p.isEmpty) return 0;
    if (p.length < kMinPasswordLength) return 1;
    final met = rules(p).skip(1).where((r) => r.$2).length; // 0..4
    return (2 + met).clamp(2, 5);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final p = value.text;
        if (p.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'Use at least $kMinPasswordLength characters. Mixing letters, numbers and symbols makes it stronger.',
              style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
            ),
          );
        }
        final s = score(p);
        const labels = ['', 'Too short', 'Weak', 'Fair', 'Good', 'Strong'];
        const colors = [Colors.grey, Colors.red, Colors.deepOrange, Colors.amber, Colors.lightGreen, Colors.green];
        final color = colors[s];
        final muted = Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.black12;
        return Padding(
          padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              for (var i = 1; i <= 5; i++) ...[
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 5,
                    decoration: BoxDecoration(color: i <= s ? color : muted, borderRadius: BorderRadius.circular(3)),
                  ),
                ),
                if (i < 5) const SizedBox(width: 4),
              ],
              const SizedBox(width: 10),
              Text(labels[s], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
            ]),
            const SizedBox(height: 6),
            for (final r in rules(p))
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(children: [
                  Icon(
                    r.$2 ? Icons.check_circle : (r.$3 ? Icons.cancel : Icons.radio_button_unchecked),
                    size: 15,
                    color: r.$2 ? Colors.green : (r.$3 ? Colors.red : Theme.of(context).hintColor),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      r.$3 ? '${r.$1} (required)' : r.$1,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: r.$3 && !r.$2 ? FontWeight.w700 : FontWeight.w400,
                        color: r.$2 ? Colors.green : (r.$3 ? Colors.red : Theme.of(context).hintColor),
                      ),
                    ),
                  ),
                ]),
              ),
          ]),
        );
      },
    );
  }
}

/// "Passwords match" / "Passwords don't match yet" under the confirm field.
class PasswordMatchHint extends StatelessWidget {
  final TextEditingController password;
  final TextEditingController confirm;
  const PasswordMatchHint({super.key, required this.password, required this.confirm});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([password, confirm]),
      builder: (context, _) {
        if (confirm.text.isEmpty) return const SizedBox.shrink();
        final ok = confirm.text == password.text;
        return Padding(
          padding: const EdgeInsets.only(top: 6, left: 4),
          child: Row(children: [
            Icon(ok ? Icons.check_circle : Icons.cancel, size: 15, color: ok ? Colors.green : Colors.red),
            const SizedBox(width: 6),
            Flexible(
              child: Text(ok ? 'Passwords match' : "Passwords don't match yet",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ok ? Colors.green : Colors.red)),
            ),
          ]),
        );
      },
    );
  }
}
