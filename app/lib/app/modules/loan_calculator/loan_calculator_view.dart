import '../../core/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/nav.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/dashed_border.dart';
import '../../core/widgets/flow_scaffold.dart';
import '../../core/widgets/form_fields.dart';
import '../../core/widgets/skeleton.dart';
import '../../data/models/loan_config.dart';
import '../../data/models/loan_quote.dart';
import 'loan_calculator_controller.dart';

/// Figma "Loan Calculator".
class LoanCalculatorView extends GetView<LoanCalculatorController> {
  const LoanCalculatorView({super.key});

  @override
  Widget build(BuildContext context) => FlowScaffold(
        header: const Center(child: AppLogo(size: 30, tone: LogoTone.onLight)),
        title: 'Apply for loan',
        subtitle: const Text(
          "We've calculated your loan eligibility. Select your preferred loan amount and tenure.",
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
        ),
        body: Obx(() {
          final cfg = controller.config.value;
          if (cfg == null) {
            final error = controller.loadError.value;
            return error == null
                ? const FormSkeleton(rows: 3)
                : MessageState(
                    icon: Icons.cloud_off_rounded,
                    title: 'Could not load the calculator',
                    message: error,
                    action: SizedBox(width: 160, child: AppButton(label: 'Retry', onPressed: controller.loadConfig)),
                  );
          }
          return _CalculatorBody(controller: controller, config: cfg);
        }),
        bottom: Obx(
          () => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppButton(
                label: 'Apply',
                loading: controller.busy.value,
                onPressed: controller.config.value == null ? null : controller.apply,
              ),
              const SizedBox(height: 10),
              AppButton(label: 'Cancel', outlined: true, onPressed: () => Nav.pop()),
            ],
          ),
        ),
      );
}

class _CalculatorBody extends StatelessWidget {
  const _CalculatorBody({required this.controller, required this.config});

  final LoanCalculatorController controller;
  final LoanConfig config;

  // Its own Obx: values read here (sliders, preview) must be tracked by this builder,
  // not by the parent's, otherwise moving a slider would not rebuild the summary.
  @override
  Widget build(BuildContext context) => Obx(() => _build());

  Widget _build() {
    final pricing = controller.pricing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _RateChip(label: 'Interest Per Day', value: Fmt.percent(config.interestPerDayPct))),
            const SizedBox(width: 10),
            Expanded(child: _RateChip(label: 'Processing Fee', value: Fmt.percent(config.processingFeePct))),
          ],
        ),
        const SizedBox(height: 18),
        const Divider(),
        const SizedBox(height: 18),
        AppDropdownField<String>(
          label: 'Purpose of Loan',
          required: true,
          hint: 'Select purpose of loan',
          items: config.purposes,
          itemLabel: (p) => p,
          value: controller.purpose.value,
          onChanged: (p) => controller.purpose.value = p,
        ),
        if (controller.purposeError.value != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(controller.purposeError.value!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
          ),
        const SizedBox(height: 22),
        _SliderBlock(
          label: 'Principal Amount',
          valueText: '₹ ${Fmt.grouped(controller.principal.value)}',
          value: controller.principal.value.toDouble(),
          min: config.minAmount.toDouble(),
          max: config.maxAmount.toDouble(),
          divisions: (config.maxAmount - config.minAmount) ~/ config.amountStep,
          minLabel: Fmt.inr(config.minAmount),
          maxLabel: Fmt.inr(config.maxAmount),
          onChanged: controller.onAmountChanged,
          semanticLabel: 'Loan amount',
        ),
        const SizedBox(height: 8),
        _EligibilityHint(preview: controller.preview.value, checking: controller.checking.value),
        const SizedBox(height: 20),
        _SliderBlock(
          label: 'Tenure',
          valueText: '${controller.tenureDays.value} Days',
          value: controller.tenureDays.value.toDouble(),
          min: config.minTenureDays.toDouble(),
          max: config.maxTenureDays.toDouble(),
          divisions: config.maxTenureDays - config.minTenureDays,
          minLabel: '${config.minTenureDays} Days',
          maxLabel: '${config.maxTenureDays} Days',
          onChanged: controller.onTenureChanged,
          semanticLabel: 'Tenure in days',
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.teal, width: 1.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              InfoRow('Principal Amount', Fmt.inr(pricing.principal)),
              InfoRow(
                'Interest (${Fmt.percent(pricing.interestPerDayPct)} x ${pricing.tenureDays} days)',
                Fmt.inr(pricing.interest),
              ),
              InfoRow('Total Payable', Fmt.inr(pricing.totalPayable), bold: true),
              const Divider(height: 16),
              Text(
                'A ${Fmt.percent(pricing.processingFeePct)} processing fee (${Fmt.inr(pricing.processingFee)}) is deducted, '
                'so ${Fmt.inr(pricing.disbursalAmount)} is credited to your account.',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Thank you for choosing CreditSea. Please accept to proceed with the loan details.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, color: AppColors.teal, fontWeight: FontWeight.w600, height: 1.4),
        ),
      ],
    );
  }
}

class _RateChip extends StatelessWidget {
  const _RateChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => DashedBorder(
        child: Center(
          child: Text.rich(
            TextSpan(text: '$label ', children: [TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w700))]),
            style: const TextStyle(fontSize: 12),
          ),
        ),
      );
}

class _SliderBlock extends StatelessWidget {
  const _SliderBlock({
    required this.label,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.minLabel,
    required this.maxLabel,
    required this.onChanged,
    required this.semanticLabel,
  });

  final String label;
  final String valueText;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String minLabel;
  final String maxLabel;
  final ValueChanged<double> onChanged;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(valueText, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Semantics(
            label: semanticLabel,
            value: valueText,
            child: Slider(value: value.clamp(min, max), min: min, max: max, divisions: divisions, onChanged: onChanged),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(minLabel, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                Text(maxLabel, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      );
}

/// Live result of the debounced eligibility check under the amount slider.
class _EligibilityHint extends StatelessWidget {
  const _EligibilityHint({required this.preview, required this.checking});

  final LoanAssessment? preview;
  final bool checking;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color, String text) = switch (preview) {
      _ when checking => (Icons.hourglass_top_rounded, AppColors.textSecondary, 'Checking your eligibility...'),
      null => (Icons.info_outline_rounded, AppColors.textSecondary, 'Eligibility is confirmed when you apply.'),
      LoanAssessment(eligible: false, :final reasons) =>
        (Icons.error_outline_rounded, AppColors.error, reasons.isEmpty ? 'Not eligible right now.' : reasons.first),
      LoanAssessment(amountAdjusted: true, :final maxEligibleAmount) =>
        (Icons.info_outline_rounded, AppColors.warning, 'Your current limit is ${Fmt.inr(maxEligibleAmount)}.'),
      LoanAssessment(:final maxEligibleAmount) =>
        (Icons.check_circle_rounded, AppColors.success, 'Pre-approved · limit ${Fmt.inr(maxEligibleAmount)}'),
    };
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500))),
      ],
    );
  }
}
