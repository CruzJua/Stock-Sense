import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'signup_screen.dart';

/// Email + Google sign-in screen.
///
/// Uses Supabase Auth under the hood; the [authStateProvider] in
/// `auth_provider.dart` will emit a new value once sign-in succeeds,
/// which the [RootShell] listens to in order to redirect to the home tab.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Auth helpers
  // ---------------------------------------------------------------------------

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    TextInput.finishAutofillContext();
    _setLoading(true);

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (_) {
      _setError('An unexpected error occurred. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _signInWithGoogle() async {
    _setLoading(true);
    try {
      await Supabase.instance.client.auth.signInWithOAuth(OAuthProvider.google);
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (_) {
      _setError('Could not open Google sign-in. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    if (mounted) setState(() => _isLoading = value);
  }

  void _setError(String message) {
    if (mounted) setState(() => _errorMessage = message);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 40),
                _buildForm(),
                const SizedBox(height: 24),
                _buildDivider(),
                const SizedBox(height: 24),
                _buildGoogleButton(),
                const SizedBox(height: 32),
                _buildSignUpLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sections
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // App logo / wordmark
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.inventory_2_rounded,
                  color: AppColors.black, size: 22),
            ),
            const SizedBox(width: 12),
            Text('StockSense', style: AppTextStyles.headlineMedium),
          ],
        ),
        const SizedBox(height: 32),
        Text('Welcome back', style: AppTextStyles.displayLarge.copyWith(fontSize: 32)),
        const SizedBox(height: 8),
        Text('Sign in to manage your inventory.',
            style: AppTextStyles.bodyLarge),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Error banner
            if (_errorMessage != null) ...[
              _ErrorBanner(message: _errorMessage!),
              const SizedBox(height: 16),
            ],

            // Email
            TextFormField(
              controller: _emailCtrl,
              autofillHints: [AutofillHints.email],
              keyboardType: TextInputType.emailAddress,
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Email address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email is required.';
                if (!v.contains('@')) return 'Enter a valid email.';
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Password
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              autofillHints: [AutofillHints.password],
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required.';
                if (v.length < 6) return 'Password must be at least 6 characters.';
                return null;
              },
            ),

            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async{
                  final email = _emailCtrl.text.trim();
                  if (email.isEmpty) {
                    _setError('Please enter your email address first.');
                    return;
                  }
                  _setLoading(true);
                  try {
                    await Supabase.instance.client.auth.resetPasswordForEmail(email);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Password reset link sent to $email')),
                      );
                    }
                  } catch (e) {
                    _setError('Failed to send reset link. Try again.');
                  } finally {
                    _setLoading(false);
                  }
                },
                child: const Text('Forgot password?'),
              ),
            ),

            const SizedBox(height: 8),

            // Primary CTA
            ElevatedButton(
              onPressed: _isLoading ? null : _signInWithEmail,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.black),
                    )
                  : const Text('Sign In'),
            ),
          ],
        ),
    )
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('OR', style: AppTextStyles.labelMedium),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : _signInWithGoogle,
      icon: const Icon(Icons.g_mobiledata_rounded, size: 24),
      label: const Text('Continue with Google'),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Don't have an account? ", style: AppTextStyles.bodyMedium),
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SignupScreen()),
            );
          },
          child: const Text('Sign Up'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Error banner widget
// ---------------------------------------------------------------------------

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.errorDark.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
