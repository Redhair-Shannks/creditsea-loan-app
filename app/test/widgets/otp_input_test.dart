import 'package:creditsea_loan_app/app/core/widgets/otp_input.dart';
import 'package:creditsea_loan_app/app/core/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('OtpInput shows one box per digit and reports the full code', (tester) async {
    final controller = TextEditingController();
    String? completed;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: OtpInput(length: 4, controller: controller, onCompleted: (code) => completed = code),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '12ab34'); // non-digits are filtered out
    await tester.pump();

    expect(controller.text, '1234');
    expect(completed, '1234');
    for (final digit in ['1', '2', '3', '4']) {
      expect(find.text(digit), findsOneWidget);
    }

    controller.dispose();
  });
}
