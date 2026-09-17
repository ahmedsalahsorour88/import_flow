import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/copyable_data_helper.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../models/file_closure_model.dart';

/// Modal dialog that allows searching and selecting a previous File Closure Certificate / Archival Record
/// to clone into a new draft following the 5-Task Enterprise Protocol.
class SearchAndCloneFileClosureDialog extends ConsumerStatefulWidget {
  final List<ImportFileClosureModel> records;
  final ValueChanged<ImportFileClosureModel> onSelectRecord;

  const SearchAndCloneFileClosureDialog({
    super.key,
    required this.records,
    required this.onSelectRecord,
  });

  @override
  ConsumerState<SearchAndCloneFileClosureDialog> createState() =>
      _SearchAndCloneFileClosureDialogState();
}

class _SearchAndCloneFileClosureDialogState
    extends ConsumerState<SearchAndCloneFileClosureDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogWidth = (screenWidth - 32).clamp(360.0, 920.0);
    final dialogHeight = (screenHeight * 0.82).clamp(420.0, 780.0);
    final allFiles = ref.watch(importFilesProvider).valueOrNull ?? [];
    final importFilesMap = {for (final f in allFiles) f.importFileId: f};

    final query = _searchController.text.trim().toLowerCase();
    final filteredRecords = widget.records.where((rec) {
      if (_statusFilter == 'Closed' && !rec.isFullyVerified) {
        return false;
      } else if (_statusFilter == 'Draft' && rec.isFullyVerified) {
        return false;
      }

      if (query.isEmpty) return true;

      final codeMatch = rec.closureCode.toLowerCase().contains(query);
      final auditorMatch = rec.auditorName.toLowerCase().contains(query);
      final vaultMatch = rec.archiveLocation.toLowerCase().contains(query);
      final notesMatch = (rec.archivalNotes ?? '').toLowerCase().contains(query);
      final matchingFile = importFilesMap[rec.importFileId];
      final fileCodeMatch = (matchingFile?.primaryNameWithCode ?? 'imp-${rec.importFileId}')
          .toLowerCase()
          .contains(query);
      final compMatch = (matchingFile?.companyName ?? '').toLowerCase().contains(query);

      return codeMatch || auditorMatch || vaultMatch || notesMatch || fileCodeMatch || compMatch;
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dialog Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.emerald.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.archive_outlined, color: AppTheme.emerald, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.cloneFileClosureDialogTitle,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.charcoal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l.cloneFileClosureDialogSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: l.cancel,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Bar & Filter Chips
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: l.fileClosureSearchHint,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _searchController,
                        builder: (context, val, _) => val.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : const SizedBox.shrink(),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Filter Chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildFilterChip('All', l.isArabic ? 'الكل' : 'All', isDark),
                _buildFilterChip('Closed', l.isArabic ? 'مؤرشف نهائياً' : 'Closed', isDark),
                _buildFilterChip('Draft', l.isArabic ? 'مسودة قيد الاستيفاء' : 'Draft / Incomplete', isDark),
              ],
            ),
            const SizedBox(height: 14),

            // Records List
            Expanded(
              child: filteredRecords.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off, size: 44, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            l.fileClosureEmptyRecords,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: filteredRecords.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final rec = filteredRecords[index];
                        final matchingFile = importFilesMap[rec.importFileId];
                        final fileCode = matchingFile?.primaryNameWithCode ?? 'IMP-${rec.importFileId}';
                        final compName = matchingFile?.companyName ?? '';
                        final chk = rec.closureChecklist;
                        final verifiedCount = (chk.docsVerified ? 1 : 0) +
                            (chk.customsCleared ? 1 : 0) +
                            (chk.warehouseReceived ? 1 : 0) +
                            (chk.landedCostSettled ? 1 : 0) +
                            (chk.tasksClosed ? 1 : 0);

                        return Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
                            ),
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Row 1: Code, status, and Clone action
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.emerald.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppTheme.emerald),
                                    ),
                                    child: CopyableText(
                                      rec.closureCode,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: AppTheme.emerald,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: (rec.isFullyVerified ? AppTheme.emerald : AppTheme.orange).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      rec.isFullyVerified
                                          ? (l.isArabic ? 'مغلق ومؤرشف' : 'Archived (100%)')
                                          : (l.isArabic ? 'مسودة قيد الاستيفاء' : 'Draft / Incomplete'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        color: rec.isFullyVerified ? AppTheme.emerald : AppTheme.orange,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  ElevatedButton.icon(
                                    key: Key('selectClosureToCloneBtn_${rec.closureCode}'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.emerald,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: const Icon(Icons.difference_outlined, size: 16),
                                    label: Text(
                                      l.isArabic ? 'استنساخ لمسودة' : 'Clone to Draft',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      widget.onSelectRecord(rec);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Row 2: Import File & Vault Location
                              Row(
                                children: [
                                  const Icon(Icons.folder_open, size: 16, color: AppTheme.cobalt),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      compName.isNotEmpty ? '$fileCode ($compName)' : fileCode,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? const Color(0xFFF1F5F9) : AppTheme.charcoal,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.storage, size: 16, color: Colors.blueGrey),
                                  const SizedBox(width: 6),
                                  Text(
                                    rec.archiveLocation,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Row 3: Auditor & Verified Conditions
                              Row(
                                children: [
                                  Icon(Icons.person_pin, size: 15, color: Colors.grey.shade600),
                                  const SizedBox(width: 6),
                                  Text(
                                    rec.auditorName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade700,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    l.isArabic
                                        ? 'الشروط المستوفاة: $verifiedCount / 5'
                                        : 'Verified Conditions: $verifiedCount / 5',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: verifiedCount == 5 ? AppTheme.emerald : Colors.orange.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label, bool isDark) {
    final isSelected = _statusFilter == filterKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _statusFilter = filterKey);
        }
      },
      selectedColor: AppTheme.emerald.withOpacity(0.2),
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected
            ? AppTheme.emerald
            : (isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade800),
      ),
      side: BorderSide(
        color: isSelected
            ? AppTheme.emerald
            : (isDark ? const Color(0xFF334155) : Colors.grey.shade300),
      ),
    );
  }
}
