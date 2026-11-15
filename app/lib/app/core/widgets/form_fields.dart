import '../material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../utils/formatters.dart';

/// "First Name*" style label above a field.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.required = false});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          required ? '$text*' : text,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        ),
      );
}

/// Labelled text field used across the forms.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.hint,
    this.controller,
    this.required = false,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.obscureText = false,
    this.suffix,
    this.prefix,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.autofillHints,
    this.enabled = true,
    this.autofocus = false,
  });

  final String label;
  final String hint;
  final TextEditingController? controller;
  final bool required;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final bool obscureText;
  final Widget? suffix;
  final Widget? prefix;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final bool enabled;
  final bool autofocus;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FieldLabel(label, required: required),
          TextFormField(
            controller: controller,
            enabled: enabled,
            autofocus: autofocus,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: validator,
            obscureText: obscureText,
            textCapitalization: textCapitalization,
            textInputAction: textInputAction,
            onChanged: onChanged,
            onFieldSubmitted: onSubmitted,
            autofillHints: autofillHints,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(hintText: hint, suffixIcon: suffix, prefixIcon: prefix),
          ),
        ],
      );
}

/// Labelled dropdown ("Select your gender").
class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.label,
    required this.hint,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.value,
    this.required = false,
    this.validator,
  });

  final String label;
  final String hint;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;
  final T? value;
  final bool required;
  final FormFieldValidator<T>? validator;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FieldLabel(label, required: required),
          DropdownButtonFormField<T>(
            initialValue: value,
            isExpanded: true, // menu matches the field's width
            items: [for (final item in items) DropdownMenuItem<T>(value: item, child: Text(itemLabel(item)))],
            onChanged: onChanged,
            validator: validator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            hint: Text(hint, style: const TextStyle(color: AppColors.textHint, fontSize: 14, fontWeight: FontWeight.w400)),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textPrimary),
            borderRadius: BorderRadius.circular(8),
            dropdownColor: Colors.white,
            // The dropdown does not merge `style` with the theme, so derive it from the theme
            // (otherwise items fall back to the platform font instead of Montserrat).
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
          ),
        ],
      );
}

/// "₹" prefix for amount fields, vertically centred inside the input.
class RupeePrefix extends StatelessWidget {
  const RupeePrefix({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 44,
        child: Center(child: Text('₹', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
      );
}

/// Read-only date field that opens the Material date picker (Figma: "DD - MM - YYYY").
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    this.value,
    this.initialPickerDate,
    this.required = false,
    this.validator,
  });

  final String label;
  final ValueChanged<DateTime> onChanged;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? value;
  final DateTime? initialPickerDate;
  final bool required;
  final FormFieldValidator<DateTime>? validator;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FieldLabel(label, required: required),
          FormField<DateTime>(
            initialValue: value,
            validator: validator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            builder: (state) => InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: state.value ?? initialPickerDate ?? lastDate,
                  firstDate: firstDate,
                  lastDate: lastDate,
                  helpText: label.toUpperCase(),
                );
                if (picked != null) {
                  state.didChange(picked);
                  onChanged(picked);
                }
              },
              child: InputDecorator(
                isEmpty: state.value == null,
                decoration: InputDecoration(
                  hintText: 'DD - MM - YYYY',
                  errorText: state.errorText,
                  suffixIcon: const Icon(Icons.calendar_month_outlined, color: AppColors.textPrimary, size: 20),
                ),
                child: state.value == null
                    ? null
                    : Text(Fmt.dob(state.value!), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ),
            ),
          ),
        ],
      );
}
