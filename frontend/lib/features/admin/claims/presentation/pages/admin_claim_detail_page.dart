import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/cubit/item_state.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../core/utils/extensions.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../core/widgets/buttons/primary_button.dart';
import '../../../../../core/widgets/buttons/secondary_button.dart';
import '../../../../../core/widgets/dialogs/input_dialog.dart';
import '../../../../../core/widgets/error/empty_state.dart';
import '../../../../../core/widgets/error/error_snackbar.dart';
import '../../../../../core/widgets/layout/page_scaffold.dart';
import '../../../../../core/widgets/loading/app_loader.dart';
import '../../../../../core/widgets/media/cached_image.dart';
import '../../../../../core/widgets/status/status_chip.dart';
import '../../../../../injection_container.dart';
import '../../../../shared/data/models/claim_model.dart';
import '../../../../shared/file_viewer/presentation/pages/file_viewer_page.dart';
import '../../data/repositories/admin_claim_repository.dart';
import '../cubit/admin_claim_decision_cubit.dart';

/// Screen 24. Claim audit view with a sticky Approve / Reject bar.
class AdminClaimDetailPage extends StatelessWidget {
  const AdminClaimDetailPage({super.key, required this.claimId});

  final int claimId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminClaimDecisionCubit(sl<AdminClaimRepository>())..load(claimId),
      child: _AdminClaimDetailView(claimId: claimId),
    );
  }
}

class _AdminClaimDetailView extends StatelessWidget {
  const _AdminClaimDetailView({required this.claimId});

  final int claimId;

  Future<void> _approve(BuildContext context, ClaimModel claim) async {
    final amount = await InputDialog.show(
      context,
      title: 'Approve claim',
      label: 'Approved amount',
      initialValue: claim.claimedAmount.toStringAsFixed(0),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      confirmLabel: 'Approve',
      helper: 'Cannot exceed claimed ${DateFormatter.currency(claim.claimedAmount)}',
      validator: (value) => Validators.amount(value, max: claim.claimedAmount, field: 'Approved amount'),
    );
    if (amount == null || !context.mounted) return;
    await context.read<AdminClaimDecisionCubit>().approve(double.parse(amount.replaceAll(',', '')));
  }

  Future<void> _reject(BuildContext context) async {
    final reason = await InputDialog.show(
      context,
      title: 'Reject claim',
      label: 'Reason',
      confirmLabel: 'Reject',
      isDestructive: true,
      maxLines: 4,
      helper: 'Shown to the farmer on their claim',
      validator: Validators.rejectionReason,
    );
    if (reason == null || !context.mounted) return;
    await context.read<AdminClaimDecisionCubit>().reject(reason);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminClaimDecisionCubit, ItemState<ClaimModel>>(
      listenWhen: (previous, current) => current.isSubmitted || (current.isFailure && current.message != null),
      listener: (context, state) {
        if (state.isSubmitted && state.message != null) {
          AppSnackBar.success(context, state.message!);
        } else if (state.isFailure && state.message != null) {
          AppSnackBar.error(context, state.message!);
        }
      },
      builder: (context, state) {
        final claim = state.item;

        if (claim == null) {
          return PageScaffold(
            title: 'Claim',
            body: state.isFailure
                ? EmptyState.error(
                    title: 'Could not load this claim',
                    message: state.message,
                    onAction: () => context.read<AdminClaimDecisionCubit>().load(claimId),
                  )
                : const AppLoader(),
          );
        }

        return PageScaffold(
          title: claim.claimNumber,
          onRefresh: () => context.read<AdminClaimDecisionCubit>().load(claimId),
          bottomBar: claim.isSubmitted
              ? Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: 'Reject',
                        icon: Icons.close,
                        color: AppColors.rejected,
                        onPressed: state.isSubmitting ? null : () => _reject(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Approve',
                        icon: Icons.check,
                        backgroundColor: AppColors.approved,
                        isLoading: state.isSubmitting,
                        onPressed: state.isSubmitting ? null : () => _approve(context, claim),
                      ),
                    ),
                  ],
                )
              : null,
          body: BlockingProgressOverlay(
            isVisible: state.isSubmitting,
            message: 'Recording decision...',
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Align(alignment: Alignment.centerLeft, child: StatusChip(status: claim.status.value)),
                const SizedBox(height: 12),
                ExpansionTile(
                  initiallyExpanded: true,
                  leading: const Icon(Icons.person_outline),
                  title: Text(claim.farmerName, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(claim.farmerEmail.orDash()),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  children: [
                    DetailRow(label: 'Phone', value: claim.farmerPhone.orDash(), icon: Icons.phone_outlined),
                    DetailRow(label: 'Email', value: claim.farmerEmail.orDash(), icon: Icons.mail_outline),
                  ],
                ),
                const SizedBox(height: 8),
                SectionCard(
                  title: 'Policy',
                  icon: Icons.verified_outlined,
                  children: [
                    DetailRow(label: 'Application', value: claim.applicationNumber, icon: Icons.description_outlined),
                    DetailRow(label: 'Policy number', value: claim.policyNumber.orDash(), icon: Icons.tag_outlined),
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
                const SizedBox(height: 12),
                SectionCard(
                  title: 'Incident',
                  icon: Icons.report_problem_outlined,
                  children: [
                    DetailRow(label: 'Type', value: claim.incidentType.label, icon: Icons.report_problem_outlined),
                    DetailRow(
                      label: 'Date',
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
                    const SizedBox(height: 8),
                    Text(claim.description, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
                if (claim.hasEvidence) ...[
                  const SizedBox(height: 12),
                  SectionCard(
                    title: 'Evidence',
                    icon: Icons.attach_file_outlined,
                    children: [
                      InkWell(
                        onTap: () => context.push(
                          Routes.fileViewer,
                          extra: FileViewerArgs(
                            url: claim.evidenceUrl!,
                            title: 'Claim evidence',
                            isPdf: claim.evidenceIsPdf,
                          ),
                        ),
                        child: claim.evidenceIsPdf
                            ? const ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.picture_as_pdf_outlined),
                                title: Text('Open PDF evidence'),
                                trailing: Icon(Icons.chevron_right),
                              )
                            : CachedImage(
                                url: claim.evidenceUrl,
                                width: double.infinity,
                                height: 220,
                                fallbackIcon: Icons.attach_file_outlined,
                              ),
                      ),
                    ],
                  ),
                ],
                if (!claim.isSubmitted) ...[
                  const SizedBox(height: 12),
                  SectionCard(
                    title: claim.isRejected ? 'Rejection' : 'Decision',
                    icon: claim.isRejected ? Icons.cancel_outlined : Icons.gavel_outlined,
                    children: [
                      if (claim.isRejected) Text(claim.rejectionReason.orDash()),
                      DetailRow(
                        label: 'Decided by',
                        value: '${claim.decidedByName.orDash()} · ${DateFormatter.displayWithTime(claim.decidedAt)}',
                        icon: Icons.person_outline,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
