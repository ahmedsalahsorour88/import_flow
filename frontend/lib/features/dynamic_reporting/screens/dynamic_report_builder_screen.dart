import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../../import_files/models/import_file_model.dart';

class DynamicReportColumn {
  final String id;
  bool isVisible;

  DynamicReportColumn({required this.id, this.isVisible = true});
}

class DynamicReportBuilderScreen extends ConsumerStatefulWidget {
  const DynamicReportBuilderScreen({super.key});

  @override
  ConsumerState<DynamicReportBuilderScreen> createState() => _DynamicReportBuilderScreenState();
}

class _DynamicReportBuilderScreenState extends ConsumerState<DynamicReportBuilderScreen> {
  final List<DynamicReportColumn> _columns = [
    DynamicReportColumn(id: 'importFileCode'),
    DynamicReportColumn(id: 'companyName'),
    DynamicReportColumn(id: 'supplierName'),
    DynamicReportColumn(id: 'brokerName'),
    DynamicReportColumn(id: 'acidNumber'),
    DynamicReportColumn(id: 'form4No'),
    DynamicReportColumn(id: 'form46No'),
    DynamicReportColumn(id: 'shipmentMode'),
    DynamicReportColumn(id: 'incotermCode'),
    DynamicReportColumn(id: 'priority'),
    DynamicReportColumn(id: 'estimatedCost'),
    DynamicReportColumn(id: 'requiredEta'),
    DynamicReportColumn(id: 'currentStage'),
    DynamicReportColumn(id: 'progressPercent'),
    DynamicReportColumn(id: 'owner'),
    DynamicReportColumn(id: 'status'),
  ];

  String _filterMode = 'All';
  String _filterPriority = 'All';
  final String _filterStatus = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(importFilesProvider.notifier).fetchImportFiles();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getColumnLabel(BuildContext context, String colId) {
    final l = context.l10n;
    switch (colId) {
      case 'importFileCode': return l.dynColImportFileCode;
      case 'companyName': return l.dynColCompanyName;
      case 'supplierName': return l.dynColSupplierName;
      case 'brokerName': return l.dynColBrokerName;
      case 'acidNumber': return l.dynColAcidNumber;
      case 'form4No': return l.dynColForm4No;
      case 'form46No': return l.dynColForm46No;
      case 'shipmentMode': return l.dynColShipmentMode;
      case 'incotermCode': return l.dynColIncotermCode;
      case 'priority': return l.dynColPriority;
      case 'estimatedCost': return l.dynColEstimatedCost;
      case 'requiredEta': return l.dynColRequiredEta;
      case 'currentStage': return l.dynColCurrentStage;
      case 'progressPercent': return l.dynColProgressPercent;
      case 'owner': return l.dynColOwner;
      case 'status': return l.dynColStatus;
      default: return colId;
    }
  }

  List<ImportFileModel> _filterFiles(List<ImportFileModel> files) {
    return files.where((f) {
      if (_filterMode != 'All' && f.shipmentMode != _filterMode) return false;
      if (_filterPriority != 'All' && f.priority != _filterPriority) return false;
      if (_filterStatus != 'All' && f.status != _filterStatus) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchCode = f.importFileCode.toLowerCase().contains(q) || (f.customFileNumber?.toLowerCase().contains(q) ?? false);
        final matchComp = f.companyName.toLowerCase().contains(q);
        final matchSup = f.supplierName.toLowerCase().contains(q);
        if (!matchCode && !matchComp && !matchSup) return false;
      }
      return true;
    }).toList();
  }

  void _exportToCSV(List<ImportFileModel> files) {
    final l = context.l10n;
    final visibleCols = _columns.where((c) => c.isVisible).toList();
    final headerRow = visibleCols.map((c) => _getColumnLabel(context, c.id)).join(',');

    final rows = files.map((f) {
      return visibleCols.map((c) {
        final val = _getCellValue(f, c.id);
        return '"${val.replaceAll('"', '""')}"';
      }).join(',');
    }).toList();

    final csvContent = '$headerRow\n${rows.join('\n')}';

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.file_download, color: AppTheme.emerald),
            const SizedBox(width: 8),
            Text(l.dynExportCsvTitle),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.dynExportCsvGeneratedMsg),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                height: 150,
                decoration: BoxDecoration(color: Colors.grey.shade100, border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(6)),
                child: SingleChildScrollView(
                  child: SelectableText(csvContent, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(c), child: Text(l.close)),
        ],
      ),
    );
  }

  Future<void> _exportToPDF(List<ImportFileModel> files) async {
    final l = context.l10n;
    final visibleCols = _columns.where((c) => c.isVisible).toList();
    final doc = pw.Document();

    // Build table headers
    final headers = visibleCols.map((c) => _getColumnLabel(context, c.id)).toList();

    // Build table data rows
    final tableData = files.map((f) {
      return visibleCols.map((c) => _getCellValue(f, c.id)).toList();
    }).toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) => [
          // Title Header
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blueGrey800, width: 2)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      l.dynPdfReportTitle,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey800,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      l.dynPdfGenerated(DateTime.now().toLocal().toString().substring(0, 16), files.length),
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          // Data Table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.blueGrey200, width: 0.5),
            columnWidths: {
              for (int i = 0; i < headers.length; i++)
                i: const pw.FlexColumnWidth(1),
            },
            children: [
              // Header Row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                children: headers.map((h) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  child: pw.Text(
                    h,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textDirection: pw.TextDirection.rtl,
                  ),
                )).toList(),
              ),
              // Data Rows
              ...tableData.asMap().entries.map((entry) {
                final isEven = entry.key.isEven;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: isEven ? PdfColors.blueGrey50 : PdfColors.white,
                  ),
                  children: entry.value.map((cell) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: pw.Text(
                      cell,
                      style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.blueGrey900),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  )).toList(),
                );
              }),
            ],
          ),
          pw.SizedBox(height: 12),
          // Footer
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(l.dynPdfConfidential, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              pw.Text('${files.length} records', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'ImportFlow_Dynamic_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  String _getCellValue(ImportFileModel file, String colId) {
    switch (colId) {
      case 'importFileCode':
        return file.customFileNumber ?? file.importFileCode;
      case 'companyName':
        return file.companyName;
      case 'supplierName':
        return file.supplierName;
      case 'brokerName':
        return file.brokerName ?? '-';
      case 'acidNumber':
        return file.acidNumber ?? '-';
      case 'form4No':
        return file.form4No ?? '-';
      case 'form46No':
        return file.form46No ?? '-';
      case 'shipmentMode':
        return file.shipmentMode;
      case 'incotermCode':
        return file.incotermCode;
      case 'priority':
        return file.priority;
      case 'estimatedCost':
        return '${file.estimatedCost} USD';
      case 'requiredEta':
        return file.requiredEta ?? '-';
      case 'currentStage':
        return file.currentStage;
      case 'progressPercent':
        return '${file.progressPercent.toInt()}%';
      case 'owner':
        return file.owner;
      case 'status':
        return file.status;
      default:
        return '-';
    }
  }

  void _showColumnPicker() {
    final l = context.l10n;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: 500,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.view_column, color: AppTheme.cobalt),
                      const SizedBox(width: 10),
                      Text(l.dynColumnPickerTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Spacer(),
                      IconButton(onPressed: () => Navigator.pop(c), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _columns.length,
                      itemBuilder: (context, idx) {
                        final col = _columns[idx];
                        return CheckboxListTile(
                          title: Text(_getColumnLabel(context, col.id), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          value: col.isVisible,
                          activeColor: AppTheme.cobalt,
                          onChanged: (val) {
                            setSheetState(() => col.isVisible = val ?? true);
                            setState(() {});
                          },
                        );
                      },
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, minimumSize: const Size.fromHeight(45)),
                    onPressed: () => Navigator.pop(c),
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: Text(l.dynApplyColumnsBtn, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final importFilesState = ref.watch(importFilesProvider);
    final visibleCols = _columns.where((c) => c.isVisible).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppTheme.charcoal,
        title: Row(
          children: [
            const Icon(Icons.assessment, color: AppTheme.cobalt),
            const SizedBox(width: 10),
            Text(l.dynReportBuilderTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          const BackToDashboardButton(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref.read(importFilesProvider.notifier).fetchImportFiles(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toolbar Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
                      onPressed: _showColumnPicker,
                      icon: const Icon(Icons.view_column, color: Colors.white),
                      label: Text(l.dynCustomizeColumnsBtn(visibleCols.length, _columns.length), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),

                    importFilesState.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (files) {
                        final filtered = _filterFiles(files);
                        return Row(
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
                              onPressed: () => _exportToCSV(filtered),
                              icon: const Icon(Icons.table_chart, color: Colors.white),
                              label: Text(l.dynExportExcelBtn(filtered.length), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC0392B), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
                              onPressed: () => _exportToPDF(filtered),
                              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                              label: Text(l.dynExportPdfBtn(filtered.length), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(width: 16),

                    // Filter Mode
                    SizedBox(
                      width: 140,
                      child: DropdownButtonFormField<String>(
                        value: _filterMode,
                        decoration: InputDecoration(labelText: l.dynFilterModeLabel, isDense: true, border: const OutlineInputBorder()),
                        items: [
                          DropdownMenuItem(value: 'All', child: Text(l.dynModeAll)),
                          DropdownMenuItem(value: 'Sea FCL', child: Text(l.dynModeSeaFcl)),
                          DropdownMenuItem(value: 'Sea LCL', child: Text(l.dynModeSeaLcl)),
                          DropdownMenuItem(value: 'Air', child: Text(l.dynModeAir)),
                          DropdownMenuItem(value: 'Courier', child: Text(l.dynModeCourier)),
                          DropdownMenuItem(value: 'Land', child: Text(l.dynModeLand)),
                          DropdownMenuItem(value: 'Multimodal', child: Text(l.dynModeMultimodal)),
                        ],
                        onChanged: (v) => setState(() => _filterMode = v!),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Filter Priority
                    SizedBox(
                      width: 130,
                      child: DropdownButtonFormField<String>(
                        value: _filterPriority,
                        decoration: InputDecoration(labelText: l.dynFilterPriorityLabel, isDense: true, border: const OutlineInputBorder()),
                        items: [
                          DropdownMenuItem(value: 'All', child: Text(l.dynPriorityAll)),
                          DropdownMenuItem(value: 'High', child: Text(l.dynPriorityHigh)),
                          DropdownMenuItem(value: 'Critical', child: Text(l.dynPriorityCritical)),
                          DropdownMenuItem(value: 'Medium', child: Text(l.dynPriorityMedium)),
                        ],
                        onChanged: (v) => setState(() => _filterPriority = v!),
                      ),
                    ),
                    const Spacer(),

                    // Search Input
                    SizedBox(
                      width: 250,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: l.dynSearchPlaceholder,
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v.trim()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Live Table Preview
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: importFilesState.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text(l.dynFetchReportError(err.toString()), style: const TextStyle(color: AppTheme.crimson))),
                  data: (files) {
                    final filtered = _filterFiles(files);
                    if (filtered.isEmpty) {
                      return Center(child: Text(l.dynNoMatchingShipments));
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(AppTheme.charcoal.withOpacity(0.05)),
                          columns: visibleCols.map((c) {
                            return DataColumn(label: Text(_getColumnLabel(context, c.id), style: const TextStyle(fontWeight: FontWeight.bold)));
                          }).toList(),
                          rows: filtered.map((file) {
                            return DataRow(
                              cells: visibleCols.map((col) {
                                final textVal = _getCellValue(file, col.id);
                                return DataCell(Text(textVal, style: TextStyle(
                                  fontWeight: col.id == 'importFileCode' ? FontWeight.bold : FontWeight.normal,
                                  color: col.id == 'importFileCode' ? AppTheme.cobalt : AppTheme.charcoal,
                                )));
                              }).toList(),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

