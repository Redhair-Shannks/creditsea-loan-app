import '../../../core/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/loan_status_style.dart';
import '../../../data/models/loan.dart';
import '../../../data/models/loan_config.dart';

/// The in-progress loan, with the next action (track, finish verification, repay).
class ActiveLoanCard extends StatelessWidget {
  const ActiveLoanCard({super.key, required this.loan, required this.onTrack, required this.onRepay});

  final Loan loan;
  final VoidCallback onTrack;
  final VoidCallback onRepay;

  @override
  Widget build(BuildContext context) {
    final step = loan.nextVerificationStep;
    return SectionCard(
      title: 'Current loan',
      trailing: StatusPill(label: loan.status.label, color: loan.status.color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Fmt.inr(loan.principal), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(
            '#${loan.applicationNo} · ${loan.tenureDays} days · ${loan.purpose}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          if (loan.status == LoanStatus.disbursed) ...[
            const SizedBox(height: 14),
            InfoRow('Outstanding', Fmt.inr(loan.outstanding), valueColor: AppColors.textPrimary, bold: true),
            if (loan.dueDate != null)
              InfoRow(
                loan.isOverdue ? 'Overdue since' : 'Due on',
                Fmt.date(loan.dueDate!),
                valueColor: loan.isOverdue ? AppColors.error : AppColors.textPrimary,
              ),
          ] else if (loan.latestNote != null) ...[
            const SizedBox(height: 12),
            Text(loan.latestNote!, style: const TextStyle(fontSize: 13, height: 1.4)),
          ],
          const SizedBox(height: 16),
          if (loan.status == LoanStatus.disbursed)
            Row(
              children: [
                Expanded(child: AppButton(label: 'Track', outlined: true, onPressed: onTrack)),
                const SizedBox(width: 12),
                Expanded(child: AppButton(label: 'Repay now', onPressed: onRepay)),
              ],
            )
          else
            AppButton(
              label: step != null ? 'Complete ${step.title}' : 'Track application',
              outlined: step == null,
              onPressed: onTrack,
            ),
        ],
      ),
    );
  }
}

/// Call to action when there is no active loan.
class ApplyLoanCard extends StatelessWidget {
  const ApplyLoanCard({super.key, required this.limit, required this.onApply, this.config});

  /// Pre-approved limit (null = unknown, 0 = currently not eligible).
  final int? limit;
  final LoanConfig? config;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final headline = switch (limit) {
      null => 'Instant personal loans',
      0 => 'Check your eligibility',
      final amount => 'Get up to ${Fmt.inr(amount)}',
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.brandBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt_rounded, color: AppColors.mint, size: 20),
              SizedBox(width: 6),
              Text('Money in 30 minutes', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Text(headline, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            switch ((limit, config)) {
              (0, _) => 'Your current profile does not qualify yet. See what is needed.',
              (_, final LoanConfig c) =>
                '${c.minTenureDays}-${c.maxTenureDays} day tenure · ${Fmt.percent(c.interestPerDayPct)} interest per day · no paperwork',
              _ => 'Quick approval · no paperwork',
            },
            style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onApply,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary),
              child: const Text('Apply for loan'),
            ),
          ),
        ],
      ),
    );
  }
}

/// One past application in "My loans".
class LoanTile extends StatelessWidget {
  const LoanTile({super.key, required this.loan, required this.onTap});

  final Loan loan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: loan.status.color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(Icons.receipt_long_outlined, size: 20, color: loan.status.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${Fmt.inr(loan.principal)} · ${loan.purpose}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('#${loan.applicationNo} · ${Fmt.date(loan.createdAt)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              StatusPill(label: loan.status.label, color: loan.status.color),
            ],
          ),
        ),
      );
}
