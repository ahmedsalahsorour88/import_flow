import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
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
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    final ok = await ref.read(authProvider.notifier).login(username, password);
    if (!ok && mounted) {
      final err = ref.read(authProvider).errorMessage ?? 'اسم المستخدم أو كلمة المرور غير صحيحة';
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

    return Scaffold(
      backgroundColor: AppTheme.charcoal,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: 440,
              padding: const EdgeInsets.all(36),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                    const Text(
                      'Sorour Logistics',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.charcoal,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'منظومة سرور لإدارة سلاسل الإمداد والاستيراد والتخليص الجمركي',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 28),

                    // Username Field
                    TextFormField(
                      controller: _usernameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'اسم المستخدم أو البريد الإلكتروني (Username / Email)',
                        prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                        hintText: 'admin / manager / operator1',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال اسم المستخدم' : null,
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور (Password)',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال كلمة المرور' : null,
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
                          authState.isLoading ? 'جاري تسجيل الدخول والتحقق...' : 'تسجيل الدخول إلى النظام (Login)',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    Divider(color: Colors.grey.shade300),
                    const SizedBox(height: 12),

                    // Quick Dev Logins
                    Text(
                      'الدخول السريع بحسابات النظام التجريبية (Quick Demo Access):',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.admin_panel_settings_rounded, size: 14, color: AppTheme.crimson),
                          label: const Text('Admin', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: () => _quickFill('admin', 'admin123'),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.manage_accounts_rounded, size: 14, color: AppTheme.cobalt),
                          label: const Text('Manager', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: () => _quickFill('manager', 'manager123'),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.badge_rounded, size: 14, color: AppTheme.emerald),
                          label: const Text('Specialist', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: () => _quickFill('operator1', 'operator123'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
