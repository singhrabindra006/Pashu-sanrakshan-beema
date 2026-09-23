import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/cubit/paginated_list_cubit.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/dialogs/confirm_dialog.dart';
import '../../../../../core/widgets/error/error_snackbar.dart';
import '../../../../../injection_container.dart';
import '../../../../shared/data/models/scheme_model.dart';
import '../../../../shared/presentation/widgets/entity_cards.dart';
import '../../../../shared/presentation/widgets/paginated_list_view.dart';
import '../../data/repositories/admin_scheme_repository.dart';
import '../cubit/admin_scheme_list_cubit.dart';

/// Screen 19. Active / Inactive scheme catalogue with add, edit and toggle.
class AdminSchemeListPage extends StatelessWidget {
  const AdminSchemeListPage({super.key});

  static const List<(String, bool)> _tabs = [
    ('Active', true),
    ('Inactive', false),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Schemes'),
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Inactive'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push(Routes.adminSchemeForm),
          icon: const Icon(Icons.add),
          label: const Text('Add scheme'),
        ),
        body: TabBarView(
          children: [for (final tab in _tabs) _SchemeTab(isActive: tab.$2)],
        ),
      ),
    );
  }
}

class _SchemeTab extends StatelessWidget {
  const _SchemeTab({required this.isActive});

  final bool isActive;

  Future<void> _openForm(BuildContext context, {SchemeModel? scheme}) async {
    final changed = await context.push<bool>(Routes.adminSchemeForm, extra: scheme);
    if (changed == true && context.mounted) await context.read<AdminSchemeListCubit>().load();
  }

  Future<void> _toggle(BuildContext context, SchemeModel scheme) async {
    final activating = !scheme.isActive;
    final confirmed = await ConfirmDialog.show(
      context,
      title: activating ? 'Activate ${scheme.name}?' : 'Deactivate ${scheme.name}?',
      message: activating
          ? 'Farmers will be able to apply while the scheme is inside its validity dates.'
          : 'Farmers will no longer see this scheme in the catalogue.',
      confirmLabel: activating ? 'Activate' : 'Deactivate',
      isDestructive: !activating,
      icon: activating ? Icons.toggle_on_outlined : Icons.toggle_off_outlined,
    );
    if (!confirmed || !context.mounted) return;

    final error = await context.read<AdminSchemeListCubit>().toggle(scheme.id);
    if (!context.mounted) return;
    if (error == null) {
      AppSnackBar.success(context, activating ? 'Scheme activated' : 'Scheme deactivated');
    } else {
      AppSnackBar.error(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminSchemeListCubit(sl<AdminSchemeRepository>(), isActive: isActive)..load(),
      child: Builder(
        builder: (context) {
          final cubit = context.read<AdminSchemeListCubit>();
          return BlocBuilder<AdminSchemeListCubit, ListState<SchemeModel>>(
            builder: (context, state) => PaginatedListView<SchemeModel>(
              state: state,
              onRefresh: () => cubit.load(refresh: true),
              onLoadMore: cubit.loadMore,
              emptyTitle: isActive ? 'No active schemes' : 'No inactive schemes',
              emptyMessage: isActive
                  ? 'Create a scheme so farmers can apply for cover.'
                  : 'Deactivated schemes appear here and can be turned back on.',
              emptyIcon: Icons.policy_outlined,
              itemBuilder: (context, scheme) => SchemeCard(
                scheme: scheme,
                showStatus: true,
                onTap: () => _openForm(context, scheme: scheme),
                onEdit: () => _openForm(context, scheme: scheme),
                onToggle: () => _toggle(context, scheme),
              ),
            ),
          );
        },
      ),
    );
  }
}
