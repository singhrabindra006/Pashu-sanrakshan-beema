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
import '../../data/repositories/admin_application_repository.dart';
import '../cubit/admin_application_list_cubit.dart';

/// Screen 21. Pending / Approved / Rejected applications with search.
class AdminApplicationListPage extends StatefulWidget {
  const AdminApplicationListPage({super.key});

  @override
  State<AdminApplicationListPage> createState() => _AdminApplicationListPageState();
}

class _AdminApplicationListPageState extends State<AdminApplicationListPage> {
  String _query = '';

  static const List<ApplicationStatus> _tabs = [
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
          title: const Text('Applications'),
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Approved'),
              Tab(text: 'Rejected'),
            ],
          ),
        ),
        body: Column(
          children: [
            SearchHeader(
              hint: 'Search by application no. or farmer',
              onChanged: (value) => setState(() => _query = value),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  for (final status in _tabs) _ApplicationTab(status: status, search: _query),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicationTab extends StatefulWidget {
  const _ApplicationTab({required this.status, required this.search});

  final ApplicationStatus status;
  final String search;

  @override
  State<_ApplicationTab> createState() => _ApplicationTabState();
}

class _ApplicationTabState extends State<_ApplicationTab> with AutomaticKeepAliveClientMixin {
  late final AdminApplicationListCubit _cubit = AdminApplicationListCubit(
    sl<AdminApplicationRepository>(),
    status: widget.status,
  );

  @override
  void initState() {
    super.initState();
    _cubit.search(widget.search);
  }

  @override
  void didUpdateWidget(covariant _ApplicationTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.search != widget.search) _cubit.search(widget.search);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<AdminApplicationListCubit, ListState<ApplicationModel>>(
        builder: (context, state) => PaginatedListView<ApplicationModel>(
          state: state,
          onRefresh: () => _cubit.load(refresh: true),
          onLoadMore: _cubit.loadMore,
          emptyTitle: 'No ${widget.status.label.toLowerCase()} applications',
          emptyMessage: widget.status == ApplicationStatus.pending
              ? 'New farmer applications land here for a decision.'
              : 'Nothing in this status right now.',
          emptyIcon: Icons.description_outlined,
          itemBuilder: (context, application) => ApplicationCard(
            application: application,
            showFarmer: true,
            onTap: () => context.push(Routes.adminApplicationDetail(application.id)),
          ),
        ),
      ),
    );
  }
}
