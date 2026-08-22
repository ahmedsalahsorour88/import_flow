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

class _ProductionSyncHubDialogState extends ConsumerState<ProductionSyncHubDialog> with SingleTickerProviderStateMixin {
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
        width: 960,
        height: 680,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Header Bar
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
                    child: const Icon(Icons.sync_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مركز مزامنة وتحديث الإنتاج (Production Sync Hub)',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'إدارة وسحب ومزامنة قواعد البيانات والنسخ الاحتياطية بنقرة واحدة داخل البرودكشن',
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

            // Tab Bar
            Container(
              color: Colors.grey.shade100,
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.cobalt,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: AppTheme.cobalt,
                tabs: const [
                  Tab(icon: Icon(Icons.compare_arrows_rounded, size: 18), text: 'مقارنة ومزامنة الجداول (Database Sync)'),
                  Tab(icon: Icon(Icons.backup_rounded, size: 18), text: 'سجل النسخ الاحتياطية (Safety Backups)'),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Comparison & Sync Actions
                  compAsync.when(
                    data: (comp) => _buildComparisonTab(context, comp, isLoading),
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
                            Text('تعذر جلب بيانات المقارنة: $err', style: const TextStyle(color: AppTheme.crimson)),
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

                  // Tab 2: Backups
                  _buildBackupsTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonTab(BuildContext context, SyncComparisonResponseModel comp, bool isLoading) {
    final filteredTables = comp.tables.where((t) {
      if (_tableSearchQuery.isEmpty) return true;
      return t.tableName.toLowerCase().contains(_tableSearchQuery.toLowerCase());
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Summary Row (Dev vs Prod Stats + Action Buttons)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dev DB Card
              Expanded(
                child: _buildDatabaseStatCard(
                  title: 'قاعدة بيانات التطوير (Dev DB)',
                  subtitle: 'بيئة العمل والتطوير الحالية',
                  icon: Icons.code_rounded,
                  color: AppTheme.cobalt,
                  stats: comp.devStats,
                ),
              ),
              const SizedBox(width: 12),
              // Prod DB Card
              Expanded(
                child: _buildDatabaseStatCard(
                  title: 'قاعدة بيانات الإنتاج (Prod DB)',
                  subtitle: 'حزمة Standalone المجهزة للعميل',
                  icon: Icons.desktop_windows_rounded,
                  color: AppTheme.emerald,
                  stats: comp.prodStats,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action Toolbar Banner
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
                  comp.isFullySynchronized ? Icons.check_circle_rounded : Icons.sync_problem_rounded,
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
                            ? '✅ قواعد البيانات متطابقة بنسبة 100% (${comp.matchedTablesCount} جدول متطابق)'
                            : '⚡ توجد تحديثات جديدة (${comp.differingTablesCount} جدول به فروق سجلات)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: comp.isFullySynchronized ? AppTheme.emerald : AppTheme.charcoal,
                        ),
                      ),
                      Text(
                        comp.isFullySynchronized
                            ? 'البرودكشن محدث بآخر البيانات وموانئ الشحن والشركات وأوامر الشراء.'
                            : 'اضغط على "مزامنة وتحديث البرودكشن الآن" لنقل كافة التعديلات فوراً مع أخذ نسخة احتياطية.',
                        style: const TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Action Buttons
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  icon: isLoading
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.bolt_rounded, size: 16),
                  label: const Text('مزامنة البرودكشن الآن (Sync Dev -> Prod)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: isLoading ? null : () => _handleSyncToProd(context),
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

          // Search Bar & Stats Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'تفاصيل الجداول والسجلات (${filteredTables.length} / ${comp.totalTables})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
              ),
              SizedBox(
                width: 250,
                height: 34,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'بحث في الجداول...',
                    hintStyle: const TextStyle(fontSize: 11.5),
                    prefixIcon: const Icon(Icons.search, size: 16),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                  onChanged: (val) => setState(() => _tableSearchQuery = val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Comparison Data Table
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
                            item.isMatch ? Icons.check_circle_outline : Icons.change_circle_outlined,
                            size: 16,
                            color: item.isMatch ? AppTheme.emerald : AppTheme.orange,
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
                            child: Text(
                              'التطوير: ${item.devCount} سجل',
                              style: const TextStyle(fontSize: 11.5, color: Colors.black87),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'الإنتاج: ${item.prodCount} سجل',
                              style: const TextStyle(fontSize: 11.5, color: Colors.black87),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: item.isMatch ? AppTheme.emerald.withOpacity(0.12) : AppTheme.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.status,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: item.isMatch ? AppTheme.emerald : AppTheme.orange,
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
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.charcoal)),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('الحجم: ${stats.sizeKb} KB', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    Text('الجداول: ${stats.tablesCount}', style: const TextStyle(fontSize: 11, color: Colors.black87)),
                    const SizedBox(width: 10),
                    Text('السجلات: ${stats.totalRecords}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupsTab(BuildContext context) {
    final backupsAsync = ref.watch(backupsListProvider);

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
                    'النسخ الاحتياطية المحفوظة (Safety Database Snapshots)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                  ),
                  Text(
                    'يتم أخذ نسخة احتياطية مشفرة ومؤرخة تلقائياً قبل كل عملية مزامنة لحماية البيانات',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, foregroundColor: Colors.white),
                icon: const Icon(Icons.add_to_photos_rounded, size: 16),
                label: const Text('أخذ نسخة احتياطية الآن (Create Snapshot)', style: TextStyle(fontSize: 11.5)),
                onPressed: () async {
                  try {
                    final backup = await ref.read(productionSyncNotifierProvider.notifier).createManualBackup();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تم إنشاء النسخة الاحتياطية بنجاح: ${backup.filename}'),
                          backgroundColor: AppTheme.emerald,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('خطأ أثناء إنشاء النسخة: $e'), backgroundColor: AppTheme.crimson),
                      );
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
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: backups.length,
                  separatorBuilder: (ctx, i) => Divider(height: 1, color: Colors.grey.shade200),
                  itemBuilder: (ctx, idx) {
                    final b = backups[idx];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.inventory_2_outlined, color: AppTheme.cobalt),
                      title: Text(b.filename, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'monospace')),
                      subtitle: Text('تاريخ الإنشاء: ${b.createdAt} | الحجم: ${b.sizeKb} KB | النوع: ${b.tag}', style: const TextStyle(fontSize: 11)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                        child: Text('${b.sizeKb} KB', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text('خطأ: $err', style: const TextStyle(color: AppTheme.crimson))),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSyncToProd(BuildContext context) async {
    try {
      final res = await ref.read(productionSyncNotifierProvider.notifier).syncDevToProd();
      if (context.mounted && res != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message),
            backgroundColor: AppTheme.emerald,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل المزامنة: $e'), backgroundColor: AppTheme.crimson),
        );
      }
    }
  }

  Future<void> _handlePullToDev(BuildContext context) async {
    try {
      final res = await ref.read(productionSyncNotifierProvider.notifier).pullProdToDev();
      if (context.mounted && res != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message),
            backgroundColor: AppTheme.emerald,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل السحب: $e'), backgroundColor: AppTheme.crimson),
        );
      }
    }
  }
}
