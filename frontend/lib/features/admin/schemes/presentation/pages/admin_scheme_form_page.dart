import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/cubit/item_state.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../core/widgets/buttons/primary_button.dart';
import '../../../../../core/widgets/error/error_snackbar.dart';
import '../../../../../core/widgets/inputs/custom_text_field.dart';
import '../../../../../core/widgets/inputs/dropdown_field.dart';
import '../../../../../core/widgets/layout/page_scaffold.dart';
import '../../../../../core/widgets/layout/responsive_layout.dart';
import '../../../../../core/widgets/loading/app_loader.dart';
import '../../../../../injection_container.dart';
import '../../../../shared/data/models/scheme_model.dart';
import '../../data/repositories/admin_scheme_repository.dart';
import '../cubit/admin_scheme_form_cubit.dart';

/// Screen 20. Create or update a scheme, including coverage limit and dates.
class AdminSchemeFormPage extends StatelessWidget {
  const AdminSchemeFormPage({super.key, this.scheme});

  final SchemeModel? scheme;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminSchemeFormCubit(sl<AdminSchemeRepository>(), existing: scheme),
      child: _AdminSchemeFormView(scheme: scheme),
    );
  }
}

class _AdminSchemeFormView extends StatefulWidget {
  const _AdminSchemeFormView({this.scheme});

  final SchemeModel? scheme;

  @override
  State<_AdminSchemeFormView> createState() => _AdminSchemeFormViewState();
}

class _AdminSchemeFormViewState extends State<_AdminSchemeFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController = TextEditingController(text: widget.scheme?.name);
  late final TextEditingController _descriptionController = TextEditingController(text: widget.scheme?.description);
  late final TextEditingController _coverageController = TextEditingController(
    text: widget.scheme == null ? '' : widget.scheme!.maxCoverage.toStringAsFixed(0),
  );
  late DateTime? _startDate = DateFormatter.parse(widget.scheme?.startDate);
  late DateTime? _endDate = DateFormatter.parse(widget.scheme?.endDate);

  bool get _isEditing => widget.scheme != null;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _coverageController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    final rangeError = Validators.dateRange(_startDate, _endDate);
    if (rangeError != null) {
      AppSnackBar.error(context, rangeError);
      return;
    }
    FocusScope.of(context).unfocus();

    context.read<AdminSchemeFormCubit>().submit(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          maxCoverage: double.parse(_coverageController.text.trim().replaceAll(',', '')),
          startDate: _startDate!,
          endDate: _endDate!,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminSchemeFormCubit, ItemState<SchemeModel>>(
      listener: (context, state) {
        if (state.isSubmitted) {
          AppSnackBar.success(context, state.message ?? 'Saved');
          context.pop(true);
        } else if (state.isFailure && state.message != null) {
          AppSnackBar.error(context, state.message!);
        }
      },
      builder: (context, state) {
        return PageScaffold(
          title: _isEditing ? 'Edit scheme' : 'New scheme',
          body: BlockingProgressOverlay(
            isVisible: state.isSubmitting,
            message: 'Saving scheme...',
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: ResponsiveLayout(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomTextField(
                        label: 'Scheme name',
                        controller: _nameController,
                        prefixIcon: Icons.policy_outlined,
                        textInputAction: TextInputAction.next,
                        textCapitalizationWords: true,
                        validator: (value) => Validators.minLength(value, 3, field: 'Scheme name'),
                        errorText: state.fieldErrors?['name'],
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Description (optional)',
                        controller: _descriptionController,
                        prefixIcon: Icons.notes_outlined,
                        maxLines: 4,
                        maxLength: 2000,
                        validator: (value) => Validators.maxLength(value, 2000, field: 'Description'),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Maximum cover',
                        controller: _coverageController,
                        prefixIcon: Icons.currency_rupee,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        helper: 'Highest sum insured a farmer may request',
                        validator: (value) => Validators.amount(value, field: 'Maximum cover'),
                        errorText: state.fieldErrors?['max_coverage'],
                      ),
                      const SizedBox(height: 16),
                      DatePickerField(
                        label: 'Start date',
                        value: _startDate,
                        validator: (value) => value == null ? 'Start date is required' : null,
                        onChanged: (date) => setState(() => _startDate = date),
                      ),
                      const SizedBox(height: 16),
                      DatePickerField(
                        label: 'End date',
                        value: _endDate,
                        firstDate: _startDate,
                        validator: (value) => Validators.dateRange(_startDate, value),
                        onChanged: (date) => setState(() => _endDate = date),
                      ),
                      const SizedBox(height: 28),
                      PrimaryButton(
                        label: _isEditing ? 'Save changes' : 'Create scheme',
                        icon: Icons.check,
                        isLoading: state.isSubmitting,
                        onPressed: _submit,
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
