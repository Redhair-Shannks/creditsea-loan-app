import '../../core/material.dart';
import 'package:get/get.dart';

import '../../core/widgets/app_button.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/flow_scaffold.dart';
import '../../core/widgets/skeleton.dart';
import 'loan_status_controller.dart';
import 'widgets/status_panel.dart';
import 'widgets/status_timeline.dart';

/// Figma "Application Status".
class LoanStatusView extends GetView<LoanStatusController> {
  const LoanStatusView({super.key});

  @override
  Widget build(BuildContext context) => FlowScaffold(
        stage: FlowStage.approval,
        title: 'Application Status',
        onBack: controller.leave,
        onRefresh: controller.fetch,
        subtitle: Obx(() {
          final loan = controller.loan.value;
          return loan == null
              ? const SizedBox.shrink()
              : Text.rich(
                  TextSpan(
                    text: 'Loan application no. ',
                    children: [TextSpan(text: '#${loan.applicationNo}', style: const TextStyle(fontWeight: FontWeight.w700))],
                  ),
                  style: const TextStyle(fontSize: 13),
                );
        }),
        body: Obx(() {
          final loan = controller.loan.value;
          if (loan == null) {
            final error = controller.loadError.value;
            return error == null
                ? const Column(children: [Skeleton(height: 44), SizedBox(height: 12), Skeleton(height: 44), SizedBox(height: 12), Skeleton(height: 44)])
                : MessageState(
                    icon: Icons.cloud_off_rounded,
                    title: 'Could not load this application',
                    message: error,
                    action: SizedBox(width: 160, child: AppButton(label: 'Retry', onPressed: controller.fetch)),
                  );
          }
          return Column(
            children: [
              StatusTimeline(steps: loan.timeline),
              const SizedBox(height: 28),
              StatusPanel(loan: loan),
            ],
          );
        }),
        bottom: Obx(
          () => AppButton(
            label: controller.actionLabel,
            loading: controller.busy.value,
            onPressed: controller.loan.value == null ? null : controller.onPrimaryAction,
          ),
        ),
      );
}
