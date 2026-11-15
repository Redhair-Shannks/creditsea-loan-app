import '../../../core/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/form_fields.dart';

/// "Mobile Number" field with the +91 country box from the design.
class PhoneField extends StatelessWidget {
  const PhoneField({super.key, required this.controller, this.onSubmitted, this.textInputAction});

  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FieldLabel('Mobile Number'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    _IndiaFlag(),
                    SizedBox(width: 8),
                    Text('+91', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  textInputAction: textInputAction ?? TextInputAction.done,
                  onFieldSubmitted: onSubmitted,
                  autofillHints: const [AutofillHints.telephoneNumberNational],
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: Validators.phone,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.5),
                  decoration: const InputDecoration(hintText: 'Please enter your mobile no.'),
                ),
              ),
            ],
          ),
        ],
      );
}

/// Tiny tricolour drawn with containers (emoji flags don't render on every platform).
class _IndiaFlag extends StatelessWidget {
  const _IndiaFlag();

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: SizedBox(
          width: 22,
          height: 15,
          child: Column(
            children: [
              Expanded(child: Container(color: const Color(0xFFFF9933))),
              Expanded(
                child: Container(
                  color: Colors.white,
                  alignment: Alignment.center,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF000080)),
                  ),
                ),
              ),
              Expanded(child: Container(color: const Color(0xFF138808))),
            ],
          ),
        ),
      );
}
