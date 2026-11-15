import 'package:creditsea_loan_app/app/modules/loan_calculator/loan_calculator_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../fakes.dart';

void main() {
  late FakeLoanRepository repo;
  late LoanCalculatorController controller;

  setUp(() async {
    Get.testMode = true;
    repo = FakeLoanRepository();
    controller = Get.put(LoanCalculatorController(repo)); // Get.put runs onInit()
    await Future<void>.delayed(Duration.zero); // let the config load
  });

  tearDown(Get.reset);

  test('loads the product config and prices the default selection locally', () {
    expect(controller.config.value, isNotNull);
    expect(controller.principal.value, 30000);
    expect(controller.tenureDays.value, 40);
    expect(controller.pricing.totalPayable, 42000);
    expect(controller.preview.value?.maxEligibleAmount, 32000);
  });

  test('slider values snap to the configured step and stay in range', () {
    controller.onAmountChanged(30499);
    expect(controller.principal.value, 30000);
    controller.onAmountChanged(999999);
    expect(controller.principal.value, 100000);
  });

  test('debounce: one eligibility request after the slider stops moving', () async {
    final before = repo.quoteCalls;
    controller
      ..onAmountChanged(41000)
      ..onAmountChanged(52000)
      ..onAmountChanged(63000);
    expect(repo.quoteCalls, before); // nothing yet while "dragging"

    await Future<void>.delayed(const Duration(milliseconds: 750));
    expect(repo.quoteCalls, before + 1);
    expect(controller.preview.value?.amountAdjusted, isTrue); // 63k is above the 32k limit
  });

  test('apply requires a purpose', () async {
    await controller.apply();
    expect(controller.purposeError.value, 'Select the purpose of the loan');
  });
}
