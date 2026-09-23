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

/// Screen 4. Sends the Firebase password reset email.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    FocusScope.of(context).unfocus();
    context.read<AuthCubit>().sendPasswordReset(_emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          current is AuthFailure || current is AuthUnauthenticated,
      listener: (context, state) {
        if (state is AuthFailure) AppSnackBar.error(context, state.message);
        if (state is AuthUnauthenticated && state.notice != null) {
          setState(() => _sent = true);
          AppSnackBar.success(context, state.notice!);
        }
      },
      builder: (context, state) {
        final isBusy = state is AuthSubmitting;

        return AuthFormShell(
          icon: Icons.lock_reset_outlined,
          title: 'Reset your password',
          subtitle: 'We will email you a secure link to set a new password',
          footer: TextButton(
            onPressed: isBusy ? null : () => context.pop(),
            child: const Text('Back to sign in'),
          ),
          children: [
            Form(
              key: _formKey,
              child: CustomTextField(
                label: 'Email',
                controller: _emailController,
                prefixIcon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                validator: Validators.email,
                enabled: !isBusy,
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: _sent ? 'Resend link' : 'Send reset link',
              onPressed: _submit,
              isLoading: isBusy,
            ),
            if (_sent) ...[
              const SizedBox(height: 16),
              Text(
                'Link sent. Open it on this device, set a new password, then come back and sign in.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        );
      },
    );
  }
}
