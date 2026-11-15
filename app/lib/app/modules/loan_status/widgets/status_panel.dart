import '../../../core/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/loan.dart';

/// The message under the timeline ("Application Under Review ... Thank you for your patience.").
class StatusPanel extends StatelessWidget {
  const StatusPanel({super.key, required this.loan});

  final Loan loan;

  @override
  Widget build(BuildContext context) {
    final step = loan.nextVerificationStep;
    final (IconData icon, Color color, String title, String message) = switch (loan.status) {
      LoanStatus.submitted || LoanStatus.underReview => (
          Icons.content_paste_search_rounded,
          AppColors.primary,
          'Application Under Review',
          "We're carefully reviewing your application to ensure everything is in order. Thank you for your patience.",
        ),
      LoanStatus.approved when step != null => (
          Icons.verified_rounded,
          AppColors.success,
          'Loan approved!',
          'Complete E-KYC, E-NACH and E-Sign to receive ${Fmt.inr(loan.disbursalAmount)} in your bank account. '
              'Next: ${step.description.toLowerCase()}.',
        ),
      LoanStatus.approved => (
          Icons.account_balance_rounded,
          AppColors.primary,
          'Disbursal in progress',
          "All steps are done. We're transferring ${Fmt.inr(loan.disbursalAmount)} to your bank account.",
        ),
      LoanStatus.rejected => (
          Icons.cancel_rounded,
          AppColors.error,
          'Application not approved',
          loan.rejectionReasons.isEmpty
              ? 'Unfortunately we cannot approve this application.'
              : loan.rejectionReasons.join('\n'),
        ),
      LoanStatus.disbursed => (
          Icons.account_balance_wallet_rounded,
          loan.isOverdue ? AppColors.error : AppColors.teal,
          '${Fmt.inr(loan.disbursalAmount)} credited',
          loan.dueDate == null
              ? 'Repay ${Fmt.inr(loan.outstanding)} to close your loan.'
              : '${loan.isOverdue ? 'Overdue: repay' : 'Repay'} ${Fmt.inr(loan.outstanding)} by ${Fmt.date(loan.dueDate!)} to close your loan.',
        ),
      LoanStatus.closed => (
          Icons.celebration_rounded,
          AppColors.success,
          'Loan closed',
          'Thank you for repaying ${Fmt.inr(loan.totalPayable)}. Timely repayments raise your CreditSea score.',
        ),
    };

    return Column(
      children: [
        Icon(icon, size: 40, color: color),
        const SizedBox(height: 10),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.45),
        ),
        if (loan.isProcessing) ...[
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox.square(dimension: 12, child: CircularProgressIndicator(strokeWidth: 1.6)),
              SizedBox(width: 8),
              Text('This page updates automatically', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ],
    );
  }
}
