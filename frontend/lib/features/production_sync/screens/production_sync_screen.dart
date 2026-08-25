import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';
import '../services/local_process_sync_service.dart';
import '../widgets/sync_console_widget.dart';

class ProductionSyncScreen extends ConsumerStatefulWidget {
  const ProductionSyncScreen({super.key});

  @override
  ConsumerState<ProductionSyncScreen> createState() => _ProductionSyncScreenState();
}

class _ProductionSyncScreenState extends ConsumerState<ProductionSyncScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LocalProcessSyncService _service = LocalProcessSyncService();

  final List<ConsoleLogLine> _consoleLogs = [];
  bool _isRunning = false;
  String _currentAction = '';

  late LocalDbStats _devStats;
  late LocalDbStats _prodStats;
  late List<LocalBackupEntry> _backups;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refreshLocalData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshLocalData() {
    setState(() {
      _devStats = _service.getDbStats(_service.devDbPath);
      _prodStats = _service.getDbStats(_service.prodDbPath);
      _backups = _service.listBackups();
    });
  }

  void _appendLog(String text, {bool isError = false}) {
    if (mounted) {
      setState(() {
        _consoleLogs.add(ConsoleLogLine(text, isError: isError));
      });
    }
  }

  Future<void> _executeAction(String actionName, Future<int> Function() task) async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _currentAction = actionName;
      _consoleLogs.add(ConsoleLogLine('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'));
      _consoleLogs.add(ConsoleLogLine('🚀 بدء عملية: $actionName'));
    });

    try {
      final code = await task();
      _refreshLocalData();
      if (mounted) {
        if (code == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ اكتملت عملية [$actionName] بنجاح!'),
              backgroundColor: AppTheme.emerald,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ انتهت عملية [$actionName] مع أخطاء. راجع السجل.'),
              backgroundColor: AppTheme.crimson,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      _appendLog('❌ استثناء غير متوقع: $e', isError: true);
      _refreshLocalData();
    } finally {
      if (mounted) {
        setState(() {
          _isRunning = false;
          _currentAction = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppTheme.charcoal,
        elevation: 1,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.cobalt,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.sync_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مركز مزامنة ونقل تحديثات الإنتاج (Production Sync Hub)',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'إدارة ونقل التعديلات وبناء حزم الإنتاج المباشرة بدون وسيط',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'تحديث حالة الملفات',
            onPressed: _refreshLocalData,
          ),
          const SizedBox(width: 8),
          const BackToDashboardButton(),
          const SizedBox(width: 12),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppTheme.cobalt,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.flash_on_rounded, size: 18), text: 'عمليات المزامنة والتشغيل المباشر'),
            Tab(icon: Icon(Icons.history_rounded, size: 18), text: 'أرشيف النسخ الاحتياطية'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // DB Status Cards
            Row(
              children: [
                Expanded(
                  child: _buildDbCard(
                    title: 'قاعدة بيانات التطوير (Dev DB)',
                    path: _service.devDbPath,
                    stats: _devStats,
                    color: AppTheme.cobalt,
                    icon: Icons.code_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDbCard(
                    title: 'قاعدة بيانات الإنتاج (Prod DB)',
                    path: _service.prodDbPath,
                    stats: _prodStats,
                    color: AppTheme.emerald,
                    icon: Icons.desktop_windows_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOperationsTab(),
                  _buildBackupsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationsTab() {
    return Column(
      children: [
        // Action Buttons Row
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              // 1. Sync Dev -> Prod
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emerald,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                icon: _isRunning && _currentAction.contains('Dev → Prod')
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.cloud_upload_rounded, size: 18),
                label: const Text(
                  '⚡ مزامنة لقاعدة الإنتاج (Dev → Prod)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
                onPressed: _isRunning
                    ? null
                    : () => _executeAction(
                          'مزامنة لقاعدة الإنتاج (Dev → Prod)',
                          () => _service.syncDevToProd(
                            onOutput: (l) => _appendLog(l),
                            onError: (l) => _appendLog(l, isError: true),
                          ),
                        ),
              ),

              // 2. Compare DBs
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cobalt,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                icon: _isRunning && _currentAction.contains('مقارنة')
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.compare_arrows_rounded, size: 18),
                label: const Text(
                  '🔍 فحص ومقارنة الجداول (Compare)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
                onPressed: _isRunning
                    ? null
                    : () => _executeAction(
                          'فحص ومقارنة الجداول',
                          () => _service.compareDatabases(
                            onOutput: (l) => _appendLog(l),
                            onError: (l) => _appendLog(l, isError: true),
                          ),
                        ),
              ),

              // 3. Pull Prod -> Dev
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.charcoal,
                  side: const BorderSide(color: AppTheme.charcoal),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                icon: _isRunning && _currentAction.contains('سحب')
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.charcoal))
                    : const Icon(Icons.download_rounded, size: 18),
                label: const Text(
                  '⬇ سحب الإنتاج للتطوير (Prod → Dev)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                onPressed: _isRunning
                    ? null
                    : () => _executeAction(
                          'سحب بيانات الإنتاج إلى بيئة التطوير (Prod → Dev)',
                          () => _service.pullProdToDev(
                            onOutput: (l) => _appendLog(l),
                            onError: (l) => _appendLog(l, isError: true),
                          ),
                        ),
              ),

              // 4. Full Production Package
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                icon: _isRunning && _currentAction.contains('بناء كامل')
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.inventory_rounded, size: 18),
                label: const Text(
                  '📦 بناء وحزم الإنتاج بالكامل (Full Build)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                onPressed: _isRunning
                    ? null
                    : () => _executeAction(
                          'بناء وتجميع الإنتاج بالكامل (Full Build & Package)',
                          () => _service.fullBuildAndSync(
                            onOutput: (l) => _appendLog(l),
                            onError: (l) => _appendLog(l, isError: true),
                          ),
                        ),
              ),

              // 5. Launch Standalone App
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1), // Indigo
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                icon: const Icon(Icons.play_circle_filled_rounded, size: 18),
                label: const Text(
                  '🚀 إطلاق تطبيق البرودكشن الآن',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                onPressed: _isRunning
                    ? null
                    : () => _executeAction(
                          'إطلاق تطبيق البرودكشن',
                          () => _service.launchProductionApp(
                            onOutput: (l) => _appendLog(l),
                            onError: (l) => _appendLog(l, isError: true),
                          ),
                        ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Live Console Output
        Expanded(
          child: SyncConsoleWidget(
            logs: _consoleLogs,
            isRunning: _isRunning,
            onClear: () => setState(() => _consoleLogs.clear()),
          ),
        ),
      ],
    );
  }

  Widget _buildBackupsTab() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'أرشيف النسخ الاحتياطية (${_backups.length} نسخة محفوظة)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.charcoal),
                  ),
                  const Text(
                    'يتم إنشاء نسخة أمان تلقائية قبل كل عملية مزامنة لضمان عدم فقدان أي بيانات نهائياً',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, foregroundColor: Colors.white),
                icon: const Icon(Icons.add_to_photos_rounded, size: 16),
                label: const Text('📸 لقطة فورية لقاعدة البيانات', style: TextStyle(fontSize: 11.5)),
                onPressed: _isRunning
                    ? null
                    : () => _executeAction(
                          'إنشاء نسخة أمان فورية',
                          () => _service.createManualBackup(
                            onOutput: (l) => _appendLog(l),
                            onError: (l) => _appendLog(l, isError: true),
                          ),
                        ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _backups.isEmpty
                ? const Center(
                    child: Text('لا توجد نسخ احتياطية سابقة في مجلد backups/.'),
                  )
                : ListView.separated(
                    itemCount: _backups.length,
                    separatorBuilder: (ctx, i) => Divider(height: 1, color: Colors.grey.shade200),
                    itemBuilder: (ctx, idx) {
                      final b = _backups[idx];
                      final tagColor = b.tag.contains('prod')
                          ? AppTheme.emerald
                          : b.tag.contains('dev')
                              ? AppTheme.cobalt
                              : AppTheme.orange;

                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.inventory_2_outlined, color: AppTheme.cobalt, size: 20),
                        title: Text(
                          b.filename,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'monospace'),
                        ),
                        subtitle: Text(
                          'تاريخ الإنشاء: ${b.mtime}  •  الحجم: ${b.sizeKb} KB',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: tagColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            b.tag,
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: tagColor),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDbCard({
    required String title,
    required String path,
    required LocalDbStats stats,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                const SizedBox(height: 2),
                Text(
                  stats.exists
                      ? 'الحجم: ${stats.sizeKb} KB  •  آخر تعديل: ${stats.mtime ?? "—"}'
                      : '⚠️ لم يتم العثور على الملف بعد (سيتم إنشاؤه عند أول مزامنة)',
                  style: TextStyle(
                    fontSize: 11,
                    color: stats.exists ? Colors.black87 : AppTheme.crimson,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
