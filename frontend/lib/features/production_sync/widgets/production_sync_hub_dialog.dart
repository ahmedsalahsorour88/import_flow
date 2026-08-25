import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
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
    final l = context.l10n;
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.prodSyncHubDialogTitle,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        l.prodSyncHubDialogSubtitle,
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                    tooltip: l.refreshDataTooltip,
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
                tabs: [
                  Tab(icon: const Icon(Icons.upgrade_rounded, size: 18), text: l.prodSyncTabSchemaUpgrade),
                  Tab(icon: const Icon(Icons.backup_rounded, size: 18), text: l.prodSyncTabSafetyBackups),
                ],
              ),
            ),

            // ─── Tab Views ────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  compAsync.when(
                    data: (comp) => _buildUpgradeTab(context, l, comp, isLoading),
                    loading: () => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 12),
                          Text(l.prodSyncComparingDatabasesProgress, style: const TextStyle(color: Colors.grey)),
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
                            Text(l.prodSyncErrorFetchingComparison(err),
                                style: const TextStyle(color: AppTheme.crimson)),
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
                  ),
                  _buildBackupsTab(context, l),
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

  Widget _buildUpgradeTab(BuildContext context, AppLocalizations l, SyncComparisonResponseModel comp, bool isLoading) {
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.prodSyncSafetyGuaranteeTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF064E3B)),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l.prodSyncSafetyGuaranteeBody,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF065F46)),
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
                  title: l.prodSyncDevDbTitle,
                  subtitle: l.prodSyncDevDbUpgradeSub,
                  icon: Icons.code_rounded,
                  color: AppTheme.cobalt,
                  stats: comp.devStats,
                  l: l,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDatabaseStatCard(
                  title: l.prodSyncProdDbTitle,
                  subtitle: l.prodSyncProdDbUpgradeSub,
                  icon: Icons.desktop_windows_rounded,
                  color: AppTheme.emerald,
                  stats: comp.prodStats,
                  l: l,
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
                            ? l.prodSyncFullySynchronizedTitle(comp.matchedTablesCount)
                            : l.prodSyncUpgradeReadyTitle(comp.differingTablesCount),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: comp.isFullySynchronized ? AppTheme.emerald : AppTheme.charcoal,
                        ),
                      ),
                      if (!comp.isFullySynchronized) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (comp.differingTablesCount > 0)
                              _buildSummaryBadge(
                                '${comp.differingTablesCount} جداول بيانات مختلفة',
                                AppTheme.orange,
                                Icons.compare_arrows_rounded,
                              ),
                            if (comp.schemaDiffsCount > 0)
                              _buildSummaryBadge(
                                '${comp.schemaDiffsCount} جداول تحتاج ترقية Schema',
                                AppTheme.cobalt,
                                Icons.schema_rounded,
                              ),
                          ],
                        ),
                      ] else
                        Text(
                          l.prodSyncFullySynchronizedSub,
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
                  label: Text(
                    l.prodSyncUpgradeBtn,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: isLoading ? null : () => _confirmAndSyncToProd(context, l),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.cobalt,
                    side: const BorderSide(color: AppTheme.cobalt),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: Text(l.prodSyncPullFromProdBtn, style: const TextStyle(fontSize: 11.5)),
                  onPressed: isLoading ? null : () => _handlePullToDev(context, l),
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
                l.prodSyncTablesUpgradeHeader(filteredTables.length, comp.totalTables),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal),
              ),
              SizedBox(
                width: 240,
                height: 34,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: l.prodSyncSearchTablesHint,
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

                    // Determine row highlight color
                    Color rowBg = Colors.transparent;
                    if (item.isNewTable) {
                      rowBg = const Color(0xFFF3E8FF).withOpacity(0.5); // purple tint
                    } else if (item.hasSchemaDiff) {
                      rowBg = const Color(0xFFEFF6FF).withOpacity(0.5); // blue tint
                    } else if (!item.isMatch) {
                      rowBg = Colors.amber.shade50.withOpacity(0.4);    // amber tint
                    }

                    return Container(
                      color: rowBg,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // ── Status icon ─────────────────────────────────
                              Icon(
                                item.isNewTable
                                    ? Icons.add_circle_outline_rounded
                                    : item.hasSchemaDiff
                                        ? Icons.schema_rounded
                                        : item.isMatch
                                            ? Icons.check_circle_outline
                                            : Icons.compare_arrows_rounded,
                                size: 16,
                                color: item.isNewTable
                                    ? const Color(0xFF7C3AED)
                                    : item.hasSchemaDiff
                                        ? AppTheme.cobalt
                                        : item.isMatch
                                            ? AppTheme.emerald
                                            : AppTheme.orange,
                              ),
                              const SizedBox(width: 10),
                              // ── Table name ──────────────────────────────────
                              Expanded(
                                flex: 3,
                                child: Text(
                                  item.tableName,
                                  style: TextStyle(
                                    fontWeight: item.isMatch ? FontWeight.normal : FontWeight.bold,
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    color: item.isNewTable
                                        ? const Color(0xFF7C3AED)
                                        : item.hasSchemaDiff
                                            ? AppTheme.cobalt
                                            : item.isMatch
                                                ? AppTheme.charcoal
                                                : AppTheme.orange,
                                  ),
                                ),
                              ),
                              // ── Dev count ───────────────────────────────────
                              Expanded(
                                flex: 2,
                                child: Text(l.prodSyncDevRecordsCount(item.devCount),
                                    style: const TextStyle(fontSize: 11.5, color: Colors.black87)),
                              ),
                              // ── Prod count ──────────────────────────────────
                              Expanded(
                                flex: 2,
                                child: Text(
                                  item.isNewTable
                                      ? '— غير موجود'
                                      : l.prodSyncProdRecordsCount(item.prodCount),
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: item.isNewTable ? Colors.grey : Colors.black87,
                                    fontStyle: item.isNewTable ? FontStyle.italic : FontStyle.normal,
                                  ),
                                ),
                              ),
                              // ── Status badge ────────────────────────────────
                              _buildTableStatusBadge(item),
                            ],
                          ),
                          // ── New columns list (if schema diff) ────────────────
                          if (item.hasSchemaDiff && !item.isNewTable && item.newColumns.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 26, top: 4),
                              child: Wrap(
                                spacing: 4,
                                runSpacing: 2,
                                children: [
                                  const Icon(Icons.add_box_outlined, size: 12, color: AppTheme.cobalt),
                                  const SizedBox(width: 2),
                                  ...item.newColumns.take(5).map((col) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: AppTheme.cobalt.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(3),
                                          border: Border.all(color: AppTheme.cobalt.withOpacity(0.25)),
                                        ),
                                        child: Text(
                                          col,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontFamily: 'monospace',
                                            color: AppTheme.cobalt,
                                          ),
                                        ),
                                      )),
                                  if (item.newColumns.length > 5)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        '+${item.newColumns.length - 5} more',
                                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                    ),
                                ],
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

  Widget _buildBackupsTab(BuildContext context, AppLocalizations l) {
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.prodSyncBackupsSectionHeader,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                    ),
                    Text(
                      l.prodSyncBackupsDialogSub,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cobalt,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add_to_photos_rounded, size: 16),
                label: Text(l.prodSyncCreateDevSnapshotBtn, style: const TextStyle(fontSize: 11.5)),
                onPressed: isLoading
                    ? null
                    : () async {
                        try {
                          final backup = await ref
                              .read(productionSyncNotifierProvider.notifier)
                              .createManualBackup(target: 'dev');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(l.prodSyncBackupCreatedSuccess(backup.filename)),
                              backgroundColor: AppTheme.emerald,
                            ));
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(l.prodSyncSyncError(e)),
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
                        Text(l.prodSyncNoBackupsFound, style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 6),
                        Text(
                          l.prodSyncNoBackupsDialogSub,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
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
                                      '${l.prodSyncBackupCreatedAt(b.createdAt)}  •  ${l.prodSyncBackupSize(b.sizeKb)}',
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
                                label: Text(l.prodSyncRestoreToProdBtn, style: const TextStyle(fontSize: 11)),
                                onPressed: isLoading ? null : () => _confirmAndRestore(context, l, b, 'prod'),
                              ),
                              const SizedBox(width: 4),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.cobalt,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                                icon: const Icon(Icons.restore_page_rounded, size: 15),
                                label: Text(l.prodSyncRestoreToDevBtn, style: const TextStyle(fontSize: 11)),
                                onPressed: isLoading ? null : () => _confirmAndRestore(context, l, b, 'dev'),
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
                  Center(child: Text(l.prodSyncErrorFetchingComparison(err), style: const TextStyle(color: AppTheme.crimson))),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Helper: Status badge for each table row
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildTableStatusBadge(TableComparisonItemModel item) {
    if (item.isNewTable) {
      return _buildBadgeChip('جدول جديد', const Color(0xFF7C3AED), const Color(0xFFF3E8FF));
    }
    if (item.hasSchemaDiff && item.isMatch) {
      return _buildBadgeChip('Schema Upgrade', AppTheme.cobalt, const Color(0xFFEFF6FF));
    }
    if (item.hasSchemaDiff && !item.isMatch) {
      return _buildBadgeChip('بيانات + Schema', AppTheme.orange, const Color(0xFFFFFBEB));
    }
    if (!item.isMatch) {
      return _buildBadgeChip(
        item.diff > 0 ? '+${item.diff} سجل' : '${item.diff} سجل',
        AppTheme.orange,
        Colors.amber.shade50,
      );
    }
    return _buildBadgeChip('✓ متطابق', AppTheme.emerald, const Color(0xFFF0FDF4));
  }

  Widget _buildBadgeChip(String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildSummaryBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color),
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
    required AppLocalizations l,
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
                    Text(l.prodSyncDbSize(stats.sizeKb),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    Text(l.prodSyncDbTablesCount(stats.tablesCount),
                        style: const TextStyle(fontSize: 11, color: Colors.black87)),
                    const SizedBox(width: 10),
                    Text(l.prodSyncDbRecordsCount(stats.totalRecords),
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

  Future<void> _confirmAndSyncToProd(BuildContext context, AppLocalizations l) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.upgrade_rounded, color: AppTheme.emerald, size: 22),
            const SizedBox(width: 8),
            Text(l.prodSyncConfirmUpgradeTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
              child: Text(
                l.prodSyncConfirmUpgradeWhatHappens,
                style: const TextStyle(fontSize: 12, color: Color(0xFF065F46), height: 1.7),
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
              child: Text(
                l.prodSyncConfirmUpgradeWhatWontHappen,
                style: const TextStyle(fontSize: 12, color: Color(0xFF1E40AF), height: 1.7),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emerald,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.upgrade_rounded, size: 16),
            label: Text(l.prodSyncConfirmUpgradeSubmitBtn, style: const TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await _handleSyncToProd(context, l);
    }
  }

  Future<void> _confirmAndRestore(BuildContext context, AppLocalizations l, BackupItemModel backup, String target) async {
    final targetLabel = target == 'prod' ? l.prodSyncTargetProdLabel : l.prodSyncTargetDevLabel;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.restore_rounded, color: AppTheme.orange, size: 22),
            const SizedBox(width: 8),
            Text(l.prodSyncConfirmRestoreTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.prodSyncConfirmRestoreMsg(targetLabel),
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
                  Text('${l.prodSyncBackupCreatedAt(backup.createdAt)}  •  ${l.prodSyncBackupSize(backup.sizeKb)}',
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
              child: Text(
                l.prodSyncConfirmRestoreWarning,
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF92400E)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.orange,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.restore_rounded, size: 16),
            label: Text(l.prodSyncConfirmRestoreSubmitBtn, style: const TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await _handleRestore(context, l, backup.filename, target);
    }
  }

  Future<void> _handleSyncToProd(BuildContext context, AppLocalizations l) async {
    try {
      final res = await ref.read(productionSyncNotifierProvider.notifier).syncDevToProd();
      if (context.mounted && res != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res.message),
          backgroundColor: AppTheme.emerald,
          duration: const Duration(seconds: 5),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.prodSyncSyncError(e)), backgroundColor: AppTheme.crimson),
        );
      }
    }
  }

  Future<void> _handlePullToDev(BuildContext context, AppLocalizations l) async {
    try {
      final res = await ref.read(productionSyncNotifierProvider.notifier).pullProdToDev();
      if (context.mounted && res != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res.message),
          backgroundColor: AppTheme.emerald,
          duration: const Duration(seconds: 4),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.prodSyncPullError(e)), backgroundColor: AppTheme.crimson),
        );
      }
    }
  }

  Future<void> _handleRestore(BuildContext context, AppLocalizations l, String filename, String target) async {
    try {
      final res = await ref
          .read(productionSyncNotifierProvider.notifier)
          .restoreBackup(filename: filename, target: target);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res.message),
          backgroundColor: AppTheme.emerald,
          duration: const Duration(seconds: 5),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.prodSyncRestoreError(e)), backgroundColor: AppTheme.crimson),
        );
      }
    }
  }
}

