import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api/checkout_service.dart';

/// Pays for something through iTechPay and waits until the money arrives.
///
/// Returns the final [CheckoutState] (check `isPaid`), or null when the user
/// closed the sheet before paying. If the user closes it while a payment is
/// still waiting, the server keeps checking and unlocks the item by itself.
Future<CheckoutState?> showCheckoutSheet(
  BuildContext context, {
  required CheckoutItem item,
  required String title,
  required num amount,
  String? subtitle,
  String? defaultPhone,
  String? defaultEmail,
  CheckoutService? service,
}) {
  return showModalBottomSheet<CheckoutState>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: CheckoutSheet(
        item: item,
        title: title,
        subtitle: subtitle,
        amount: amount,
        defaultPhone: defaultPhone,
        defaultEmail: defaultEmail,
        service: service ?? CheckoutService(),
      ),
    ),
  );
}

String formatRwf(num v) {
  final s = v.round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return 'RWF $b';
}

/// Rwandan number → MTN or Airtel method id, or null.
String? methodForPhone(String phone) {
  var p = phone.replaceAll(RegExp(r'[\s\-().+]'), '');
  if (p.startsWith('250') && p.length == 12) p = '0${p.substring(3)}';
  if (p.length == 9 && !p.startsWith('0')) p = '0$p';
  if (RegExp(r'^07[89]\d{7}$').hasMatch(p)) return 'mtn_momo';
  if (RegExp(r'^07[23]\d{7}$').hasMatch(p)) return 'airtel_money';
  return null;
}

class CheckoutSheet extends StatefulWidget {
  final CheckoutItem item;
  final String title;
  final String? subtitle;
  final num amount;
  final String? defaultPhone;
  final String? defaultEmail;
  final CheckoutService service;

  const CheckoutSheet({
    super.key,
    required this.item,
    required this.title,
    required this.amount,
    required this.service,
    this.subtitle,
    this.defaultPhone,
    this.defaultEmail,
  });

  @override
  State<CheckoutSheet> createState() => _CheckoutSheetState();
}

enum _Step { form, waiting, done }

class _CheckoutSheetState extends State<CheckoutSheet> {
  static const _pollEvery = Duration(seconds: 4);

  final _phone = TextEditingController();
  final _email = TextEditingController();
  List<PaymentMethodOption> _methods = PaymentMethodOption.defaults;
  String _method = 'mtn_momo';
  _Step _step = _Step.form;
  bool _busy = false;
  String? _error;
  CheckoutState? _state;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _phone.text = widget.defaultPhone ?? '';
    _email.text = widget.defaultEmail ?? '';
    _method = methodForPhone(_phone.text) ?? 'mtn_momo';
    widget.service.methods().then((m) {
      if (!mounted) return;
      setState(() {
        _methods = m;
        if (!m.any((x) => x.id == _method && x.enabled)) {
          _method = m.firstWhere((x) => x.enabled, orElse: () => m.first).id;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  bool get _isCard => _method == 'card';

  Future<void> _pay() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final s = await widget.service.start(
        widget.item,
        method: _method,
        phone: _isCard ? null : _phone.text,
        email: _isCard ? _email.text : null,
      );
      if (!mounted) return;
      setState(() {
        _state = s;
        _step = _Step.waiting;
      });
      if (s.paymentUrl != null) _openCardPage(s.paymentUrl!);
      _startPolling();
    } on CheckoutException catch (e) {
      if (!mounted) return;
      // A payment for this is already running: wait on it instead.
      if (e.payment != null && e.payment!['reference'] != null) {
        setState(() {
          _state = CheckoutState.fromJson(e.payment!, message: e.message);
          _step = _state!.isPending ? _Step.waiting : _Step.done;
        });
        if (_state!.isPending) _startPolling();
      } else {
        setState(() => _error = e.message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openCardPage(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not open the card payment page.');
    }
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(_pollEvery, (_) => _check());
  }

  Future<void> _check() async {
    final ref = _state?.reference;
    if (ref == null || ref.isEmpty) return;
    try {
      final s = await widget.service.status(ref);
      if (!mounted) return;
      setState(() {
        _state = s;
        if (!s.isPending) {
          _step = _Step.done;
          _timer?.cancel();
        }
      });
    } catch (_) {
      // Network hiccup: keep waiting; the server keeps checking too.
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: switch (_step) {
          _Step.form => _form(context),
          _Step.waiting => _waiting(context),
          _Step.done => _done(context),
        },
      ),
    );
  }

  Widget _header(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 4),
          Text(widget.subtitle!, style: t.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
        const SizedBox(height: 12),
        Text(formatRwf(widget.amount), style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _form(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(context),
        Text('Pay with', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in _methods)
              ChoiceChip(
                label: Text(m.label),
                avatar: Icon(
                  m.id == 'card' ? Icons.credit_card : Icons.phone_android,
                  size: 18,
                ),
                selected: _method == m.id,
                onSelected: m.enabled && !_busy ? (_) => setState(() { _method = m.id; _error = null; }) : null,
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isCard)
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            enabled: !_busy,
            decoration: const InputDecoration(
              labelText: 'Email for the receipt',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
          )
        else
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            enabled: !_busy,
            onChanged: (v) {
              final m = methodForPhone(v);
              if (m != null && m != _method && _methods.any((x) => x.id == m && x.enabled)) setState(() => _method = m);
            },
            decoration: InputDecoration(
              labelText: _method == 'airtel_money' ? 'Airtel Money number' : 'MTN MoMo number',
              hintText: '07XXXXXXXX',
              prefixIcon: const Icon(Icons.phone_outlined),
              border: const OutlineInputBorder(),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          _isCard
              ? 'You will finish the payment on a secure card page (Pesapal).'
              : 'You will get a prompt on this phone. Enter your mobile money PIN to approve.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          _notice(context, _error!, cs.error, Icons.error_outline),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _busy ? null : _pay,
          icon: _busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.lock_outline),
          label: Text(_busy ? 'Starting…' : 'Pay ${formatRwf(widget.amount)}'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),
      ],
    );
  }

  Widget _waiting(BuildContext context) {
    final s = _state!;
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final card = s.paymentUrl != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(context),
        const Center(child: SizedBox(width: 48, height: 48, child: CircularProgressIndicator())),
        const SizedBox(height: 20),
        Text(
          card ? 'Finish the payment on the card page' : 'Check your phone',
          textAlign: TextAlign.center,
          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          card
              ? 'When the card page says the payment is done, come back here. This updates by itself.'
              : 'A prompt was sent to ${s.phone ?? 'your phone'}. Enter your PIN to approve ${formatRwf(s.amount)}. This updates by itself.',
          textAlign: TextAlign.center,
          style: t.bodyMedium,
        ),
        if (!card && s.paymentMethod == 'mtn_momo') ...[
          const SizedBox(height: 8),
          Text('No prompt? Dial *182*7*1# to see pending approvals.',
              textAlign: TextAlign.center, style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ],
        const SizedBox(height: 20),
        if (card)
          OutlinedButton.icon(
            onPressed: () => _openCardPage(s.paymentUrl!),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open the card page again'),
          ),
        TextButton(onPressed: _check, child: const Text('Check now')),
        const SizedBox(height: 4),
        Text(
          'You can close this. Once the payment arrives it is applied automatically.',
          textAlign: TextAlign.center,
          style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        TextButton(onPressed: () => Navigator.of(context).pop(_state), child: const Text('Close')),
      ],
    );
  }

  Widget _done(BuildContext context) {
    final s = _state!;
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final ok = s.isPaid || s.isInReview;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Icon(ok ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 72, color: ok ? Colors.green : cs.error),
        const SizedBox(height: 12),
        Text(
          s.isPaid ? 'Payment received' : s.isInReview ? 'Payment received' : 'Payment did not go through',
          textAlign: TextAlign.center,
          style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          s.isPaid
              ? 'Thank you! ${widget.title} is unlocked.'
              : (s.message ?? (s.isInReview ? 'ECH is finishing your order and will unlock it shortly.' : 'You were not charged.')),
          textAlign: TextAlign.center,
          style: t.bodyMedium,
        ),
        const SizedBox(height: 24),
        if (ok)
          FilledButton(
            onPressed: () => Navigator.of(context).pop(s),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: const Text('Continue'),
          )
        else ...[
          FilledButton(
            onPressed: () => setState(() {
              _step = _Step.form;
              _error = null;
            }),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: const Text('Try again'),
          ),
          TextButton(onPressed: () => Navigator.of(context).pop(s), child: const Text('Close')),
        ],
      ],
    );
  }

  Widget _notice(BuildContext context, String text, Color color, IconData icon) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: color))),
        ]),
      );
}
