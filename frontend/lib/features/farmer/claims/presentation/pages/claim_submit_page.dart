import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../core/utils/file_picker_helper.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../core/widgets/buttons/primary_button.dart';
import '../../../../../core/widgets/error/empty_state.dart';
import '../../../../../core/widgets/error/error_snackbar.dart';
import '../../../../../core/widgets/inputs/custom_text_field.dart';
import '../../../../../core/widgets/inputs/dropdown_field.dart';
import '../../../../../core/widgets/layout/page_scaffold.dart';
import '../../../../../core/widgets/layout/responsive_layout.dart';
import '../../../../../core/widgets/loading/app_loader.dart';
import '../../../../../core/widgets/media/cached_image.dart';
import '../../../../../injection_container.dart';
import '../../../../shared/data/models/application_model.dart';
import '../../../../shared/file_upload/presentation/cubit/file_upload_cubit.dart';
import '../../../applications/data/repositories/application_repository.dart';
import '../../data/repositories/claim_repository.dart';
import '../cubit/claim_submit_cubit.dart';

/// Screen 15. Claim form against an approved policy, with optional evidence.
class ClaimSubmitPage extends StatelessWidget {
  const ClaimSubmitPage({super.key, this.preselectedApplicationId});

  final int? preselectedApplicationId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ClaimSubmitCubit(
            claims: sl<ClaimRepository>(),
            applications: sl<ApplicationRepository>(),
          )..loadPolicies(preselectedApplicationId: preselectedApplicationId),
        ),
        BlocProvider(create: (_) => FileUploadCubit(picker: sl<FilePickerHelper>())),
      ],
      child: const _ClaimSubmitView(),
    );
  }
}

class _ClaimSubmitView extends StatefulWidget {
  const _ClaimSubmitView();

  @override
  State<_ClaimSubmitView> createState() => _ClaimSubmitViewState();
}

class _ClaimSubmitViewState extends State<_ClaimSubmitView> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  IncidentType? _incidentType;
  DateTime? _incidentDate;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit(ClaimSubmitState state) {
    if (_formKey.currentState?.validate() != true) return;
    if (state.selectedPolicy == null) {
      AppSnackBar.info(context, 'Select the policy you are claiming against');
      return;
    }
    FocusScope.of(context).unfocus();

    context.read<ClaimSubmitCubit>().submit(
          incidentType: _incidentType!,
          incidentDate: _incidentDate!,
          description: _descriptionController.text.trim(),
          claimedAmount: double.parse(_amountController.text.trim().replaceAll(',', '')),
          evidencePath: context.read<FileUploadCubit>().state.path,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ClaimSubmitCubit, ClaimSubmitState>(
      listener: (context, state) {
        if (state.stage == ClaimSubmitStage.submitted && state.created != null) {
          AppSnackBar.success(context, 'Claim ${state.created!.claimNumber} submitted');
          context.pop();
          context.push(Routes.claimDetail(state.created!.id));
        } else if (state.stage == ClaimSubmitStage.failure && state.message != null && state.policies.isNotEmpty) {
          AppSnackBar.error(context, state.message!);
        }
      },
      builder: (context, state) {
        if (state.isLoading) {
          return const PageScaffold(title: 'File a claim', body: AppLoader(message: 'Loading your policies...'));
        }

        if (state.policies.isEmpty) {
          return PageScaffold(
            title: 'File a claim',
            body: EmptyState(
              title: state.message ?? 'No approved policy to claim against',
              message: 'A claim can only be filed after an application is approved. '
                  'Apply for cover first, then come back here.',
              icon: Icons.verified_user_outlined,
              actionLabel: 'Apply for cover',
              onAction: () => context.push(Routes.applicationSubmit),
            ),
          );
        }

        final upload = context.watch<FileUploadCubit>().state;
        final policy = state.selectedPolicy;

        return PageScaffold(
          title: 'File a claim',
          body: BlockingProgressOverlay(
            isVisible: state.isSubmitting,
            message: 'Submitting claim...',
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: ResponsiveLayout(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownField<ApplicationModel>(
                        label: 'Approved policy',
                        prefixIcon: Icons.verified_outlined,
                        items: state.policies,
                        value: policy,
                        itemLabel: (item) => item.policyLabel,
                        validator: (value) => value == null ? 'Select a policy' : null,
                        onChanged: (value) {
                          _amountController.clear();
                          context.read<ClaimSubmitCubit>().selectPolicy(value);
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownField<IncidentType>(
                        label: 'Incident type',
                        prefixIcon: Icons.report_problem_outlined,
                        items: IncidentType.values,
                        value: _incidentType,
                        itemLabel: (type) => type.label,
                        hint: 'What happened?',
                        validator: (value) => value == null ? 'Select an incident type' : null,
                        onChanged: (type) => setState(() => _incidentType = type),
                      ),
                      const SizedBox(height: 16),
                      DatePickerField(
                        label: 'Incident date',
                        value: _incidentDate,
                        lastDate: DateTime.now(),
                        validator: (value) => value == null ? 'Incident date is required' : null,
                        onChanged: (date) => setState(() => _incidentDate = date),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Description',
                        controller: _descriptionController,
                        prefixIcon: Icons.notes_outlined,
                        maxLines: 4,
                        maxLength: 2000,
                        helper: 'Describe what happened, when, and where',
                        validator: (value) => Validators.minLength(value, 10, field: 'Description'),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Claimed amount',
                        controller: _amountController,
                        prefixIcon: Icons.currency_rupee,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        helper: policy == null
                            ? null
                            : 'Cannot exceed ${DateFormatter.currency(policy.coverageAmount)}',
                        validator: (value) => Validators.amount(
                          value,
                          max: policy?.coverageAmount,
                          field: 'Claimed amount',
                        ),
                      ),
                      const SizedBox(height: 20),
                      _EvidencePicker(
                        file: upload.file,
                        isBusy: upload.isPicking,
                        onPick: () => context.read<FileUploadCubit>().pickEvidence(),
                        onClear: upload.hasFile ? context.read<FileUploadCubit>().clear : null,
                      ),
                      if (upload.message != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            upload.message!,
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          ),
                        ),
                      const SizedBox(height: 28),
                      PrimaryButton(
                        label: 'Submit claim',
                        icon: Icons.send_outlined,
                        isLoading: state.isSubmitting,
                        onPressed: () => _submit(state),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EvidencePicker extends StatelessWidget {
  const _EvidencePicker({
    required this.file,
    required this.isBusy,
    required this.onPick,
    this.onClear,
  });

  final PickedFileRef? file;
  final bool isBusy;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Evidence (optional)', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        if (file != null && !file!.isPdf)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CachedImage(
              url: null,
              localFilePath: file!.path,
              width: double.infinity,
              height: 160,
              fallbackIcon: Icons.attach_file_outlined,
            ),
          )
        else
          Card(
            child: ListTile(
              leading: Icon(file == null ? Icons.attach_file_outlined : Icons.picture_as_pdf_outlined),
              title: Text(file?.name ?? 'Photo or PDF'),
              subtitle: Text(file == null ? 'JPG, PNG or PDF, up to 10 MB' : file!.readableSize),
            ),
          ),
        Row(
          children: [
            TextButton.icon(
              onPressed: isBusy ? null : onPick,
              icon: const Icon(Icons.upload_file_outlined, size: 18),
              label: Text(file == null ? 'Add evidence' : 'Change file'),
            ),
            if (onClear != null)
              TextButton.icon(
                onPressed: onClear,
                icon: Icon(Icons.close, size: 18, color: scheme.error),
                label: const Text('Remove'),
              ),
          ],
        ),
      ],
    );
  }
}
