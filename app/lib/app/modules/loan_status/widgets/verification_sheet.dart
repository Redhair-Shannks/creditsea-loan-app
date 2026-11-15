import '../../../core/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/form_fields.dart';
import '../../../data/models/loan.dart';
import '../loan_status_controller.dart';

/// Bottom sheet for one post-approval step: E-KYC, E-NACH or E-Sign (sandbox versions).
class VerificationSheet extends StatefulWidget {
  const VerificationSheet({super.key, required this.step, required this.loan, required this.controller});

  final VerificationStep step;
  final Loan loan;
  final LoanStatusController controller;

  @override
  State<VerificationSheet> createState() => _VerificationSheetState();
}

class _VerificationSheetState extends State<VerificationSheet> {
  final _form = GlobalKey<FormState>();
  final _aadhaar = TextEditingController();
  final _account = TextEditingController();
  final _ifsc = TextEditingController();
  bool _accepted = false;
  bool _showAcceptError = false;

  @override
  void dispose() {
    _aadhaar.dispose();
    _account.dispose();
    _ifsc.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formOk = _form.currentState?.validate() ?? false;
    final needsAcceptance = widget.step != VerificationStep.enach;
    if (needsAcceptance && !_accepted) setState(() => _showAcceptError = true);
    if (!formOk || (needsAcceptance && !_accepted)) return;

    final c = widget.controller;
    final ok = switch (widget.step) {
      VerificationStep.ekyc => await c.submitEkyc(_aadhaar.text),
      VerificationStep.enach => await c.submitEnach(_account.text.trim(), _ifsc.text.trim().toUpperCase()),
      VerificationStep.esign => await c.submitEsign(),
    };
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.step.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(widget.step.description, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 18),
                  ..._fields(),
                  const SizedBox(height: 20),
                  Obx(
                    () => AppButton(
                      label: switch (widget.step) {
                        VerificationStep.ekyc => 'Verify Aadhaar',
                        VerificationStep.enach => 'Register mandate',
                        VerificationStep.esign => 'Sign agreement',
                      },
                      loading: widget.controller.busy.value,
                      onPressed: _submit,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  List<Widget> _fields() => switch (widget.step) {
        VerificationStep.ekyc => [
            AppTextField(
              label: 'Aadhaar Number',
              required: true,
              hint: '12-digit Aadhaar number',
              controller: _aadhaar,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(12)],
              validator: Validators.aadhaar,
            ),
            const SizedBox(height: 12),
            _Acceptance(
              value: _accepted,
              showError: _showAcceptError,
              text: 'I consent to CreditSea verifying my Aadhaar for KYC. Sandbox: nothing is sent to UIDAI '
                  'and only the last 4 digits are stored.',
              onChanged: (v) => setState(() {
                _accepted = v;
                _showAcceptError = false;
              }),
            ),
          ],
        VerificationStep.enach => [
            AppTextField(
              label: 'Bank Account Number',
              required: true,
              hint: 'Account number',
              controller: _account,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(18)],
              validator: Validators.bankAccount,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'IFSC',
              required: true,
              hint: 'e.g. HDFC0001234',
              controller: _ifsc,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [UpperCaseTextFormatter(), LengthLimitingTextInputFormatter(11)],
              validator: Validators.ifsc,
            ),
            const SizedBox(height: 12),
            Text(
              '${Fmt.inr(widget.loan.totalPayable)} will be auto-debited from this account '
              '${widget.loan.tenureDays} days after disbursal.',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
          ],
        VerificationStep.esign => [
            SectionCard(
              title: 'Loan agreement summary',
              child: Column(
                children: [
                  InfoRow('Application', '#${widget.loan.applicationNo}', valueColor: AppColors.textPrimary),
                  InfoRow('Loan amount', Fmt.inr(widget.loan.principal)),
                  InfoRow('Interest (${Fmt.percent(widget.loan.interestPerDayPct)}/day)', Fmt.inr(widget.loan.interest)),
                  InfoRow('Processing fee', Fmt.inr(widget.loan.processingFee)),
                  InfoRow('Tenure', '${widget.loan.tenureDays} days', valueColor: AppColors.textPrimary),
                  InfoRow('Total payable', Fmt.inr(widget.loan.totalPayable), bold: true),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Acceptance(
              value: _accepted,
              showError: _showAcceptError,
              text: 'I have read and agree to the loan agreement and Key Fact Statement.',
              onChanged: (v) => setState(() {
                _accepted = v;
                _showAcceptError = false;
              }),
            ),
          ],
      };
}

class _Acceptance extends StatelessWidget {
  const _Acceptance({required this.value, required this.showError, required this.text, required this.onChanged});

  final bool value;
  final bool showError;
  final String text;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox.square(
                dimension: 24,
                child: Checkbox(
                  value: value,
                  isError: showError,
                  onChanged: (v) => onChanged(v ?? false),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(fontSize: 12.5, height: 1.4, color: showError ? AppColors.error : AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      );
}
