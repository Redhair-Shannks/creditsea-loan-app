import '../../../core/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/flow_scaffold.dart';
import '../../../core/widgets/form_fields.dart';
import '../../../core/widgets/illustrations.dart';
import '../../../data/models/user.dart';
import 'employment_details_controller.dart';

/// Employment & income (same visual language as the Figma Details screens).
class EmploymentDetailsView extends GetView<EmploymentDetailsController> {
  const EmploymentDetailsView({super.key});

  @override
  Widget build(BuildContext context) => FlowScaffold(
        stage: FlowStage.register,
        title: 'Employment Details',
        body: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: IconIllustration(icon: Icons.work_outline_rounded, accent: Icons.currency_rupee_rounded)),
              const SizedBox(height: 24),
              AppDropdownField<EmploymentType>(
                label: 'Employment Type',
                required: true,
                hint: 'Select your employment type',
                items: EmploymentType.values,
                itemLabel: (e) => e.label,
                value: controller.employmentType.value,
                onChanged: (e) => controller.employmentType.value = e,
                validator: (e) => e == null ? 'Select your employment type' : null,
              ),
              const SizedBox(height: 18),
              AppTextField(
                label: 'Monthly Income',
                required: true,
                hint: 'e.g. 45000',
                controller: controller.incomeController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
                validator: controller.validateIncome,
                prefix: const RupeePrefix(),
                onSubmitted: (_) => controller.submit(),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your income and credit score decide your loan limit. Salaried and self-employed '
                'applicants earning ₹15,000+ a month are eligible.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
        bottom: Obx(
          () => AppButton(
            label: controller.primaryActionLabel,
            loading: controller.busy.value,
            onPressed: controller.submit,
          ),
        ),
      );
}
