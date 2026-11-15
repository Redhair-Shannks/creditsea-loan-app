import '../../core/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/flow_scaffold.dart';
import '../../core/widgets/illustrations.dart';
import '../../data/models/loan_quote.dart';
import 'loan_offer_controller.dart';

/// Figma "Offer".
class LoanOfferView extends GetView<LoanOfferController> {
  const LoanOfferView({super.key});

  @override
  Widget build(BuildContext context) {
    final assessment = controller.assessment;
    final offer = assessment.offer;
    return FlowScaffold(
      stage: FlowStage.offer,
      title: offer != null ? 'Our Offerings' : 'Eligibility check',
      body: offer != null ? _OfferBody(assessment: assessment, offer: offer) : _NotEligibleBody(assessment: assessment),
      bottom: offer != null
          ? Obx(
              () => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton(label: 'Accept Offer', loading: controller.busy.value, onPressed: controller.accept),
                  const SizedBox(height: 10),
                  AppButton(label: 'Modify Offer', outlined: true, onPressed: controller.modify),
                ],
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppButton(label: 'Review my profile', onPressed: controller.completeProfile),
                const SizedBox(height: 10),
                AppButton(label: 'Back', outlined: true, onPressed: controller.modify),
              ],
            ),
    );
  }
}

class _OfferBody extends StatelessWidget {
  const _OfferBody({required this.assessment, required this.offer});

  final LoanAssessment assessment;
  final LoanPricing offer;

  @override
  Widget build(BuildContext context) {
    const bold = TextStyle(fontWeight: FontWeight.w700);
    return Column(
      children: [
        const SizedBox(height: 12),
        const RupeeCoin(size: 76),
        const SizedBox(height: 28),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Congratulations! ', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
              const TextSpan(text: 'We can offer you '),
              TextSpan(text: 'Rs. ${Fmt.grouped(offer.principal)}', style: bold),
              const TextSpan(text: ' Amount Within '),
              const TextSpan(text: '30 minutes', style: bold),
              TextSpan(text: ' for ${offer.tenureDays} days, with a payable amount of '),
              TextSpan(text: 'Rs. ${Fmt.grouped(offer.totalPayable)}', style: bold),
              const TextSpan(text: '. Just with few more steps.'),
            ],
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, height: 1.55),
        ),
        const SizedBox(height: 8),
        const Text('Proceed further to accept the offer.', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        if (assessment.amountAdjusted) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.warningSoft, borderRadius: BorderRadius.circular(8)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You asked for ${Fmt.inr(assessment.requested.principal)}. Based on your income and credit score '
                    '(${assessment.creditScore}, ${assessment.creditBand}) your current limit is ${Fmt.inr(assessment.maxEligibleAmount)}.',
                    style: const TextStyle(fontSize: 12.5, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        SectionCard(
          title: 'Offer details',
          child: Column(
            children: [
              InfoRow('Loan amount', Fmt.inr(offer.principal)),
              InfoRow('Interest (${Fmt.percent(offer.interestPerDayPct)} per day)', Fmt.inr(offer.interest)),
              InfoRow('Processing fee (${Fmt.percent(offer.processingFeePct)})', '- ${Fmt.inr(offer.processingFee)}'),
              InfoRow('Credited to your account', Fmt.inr(offer.disbursalAmount)),
              const Divider(height: 16),
              InfoRow('Total payable in ${offer.tenureDays} days', Fmt.inr(offer.totalPayable), bold: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotEligibleBody extends StatelessWidget {
  const _NotEligibleBody({required this.assessment});

  final LoanAssessment assessment;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: IconIllustration(icon: Icons.policy_outlined, color: AppColors.warning)),
          const SizedBox(height: 20),
          const Text("We can't offer a loan right now", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text(
            'Here is how your profile matches our lending criteria:',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          for (final check in assessment.checks)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    check.passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    size: 20,
                    color: check.passed ? AppColors.success : AppColors.error,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(check.label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                        if (check.message != null)
                          Text(check.message!, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
}
