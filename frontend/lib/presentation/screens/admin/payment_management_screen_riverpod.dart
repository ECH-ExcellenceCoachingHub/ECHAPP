import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/app_theme.dart';
import '../../../presentation/providers/payment_riverpod_provider.dart';
import '../../../models/payment.dart';
import '../../../models/payment_status.dart';
import '../../../services/api/payment_api_service.dart';
import '../../../services/api/checkout_service.dart';

class PaymentManagementScreen extends ConsumerStatefulWidget {
  const PaymentManagementScreen({super.key});

  @override
  ConsumerState<PaymentManagementScreen> createState() => _PaymentManagementScreenState();
}

class _PaymentManagementScreenState extends ConsumerState<PaymentManagementScreen> {
  bool _hasLoaded = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Load data once when widget is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final paymentState = ref.read(paymentProvider);
      if (!_hasLoaded && !paymentState.isLoading) {
        _hasLoaded = true;
        final paymentNotifier = ref.read(paymentProvider.notifier);
        print('PaymentManagementScreen: Initial loading of payments and stats');
        paymentNotifier.loadPayments();
        paymentNotifier.loadPaymentStats();
        
        // Start periodic refresh every 30 seconds to catch new payments
        _startPeriodicRefresh();
      }
    });
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      final paymentNotifier = ref.read(paymentProvider.notifier);
      print('PaymentManagementScreen: Auto-refreshing payments');
      
      // Show a subtle indicator that we're checking for new payments
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checking for new payments...'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.blue,
          ),
        );
      }
      
      paymentNotifier.loadPayments();
      paymentNotifier.loadPaymentStats();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentProvider);
    final paymentNotifier = ref.read(paymentProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: context.canPop() ? IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ) : null,
        title: const Text('Payment Management'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('PaymentManagementScreen: Refresh button pressed');
              paymentNotifier.loadPayments();
              paymentNotifier.loadPaymentStats();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8.0), // Prevent bottom overflow
          child: Column(
            children: [
              // Filters and Search
              _buildFilters(ref, paymentState, paymentNotifier),
              
              // Statistics
              if (paymentState.stats != null) _buildStats(paymentState.stats!),
              
              // Payments List
              Expanded(
                child: _buildPaymentsList(ref, paymentState, paymentNotifier),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(WidgetRef ref, PaymentState state, PaymentStateNotifier notifier) {
    final searchController = TextEditingController(text: state.searchQuery);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: searchController,
            decoration: const InputDecoration(
              hintText: 'Search by transaction ID, user, or course...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => notifier.setSearchQuery(value),
          ),
          const SizedBox(height: 12),
          
          // Status filter chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('All', null, state, notifier),
                _buildFilterChip('Pending', PaymentStatus.pending, state, notifier),
                _buildFilterChip('Admin Review', PaymentStatus.adminReview, state, notifier),
                _buildFilterChip('Approved', PaymentStatus.approved, state, notifier),
                _buildFilterChip('Completed', PaymentStatus.completed, state, notifier),
                _buildFilterChip('Failed', PaymentStatus.failed, state, notifier),
                _buildFilterChip('Cancelled', PaymentStatus.cancelled, state, notifier),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, PaymentStatus? status, PaymentState state, PaymentStateNotifier notifier) {
    final isSelected = state.filterStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          notifier.setFilterStatus(selected ? status : null);
        },
        selectedColor: AppTheme.primary.withOpacity(0.2),
        backgroundColor: Colors.grey[200],
      ),
    );
  }

  Widget _buildStats(PaymentStatsResponse stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Statistics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard('Total', stats.totalPayments.toString(), Colors.blue),
              _buildStatCard('Pending', stats.pendingPayments.toString(), Colors.orange),
              _buildStatCard('Approved', stats.approvedPayments.toString(), Colors.green),
              _buildStatCard('Completed', stats.completedPayments.toString(), Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentsList(WidgetRef ref, PaymentState state, PaymentStateNotifier notifier) {
    if (state.isLoading && state.payments.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text(
              'Error loading payments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                print('PaymentManagementScreen: Retry button pressed');
                notifier.loadPayments();
                notifier.loadPaymentStats();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final payments = state.filteredPayments;
    
    if (payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No payments found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              state.searchQuery.isNotEmpty
                  ? 'Try adjusting your search criteria'
                  : 'No payments match the current filters',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        print('PaymentManagementScreen: Pull to refresh triggered');
        await notifier.loadPayments();
        await notifier.loadPaymentStats();
      },
      child: ListView.builder(
        itemCount: payments.length,
        itemBuilder: (context, index) {
          final payment = payments[index];
          return _buildPaymentCard(context, payment, state, notifier);
        },
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, Payment payment, PaymentState state, PaymentStateNotifier notifier) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.transactionId,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        payment.user?.fullName ?? 'Unknown User',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      Text(
                        payment.user?.email ?? '',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      if (payment.user?.phone != null && payment.user!.phone!.isNotEmpty)
                        Text(
                          payment.user!.phone!,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(payment.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    payment.statusDisplayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Course and Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (payment.isTeacherGuide)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                          child: const Text("TEACHER'S GUIDE REQUEST", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF3B82F6))),
                        ),
                      if (payment.isSchoolTerm || payment.isOnline)
                        Wrap(spacing: 6, children: [
                          if (payment.isSchoolTerm) _tag('SCHOOL TERM', const Color(0xFF7C3AED)),
                          if (payment.isOnline) _tag('ONLINE · iTechPay', const Color(0xFF059669)),
                        ]),
                      Text(
                        payment.isSchoolTerm
                            ? '${payment.schoolName ?? 'School'}${payment.seats != null ? ' · ${payment.seats} students' : ''}'
                            : payment.course?.title ?? 'Unknown Course',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (payment.isOnline && payment.gatewayReference != null)
                        Text(
                          'Ref ${payment.gatewayReference} · iTechPay: ${payment.gatewayStatus ?? '—'}'
                          '${payment.failureReason != null ? ' · ${payment.failureReason}' : ''}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        '${payment.amount} ${payment.currency}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Payment Method: ${payment.paymentMethod}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Payment Date and Contact Info
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Requested: ${_formatDate(payment.createdAt)}',
                    style: TextStyle(color: Colors.grey[700], fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Contact: ${payment.contactInfo}',
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Action Buttons
            Wrap(
              alignment: WrapAlignment.end,
              runSpacing: 8,
              children: [
                if (payment.isOnline && payment.status != PaymentStatus.completed && payment.status != PaymentStatus.approved) ...[
                  OutlinedButton.icon(
                    onPressed: state.isProcessing ? null : () => _recheckOnline(context, payment, notifier),
                    icon: const Icon(Icons.sync, size: 16),
                    label: const Text('Check with iTechPay'),
                  ),
                  const SizedBox(width: 8),
                ],
                if (payment.canBeApproved) ...[
                  OutlinedButton(
                    onPressed: state.isProcessing ? null : () => _showApproveDialog(context, payment, notifier, state.isProcessing),
                    child: const Text('Approve'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: state.isProcessing ? null : () => _showRejectDialog(context, payment, notifier, state.isProcessing),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Reject'),
                  ),
                ],
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: state.isProcessing ? null : () => _showDeleteDialog(context, payment, notifier, state.isProcessing),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    backgroundColor: Colors.red.withOpacity(0.1),
                  ),
                  child: const Text('Delete'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: state.isProcessing ? null : () => _downloadInvoice(context, payment, notifier, state.isProcessing),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    backgroundColor: Colors.blue.withOpacity(0.1),
                  ),
                  child: const Text('Download Invoice'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _showPaymentDetails(context, payment),
                  child: const Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      }
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatDetailedDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.adminReview:
        return Colors.blue;
      case PaymentStatus.approved:
        return Colors.green;
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.cancelled:
        return Colors.grey;
    }
  }

  Widget _tag(String text, Color color) => Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
      );

  /// Online payment: ask iTechPay now; if it was paid, access is granted on the spot.
  Future<void> _recheckOnline(BuildContext context, Payment payment, PaymentStateNotifier notifier) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final s = await CheckoutService().recheck(payment.id);
      messenger.showSnackBar(SnackBar(
        content: Text(s.isPaid ? 'Paid — access granted.' : 'iTechPay says: ${s.message ?? s.status}'),
        backgroundColor: s.isPaid ? Colors.green : null,
      ));
      await notifier.loadPayments();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  void _showApproveDialog(BuildContext context, Payment payment, PaymentStateNotifier notifier, bool isProcessing) {
    final notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to approve payment ${payment.transactionId}?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Admin Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: isProcessing
                ? null
                : () {
                    Navigator.pop(context);
                    notifier.verifyPayment(
                      paymentId: payment.id,
                      status: PaymentStatus.approved,
                      adminNotes: notesController.text,
                    );
                  },
            child: isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, Payment payment, PaymentStateNotifier notifier, bool isProcessing) {
    final notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to reject payment ${payment.transactionId}?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Reason for Rejection',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: isProcessing
                ? null
                : () {
                    Navigator.pop(context);
                    notifier.verifyPayment(
                      paymentId: payment.id,
                      status: PaymentStatus.failed,
                      adminNotes: notesController.text,
                    );
                  },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Payment payment, PaymentStateNotifier notifier, bool isProcessing) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete payment ${payment.transactionId}?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Warning: This action cannot be undone!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Payment record will be permanently deleted\n'
                    '• Associated enrollment will be removed if payment was approved\n'
                    '• User will lose access to the course if enrolled',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'User: ${payment.user?.fullName ?? 'Unknown User'}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              'Course: ${payment.course?.title ?? 'Unknown Course'}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            if (payment.isTeacherGuide)
              const Text(
                "Teacher's guide request — approving gives this teacher the course's guide and unlocks their teacher tools (not a student enrollment).",
                style: TextStyle(fontSize: 12, color: Color(0xFF3B82F6)),
              ),
            Text(
              'Amount: ${payment.amount} ${payment.currency}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: isProcessing
                ? null
                : () {
                    Navigator.pop(context);
                    notifier.deletePayment(payment.id);
                  },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _downloadInvoice(BuildContext context, Payment payment, PaymentStateNotifier notifier, bool isProcessing) {
  try {
    notifier.downloadInvoice(payment.id);
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Downloading invoice...'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  } catch (e) {
    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to download invoice: $e'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

void _showPaymentDetails(BuildContext context, Payment payment) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Transaction ID', payment.transactionId),
            _buildDetailRow('Status', payment.statusDisplayName),
            _buildDetailRow('Amount', '${payment.amount} ${payment.currency}'),
            _buildDetailRow('Payment Method', payment.paymentMethod),
            _buildDetailRow('Contact Info', payment.contactInfo),
            _buildDetailRow('Requested On', _formatDetailedDate(payment.createdAt)),
            if (payment.paymentDate != null)
              _buildDetailRow('Payment Date', _formatDetailedDate(payment.paymentDate!)),
            if (payment.adminApproval != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Admin Approval',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              _buildDetailRow('Approved By', payment.adminApproval!.approvedBy),
              _buildDetailRow('Approved At', _formatDetailedDate(payment.adminApproval!.approvedAt)),
              if (payment.adminApproval!.adminNotes != null)
                _buildDetailRow('Notes', payment.adminApproval!.adminNotes!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
