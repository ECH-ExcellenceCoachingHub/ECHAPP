import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/widgets/network_image_widget.dart';
import 'package:excellencecoachinghub/widgets/school_admin_layout_wrapper.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/l10n/app_localizations.dart';
import 'package:excellencecoachinghub/services/api/school_service.dart';

/// Dedicated profile screen for school admins.
/// Separate from the student profile so school admins manage their own
/// school-admin account details and school information.
class SchoolAdminProfileScreen extends ConsumerStatefulWidget {
  const SchoolAdminProfileScreen({super.key});

  @override
  ConsumerState<SchoolAdminProfileScreen> createState() =>
      _SchoolAdminProfileScreenState();
}

class _SchoolAdminProfileScreenState
    extends ConsumerState<SchoolAdminProfileScreen> {
  bool _isEditing = false;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  File? _imageFile;
  final _picker = ImagePicker();
  final _schoolService = SchoolService();

  Map<String, dynamic>? _school;
  bool _isLoadingSchool = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSchool();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _schoolService.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final user = ref.read(authProvider.select((state) => state.user));
    if (user != null) {
      _nameController.text = user.fullName;
      _emailController.text = user.email;
      _phoneController.text = user.phone ?? '';
    }
  }

  Future<void> _loadSchool() async {
    try {
      final school = await _schoolService.getSchool('me');
      if (!mounted) return;
      setState(() {
        _school = school;
        _isLoadingSchool = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingSchool = false;
      });
    }
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _loadUserData();
        _imageFile = null;
      }
    });
  }

  Future<void> _pickImage() async {
    if (!_isEditing) return;

    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${l10n?.errorPickingImage ?? 'Error picking image'}: $e',
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    try {
      await ref.read(authProvider.notifier).updateProfile(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        phone: _phoneController.text.trim(),
        imageFile: _imageFile,
      );

      if (mounted) {
        setState(() {
          _isEditing = false;
          _imageFile = null;
        });

        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.profileUpdated ?? 'Profile updated'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${l10n?.profileUpdateError ?? 'Error updating profile'}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (!_isEditing && next.user != null && next.user != previous?.user) {
        _nameController.text = next.user!.fullName;
        _emailController.text = next.user!.email;
        _phoneController.text = next.user!.phone ?? '';
      }
    });

    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final padding = ResponsiveBreakpoints.getPadding(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SchoolAdminLayoutWrapper(
      screenName: 'School Admin Profile',
      child: Scaffold(
        backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('School Admin Profile'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
            AppTheme.primaryGreen,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor ??
            Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = isDesktop ? 1000.0 : double.infinity;
                final horizontalPadding = isDesktop
                    ? (constraints.maxWidth - maxWidth) / 2
                    : 0.0;

                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          padding.left + horizontalPadding,
                          padding.top,
                          padding.right + horizontalPadding,
                          padding.bottom * 1.5,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 100,
                            maxWidth: maxWidth,
                          ),
                          child: Column(
                            children: [
                              _buildHeader(user),
                              const SizedBox(height: 30),

                              _buildProfileCard(user),
                              const SizedBox(height: 30),

                              if (_school != null || _isLoadingSchool) ...[
                                _buildSchoolInfoCard(),
                                const SizedBox(height: 30),
                              ],

                              _buildStatsSection(),
                              const SizedBox(height: 30),

                              _buildActionButtons(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (authState.isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _isEditing
          ? FloatingActionButton.extended(
              onPressed: authState.isLoading ? null : _saveProfile,
              label: Text(authState.isLoading
                  ? l10n.saving
                  : l10n.saveChanges),
              icon: authState.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ))
                  : const Icon(Icons.check_rounded),
              backgroundColor: AppTheme.primaryGreen,
            )
          : FloatingActionButton.extended(
              onPressed: _toggleEdit,
              label: Text(l10n.editProfile),
              icon: const Icon(Icons.edit_rounded),
              backgroundColor: AppTheme.primaryGreen,
            ),
          ),
        );
  }

  Widget _buildHeader(user) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final avatarSize = isDesktop ? 160.0 : 130.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isDesktop ? 40 : 30,
        horizontal: isSmallScreen ? 16 : 20,
      ),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/school-admin/dashboard');
                }
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.getBackgroundColor(context).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppTheme.getTextColor(context),
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    border: Border.all(
                      color: AppTheme.primaryGreen,
                      width: 3,
                    ),
                  ),
                  child: _imageFile != null
                      ? ClipOval(
                          child: Image.file(
                            _imageFile!,
                            width: avatarSize,
                            height: avatarSize,
                            fit: BoxFit.cover,
                          ),
                        )
                      : (user?.profilePicture != null &&
                          user!.profilePicture!.isNotEmpty
                          ? ClipOval(
                              child: NetworkImageWidget(
                                imageUrl: user.profilePicture!,
                                width: avatarSize,
                                height: avatarSize,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: avatarSize * 0.4,
                              color: AppTheme.primaryGreen,
                            )),
                ),
                if (_isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.fullName ?? 'Unknown User',
            style: TextStyle(
              fontSize: isDesktop ? 28 : 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'School Administrator',
            style: TextStyle(
              fontSize: isDesktop ? 16 : 14,
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (user?.email != null && user!.email!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              user.email!,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.getSecondaryTextColor(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileCard(user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: isDark ? 6 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppTheme.getCardColor(context),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.getTextColor(context),
              ),
            ),
            const SizedBox(height: 16),
            _buildEditableField(
              label: 'Full Name',
              controller: _nameController,
              icon: Icons.person_outline,
            ),
            const Divider(height: 24),
            _buildEditableField(
              label: 'Email Address',
              controller: _emailController,
              icon: Icons.email_outlined,
            ),
            const Divider(height: 24),
            _buildEditableField(
              label: 'Phone Number',
              controller: _phoneController,
              icon: Icons.phone_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      enabled: _isEditing,
      style: TextStyle(
        color: AppTheme.getTextColor(context),
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: AppTheme.getSecondaryTextColor(context),
        ),
        prefixIcon: Icon(icon, color: AppTheme.primaryGreen),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: AppTheme.getBackgroundColor(context).withOpacity(0.3),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppTheme.getBorderColor(context),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
        ),
      ),
    );
  }

  Widget _buildSchoolInfoCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_isLoadingSchool) {
      return Card(
        elevation: isDark ? 6 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: AppTheme.getCardColor(context),
        child: const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_school == null) {
      return Card(
        elevation: isDark ? 6 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: AppTheme.getCardColor(context),
        child: const Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text('No school information available'),
          ),
        ),
      );
    }

    final school = _school!;
    return Card(
      elevation: isDark ? 6 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppTheme.getCardColor(context),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.school,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'School Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'School Name',
              value: '${school['name']}',
              icon: Icons.school,
            ),
            const Divider(height: 24),
            _InfoRow(
              label: 'Plan',
              value: switch ((school['subscription'] as Map?)?['status']) { 'active' => 'Term paid', 'grace' => 'Grace period', 'trial' => 'Trial', 'expired' => 'Expired', _ => '—' },
              icon: Icons.payment,
            ),
            const Divider(height: 24),
            _InfoRow(
              label: 'Student Limit',
              value: '${(school['subscription'] as Map?)?['studentLimit'] ?? 0}',
              icon: Icons.people_outline,
            ),
            const Divider(height: 24),
            _InfoRow(
              label: 'Current Students',
              value: '${school['studentCount'] ?? 0}',
              icon: Icons.person_outline,
            ),
            const Divider(height: 24),
            _InfoRow(
              label: 'Teachers',
              value: '${school['teacherCount'] ?? 0}',
              icon: Icons.person,
            ),
            const Divider(height: 24),
            _InfoRow(
              label: 'Status',
              value: school['isActive'] != false ? 'Active' : 'Inactive',
              icon: school['isActive'] != false ? Icons.check_circle : Icons.error,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: isDark ? 6 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppTheme.getCardColor(context),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text('Manage your school from the dashboard.'),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.getErrorColor(context),
              side: BorderSide(
                color: AppTheme.getErrorColor(context).withOpacity(0.4),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              context.go('/school-admin/dashboard');
            },
            icon: const Icon(Icons.dashboard, size: 18),
            label: const Text('Back to Dashboard'),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.getSecondaryTextColor(context)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.getSecondaryTextColor(context),
                fontSize: 14,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.getTextColor(context),
          ),
        ),
      ],
    );
  }
}
