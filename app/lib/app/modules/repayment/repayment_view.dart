import '../../core/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/flow_scaffold.dart';
import '../../core/widgets/form_fields.dart';
import '../../core/widgets/skeleton.dart';
import '../../data/models/loan.dart';
import 'repayment_controller.dart';

/// Repay with UPI (sandbox).
class RepaymentView extends GetView<RepaymentController> {
  const RepaymentView({super.key});

  @override
  Widget build(BuildContext context) => FlowScaffold(
        title: 'Repay loan',
        body: Obx(() {
          final loan = controller.loan.value;
          if (loan == null) {
            final error = controller.loadError.value;
            return error == null
                ? const FormSkeleton(rows: 2)
                : MessageState(icon: Icons.cloud_off_rounded, title: 'Could not load the loan', message: error);
          }
          return _RepaymentForm(controller: controller, loan: loan);
        }),
        bottom: Obx(
          () => AppButton(
            label: controller.amount > 0 ? 'Pay ${Fmt.inr(controller.amount)} via UPI' : 'Pay via UPI',
            icon: Icons.lock_outline_rounded,
            loading: controller.busy.value,
            onPressed: controller.loan.value?.status == LoanStatus.disbursed ? controller.pay : null,
          ),
        ),
      );
}

class _RepaymentForm extends StatelessWidget {
  const _RepaymentForm({required this.controller, required this.loan});

  final RepaymentController controller;
  final Loan loan;

  @override
  Widget build(BuildContext context) => Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionCard(
              title: 'Amount due',
              trailing: Text('#${loan.applicationNo}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              child: Column(
                children: [
                  InfoRow('Outstanding', Fmt.inr(loan.outstanding), valueColor: AppColors.textPrimary, bold: true),
                  if (loan.amountPaid > 0) InfoRow('Already paid', Fmt.inr(loan.amountPaid), valueColor: AppColors.success),
                  if (loan.dueDate != null)
                    InfoRow(
                      'Due date',
                      Fmt.date(loan.dueDate!),
                      valueColor: loan.isOverdue ? AppColors.error : AppColors.textPrimary,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('How much would you like to pay?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Obx(
              () => Column(
                children: [
                  _AmountOption(
                    selected: controller.payFull.value,
                    title: 'Full amount',
                    subtitle: '${Fmt.inr(loan.outstanding)} · closes the loan',
                    onTap: () => controller.payFull.value = true,
                  ),
                  const SizedBox(height: 8),
                  _AmountOption(
                    selected: !controller.payFull.value,
                    title: 'Part payment',
                    subtitle: 'Pay what you can today',
                    onTap: () => controller.payFull.value = false,
                  ),
                  if (!controller.payFull.value) ...[
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Amount',
                      required: true,
                      hint: 'Enter amount',
                      controller: controller.amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(7)],
                      validator: controller.validateAmount,
                      prefix: const RupeePrefix(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'UPI ID',
              required: true,
              hint: 'yourname@okaxis',
              controller: controller.upiController,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.upi,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final handle in RepaymentController.upiHandles)
                  ActionChip(
                    label: Text(handle, style: const TextStyle(fontSize: 12)),
                    onPressed: () => controller.useHandle(handle),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(8)),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.science_outlined, size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sandbox payment: no real money moves. Any valid UPI ID succeeds; '
                      'use fail@upi to see a declined payment.',
                      style: TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _AmountOption extends StatelessWidget {
  const _AmountOption({required this.selected, required this.title, required this.subtitle, required this.onTap});

  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySoft : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.4 : 1),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                color: selected ? AppColors.primary : AppColors.textHint,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
