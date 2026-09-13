import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../models/customs_consultation_model.dart';
import '../providers/customs_consultation_provider.dart';
import 'consultation_metric_badge.dart';
import 'consultation_status_badges.dart';
import '../../../core/widgets/copyable_data_helper.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/row_actions_pill.dart';
import 'package:printing/printing.dart';
import '../../../core/services/display_name_resolver.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../services/customs_consultation_pdf_service.dart';
import '../services/customs_export_service.dart';
class SavedConsultationsTab extends ConsumerStatefulWidget {
  final Function(CustomsConsultationModel) onEdit;
  final Function(BuildContext, CustomsConsultationModel) onViewDetails;
  final bool isTaxReviewOnly;

  const SavedConsultationsTab({
    super.key,
    required this.onEdit,
    required this.onViewDetails,
    this.isTaxReviewOnly = false,
  });

  @override
  ConsumerState<SavedConsultationsTab> createState() => _SavedConsultationsTabState();
}

class _SavedConsultationsTabState extends ConsumerState<SavedConsultationsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'All';
  bool _showInactive = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final consultationsState = ref.watch(customsConsultationsProvider);
    final importFiles = ref.watch(importFilesProvider).valueOrNull ?? [];
    return // TAB 2: SAVED CONSULTATIONS HISTORY REGISTRY (Premium Design)
        consultationsState.when(
      loading: () => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.cobalt),
            const SizedBox(height: 16),
            Text(l.loading,
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
      error: (err, stack) => Center(child: Text('${l.error}: $err')),
      data: (allSessions) {
        final sessions = widget.isTaxReviewOnly
            ? allSessions.where((s) => s.estimatedDutiesEgp > 0).toList()
            : allSessions;

        final filtered = sessions.where((s) {
          final rawFileCode = s.importFileCode ?? (s.importFileId != null ? 'IMP-${s.importFileId}' : '');
          final shipmentTitle = rawFileCode.isNotEmpty
              ? DisplayNameResolver.resolveShipmentTitleByCode(rawFileCode, shipments: importFiles, isArabic: Localizations.localeOf(context).languageCode == 'ar')
              : '';
          final matchQuery = _searchQuery.isEmpty ||
              s.consultationCode
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              s.title
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              s.brokerName
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              rawFileCode
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              shipmentTitle
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase());
          final matchStatus =
              _statusFilter == 'All' || s.overallStatus == _statusFilter;
          return matchQuery && matchStatus;
        }).toList();

        // Aggregate metrics for header strip
        final totalCount = sessions.length;
        final readyCount = sessions
            .where((s) => s.overallStatus == 'Clearance Ready')
            .length;
        final blockedCount = sessions
            .where(
                (s) => s.overallStatus == 'Blocked' || s.hasBlockingIssues)
            .length;
        final avgReadiness = sessions.isEmpty
            ? 0.0
            : sessions.fold(
                    0.0, (s, c) => s + c.readinessPercentage) /
                sessions.length;

              return SelectionArea(
                child: Column(
                children: [
                  // ── Metrics & Toolbar Strip ──────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.charcoal.withOpacity(0.03),
                      border:
                          Border(bottom: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Left group: Metric Badges
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            ConsultationMetricBadge(
                                title: l.totalStudiesMetric, value: '$totalCount', color: AppTheme.charcoal),
                            ConsultationMetricBadge(
                                title: l.clearanceReadyStatus, value: '$readyCount', color: AppTheme.emerald),
                            ConsultationMetricBadge(
                                title: l.openBlockingIssues,
                                value: '$blockedCount',
                                color: blockedCount > 0
                                    ? AppTheme.crimson
                                    : Colors.grey),
                            ConsultationMetricBadge(
                                title: l.avgReadinessMetric,
                                value: '${avgReadiness.toStringAsFixed(0)}%',
                                color: AppTheme.cobalt),
                          ],
                        ),

                        // Right group: Search & Filter Controls
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Search field
                            SizedBox(
                              width: 220,
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: l.searchConsultationsHint,
                                  prefixIcon:
                                      const Icon(Icons.search, size: 18),
                                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                                    valueListenable: _searchController,
                                    builder: (context, val, _) {
                                      return val.text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.clear, size: 16),
                                              onPressed: () {
                                                _searchController.clear();
                                                setState(() => _searchQuery = '');
                                              },
                                            )
                                          : const SizedBox.shrink();
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  isDense: true,
                                ),
                                onChanged: (v) =>
                                    setState(() => _searchQuery = v),
                              ),
                            ),
                            // Status Filter
                            SizedBox(
                              width: 160,
                              child: SearchableDropdownField<String>(
                                value: _statusFilter,
                                labelText: l.statusFilterLabel,
                                items: [
                                  SearchableDropdownItem(
                                      value: 'All', label: l.allStatuses),
                                  SearchableDropdownItem(
                                      value: 'Pending Review',
                                      label: l.statusPendingReview),
                                  SearchableDropdownItem(
                                      value: 'In Progress',
                                      label: l.statusInProgress),
                                  SearchableDropdownItem(
                                      value: 'Action Required',
                                      label: l.statusActionRequired),
                                  SearchableDropdownItem(
                                      value: 'Clearance Ready',
                                      label: l.statusClearanceReady),
                                  SearchableDropdownItem(
                                      value: 'Blocked', label: l.statusBlocked),
                                ],
                                onChanged: (v) =>
                                    setState(() => _statusFilter = v!),
                              ),
                            ),
                            FilterChip(
                              avatar: Icon(_showInactive ? Icons.visibility_off : Icons.visibility, size: 16),
                              label: Text(_showInactive ? l.hideArchivedChip : l.showArchivedChip),
                              selected: _showInactive,
                              selectedColor: Colors.red.shade100,
                              onSelected: (val) {
                                setState(() => _showInactive = val);
                                ref.read(customsConsultationsProvider.notifier).fetchConsultations(includeInactive: val);
                              },
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.cobalt.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${filtered.length}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.cobalt),
                              ),
                            ),

                            // 1. TSV Export Button
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.charcoal,
                                side: BorderSide(color: Colors.grey.shade400),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              onPressed: () => CustomsExportService.exportConsultationsLogTsv(
                                context: context,
                                sessions: filtered,
                                shipments: importFiles,
                              ),
                              icon: const Icon(Icons.table_view_outlined, size: 15, color: Colors.blueGrey),
                              label: Text(l.customsTaxExportTsvBtn, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),

                            // 2. Excel Export Button
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.charcoal,
                                side: BorderSide(color: Colors.grey.shade400),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              onPressed: () => CustomsExportService.exportConsultationsLogExcel(
                                context: context,
                                sessions: filtered,
                                shipments: importFiles,
                              ),
                              icon: const Icon(Icons.description_outlined, size: 15, color: AppTheme.emerald),
                              label: Text(l.customsTaxExportExcelBtn, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),

                            // 3. PDF Statement Print/Preview Button
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.charcoal,
                                side: BorderSide(color: Colors.grey.shade400),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              onPressed: () => CustomsConsultationPdfService.printOrPreviewConsultationsLogPdf(context, filtered),
                              icon: const Icon(Icons.picture_as_pdf_outlined, size: 15, color: AppTheme.crimson),
                              label: Text(l.customsTaxPrintPdfBtn, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),

                            // 4. Dossier Copy Button
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.charcoal,
                                side: BorderSide(color: Colors.grey.shade400),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              onPressed: () => CustomsExportService.copyConsultationsLogDossier(
                                context: context,
                                sessions: filtered,
                                shipments: importFiles,
                              ),
                              icon: const Icon(Icons.copy_all_outlined, size: 15, color: AppTheme.cobalt),
                              label: Text(l.customsTaxCopyDossierBtn, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Data Table ──────────────────────────────────────────
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.folder_open_rounded,
                                    size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  l.noResultsFound,
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            padding:
                                const EdgeInsets.fromLTRB(16, 12, 16, 24),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side:
                                    BorderSide(color: Colors.grey.shade200),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowHeight: 48,
                                  dataRowMinHeight: 60,
                                  dataRowMaxHeight: 76,
                                  horizontalMargin: 16,
                                  columnSpacing: 20,
                                  dividerThickness: 0.5,
                                  headingRowColor: WidgetStateProperty.all(
                                      AppTheme.charcoal),
                                  headingTextStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 0.3,
                                  ),
                                  columns: [
                                    DataColumn(
                                      label: SizedBox(
                                        width: 168,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.bolt_rounded,
                                                size: 14, color: Colors.amber),
                                            const SizedBox(width: 4),
                                            Text(l.actionsCol,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    DataColumn(label: Text('📋 ${l.studyCodeCol}')),
                                    DataColumn(label: Text('📁 ${l.linkImportFile}')),
                                    DataColumn(label: Text('📝 ${l.titleField}')),
                                    DataColumn(
                                        label: Text('🧑‍💼 ${l.customsBrokerLabel}')),
                                    DataColumn(
                                        label: Text('💰 ${l.customsDutyCol}')),
                                    DataColumn(
                                        label: Text('📊 ${l.customsInspectionReadiness}')),
                                    DataColumn(label: Text('🔖 ${l.statusCol}')),
                                  ],

                                  rows: filtered.asMap().entries.map((entry) {
                                    final idx = entry.key;
                                    final session = entry.value;
                                    final isEven = idx.isEven;
                                    final rowColor = isEven
                                        ? Colors.white
                                        : Colors.grey.shade50;
                                    final readinessPct =
                                        session.readinessPercentage;
                                    final hasBlocking =
                                        session.hasBlockingIssues ||
                                            session.blockingIssuesCount > 0;
                                    final rawFileCode = session.importFileCode ?? (session.importFileId != null ? 'IMP-${session.importFileId}' : '—');
                                    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
                                    final egpLabel = isArabic ? 'ج.م' : 'EGP';
                                    final shipmentTitle = (rawFileCode != '—')
                                        ? DisplayNameResolver.resolveShipmentTitleByCode(rawFileCode, shipments: importFiles, isArabic: isArabic)
                                        : '—';
                                    final fileDisplay = (shipmentTitle != '—' && shipmentTitle != rawFileCode)
                                        ? '$shipmentTitle ($rawFileCode)'
                                        : shipmentTitle;
                                    final rowSummary =
                                        '${session.consultationCode} | $fileDisplay | ${session.title} | ${session.brokerName} | ${session.estimatedDutiesEgp.toStringAsFixed(0)} $egpLabel | ${readinessPct.toStringAsFixed(0)}% | ${session.overallStatus}';

                                    return DataRow(
                                      color:
                                          WidgetStateProperty.all(rowColor),
                                      onSelectChanged: (_) =>
                                          widget.onViewDetails(context, session),
                                      cells: [
                                        // ⚡ 1. Actions
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              RowActionsPill(
                                                onView: () =>
                                                    widget.onViewDetails(context, session),
                                                onEdit: () =>
                                                    widget.onEdit(
                                                        session),
                                                onPrint: () {
                                                  Printing.layoutPdf(
                                                    onLayout: (format) =>
                                                        CustomsConsultationPdfService.generateConsultationPdf(session),
                                                    name: 'Customs_Consultation_${session.consultationCode}',
                                                  );
                                                },
                                                onDelete: () async {
                                               final messenger = ScaffoldMessenger.of(context);
                                               if (session.isActive == false) {
                                                 final confirm = await showDialog<bool>(
                                                   context: context,
                                                   builder: (ctx) => AlertDialog(
                                                     title: Row(
                                                       children: [
                                                         const Icon(Icons.restore_from_trash_rounded, color: Colors.green, size: 22),
                                                         const SizedBox(width: 8),
                                                         Text(l.restoreConsultationTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                       ],
                                                     ),
                                                     content: Text(
                                                       l.restoreConsultationMsg(session.consultationCode, session.title),
                                                       style: const TextStyle(fontSize: 13),
                                                     ),
                                                     actions: [
                                                       TextButton(
                                                         onPressed: () => Navigator.pop(ctx, false),
                                                         child: Text(l.cancel),
                                                       ),
                                                       ElevatedButton.icon(
                                                         style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white),
                                                         icon: const Icon(Icons.restore_rounded, size: 16),
                                                         label: Text(l.restoreAndActivateBtn),
                                                         onPressed: () => Navigator.pop(ctx, true),
                                                       ),
                                                     ],
                                                   ),
                                                 );
                                                 if (confirm == true) {
                                                   try {
                                                     await ref.read(customsConsultationsProvider.notifier).restoreConsultation(session.consultationId);
                                                     if (mounted) {
                                                       messenger.showSnackBar(
                                                         SnackBar(
                                                           content: Text('♻️ ${l.restoreConsultationSuccess(session.consultationCode)}'),
                                                           backgroundColor: AppTheme.emerald,
                                                         ),
                                                       );
                                                     }
                                                   } catch (e) {
                                                     if (mounted) {
                                                       messenger.showSnackBar(
                                                         SnackBar(
                                                           content: Text('❌ $e'),
                                                           backgroundColor: AppTheme.crimson,
                                                         ),
                                                       );
                                                     }
                                                   }
                                                 }
                                               } else {
                                                 final confirm = await showDialog<bool>(
                                                   context: context,
                                                   builder: (ctx) => AlertDialog(
                                                     title: Row(
                                                       children: [
                                                         const Icon(Icons.warning_rounded, color: Colors.orange, size: 22),
                                                         const SizedBox(width: 8),
                                                         Text(l.deleteConsultationTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                       ],
                                                     ),
                                                     content: Text(
                                                       l.deleteConsultationMsg(session.consultationCode, session.title),
                                                       style: const TextStyle(fontSize: 13),
                                                     ),
                                                     actions: [
                                                       TextButton(
                                                         onPressed: () => Navigator.pop(ctx, false),
                                                         child: Text(l.cancel),
                                                       ),
                                                       ElevatedButton.icon(
                                                         style: ElevatedButton.styleFrom(
                                                           backgroundColor: AppTheme.crimson,
                                                           foregroundColor: Colors.white,
                                                         ),
                                                         icon: const Icon(Icons.delete_rounded, size: 16),
                                                         label: Text(l.deleteAndArchiveBtn),
                                                         onPressed: () => Navigator.pop(ctx, true),
                                                       ),
                                                     ],
                                                   ),
                                                 );
                                                 if (confirm == true) {
                                                   try {
                                                     await ref.read(customsConsultationsProvider.notifier).softDeleteConsultation(session.consultationId);
                                                     if (mounted) {
                                                       messenger.showSnackBar(
                                                         SnackBar(
                                                           content: Text('🗑️ ${l.deleteConsultationSuccess(session.consultationCode)}'),
                                                           backgroundColor: AppTheme.emerald,
                                                         ),
                                                       );
                                                     }
                                                   } catch (e) {
                                                     if (mounted) {
                                                       messenger.showSnackBar(
                                                         SnackBar(
                                                           content: Text('❌ $e'),
                                                           backgroundColor: AppTheme.crimson,
                                                         ),
                                                       );
                                                     }
                                                   }
                                                 }
                                               }
                                             },
                                             deleteTooltip: session.isActive == false ? l.restoreDeletedTooltip : l.deleteStudyTooltip,
                                              ),
                                              const SizedBox(width: 4),
                                              IconButton(
                                                icon: const Icon(Icons.copy, size: 16, color: AppTheme.cobalt),
                                                tooltip: l.copyTooltip,
                                                onPressed: () => CopyHelper.copy(context, rowSummary, customMessage: l.customsTaxCopyRowSuccess),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // 2. Consultation Code
                                        DataCell(
                                          CopyableTableCell(
                                            value: session.consultationCode,
                                            rowSummary: rowSummary,
                                            child: InkWell(
                                              onTap: () => widget.onViewDetails(context, session),
                                              borderRadius: BorderRadius.circular(6),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.cobalt.withOpacity(0.08),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: AppTheme.cobalt.withOpacity(0.25)),
                                                ),
                                                child: Text(
                                                  session.consultationCode,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt, fontSize: 12),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                        // 3. Import File
                                        DataCell(
                                          CopyableTableCell(
                                            value: fileDisplay,
                                            rowSummary: rowSummary,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  shipmentTitle,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                                ),
                                                if (rawFileCode != '—' && rawFileCode != shipmentTitle) ...[
                                                  const SizedBox(height: 2),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.cobalt.withOpacity(0.08),
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(color: AppTheme.cobalt.withOpacity(0.3)),
                                                    ),
                                                    child: Text(
                                                      rawFileCode,
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppTheme.cobalt,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),

                                        // 4. Title
                                        DataCell(
                                          CopyableTableCell(
                                            value: session.title,
                                            rowSummary: rowSummary,
                                            child: SizedBox(
                                              width: 180,
                                              child: Text(
                                                session.title,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 2,
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                            ),
                                          ),
                                        ),

                                        // 5. Broker
                                        DataCell(
                                          CopyableTableCell(
                                            value: '${session.brokerName}${session.brokerContactPerson != null ? " (${session.brokerContactPerson})" : ""}',
                                            rowSummary: rowSummary,
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  session.brokerName,
                                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                                ),
                                                if (session.brokerContactPerson != null)
                                                  Text(
                                                    session.brokerContactPerson!,
                                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        // 6. Estimated Duties
                                        DataCell(
                                          CopyableTableCell(
                                            value: '${session.estimatedDutiesEgp.toStringAsFixed(0)} $egpLabel',
                                            rowSummary: rowSummary,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppTheme.crimson.withOpacity(0.08),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                '${session.estimatedDutiesEgp.toStringAsFixed(0)} $egpLabel',
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.crimson, fontSize: 12),
                                              ),
                                            ),
                                          ),
                                        ),

                                        // 7. Readiness Progress Bar
                                        DataCell(
                                          CopyableTableCell(
                                            value: '${readinessPct.toStringAsFixed(0)}%',
                                            rowSummary: rowSummary,
                                            child: SizedBox(
                                              width: 145,
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        '${readinessPct.toStringAsFixed(0)}%',
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 11,
                                                          color: readinessPct >= 80 ? AppTheme.emerald : (readinessPct >= 50 ? Colors.orange : AppTheme.crimson),
                                                        ),
                                                      ),
                                                      if (hasBlocking)
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                          decoration: BoxDecoration(
                                                            color: AppTheme.crimson.withOpacity(0.12),
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                          child: Text(
                                                            l.blockingIssuesBadge(session.blockingIssuesCount),
                                                            style: const TextStyle(color: AppTheme.crimson, fontSize: 10, fontWeight: FontWeight.bold),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(4),
                                                    child: LinearProgressIndicator(
                                                      value: (readinessPct / 100).clamp(0.0, 1.0),
                                                      minHeight: 6,
                                                      backgroundColor: Colors.grey.shade200,
                                                      valueColor: AlwaysStoppedAnimation<Color>(
                                                        readinessPct >= 80 ? AppTheme.emerald : (readinessPct >= 50 ? Colors.orange : AppTheme.crimson),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    l.approvedDocsCountBadge(session.approvedDocumentsCount, session.totalDocumentsCount),
                                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),

                                        // 8. Status Badge
                                        DataCell(
                                          CopyableTableCell(
                                            value: session.overallStatus,
                                            rowSummary: rowSummary,
                                            child: ConsultationStatusBadge(status: session.overallStatus),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
          );
  }
}

