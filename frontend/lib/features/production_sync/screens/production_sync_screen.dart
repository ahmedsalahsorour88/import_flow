import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';
import '../models/production_sync_model.dart';
import '../providers/production_sync_provider.dart';

class ProductionSyncScreen extends ConsumerStatefulWidget {
  const ProductionSyncScreen({super.key});

  @override
  ConsumerState<ProductionSyncScreen> createState() => _ProductionSyncScreenState();
}

class _ProductionSyncScreenState extends ConsumerState<ProductionSyncScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

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
    final l = context.l10n;
    final compAsync = ref.watch(syncComparisonProvider);
    final syncState = ref.watch(productionSyncNotifierProvider);
    final isLoading = syncState.isLoading;

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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.prodSyncScreenTitle,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  l.prodSyncScreenSubtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: l.refreshDataTooltip,
            onPressed: () {
              ref.invalidate(syncComparisonProvider);
              ref.invalidate(backupsListProvider);
            },
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
          tabs: [
            Tab(icon: const Icon(Icons.compare_arrows_rounded, size: 18), text: l.prodSyncTabCompareTables),
            Tab(icon: const Icon(Icons.backup_rounded, size: 18), text: l.prodSyncTabSafetyBackups),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          compAsync.when(
            data: (comp) => _buildComparisonView(context, l, comp, isLoading),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, st) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppTheme.crimson, size: 48),
                  const SizedBox(height: 10),
                  Text(l.prodSyncErrorFetchingComparison(err), style: const TextStyle(color: AppTheme.crimson)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: Text(l.retry),
                    onPressed: () => ref.invalidate(syncComparisonProvider),
                  ),
                ],
              ),
            ),
          ),
          _buildBackupsView(context, l),
        ],
      ),
    );
  }

  Widget _buildComparisonView(BuildContext context, AppLocalizations l, SyncComparisonResponseModel comp, bool isLoading) {
    final filtered = comp.tables.where((t) {
      if (_searchQuery.isEmpty) return true;
      return t.tableName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildCard(
                  l.prodSyncDevDbTitle,
                  l.prodSyncDevDbSubtitle,
                  Icons.code_rounded,
                  AppTheme.cobalt,
                  comp.devStats,
                  l,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCard(
                  l.prodSyncProdDbTitle,
                  l.prodSyncProdDbSubtitle,
                  Icons.desktop_windows_rounded,
                  AppTheme.emerald,
                  comp.prodStats,
                  l,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: comp.isFullySynchronized ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: comp.isFullySynchronized ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  comp.isFullySynchronized ? Icons.check_circle_rounded : Icons.sync_problem_rounded,
                  color: comp.isFullySynchronized ? AppTheme.emerald : AppTheme.orange,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comp.isFullySynchronized
                            ? l.prodSyncFullySynchronizedTitle(comp.matchedTablesCount)
                            : l.prodSyncDifferencesDetectedTitle(comp.differingTablesCount),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: comp.isFullySynchronized ? AppTheme.emerald : AppTheme.charcoal,
                        ),
                      ),
                      Text(
                        comp.isFullySynchronized
                            ? l.prodSyncFullySynchronizedSub
                            : l.prodSyncDifferencesDetectedSub,
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  icon: isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.bolt_rounded, size: 18),
                  label: Text(l.prodSyncSyncNowBtn, style: const TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: isLoading ? null : () => _handleSync(context, l),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.cobalt,
                    side: const BorderSide(color: AppTheme.cobalt),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: Text(l.prodSyncPullFromProdBtn),
                  onPressed: isLoading ? null : () => _handlePull(context, l),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l.prodSyncTablesMatchHeader(filtered.length, comp.totalTables),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal),
              ),
              SizedBox(
                width: 280,
                height: 38,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: l.prodSyncSearchTablesHint,
                    prefixIcon: const Icon(Icons.search, size: 18),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (ctx, i) => Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (ctx, idx) {
                final item = filtered[idx];
                return Container(
                  color: item.isMatch ? Colors.transparent : Colors.amber.shade50.withOpacity(0.4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        item.isMatch ? Icons.check_circle_outline : Icons.change_circle_outlined,
                        size: 18,
                        color: item.isMatch ? AppTheme.emerald : AppTheme.orange,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Text(
                          item.tableName,
                          style: TextStyle(
                            fontWeight: item.isMatch ? FontWeight.normal : FontWeight.bold,
                            fontSize: 12.5,
                            fontFamily: 'monospace',
                            color: item.isMatch ? AppTheme.charcoal : AppTheme.cobalt,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(l.prodSyncDevRecordsCount(item.devCount), style: const TextStyle(fontSize: 12)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(l.prodSyncProdRecordsCount(item.prodCount), style: const TextStyle(fontSize: 12)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: item.isMatch ? AppTheme.emerald.withOpacity(0.12) : AppTheme.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.isMatch ? l.prodSyncTableStatusUpdated : item.status,
                          style: TextStyle(
                            fontSize: 11,
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
        ],
      ),
    );
  }

  Widget _buildCard(String title, String subtitle, IconData icon, Color color, DatabaseStatsModel stats, AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.charcoal)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(l.prodSyncDbSize(stats.sizeKb), style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 14),
                    Text(l.prodSyncDbTablesCount(stats.tablesCount), style: const TextStyle(fontSize: 11.5)),
                    const SizedBox(width: 14),
                    Text(l.prodSyncDbRecordsCount(stats.totalRecords), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupsView(BuildContext context, AppLocalizations l) {
    final backupsAsync = ref.watch(backupsListProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.prodSyncBackupsSectionHeader,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal),
                    ),
                    Text(
                      l.prodSyncBackupsSectionSub,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, foregroundColor: Colors.white),
                icon: const Icon(Icons.add_to_photos_rounded, size: 18),
                label: Text(l.prodSyncCreateSnapshotBtn),
                onPressed: () async {
                  try {
                    final backup = await ref.read(productionSyncNotifierProvider.notifier).createManualBackup();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l.prodSyncBackupCreatedSuccess(backup.filename)), backgroundColor: AppTheme.emerald),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l.prodSyncSyncError(e)), backgroundColor: AppTheme.crimson),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          backupsAsync.when(
            data: (backups) {
              if (backups.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.folder_zip_outlined, size: 54, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(l.prodSyncNoBackupsFound, style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: backups.length,
                  separatorBuilder: (ctx, i) => Divider(height: 1, color: Colors.grey.shade200),
                  itemBuilder: (ctx, idx) {
                    final b = backups[idx];
                    return ListTile(
                      leading: const Icon(Icons.inventory_2_outlined, color: AppTheme.cobalt),
                      title: Text(b.filename, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace')),
                      subtitle: Text('${l.prodSyncBackupCreatedAt(b.createdAt)} | ${l.prodSyncBackupSize(b.sizeKb)} | ${l.prodSyncBackupTag(b.tag)}', style: const TextStyle(fontSize: 11.5)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                        child: Text('${b.sizeKb} KB', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, st) => Center(child: Text(l.prodSyncErrorFetchingComparison(err), style: const TextStyle(color: AppTheme.crimson))),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSync(BuildContext context, AppLocalizations l) async {
    try {
      final res = await ref.read(productionSyncNotifierProvider.notifier).syncDevToProd();
      if (context.mounted && res != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message), backgroundColor: AppTheme.emerald, duration: const Duration(seconds: 4)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.prodSyncSyncError(e)), backgroundColor: AppTheme.crimson),
        );
      }
    }
  }

  Future<void> _handlePull(BuildContext context, AppLocalizations l) async {
    try {
      final res = await ref.read(productionSyncNotifierProvider.notifier).pullProdToDev();
      if (context.mounted && res != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message), backgroundColor: AppTheme.emerald, duration: const Duration(seconds: 4)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.prodSyncPullError(e)), backgroundColor: AppTheme.crimson),
        );
      }
    }
  }
}

