import '../../core/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/flow_scaffold.dart';
import '../../core/widgets/loan_status_style.dart';
import '../../data/models/user.dart';
import '../../routes/app_routes.dart';
import 'profile_controller.dart';

/// Profile: every detail captured during sign-up, each section editable.
class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) => FlowScaffold(
        title: 'My Profile',
        body: Obx(() {
          final user = controller.user.value;
          if (user == null) return const SizedBox.shrink();
          return Column(
            children: [
              _ProfileHeader(user: user),
              const SizedBox(height: 20),
              SectionCard(
                title: 'Personal details',
                trailing: _EditButton(onTap: () => controller.edit(Routes.personalDetails)),
                child: Column(
                  children: [
                    _Field('Full name', user.fullName),
                    _Field('Date of birth', user.dob == null ? null : Fmt.date(user.dob!)),
                    _Field('Gender', user.gender?.label),
                    _Field('Marital status', user.maritalStatus?.label),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'Contact',
                trailing: _EditButton(onTap: () => controller.edit(Routes.emailVerification)),
                child: Column(
                  children: [
                    _Field('Mobile', Fmt.phone(user.phone), verified: true),
                    _Field('Email ID', user.email, verified: user.emailVerified),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'KYC',
                trailing: _EditButton(onTap: () => controller.edit(Routes.panVerification)),
                child: _Field('PAN', user.panMasked, verified: user.panVerified),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'Employment & income',
                trailing: _EditButton(onTap: () => controller.edit(Routes.employmentDetails)),
                child: Column(
                  children: [
                    _Field('Employment type', user.employmentType?.label),
                    _Field('Monthly income', user.monthlyIncome == null ? null : Fmt.inr(user.monthlyIncome!)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _CreditHistoryCard(user: user),
              const SizedBox(height: 24),
              AppButton(label: 'Log out', outlined: true, icon: Icons.logout_rounded, onPressed: controller.logout),
            ],
          );
        }),
      );
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primarySoft,
            child: Text(
              Fmt.initials(user.fullName),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName ?? 'CreditSea user', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(Fmt.phone(user.phone), style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      );
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.value, {this.verified = false});

  final String label;
  final String? value;
  final bool verified;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(width: 16),
            // The value gets all remaining width (long emails stay readable).
            Expanded(
              child: Text(
                value ?? 'Not added',
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: value == null ? AppColors.textHint : AppColors.textPrimary,
                ),
              ),
            ),
            if (verified && value != null) ...[
              const SizedBox(width: 6),
              const Icon(Icons.verified_rounded, size: 16, color: AppColors.success, semanticLabel: 'Verified'),
            ],
          ],
        ),
      );
}

class _EditButton extends StatelessWidget {
  const _EditButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TextButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.edit_outlined, size: 16),
        label: const Text('Edit'),
        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
      );
}

class _CreditHistoryCard extends StatelessWidget {
  const _CreditHistoryCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) => SectionCard(
        title: 'Credit score',
        trailing: StatusPill(label: '${user.creditScore} · ${user.creditBand}', color: creditScoreColor(user.creditScore)),
        child: user.creditHistory.isEmpty
            ? const Text(
                'Repay loans on time to increase your score. A higher score unlocks a higher loan limit.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
              )
            : Column(
                children: [
                  for (final event in user.creditHistory)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Text(
                            '${event.delta >= 0 ? '+' : ''}${event.delta}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: event.delta >= 0 ? AppColors.success : AppColors.error,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(event.reason, style: const TextStyle(fontSize: 13))),
                          Text(Fmt.date(event.at), style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                ],
              ),
      );
}
