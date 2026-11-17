import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/presentation/providers/notification_provider.dart';
import 'package:excellencecoachinghub/models/notification.dart' as app_notification;
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/l10n/app_localizations.dart';
import 'package:excellencecoachinghub/presentation/widgets/eexams_section.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
    Future.microtask(() => ref.read(notificationProvider.notifier).loadNotifications());
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getTimeAgo(BuildContext context, DateTime timestamp) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return l10n?.timeDaysAgo(difference.inDays) ?? '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return l10n?.timeHoursAgo(difference.inHours) ?? '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return l10n?.timeMinutesAgo(difference.inMinutes) ?? '${difference.inMinutes}m ago';
    } else {
      return l10n?.timeJustNow ?? 'Just now';
    }
  }

  IconData _getNotificationIcon(app_notification.Notification notification) {
    switch (notification.type) {
      case 'success':
        return Icons.check_circle_rounded;
      case 'info':
        return Icons.info_rounded;
      case 'achievement':
        return Icons.emoji_events_rounded;
      case 'warning':
        return Icons.warning_rounded;
      case 'error':
        return Icons.error_rounded;
      case 'payment':
        return Icons.receipt_long_rounded;
      case 'course':
        return Icons.school_rounded;
      case 'exam':
        return Icons.quiz_rounded;
      case 'reminder':
        return Icons.alarm_rounded;
      case 'promotion':
        return Icons.local_offer_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getNotificationColor(app_notification.Notification notification, BuildContext context) {
    switch (notification.type) {
      case 'success':
        return const Color(0xFF10B981);
      case 'info':
        return AppTheme.primaryGreen;
      case 'achievement':
        return const Color(0xFFF59E0B);
      case 'warning':
        return const Color(0xFFF97316);
      case 'error':
        return Theme.of(context).colorScheme.error;
      case 'payment':
        return const Color(0xFF10B981);
      case 'course':
        return AppTheme.primaryGreen;
      case 'exam':
        return const Color(0xFF3B82F6);
      case 'reminder':
        return const Color(0xFFF59E0B);
      case 'promotion':
        return const Color(0xFF8B5CF6);
      default:
        return AppTheme.greyColor;
    }
  }

  String _getTypeLabel(app_notification.Notification notification, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (notification.type) {
      case 'payment':
        return l10n?.notificationTypePayment ?? 'Payment';
      case 'course':
        return l10n?.notificationTypeCourse ?? 'Course';
      case 'exam':
        return l10n?.notificationTypeExam ?? 'Exam';
      case 'achievement':
        return l10n?.notificationTypeAchievement ?? 'Achievement';
      case 'reminder':
        return l10n?.notificationTypeReminder ?? 'Reminder';
      case 'promotion':
        return l10n?.notificationTypePromotion ?? 'Promotion';
      default:
        return notification.type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final notificationState = ref.watch(notificationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: _buildAppBar(context, l10n, notificationState, isDark),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          color: AppTheme.primaryGreen,
          onRefresh: () async {
            await ref.read(notificationProvider.notifier).loadNotifications();
          },
          child: _buildBody(context, l10n, notificationState, isDark),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AppLocalizations? l10n,
    dynamic notificationState,
    bool isDark,
  ) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: context.canPop()
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
              onPressed: () => context.pop(),
            )
          : null,
      title: Text(
        l10n?.notificationsScreenTitle ?? 'Notifications',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          thickness: 1,
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
        ),
      ),
      actions: [
        if (notificationState.notifications.isNotEmpty) ...[
          IconButton(
            icon: const Icon(Icons.done_all_rounded, size: 22),
            tooltip: l10n?.markAllAsRead ?? 'Mark all as read',
            onPressed: () {
              ref.read(notificationProvider.notifier).markAllAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n?.allNotificationsMarkedRead ?? 'All notifications marked as read'),
                  backgroundColor: AppTheme.primaryGreen,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, size: 22),
            tooltip: l10n?.deleteAll ?? 'Delete all',
            onPressed: () => _showDeleteAllConfirmation(context, l10n),
          ),
          const SizedBox(width: 4),
        ],
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations? l10n,
    dynamic notificationState,
    bool isDark,
  ) {
    if (notificationState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryGreen, strokeWidth: 2.5),
      );
    }

    if (notificationState.error != null) {
      return _buildErrorState(context, l10n, notificationState.error!, isDark);
    }

    if (notificationState.notifications.isEmpty) {
      return _buildEmptyState(context, l10n, isDark);
    }

    return ListView.builder(
      padding: ResponsiveBreakpoints.getPadding(context).copyWith(top: 12, bottom: 24),
      itemCount: notificationState.notifications.length,
      itemBuilder: (context, index) {
        final notification = notificationState.notifications[index] as app_notification.Notification;
        return _buildNotificationCard(context, l10n, notification, isDark);
      },
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    AppLocalizations? l10n,
    app_notification.Notification notification,
    bool isDark,
  ) {
    final color = _getNotificationColor(notification, context);
    final notificationNotifier = ref.read(notificationProvider.notifier);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 10, left: 16, right: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade300, Colors.red.shade600],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_rounded, color: Colors.white, size: 26),
            const SizedBox(height: 4),
            Text(
              l10n?.delete ?? 'Delete',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (direction) {
        notificationNotifier.deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.notificationDeleted ?? 'Notification deleted'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (!notification.isRead) {
              notificationNotifier.markAsRead(notification.id);
            }
            _handleNotificationAction(notification);
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: color.withOpacity(0.1),
          highlightColor: color.withOpacity(0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10, left: 16, right: 16),
            decoration: BoxDecoration(
              color: notification.isRead
                  ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                  : (isDark
                      ? color.withOpacity(0.08)
                      : color.withOpacity(0.04)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: notification.isRead
                    ? (isDark ? Colors.white10 : Colors.black.withOpacity(0.06))
                    : color.withOpacity(0.25),
                width: notification.isRead ? 1 : 1.5,
              ),
              boxShadow: notification.isRead
                  ? null
                  : [
                      BoxShadow(
                        color: color.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon container with unread indicator
                  Stack(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          _getNotificationIcon(notification),
                          color: color,
                          size: 22,
                        ),
                      ),
                      if (!notification.isRead)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
                                  fontSize: 15,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  height: 1.3,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 4, left: 8),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        notification.message,
                        style: TextStyle(
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          fontSize: 13,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          // Type chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getTypeLabel(notification, context),
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Time
                          Text(
                            _getTimeAgo(context, notification.timestamp),
                            style: TextStyle(
                              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations? l10n, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 48,
                color: AppTheme.primaryGreen.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n?.noNotificationsYet ?? 'No notifications yet',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n?.noNotificationsYetSubtitle ?? 'You\'ll see important updates here',
              style: TextStyle(
                color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    AppLocalizations? l10n,
    String error,
    bool isDark,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: Colors.red.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n?.failedToLoadNotifications ?? 'Failed to load notifications',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              error,
              style: TextStyle(
                color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => ref.read(notificationProvider.notifier).loadNotifications(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n?.retry ?? 'Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAllConfirmation(BuildContext context, AppLocalizations? l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          l10n?.deleteAllNotifications ?? 'Delete All Notifications',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: Text(
          l10n?.deleteAllNotificationsConfirm ??
              'Are you sure you want to delete all notifications? This action cannot be undone.',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : const Color(0xFF64748B),
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n?.cancel ?? 'Cancel',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(notificationProvider.notifier).deleteAllNotifications();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n?.allNotificationsDeleted ?? 'All notifications deleted'),
                  backgroundColor: AppTheme.primaryGreen,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade400),
            child: Text(
              l10n?.deleteAll ?? 'Delete All',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNotificationAction(app_notification.Notification notification) {
    switch (notification.type) {
      case 'payment':
        context.push('/payments/history');
        break;
      case 'course':
        context.push('/my-courses');
        break;
      case 'exam':
        // eexams.net result → open that result on eexams, already signed in.
        final data = notification.data;
        final reviewPath = data?['reviewPath'];
        if (data?['source'] == 'eexams' && reviewPath is String && reviewPath.startsWith('/')) {
          openEexams(context, redirect: reviewPath);
        } else {
          context.push('/exams/history');
        }
        break;
      case 'achievement':
        context.push('/profile');
        break;
      default:
        break;
    }
  }
}