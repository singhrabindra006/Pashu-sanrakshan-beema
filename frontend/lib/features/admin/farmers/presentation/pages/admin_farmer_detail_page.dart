import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/cubit/item_state.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../core/utils/extensions.dart';
import '../../../../../core/widgets/dialogs/confirm_dialog.dart';
import '../../../../../core/widgets/error/empty_state.dart';
import '../../../../../core/widgets/error/error_snackbar.dart';
import '../../../../../core/widgets/layout/page_scaffold.dart';
import '../../../../../core/widgets/loading/app_loader.dart';
import '../../../../../core/widgets/media/cached_image.dart';
import '../../../../../core/widgets/status/status_chip.dart';
import '../../../../../injection_container.dart';
import '../../../../shared/data/models/farmer_model.dart';
import '../../../../shared/file_viewer/presentation/pages/file_viewer_page.dart';
import '../../../../shared/presentation/widgets/entity_cards.dart';
import '../../data/repositories/admin_farmer_repository.dart';
import '../cubit/admin_farmer_list_cubit.dart';

/// Screen 26. Audit view: animals, applications and claims for one farmer.
class AdminFarmerDetailPage extends StatelessWidget {
  const AdminFarmerDetailPage({super.key, required this.userId});

  final int userId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminFarmerDetailCubit(sl<AdminFarmerRepository>())..load(userId),
      child: _AdminFarmerDetailView(userId: userId),
    );
  }
}

class _AdminFarmerDetailView extends StatelessWidget {
  const _AdminFarmerDetailView({required this.userId});

  final int userId;

  Future<void> _toggle(BuildContext context, FarmerModel farmer) async {
    final activating = !farmer.isActive;
    final confirmed = await ConfirmDialog.show(
      context,
      title: activating ? 'Activate ${farmer.fullName}?' : 'Deactivate ${farmer.fullName}?',
      message: activating
          ? 'The farmer will be able to sign in again.'
          : 'The farmer will be blocked from signing in.',
      confirmLabel: activating ? 'Activate' : 'Deactivate',
      isDestructive: !activating,
    );
    if (!confirmed || !context.mounted) return;

    final error = await context.read<AdminFarmerDetailCubit>().toggleActive();
    if (!context.mounted) return;
    if (error != null) {
      AppSnackBar.error(context, error);
    } else {
      AppSnackBar.success(context, activating ? 'Farmer activated' : 'Farmer deactivated');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminFarmerDetailCubit, ItemState<FarmerDetailModel>>(
      builder: (context, state) {
        final detail = state.item;

        if (detail == null) {
          return PageScaffold(
            title: 'Farmer',
            body: state.isFailure
                ? EmptyState.error(
                    title: 'Could not load this farmer',
                    message: state.message,
                    onAction: () => context.read<AdminFarmerDetailCubit>().load(userId),
                  )
                : const AppLoader(),
          );
        }

        final farmer = detail.farmer;

        return DefaultTabController(
          length: 3,
          child: PageScaffold(
            title: farmer.fullName,
            actions: [
              IconButton(
                tooltip: farmer.isActive ? 'Deactivate' : 'Activate',
                icon: Icon(farmer.isActive ? Icons.block_outlined : Icons.check_circle_outline),
                onPressed: () => _toggle(context, farmer),
              ),
            ],
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Animals'),
                Tab(text: 'Applications'),
                Tab(text: 'Claims'),
              ],
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: farmer.imageUrl == null
                            ? null
                            : () => context.push(
                                  Routes.fileViewer,
                                  extra: FileViewerArgs(url: farmer.imageUrl!, title: farmer.fullName),
                                ),
                        child: UserAvatar(imageUrl: farmer.imageUrl, name: farmer.fullName, radius: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(farmer.email, style: Theme.of(context).textTheme.bodyMedium),
                            Text(farmer.phone.orDash(), style: Theme.of(context).textTheme.bodySmall),
                            Text(
                              'Member since ${DateFormatter.display(farmer.createdAt)}',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                      StatusChip(status: farmer.isActive ? 'ACTIVE' : 'INACTIVE'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _Pane(
                        isEmpty: detail.animals.isEmpty,
                        emptyTitle: 'No animals registered',
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: detail.animals.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final animal = detail.animals[index];
                            return AnimalCard(
                              animal: animal,
                              onPhotoTap: animal.photoUrl == null
                                  ? null
                                  : () => context.push(
                                        Routes.fileViewer,
                                        extra: FileViewerArgs(url: animal.photoUrl!, title: animal.earTag),
                                      ),
                            );
                          },
                        ),
                      ),
                      _Pane(
                        isEmpty: detail.applications.isEmpty,
                        emptyTitle: 'No applications',
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: detail.applications.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final application = detail.applications[index];
                            return ApplicationCard(
                              application: application,
                              onTap: () => context.push(Routes.adminApplicationDetail(application.id)),
                            );
                          },
                        ),
                      ),
                      _Pane(
                        isEmpty: detail.claims.isEmpty,
                        emptyTitle: 'No claims',
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: detail.claims.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final claim = detail.claims[index];
                            return ClaimCard(
                              claim: claim,
                              onTap: () => context.push(Routes.adminClaimDetail(claim.id)),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Pane extends StatelessWidget {
  const _Pane({required this.isEmpty, required this.emptyTitle, required this.child});

  final bool isEmpty;
  final String emptyTitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (isEmpty) {
      return EmptyState(title: emptyTitle, icon: Icons.inbox_outlined);
    }
    return child;
  }
}
