import '../../../core/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/nav.dart';
import '../../../core/widgets/app_button.dart';

/// "Waiting for UPI approval" while the (sandbox) payment is processed.
class UpiProcessingDialog extends StatelessWidget {
  const UpiProcessingDialog({super.key});

  @override
  Widget build(BuildContext context) => const PopScope(
        canPop: false,
        child: Dialog(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(dimension: 40, child: CircularProgressIndicator(strokeWidth: 3)),
                SizedBox(height: 18),
                Text('Waiting for UPI approval', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(height: 6),
                Text(
                  'Approve the request in your UPI app. Do not press back.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
}

class PaymentSuccessDialog extends StatelessWidget {
  const PaymentSuccessDialog({
    super.key,
    required this.amount,
    required this.reference,
    required this.scoreAfter,
    required this.loanClosed,
    this.scoreBefore,
  });

  final int amount;
  final String reference;
  final int? scoreBefore;
  final int scoreAfter;
  final bool loanClosed;

  @override
  Widget build(BuildContext context) {
    final delta = scoreBefore == null ? null : scoreAfter - scoreBefore!;
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.successSoft,
              child: Icon(Icons.check_rounded, size: 34, color: AppColors.success),
            ),
            const SizedBox(height: 14),
            const Text('Payment successful', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(Fmt.inr(amount), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('UPI ref: $reference', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            if (delta != null && delta > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: AppColors.successSoft, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up_rounded, color: AppColors.success, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Credit score $scoreBefore → $scoreAfter (+$delta)',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.success),
                    ),
                  ],
                ),
              ),
            ],
            if (loanClosed) ...[
              const SizedBox(height: 12),
              const Text(
                'Your loan is fully repaid and closed. Thank you!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13),
              ),
            ],
            const SizedBox(height: 20),
            AppButton(label: 'Done', onPressed: () => Nav.pop()),
          ],
        ),
      ),
    );
  }
}
