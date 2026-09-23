import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/cubit/item_state.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../core/utils/extensions.dart';
import '../../../../../core/widgets/buttons/primary_button.dart';
import '../../../../../core/widgets/error/empty_state.dart';
import '../../../../../core/widgets/layout/page_scaffold.dart';
import '../../../../../core/widgets/loading/app_loader.dart';
import '../../../../../core/widgets/status/status_chip.dart';
import '../../../../../injection_container.dart';
import '../../../../shared/data/models/scheme_model.dart';
import '../../data/repositories/scheme_repository.dart';
import '../cubit/scheme_list_cubit.dart';

/// Screen 10. Full scheme description with the "apply" entry point.
class SchemeDetailPage extends StatelessWidget {
  const SchemeDetailPage({super.key, required this.schemeId, this.scheme});

  final int schemeId;

  /// Passed from the list so the page renders instantly while refreshing.
  final SchemeModel? scheme;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SchemeDetailCubit(sl<SchemeRepository>())..load(schemeId),
      child: _SchemeDetailView(schemeId: schemeId, fallback: scheme),
    );
  }
}

class _SchemeDetailView extends StatelessWidget {
  const _SchemeDetailView({required this.schemeId, this.fallback});

  final int schemeId;
  final SchemeModel? fallback;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SchemeDetailCubit, ItemState<SchemeModel>>(
      builder: (context, state) {
        final scheme = state.item ?? fallback;

        if (scheme == null) {
          return PageScaffold(
            title: 'Scheme',
            body: state.isFailure
                ? EmptyState.error(
                    title: 'Could not load this scheme',
                    message: state.message,
                    onAction: () => context.read<SchemeDetailCubit>().load(schemeId),
                  )
                : const AppLoader(),
          );
        }

        return PageScaffold(
          title: 'Scheme details',
          bottomBar: PrimaryButton(
            label: scheme.isAvailable ? 'Apply for this scheme' : 'Not open for applications',
            icon: scheme.isAvailable ? Icons.post_add_outlined : Icons.block_outlined,
            onPressed: scheme.isAvailable
                ? () => context.push(Routes.applicationSubmit, extra: scheme.id)
                : null,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      scheme.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  StatusChip(status: scheme.statusLabel),
                ],
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Cover',
                icon: Icons.account_balance_wallet_outlined,
                children: [
                  DetailRow(
                    label: 'Maximum cover',
                    value: DateFormatter.currency(scheme.maxCoverage),
                    icon: Icons.payments_outlined,
                  ),
                  DetailRow(
                    label: 'Valid from',
                    value: DateFormatter.displayRaw(scheme.startDate),
                    icon: Icons.event_available_outlined,
                  ),
                  DetailRow(
                    label: 'Valid until',
                    value: DateFormatter.displayRaw(scheme.endDate),
                    icon: Icons.event_busy_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'About this scheme',
                icon: Icons.info_outline,
                children: [
                  Text(
                    scheme.description.isNullOrBlank
                        ? 'No additional description was provided for this scheme.'
                        : scheme.description!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.tips_and_updates_outlined, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your requested cover cannot exceed the maximum above. '
                          'Each animal can hold only one active policy at a time.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
