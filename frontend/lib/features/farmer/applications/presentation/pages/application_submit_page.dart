import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../core/widgets/buttons/primary_button.dart';
import '../../../../../core/widgets/error/empty_state.dart';
import '../../../../../core/widgets/error/error_snackbar.dart';
import '../../../../../core/widgets/inputs/custom_text_field.dart';
import '../../../../../core/widgets/layout/page_scaffold.dart';
import '../../../../../core/widgets/loading/app_loader.dart';
import '../../../../../injection_container.dart';
import '../../../../shared/data/models/animal_model.dart';
import '../../../../shared/data/models/scheme_model.dart';
import '../../../animals/data/repositories/animal_repository.dart';
import '../../../schemes/data/repositories/scheme_repository.dart';
import '../../data/repositories/application_repository.dart';
import '../cubit/application_submit_cubit.dart';

/// Screen 12. Three-step stepper: animal -> scheme -> coverage amount.
class ApplicationSubmitPage extends StatelessWidget {
  const ApplicationSubmitPage({super.key, this.preselectedSchemeId});

  final int? preselectedSchemeId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ApplicationSubmitCubit(
        applications: sl<ApplicationRepository>(),
        animals: sl<AnimalRepository>(),
        schemes: sl<SchemeRepository>(),
      )..loadOptions(preselectedSchemeId: preselectedSchemeId),
      child: const _ApplicationSubmitView(),
    );
  }
}

class _ApplicationSubmitView extends StatefulWidget {
  const _ApplicationSubmitView();

  @override
  State<_ApplicationSubmitView> createState() => _ApplicationSubmitViewState();
}

class _ApplicationSubmitViewState extends State<_ApplicationSubmitView> {
  final _coverageKey = GlobalKey<FormState>();
  final _coverageController = TextEditingController();
  int _step = 0;

  @override
  void dispose() {
    _coverageController.dispose();
    super.dispose();
  }

  void _next(ApplicationSubmitState state) {
    if (_step == 0 && state.selectedAnimal == null) {
      AppSnackBar.info(context, 'Select the animal you want to insure');
      return;
    }
    if (_step == 1 && state.selectedScheme == null) {
      AppSnackBar.info(context, 'Select a scheme');
      return;
    }
    if (_step == 2) {
      if (_coverageKey.currentState?.validate() != true) return;
      final amount = double.tryParse(_coverageController.text.trim().replaceAll(',', ''));
      context.read<ApplicationSubmitCubit>()
        ..setCoverage(amount)
        ..submit();
      return;
    }
    setState(() => _step += 1);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ApplicationSubmitCubit, ApplicationSubmitState>(
      listener: (context, state) {
        if (state.stage == SubmitStage.submitted && state.created != null) {
          AppSnackBar.success(context, 'Application ${state.created!.applicationNumber} submitted');
          context.pop();
          context.push(Routes.applicationDetail(state.created!.id));
        } else if (state.stage == SubmitStage.failure && state.message != null) {
          AppSnackBar.error(context, state.message!);
        }
      },
      builder: (context, state) {
        if (state.isLoading) {
          return const PageScaffold(title: 'Apply for cover', body: AppLoader(message: 'Loading your animals...'));
        }

        if (state.animals.isEmpty) {
          return PageScaffold(
            title: 'Apply for cover',
            body: EmptyState(
              title: 'No animal is available to insure',
              message: 'Register an animal first, or wait for an existing application to be decided. '
                  'An animal can hold only one active policy at a time.',
              icon: Icons.pets_outlined,
              actionLabel: 'Add an animal',
              onAction: () => context.push(Routes.animalForm),
            ),
          );
        }

        if (state.schemes.isEmpty) {
          return const PageScaffold(
            title: 'Apply for cover',
            body: EmptyState(
              title: 'No scheme is open right now',
              message: 'Applications can only be submitted while a scheme is active and within its validity dates.',
              icon: Icons.policy_outlined,
            ),
          );
        }

        return PageScaffold(
          title: 'Apply for cover',
          body: BlockingProgressOverlay(
            isVisible: state.isSubmitting,
            message: 'Submitting application...',
            child: Stepper(
              currentStep: _step,
              type: StepperType.vertical,
              onStepTapped: (step) => setState(() => _step = step),
              onStepContinue: () => _next(state),
              onStepCancel: _step == 0 ? null : () => setState(() => _step -= 1),
              controlsBuilder: (context, details) => Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: _step == 2 ? 'Submit application' : 'Continue',
                        onPressed: details.onStepContinue,
                        isLoading: state.isSubmitting && _step == 2,
                      ),
                    ),
                    if (details.onStepCancel != null) ...[
                      const SizedBox(width: 12),
                      TextButton(onPressed: details.onStepCancel, child: const Text('Back')),
                    ],
                  ],
                ),
              ),
              steps: [
                Step(
                  title: const Text('Select animal'),
                  subtitle: state.selectedAnimal == null ? null : Text(state.selectedAnimal!.title),
                  isActive: _step >= 0,
                  state: state.selectedAnimal == null ? StepState.indexed : StepState.complete,
                  content: Column(
                    children: [
                      for (final animal in state.animals)
                        RadioListTile<int>(
                          value: animal.id,
                          groupValue: state.selectedAnimal?.id,
                          onChanged: (_) => context.read<ApplicationSubmitCubit>().selectAnimal(animal),
                          title: Text(animal.earTag),
                          subtitle: Text(
                            '${animal.animalType.label}'
                            '${animal.breed == null ? '' : ' - ${animal.breed}'}'
                            ' - ${DateFormatter.monthsToAge(animal.ageMonths)}',
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                ),
                Step(
                  title: const Text('Select scheme'),
                  subtitle: state.selectedScheme == null ? null : Text(state.selectedScheme!.name),
                  isActive: _step >= 1,
                  state: state.selectedScheme == null ? StepState.indexed : StepState.complete,
                  content: Column(
                    children: [
                      for (final scheme in state.schemes)
                        RadioListTile<int>(
                          value: scheme.id,
                          groupValue: state.selectedScheme?.id,
                          onChanged: (_) {
                            _coverageController.clear();
                            context.read<ApplicationSubmitCubit>().selectScheme(scheme);
                          },
                          title: Text(scheme.name),
                          subtitle: Text(
                            'Up to ${DateFormatter.currency(scheme.maxCoverage)} - '
                            'valid till ${DateFormatter.displayRaw(scheme.endDate)}',
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                ),
                Step(
                  title: const Text('Coverage amount'),
                  isActive: _step >= 2,
                  content: Form(
                    key: _coverageKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomTextField(
                          label: 'Requested sum insured',
                          controller: _coverageController,
                          prefixIcon: Icons.currency_rupee,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          helper: state.maxCoverage == null
                              ? null
                              : 'Maximum ${DateFormatter.currency(state.maxCoverage)}',
                          validator: (value) => Validators.amount(
                            value,
                            max: state.maxCoverage,
                            field: 'Coverage amount',
                          ),
                        ),
                        const SizedBox(height: 12),
                        _Summary(animal: state.selectedAnimal, scheme: state.selectedScheme),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({this.animal, this.scheme});

  final AnimalModel? animal;
  final SchemeModel? scheme;

  @override
  Widget build(BuildContext context) {
    if (animal == null || scheme == null) return const SizedBox.shrink();
    return SectionCard(
      title: 'Review',
      icon: Icons.fact_check_outlined,
      children: [
        DetailRow(label: 'Animal', value: animal!.title, icon: Icons.pets_outlined),
        DetailRow(label: 'Scheme', value: scheme!.name, icon: Icons.policy_outlined),
        DetailRow(
          label: 'Scheme limit',
          value: DateFormatter.currency(scheme!.maxCoverage),
          icon: Icons.account_balance_wallet_outlined,
        ),
      ],
    );
  }
}
