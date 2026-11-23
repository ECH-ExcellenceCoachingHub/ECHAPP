import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../models/payment.dart';
import '../../../../models/payment_status.dart';

/// Labels, colours and rules shared by the admin payments screen and its
/// details sheet. Online (iTechPay) payments read differently from manual ones:
/// "pending" means the customer hasn't approved yet, not that an admin must act.

final _money = NumberFormat('#,##0');
String rwf(num v) => 'RWF ${_money.format(v)}';
String compactRwf(num v) {
  if (v >= 1000000) return 'RWF ${(v / 1000000).toStringAsFixed(v >= 10000000 ? 0 : 1)}M';
  if (v >= 10000) return 'RWF ${(v / 1000).toStringAsFixed(0)}k';
  return rwf(v);
}

const onlineStuckAfter = Duration(minutes: 15);

const purposeLabels = {'course': 'Course', 'teacher_guide': "Teacher's guide", 'school_term': 'School term'};
const purposeIcons = {'course': Icons.school_outlined, 'teacher_guide': Icons.menu_book_outlined, 'school_term': Icons.apartment_outlined};
const purposeColors = {'course': Color(0xFF0EA5E9), 'teacher_guide': Color(0xFF6366F1), 'school_term': Color(0xFF8B5CF6)};

const methodLabels = {'mtn_momo': 'MTN MoMo', 'airtel_money': 'Airtel Money', 'card': 'Card', 'free': 'Free'};
const methodColors = {'mtn_momo': Color(0xFFEAB308), 'airtel_money': Color(0xFFEF4444), 'card': Color(0xFF3B82F6), 'free': Color(0xFF94A3B8)};

String purposeOf(Payment p) => purposeLabels.containsKey(p.purpose) ? p.purpose : 'course';

String methodLabel(String m) => methodLabels[m] ?? (m.isEmpty ? '—' : m);

/// What was bought, in one line.
String itemTitle(Payment p) {
  if (p.isSchoolTerm) {
    return [p.schoolName ?? 'School', if (p.termLabel != null && p.termLabel!.isNotEmpty) p.termLabel].join(' · ');
  }
  return p.course?.title.isNotEmpty == true ? p.course!.title : 'Unknown course';
}

String itemSubtitle(Payment p) {
  if (p.isSchoolTerm) return '${p.seats ?? 0} student places';
  return purposeLabels[purposeOf(p)]!;
}

String customerName(Payment p) => p.user?.fullName.isNotEmpty == true ? p.user!.fullName : 'Unknown user';

bool isPaid(Payment p) => p.status == PaymentStatus.completed || p.status == PaymentStatus.approved;

/// Admin can confirm with iTechPay: online and not yet paid or in review.
bool canRecheck(Payment p) =>
    p.isOnline && const [PaymentStatus.pending, PaymentStatus.failed, PaymentStatus.cancelled].contains(p.status);

bool canDecide(Payment p) => p.status == PaymentStatus.pending || p.status == PaymentStatus.adminReview;

/// True when an admin should act on it (same rule as the server's "needs attention").
bool needsAttention(Payment p) =>
    p.status == PaymentStatus.adminReview ||
    (p.status == PaymentStatus.pending && (!p.isOnline || DateTime.now().difference(p.createdAt) > onlineStuckAfter));

class StatusLook {
  final String label;
  final Color color;
  final IconData icon;
  final String? hint;
  const StatusLook(this.label, this.color, this.icon, [this.hint]);
}

StatusLook statusLook(Payment p) {
  switch (p.status) {
    case PaymentStatus.completed:
    case PaymentStatus.approved:
      return StatusLook('Paid', const Color(0xFF16A34A), Icons.check_circle,
          p.isOnline ? 'Confirmed by iTechPay${p.adminApproval == null ? '' : ' and admin'}' : 'Approved by an admin');
    case PaymentStatus.adminReview:
      return StatusLook('Needs review', const Color(0xFF7C3AED), Icons.rate_review_outlined,
          p.isOnline ? 'Money arrived but could not be applied automatically${p.failureReason != null ? ': ${p.failureReason}' : ''}' : 'The customer says they paid');
    case PaymentStatus.pending:
      if (!p.isOnline) return const StatusLook('Awaiting approval', Color(0xFFEA580C), Icons.hourglass_top, 'Manual request: check the money arrived, then approve');
      final stuck = DateTime.now().difference(p.createdAt) > onlineStuckAfter;
      return stuck
          ? const StatusLook('No answer yet', Color(0xFFD97706), Icons.help_outline, 'iTechPay has not confirmed it. Check with iTechPay.')
          : const StatusLook('Customer approving', Color(0xFFF59E0B), Icons.phonelink_ring, 'Waiting for the customer to approve on their phone or card page');
    case PaymentStatus.failed:
      if (p.isOnline && p.failureReason == 'declined') return const StatusLook('Declined', Color(0xFFDC2626), Icons.block, 'Declined or cancelled on the phone. No money was taken.');
      if (p.isOnline && p.failureReason == 'timeout') {
        return const StatusLook('Not confirmed', Color(0xFFDC2626), Icons.timer_off_outlined, 'No confirmation in time. ECH keeps checking for 48 hours.');
      }
      return StatusLook(p.isOnline ? 'Failed' : 'Rejected', const Color(0xFFDC2626), Icons.cancel_outlined);
    case PaymentStatus.cancelled:
      return const StatusLook('Cancelled', Color(0xFF64748B), Icons.do_not_disturb_on_outlined);
  }
}

String relativeDate(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  return DateFormat('d MMM yyyy').format(d);
}

String fullDate(DateTime d) => DateFormat('d MMM yyyy, HH:mm').format(d.toLocal());

// ── Small shared widgets ─────────────────────────────────────────────────────

class StatusPill extends StatelessWidget {
  const StatusPill(this.look, {super.key, this.dense = false});
  final StatusLook look;
  final bool dense;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 3 : 5),
        decoration: BoxDecoration(color: look.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(look.icon, size: dense ? 12 : 14, color: look.color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(look.label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: look.color, fontWeight: FontWeight.w700, fontSize: dense ? 11 : 12)),
          ),
        ]),
      );
}

class Tag extends StatelessWidget {
  const Tag(this.text, this.color, {super.key, this.icon});
  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 11, color: color), const SizedBox(width: 3)],
          Flexible(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.2)),
          ),
        ]),
      );
}

class Initials extends StatelessWidget {
  const Initials(this.name, {super.key, this.size = 38, this.color});
  final String name;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+')).where((x) => x.isNotEmpty).toList();
    final text = parts.isEmpty ? '?' : (parts.first[0] + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.withValues(alpha: 0.14), shape: BoxShape.circle),
      child: Text(text, style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: size * 0.36)),
    );
  }
}

/// Method + channel, e.g. "MTN MoMo · Online".
class MethodLine extends StatelessWidget {
  const MethodLine(this.p, {super.key});
  final Payment p;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: methodColors[p.paymentMethod] ?? muted, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Flexible(child: Text(methodLabel(p.paymentMethod), overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
      const SizedBox(width: 6),
      Flexible(child: Tag(p.isOnline ? 'ONLINE' : 'MANUAL', p.isOnline ? const Color(0xFF059669) : muted)),
    ]);
  }
}
