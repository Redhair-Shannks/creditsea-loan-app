import '../material.dart';

import '../../data/models/loan.dart';
import '../theme/app_colors.dart';

/// Colour per loan status, shared by Home, Status and Profile.
extension LoanStatusStyle on LoanStatus {
  Color get color => switch (this) {
        LoanStatus.submitted || LoanStatus.underReview => AppColors.primary,
        LoanStatus.approved => AppColors.success,
        LoanStatus.rejected => AppColors.error,
        LoanStatus.disbursed => AppColors.teal,
        LoanStatus.closed => AppColors.textSecondary,
      };
}

/// Colour for a credit score (300-900).
Color creditScoreColor(int score) => switch (score) {
      >= 750 => AppColors.success,
      >= 700 => const Color(0xFF5DB85C),
      >= 650 => AppColors.gold,
      >= 600 => AppColors.warning,
      _ => AppColors.error,
    };
