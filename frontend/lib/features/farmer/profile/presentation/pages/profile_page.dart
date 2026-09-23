import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/cubit/item_state.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/cubit/theme_cubit.dart';
import '../../../../../core/theme/cubit/theme_state.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../core/utils/extensions.dart';
import '../../../../../core/utils/file_picker_helper.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../core/widgets/dialogs/confirm_dialog.dart';
import '../../../../../core/widgets/dialogs/input_dialog.dart';
import '../../../../../core/widgets/error/empty_state.dart';
import '../../../../../core/widgets/error/error_snackbar.dart';
import '../../../../../core/widgets/layout/page_scaffold.dart';
import '../../../../../core/widgets/loading/app_loader.dart';
import '../../../../../core/widgets/media/cached_image.dart';
import '../../../../../injection_container.dart';
import '../../../../auth/domain/entities/user_entity.dart';
import '../../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../../shared/data/models/profile_model.dart';
import '../../../../shared/file_viewer/presentation/pages/file_viewer_page.dart';
import '../../data/repositories/profile_repository.dart';
import '../cubit/profile_cubit.dart';
import '../widgets/profile_avatar.dart';

/// Screen 6. Read-only identity with two editable things: phone and avatar.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileCubit(sl<ProfileRepository>())..load(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  Future<void> _editPhone(BuildContext context, ProfileModel profile) async {
    final phone = await InputDialog.show(
      context,
      title: 'Edit phone number',
      label: 'Phone number',
      initialValue: profile.phone,
      keyboardType: TextInputType.phone,
      helper: 'Used by the insurer to reach you about claims',
      validator: Validators.phone,
    );
    if (phone == null || !context.mounted) return;

    final updated = await context.read<ProfileCubit>().updatePhone(phone);
    if (!context.mounted) return;
    if (updated != null) {
      _syncAuth(context, updated);
      AppSnackBar.success(context, 'Phone number updated');
    }
  }

  Future<void> _changeAvatar(BuildContext context) async {
    final source = await FilePickerHelper.chooseImageSource(context);
    if (source == null || !context.mounted) return;

    final picked = await sl<FilePickerHelper>().pickImage(source: source);
    if (!context.mounted) return;

    final file = picked.dataOrNull;
    if (file == null) {
      final error = picked.errorOrNull;
      if (error != null) AppSnackBar.failure(context, error);
      return;
    }

    final updated = await context.read<ProfileCubit>().uploadPhoto(file.path);
    if (!context.mounted) return;
    if (updated != null) {
      // The cached image widget must forget the previous URL's bytes.
      AuthImageHeaders.invalidate();
      _syncAuth(context, updated);
      AppSnackBar.success(context, 'Profile photo updated');
    }
  }

  /// Keeps the app bar avatar and hydrated auth state in step with the edit.
  void _syncAuth(BuildContext context, ProfileModel profile) {
    final authCubit = context.read<AuthCubit>();
    final user = authCubit.state.user;
    if (user == null) return;
    authCubit.updateProfile(
      user.copyWith(
        farmerProfile: FarmerProfileEntity(
          id: profile.id,
          phone: profile.phone,
          profileImagePath: user.farmerProfile?.profileImagePath,
          imageUrl: profile.imageUrl,
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Sign out?',
      message: 'You will need your email and password to sign back in.',
      confirmLabel: 'Sign out',
      isDestructive: true,
      icon: Icons.logout_rounded,
    );
    if (!confirmed || !context.mounted) return;
    await context.read<AuthCubit>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ItemState<ProfileModel>>(
      listenWhen: (previous, current) => current.isFailure,
      listener: (context, state) {
        if (state.message != null) AppSnackBar.error(context, state.message!);
      },
      builder: (context, state) {
        final profile = state.item;

        return PageScaffold(
          title: 'My profile',
          showBackButton: false,
          onRefresh: () => context.read<ProfileCubit>().load(),
          actions: [
            IconButton(
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout_rounded),
              onPressed: () => _logout(context),
            ),
          ],
          body: profile == null
              ? (state.isFailure
                  ? EmptyState.error(
                      title: 'Could not load your profile',
                      message: state.message,
                      onAction: () => context.read<ProfileCubit>().load(),
                    )
                  : const AppLoader(message: 'Loading profile...'))
              : BlockingProgressOverlay(
                  isVisible: state.isSubmitting,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      Center(
                        child: ProfileAvatar(
                          name: profile.fullName,
                          imageUrl: profile.imageUrl,
                          isUploading: state.isSubmitting,
                          onEdit: () => _changeAvatar(context),
                          onView: profile.imageUrl == null
                              ? null
                              : () => context.push(
                                    Routes.fileViewer,
                                    extra: FileViewerArgs(url: profile.imageUrl!, title: 'Profile photo'),
                                  ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: Text(
                          profile.fullName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Center(
                        child: Text(
                          profile.email,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SectionCard(
                        title: 'Account details',
                        icon: Icons.badge_outlined,
                        children: [
                          DetailRow(label: 'Full name', value: profile.fullName, icon: Icons.person_outline),
                          DetailRow(label: 'Email', value: profile.email, icon: Icons.mail_outline),
                          DetailRow(
                            label: 'Phone',
                            value: profile.phone.orDash(),
                            icon: Icons.phone_outlined,
                            trailing: IconButton(
                              tooltip: 'Edit phone',
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => _editPhone(context, profile),
                            ),
                          ),
                          DetailRow(
                            label: 'Member since',
                            value: DateFormatter.display(profile.createdAt),
                            icon: Icons.event_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      BlocBuilder<ThemeCubit, ThemeState>(
                        builder: (context, themeState) => Card(
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.brightness_6_outlined),
                                title: const Text('Appearance'),
                                subtitle: Text(themeState.label),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => context.read<ThemeCubit>().toggle(),
                              ),
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
