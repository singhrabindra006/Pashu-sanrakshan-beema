import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/cubit/item_state.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../core/utils/extensions.dart';
import '../../../../../core/widgets/buttons/primary_button.dart';
import '../../../../../core/widgets/error/empty_state.dart';
import '../../../../../core/widgets/layout/page_scaffold.dart';
import '../../../../../core/widgets/loading/app_loader.dart';
import '../../../../../core/widgets/media/cached_image.dart';
import '../../../../../core/widgets/status/status_chip.dart';
import '../../../../../injection_container.dart';
import '../../../../shared/data/models/application_model.dart';
import '../../../../shared/file_viewer/presentation/pages/file_viewer_page.dart';
import '../../data/repositories/application_repository.dart';
import '../cubit/application_list_cubit.dart';

/// Screen 13. Read-only application with status timeline and policy details.
class ApplicationDetailPage extends StatelessWidget {
  const ApplicationDetailPage({super.key, required this.applicationId});

  final int applicationId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ApplicationDetailCubit(sl<ApplicationRepository>())..load(applicationId),
      child: _ApplicationDetailView(applicationId: applicationId),
    );
  }
}

class _ApplicationDetailView extends StatelessWidget {
  const _ApplicationDetailView({required this.applicationId});

  final int applicationId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ApplicationDetailCubit, ItemState<ApplicationModel>>(
      builder: (context, state) {
        final application = state.item;

        if (application == null) {
          return PageScaffold(
            title: 'Application',
            body: state.isFailure
                ? EmptyState.error(
                    title: 'Could not load this application',
                    message: state.message,
                    onAction: () => context.read<ApplicationDetailCubit>().load(applicationId),
                  )
                : const AppLoader(),
          );
        }

        return PageScaffold(
          title: application.applicationNumber,
          onRefresh: () => context.read<ApplicationDetailCubit>().load(applicationId),
          bottomBar: application.isApproved
              ? PrimaryButton(
                  label: 'File a claim',
                  icon: Icons.assignment_late_outlined,
                  onPressed: () => context.push(Routes.claimSubmit, extra: application.id),
                )
              : null,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      application.schemeName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  StatusChip(status: application.status.value),
                ],
              ),
              const SizedBox(height: 16),
              _Timeline(application: application),
              const SizedBox(height: 12),
              SectionCard(
                title: 'Cover',
                icon: Icons.account_balance_wallet_outlined,
                children: [
                  DetailRow(
                    label: 'Sum insured',
                    value: DateFormatter.currency(application.coverageAmount),
                    icon: Icons.payments_outlined,
                  ),
                  DetailRow(
                    label: 'Scheme limit',
                    value: DateFormatter.currency(application.schemeMaxCoverage),
                    icon: Icons.policy_outlined,
                  ),
                  DetailRow(
                    label: 'Submitted',
                    value: DateFormatter.displayWithTime(application.createdAt),
                    icon: Icons.event_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
                          height: 160,
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
              if (application.isApproved) ...[
                const SizedBox(height: 12),
                SectionCard(
                  title: 'Policy',
                  icon: Icons.verified_outlined,
                  children: [
                    DetailRow(
                      label: 'Policy number',
                      value: application.policyNumber.orDash(),
                      icon: Icons.tag_outlined,
                    ),
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
                  ],
                ),
              ],
              if (application.isRejected) ...[
                const SizedBox(height: 12),
                SectionCard(
                  title: 'Rejection',
                  icon: Icons.cancel_outlined,
                  children: [
                    Text(
                      application.rejectionReason.orDash(),
                      style: Theme.of(context).textTheme.bodyMedium,
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

class _Timeline extends StatelessWidget {
  const _Timeline({required this.application});

  final ApplicationModel application;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Status timeline',
      icon: Icons.timeline_outlined,
      children: [
        _Step(
          title: 'Submitted',
          subtitle: DateFormatter.displayWithTime(application.createdAt),
          done: true,
          color: AppColors.info,
        ),
        _Step(
          title: application.isRejected
              ? 'Rejected'
              : application.isApproved
                  ? 'Approved'
                  : 'Awaiting decision',
          subtitle: application.decidedAt == null
              ? 'The insurer has not decided yet'
              : '${application.decidedByName.orDash()} · ${DateFormatter.displayWithTime(application.decidedAt)}',
          done: !application.isPending,
          color: application.isRejected
              ? AppColors.rejected
              : application.isApproved
                  ? AppColors.approved
                  : AppColors.pending,
          isLast: true,
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.title,
    required this.subtitle,
    required this.done,
    required this.color,
    this.isLast = false,
  });

  final String title;
  final String subtitle;
  final bool done;
  final Color color;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, color: color, size: 20),
            if (!isLast)
              Container(
                width: 2,
                height: 28,
                margin: const EdgeInsets.symmetric(vertical: 2),
                color: color.withValues(alpha: 0.35),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
