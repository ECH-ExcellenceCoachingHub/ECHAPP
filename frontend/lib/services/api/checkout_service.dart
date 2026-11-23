import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../infrastructure/api_client.dart';

/// Automatic payments through iTechPay (MTN MoMo, Airtel Money, card).
/// The server sets the price; the app only says what is being bought.
class CheckoutException implements Exception {
  final String message;
  final int? status;
  final Map<String, dynamic>? payment;
  CheckoutException(this.message, {this.status, this.payment});
  @override
  String toString() => message;
}

/// What the customer is paying for.
class CheckoutItem {
  final String purpose; // course | teacher_guide | school_term
  final String? courseId;
  final String? schoolId;
  final String? termId;
  final int? students;

  const CheckoutItem.course(String this.courseId)
      : purpose = 'course',
        schoolId = null,
        termId = null,
        students = null;
  const CheckoutItem.teacherGuide(String this.courseId)
      : purpose = 'teacher_guide',
        schoolId = null,
        termId = null,
        students = null;
  const CheckoutItem.schoolTerm({required String this.termId, required int this.students, this.schoolId = 'me'})
      : purpose = 'school_term',
        courseId = null;

  Map<String, dynamic> toJson() => {
        'purpose': purpose,
        if (courseId != null) 'courseId': courseId,
        if (schoolId != null) 'schoolId': schoolId,
        if (termId != null) 'termId': termId,
        if (students != null) 'students': students,
      };
}

class PaymentMethodOption {
  final String id;
  final String label;
  final bool enabled;
  const PaymentMethodOption(this.id, this.label, this.enabled);

  static const defaults = [
    PaymentMethodOption('mtn_momo', 'MTN MoMo', true),
    PaymentMethodOption('airtel_money', 'Airtel Money', true),
    PaymentMethodOption('card', 'Card', true),
  ];
}

class CheckoutState {
  final String reference;
  final String status; // pending | completed | approved | admin_review | failed | cancelled
  final String? message;
  final num amount;
  final String paymentMethod;
  final String? phone;
  final String? paymentUrl;
  final String? failureReason;
  final DateTime? timeoutAt;

  const CheckoutState({
    required this.reference,
    required this.status,
    required this.amount,
    required this.paymentMethod,
    this.message,
    this.phone,
    this.paymentUrl,
    this.failureReason,
    this.timeoutAt,
  });

  bool get isPending => status == 'pending';
  bool get isPaid => status == 'completed' || status == 'approved';
  /// Money arrived but ECH has to finish the order by hand.
  bool get isInReview => status == 'admin_review';
  bool get isFailed => status == 'failed' || status == 'cancelled';

  factory CheckoutState.fromJson(Map<String, dynamic> j, {String? message}) => CheckoutState(
        reference: j['reference']?.toString() ?? '',
        status: j['status']?.toString() ?? 'pending',
        message: j['message']?.toString() ?? message,
        amount: (j['amount'] as num?) ?? 0,
        paymentMethod: j['paymentMethod']?.toString() ?? '',
        phone: j['phone']?.toString(),
        paymentUrl: j['paymentUrl']?.toString(),
        failureReason: j['failureReason']?.toString(),
        timeoutAt: DateTime.tryParse(j['timeoutAt']?.toString() ?? '')?.toLocal(),
      );
}

class CheckoutService {
  final ApiClient _api;
  CheckoutService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  String get _base => '${ApiConfig.baseUrl}/payments';

  Map<String, dynamic> _body(http.Response r) {
    Map<String, dynamic>? body;
    try {
      body = jsonDecode(r.body) as Map<String, dynamic>;
    } catch (_) {}
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw CheckoutException(
        body?['message']?.toString() ?? 'Something went wrong (HTTP ${r.statusCode}). Please try again.',
        status: r.statusCode,
        payment: body?['payment'] is Map ? Map<String, dynamic>.from(body!['payment']) : null,
      );
    }
    return body ?? const {};
  }

  Future<T> _wrap<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on CheckoutException {
      rethrow;
    } on ApiException catch (e) {
      throw CheckoutException(e.message, status: e.statusCode);
    } catch (_) {
      throw CheckoutException('Could not reach the server. Check your connection and try again.');
    }
  }

  Future<List<PaymentMethodOption>> methods() async {
    try {
      final b = _body(await _api.get('$_base/checkout/methods'));
      final list = ((b['data']?['methods'] as List?) ?? const [])
          .map((m) => PaymentMethodOption(m['id'].toString(), m['label'].toString(), m['enabled'] == true))
          .toList();
      return list.isEmpty ? PaymentMethodOption.defaults : list;
    } catch (_) {
      return PaymentMethodOption.defaults;
    }
  }

  Future<CheckoutState> start(CheckoutItem item, {required String method, String? phone, String? email}) => _wrap(() async {
        final b = _body(await _api.post('$_base/checkout', body: {
          ...item.toJson(),
          'paymentMethod': method,
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
          if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        }));
        return CheckoutState.fromJson(Map<String, dynamic>.from(b['data'] as Map), message: b['message']?.toString());
      });

  Future<CheckoutState> status(String reference) => _wrap(() async {
        final b = _body(await _api.get('$_base/checkout/${Uri.encodeComponent(reference)}'));
        return CheckoutState.fromJson(Map<String, dynamic>.from(b['data'] as Map));
      });

  /// Admin: ask iTechPay again right now.
  Future<CheckoutState> recheck(String paymentId) => _wrap(() async {
        final b = _body(await _api.post('$_base/$paymentId/recheck', body: const {}));
        return CheckoutState.fromJson(Map<String, dynamic>.from(b['data'] as Map));
      });
}
