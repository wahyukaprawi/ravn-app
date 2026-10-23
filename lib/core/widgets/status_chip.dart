import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  Color get _color {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.success;
      case 'pending':
      case 'held':
        return AppColors.warning;
      case 'rejected':
      case 'canceled':
        return AppColors.danger;
      default:
        return AppColors.textMuted;
    }
  }

  String get _label {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'held':
        return 'Held';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'canceled':
        return 'Canceled';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
