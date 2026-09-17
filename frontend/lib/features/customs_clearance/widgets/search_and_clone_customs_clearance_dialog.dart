import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../models/customs_clearance_model.dart';

/// Search and Clone Previous Customs Clearance Record Dialog (Screen 27 / SubTab 0)
///
/// Allows operators to quickly search past customs clearance records by clearance code,
/// Declaration 46 number, D/O number, customs office, or channel, and select one to clone
/// into a new editable draft.
class SearchAndCloneCustomsClearanceDialog extends StatefulWidget {
  final List<CustomsClearanceModel> records;
  final ValueChanged<CustomsClearanceModel> onSelectRecord;

  const SearchAndCloneCustomsClearanceDialog({
    super.key,
    required this.records,
    required this.onSelectRecord,
  });

  @override
  State<SearchAndCloneCustomsClearanceDialog> createState() =>
      _SearchAndCloneCustomsClearanceDialogState();
}

class _SearchAndCloneCustomsClearanceDialogState
    extends State<SearchAndCloneCustomsClearanceDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedChannel = 'All';
  String _selectedStatus = 'All';
  late List<CustomsClearanceModel> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.records.where((r) => r.isActive).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = widget.records.where((r) {
        if (!r.isActive) return false;

        final matchesChannel = _selectedChannel == 'All' ||
            r.channelType.toLowerCase().contains(_selectedChannel.toLowerCase());
        if (!matchesChannel) return false;

        final matchesStatus =
            _selectedStatus == 'All' || r.status == _selectedStatus;
        if (!matchesStatus) return false;

        if (q.isEmpty) return true;

        final code = r.clearanceCode.toLowerCase();
        final decl = (r.declaration46No ?? '').toLowerCase();
        final don = (r.deliveryOrderNumber ?? '').toLowerCase();
        final office = r.customsOfficeName.toLowerCase();
        final file = 'imp-${r.importFileId}';

        return code.contains(q) ||
            decl.contains(q) ||
            don.contains(q) ||
            office.contains(q) ||
            file.contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAr = l.isArabic;
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = (screenWidth - 32).clamp(360.0, 920.0);

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dialogWidth, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : AppTheme.cobalt.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.gavel_rounded,
                      color: AppTheme.cobalt,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.cloneCustomsClearanceDialogTitle,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFFF1F5F9) : AppTheme.charcoal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l.cloneCustomsClearanceDialogSubtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: l.close,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Search Field
              TextField(
                controller: _searchController,
                onChanged: (_) => _applyFilter(),
                decoration: InputDecoration(
                  hintText: isAr
                      ? 'ابحث برقم البيان، 46 ك.م، إذن التسليم، أو الجمرك...'
                      : 'Search by clearance code, Decl. 46, D/O no., or customs office...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _applyFilter();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),

              // 3. Filter Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Text(
                      isAr ? 'المسار: ' : 'Channel: ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade700,
                      ),
                    ),
                    ...['All', 'Red', 'Green', 'Yellow'].map((c) {
                      final isSelected = _selectedChannel == c;
                      String label = c == 'All' ? (isAr ? 'الكل' : 'All') : c;
                      if (c == 'Red') label = isAr ? 'أحمر' : 'Red';
                      if (c == 'Green') label = isAr ? 'أخضر' : 'Green';
                      if (c == 'Yellow') label = isAr ? 'أصفر' : 'Yellow';
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              _selectedChannel = c;
                              _applyFilter();
                            });
                          },
                        ),
                      );
                    }),
                    const SizedBox(width: 12),
                    Text(
                      isAr ? 'الحالة: ' : 'Status: ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade700,
                      ),
                    ),
                    ...['All', 'Inspection In Progress', 'Duty Requested', 'Duty Paid', 'Final Release Granted'].map((s) {
                      final isSelected = _selectedStatus == s;
                      String label = s;
                      if (s == 'All') label = l.customsClearanceFilterAll;
                      if (s == 'Inspection In Progress') label = l.customsClearanceFilterInspection;
                      if (s == 'Duty Requested') label = l.customsClearanceFilterDutyRequested;
                      if (s == 'Duty Paid') label = l.customsClearanceFilterDutyPaid;
                      if (s == 'Final Release Granted') label = l.customsClearanceFilterFinalRelease;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              _selectedStatus = s;
                              _applyFilter();
                            });
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 4. Records List
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: isDark ? const Color(0xFF64748B) : Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l.customsClearanceEmptyRecords,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final rec = _filtered[index];
                          final isGreen = rec.channelType.toLowerCase().contains('green');
                          final isRed = rec.channelType.toLowerCase().contains('red');
                          final dutyTotal = (rec.actualDutyTotal > 0 ? rec.actualDutyTotal : rec.totalDutyPayable).toStringAsFixed(2);

                          return Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Leading Icon
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isGreen
                                          ? AppTheme.emerald.withOpacity(0.12)
                                          : (isRed ? AppTheme.crimson.withOpacity(0.12) : AppTheme.orange.withOpacity(0.12)),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      isGreen
                                          ? Icons.check_circle_outline
                                          : (isRed ? Icons.flag_rounded : Icons.pending_actions_outlined),
                                      color: isGreen
                                          ? AppTheme.emerald
                                          : (isRed ? AppTheme.crimson : AppTheme.orange),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              rec.clearanceCode,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: isDark ? const Color(0xFFF1F5F9) : AppTheme.charcoal,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                rec.channelType,
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: isGreen
                                                      ? AppTheme.emerald
                                                      : (isRed ? AppTheme.crimson : AppTheme.orange),
                                                ),
                                              ),
                                            ),
                                            if (rec.declaration46No != null && rec.declaration46No!.isNotEmpty) ...[
                                              const SizedBox(width: 6),
                                              Text(
                                                '46: ${rec.declaration46No}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.cobalt,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${rec.customsOfficeName} | ${isAr ? "الرسوم" : "Duties"}: $dutyTotal EGP | ${rec.status}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Select & Clone Button
                                  ElevatedButton.icon(
                                    key: Key('selectRecordToCloneBtn_${rec.clearanceCode}'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.cobalt,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      widget.onSelectRecord(rec);
                                    },
                                    icon: const Icon(Icons.copy_rounded, size: 14),
                                    label: Text(
                                      isAr ? 'استنساخ' : 'Clone',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
