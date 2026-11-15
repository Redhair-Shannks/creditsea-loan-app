import '../material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Row of OTP boxes (4 for phone, 6 for email in the design).
///
/// A single invisible TextField handles the keyboard, paste and SMS autofill,
/// and the boxes just draw its current value.
class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    required this.length,
    required this.controller,
    this.onCompleted,
    this.enabled = true,
    this.hasError = false,
    this.autofocus = true,
    this.spacing = 12,
    this.maxBoxSize = 52,
  });

  final int length;
  final TextEditingController controller;
  final ValueChanged<String>? onCompleted;
  final bool enabled;
  final bool hasError;
  final bool autofocus;
  final double spacing;
  final double maxBoxSize;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focus.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(OtpInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focus.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  void _onTextChanged() {
    _rebuild();
    if (widget.controller.text.length == widget.length) widget.onCompleted?.call(widget.controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth - widget.spacing * (widget.length - 1);
        final box = (available / widget.length).clamp(36.0, widget.maxBoxSize);
        return SizedBox(
          height: box,
          child: Stack(
            children: [
              Row(
                children: [
                  for (var i = 0; i < widget.length; i++) ...[
                    if (i > 0) SizedBox(width: widget.spacing),
                    _OtpBox(
                      size: box,
                      digit: i < text.length ? text[i] : '',
                      active: widget.enabled && _focus.hasFocus && i == text.length.clamp(0, widget.length - 1),
                      hasError: widget.hasError,
                      enabled: widget.enabled,
                    ),
                  ],
                ],
              ),
              Positioned.fill(
                child: Opacity(
                  opacity: 0,
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focus,
                    enabled: widget.enabled,
                    autofocus: widget.autofocus && widget.enabled,
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(widget.length),
                    ],
                    showCursor: false,
                    enableInteractiveSelection: false,
                    decoration: const InputDecoration(counterText: '', isCollapsed: true),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.size,
    required this.digit,
    required this.active,
    required this.hasError,
    required this.enabled,
  });

  final double size;
  final String digit;
  final bool active;
  final bool hasError;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? AppColors.error
        : active
            ? AppColors.primary
            : digit.isNotEmpty
                ? AppColors.textHint
                : AppColors.border;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: enabled ? Colors.white : AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: active ? 1.6 : 1),
      ),
      child: Text(digit, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
    );
  }
}
