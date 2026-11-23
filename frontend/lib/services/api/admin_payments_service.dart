import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../models/payment.dart';
import '../infrastructure/api_client.dart';

/// Super-admin payments: server-side filtered list and the revenue overview.
class AdminPaymentsQuery {
  final String? status; // pending | admin_review | approved | completed | failed | cancelled
  final String? purpose; // course | teacher_guide | school_term
  final String? channel; // online | manual
  final String? method; // mtn_momo | airtel_money | card | free
  final bool attention;
  final String search;

  const AdminPaymentsQuery({this.status, this.purpose, this.channel, this.method, this.attention = false, this.search = ''});

  AdminPaymentsQuery copyWith({
    Object? status = _keep,
    Object? purpose = _keep,
    Object? channel = _keep,
    Object? method = _keep,
    bool? attention,
    String? search,
  }) =>
      AdminPaymentsQuery(
        status: status == _keep ? this.status : status as String?,
        purpose: purpose == _keep ? this.purpose : purpose as String?,
        channel: channel == _keep ? this.channel : channel as String?,
        method: method == _keep ? this.method : method as String?,
        attention: attention ?? this.attention,
        search: search ?? this.search,
      );

  bool get isFiltered => status != null || purpose != null || channel != null || method != null || attention || search.trim().isNotEmpty;

  Map<String, String> toParams() => {
        if (status != null) 'status': status!,
        if (purpose != null) 'purpose': purpose!,
        if (channel != null) 'channel': channel!,
        if (method != null) 'method': method!,
        if (attention) 'attention': '1',
        if (search.trim().isNotEmpty) 'search': search.trim(),
      };
}

const _keep = Object();

class AdminPaymentsPage {
  final List<Payment> payments;
  final int total;
  final int page;
  final int totalPages;
  const AdminPaymentsPage(this.payments, this.total, this.page, this.totalPages);
}

class MoneyCount {
  final num revenue;
  final int count;
  const MoneyCount(this.revenue, this.count);
  static const zero = MoneyCount(0, 0);
  factory MoneyCount.fromJson(dynamic j) =>
      j is Map ? MoneyCount((j['revenue'] as num?) ?? 0, (j['count'] as num?)?.toInt() ?? 0) : zero;
}

class DailyRevenue {
  final DateTime date;
  final num revenue;
  final int count;
  const DailyRevenue(this.date, this.revenue, this.count);
}

class PaymentsOverview {
  final MoneyCount total;
  final MoneyCount thisMonth;
  final MoneyCount lastMonth;
  final Map<String, MoneyCount> byPurpose;
  final Map<String, MoneyCount> byMethod;
  final Map<String, MoneyCount> byChannel;
  final Map<String, int> statusCounts;
  final int needsAttention;
  final List<DailyRevenue> daily;
  final int online30Started;
  final int online30NotPaid;
  /// Built from the older /payments/stats endpoint (server not updated yet):
  /// totals and status counts only, no breakdowns or chart.
  final bool partial;

  const PaymentsOverview({
    this.partial = false,
    required this.total,
    required this.thisMonth,
    required this.lastMonth,
    required this.byPurpose,
    required this.byMethod,
    required this.byChannel,
    required this.statusCounts,
    required this.needsAttention,
    required this.daily,
    required this.online30Started,
    required this.online30NotPaid,
  });

  /// Change of this month's revenue vs last month, in percent (null when last month was 0).
  double? get monthChange => lastMonth.revenue == 0 ? null : (thisMonth.revenue - lastMonth.revenue) / lastMonth.revenue * 100;

  /// Share of revenue paid online through iTechPay (0–1).
  double get onlineShare => total.revenue == 0 ? 0 : (byChannel['online']?.revenue ?? 0) / total.revenue;

  int get allCount => statusCounts.values.fold(0, (a, b) => a + b);

  factory PaymentsOverview.fromJson(Map<String, dynamic> j) {
    Map<String, MoneyCount> mc(dynamic v) =>
        v is Map ? v.map((k, x) => MapEntry(k.toString(), MoneyCount.fromJson(x))) : <String, MoneyCount>{};
    final online = (j['online30'] as Map?) ?? const {};
    return PaymentsOverview(
      total: MoneyCount.fromJson(j['total']),
      thisMonth: MoneyCount.fromJson(j['thisMonth']),
      lastMonth: MoneyCount.fromJson(j['lastMonth']),
      byPurpose: mc(j['byPurpose']),
      byMethod: mc(j['byMethod']),
      byChannel: mc(j['byChannel']),
      statusCounts: (j['statusCounts'] is Map)
          ? (j['statusCounts'] as Map).map((k, v) => MapEntry(k.toString(), (v as num).toInt()))
          : const {},
      needsAttention: (j['needsAttention'] as num?)?.toInt() ?? 0,
      daily: ((j['daily'] as List?) ?? const [])
          .map((d) => DailyRevenue(
                DateTime.tryParse(d['date']?.toString() ?? '') ?? DateTime.now(),
                (d['revenue'] as num?) ?? 0,
                (d['count'] as num?)?.toInt() ?? 0,
              ))
          .toList(),
      online30Started: (online['started'] as num?)?.toInt() ?? 0,
      online30NotPaid: (online['notPaid'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminPaymentsService {
  final ApiClient _api;
  AdminPaymentsService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  String get _base => ApiConfig.payments;

  Map<String, dynamic> _data(http.Response r) {
    Map<String, dynamic>? body;
    try {
      body = jsonDecode(r.body) as Map<String, dynamic>;
    } catch (_) {}
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw ApiException(body?['message']?.toString() ?? 'Something went wrong (HTTP ${r.statusCode})', r.statusCode);
    }
    final d = body?['data'];
    return d is Map<String, dynamic> ? d : const {};
  }

  Future<AdminPaymentsPage> list(AdminPaymentsQuery q, {int page = 1, int limit = 25}) async {
    final d = _data(await _api.get(_base, queryParams: {...q.toParams(), 'page': '$page', 'limit': '$limit'}));
    final items = ((d['payments'] as List?) ?? const [])
        .whereType<Map>()
        .map((p) {
          try {
            return Payment.fromJson(Map<String, dynamic>.from(p));
          } catch (_) {
            return null; // one malformed record must not hide the rest
          }
        })
        .whereType<Payment>()
        .toList();
    return AdminPaymentsPage(
      items,
      (d['total'] as num?)?.toInt() ?? items.length,
      (d['currentPage'] as num?)?.toInt() ?? page,
      (d['totalPages'] as num?)?.toInt() ?? 1,
    );
  }

  /// Revenue overview. Falls back to the older /payments/stats endpoint when the
  /// server doesn't have /payments/admin/overview yet (not deployed), so the
  /// summary still shows totals instead of loading forever.
  Future<PaymentsOverview> overview() async {
    try {
      final d = _data(await _api.get('$_base/admin/overview'));
      if (d['total'] is Map) return PaymentsOverview.fromJson(d);
      throw ApiException('Unexpected overview response');
    } catch (e) {
      try {
        return _fromStats(_data(await _api.get('$_base/stats')));
      } catch (_) {
        rethrow; // report the original problem
      }
    }
  }

  PaymentsOverview _fromStats(Map<String, dynamic> d) {
    int n(String k) => (d[k] as num?)?.toInt() ?? 0;
    final counts = {
      'pending': n('pendingPayments'),
      'admin_review': n('adminReviewPayments'),
      'approved': n('approvedPayments'),
      'completed': n('completedPayments'),
      'failed': n('failedPayments'),
      'cancelled': n('cancelledPayments'),
    };
    final paid = counts['approved']! + counts['completed']!;
    return PaymentsOverview(
      partial: true,
      total: MoneyCount((d['totalRevenue'] as num?) ?? 0, paid),
      thisMonth: MoneyCount.zero,
      lastMonth: MoneyCount.zero,
      byPurpose: const {},
      byMethod: const {},
      byChannel: const {},
      statusCounts: counts,
      needsAttention: counts['pending']! + counts['admin_review']!,
      daily: const [],
      online30Started: 0,
      online30NotPaid: 0,
    );
  }
}
