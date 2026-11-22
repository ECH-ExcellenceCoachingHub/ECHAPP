import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../school/school_i18n.dart';

/// Password / PIN input with a show-hide eye button.
///
/// Use [PasswordField.pin] for 6-digit PINs. [onGenerate] adds a "generate"
/// button that fills in a strong password (shown in clear so it can be noted).
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.hint,
    this.helper,
    this.validator,
    this.textInputAction,
    this.onSubmitted,
    this.autofocus = false,
    this.showGenerate = false,
    this.isPin = false,
    this.enabled = true,
    this.autofillHints = const [AutofillHints.password],
  });

  /// A 6-digit numeric PIN field.
  const PasswordField.pin({
    super.key,
    required this.controller,
    this.label = 'PIN',
    this.hint = '6 digits',
    this.helper,
    this.validator,
    this.textInputAction,
    this.onSubmitted,
    this.autofocus = false,
    this.enabled = true,
  })  : showGenerate = false,
        isPin = true,
        autofillHints = const [AutofillHints.password];

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? helper;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final bool showGenerate;
  final bool isPin;
  final bool enabled;
  final Iterable<String> autofillHints;

  /// Strong password without look-alike characters.
  static String generate([int length = 12]) {
    const lower = 'abcdefghjkmnpqrstuvwxyz';
    const upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    const digits = '23456789';
    const symbols = '!@#\$%*?';
    final rnd = Random.secure();
    String pick(String s) => s[rnd.nextInt(s.length)];
    final chars = [pick(lower), pick(upper), pick(digits), pick(symbols)];
    const all = lower + upper + digits + symbols;
    while (chars.length < length) {
      chars.add(pick(all));
    }
    chars.shuffle(rnd);
    return chars.join();
  }

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      if (widget.showGenerate)
        IconButton(
          tooltip: 'Generate a strong password',
          icon: const Icon(Icons.auto_fix_high_outlined),
          onPressed: widget.enabled
              ? () {
                  widget.controller.text = PasswordField.generate();
                  setState(() => _obscure = false);
                }
              : null,
        ),
      IconButton(
        tooltip: _obscure ? 'Show' : 'Hide',
        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    ];

    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      enableSuggestions: false,
      autocorrect: false,
      autofillHints: widget.autofillHints,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted,
      keyboardType: widget.isPin ? TextInputType.number : TextInputType.visiblePassword,
      inputFormatters: widget.isPin
          ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)]
          : null,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: trSchool(context, widget.label),
        hintText: widget.hint == null ? null : trSchool(context, widget.hint!),
        helperText: widget.helper == null ? null : trSchool(context, widget.helper!),
        helperMaxLines: 2,
        prefixIcon: Icon(widget.isPin ? Icons.pin_outlined : Icons.lock_outline),
        suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: buttons),
      ),
    );
  }
}
