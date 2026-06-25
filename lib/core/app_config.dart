import 'package:flutter/material.dart';

// Central place for anything that might change between environments.
class AppConfig {
  // Your live backend. Change this one line to point at a different server.
  static const String baseUrl = 'http://165.22.247.79:8080';
  static const String apiPrefix = '/api';
}

// Plain, readable palette for an internal admin tool.
class AppColors {
  static const Color primary = Color(0xFF0B3D2E); // deep green (matches brand)
  static const Color primaryLight = Color(0xFF2F8F6F);
  static const Color bg = Color(0xFFF5F7F6);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE1E8E5);
  static const Color text = Color(0xFF1F2933);
  static const Color textMuted = Color(0xFF6B7280);

  static const Color success = Color(0xFF2F8F6F);
  static const Color warning = Color(0xFFB8881D);
  static const Color danger = Color(0xFFC0392B);
  static const Color info = Color(0xFF1D6FB8);
}

// Status → color helper used across tables/badges.
Color statusColor(String? status) {
  switch ((status ?? '').toLowerCase()) {
    case 'approved':
    case 'delivered':
    case 'completed':
    case 'verified':
    case 'paid':
    case 'active':
      return AppColors.success;
    case 'pending':
    case 'processing':
    case 'submitted':
    case 'dispatched':
      return AppColors.warning;
    case 'rejected':
    case 'cancelled':
    case 'inactive':
      return AppColors.danger;
    default:
      return AppColors.info;
  }
}
