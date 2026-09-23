import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/cubit/paginated_list_cubit.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../injection_container.dart';
import '../../../../shared/data/models/claim_model.dart';
import '../../../../shared/presentation/widgets/entity_cards.dart';
import '../../../../shared/presentation/widgets/paginated_list_view.dart';
import '../../data/repositories/admin_claim_repository.dart';
import '../cubit/admin_claim_list_cubit.dart';

/// Screen 23. Submitted / Approved / Rejected claims with search.
class AdminClaimListPage extends StatefulWidget {
  const AdminClaimListPage({super.key});

  @override
  State<AdminClaimListPage> createState() => _AdminClaimListPageState();
}

class _AdminClaimListPageState extends State<AdminClaimListPage> {
  String _query = '';

  static const List<ClaimStatus> _tabs = [
    ClaimStatus.submitted,
    ClaimStatus.approved,
    ClaimStatus.rejected,
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Claims'),
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Submitted'),
              Tab(text: 'Approved'),
              Tab(text: 'Rejected'),
            ],
          ),
        ),
        body: Column(
          children: [
            SearchHeader(
              hint: 'Search by claim no. or farmer',
              onChanged: (value) => setState(() => _query = value),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  for (final status in _tabs) _ClaimTab(status: status, search: _query),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClaimTab extends StatefulWidget {
  const _ClaimTab({required this.status, required this.search});

  final ClaimStatus status;
  final String search;

  @override
  State<_ClaimTab> createState() => _ClaimTabState();
}

class _ClaimTabState extends State<_ClaimTab> with AutomaticKeepAliveClientMixin {
  late final AdminClaimListCubit _cubit = AdminClaimListCubit(
    sl<AdminClaimRepository>(),
    status: widget.status,
  );

  @override
  void initState() {
    super.initState();
    _cubit.search(widget.search);
  }

  @override
  void didUpdateWidget(covariant _ClaimTab oldWidget) {
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
      child: BlocBuilder<AdminClaimListCubit, ListState<ClaimModel>>(
        builder: (context, state) => PaginatedListView<ClaimModel>(
          state: state,
          onRefresh: () => _cubit.load(refresh: true),
          onLoadMore: _cubit.loadMore,
          emptyTitle: 'No ${widget.status.label.toLowerCase()} claims',
          emptyMessage: widget.status == ClaimStatus.submitted
              ? 'New farmer claims land here for a decision.'
              : 'Nothing in this status right now.',
          emptyIcon: Icons.medical_services_outlined,
          itemBuilder: (context, claim) => ClaimCard(
            claim: claim,
            showFarmer: true,
            onTap: () => context.push(Routes.adminClaimDetail(claim.id)),
          ),
        ),
      ),
    );
  }
}
