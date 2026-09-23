import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/cubit/item_state.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../core/utils/extensions.dart';
import '../../../../../core/widgets/error/empty_state.dart';
import '../../../../../core/widgets/layout/page_scaffold.dart';
import '../../../../../core/widgets/loading/app_loader.dart';
import '../../../../../core/widgets/media/cached_image.dart';
import '../../../../../core/widgets/status/status_chip.dart';
import '../../../../../injection_container.dart';
import '../../../../shared/data/models/claim_model.dart';
import '../../../../shared/file_viewer/presentation/pages/file_viewer_page.dart';
import '../../data/repositories/claim_repository.dart';
import '../cubit/claim_list_cubit.dart';

/// Screen 16. Claim details, evidence viewer and decision outcome.
class ClaimDetailPage extends StatelessWidget {
  const ClaimDetailPage({super.key, required this.claimId});

  final int claimId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ClaimDetailCubit(sl<ClaimRepository>())..load(claimId),
      child: _ClaimDetailView(claimId: claimId),
    );
  }
}

class _ClaimDetailView extends StatelessWidget {
  const _ClaimDetailView({required this.claimId});

  final int claimId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClaimDetailCubit, ItemState<ClaimModel>>(
      builder: (context, state) {
        final claim = state.item;

        if (claim == null) {
          return PageScaffold(
            title: 'Claim',
            body: state.isFailure
                ? EmptyState.error(
                    title: 'Could not load this claim',
                    message: state.message,
                    onAction: () => context.read<ClaimDetailCubit>().load(claimId),
                  )
                : const AppLoader(),
          );
        }

        return PageScaffold(
          title: claim.claimNumber,
          onRefresh: () => context.read<ClaimDetailCubit>().load(claimId),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      claim.incidentType.label,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  StatusChip(status: claim.status.value),
                ],
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Incident',
                icon: Icons.report_problem_outlined,
                children: [
                  DetailRow(
                    label: 'Incident date',
                    value: DateFormatter.displayRaw(claim.incidentDate),
                    icon: Icons.event_outlined,
                  ),
                  DetailRow(
                    label: 'Claimed',
                    value: DateFormatter.currency(claim.claimedAmount),
                    icon: Icons.payments_outlined,
                  ),
                  if (claim.approvedAmount != null)
                    DetailRow(
                      label: 'Approved',
                      value: DateFormatter.currency(claim.approvedAmount),
                      icon: Icons.verified_outlined,
                    ),
                  DetailRow(
                    label: 'Submitted',
                    value: DateFormatter.displayWithTime(claim.createdAt),
                    icon: Icons.upload_file_outlined,
                  ),
                  const SizedBox(height: 8),
                  Text(claim.description, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'Policy',
                icon: Icons.policy_outlined,
                children: [
                  DetailRow(label: 'Application', value: claim.applicationNumber, icon: Icons.description_outlined),
                  DetailRow(label: 'Policy number', value: claim.policyNumber.orDash(), icon: Icons.verified_outlined),
                  DetailRow(
                    label: 'Sum insured',
                    value: DateFormatter.currency(claim.coverageAmount),
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                  DetailRow(
                    label: 'Animal',
                    value: '${claim.animalEarTag} · ${claim.animalType.label}',
                    icon: Icons.pets_outlined,
                  ),
                  DetailRow(label: 'Scheme', value: claim.schemeName, icon: Icons.policy_outlined),
                ],
              ),
              if (claim.hasEvidence) ...[
                const SizedBox(height: 12),
                SectionCard(
                  title: 'Evidence',
                  icon: Icons.attach_file_outlined,
                  children: [
                    _EvidencePreview(claim: claim),
                  ],
                ),
              ],
              if (claim.isRejected) ...[
                const SizedBox(height: 12),
                SectionCard(
                  title: 'Rejection',
                  icon: Icons.cancel_outlined,
                  children: [
                    Text(claim.rejectionReason.orDash(), style: Theme.of(context).textTheme.bodyMedium),
                    if (claim.decidedByName != null)
                      DetailRow(
                        label: 'Decided by',
                        value: '${claim.decidedByName} · ${DateFormatter.displayWithTime(claim.decidedAt)}',
                        icon: Icons.person_outline,
                      ),
                  ],
                ),
              ],
              if (claim.isApproved && claim.decidedByName != null) ...[
                const SizedBox(height: 12),
                SectionCard(
                  title: 'Decision',
                  icon: Icons.gavel_outlined,
                  children: [
                    DetailRow(
                      label: 'Decided by',
                      value: '${claim.decidedByName} · ${DateFormatter.displayWithTime(claim.decidedAt)}',
                      icon: Icons.person_outline,
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _EvidencePreview extends StatelessWidget {
  const _EvidencePreview({required this.claim});

  final ClaimModel claim;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(
        Routes.fileViewer,
        extra: FileViewerArgs(
          url: claim.evidenceUrl!,
          title: 'Claim evidence',
          isPdf: claim.evidenceIsPdf,
        ),
      ),
      child: claim.evidenceIsPdf
          ? ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Open PDF evidence'),
              trailing: const Icon(Icons.chevron_right),
            )
          : CachedImage(
              url: claim.evidenceUrl,
              width: double.infinity,
              height: 200,
              fallbackIcon: Icons.attach_file_outlined,
            ),
    );
  }
}
