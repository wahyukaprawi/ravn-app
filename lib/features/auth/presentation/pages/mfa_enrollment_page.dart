import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../cubit/auth_cubit.dart';

class MfaEnrollmentPage extends StatefulWidget {
  const MfaEnrollmentPage({super.key});

  @override
  State<MfaEnrollmentPage> createState() => _MfaEnrollmentPageState();
}

class _MfaEnrollmentPageState extends State<MfaEnrollmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final state = context.read<AuthCubit>().state;

      if (state is AuthMfaEnrollmentRequired &&
          state.secret == null &&
          !state.isLoading &&
          state.error == null) {
        context.read<AuthCubit>().startMfaEnrollment();
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Set up MFA'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => context.read<AuthCubit>().cancelMfaEnrollment(),
            child: const Text('Cancel'),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state is AuthMfaEnrollmentComplete) {
              return _buildRecoveryCodes(state);
            }

            if (state is AuthMfaEnrollmentRequired) {
              return _buildEnrollment(state);
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildEnrollment(AuthMfaEnrollmentRequired state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Protect your admin account',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add this account to an authenticator app, then enter the six-digit code to finish signing in.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          if (state.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (state.secret != null) ...[
            Card(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Setup key',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      state.secret!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 18,
                        letterSpacing: 2,
                      ),
                    ),
                    if (state.otpauthUrl != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Or open this URI in your authenticator:',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        state.otpauthUrl!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Authenticator code',
                  helperText: 'Six digits from your authenticator app',
                  prefixIcon: Icon(Icons.shield_outlined),
                ),
                keyboardType: TextInputType.number,
                autocorrect: false,
                enableSuggestions: false,
                validator: (value) {
                  final code = value?.trim() ?? '';
                  if (code.length < 6) {
                    return 'Enter the complete six-digit code';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            AppButton(
              text: 'Confirm and continue',
              isLoading: state.isLoading,
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  context.read<AuthCubit>().confirmMfaEnrollment(
                    _codeController.text.trim(),
                  );
                }
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.read<AuthCubit>().startMfaEnrollment(),
              child: const Text('Generate a new setup key'),
            ),
          ] else ...[
            Text(
              state.error ?? 'Unable to start MFA enrollment.',
              style: const TextStyle(color: AppColors.danger),
            ),
            const SizedBox(height: 16),
            AppButton(
              text: 'Try again',
              isLoading: state.isLoading,
              onPressed: () => context.read<AuthCubit>().startMfaEnrollment(),
            ),
          ],
          if (state.error != null && state.secret != null) ...[
            const SizedBox(height: 12),
            Text(state.error!, style: const TextStyle(color: AppColors.danger)),
          ],
        ],
      ),
    );
  }

  Widget _buildRecoveryCodes(AuthMfaEnrollmentComplete state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 56,
            color: AppColors.success,
          ),
          const SizedBox(height: 16),
          Text(
            'MFA is enabled',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Store these recovery codes somewhere safe. Each code can be used once if you lose access to your authenticator.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Card(
            color: AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (final code in state.recoveryCodes)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: SelectableText(
                        code,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          AppButton(
            text: 'I have saved these codes',
            onPressed: () => context.read<AuthCubit>().finishMfaEnrollment(),
          ),
        ],
      ),
    );
  }
}
