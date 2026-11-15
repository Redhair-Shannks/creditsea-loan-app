import '../../core/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/responsive.dart';
import '../../core/widgets/skeleton.dart';
import 'home_controller.dart';
import 'widgets/credit_score_card.dart';
import 'widgets/loan_cards.dart';

/// Dashboard (not in the Figma file; built in the same visual language).
/// Phones: one column. Tablets: loan actions on the left, history on the right.
class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: RefreshIndicator(
            onRefresh: controller.load,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _Header(controller: controller)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  sliver: SliverToBoxAdapter(
                    child: ResponsiveCenter(maxWidth: 1000, child: Obx(() => _content(context))),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _content(BuildContext context) {
    if (controller.loading.value) return const _HomeSkeleton();
    final error = controller.loadError.value;
    if (error != null && controller.loans.isEmpty) {
      return MessageState(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load your loans',
        message: error,
        action: SizedBox(width: 160, child: AppButton(label: 'Retry', onPressed: controller.load)),
      );
    }

    final active = controller.activeLoan;
    final primary = active != null
        ? ActiveLoanCard(
            loan: active,
            onTrack: () => controller.openLoan(active),
            onRepay: () => controller.repay(active),
          )
        : ApplyLoanCard(
            limit: controller.limit.value,
            config: controller.config.value,
            onApply: controller.applyForLoan,
          );

    final history = SectionCard(
      title: 'My loans',
      child: controller.loans.isEmpty
          ? const MessageState(
              icon: Icons.receipt_long_outlined,
              title: 'No applications yet',
              message: 'Your loan applications will appear here.',
            )
          : Column(
              children: [
                for (final loan in controller.loans) LoanTile(loan: loan, onTap: () => controller.openLoan(loan)),
              ],
            ),
    );

    if (Breakpoints.isWide(context)) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: primary),
          const SizedBox(width: 20),
          Expanded(child: history),
        ],
      );
    }
    return Column(children: [primary, const SizedBox(height: 16), history]);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.brandBlue,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: ResponsiveCenter(
              maxWidth: 1000,
              child: Obx(() {
                final user = controller.user.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const AppLogo(size: 26),
                        const Spacer(),
                        Tooltip(
                          message: 'Profile',
                          child: InkWell(
                            onTap: controller.openProfile,
                            customBorder: const CircleBorder(),
                            child: CircleAvatar(
                              radius: 19,
                              backgroundColor: Colors.white.withValues(alpha: 0.18),
                              child: Text(
                                Fmt.initials(user?.fullName),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Hi, ${user?.greetingName ?? 'there'}',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Welcome back to CreditSea',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13),
                    ),
                    if (user != null) ...[const SizedBox(height: 16), CreditScoreCard(user: user)],
                  ],
                );
              }),
            ),
          ),
        ),
      );
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton(height: 180, radius: 14),
          SizedBox(height: 16),
          Skeleton(width: 120, height: 18),
          SizedBox(height: 12),
          Skeleton(height: 56),
          SizedBox(height: 10),
          Skeleton(height: 56),
        ],
      );
}
