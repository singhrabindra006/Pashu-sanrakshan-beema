import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/cubit/paginated_list_cubit.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/dialogs/confirm_dialog.dart';
import '../../../../../core/widgets/error/error_snackbar.dart';
import '../../../../../injection_container.dart';
import '../../../../shared/data/models/animal_model.dart';
import '../../../../shared/file_viewer/presentation/pages/file_viewer_page.dart';
import '../../../../shared/presentation/widgets/entity_cards.dart';
import '../../../../shared/presentation/widgets/paginated_list_view.dart';
import '../../data/repositories/animal_repository.dart';
import '../cubit/animal_list_cubit.dart';

/// Screen 7. My animals, with an Active/Inactive filter and row actions.
class AnimalListPage extends StatelessWidget {
  const AnimalListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AnimalListCubit(sl<AnimalRepository>())..load(),
      child: const _AnimalListView(),
    );
  }
}

class _AnimalListView extends StatelessWidget {
  const _AnimalListView();

  Future<void> _openForm(BuildContext context, {AnimalModel? animal}) async {
    final changed = await context.push<bool>(Routes.animalForm, extra: animal);
    if (changed == true && context.mounted) await context.read<AnimalListCubit>().load();
  }

  Future<void> _deactivate(BuildContext context, AnimalModel animal) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Deactivate ${animal.earTag}?',
      message: 'The animal stays in your history but can no longer be insured. '
          'Use this when an animal is sold or has died.',
      confirmLabel: 'Deactivate',
      isDestructive: true,
      icon: Icons.block_outlined,
    );
    if (!confirmed || !context.mounted) return;

    final error = await context.read<AnimalListCubit>().deactivate(animal.id);
    if (!context.mounted) return;
    if (error == null) {
      AppSnackBar.success(context, '${animal.earTag} deactivated');
    } else {
      AppSnackBar.error(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AnimalListCubit>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My animals'),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Add animal'),
      ),
      body: BlocBuilder<AnimalListCubit, ListState<AnimalModel>>(
        builder: (context, state) => PaginatedListView<AnimalModel>(
          state: state,
          onRefresh: () => cubit.load(refresh: true),
          onLoadMore: cubit.loadMore,
          emptyTitle: 'No animals registered yet',
          emptyMessage: 'Add your cattle, buffalo, goats or sheep to apply for insurance cover.',
          emptyIcon: Icons.pets_outlined,
          header: _FilterChips(
            selected: cubit.activeFilter,
            onChanged: cubit.setActiveFilter,
            total: state.total,
          ),
          itemBuilder: (context, animal) => AnimalCard(
            animal: animal,
            onTap: () => _openForm(context, animal: animal),
            onEdit: () => _openForm(context, animal: animal),
            onDeactivate: animal.isActive ? () => _deactivate(context, animal) : null,
            onPhotoTap: animal.photoUrl == null
                ? null
                : () => context.push(
                      Routes.fileViewer,
                      extra: FileViewerArgs(url: animal.photoUrl!, title: animal.earTag),
                    ),
          ),
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onChanged, required this.total});

  final bool? selected;
  final ValueChanged<bool?> onChanged;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ChoiceChip(label: const Text('All'), selected: selected == null, onSelected: (_) => onChanged(null)),
          ChoiceChip(label: const Text('Active'), selected: selected == true, onSelected: (_) => onChanged(true)),
          ChoiceChip(label: const Text('Inactive'), selected: selected == false, onSelected: (_) => onChanged(false)),
          Text('$total total', style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
