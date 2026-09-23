import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/cubit/paginated_list_cubit.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../injection_container.dart';
import '../../../../shared/data/models/scheme_model.dart';
import '../../../../shared/presentation/widgets/entity_cards.dart';
import '../../../../shared/presentation/widgets/paginated_list_view.dart';
import '../../data/repositories/scheme_repository.dart';
import '../cubit/scheme_list_cubit.dart';

/// Screen 9. Schemes a farmer can apply for right now.
class SchemeListPage extends StatelessWidget {
  const SchemeListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SchemeListCubit(sl<SchemeRepository>())..load(),
      child: const _SchemeListView(),
    );
  }
}

class _SchemeListView extends StatelessWidget {
  const _SchemeListView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SchemeListCubit>();

    return Scaffold(
      appBar: AppBar(title: const Text('Insurance schemes'), automaticallyImplyLeading: false),
      body: BlocBuilder<SchemeListCubit, ListState<SchemeModel>>(
        builder: (context, state) => PaginatedListView<SchemeModel>(
          state: state,
          onRefresh: () => cubit.load(refresh: true),
          onLoadMore: cubit.loadMore,
          emptyTitle: 'No schemes are open right now',
          emptyMessage: 'New schemes appear here as soon as the insurer publishes them.',
          emptyIcon: Icons.policy_outlined,
          itemBuilder: (context, scheme) => SchemeCard(
            scheme: scheme,
            onTap: () => context.push(Routes.schemeDetail(scheme.id), extra: scheme),
          ),
        ),
      ),
    );
  }
}
