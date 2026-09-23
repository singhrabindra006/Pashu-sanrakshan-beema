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
import '../../data/repositories/claim_repository.dart';
import '../cubit/claim_list_cubit.dart';

/// Screen 14. All / Submitted / Approved / Rejected tabs over my claims.
class ClaimListPage extends StatelessWidget {
  const ClaimListPage({super.key});

  static const List<ClaimStatus?> _tabs = [
    null,
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
          title: const Text('My claims'),
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Submitted'),
              Tab(text: 'Approved'),
              Tab(text: 'Rejected'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push(Routes.claimSubmit),
          icon: const Icon(Icons.assignment_late_outlined),
          label: const Text('New claim'),
        ),
        body: TabBarView(
          children: [for (final status in _tabs) _ClaimTab(status: status)],
        ),
      ),
    );
  }
}

class _ClaimTab extends StatelessWidget {
  const _ClaimTab({this.status});

  final ClaimStatus? status;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ClaimListCubit(sl<ClaimRepository>(), status: status)..load(),
      child: Builder(
        builder: (context) {
          final cubit = context.read<ClaimListCubit>();
          return BlocBuilder<ClaimListCubit, ListState<ClaimModel>>(
            builder: (context, state) => PaginatedListView<ClaimModel>(
              state: state,
              onRefresh: () => cubit.load(refresh: true),
              onLoadMore: cubit.loadMore,
              emptyTitle: status == null ? 'No claims yet' : 'No ${status!.label.toLowerCase()} claims',
              emptyMessage: status == null
                  ? 'File a claim against an approved policy if an insured animal is affected.'
                  : 'Claims move here once their status changes.',
              emptyIcon: Icons.medical_services_outlined,
              itemBuilder: (context, claim) => ClaimCard(
                claim: claim,
                onTap: () => context.push(Routes.claimDetail(claim.id)),
              ),
            ),
          );
        },
      ),
    );
  }
}
