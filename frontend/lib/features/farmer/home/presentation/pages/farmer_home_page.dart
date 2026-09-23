import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/cubit/item_state.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/theme/cubit/theme_cubit.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../core/widgets/error/empty_state.dart';
import '../../../../../core/widgets/layout/responsive_layout.dart';
import '../../../../../core/widgets/loading/shimmer_loader.dart';
import '../../../../../core/widgets/media/cached_image.dart';
import '../../../../../injection_container.dart';
import '../../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../../shared/data/models/profile_model.dart';
import '../../../../shared/presentation/widgets/stat_card.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';

/// Screen 5. Stat cards plus quick actions.
class FarmerHomePage extends StatelessWidget {
  const FarmerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FarmerDashboardCubit(sl<ProfileRepository>())..load(),
      child: const _FarmerHomeView(),
    );
  }
}

class _FarmerHomeView extends StatelessWidget {
  const _FarmerHomeView();

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthCubit cubit) => cubit.state.user);
    final name = user?.fullName ?? 'Farmer';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Switch theme',
            icon: const Icon(Icons.brightness_6_outlined),
            onPressed: () => context.read<ThemeCubit>().toggle(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 4),
            child: GestureDetector(
              onTap: () => context.go(Routes.farmerProfile),
              child: UserAvatar(imageUrl: user?.avatarUrl, name: name, radius: 18),
            ),
          ),
        ],
      ),
      body: BlocBuilder<FarmerDashboardCubit, ItemState<FarmerDashboardModel>>(
        builder: (context, state) {
          if (state.isLoading && !state.hasItem) return const ShimmerGridLoader(itemCount: 6);
          if (state.isFailure && !state.hasItem) {
            return EmptyState.error(
              title: 'Could not load your dashboard',
              message: state.message,
              onAction: () => context.read<FarmerDashboardCubit>().load(),
            );
          }

          final stats = state.item;
          return RefreshIndicator(
            onRefresh: () => context.read<FarmerDashboardCubit>().load(),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    'Overview',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                ResponsiveGrid(
                  children: [
                    StatCard(
                      label: 'My animals',
                      value: '${stats?.activeAnimals ?? 0}',
                      caption: 'of ${stats?.totalAnimals ?? 0} registered',
                      icon: Icons.pets_rounded,
                      color: AppColors.info,
                      onTap: () => context.go(Routes.farmerAnimals),
                    ),
                    StatCard(
                      label: 'Active policies',
                      value: '${stats?.activePolicies ?? 0}',
                      caption: DateFormatter.currencyCompact(stats?.totalSumInsured ?? 0),
                      icon: Icons.verified_user_rounded,
                      color: AppColors.approved,
                      onTap: () => context.go(Routes.farmerApplications),
                    ),
                    StatCard(
                      label: 'Pending applications',
                      value: '${stats?.pendingApplications ?? 0}',
                      icon: Icons.hourglass_top_rounded,
                      color: AppColors.pending,
                      onTap: () => context.go(Routes.farmerApplications),
                    ),
                    StatCard(
                      label: 'Open claims',
                      value: '${stats?.submittedClaims ?? 0}',
                      caption: 'Paid ${DateFormatter.currencyCompact(stats?.totalPayout ?? 0)}',
                      icon: Icons.medical_services_rounded,
                      color: AppColors.accent,
                      onTap: () => context.go(Routes.farmerClaims),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Text(
                    'Quick actions',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 10.0;
                    const padding = 16.0;
                    final tileWidth = (constraints.maxWidth - padding * 2 - spacing * 2) / 3;
                    final aspect = tileWidth / 104;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: padding),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        childAspectRatio: aspect,
                        children: [
                          QuickActionTile(
                            label: 'Add animal',
                            icon: Icons.add_circle_outline,
                            onTap: () => context.push(Routes.animalForm),
                          ),
                          QuickActionTile(
                            label: 'Apply for cover',
                            icon: Icons.post_add_outlined,
                            onTap: () => context.push(Routes.applicationSubmit),
                          ),
                          QuickActionTile(
                            label: 'File a claim',
                            icon: Icons.assignment_late_outlined,
                            onTap: () => context.push(Routes.claimSubmit),
                          ),
                          QuickActionTile(
                            label: 'Browse schemes',
                            icon: Icons.policy_outlined,
                            onTap: () => context.go(Routes.farmerSchemes),
                          ),
                          QuickActionTile(
                            label: 'My applications',
                            icon: Icons.description_outlined,
                            onTap: () => context.go(Routes.farmerApplications),
                          ),
                          QuickActionTile(
                            label: 'My profile',
                            icon: Icons.person_outline,
                            onTap: () => context.go(Routes.farmerProfile),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                if (stats != null) ...[
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your cover at a glance',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const Divider(height: 20),
                            _SummaryRow(
                              icon: Icons.savings_outlined,
                              label: 'Total sum insured',
                              value: DateFormatter.currency(stats.totalSumInsured),
                            ),
                            _SummaryRow(
                              icon: Icons.verified_outlined,
                              label: 'Claims approved',
                              value: '${stats.approvedClaims}',
                            ),
                            _SummaryRow(
                              icon: Icons.payments_outlined,
                              label: 'Amount received',
                              value: DateFormatter.currency(stats.totalPayout),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
