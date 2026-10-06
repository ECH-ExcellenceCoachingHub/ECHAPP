import 'package:flutter/material.dart';

class CategoryUtils {
  static IconData getCategoryIcon(String? categoryId, {String? name}) {
    final id = categoryId?.toLowerCase() ?? '';
    final categoryName = name?.toLowerCase() ?? '';

    // Specific coaching areas first, before the broader keyword matches below
    if (categoryName.contains('mental') || categoryName.contains('parent')) {
      return Icons.family_restroom_rounded;
    }
    if (categoryName.contains('entrepreneur')) {
      return Icons.rocket_launch_rounded;
    }
    if (categoryName.contains('laguange')) {
      return Icons.translate_rounded;
    }
    if (categoryName.contains('account') || categoryName.contains('finance')) {
      return Icons.account_balance_rounded;
    }
    if (categoryName.contains('leader') || categoryName.contains('manage')) {
      return Icons.groups_rounded;
    }
    if (categoryName.contains('primary')) {
      return Icons.backpack_rounded;
    }

    // Match by ID first
    if (id.contains('academic') || id.contains('school') || categoryName.contains('academic')) {
      return Icons.school_rounded;
    }
    if (id.contains('language') || categoryName.contains('language')) {
      return Icons.translate_rounded;
    }
    if (id.contains('business') || id.contains('entrepreneurship') || categoryName.contains('business')) {
      return Icons.rocket_launch_rounded;
    }
    if (id.contains('technical') || id.contains('digital') || id.contains('tech') || categoryName.contains('technical') || categoryName.contains('digital')) {
      return Icons.devices_other_rounded;
    }
    if (id.contains('professional') || categoryName.contains('professional')) {
      return Icons.business_center_rounded;
    }
    if (id.contains('job') || id.contains('career') || categoryName.contains('job') || categoryName.contains('career')) {
      return Icons.person_search_rounded;
    }
    if (id.contains('personal') || id.contains('corporate') || id.contains('development') || categoryName.contains('personal') || categoryName.contains('corporate')) {
      return Icons.psychology_rounded;
    }
    if (id == 'all') {
      return Icons.grid_view_rounded;
    }

    // Default icon
    return Icons.category_rounded;
  }

  static Color getCategoryColor(String? categoryId, {String? name}) {
    final id = categoryId?.toLowerCase() ?? '';
    final categoryName = name?.toLowerCase() ?? '';

    if (categoryName.contains('mental') || categoryName.contains('parent')) {
      return const Color(0xFFEC4899); // Pink
    }
    if (categoryName.contains('entrepreneur')) {
      return const Color(0xFFEF4444); // Red
    }
    if (categoryName.contains('laguange')) {
      return const Color(0xFF8B5CF6); // Purple
    }
    if (categoryName.contains('digital') || categoryName.contains('tech')) {
      return const Color(0xFF06B6D4); // Cyan
    }
    if (categoryName.contains('account') || categoryName.contains('finance')) {
      return const Color(0xFF14B8A6); // Teal
    }
    if (categoryName.contains('leader') || categoryName.contains('manage')) {
      return const Color(0xFFF59E0B); // Amber
    }
    if (categoryName.contains('job') || categoryName.contains('career')) {
      return const Color(0xFF3B82F6); // Blue
    }
    if (id.contains('academic') || categoryName.contains('academic')) {
      return const Color(0xFF10B981); // Emerald
    }
    if (id.contains('language') || categoryName.contains('language')) {
      return const Color(0xFF8B5CF6); // Purple
    }
    if (id.contains('business') || categoryName.contains('business')) {
      return const Color(0xFFEF4444); // Red
    }
    if (id.contains('technical') || id.contains('digital') || categoryName.contains('technical')) {
      return const Color(0xFF06B6D4); // Cyan
    }
    if (id.contains('professional') || categoryName.contains('professional') || id.contains('job')) {
      return const Color(0xFF3B82F6); // Blue
    }
    if (id.contains('personal') || categoryName.contains('personal')) {
      return const Color(0xFFF59E0B); // Amber
    }
    
    return const Color(0xFF10B981); // Default
  }
}
