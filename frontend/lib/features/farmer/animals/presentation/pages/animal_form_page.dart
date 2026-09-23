import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/cubit/item_state.dart';
import '../../../../../core/utils/file_picker_helper.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../core/widgets/buttons/primary_button.dart';
import '../../../../../core/widgets/error/error_snackbar.dart';
import '../../../../../core/widgets/inputs/custom_text_field.dart';
import '../../../../../core/widgets/inputs/dropdown_field.dart';
import '../../../../../core/widgets/layout/page_scaffold.dart';
import '../../../../../core/widgets/layout/responsive_layout.dart';
import '../../../../../core/widgets/loading/app_loader.dart';
import '../../../../../core/widgets/media/cached_image.dart';
import '../../../../../injection_container.dart';
import '../../../../shared/data/models/animal_model.dart';
import '../../../../shared/file_upload/presentation/cubit/file_upload_cubit.dart';
import '../../data/repositories/animal_repository.dart';
import '../cubit/animal_form_cubit.dart';

/// Screen 8. Add or edit one animal; submits as multipart with an optional photo.
class AnimalFormPage extends StatelessWidget {
  const AnimalFormPage({super.key, this.animal});

  final AnimalModel? animal;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AnimalFormCubit(sl<AnimalRepository>(), existing: animal)),
        BlocProvider(create: (_) => FileUploadCubit(picker: sl<FilePickerHelper>())),
      ],
      child: _AnimalFormView(animal: animal),
    );
  }
}

class _AnimalFormView extends StatefulWidget {
  const _AnimalFormView({this.animal});

  final AnimalModel? animal;

  @override
  State<_AnimalFormView> createState() => _AnimalFormViewState();
}

class _AnimalFormViewState extends State<_AnimalFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _earTagController = TextEditingController(text: widget.animal?.earTag);
  late final TextEditingController _breedController = TextEditingController(text: widget.animal?.breed);
  late final TextEditingController _ageController =
      TextEditingController(text: widget.animal == null ? '' : widget.animal!.ageMonths.toString());
  late AnimalType _animalType = widget.animal?.animalType ?? AnimalType.cow;

  bool get _isEditing => widget.animal != null;

  @override
  void dispose() {
    _earTagController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final source = await FilePickerHelper.chooseImageSource(context);
    if (source == null || !mounted) return;
    await context.read<FileUploadCubit>().pickImage(source);
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    FocusScope.of(context).unfocus();

    context.read<AnimalFormCubit>().submit(
          earTag: _earTagController.text.trim(),
          animalType: _animalType,
          breed: _breedController.text.trim(),
          ageMonths: int.tryParse(_ageController.text.trim()) ?? 0,
          photoPath: context.read<FileUploadCubit>().state.path,
        );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<FileUploadCubit, FileUploadState>(
          listenWhen: (previous, current) => current.status == FileUploadStatus.failure,
          listener: (context, state) {
            if (state.message != null) AppSnackBar.error(context, state.message!);
          },
        ),
        BlocListener<AnimalFormCubit, ItemState<AnimalModel>>(
          listener: (context, state) {
            if (state.isSubmitted) {
              AppSnackBar.success(context, state.message ?? 'Saved');
              context.pop(true);
            } else if (state.isFailure && state.message != null) {
              AppSnackBar.error(context, state.message!);
            }
          },
        ),
      ],
      child: BlocBuilder<AnimalFormCubit, ItemState<AnimalModel>>(
      builder: (context, state) {
        final upload = context.watch<FileUploadCubit>().state;

        return PageScaffold(
          title: _isEditing ? 'Edit animal' : 'Add animal',
          body: BlockingProgressOverlay(
            isVisible: state.isSubmitting,
            message: 'Saving animal...',
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: ResponsiveLayout(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PhotoPicker(
                        localPath: upload.path,
                        existingUrl: widget.animal?.photoUrl,
                        isBusy: upload.isPicking,
                        onPick: _pickPhoto,
                        onClear: upload.hasFile ? context.read<FileUploadCubit>().clear : null,
                      ),
                      const SizedBox(height: 24),
                      CustomTextField(
                        label: 'Ear tag',
                        controller: _earTagController,
                        prefixIcon: Icons.confirmation_number_outlined,
                        textInputAction: TextInputAction.next,
                        helper: 'The unique physical tag number on the animal',
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-/]')),
                          LengthLimitingTextInputFormatter(50),
                        ],
                        validator: Validators.earTag,
                        errorText: state.fieldErrors?['ear_tag'],
                      ),
                      const SizedBox(height: 16),
                      DropdownField<AnimalType>(
                        label: 'Animal type',
                        prefixIcon: Icons.pets_outlined,
                        items: AnimalType.values,
                        value: _animalType,
                        itemLabel: (type) => type.label,
                        onChanged: (type) => setState(() => _animalType = type ?? AnimalType.cow),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Breed (optional)',
                        controller: _breedController,
                        prefixIcon: Icons.category_outlined,
                        textInputAction: TextInputAction.next,
                        textCapitalizationWords: true,
                        validator: (value) => Validators.maxLength(value, 100, field: 'Breed'),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Age in months',
                        controller: _ageController,
                        prefixIcon: Icons.cake_outlined,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: Validators.ageMonths,
                      ),
                      const SizedBox(height: 28),
                      PrimaryButton(
                        label: _isEditing ? 'Save changes' : 'Register animal',
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
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.localPath,
    required this.existingUrl,
    required this.isBusy,
    required this.onPick,
    this.onClear,
  });

  final String? localPath;
  final String? existingUrl;
  final bool isBusy;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CachedImage(
          url: existingUrl,
          localFilePath: localPath,
          width: double.infinity,
          height: 190,
          fallbackIcon: Icons.add_a_photo_outlined,
          borderRadius: BorderRadius.circular(16),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: isBusy ? null : onPick,
              icon: const Icon(Icons.photo_camera_outlined, size: 18),
              label: Text(localPath == null && existingUrl == null ? 'Add photo' : 'Change photo'),
            ),
            if (onClear != null)
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Remove'),
              ),
          ],
        ),
        Text(
          'JPG or PNG, up to 5 MB',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
