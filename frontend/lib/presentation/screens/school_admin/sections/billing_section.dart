import 'package:flutter/material.dart';

import '../../../../config/app_theme.dart';
import '../../../../services/api/checkout_service.dart';
import '../../../../services/api/school_service.dart';
import '../../../../widgets/payments/checkout_sheet.dart';
import '../../../../widgets/school/school_ui.dart';
import '../school_admin_dashboard_screen.dart';

/// School terms (calendar) and what was paid for each: per student per term.
/// The school defines its terms and pays online (MoMo / Airtel / card through
/// iTechPay); ECH (super admin) can also record payments made another way.
class BillingSection extends StatefulWidget {
  const BillingSection({super.key, required this.c});
  final SchoolCtx c;

  @override
  State<BillingSection> createState() => _BillingSectionState();
}

class _BillingSectionState extends State<BillingSection> {
  final _key = GlobalKey<AsyncBodyState<Map<String, dynamic>>>();

  Future<void> _termDialog({Map<String, dynamic>? term}) async {
    final year = TextEditingController(text: term?['academicYear'] ?? '${DateTime.now().year}');
    int number = (term?['term'] as num?)?.toInt() ?? 1;
    DateTime? start = parseDate(term?['startDate']);
    DateTime? end = parseDate(term?['endDate']);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
        Future<void> pick(bool isStart) async {
          final d = await showDatePicker(context: ctx, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDate: (isStart ? start : end) ?? DateTime.now());
          if (d != null) set(() => isStart ? start = d : end = d);
        }
        return AlertDialog(
          title: Text(term == null ? 'Add term' : 'Edit term dates'),
          content: SizedBox(
            width: 400,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Expanded(child: TextField(controller: year, enabled: term == null, decoration: const InputDecoration(labelText: 'Academic year'))),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: number,
                    decoration: const InputDecoration(labelText: 'Term'),
                    items: const [DropdownMenuItem(value: 1, child: T('Term 1')), DropdownMenuItem(value: 2, child: T('Term 2')), DropdownMenuItem(value: 3, child: T('Term 3'))],
                    onChanged: term == null ? (v) => set(() => number = v ?? 1) : null,
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => pick(true), child: Text(start == null ? 'Start date' : 'Starts ${fmtDate(start)}'))),
                const SizedBox(width: 12),
                Expanded(child: OutlinedButton(onPressed: () => pick(false), child: Text(end == null ? 'End date' : 'Ends ${fmtDate(end)}'))),
              ]),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const T('Cancel')),
            FilledButton(onPressed: start != null && end != null ? () => Navigator.pop(ctx, true) : null, child: const T('Save')),
          ],
        );
      }),
    );
    if (ok != true) return;
    try {
      final body = {'academicYear': year.text.trim(), 'term': number, 'startDate': start!.toIso8601String(), 'endDate': end!.toIso8601String()};
      if (term == null) {
        await widget.c.svc.createTerm(widget.c.schoolId, body);
      } else {
        await widget.c.svc.updateTerm(widget.c.schoolId, '${term['id']}', {'startDate': body['startDate'], 'endDate': body['endDate']});
      }
      _key.currentState?.reload();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  Future<void> _paymentDialog(Map<String, dynamic> term, num defaultPrice) async {
    final b = Map<String, dynamic>.from(term['billing'] as Map? ?? {});
    final students = TextEditingController(text: '${b['studentsPaid'] ?? 0}');
    final price = TextEditingController(text: '${(b['pricePerStudent'] ?? 0) == 0 ? defaultPrice : b['pricePerStudent']}');
    final reference = TextEditingController(text: '${b['reference'] ?? ''}');
    final notes = TextEditingController(text: '${b['notes'] ?? ''}');
    String status = (b['status'] as String?) ?? 'unpaid';
    String method = (b['method'] as String?)?.isNotEmpty == true ? b['method'] as String : 'bank';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
        final total = (int.tryParse(students.text) ?? 0) * (num.tryParse(price.text) ?? 0);
        return AlertDialog(
          title: T('Payment — ${term['label']}'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  Expanded(child: TextField(controller: students, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Students paid for'), onChanged: (_) => set(() {}))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price per student'), onChanged: (_) => set(() {}))),
                ]),
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerLeft, child: T('Total: ${fmtMoney(total)}', style: const TextStyle(fontWeight: FontWeight.w600))),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'unpaid', child: T('Unpaid')),
                    DropdownMenuItem(value: 'pending', child: T('Pending confirmation')),
                    DropdownMenuItem(value: 'paid', child: T('Paid')),
                    DropdownMenuItem(value: 'waived', child: T('Free (waived)')),
                  ],
                  onChanged: (v) => set(() => status = v ?? 'unpaid'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: ['bank', 'mobile_money', 'cash', 'other'].contains(method) ? method : 'other',
                  decoration: const InputDecoration(labelText: 'Method'),
                  items: const [
                    DropdownMenuItem(value: 'bank', child: T('Bank transfer')),
                    DropdownMenuItem(value: 'mobile_money', child: T('Mobile money')),
                    DropdownMenuItem(value: 'cash', child: T('Cash')),
                    DropdownMenuItem(value: 'other', child: T('Other')),
                  ],
                  onChanged: (v) => method = v ?? 'other',
                ),
                const SizedBox(height: 12),
                TextField(controller: reference, decoration: const InputDecoration(labelText: 'Reference / receipt number')),
                const SizedBox(height: 12),
                TextField(controller: notes, decoration: const InputDecoration(labelText: 'Notes')),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const T('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const T('Save payment')),
          ],
        );
      }),
    );
    if (ok != true) return;
    try {
      await widget.c.svc.updateTerm(widget.c.schoolId, '${term['id']}', {
        'billing': {
          'studentsPaid': int.tryParse(students.text.trim()) ?? 0,
          'pricePerStudent': num.tryParse(price.text.trim()) ?? 0,
          'status': status,
          'method': method,
          'reference': reference.text.trim(),
          'notes': notes.text.trim(),
        },
      });
      _key.currentState?.reload();
      widget.c.reloadSchool();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  /// A term the school can still pay for: not ended, not waived by ECH.
  bool _payable(Map<String, dynamic> t) {
    final st = (t['billing'] as Map?)?['status'];
    final end = parseDate(t['endDate']);
    return st != 'waived' && (end == null || !end.isBefore(DateTime.now()));
  }

  /// The school admin pays for student places with mobile money or card.
  Future<void> _payOnline(Map<String, dynamic> term, num price) async {
    if (price <= 0) {
      showSnack(context, 'ECH has not set a price for your school yet. Please contact ECH.', error: true);
      return;
    }
    final b = Map<String, dynamic>.from(term['billing'] as Map? ?? {});
    final topUp = b['status'] == 'paid';
    final paidSeats = (b['studentsPaid'] as num?)?.toInt() ?? 0;
    final enrolled = (widget.c.school['studentCount'] as num?)?.toInt() ?? 0;
    final suggested = topUp ? (enrolled - paidSeats).clamp(1, 100000) : (enrolled < 1 ? 1 : enrolled);
    final students = TextEditingController(text: '$suggested');

    final n = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
        final count = int.tryParse(students.text.trim()) ?? 0;
        return AlertDialog(
          title: T(topUp ? 'Add students — ${term['label']}' : 'Pay for ${term['label']}'),
          content: SizedBox(
            width: 380,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              T(topUp
                  ? 'You already paid for $paidSeats students this term. You have $enrolled students registered.'
                  : 'You have $enrolled students registered. Pay for every student who will use ECH this term.'),
              const SizedBox(height: 12),
              TextField(
                controller: students,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: topUp ? 'Extra students' : 'Number of students'),
                onChanged: (_) => set(() {}),
              ),
              const SizedBox(height: 12),
              T('${fmtMoney(price)} × $count = ${fmtMoney(price * count)}', style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const T('Cancel')),
            FilledButton(onPressed: count >= 1 ? () => Navigator.pop(ctx, count) : null, child: const T('Continue to payment')),
          ],
        );
      }),
    );
    if (n == null || !mounted) return;

    final admin = widget.c.school['admin'];
    final result = await showCheckoutSheet(
      context,
      item: CheckoutItem.schoolTerm(termId: '${term['id']}', students: n, schoolId: widget.c.schoolId),
      title: '${term['label']}',
      subtitle: '${widget.c.school['name'] ?? 'School'} · $n students',
      amount: price * n,
      defaultPhone: (admin is Map ? admin['phone'] : null)?.toString() ?? widget.c.school['phone']?.toString(),
      defaultEmail: (admin is Map ? admin['email'] : null)?.toString() ?? widget.c.school['email']?.toString(),
    );
    if (!mounted) return;
    _key.currentState?.reload();
    if (result?.isPaid == true) {
      await widget.c.reloadSchool();
      if (mounted) showSnack(context, 'Payment received. ${term['label']} is paid.');
    }
  }

  Future<void> _settings() async {
    final s = widget.c.school;
    final price = TextEditingController(text: '${s['pricePerStudentPerTerm'] ?? 0}');
    final grace = TextEditingController(text: '${s['graceDays'] ?? 21}');
    final trial = TextEditingController(text: '${s['trialStudentLimit'] ?? 30}');
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const T('Billing settings'),
      content: SizedBox(width: 380, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price per student per term (RWF)')),
        const SizedBox(height: 12),
        TextField(controller: grace, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Grace days after a term ends')),
        const SizedBox(height: 12),
        TextField(controller: trial, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Trial students (before any payment)')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const T('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const T('Save'))],
    ));
    if (ok != true) return;
    try {
      await widget.c.svc.updateSchool(widget.c.schoolId, {
        'pricePerStudentPerTerm': num.tryParse(price.text) ?? 0,
        'graceDays': int.tryParse(grace.text) ?? 21,
        'trialStudentLimit': int.tryParse(trial.text) ?? 30,
      });
      await widget.c.reloadSchool();
      _key.currentState?.reload();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AsyncBody<Map<String, dynamic>>(
      key: _key,
      load: () => widget.c.svc.terms(widget.c.schoolId),
      builder: (context, d, reload) {
        final terms = SchoolService.list(d['terms']);
        final sub = Map<String, dynamic>.from(d['subscription'] as Map? ?? {});
        final price = (d['pricePerStudentPerTerm'] as num?) ?? 0;
        final muted = AppTheme.getSecondaryTextColor(context);
        final status = sub['status'] as String?;
        return SchoolPage(onRefresh: reload, children: [
          StatGrid(children: [
            StatTile(
              label: 'Subscription',
              value: switch (status) { 'active' => 'Active', 'grace' => 'Grace', 'trial' => 'Trial', 'expired' => 'Expired', _ => '—' },
              icon: Icons.verified_outlined,
              tone: switch (status) { 'active' => Tone.good, 'grace' => Tone.warn, 'trial' => Tone.info, _ => Tone.bad },
              caption: (sub['daysLeft'] ?? 0) > 0 ? '${sub['daysLeft']} days left' : null,
            ),
            StatTile(label: 'Paid student places', value: '${sub['studentLimit'] ?? 0}', icon: Icons.event_seat_outlined),
            StatTile(label: 'Price per student / term', value: fmtMoney(price), icon: Icons.payments_outlined, tone: Tone.neutral),
          ]),
          SectionCard(
            icon: Icons.info_outline,
            title: 'How billing works',
            trailing: widget.c.superAdmin ? TextButton.icon(onPressed: _settings, icon: const Icon(Icons.tune), label: const T('Settings')) : null,
            child: Text(
              'Your school pays ECH per student for each term. While a paid term is running, your students get the ECH courses meant for their class for free, and you can register up to the number of students paid for. '
              'After a term ends you have ${widget.c.school['graceDays'] ?? 21} days of grace (school holidays) before course access stops.'
              '${widget.c.superAdmin ? '' : ' Pay for a term here with MTN MoMo, Airtel Money or card: it is unlocked as soon as the payment arrives.'}',
              style: TextStyle(color: muted, height: 1.45),
            ),
          ),
          if (!widget.c.superAdmin && _dueTerm(terms) != null)
            Builder(builder: (context) {
              final due = _dueTerm(terms)!;
              final paid = (due['billing'] as Map?)?['status'] == 'paid';
              return FilledButton.icon(
                onPressed: () => _payOnline(due, price),
                icon: Icon(paid ? Icons.group_add_outlined : Icons.payments_outlined),
                label: T(paid ? 'Pay for more students — ${due['label']}' : 'Pay for ${due['label']}'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              );
            }),
          SectionCard(
            icon: Icons.event_note_outlined,
            title: 'Terms',
            trailing: FilledButton.tonalIcon(onPressed: () => _termDialog(), icon: const Icon(Icons.add), label: const T('Add term')),
            child: terms.isEmpty
                ? T('Add your school terms (e.g. 2026 Term 1, 2 and 3 with their dates). They are used for billing, homework and lesson reports.', style: TextStyle(color: muted))
                : Column(children: [
                    for (var i = 0; i < terms.length; i++) ...[if (i > 0) const RowDivider(), _termTile(terms[i], price)],
                  ]),
          ),
        ]);
      },
    );
  }

  /// The term to offer payment for: the current one, else the next unpaid one.
  Map<String, dynamic>? _dueTerm(List<Map<String, dynamic>> terms) {
    final now = DateTime.now();
    final payable = terms.where(_payable).toList()
      ..sort((a, b) => (parseDate(a['startDate']) ?? now).compareTo(parseDate(b['startDate']) ?? now));
    for (final t in payable) {
      final s = parseDate(t['startDate']);
      if (s != null && !s.isAfter(now)) return t; // running now
    }
    for (final t in payable) {
      if ((t['billing'] as Map?)?['status'] != 'paid') return t;
    }
    return null;
  }

  Widget _termTile(Map<String, dynamic> t, num price) {
    final b = Map<String, dynamic>.from(t['billing'] as Map? ?? {});
    final st = b['status'] as String? ?? 'unpaid';
    final now = DateTime.now();
    final s = parseDate(t['startDate']);
    final e = parseDate(t['endDate']);
    final current = s != null && e != null && !now.isBefore(s) && !now.isAfter(e);
    final c = current ? AppTheme.primary : AppTheme.getSecondaryTextColor(context);
    return EntityTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
        child: Icon(current ? Icons.play_circle_outline : Icons.event_outlined, color: c, size: 21),
      ),
      title: '${t['label']}',
      subtitle: '${fmtDate(t['startDate'])} – ${fmtDate(t['endDate'])}'
          '${(b['studentsPaid'] ?? 0) > 0 ? ' · ${b['studentsPaid']} students · ${fmtMoney(b['amount'] as num?)}' : ''}'
          '${b['reference'] != null && '${b['reference']}'.isNotEmpty ? ' · ref ${b['reference']}' : ''}',
      pills: [
        StatusPill(switch (st) { 'paid' => 'Paid', 'waived' => 'Free', 'pending' => 'Pending', _ => 'Unpaid' }, tone: switch (st) { 'paid' || 'waived' => Tone.good, 'pending' => Tone.warn, _ => Tone.bad }),
        if (current) const StatusPill('Current', tone: Tone.info),
      ],
      trailing: PopupMenuButton<String>(
        onSelected: (v) async {
          if (v == 'pay') _paymentDialog(t, price);
          if (v == 'online') _payOnline(t, price);
          if (v == 'dates') _termDialog(term: t);
          if (v == 'delete') {
            if (!await confirm(context, title: 'Remove ${t['label']}?', message: 'This removes the term dates.', confirmLabel: 'Remove', destructive: true)) return;
            try {
              await widget.c.svc.deleteTerm(widget.c.schoolId, '${t['id']}');
              _key.currentState?.reload();
            } catch (e) {
              if (mounted) showSnack(context, e.toString(), error: true);
            }
          }
        },
        itemBuilder: (_) => [
          if (widget.c.superAdmin) const PopupMenuItem(value: 'pay', child: T('Record payment')),
          if (!widget.c.superAdmin && _payable(t))
            PopupMenuItem(value: 'online', child: T((t['billing'] as Map?)?['status'] == 'paid' ? 'Pay for more students' : 'Pay online')),
          const PopupMenuItem(value: 'dates', child: T('Change dates')),
          const PopupMenuItem(value: 'delete', child: T('Remove term')),
        ],
      ),
    );
  }
}
