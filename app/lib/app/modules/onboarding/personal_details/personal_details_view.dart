import '../../../core/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/flow_scaffold.dart';
import '../../../core/widgets/form_fields.dart';
import '../../../data/models/user.dart';
import 'personal_details_controller.dart';

/// Figma "Details" -> "Personal Details".
class PersonalDetailsView extends GetView<PersonalDetailsController> {
  const PersonalDetailsView({super.key});

  @override
  Widget build(BuildContext context) => FlowScaffold(
        stage: FlowStage.register,
        title: 'Personal Details',
        body: Form(
          key: controller.formKey,
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'First Name',
                      required: true,
                      hint: 'Your first name',
                      controller: controller.firstNameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.givenName],
                      validator: (v) => Validators.name(v, 'First name'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppTextField(
                      label: 'Last Name',
                      required: true,
                      hint: 'Your last name',
                      controller: controller.lastNameController,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.familyName],
                      validator: (v) => Validators.name(v, 'Last name'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              AppDropdownField<Gender>(
                label: 'Gender',
                required: true,
                hint: 'Select your gender',
                items: Gender.values,
                itemLabel: (g) => g.label,
                value: controller.gender.value,
                onChanged: (g) => controller.gender.value = g,
                validator: (g) => g == null ? 'Select your gender' : null,
              ),
              const SizedBox(height: 18),
              DateField(
                label: 'Date of Birth',
                required: true,
                value: controller.dob.value,
                firstDate: controller.earliestDob,
                lastDate: controller.latestDob,
                initialPickerDate: DateTime(1995),
                onChanged: (d) => controller.dob.value = d,
                validator: (d) => d == null ? 'Select your date of birth' : null,
              ),
              const SizedBox(height: 18),
              AppDropdownField<MaritalStatus>(
                label: 'Your Marital Status',
                required: true,
                hint: 'Select',
                items: MaritalStatus.values,
                itemLabel: (m) => m.label,
                value: controller.maritalStatus.value,
                onChanged: (m) => controller.maritalStatus.value = m,
                validator: (m) => m == null ? 'Select your marital status' : null,
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
