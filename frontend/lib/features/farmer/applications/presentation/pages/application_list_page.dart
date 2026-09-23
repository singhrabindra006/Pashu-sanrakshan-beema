import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/cubit/paginated_list_cubit.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../injection_container.dart';
import '../../../../shared/data/models/application_model.dart';
import '../../../../shared/presentation/widgets/entity_cards.dart';
import '../../../../shared/presentation/widgets/paginated_list_view.dart';
import '../../data/repositories/application_repository.dart';
import '../cubit/application_list_cubit.dart';

/// Screen 11. All / Pending / Approved / Rejected tabs over my applications.
class ApplicationListPage extends StatelessWidget {
  const ApplicationListPage({super.key});

  static const List<ApplicationStatus?> _tabs = [
    null,
    ApplicationStatus.pending,
    ApplicationStatus.approved,
    ApplicationStatus.rejected,
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My applications'),
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Pending'),
              Tab(text: 'Approved'),
              Tab(text: 'Rejected'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push(Routes.applicationSubmit),
          icon: const Icon(Icons.post_add_outlined),
          label: const Text('New application'),
        ),
        body: TabBarView(
          children: [for (final status in _tabs) _ApplicationTab(status: status)],
        ),
      ),
    );
  }
}

class _ApplicationTab extends StatelessWidget {
  const _ApplicationTab({this.status});

  final ApplicationStatus? status;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ApplicationListCubit(sl<ApplicationRepository>(), status: status)..load(),
      child: Builder(
        builder: (context) {
          final cubit = context.read<ApplicationListCubit>();
          return BlocBuilder<ApplicationListCubit, ListState<ApplicationModel>>(
            builder: (context, state) => PaginatedListView<ApplicationModel>(
              state: state,
              onRefresh: () => cubit.load(refresh: true),
              onLoadMore: cubit.loadMore,
              emptyTitle: status == null ? 'No applications yet' : 'No ${status!.label.toLowerCase()} applications',
              emptyMessage: status == null
                  ? 'Apply for a scheme to insure one of your animals.'
                  : 'Applications move here once their status changes.',
              emptyIcon: Icons.description_outlined,
              itemBuilder: (context, application) => ApplicationCard(
                application: application,
                onTap: () => context.push(Routes.applicationDetail(application.id)),
              ),
            ),
          );
        },
      ),
    );
  }
}
