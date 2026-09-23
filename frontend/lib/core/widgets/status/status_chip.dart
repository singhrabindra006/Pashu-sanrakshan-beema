import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../utils/extensions.dart';

/// Renders any application/claim/animal status with a consistent colour code.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.compact = false});

  final String status;
  final bool compact;

  Color get _color => switch (status.toUpperCase()) {
        'PENDING' || 'SUBMITTED' => AppColors.pending,
        'APPROVED' || 'ACTIVE' => AppColors.approved,
        'REJECTED' || 'INACTIVE' || 'EXPIRED' => AppColors.rejected,
        _ => AppColors.info,
      };

  IconData get _icon => switch (status.toUpperCase()) {
        'PENDING' => Icons.hourglass_top_rounded,
        'SUBMITTED' => Icons.upload_file_rounded,
        'APPROVED' || 'ACTIVE' => Icons.verified_rounded,
        'REJECTED' => Icons.cancel_rounded,
        'INACTIVE' => Icons.pause_circle_outline_rounded,
        'EXPIRED' => Icons.event_busy_rounded,
        _ => Icons.info_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 4 : 5),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: compact ? 12 : 14, color: _color),
          const SizedBox(width: 5),
          Text(
            status.humanised,
            style: TextStyle(
              color: _color,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
