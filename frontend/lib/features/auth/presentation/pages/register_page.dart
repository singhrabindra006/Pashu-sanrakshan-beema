import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/error/error_snackbar.dart';
import '../../../../core/widgets/inputs/custom_text_field.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/auth_form.dart';

/// Screen 3. Farmer self-registration: Firebase sign-up followed by
/// POST /auth/sync, which creates the MySQL user and farmer profile.
/// Admin accounts are provisioned directly in the database.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    FocusScope.of(context).unfocus();
    context.read<AuthCubit>().register(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (previous, current) => current is AuthFailure,
      listener: (context, state) {
        if (state is AuthFailure) AppSnackBar.error(context, state.message);
      },
      builder: (context, state) {
        final isBusy = state is AuthSubmitting;

        return AuthFormShell(
          icon: Icons.person_add_alt_1_outlined,
          title: 'Create account',
          subtitle:
              'Farmers can register here. Admin accounts are issued separately.',
          footer: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Already registered?'),
              TextButton(
                onPressed: isBusy ? null : () => context.pop(),
                child: const Text('Sign in'),
              ),
            ],
          ),
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  CustomTextField(
                    label: 'Full name',
                    controller: _nameController,
                    prefixIcon: Icons.person_outline,
                    textCapitalizationWords: true,
                    textInputAction: TextInputAction.next,
                    validator: Validators.fullName,
                    enabled: !isBusy,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Email',
                    controller: _emailController,
                    prefixIcon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: Validators.email,
                    enabled: !isBusy,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Password',
                    controller: _passwordController,
                    prefixIcon: Icons.lock_outline,
                    obscure: true,
                    textInputAction: TextInputAction.next,
                    helper: 'At least 6 characters',
                    validator: Validators.password,
                    enabled: !isBusy,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Confirm password',
                    controller: _confirmController,
                    prefixIcon: Icons.lock_reset_outlined,
                    obscure: true,
                    textInputAction: TextInputAction.done,
                    validator: (value) => Validators.confirmPassword(
                      value,
                      _passwordController.text,
                    ),
                    enabled: !isBusy,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Create account',
              onPressed: _submit,
              isLoading: isBusy,
            ),
          ],
        );
      },
    );
  }
}
