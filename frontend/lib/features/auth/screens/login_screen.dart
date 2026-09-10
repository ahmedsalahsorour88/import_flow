import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/copyable_data_helper.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController(text: 'manager');
  final _passwordCtrl = TextEditingController(text: 'manager123');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final l = context.l10n;
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    final ok = await ref.read(authProvider.notifier).login(username, password);
    if (!ok && mounted) {
      final err = ref.read(authProvider).errorMessage ?? l.loginInvalidCredentials;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(err)),
            ],
          ),
          backgroundColor: AppTheme.crimson,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _quickFill(String user, String pass) {
    _usernameCtrl.text = user;
    _passwordCtrl.text = pass;
    _handleLogin();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currentLocale = ref.watch(localeProvider);
    final l = context.l10n;

    return Scaffold(
      backgroundColor: AppTheme.charcoal,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Card(
                elevation: 10,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: SelectionArea(
                  child: Container(
                    width: 440,
                    padding: const EdgeInsets.all(36),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Language Switcher in Card Header
                          Align(
                            alignment: AlignmentDirectional.topEnd,
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.cobalt,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                              icon: const Icon(Icons.language_rounded, size: 18),
                              label: Text(
                                currentLocale.languageCode == 'ar' ? 'English' : 'العربية',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              onPressed: () {
                                ref.read(localeProvider.notifier).toggleLocale();
                              },
                            ),
                          ),

                          // System Logo & Branding
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.cobalt.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.local_shipping_rounded, size: 48, color: AppTheme.cobalt),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l.appTitle,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.charcoal,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l.loginScreenSubtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                          const SizedBox(height: 28),

                          // Username Field
                          TextFormField(
                            controller: _usernameCtrl,
                            decoration: InputDecoration(
                              labelText: l.loginUsernameLabel,
                              prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                              hintText: l.loginUsernameHint,
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 18),
                                tooltip: l.loginCopyUsernameTooltip,
                                onPressed: () => CopyHelper.copy(
                                  context,
                                  _usernameCtrl.text,
                                  customMessage: l.loginUsernameCopied,
                                ),
                              ),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? l.loginUsernameRequired : null,
                          ),
                          const SizedBox(height: 16),

                          // Password Field
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: l.loginPasswordLabel,
                              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.copy_rounded, size: 18),
                                    tooltip: l.loginCopyPasswordTooltip,
                                    onPressed: () => CopyHelper.copy(
                                      context,
                                      _passwordCtrl.text,
                                      customMessage: l.loginPasswordCopied,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ],
                              ),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? l.loginPasswordRequired : null,
                            onFieldSubmitted: (_) => _handleLogin(),
                          ),
                          const SizedBox(height: 24),

                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: authState.isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.cobalt,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 2,
                              ),
                              icon: authState.isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.login_rounded, size: 20),
                              label: Text(
                                authState.isLoading ? l.loginAuthenticating : l.loginButtonLabel,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                          Divider(color: Colors.grey.shade300),
                          const SizedBox(height: 12),

                          // Quick Dev Logins
                          Text(
                            l.loginQuickDemoAccess,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildQuickDemoChip(
                                icon: Icons.admin_panel_settings_rounded,
                                color: AppTheme.crimson,
                                roleLabel: l.loginRoleAdmin,
                                username: 'admin',
                                password: 'admin123',
                                l: l,
                              ),
                              _buildQuickDemoChip(
                                icon: Icons.manage_accounts_rounded,
                                color: AppTheme.cobalt,
                                roleLabel: l.loginRoleManager,
                                username: 'manager',
                                password: 'manager123',
                                l: l,
                              ),
                              _buildQuickDemoChip(
                                icon: Icons.badge_rounded,
                                color: AppTheme.emerald,
                                roleLabel: l.loginRoleSpecialist,
                                username: 'operator1',
                                password: 'operator123',
                                l: l,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickDemoChip({
    required IconData icon,
    required Color color,
    required String roleLabel,
    required String username,
    required String password,
    required AppLocalizations l,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => _quickFill(username, password),
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(20),
              right: Radius.circular(4),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: 6),
                  Text(
                    roleLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () => CopyHelper.copy(
              context,
              '$username ($password)',
              customMessage: l.loginDemoCredentialsCopied,
            ),
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(4),
              right: Radius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Tooltip(
                message: l.loginDemoCredentialsTooltip,
                child: Icon(Icons.copy_rounded, size: 13, color: color.withOpacity(0.85)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
