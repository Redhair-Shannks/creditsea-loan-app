import '../material.dart';

import '../theme/app_colors.dart';
import 'responsive.dart';

/// The three stages shown at the top of the Details / Offer / Status screens.
enum FlowStage { register, offer, approval }

/// Scaffold for the white "sheet" screens in the design: optional stage indicator,
/// a back arrow + title, scrollable content and a pinned bottom action.
class FlowScaffold extends StatelessWidget {
  const FlowScaffold({
    super.key,
    required this.title,
    required this.body,
    this.stage,
    this.subtitle,
    this.header,
    this.bottom,
    this.showBack = true,
    this.onBack,
    this.onRefresh,
  });

  final String title;
  final Widget body;
  final FlowStage? stage;
  final Widget? subtitle;

  /// Shown above the sheet instead of the stage indicator (e.g. the logo).
  final Widget? header;
  final Widget? bottom;
  final bool showBack;
  final VoidCallback? onBack;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final canPop = showBack && (onBack != null || Navigator.of(context).canPop());

    Widget content = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: ResponsiveCenter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (canPop) ...[
                  InkResponse(
                    onTap: onBack ?? () => Navigator.of(context).maybePop(),
                    radius: 22,
                    child: const Icon(Icons.arrow_back, size: 22, semanticLabel: 'Back'),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            if (subtitle != null) ...[const SizedBox(height: 6), subtitle!],
            const SizedBox(height: 20),
            body,
          ],
        ),
      ),
    );
    if (onRefresh != null) content = RefreshIndicator(onRefresh: onRefresh!, child: content);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            if (header != null)
              Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 16), child: header!)
            else if (stage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                child: ResponsiveCenter(child: StageIndicator(current: stage!)),
              ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(color: Color(0x12000000), blurRadius: 14, offset: Offset(0, -2))],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: content,
                ),
              ),
            ),
            if (bottom != null)
              ColoredBox(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: ResponsiveCenter(child: bottom!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// "① Register  ② Offer  ③ Approval"
class StageIndicator extends StatelessWidget {
  const StageIndicator({super.key, required this.current});

  final FlowStage current;

  static const _labels = {FlowStage.register: 'Register', FlowStage.offer: 'Offer', FlowStage.approval: 'Approval'};

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Step ${current.index + 1} of 3: ${_labels[current]}',
        excludeSemantics: true,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [for (final stage in FlowStage.values) _StageItem(stage: stage, current: current, label: _labels[stage]!)],
        ),
      );
}

class _StageItem extends StatelessWidget {
  const _StageItem({required this.stage, required this.current, required this.label});

  final FlowStage stage;
  final FlowStage current;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isCurrent = stage == current;
    final isDone = stage.index < current.index;
    final color = isCurrent ? AppColors.primary : (isDone ? AppColors.success : AppColors.textSecondary);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCurrent ? AppColors.primary : (isDone ? AppColors.success : AppColors.divider),
          ),
          child: isDone
              ? const Icon(Icons.check, size: 13, color: Colors.white)
              : Text(
                  '${stage.index + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isCurrent ? Colors.white : AppColors.textSecondary,
                  ),
                ),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
      ],
    );
  }
}
