import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/cubit/item_state.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/theme/cubit/theme_cubit.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../core/widgets/dialogs/confirm_dialog.dart';
import '../../../../../core/widgets/error/empty_state.dart';
import '../../../../../core/widgets/layout/responsive_layout.dart';
import '../../../../../core/widgets/loading/shimmer_loader.dart';
import '../../../../../core/widgets/status/status_chip.dart';
import '../../../../../injection_container.dart';
import '../../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../../shared/data/models/admin_dashboard_model.dart';
import '../../../../shared/presentation/widgets/stat_card.dart';
import '../../data/repositories/admin_dashboard_repository.dart';
import '../cubit/dashboard_cubit.dart';

/// Screen 18. Admin overview: stat cards plus recent activity.
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DashboardCubit(sl<AdminDashboardRepository>())..load(),
      child: const _AdminDashboardView(),
    );
  }
}

class _AdminDashboardView extends StatelessWidget {
  const _AdminDashboardView();

  Future<void> _logout(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Sign out?',
      message: 'You will need your email and password to sign back in.',
      confirmLabel: 'Sign out',
      isDestructive: true,
      icon: Icons.logout_rounded,
    );
    if (!confirmed || !context.mounted) return;
    await context.read<AuthCubit>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        automaticallyImplyLeading: false,
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Switch theme',
            icon: const Icon(Icons.brightness_6_outlined),
            onPressed: () => context.read<ThemeCubit>().toggle(),
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: BlocBuilder<DashboardCubit, ItemState<AdminDashboardModel>>(
        builder: (context, state) {
          if (state.isLoading && !state.hasItem) return const ShimmerGridLoader(itemCount: 8);
          if (state.isFailure && !state.hasItem) {
            return EmptyState.error(
              title: 'Could not load the dashboard',
              message: state.message,
              onAction: () => context.read<DashboardCubit>().load(),
            );
          }

          final data = state.item;
          return RefreshIndicator(
            onRefresh: () => context.read<DashboardCubit>().load(),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                ResponsiveGrid(
                  children: [
                    StatCard(
                      label: 'Farmers',
                      value: '${data?.totalFarmers ?? 0}',
                      caption: '${data?.activeFarmers ?? 0} active',
                      icon: Icons.groups_rounded,
                      color: AppColors.info,
                      onTap: () => context.go(Routes.adminFarmers),
                    ),
                    StatCard(
                      label: 'Animals',
                      value: '${data?.totalAnimals ?? 0}',
                      icon: Icons.pets_rounded,
                      color: AppColors.secondary,
                      onTap: () => context.go(Routes.adminFarmers),
                    ),
                    StatCard(
                      label: 'Pending applications',
                      value: '${data?.pendingApplications ?? 0}',
                      caption: '${data?.approvedApplications ?? 0} approved',
                      icon: Icons.hourglass_top_rounded,
                      color: AppColors.pending,
                      onTap: () => context.go(Routes.adminApplications),
                    ),
                    StatCard(
                      label: 'Open claims',
                      value: '${data?.submittedClaims ?? 0}',
                      caption: 'Paid ${DateFormatter.currencyCompact(data?.totalPayout ?? 0)}',
                      icon: Icons.medical_services_rounded,
                      color: AppColors.accent,
                      onTap: () => context.go(Routes.adminClaims),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                      child: Column(
                        children: [
                          _SummaryRow(label: 'Active schemes', value: '${data?.activeSchemes ?? 0} of ${data?.totalSchemes ?? 0}'),
                          _SummaryRow(label: 'Total sum insured', value: DateFormatter.currency(data?.totalSumInsured)),
                          _SummaryRow(label: 'Claims paid', value: DateFormatter.currency(data?.totalPayout)),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Text(
                    'Recent activity',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (data == null || data.recentActivity.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Text(
                      'New applications and claims will appear here.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  )
                else
                  ...data.recentActivity.map((item) => _ActivityTile(item: item)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.item});

  final ActivityItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: ListTile(
          leading: Icon(item.isApplication ? Icons.description_outlined : Icons.medical_services_outlined),
          title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${item.reference} · ${DateFormatter.relative(item.createdAt)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: StatusChip(status: item.status, compact: true),
          onTap: () => context.push(
            item.isApplication ? Routes.adminApplicationDetail(item.id) : Routes.adminClaimDetail(item.id),
          ),
        ),
      ),
    );
  }
}
