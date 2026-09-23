import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/cubit/paginated_list_cubit.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/dialogs/confirm_dialog.dart';
import '../../../../../core/widgets/error/error_snackbar.dart';
import '../../../../../injection_container.dart';
import '../../../../shared/data/models/farmer_model.dart';
import '../../../../shared/presentation/widgets/entity_cards.dart';
import '../../../../shared/presentation/widgets/paginated_list_view.dart';
import '../../data/repositories/admin_farmer_repository.dart';
import '../cubit/admin_farmer_list_cubit.dart';

/// Screen 25. Searchable farmer directory with active/inactive toggle.
class AdminFarmerListPage extends StatelessWidget {
  const AdminFarmerListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminFarmerListCubit(sl<AdminFarmerRepository>())..load(),
      child: const _AdminFarmerListView(),
    );
  }
}

class _AdminFarmerListView extends StatelessWidget {
  const _AdminFarmerListView();

  Future<void> _toggle(BuildContext context, FarmerModel farmer) async {
    final activating = !farmer.isActive;
    final confirmed = await ConfirmDialog.show(
      context,
      title: activating ? 'Activate ${farmer.fullName}?' : 'Deactivate ${farmer.fullName}?',
      message: activating
          ? 'The farmer will be able to sign in and use the app again.'
          : 'The farmer will be blocked from signing in. Existing data is kept.',
      confirmLabel: activating ? 'Activate' : 'Deactivate',
      isDestructive: !activating,
      icon: activating ? Icons.toggle_on_outlined : Icons.block_outlined,
    );
    if (!confirmed || !context.mounted) return;

    final error = await context.read<AdminFarmerListCubit>().toggleActive(farmer.userId);
    if (!context.mounted) return;
    if (error == null) {
      AppSnackBar.success(context, activating ? 'Farmer activated' : 'Farmer deactivated');
    } else {
      AppSnackBar.error(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AdminFarmerListCubit>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmers'),
        automaticallyImplyLeading: false,
      ),
      body: BlocBuilder<AdminFarmerListCubit, ListState<FarmerModel>>(
        builder: (context, state) => PaginatedListView<FarmerModel>(
          state: state,
          onRefresh: () => cubit.load(refresh: true),
          onLoadMore: cubit.loadMore,
          emptyTitle: 'No farmers found',
          emptyMessage: 'Farmers appear here after they register and sync their account.',
          emptyIcon: Icons.groups_outlined,
          header: Column(
            children: [
              SearchHeader(
                hint: 'Search name, phone or email',
                onChanged: (value) => cubit.search(value),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: cubit.activeFilter == null,
                      onSelected: (_) => cubit.setActiveFilter(null),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Active'),
                      selected: cubit.activeFilter == true,
                      onSelected: (_) => cubit.setActiveFilter(true),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Inactive'),
                      selected: cubit.activeFilter == false,
                      onSelected: (_) => cubit.setActiveFilter(false),
                    ),
                    const Spacer(),
                    Text('${state.total} total', style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
            ],
          ),
          itemBuilder: (context, farmer) => FarmerCard(
            farmer: farmer,
            onTap: () => context.push(Routes.adminFarmerDetail(farmer.userId)),
            onToggle: () => _toggle(context, farmer),
          ),
        ),
      ),
    );
  }
}
