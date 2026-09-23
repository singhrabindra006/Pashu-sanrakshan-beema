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
import '../../../../../core/widgets/dialogs/confirm_dialog.dart';
import '../../../../../core/widgets/dialogs/input_dialog.dart';
import '../../../../../core/widgets/error/empty_state.dart';
import '../../../../../core/widgets/error/error_snackbar.dart';
import '../../../../../core/widgets/layout/page_scaffold.dart';
import '../../../../../core/widgets/loading/app_loader.dart';
import '../../../../../core/widgets/media/cached_image.dart';
import '../../../../../core/widgets/status/status_chip.dart';
import '../../../../../injection_container.dart';
import '../../../../shared/data/models/application_model.dart';
import '../../../../shared/file_viewer/presentation/pages/file_viewer_page.dart';
import '../../data/repositories/admin_application_repository.dart';
import '../cubit/admin_application_decision_cubit.dart';

/// Screen 22. Full application audit view with a sticky Approve / Reject bar.
class AdminApplicationDetailPage extends StatelessWidget {
  const AdminApplicationDetailPage({super.key, required this.applicationId});

  final int applicationId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminApplicationDecisionCubit(sl<AdminApplicationRepository>())..load(applicationId),
      child: _AdminApplicationDetailView(applicationId: applicationId),
    );
  }
}

class _AdminApplicationDetailView extends StatelessWidget {
  const _AdminApplicationDetailView({required this.applicationId});

  final int applicationId;

  Future<void> _approve(BuildContext context, ApplicationModel application) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Approve ${application.applicationNumber}?',
      message: 'A policy number and a 12-month term will be generated automatically '
          'unless you override them later. Sum insured: ${DateFormatter.currency(application.coverageAmount)}.',
      confirmLabel: 'Approve',
      icon: Icons.verified_outlined,
    );
    if (!confirmed || !context.mounted) return;
    await context.read<AdminApplicationDecisionCubit>().approve();
  }

  Future<void> _reject(BuildContext context) async {
    final reason = await InputDialog.show(
      context,
      title: 'Reject application',
      label: 'Reason',
      confirmLabel: 'Reject',
      isDestructive: true,
      maxLines: 4,
      helper: 'Shown to the farmer on their application',
      validator: Validators.rejectionReason,
    );
    if (reason == null || !context.mounted) return;
    await context.read<AdminApplicationDecisionCubit>().reject(reason);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminApplicationDecisionCubit, ItemState<ApplicationModel>>(
      listenWhen: (previous, current) => current.isSubmitted || (current.isFailure && current.message != null),
      listener: (context, state) {
        if (state.isSubmitted && state.message != null) {
          AppSnackBar.success(context, state.message!);
        } else if (state.isFailure && state.message != null) {
          AppSnackBar.error(context, state.message!);
        }
      },
      builder: (context, state) {
        final application = state.item;

        if (application == null) {
          return PageScaffold(
            title: 'Application',
            body: state.isFailure
                ? EmptyState.error(
                    title: 'Could not load this application',
                    message: state.message,
                    onAction: () => context.read<AdminApplicationDecisionCubit>().load(applicationId),
                  )
                : const AppLoader(),
          );
        }

        return PageScaffold(
          title: application.applicationNumber,
          onRefresh: () => context.read<AdminApplicationDecisionCubit>().load(applicationId),
          bottomBar: application.isPending
              ? BlockingProgressOverlay(
                  isVisible: state.isSubmitting,
                  child: Row(
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
                          onPressed: state.isSubmitting ? null : () => _approve(context, application),
                        ),
                      ),
                    ],
                  ),
                )
              : null,
          body: BlockingProgressOverlay(
            isVisible: state.isSubmitting,
            message: 'Recording decision...',
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Align(alignment: Alignment.centerLeft, child: StatusChip(status: application.status.value)),
                const SizedBox(height: 12),
                ExpansionTile(
                  initiallyExpanded: true,
                  leading: const Icon(Icons.person_outline),
                  title: Text(application.farmerName, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(application.farmerEmail.orDash()),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  children: [
                    DetailRow(label: 'Phone', value: application.farmerPhone.orDash(), icon: Icons.phone_outlined),
                    DetailRow(label: 'Email', value: application.farmerEmail.orDash(), icon: Icons.mail_outline),
                  ],
                ),
                const SizedBox(height: 8),
                SectionCard(
                  title: 'Animal',
                  icon: Icons.pets_outlined,
                  children: [
                    if (application.animalPhotoUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () => context.push(
                            Routes.fileViewer,
                            extra: FileViewerArgs(url: application.animalPhotoUrl!, title: application.animalEarTag),
                          ),
                          child: CachedImage(
                            url: application.animalPhotoUrl,
                            width: double.infinity,
                            height: 180,
                            fallbackIcon: Icons.pets_outlined,
                          ),
                        ),
                      ),
                    DetailRow(label: 'Ear tag', value: application.animalEarTag, icon: Icons.confirmation_number_outlined),
                    DetailRow(label: 'Type', value: application.animalType.label, icon: Icons.pets_outlined),
                    DetailRow(label: 'Breed', value: application.animalBreed.orDash(), icon: Icons.category_outlined),
                    DetailRow(
                      label: 'Age',
                      value: DateFormatter.monthsToAge(application.animalAgeMonths),
                      icon: Icons.cake_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SectionCard(
                  title: 'Scheme & cover',
                  icon: Icons.policy_outlined,
                  children: [
                    DetailRow(label: 'Scheme', value: application.schemeName, icon: Icons.policy_outlined),
                    DetailRow(
                      label: 'Requested',
                      value: DateFormatter.currency(application.coverageAmount),
                      icon: Icons.payments_outlined,
                    ),
                    DetailRow(
                      label: 'Scheme limit',
                      value: DateFormatter.currency(application.schemeMaxCoverage),
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                    DetailRow(
                      label: 'Submitted',
                      value: DateFormatter.displayWithTime(application.createdAt),
                      icon: Icons.event_outlined,
                    ),
                  ],
                ),
                if (application.isApproved) ...[
                  const SizedBox(height: 12),
                  SectionCard(
                    title: 'Policy',
                    icon: Icons.verified_outlined,
                    children: [
                      DetailRow(label: 'Policy number', value: application.policyNumber.orDash(), icon: Icons.tag_outlined),
                      DetailRow(
                        label: 'Valid from',
                        value: DateFormatter.displayRaw(application.policyStartDate),
                        icon: Icons.event_available_outlined,
                      ),
                      DetailRow(
                        label: 'Valid until',
                        value: DateFormatter.displayRaw(application.policyEndDate),
                        icon: Icons.event_busy_outlined,
                      ),
                      DetailRow(
                        label: 'Decided by',
                        value: '${application.decidedByName.orDash()} · ${DateFormatter.displayWithTime(application.decidedAt)}',
                        icon: Icons.gavel_outlined,
                      ),
                    ],
                  ),
                ],
                if (application.isRejected) ...[
                  const SizedBox(height: 12),
                  SectionCard(
                    title: 'Rejection',
                    icon: Icons.cancel_outlined,
                    children: [
                      Text(application.rejectionReason.orDash()),
                      DetailRow(
                        label: 'Decided by',
                        value: '${application.decidedByName.orDash()} · ${DateFormatter.displayWithTime(application.decidedAt)}',
                        icon: Icons.gavel_outlined,
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
