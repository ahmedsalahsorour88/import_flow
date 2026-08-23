import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../models/production_sync_model.dart';
import '../providers/production_sync_provider.dart';

class ProductionSyncHubDialog extends ConsumerStatefulWidget {
  const ProductionSyncHubDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const ProductionSyncHubDialog(),
    );
  }

  @override
  ConsumerState<ProductionSyncHubDialog> createState() => _ProductionSyncHubDialogState();
}

class _ProductionSyncHubDialogState extends ConsumerState<ProductionSyncHubDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _tableSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compAsync = ref.watch(syncComparisonProvider);
    final syncState = ref.watch(productionSyncNotifierProvider);
    final isLoading = syncState.isLoading;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 980,
        height: 700,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // ─── Header Bar ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: AppTheme.charcoal,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.cobalt,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مركز حماية ومزامنة الإنتاج (Production Sync & Backup Hub)',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'ترقية الـ Schema + إدارة النسخ الاحتياطية + الاستعادة — بدون أي مساس ببيانات التشغيل',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                    tooltip: 'إعادة فحص وتحديث البيانات',
                    onPressed: () {
                      ref.invalidate(syncComparisonProvider);
                      ref.invalidate(backupsListProvider);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ─── Tab Bar ──────────────────────────────────────────────────
            Container(
              color: Colors.grey.shade100,
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.cobalt,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: AppTheme.cobalt,
                tabs: const [
                  Tab(icon: Icon(Icons.upgrade_rounded, size: 18), text: 'ترقية الـ Schema (Schema Upgrade)'),
                  Tab(icon: Icon(Icons.backup_rounded, size: 18), text: 'النسخ الاحتياطية والاستعادة'),
                ],
              ),
            ),

            // ─── Tab Views ────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  compAsync.when(
                    data: (comp) => _buildUpgradeTab(context, comp, isLoading),
                    loading: () => const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('جاري فحص ومقارنة قواعد البيانات...', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                    error: (err, st) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppTheme.crimson, size: 48),
                            const SizedBox(height: 10),
                            Text('تعذر جلب بيانات المقارنة: $err',
                                style: const TextStyle(color: AppTheme.crimson)),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('إعادة المحاولة'),
                              onPressed: () => ref.invalidate(syncComparisonProvider),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildBackupsTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Tab 1: Schema Upgrade
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildUpgradeTab(BuildContext context, SyncComparisonResponseModel comp, bool isLoading) {
    final filteredTables = comp.tables.where((t) {
      if (_tableSearchQuery.isEmpty) return true;
      return t.tableName.toLowerCase().contains(_tableSearchQuery.toLowerCase());
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Safety Guarantee Banner ──────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF6EE7B7), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.emerald,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🔒 ضمان الحماية الكاملة لبيانات التشغيل',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF064E3B)),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'الترقية تضيف فقط الجداول والأعمدة الجديدة • لا تحذف أي سجل • لا تعدل بيانات الموردين أو الشركات أو POs أو ملفات الشحن • نسخة احتياطية تلقائية قبل البدء',
                        style: TextStyle(fontSize: 11, color: Color(0xFF065F46)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── DB Stats Row ──────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildDatabaseStatCard(
                  title: 'قاعدة بيانات التطوير (Dev DB)',
                  subtitle: 'مصدر الميزات الجديدة والترقيات',
                  icon: Icons.code_rounded,
                  color: AppTheme.cobalt,
                  stats: comp.devStats,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDatabaseStatCard(
                  title: 'قاعدة بيانات الإنتاج (Prod DB)',
                  subtitle: 'الهدف — بياناتها محمية 100%',
                  icon: Icons.desktop_windows_rounded,
                  color: AppTheme.emerald,
                  stats: comp.prodStats,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Status + Action Banner ────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: comp.isFullySynchronized ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: comp.isFullySynchronized ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  comp.isFullySynchronized ? Icons.check_circle_rounded : Icons.upgrade_rounded,
                  color: comp.isFullySynchronized ? AppTheme.emerald : AppTheme.orange,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comp.isFullySynchronized
                            ? '✅ الإنتاج محدث بآخر الميزات (${comp.matchedTablesCount} جدول متطابق)'
                            : '⬆️ يوجد ميزات جديدة جاهزة للترقية (${comp.differingTablesCount} جدول)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: comp.isFullySynchronized ? AppTheme.emerald : AppTheme.charcoal,
                        ),
                      ),
                      Text(
                        comp.isFullySynchronized
                            ? 'البرودكشن يعمل بآخر إصدار من الـ Schema والميزات.'
                            : 'اضغط "ترقية البرودكشن" لإضافة الميزات الجديدة فقط — بياناتك محمية تماماً.',
                        style: const TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  icon: isLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.upgrade_rounded, size: 16),
                  label: const Text(
                    'ترقية البرودكشن (Schema Upgrade)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: isLoading ? null : () => _confirmAndSyncToProd(context),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.cobalt,
                    side: const BorderSide(color: AppTheme.cobalt),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('سحب من البرودكشن (Pull)', style: TextStyle(fontSize: 11.5)),
                  onPressed: isLoading ? null : () => _handlePullToDev(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Tables List Header ────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'تفاصيل الجداول (${filteredTables.length} / ${comp.totalTables}) — الجداول ذات الفروق ستتلقى الأعمدة الجديدة فقط',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal),
              ),
              SizedBox(
                width: 240,
                height: 34,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'بحث في الجداول...',
                    hintStyle: const TextStyle(fontSize: 11.5),
                    prefixIcon: const Icon(Icons.search, size: 16),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  onChanged: (val) => setState(() => _tableSearchQuery = val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Tables Comparison List ────────────────────────────────────
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ListView.separated(
                  itemCount: filteredTables.length,
                  separatorBuilder: (ctx, i) => Divider(height: 1, color: Colors.grey.shade200),
                  itemBuilder: (ctx, idx) {
                    final item = filteredTables[idx];
                    return Container(
                      color: item.isMatch ? Colors.transparent : Colors.amber.shade50.withOpacity(0.4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            item.isMatch ? Icons.check_circle_outline : Icons.upgrade_rounded,
                            size: 16,
                            color: item.isMatch ? AppTheme.emerald : AppTheme.cobalt,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 3,
                            child: Text(
                              item.tableName,
                              style: TextStyle(
                                fontWeight: item.isMatch ? FontWeight.normal : FontWeight.bold,
                                fontSize: 12,
                                fontFamily: 'monospace',
                                color: item.isMatch ? AppTheme.charcoal : AppTheme.cobalt,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('التطوير: ${item.devCount} سجل',
                                style: const TextStyle(fontSize: 11.5, color: Colors.black87)),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('الإنتاج: ${item.prodCount} سجل',
                                style: const TextStyle(fontSize: 11.5, color: Colors.black87)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: item.isMatch
                                  ? AppTheme.emerald.withOpacity(0.12)
                                  : AppTheme.cobalt.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.isMatch ? 'محدث ✓' : item.status,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: item.isMatch ? AppTheme.emerald : AppTheme.cobalt,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Tab 2: Backups & Restore
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildBackupsTab(BuildContext context) {
    final backupsAsync = ref.watch(backupsListProvider);
    final isLoading = ref.watch(productionSyncNotifierProvider).isLoading;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'النسخ الاحتياطية المحفوظة (Safety Snapshots)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                  ),
                  Text(
                    'يمكنك استعادة أي نسخة — يتم حفظ نسخة أمان من الوضع الحالي قبل الاستعادة',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cobalt,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add_to_photos_rounded, size: 16),
                label: const Text('نسخة احتياطية الآن (Dev)', style: TextStyle(fontSize: 11.5)),
                onPressed: isLoading
                    ? null
                    : () async {
                        try {
                          final backup = await ref
                              .read(productionSyncNotifierProvider.notifier)
                              .createManualBackup(target: 'dev');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('✅ تم إنشاء النسخة الاحتياطية: ${backup.filename}'),
                              backgroundColor: AppTheme.emerald,
                            ));
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('❌ خطأ: $e'),
                              backgroundColor: AppTheme.crimson,
                            ));
                          }
                        }
                      },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: backupsAsync.when(
              data: (backups) {
                if (backups.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_zip_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 10),
                        const Text('لا توجد نسخ احتياطية محفوظة بعد', style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 6),
                        const Text(
                          'يتم أخذ نسخة احتياطية تلقائياً قبل كل ترقية وعند إغلاق النظام',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ListView.separated(
                      itemCount: backups.length,
                      separatorBuilder: (ctx, i) => Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (ctx, idx) {
                        final b = backups[idx];
                        final tagColor = b.tag.contains('prod')
                            ? AppTheme.emerald
                            : b.tag.contains('dev')
                                ? AppTheme.cobalt
                                : AppTheme.orange;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.inventory_2_outlined, color: AppTheme.cobalt, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      b.filename,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11.5,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    Text(
                                      '${b.createdAt}  •  ${b.sizeKb} KB',
                                      style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: tagColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  b.tag,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: tagColor,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.orange,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                                icon: const Icon(Icons.restore_rounded, size: 15),
                                label: const Text('استعادة → Prod', style: TextStyle(fontSize: 11)),
                                onPressed: isLoading ? null : () => _confirmAndRestore(context, b, 'prod'),
                              ),
                              const SizedBox(width: 4),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.cobalt,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                                icon: const Icon(Icons.restore_page_rounded, size: 15),
                                label: const Text('استعادة → Dev', style: TextStyle(fontSize: 11)),
                                onPressed: isLoading ? null : () => _confirmAndRestore(context, b, 'dev'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) =>
                  Center(child: Text('خطأ: $err', style: const TextStyle(color: AppTheme.crimson))),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DB Stat Card
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildDatabaseStatCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required DatabaseStatsModel stats,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.charcoal)),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('الحجم: ${stats.sizeKb} KB',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    Text('الجداول: ${stats.tablesCount}',
                        style: const TextStyle(fontSize: 11, color: Colors.black87)),
                    const SizedBox(width: 10),
                    Text('السجلات: ${stats.totalRecords}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Confirm dialogs & handlers
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _confirmAndSyncToProd(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.upgrade_rounded, color: AppTheme.emerald, size: 22),
            SizedBox(width: 8),
            Text('تأكيد ترقية الإنتاج', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF6EE7B7)),
              ),
              child: const Text(
                '✅ ما سيحدث:\n'
                '• نسخة احتياطية أمان تلقائية قبل البدء\n'
                '• إضافة الجداول الجديدة (إن وجدت)\n'
                '• إضافة الأعمدة الجديدة لكل جدول موجود\n'
                '• دمج بيانات المرجعية الجديدة (INSERT OR IGNORE)',
                style: TextStyle(fontSize: 12, color: Color(0xFF065F46), height: 1.7),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF93C5FD)),
              ),
              child: const Text(
                '🔒 ما لن يحدث أبداً:\n'
                '• لن يُمسّ أي مورد أو شركة أو PO أو ملف شحن\n'
                '• لن يُحذف أي سجل موجود في الإنتاج\n'
                '• لن يُعدَّل أي بيان تشغيلي مُدخل يدوياً',
                style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF), height: 1.7),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emerald,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.upgrade_rounded, size: 16),
            label: const Text('تأكيد الترقية', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await _handleSyncToProd(context);
    }
  }

  Future<void> _confirmAndRestore(BuildContext context, BackupItemModel backup, String target) async {
    final targetLabel = target == 'prod' ? 'الإنتاج (Prod)' : 'التطوير (Dev)';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.restore_rounded, color: AppTheme.orange, size: 22),
            SizedBox(width: 8),
            Text('تأكيد الاستعادة', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('سيتم استعادة النسخة التالية إلى قاعدة بيانات $targetLabel:',
                style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(backup.filename,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'monospace')),
                  Text('التاريخ: ${backup.createdAt}  •  ${backup.sizeKb} KB',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: const Text(
                '⚠️ سيتم حفظ نسخة أمان من الوضع الحالي قبل الاستعادة، ثم استبدال قاعدة البيانات بالنسخة المختارة.',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF92400E)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.orange,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.restore_rounded, size: 16),
            label: const Text('تأكيد الاستعادة', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await _handleRestore(context, backup.filename, target);
    }
  }

  Future<void> _handleSyncToProd(BuildContext context) async {
    try {
      final res = await ref.read(productionSyncNotifierProvider.notifier).syncDevToProd();
      if (context.mounted && res != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ ${res.message}'),
          backgroundColor: AppTheme.emerald,
          duration: const Duration(seconds: 5),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ فشلت الترقية: $e'), backgroundColor: AppTheme.crimson),
        );
      }
    }
  }

  Future<void> _handlePullToDev(BuildContext context) async {
    try {
      final res = await ref.read(productionSyncNotifierProvider.notifier).pullProdToDev();
      if (context.mounted && res != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ ${res.message}'),
          backgroundColor: AppTheme.emerald,
          duration: const Duration(seconds: 4),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ فشل السحب: $e'), backgroundColor: AppTheme.crimson),
        );
      }
    }
  }

  Future<void> _handleRestore(BuildContext context, String filename, String target) async {
    try {
      final res = await ref
          .read(productionSyncNotifierProvider.notifier)
          .restoreBackup(filename: filename, target: target);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ ${res.message}'),
          backgroundColor: AppTheme.emerald,
          duration: const Duration(seconds: 5),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ فشلت الاستعادة: $e'), backgroundColor: AppTheme.crimson),
        );
      }
    }
  }
}
