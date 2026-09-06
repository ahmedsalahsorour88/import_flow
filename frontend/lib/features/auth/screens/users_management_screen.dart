import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/users_provider.dart';

class UsersManagementScreen extends ConsumerStatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  ConsumerState<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends ConsumerState<UsersManagementScreen> {
  String _filterRole = 'ALL';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(usersProvider.notifier).fetchUsers();
    });
  }

  // ─── Role Helpers ──────────────────────────────────────────────────────────

  Color _roleColor(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return AppTheme.crimson;
      case 'MANAGER':
        return AppTheme.cobalt;
      default:
        return AppTheme.emerald;
    }
  }


  IconData _roleIcon(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return Icons.admin_panel_settings_rounded;
      case 'MANAGER':
        return Icons.manage_accounts_rounded;
      default:
        return Icons.badge_rounded;
    }
  }

  // ─── Add / Edit Dialog ─────────────────────────────────────────────────────

  void _showUserDialog({UserDetail? editUser}) {
    final isEdit = editUser != null;
    final formKey = GlobalKey<FormState>();

    final usernameCtrl = TextEditingController(text: editUser?.username ?? '');
    final emailCtrl = TextEditingController(text: editUser?.email ?? '');
    final fullNameCtrl = TextEditingController(text: editUser?.fullName ?? '');
    final passwordCtrl = TextEditingController();
    String selectedRole = editUser?.role.toUpperCase() ?? 'OPERATOR';
    bool obscurePassword = true;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.cobalt.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isEdit ? Icons.edit_outlined : Icons.person_add_outlined,
                  color: AppTheme.cobalt,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(isEdit ? 'تعديل بيانات المستخدم' : 'إضافة مستخدم جديد'),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Full Name ──────────────────────────────────────────────
                  TextFormField(
                    controller: fullNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'الاسم الكامل *',
                      prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                      hintText: 'مثال: أحمد محمد سرور',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'الاسم الكامل مطلوب' : null,
                  ),
                  const SizedBox(height: 14),

                  // ── Username (disable on edit) ─────────────────────────────
                  TextFormField(
                    controller: usernameCtrl,
                    enabled: !isEdit,
                    decoration: InputDecoration(
                      labelText: 'اسم المستخدم *',
                      prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
                      hintText: 'مثال: ahmed_sorour',
                      helperText: isEdit ? 'لا يمكن تعديل اسم المستخدم' : null,
                      filled: isEdit,
                      fillColor: isEdit ? Colors.grey.shade100 : null,
                    ),
                    validator: (v) {
                      if (isEdit) return null;
                      if (v == null || v.trim().isEmpty) return 'اسم المستخدم مطلوب';
                      if (v.trim().length < 3) return 'اسم المستخدم 3 أحرف على الأقل';
                      if (v.contains(' ')) return 'اسم المستخدم لا يحتوي على مسافات';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // ── Email ──────────────────────────────────────────────────
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني *',
                      prefixIcon: Icon(Icons.email_outlined, size: 20),
                      hintText: 'مثال: ahmed@company.com',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'البريد الإلكتروني مطلوب';
                      if (!v.contains('@') || !v.contains('.')) return 'بريد إلكتروني غير صالح';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // ── Role Dropdown ──────────────────────────────────────────
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'الدور والصلاحيات *',
                      prefixIcon: Icon(Icons.shield_outlined, size: 20),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'ADMIN',
                        child: Row(children: [
                          Icon(Icons.admin_panel_settings_rounded, size: 16, color: AppTheme.crimson),
                          SizedBox(width: 8),
                          Text('ADMIN — مدير النظام (صلاحيات كاملة)'),
                        ]),
                      ),
                      DropdownMenuItem(
                        value: 'MANAGER',
                        child: Row(children: [
                          Icon(Icons.manage_accounts_rounded, size: 16, color: AppTheme.cobalt),
                          SizedBox(width: 8),
                          Text('MANAGER — مدير العمليات'),
                        ]),
                      ),
                      DropdownMenuItem(
                        value: 'OPERATOR',
                        child: Row(children: [
                          Icon(Icons.badge_rounded, size: 16, color: AppTheme.emerald),
                          SizedBox(width: 8),
                          Text('OPERATOR — أخصائي استيراد'),
                        ]),
                      ),
                    ],
                    onChanged: (v) => setLocal(() => selectedRole = v ?? 'OPERATOR'),
                    validator: (v) => v == null ? 'اختر دوراً' : null,
                  ),
                  const SizedBox(height: 14),

                  // ── Password ───────────────────────────────────────────────
                  TextFormField(
                    controller: passwordCtrl,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: isEdit ? 'كلمة مرور جديدة (اتركها فارغة لعدم التغيير)' : 'كلمة المرور *',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 18,
                        ),
                        onPressed: () => setLocal(() => obscurePassword = !obscurePassword),
                      ),
                    ),
                    validator: (v) {
                      if (!isEdit && (v == null || v.trim().isEmpty)) return 'كلمة المرور مطلوبة';
                      if (v != null && v.isNotEmpty && v.length < 6) return 'كلمة المرور 6 أحرف على الأقل';
                      return null;
                    },
                  ),

                  // ── Role Description Card ──────────────────────────────────
                  const SizedBox(height: 16),
                  _RoleDescriptionCard(role: selectedRole),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton.icon(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setLocal(() => isSaving = true);

                      // Capture messenger before async gap
                      final messenger = ScaffoldMessenger.of(context);

                      String? error;
                      if (isEdit) {
                        error = await ref.read(usersProvider.notifier).updateUser(
                              userId: editUser.userId,
                              fullName: fullNameCtrl.text.trim(),
                              email: emailCtrl.text.trim(),
                              role: selectedRole,
                              password: passwordCtrl.text.isEmpty ? null : passwordCtrl.text,
                            );
                      } else {
                        error = await ref.read(usersProvider.notifier).createUser(
                              username: usernameCtrl.text.trim(),
                              email: emailCtrl.text.trim(),
                              fullName: fullNameCtrl.text.trim(),
                              role: selectedRole,
                              password: passwordCtrl.text,
                            );
                      }

                      setLocal(() => isSaving = false);

                      if (!ctx.mounted) return;
                      if (error != null) {
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                          content: Row(children: [
                            const Icon(Icons.error_outline, color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(child: Text(error)),
                          ]),
                          backgroundColor: AppTheme.crimson,
                          behavior: SnackBarBehavior.floating,
                        ));
                      } else {
                        Navigator.pop(ctx);
                        messenger.showSnackBar(SnackBar(
                          content: Row(children: [
                            const Icon(Icons.check_circle_outline, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(isEdit ? 'تم تعديل بيانات المستخدم بنجاح' : 'تم إنشاء المستخدم بنجاح'),
                          ]),
                          backgroundColor: AppTheme.emerald,
                          behavior: SnackBarBehavior.floating,
                        ));
                      }
                    },
              icon: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(isEdit ? Icons.save_outlined : Icons.person_add_outlined, size: 18),
              label: Text(isEdit ? 'حفظ التعديلات' : 'إنشاء المستخدم'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isEdit ? AppTheme.cobalt : AppTheme.emerald,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Toggle Status Confirm Dialog ──────────────────────────────────────────

  void _showToggleConfirmDialog(UserDetail user) {
    final isActivating = !user.isActive;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isActivating ? Icons.check_circle_outline : Icons.block_outlined,
              color: isActivating ? AppTheme.emerald : AppTheme.crimson,
            ),
            const SizedBox(width: 10),
            Text(isActivating ? 'تفعيل المستخدم' : 'تعطيل المستخدم'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isActivating
                  ? 'هل تريد تفعيل حساب المستخدم التالي؟'
                  : 'هل تريد تعطيل حساب المستخدم التالي؟\nلن يتمكن من تسجيل الدخول بعد التعطيل.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _roleColor(user.role).withOpacity(0.15),
                    radius: 18,
                    child: Icon(_roleIcon(user.role), color: _roleColor(user.role), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('@${user.username}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final error = await ref.read(usersProvider.notifier).toggleUserStatus(user.userId);
              if (!mounted) return;
              if (error != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(error),
                  backgroundColor: AppTheme.crimson,
                  behavior: SnackBarBehavior.floating,
                ));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(isActivating ? 'تم تفعيل المستخدم بنجاح' : 'تم تعطيل المستخدم بنجاح'),
                  backgroundColor: isActivating ? AppTheme.emerald : AppTheme.orange,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isActivating ? AppTheme.emerald : AppTheme.crimson,
            ),
            child: Text(isActivating ? 'تفعيل' : 'تعطيل'),
          ),
        ],
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final usersState = ref.watch(usersProvider);
    final currentUser = ref.watch(authProvider).user;
    final isAdmin = currentUser?.isAdmin ?? false;

    // Filter users
    final filtered = usersState.users.where((u) {
      final matchRole = _filterRole == 'ALL' || u.role.toUpperCase() == _filterRole;
      final matchSearch = _searchQuery.isEmpty ||
          u.fullName.toLowerCase().contains(_searchQuery) ||
          u.username.toLowerCase().contains(_searchQuery) ||
          u.email.toLowerCase().contains(_searchQuery);
      return matchRole && matchSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.cloudWhite,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          _buildHeader(isAdmin, usersState),

          // ── Filters & Stats Row ──────────────────────────────────────────
          _buildFiltersRow(usersState),

          // ── Table Area ──────────────────────────────────────────────────
          Expanded(
            child: usersState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : usersState.error != null
                    ? _buildErrorState(usersState.error!)
                    : filtered.isEmpty
                        ? _buildEmptyState()
                        : _buildUsersTable(filtered, isAdmin, currentUser?.userId ?? -1),
          ),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isAdmin, UsersState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.cobalt.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.manage_accounts_rounded, color: AppTheme.cobalt, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'إدارة المستخدمين والصلاحيات',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
              ),
              Text(
                'User Access Control (RBAC) — ${state.users.length} مستخدم مسجل',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const Spacer(),
          // Refresh
          IconButton(
            onPressed: () => ref.read(usersProvider.notifier).fetchUsers(),
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.cobalt),
            tooltip: 'تحديث القائمة',
          ),
          const SizedBox(width: 8),
          // Add User (ADMIN only)
          if (isAdmin)
            ElevatedButton.icon(
              onPressed: () => _showUserDialog(),
              icon: const Icon(Icons.person_add_outlined, size: 18),
              label: const Text('مستخدم جديد'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.cobalt,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.orange.withOpacity(0.10),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.orange.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.visibility_outlined, size: 14, color: AppTheme.orange),
                  SizedBox(width: 6),
                  Text(
                    'عرض فقط — صلاحية ADMIN مطلوبة للتعديل',
                    style: TextStyle(fontSize: 11, color: AppTheme.orange, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Stats & Filters ──────────────────────────────────────────────────────

  Widget _buildFiltersRow(UsersState state) {
    final admins = state.users.where((u) => u.role.toUpperCase() == 'ADMIN').length;
    final managers = state.users.where((u) => u.role.toUpperCase() == 'MANAGER').length;
    final operators = state.users.where((u) => u.role.toUpperCase() == 'OPERATOR').length;
    final active = state.users.where((u) => u.isActive).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Colors.white,
      child: Column(
        children: [
          // Stats chips
          Row(
            children: [
              _StatChip(label: 'الكل', count: state.users.length, color: AppTheme.charcoal),
              const SizedBox(width: 8),
              _StatChip(label: 'نشط', count: active, color: AppTheme.emerald, icon: Icons.check_circle_outline),
              const SizedBox(width: 8),
              _StatChip(label: 'Admin', count: admins, color: AppTheme.crimson),
              const SizedBox(width: 8),
              _StatChip(label: 'Manager', count: managers, color: AppTheme.cobalt),
              const SizedBox(width: 8),
              _StatChip(label: 'Operator', count: operators, color: AppTheme.emerald),
              const Spacer(),
              // Search
              SizedBox(
                width: 260,
                height: 36,
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'بحث بالاسم أو اسم المستخدم أو البريد...',
                    hintStyle: const TextStyle(fontSize: 12),
                    prefixIcon: const Icon(Icons.search, size: 16),
                    contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Role filter tabs
          Row(
            children: [
              _FilterTab(label: 'الكل', value: 'ALL', selected: _filterRole == 'ALL',
                  onTap: () => setState(() => _filterRole = 'ALL')),
              const SizedBox(width: 6),
              _FilterTab(label: 'ADMIN', value: 'ADMIN', selected: _filterRole == 'ADMIN',
                  color: AppTheme.crimson, onTap: () => setState(() => _filterRole = 'ADMIN')),
              const SizedBox(width: 6),
              _FilterTab(label: 'MANAGER', value: 'MANAGER', selected: _filterRole == 'MANAGER',
                  color: AppTheme.cobalt, onTap: () => setState(() => _filterRole = 'MANAGER')),
              const SizedBox(width: 6),
              _FilterTab(label: 'OPERATOR', value: 'OPERATOR', selected: _filterRole == 'OPERATOR',
                  color: AppTheme.emerald, onTap: () => setState(() => _filterRole = 'OPERATOR')),
            ],
          ),
        ],
      ),
    );
  }

  // ── Users Table ──────────────────────────────────────────────────────────

  Widget _buildUsersTable(List<UserDetail> users, bool isAdmin, int currentUserId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.charcoal.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Row(
              children: [
                SizedBox(width: 40),
                Expanded(flex: 3, child: _TableHeader('الاسم الكامل')),
                Expanded(flex: 2, child: _TableHeader('اسم المستخدم')),
                Expanded(flex: 3, child: _TableHeader('البريد الإلكتروني')),
                Expanded(flex: 2, child: _TableHeader('الدور')),
                SizedBox(width: 80, child: _TableHeader('الحالة')),
                SizedBox(width: 110, child: _TableHeader('تاريخ الإنشاء')),
                SizedBox(width: 100, child: _TableHeader('الإجراءات')),
              ],
            ),
          ),
          // Rows
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: users.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, i) => _buildUserRow(users[i], isAdmin, currentUserId),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRow(UserDetail user, bool isAdmin, int currentUserId) {
    final isSelf = user.userId == currentUserId;
    final createdDate = _formatDate(user.createdAt);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: !user.isActive ? Colors.grey.shade50 : null,
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: _roleColor(user.role).withOpacity(0.15),
            child: Icon(_roleIcon(user.role), color: _roleColor(user.role), size: 16),
          ),
          const SizedBox(width: 8),
          // Full Name
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: user.isActive ? AppTheme.charcoal : Colors.grey,
                  ),
                ),
                if (isSelf)
                  const Text(
                    '(أنت)',
                    style: TextStyle(fontSize: 10, color: AppTheme.cobalt, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
          // Username
          Expanded(
            flex: 2,
            child: Text(
              '@${user.username}',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: user.isActive ? Colors.grey.shade700 : Colors.grey.shade400,
              ),
            ),
          ),
          // Email
          Expanded(
            flex: 3,
            child: Text(
              user.email,
              style: TextStyle(
                fontSize: 12,
                color: user.isActive ? Colors.grey.shade700 : Colors.grey.shade400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Role Badge
          Expanded(
            flex: 2,
            child: _RoleBadge(role: user.role),
          ),
          // Status
          SizedBox(
            width: 80,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: user.isActive
                    ? AppTheme.emerald.withOpacity(0.10)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: user.isActive
                      ? AppTheme.emerald.withOpacity(0.4)
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    user.isActive ? Icons.circle : Icons.circle_outlined,
                    size: 7,
                    color: user.isActive ? AppTheme.emerald : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    user.isActive ? 'نشط' : 'معطّل',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: user.isActive ? AppTheme.emerald : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Created At
          SizedBox(
            width: 110,
            child: Text(
              createdDate,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ),
          // Actions (ADMIN only)
          SizedBox(
            width: 100,
            child: isAdmin
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Edit
                      Tooltip(
                        message: 'تعديل البيانات',
                        child: InkWell(
                          onTap: () => _showUserDialog(editUser: user),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            child: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.cobalt),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Toggle Status (can't deactivate self)
                      if (!isSelf)
                        Tooltip(
                          message: user.isActive ? 'تعطيل الحساب' : 'تفعيل الحساب',
                          child: InkWell(
                            onTap: () => _showToggleConfirmDialog(user),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                user.isActive ? Icons.block_outlined : Icons.check_circle_outline,
                                size: 16,
                                color: user.isActive ? AppTheme.crimson : AppTheme.emerald,
                              ),
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 28),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ── Empty / Error States ──────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_outlined, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('لا توجد نتائج', style: TextStyle(fontSize: 15, color: Colors.grey.shade500)),
          const SizedBox(height: 6),
          Text('جرّب تغيير الفلتر أو مسح البحث', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppTheme.crimson),
          const SizedBox(height: 12),
          Text(error, style: const TextStyle(color: AppTheme.crimson), textAlign: TextAlign.center),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () => ref.read(usersProvider.notifier).fetchUsers(),
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '—';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return isoDate.substring(0, 10);
    }
  }
}

// ─── Sub-Widgets ──────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AppTheme.charcoal,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  Color get _color {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return AppTheme.crimson;
      case 'MANAGER':
        return AppTheme.cobalt;
      default:
        return AppTheme.emerald;
    }
  }

  IconData get _icon {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return Icons.admin_panel_settings_rounded;
      case 'MANAGER':
        return Icons.manage_accounts_rounded;
      default:
        return Icons.badge_rounded;
    }
  }

  String get _label {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return 'Admin';
      case 'MANAGER':
        return 'Manager';
      default:
        return 'Operator';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 12, color: _color),
          const SizedBox(width: 4),
          Text(_label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _color)),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData? icon;

  const _StatChip({required this.label, required this.count, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppTheme.charcoal;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? activeColor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? activeColor.withOpacity(0.5) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? activeColor : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}

class _RoleDescriptionCard extends StatelessWidget {
  final String role;
  const _RoleDescriptionCard({required this.role});

  @override
  Widget build(BuildContext context) {
    final info = _getRoleInfo(role);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: info.color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: info.color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(info.icon, size: 14, color: info.color),
              const SizedBox(width: 6),
              Text(
                info.title,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: info.color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...info.permissions.map(
            (p) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 11, color: info.color),
                  const SizedBox(width: 5),
                  Text(p, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _RoleInfo _getRoleInfo(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return const _RoleInfo(
          title: 'مدير النظام — صلاحيات كاملة',
          icon: Icons.admin_panel_settings_rounded,
          color: AppTheme.crimson,
          permissions: [
            'إدارة المستخدمين وصلاحياتهم',
            'الوصول لجميع شاشات النظام',
            'تعديل البيانات المرجعية (Master Data)',
            'مزامنة قواعد البيانات (Production Sync)',
            'عرض جميع سجلات التدقيق (Audit Logs)',
          ],
        );
      case 'MANAGER':
        return const _RoleInfo(
          title: 'مدير العمليات — صلاحيات متقدمة',
          icon: Icons.manage_accounts_rounded,
          color: AppTheme.cobalt,
          permissions: [
            'الوصول لجميع ملفات الاستيراد والشحنات',
            'اعتماد القرارات التشغيلية',
            'عرض جميع التقارير والتحليلات',
            'إدارة البيانات المرجعية (قراءة)',
            'لا يستطيع إدارة المستخدمين',
          ],
        );
      default:
        return const _RoleInfo(
          title: 'أخصائي استيراد — صلاحيات تشغيلية',
          icon: Icons.badge_rounded,
          color: AppTheme.emerald,
          permissions: [
            'إنشاء وتعديل ملفات الاستيراد',
            'إدخال بيانات الشحنات والمستندات',
            'متابعة مراحل التخليص الجمركي',
            'عرض التقارير المخصصة له',
            'لا يستطيع تعديل البيانات المرجعية أو إدارة المستخدمين',
          ],
        );
    }
  }
}

class _RoleInfo {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> permissions;

  const _RoleInfo({
    required this.title,
    required this.icon,
    required this.color,
    required this.permissions,
  });
}
