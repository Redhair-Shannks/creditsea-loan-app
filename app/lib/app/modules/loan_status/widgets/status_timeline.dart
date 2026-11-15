import '../../../core/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/loan.dart';

/// Vertical list of bordered steps joined by connectors (Figma "Application Status").
class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.steps});

  final List<TimelineStep> steps;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (final (index, step) in steps.indexed) ...[
            if (index > 0) _Connector(active: step.state == TrackerState.done || step.state == TrackerState.current),
            _StepBox(step: step),
          ],
        ],
      );
}

class _Connector extends StatelessWidget {
  const _Connector({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) => Container(
        width: 1.5,
        height: 12,
        color: active ? AppColors.success.withValues(alpha: 0.6) : AppColors.border,
      );
}

class _StepBox extends StatelessWidget {
  const _StepBox({required this.step});

  final TimelineStep step;

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData icon) = switch (step.state) {
      TrackerState.done => (AppColors.success, Icons.task_alt_rounded),
      TrackerState.current => (AppColors.primary, Icons.pending_actions_rounded),
      TrackerState.pending => (AppColors.textSecondary, Icons.assignment_outlined),
      TrackerState.failed => (AppColors.error, Icons.cancel_outlined),
    };
    final emphasised = step.state != TrackerState.pending;
    return Semantics(
      label: '${step.title}: ${step.state.name}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: step.state == TrackerState.failed ? AppColors.errorSoft : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: emphasised ? color : AppColors.border, width: emphasised ? 1.4 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            Expanded(
              child: Column(
                children: [
                  Text(
                    step.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: emphasised ? color : AppColors.textSecondary),
                  ),
                  if (step.at != null && step.state != TrackerState.pending)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(Fmt.dateTime(step.at!), style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 20), // balances the icon so the title stays centred
          ],
        ),
      ),
    );
  }
}
