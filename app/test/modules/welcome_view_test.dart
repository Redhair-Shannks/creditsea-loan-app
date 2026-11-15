import 'package:creditsea_loan_app/app/core/theme/app_theme.dart';
import 'package:creditsea_loan_app/app/core/widgets/app_button.dart';
import 'package:creditsea_loan_app/app/data/repositories/auth_repository.dart';
import 'package:creditsea_loan_app/app/modules/auth/welcome/welcome_controller.dart';
import 'package:creditsea_loan_app/app/modules/auth/welcome/welcome_view.dart';
import 'package:creditsea_loan_app/app/core/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../fakes.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put<AuthRepository>(FakeAuthRepository());
    Get.lazyPut(() => WelcomeController(Get.find()));
  });

  tearDown(Get.reset);

  ElevatedButton requestOtpButton(WidgetTester tester) => tester.widget<ElevatedButton>(
        find.descendant(of: find.byType(AppButton), matching: find.byType(ElevatedButton)),
      );

  testWidgets('"Request OTP" enables only with a valid number and consent', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532); // phone-sized
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(GetMaterialApp(theme: AppTheme.light, home: const WelcomeView()));
    await tester.pump();

    expect(find.text('Welcome to Credit Sea!'), findsOneWidget);
    expect(requestOtpButton(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextFormField), '9876543210');
    await tester.pump();
    expect(requestOtpButton(tester).onPressed, isNull, reason: 'consent not given yet');

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(requestOtpButton(tester).onPressed, isNotNull);
  });
}
