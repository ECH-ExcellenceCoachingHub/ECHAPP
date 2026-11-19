import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';

/// Wrapper for school admin screens: only users with role `admin` or
/// `school_admin` may enter; everyone else is redirected.
class SchoolAdminLayoutWrapper extends ConsumerStatefulWidget {
  final Widget child;
  final String? screenName;

  const SchoolAdminLayoutWrapper({
    super.key,
    required this.child,
    this.screenName,
  });

  @override
  ConsumerState<SchoolAdminLayoutWrapper> createState() =>
      _SchoolAdminLayoutWrapperState();
}

class _SchoolAdminLayoutWrapperState
    extends ConsumerState<SchoolAdminLayoutWrapper> {
  bool _hasInitialized = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      if (next.user == null && !next.isLoading) {
        Future.microtask(() {
          if (mounted) _redirectToAuthScreen();
        });
      }
    });

    if (!_hasInitialized) {
      _hasInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAuthenticationAndRedirect();
      });
    }

    return widget.child;
  }

  void _checkAuthenticationAndRedirect() {
    final authState = ref.read(authProvider);
    if (authState.user == null && !authState.isLoading) {
      _redirectToAuthScreen();
    } else if (authState.user != null &&
        authState.user!.role != 'admin' &&
        authState.user!.role != 'school_admin') {
      Future.microtask(() {
        if (mounted) context.go('/dashboard');
      });
    }
  }

  void _redirectToAuthScreen() {
    if (!mounted) return;
    final isDesktop = !kIsWeb && (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS);
    if (isDesktop) {
      context.go('/email-auth-option');
    } else {
      context.go('/auth-selection');
    }
  }
}
