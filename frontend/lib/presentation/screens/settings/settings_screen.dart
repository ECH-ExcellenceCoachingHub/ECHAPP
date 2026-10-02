import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/feedback_provider.dart';
import 'package:excellencecoachinghub/widgets/modern_dialog.dart';
import 'package:excellencecoachinghub/l10n/app_localizations.dart';
import 'package:excellencecoachinghub/services/achievement_sound_service.dart';

// Providers for settings
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
final notificationsProvider = StateProvider<bool>((ref) => true);
final darkModeProvider = StateProvider<bool>((ref) => false);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

// Device binding policy widget for settings screen
class _SettingsDeviceBindingPolicy extends StatelessWidget {
  const _SettingsDeviceBindingPolicy();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0), // Light orange background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFB74D), // Orange border
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.security,
            color: Color(0xFFF57C00), // Orange icon
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.deviceWarningMessage,
              style: TextStyle(
                color: Color(0xFF333333), // Dark text for visibility
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _achievementSounds = AchievementSoundService.instance.isEnabled;

  @override
  void initState() {
    super.initState();
    AchievementSoundService.instance.loadEnabled().then((enabled) {
      if (mounted) setState(() => _achievementSounds = enabled);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    // Use selective watching to minimize rebuilds
    final isDarkMode = ref.watch(darkModeProvider);
    final notificationsEnabled = ref.watch(notificationsProvider);
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final padding = ResponsiveBreakpoints.getPadding(context);
    // Watch theme mode to trigger rebuilds
    ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: Colors.transparent, // Let MainLayout background show through
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = isDesktop ? 800.0 : double.infinity;
            final horizontalPadding = isDesktop ? (constraints.maxWidth - maxWidth) / 2 : 0.0;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                padding.left + horizontalPadding, 
                padding.top, 
                padding.right + horizontalPadding, 
                padding.bottom * 1.5
              ),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Device Security Policy
                  const _SettingsDeviceBindingPolicy(),
                  const SizedBox(height: 25),
                  
                  // Account Settings
                  _buildSection(
                    context,
                    l10n.accountSettings,
                    [
                      _buildSettingTile(
                        context,
                        icon: Icons.person_outline,
                        title: l10n.profileInformation,
                        subtitle: l10n.updatePersonalDetails,
                        onTap: () => context.push('/profile'),
                      ),
                      _buildNotificationTile(
                        context,
                        icon: Icons.notifications_outlined,
                        title: l10n.pushNotifications,
                        subtitle: l10n.receiveUpdates,
                        value: notificationsEnabled,
                        onChanged: (value) {
                          ref.read(notificationsProvider.notifier).state = value;
                          _showSnackbar(context, 
                            value ? l10n.notificationsEnabled : l10n.notificationsDisabled);
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 25),
                  
                  // Preferences
                  _buildSection(
                    context,
                    l10n.preferences,
                    [
                      _buildThemeTile(
                        context,
                        icon: Icons.dark_mode_outlined,
                        title: l10n.darkMode,
                        subtitle: isDarkMode ? l10n.darkTheme : l10n.lightTheme,
                        value: isDarkMode,
                        onChanged: (value) {
                          ref.read(darkModeProvider.notifier).state = value;
                          ref.read(themeModeProvider.notifier).state = 
                            value ? ThemeMode.dark : ThemeMode.light;
                          _showSnackbar(context,
                            value ? l10n.darkModeEnabled : l10n.lightModeEnabled);
                        },
                      ),
                      _buildNotificationTile(
                        context,
                        icon: Icons.music_note_outlined,
                        title: 'Achievement sounds',
                        subtitle: 'Play sounds when you complete lessons, quizzes and chapters',
                        value: _achievementSounds,
                        onChanged: (value) async {
                          setState(() => _achievementSounds = value);
                          await AchievementSoundService.instance.setEnabled(value);
                          // Let the learner hear what they just switched on.
                          if (value) {
                            AchievementSoundService.instance
                                .play(AchievementSound.achievementUnlocked);
                          }
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 25),
                  
                  // Support
                  _buildSection(
                    context,
                    l10n.support,
                    [
                      _buildSettingTile(
                        context,
                        icon: Icons.help_outline,
                        title: l10n.helpCenter,
                        subtitle: l10n.helpCenterSubtitle,
                        onTap: () => context.push('/help'),
                      ),
                      _buildSettingTile(
                        context,
                        icon: Icons.feedback_outlined,
                        title: l10n.sendFeedback,
                        subtitle: l10n.shareThoughts,
                        onTap: () => _showFeedbackDialog(context),
                      ),
                      _buildSettingTile(
                        context,
                        icon: Icons.info_outline,
                        title: l10n.about,
                        subtitle: l10n.appVersion,
                        onTap: () => _showAboutDialog(context),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 25),
                  
                  // Legal
                  _buildSection(
                    context,
                    l10n.legal,
                    [
                      _buildSettingTile(
                        context,
                        icon: Icons.privacy_tip_outlined,
                        title: l10n.privacyPolicy,
                        subtitle: l10n.readPrivacyPolicy,
                        onTap: () => context.push('/privacy'),
                      ),
                      _buildSettingTile(
                        context,
                        icon: Icons.description_outlined,
                        title: l10n.termsOfService,
                        subtitle: l10n.readTerms,
                        onTap: () => context.push('/terms'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Danger Zone
                  _buildDangerZone(context, l10n),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
              ? Colors.black.withOpacity(0.2)
              : AppTheme.greyColor.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isDarkMode
            ? AppTheme.greyColor.withOpacity(0.1)
            : AppTheme.greyColor.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark 
                  ? AppTheme.whiteColor 
                  : AppTheme.blackColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 14),
            Column(
              children: children,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Function onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryGreen.withOpacity(0.12),
                      AppTheme.primaryGreen.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
                child: Icon(icon, 
                  color: AppTheme.primaryGreen,
                  size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDarkMode 
                          ? AppTheme.whiteColor 
                          : AppTheme.blackColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.getSecondaryTextColor(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.primaryGreen.withOpacity(0.5),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryGreen.withOpacity(0.12),
                  AppTheme.primaryGreen.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: Icon(icon, 
              color: AppTheme.primaryGreen,
              size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDarkMode 
                      ? AppTheme.whiteColor 
                      : AppTheme.blackColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.getSecondaryTextColor(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primaryGreen,
            inactiveTrackColor: Colors.grey.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryGreen.withOpacity(0.12),
                  AppTheme.primaryGreen.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: Icon(icon, 
              color: AppTheme.primaryGreen,
              size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDarkMode 
                      ? AppTheme.whiteColor 
                      : AppTheme.blackColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.getSecondaryTextColor(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primaryGreen,
            inactiveTrackColor: Colors.grey.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF1E1E1E) 
          : AppTheme.whiteColor,
        border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.dangerZone,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            _buildDangerButton(
              context,
              icon: Icons.delete_outline,
              title: l10n.deleteAccount,
              subtitle: l10n.permanentlyDelete,
              color: Colors.red,
              onTap: () => _showDeleteAccountDialog(context),
            ),
            const SizedBox(height: 10),
            _buildDangerButton(
              context,
              icon: Icons.logout,
              title: l10n.signOut,
              subtitle: l10n.signOutAllDevices,
              color: Colors.orange,
              onTap: () => _showSignOutDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Function onTap,
  }) {
    return InkWell(
      onTap: () => onTap(),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: color.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color.withOpacity(0.7),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // Dialog methods
  void _showFeedbackDialog(BuildContext context) {
    final dialogL10n = AppLocalizations.of(context);
    if (dialogL10n == null) return;
    final feedbackController = TextEditingController();
    bool isSubmitting = false;

    showModernDialog(
      context: context,
      barrierDismissible: !isSubmitting,
      title: 'Send Feedback',
      icon: const Icon(Icons.feedback_outlined, color: AppTheme.primaryGreen, size: 32),
      content: StatefulBuilder(
        builder: (context, setDialogState) {
          return SizedBox(
            width: double.maxFinite,
            child: isSubmitting
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : TextField(
                    controller: feedbackController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: dialogL10n.howCanWeImprove,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
                      ),
                    ),
                  ),
          );
        },
      ),
      actions: [
        ModernDialogAction.cancel(
          onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
        ),
        StatefulBuilder(
          builder: (context, setDialogState) {
            return ModernDialogAction.confirm(
              text: 'Send',
              isLoading: isSubmitting,
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final content = feedbackController.text.trim();
                      if (content.isEmpty) {
                        _showSnackbar(context, dialogL10n.enterFeedback);
                        return;
                      }

                      setDialogState(() => isSubmitting = true);

                      final success = await ref.read(feedbackNotifierProvider.notifier).submitFeedback(content);

                      if (mounted) {
                        Navigator.of(context).pop();
                        if (success) {
                          _showSnackbar(context, dialogL10n.feedbackSent);
                        } else {
                          _showSnackbar(context, dialogL10n.feedbackFailed);
                        }
                      }
                    },
            );
          },
        ),
      ],
    );
  }

  void _showAboutDialog(BuildContext context) {
    final dialogL10n = AppLocalizations.of(context);
    if (dialogL10n == null) return;
    showAboutDialog(
      context: context,
      applicationName: dialogL10n.appName,
      applicationVersion: '1.0.0',
      applicationLegalese: dialogL10n.copyright,
      children: [
        Flexible(
          child: Text(
            dialogL10n.aboutApp,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.white70
                : AppTheme.greyColor),
          ),
        ),
      ],
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1E1E1E) 
            : AppTheme.whiteColor,
          title: Text('Terms of Service', 
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark 
                ? AppTheme.whiteColor 
                : AppTheme.blackColor)),
          content: const SizedBox(
            height: 200, // Set fixed height to prevent overflow
            child: SingleChildScrollView(
              child: Text(
                'By using this application, you agree to our terms of service...\n\n'
                '• You must be at least 13 years old\n'
                '• Content is for educational purposes only\n'
                '• Payments are non-refundable after 7 days\n'
                '• We reserve the right to terminate accounts\n\n'
                'Last updated: February 1, 2026',
                style: TextStyle(color: AppTheme.greyColor),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (context.canPop()) context.pop();
              },
              child: Text('Close', 
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? AppTheme.white70 
                    : AppTheme.greyColor)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final dialogL10n = AppLocalizations.of(context);
    if (dialogL10n == null) return;
    final passwordController = TextEditingController();
    bool isDeleting = false;
    String? localError;

    showModernDialog(
      context: context,
      barrierDismissible: false,
      title: 'Delete Account',
      icon: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 32),
      content: StatefulBuilder(
        builder: (context, setDialogState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dialogL10n.areYouSureDelete,
                style: const TextStyle(fontSize: 14, color: AppTheme.greyColor),
              ),
              const SizedBox(height: 20),
              if (localError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    localError!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              Text(
                dialogL10n.enterPasswordConfirm,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: dialogL10n.currentPassword,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        ModernDialogAction.cancel(
          onPressed: isDeleting ? null : () => Navigator.of(context).pop(),
        ),
        StatefulBuilder(
          builder: (context, setDialogState) {
            return ModernDialogAction.danger(
              text: 'Delete',
              isLoading: isDeleting,
              onPressed: isDeleting
                  ? null
                  : () async {
                      final password = passwordController.text.trim();
                      if (password.isEmpty) {
                        setDialogState(() => localError = dialogL10n.passwordRequired);
                        return;
                      }

                      setDialogState(() {
                        isDeleting = true;
                        localError = null;
                      });

                      try {
                        await ref.read(authProvider.notifier).deleteAccount(password);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          context.go('/splash');
                          _showSnackbar(context, dialogL10n.deleteAccount);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          setDialogState(() {
                            isDeleting = false;
                            localError = e.toString().replaceFirst('Exception: ', '');
                          });
                        }
                      }
                    },
            );
          },
        ),
      ],
    );
  }

  void _showSignOutDialog(BuildContext context) {
    final dialogL10n = AppLocalizations.of(context);
    if (dialogL10n == null) return;
    showModernDialog(
      context: context,
      title: dialogL10n.signOut,
      content: Text(
        dialogL10n.areYouSureSignOut,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14, color: AppTheme.greyColor),
      ),
      icon: const Icon(Icons.logout_rounded, color: Colors.orange, size: 32),
      actions: [
        ModernDialogAction.cancel(onPressed: () => Navigator.of(context).pop()),
        ModernDialogAction.custom(
          onPressed: () {
            Navigator.of(context).pop();
            ref.read(authProvider.notifier).logout();
            context.go('/login');
            _showSnackbar(context, dialogL10n.signOut);
          },
          text: dialogL10n.signOut,
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
      ],
    );
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
