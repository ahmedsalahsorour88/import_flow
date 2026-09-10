import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/copyable_data_helper.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/smart_upload_button.dart';
import '../../../core/widgets/universal_entity_extractor_dialog.dart';
import '../../../core/widgets/vertical_stage_scaffold.dart';
import '../../external_service_providers/providers/partners_provider.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../models/customs_clearance_model.dart';
import '../providers/customs_clearance_provider.dart';
import '../widgets/drawing_samples_and_shortage_tab.dart';
import '../widgets/discrepancy_and_damage_tab.dart';
import '../widgets/final_duty_payment_tab.dart';
import '../widgets/under_bond_release_dialog.dart';


class CustomsClearanceScreen extends ConsumerStatefulWidget {
  final int initialSubTab;
  final int? initialImportFileId;

  const CustomsClearanceScreen({
    super.key,
    this.initialSubTab = 0,
    this.initialImportFileId,
  });

  @override
  ConsumerState<CustomsClearanceScreen> createState() => _CustomsClearanceScreenState();
}

class _CustomsClearanceScreenState extends ConsumerState<CustomsClearanceScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = 'All';
  int _selectedTab = 0;

  // Local state for sample drawing items & discrepancy protocols (Clean Production - 0 records)
  final List<Map<String, dynamic>> _drawnSamples = [];
  final List<Map<String, dynamic>> _shortageProtocols = [];
  final List<Map<String, dynamic>> _discrepancyProtocols = [];

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialSubTab;
    Future.microtask(() {
      _refreshData();
    });
  }

  @override
  void didUpdateWidget(covariant CustomsClearanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSubTab != oldWidget.initialSubTab) {
      setState(() => _selectedTab = widget.initialSubTab);
    }
  }

  void _refreshData() {
    if (!ref.read(customsClearanceProvider).isLoading) {
      ref.read(customsClearanceProvider.notifier).fetchRecords();
    }
    if (!ref.read(importFilesProvider).isLoading) {
      ref.read(importFilesProvider.notifier).fetchImportFiles();
    }
    if (!ref.read(partnersProvider).isLoading) {
      ref.read(partnersProvider.notifier).fetchPartners();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _copyClearanceRecordsTsv(List<CustomsClearanceModel> records, AppLocalizations l) {
    if (records.isEmpty) return;
    final buffer = StringBuffer();
    buffer.writeln([
      l.customsClearanceColClearanceCode,
      l.customsClearanceColDecl46,
      l.customsClearanceOfficeLabel,
      l.customsClearanceChannelLabel,
      l.customsClearanceDeliveryOrderLabel,
      l.customsClearanceColActualDuty,
      l.customsClearanceColEstimatedDuty,
      l.customsClearanceColDutyVariance,
      l.customsClearanceColPaymentStatus,
      l.status,
    ].join('\t'));

    for (final r in records) {
      final actual = (r.actualDutyTotal > 0 ? r.actualDutyTotal : r.totalDutyPayable).toStringAsFixed(2);
      final est = r.estimatedDutyTotal.toStringAsFixed(2);
      final variance = '${r.dutyVarianceAmount >= 0 ? "+" : ""}${r.dutyVarianceAmount.toStringAsFixed(2)}';
      buffer.writeln([
        r.clearanceCode,
        r.declaration46No ?? '-',
        r.customsOfficeName,
        r.channelType,
        r.deliveryOrderNumber ?? '-',
        actual,
        est,
        variance,
        r.paymentStatus,
        r.status,
      ].join('\t'));
    }

    CopyHelper.copy(context, buffer.toString(), customMessage: l.customsClearanceExportTsvSuccess);
  }

  void _showAddEditDialog([CustomsClearanceModel? recordToEdit]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CustomsClearanceFormDialog(recordToEdit: recordToEdit),
    );
  }

  void _showDutyPaymentDialog(CustomsClearanceModel record) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DutyPaymentDialog(record: record),
    );
  }

  void _showFinalReleaseDialog(CustomsClearanceModel record) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _FinalReleaseDialog(record: record),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final clearanceAsync = ref.watch(customsClearanceProvider);

    return VerticalStageScaffold(
      stageCode: 'PHASE-07',
      titleAr: 'الميناء والتخليص الجمركي والمعاينة والمطابقة',
      titleEn: 'Port Operations & Customs Clearance Hub',
      headerIcon: Icons.gavel_rounded,
      headerColor: Colors.purple,
      headerActions: [
        ElevatedButton.icon(
          icon: const Icon(Icons.auto_awesome_rounded, size: 16),
          label: Text(l.customsClearanceAiBrokerExtractorBtn),
          onPressed: () => UniversalEntityExtractorDialog.showCustomsBrokerExtractor(
            context,
            onSaved: () => ref.read(partnersProvider.notifier).fetchPartners(),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.emerald,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
      selectedIndex: _selectedTab,
      onTabSelected: (idx) => setState(() => _selectedTab = idx),
      tabs: const [
        VerticalNavTabItem(
          icon: Icons.fact_check_outlined,
          titleAr: 'متابعة الكشف والتثمين والتفتيش الجمركي',
          titleEn: 'Customs Clearance Follow-up',
        ),
        VerticalNavTabItem(
          icon: Icons.science_outlined,
          titleAr: 'سحب العينات وتحديد عجز البضائع',
          titleEn: 'Drawing Samples & Shortage Tracking',
        ),
        VerticalNavTabItem(
          icon: Icons.report_problem_outlined,
          titleAr: 'إثبات الفاقد والتلف الجمركي ومحاضر النقص',
          titleEn: 'Discrepancy & Damage Registry',
        ),
        VerticalNavTabItem(
          icon: Icons.receipt_long_outlined,
          titleAr: 'سداد الرسوم والضرائب الجمركية النهائية',
          titleEn: 'Final Customs Duty Payment & Release',
        ),
      ],
      body: SelectionArea(
        child: clearanceAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Text(l.customsClearanceErrorFetch(err.toString()), style: const TextStyle(color: Colors.red)),
          ),
          data: (records) {
            switch (_selectedTab) {
              case 0:
                return _buildClearanceFollowUpView(records, l);
              case 1:
                return _buildDrawingSamplesAndShortageView(records, l);
              case 2:
                return _buildDiscrepancyAndDamageView(records, l);
              case 3:
                return _buildFinalDutyPaymentView(records, l);
              default:
                return _buildClearanceFollowUpView(records, l);
            }
          },
        ),
      ),
    );
  }

  // ===========================================================================
  // SUB-VIEW 0: CUSTOMS CLEARANCE FOLLOW-UP
  // ===========================================================================
  Widget _buildClearanceFollowUpView(List<CustomsClearanceModel> records, AppLocalizations l) {
    final filtered = records.where((r) {
      if (_selectedStatusFilter != 'All' && r.status != _selectedStatusFilter) return false;
      if (_searchController.text.trim().isEmpty) return true;
      final q = _searchController.text.trim().toLowerCase();
      return r.clearanceCode.toLowerCase().contains(q) ||
          (r.declaration46No ?? '').toLowerCase().contains(q) ||
          (r.deliveryOrderNumber ?? '').toLowerCase().contains(q) ||
          r.customsOfficeName.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        // Filter & Action Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(
                  width: 280,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: l.customsClearanceSearchHint,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _searchController,
                        builder: (context, value, _) {
                          return value.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : const SizedBox.shrink();
                        },
                      ),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedStatusFilter,
                  underline: const SizedBox(),
                  items: [
                    DropdownMenuItem(value: 'All', child: Text(l.customsClearanceFilterAll)),
                    DropdownMenuItem(value: 'Inspection In Progress', child: Text(l.customsClearanceFilterInspection)),
                    DropdownMenuItem(value: 'Duty Requested', child: Text(l.customsClearanceFilterDutyRequested)),
                    DropdownMenuItem(value: 'Duty Paid', child: Text(l.customsClearanceFilterDutyPaid)),
                    DropdownMenuItem(value: 'Final Release Granted', child: Text(l.customsClearanceFilterFinalRelease)),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedStatusFilter = val);
                  },
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.cobalt,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(l.customsClearanceNewRecordButton),
                  onPressed: () => _showAddEditDialog(),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.copy_all_outlined, size: 16),
                  label: Text(l.customsClearanceExportTsvBtn),
                  onPressed: () => _copyClearanceRecordsTsv(filtered, l),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppTheme.cobalt),
                  tooltip: l.customsDeclRefreshTooltip,
                  onPressed: _refreshData,
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),

        // List of Cards
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Text(l.customsClearanceEmptyRecords))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final record = filtered[index];
                    return _buildClearanceCard(record, l);
                  },
                ),
        ),
      ],
    );
  }

  // ===========================================================================
  // SUB-VIEW 1: DRAWING SAMPLES & SHORTAGE TRACKING
  // ===========================================================================
  Widget _buildDrawingSamplesAndShortageView(List<CustomsClearanceModel> records, AppLocalizations l) {
    return DrawingSamplesAndShortageTab(
      records: records,
      drawnSamples: _drawnSamples,
      shortageProtocols: _shortageProtocols,
      onRefresh: _refreshData,
      onAddSample: (sample) {
        setState(() => _drawnSamples.insert(0, sample));
      },
      onAddShortage: (shortage) {
        setState(() => _shortageProtocols.insert(0, shortage));
      },
    );
  }

  // ===========================================================================
  // SUB-VIEW 2: DISCREPANCY & DAMAGE REGISTRY
  // ===========================================================================
  Widget _buildDiscrepancyAndDamageView(List<CustomsClearanceModel> records, AppLocalizations l) {
    return DiscrepancyAndDamageTab(
      records: records,
      discrepancyProtocols: _discrepancyProtocols,
      onRefresh: _refreshData,
      onAddProtocol: (protocol) {
        setState(() => _discrepancyProtocols.insert(0, protocol));
      },
    );
  }

  // ===========================================================================
  // SUB-VIEW 3: FINAL CUSTOMS PAYMENT & RELEASE
  // ===========================================================================
  Widget _buildFinalDutyPaymentView(List<CustomsClearanceModel> records, AppLocalizations l) {
    return FinalDutyPaymentTab(
      records: records,
      onRefresh: _refreshData,
      onPay: _showDutyPaymentDialog,
      onRelease: _showFinalReleaseDialog,
    );
  }

  Widget _buildClearanceCard(CustomsClearanceModel record, AppLocalizations l) {
    Color statusColor = Colors.blueGrey;
    String statusLabel = record.status;
    if (record.status == 'Final Release Granted') {
      statusColor = AppTheme.emerald;
      statusLabel = l.customsClearanceFilterFinalRelease;
    } else if (record.status == 'Duty Paid') {
      statusColor = AppTheme.cobalt;
      statusLabel = l.customsClearanceFilterDutyPaid;
    } else if (record.status == 'Duty Requested') {
      statusColor = AppTheme.orange;
      statusLabel = l.customsClearanceFilterDutyRequested;
    } else if (record.status == 'Inspection In Progress') {
      statusLabel = l.customsClearanceFilterInspection;
    }

    final isGreenChannel = record.channelType.toLowerCase().contains('green');
    String channelLabel = record.channelType;
    if (record.channelType.toLowerCase().contains('red')) {
      channelLabel = l.customsClearanceChannelRed;
    } else if (record.channelType.toLowerCase().contains('green')) {
      channelLabel = l.customsClearanceChannelGreen;
    } else if (record.channelType.toLowerCase().contains('yellow')) {
      channelLabel = l.customsClearanceChannelYellow;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.charcoal.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: CopyableText(
                          record.clearanceCode,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.charcoal, fontSize: 13),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isGreenChannel ? AppTheme.emerald : AppTheme.crimson).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: isGreenChannel ? AppTheme.emerald : AppTheme.crimson, width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(isGreenChannel ? Icons.check_circle_outline : Icons.flag_rounded, size: 14, color: isGreenChannel ? AppTheme.emerald : AppTheme.crimson),
                            const SizedBox(width: 4),
                            Text(
                              channelLabel,
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: isGreenChannel ? AppTheme.emerald : AppTheme.crimson),
                            ),
                          ],
                        ),
                      ),
                      if (record.declaration46No != null && record.declaration46No!.isNotEmpty)
                        CopyableText('${l.customsClearanceDeclaration46Label}: ${record.declaration46No}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.cobalt)),
                      if (record.deliveryOrderNumber != null && record.deliveryOrderNumber!.isNotEmpty)
                        CopyableText('${l.customsClearanceDeliveryOrderLabel}: ${record.deliveryOrderNumber}', style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    statusLabel,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const Divider(height: 18),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CopyableText('🏢 ${l.customsClearanceOfficeLabel}: ${record.customsOfficeName}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                      const SizedBox(height: 4),
                      CopyableText('${l.customsClearanceFileRefLabel}: IMP-${record.importFileId}', style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
                      if (record.freeDaysAllowed > 0)
                        Text('⏱️ ${l.customsClearanceFreeDaysLabel(record.freeDaysAllowed)}', style: const TextStyle(fontSize: 11.5, color: Colors.indigo, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CopyableText('💰 ${l.customsClearanceTotalDutiesCard}: ${(record.actualDutyTotal > 0 ? record.actualDutyTotal : record.totalDutyPayable).toStringAsFixed(2)} EGP', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.emerald)),
                      const SizedBox(height: 4),
                      if (record.estimatedDutyTotal > 0)
                        CopyableText(
                          '⚖️ ${l.customsClearanceEstimatedDutiesCard(record.estimatedDutyTotal.toStringAsFixed(2), "${record.dutyVarianceAmount >= 0 ? '+' : ''}${record.dutyVarianceAmount.toStringAsFixed(2)}", record.dutyVariancePercentage.toString())}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: record.dutyVarianceAmount.abs() > 500 ? AppTheme.orange : Colors.black54),
                        ),
                      Text('${l.customsClearancePaymentStatusLabel}: ${record.paymentStatus == "Paid & Verified" ? l.customsClearanceStatusPaid : l.customsClearanceStatusPendingPayment}', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: record.paymentStatus == 'Paid & Verified' ? AppTheme.emerald : Colors.red)),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppTheme.cobalt, size: 20),
                      tooltip: l.customsClearanceEditTooltip,
                      onPressed: () => _showAddEditDialog(record),
                    ),
                    IconButton(
                      icon: const Icon(Icons.lock_clock_outlined, color: AppTheme.orange, size: 20),
                      tooltip: l.customsClearanceUnderBondTooltip,
                      onPressed: () => showUnderBondReleaseDialog(
                        context,
                        ref,
                        clearanceId: record.customsClearanceId,
                        declarationNo: record.declaration46No ?? record.clearanceCode,
                        isAlreadyUnderBond: record.status.contains('Bond') || record.status.contains('Quarantine'),
                        onDone: _refreshData,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.payments_outlined, color: AppTheme.emerald, size: 20),
                      tooltip: l.customsClearancePayTooltip,
                      onPressed: () => _showDutyPaymentDialog(record),
                    ),

                    IconButton(
                      icon: const Icon(Icons.assignment_turned_in_outlined, color: Colors.indigo, size: 20),
                      tooltip: l.customsClearanceReleaseTooltip,
                      onPressed: () => _showFinalReleaseDialog(record),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomsClearanceFormDialog extends ConsumerStatefulWidget {
  final CustomsClearanceModel? recordToEdit;
  const _CustomsClearanceFormDialog({this.recordToEdit});

  @override
  ConsumerState<_CustomsClearanceFormDialog> createState() => _CustomsClearanceFormDialogState();
}

class _CustomsClearanceFormDialogState extends ConsumerState<_CustomsClearanceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedImportFileId;
  final TextEditingController _decl46Ctrl = TextEditingController();
  final TextEditingController _officeCtrl = TextEditingController(text: 'Alexandria Port Customs');
  final TextEditingController _doNumberCtrl = TextEditingController();
  final TextEditingController _freeDaysCtrl = TextEditingController(text: '14');
  String _channelType = 'Red Channel';
  final TextEditingController _dutyCtrl = TextEditingController(text: '0');
  final TextEditingController _vatCtrl = TextEditingController(text: '0');
  final TextEditingController _scheduleTaxCtrl = TextEditingController(text: '0');
  final TextEditingController _whtCtrl = TextEditingController(text: '0');
  final TextEditingController _labFeesCtrl = TextEditingController(text: '0');
  final TextEditingController _estimatedDutyCtrl = TextEditingController(text: '0');
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.recordToEdit != null) {
      final r = widget.recordToEdit!;
      _selectedImportFileId = r.importFileId;
      _decl46Ctrl.text = r.declaration46No ?? '';
      _officeCtrl.text = r.customsOfficeName;
      _doNumberCtrl.text = r.deliveryOrderNumber ?? '';
      _freeDaysCtrl.text = r.freeDaysAllowed.toString();
      _channelType = r.channelType;
      _dutyCtrl.text = r.importDutyAmount.toString();
      _vatCtrl.text = r.vatAmount.toString();
      _scheduleTaxCtrl.text = r.scheduleTaxAmount.toString();
      _whtCtrl.text = r.whtAmount.toString();
      _labFeesCtrl.text = r.labServiceFees.toString();
      _estimatedDutyCtrl.text = r.estimatedDutyTotal.toString();
    }
  }

  void _applyExtractedNafezaData(Map<String, dynamic> ext, AppLocalizations l) {
    setState(() {
      if (ext['declaration_no'] != null && ext['declaration_no'].toString().isNotEmpty) {
        _decl46Ctrl.text = ext['declaration_no'].toString();
      }
      if (ext['customs_office_name'] != null && ext['customs_office_name'].toString().isNotEmpty) {
        _officeCtrl.text = ext['customs_office_name'].toString();
      }
      if (ext['channel_type'] != null && ext['channel_type'].toString().isNotEmpty) {
        _channelType = ext['channel_type'].toString();
      }
      if (ext['import_duty'] != null) {
        _dutyCtrl.text = ext['import_duty'].toString();
      }
      if (ext['vat_amount'] != null) {
        _vatCtrl.text = ext['vat_amount'].toString();
      }
      if (ext['schedule_tax'] != null) {
        _scheduleTaxCtrl.text = ext['schedule_tax'].toString();
      }
      if (ext['wht_amount'] != null) {
        _whtCtrl.text = ext['wht_amount'].toString();
      }
      if (ext['lab_service_fees'] != null) {
        _labFeesCtrl.text = ext['lab_service_fees'].toString();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.customsClearanceExtractNafezaSuccess), backgroundColor: AppTheme.emerald),
    );
  }

  @override
  void dispose() {
    _decl46Ctrl.dispose();
    _officeCtrl.dispose();
    _doNumberCtrl.dispose();
    _freeDaysCtrl.dispose();
    _dutyCtrl.dispose();
    _vatCtrl.dispose();
    _scheduleTaxCtrl.dispose();
    _whtCtrl.dispose();
    _labFeesCtrl.dispose();
    _estimatedDutyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final importFiles = ref.watch(importFilesProvider).valueOrNull ?? [];

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(widget.recordToEdit == null ? l.customsClearanceNewDialogTitle : l.customsClearanceEditDialogTitle(widget.recordToEdit!.clearanceCode)),
          SmartUploadButton(
            module: SmartUploadModule.customsClearance,
            compact: true,
            label: l.customsClearanceExtractNafezaBtn,
            onDataExtracted: (res) => _applyExtractedNafezaData(res.extractedFields, l),
          ),
        ],
      ),
      content: SelectionArea(
        child: SizedBox(
          width: 600,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SearchableDropdownField<int>(
                    value: _selectedImportFileId,
                    labelText: l.customsClearanceImportFileLabel,
                    searchHintText: l.customsClearanceImportFileSearchHint,
                    items: importFiles
                        .map((f) => SearchableDropdownItem<int>(
                              value: f.importFileId,
                              label: '${f.primaryNameWithCode} - ${f.companyName}',
                              subtitle: 'PO: ${f.poNumber ?? "N/A"} | ACID: ${f.acidNumber ?? "N/A"}',
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedImportFileId = val),
                    validator: (val) => val == null ? l.customsClearanceSelectFileValidator : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _decl46Ctrl,
                          decoration: InputDecoration(
                            labelText: l.customsClearanceDecl46Label,
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.copy, size: 16),
                              tooltip: l.customsClearanceCopyFieldTooltip,
                              onPressed: () => CopyHelper.copy(context, _decl46Ctrl.text),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _doNumberCtrl,
                          decoration: InputDecoration(
                            labelText: l.customsClearanceDoNumberLabel,
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.copy, size: 16),
                              tooltip: l.customsClearanceCopyFieldTooltip,
                              onPressed: () => CopyHelper.copy(context, _doNumberCtrl.text),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _freeDaysCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: l.customsClearanceFreeDaysInputLabel, border: const OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _officeCtrl,
                        decoration: InputDecoration(labelText: l.customsClearanceOfficeInputLabel, border: const OutlineInputBorder()),
                        validator: (v) => (v == null || v.trim().isEmpty) ? l.customsClearanceOfficeValidator : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _channelType,
                        decoration: InputDecoration(labelText: l.customsClearanceChannelLabel, border: const OutlineInputBorder()),
                        items: [
                          DropdownMenuItem(value: 'Red Channel', child: Text('🔴 ${l.customsClearanceChannelRed}')),
                          DropdownMenuItem(value: 'Green Channel', child: Text('🟢 ${l.customsClearanceChannelGreen}')),
                          DropdownMenuItem(value: 'Yellow Channel', child: Text('🟡 ${l.customsClearanceChannelYellow}')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _channelType = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(l.customsClearanceDutyBreakdownHeader, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.cobalt)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _dutyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: l.customsClearanceImportDutyInput, border: const OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _vatCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: l.customsClearanceVatInput, border: const OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _scheduleTaxCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: l.customsClearanceScheduleTaxInput, border: const OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _whtCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: l.customsClearanceWhtInput, border: const OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _labFeesCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: l.customsClearanceLabFeesInput, border: const OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _estimatedDutyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: l.customsClearanceEstimatedDutyInput, border: const OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
          onPressed: _isLoading
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _isLoading = true);

                  final duty = double.tryParse(_dutyCtrl.text) ?? 0.0;
                  final vat = double.tryParse(_vatCtrl.text) ?? 0.0;
                  final sched = double.tryParse(_scheduleTaxCtrl.text) ?? 0.0;
                  final wht = double.tryParse(_whtCtrl.text) ?? 0.0;
                  final lab = double.tryParse(_labFeesCtrl.text) ?? 0.0;
                  final total = duty + vat + sched + wht + lab;

                  final payload = {
                    'import_file_id': _selectedImportFileId,
                    'declaration_46_no': _decl46Ctrl.text.trim().isNotEmpty ? _decl46Ctrl.text.trim() : null,
                    'customs_office_name': _officeCtrl.text.trim(),
                    'channel_type': _channelType,
                    'delivery_order_number': _doNumberCtrl.text.trim().isNotEmpty ? _doNumberCtrl.text.trim() : null,
                    'free_days_allowed': int.tryParse(_freeDaysCtrl.text) ?? 14,
                    'import_duty_amount': duty,
                    'vat_amount': vat,
                    'schedule_tax_amount': sched,
                    'wht_amount': wht,
                    'lab_service_fees': lab,
                    'total_duty_payable': total,
                    'estimated_duty_total': double.tryParse(_estimatedDutyCtrl.text) ?? 0.0,
                  };

                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  try {
                    await ref.read(customsClearanceProvider.notifier).createRecord(payload);
                    navigator.pop();
                    messenger.showSnackBar(
                      SnackBar(content: Text(l.customsClearanceSaveRecordSuccess), backgroundColor: AppTheme.emerald),
                    );
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(l.customsClearanceSaveRecordError(e.toString())), backgroundColor: AppTheme.crimson),
                    );
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(l.customsClearanceSaveRecordBtn, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class _DutyPaymentDialog extends ConsumerStatefulWidget {
  final CustomsClearanceModel record;
  const _DutyPaymentDialog({required this.record});

  @override
  ConsumerState<_DutyPaymentDialog> createState() => _DutyPaymentDialogState();
}

class _DutyPaymentDialogState extends ConsumerState<_DutyPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _receiptCtrl = TextEditingController();
  final TextEditingController _actualPaidCtrl = TextEditingController();
  final TextEditingController _varianceReasonCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _actualPaidCtrl.text = (widget.record.actualDutyTotal > 0 ? widget.record.actualDutyTotal : widget.record.totalDutyPayable).toString();
    _receiptCtrl.text = widget.record.bankReceiptNo ?? '';
    _varianceReasonCtrl.text = widget.record.dutyVarianceReason ?? '';
  }

  @override
  void dispose() {
    _receiptCtrl.dispose();
    _actualPaidCtrl.dispose();
    _varianceReasonCtrl.dispose();
    super.dispose();
  }

  void _applyExtractedPayment(Map<String, dynamic> ext) {
    setState(() {
      if (ext['receipt_number'] != null) _receiptCtrl.text = ext['receipt_number'].toString();
      if (ext['actual_paid_amount'] != null) _actualPaidCtrl.text = ext['actual_paid_amount'].toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final est = widget.record.estimatedDutyTotal;
    final act = double.tryParse(_actualPaidCtrl.text) ?? widget.record.totalDutyPayable;
    final diff = act - est;
    final diffPercent = est > 0 ? ((diff / est) * 100).toStringAsFixed(1) : '0.0';

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l.customsClearanceDutyPaymentDialogTitle(widget.record.clearanceCode)),
          SmartUploadButton(
            module: SmartUploadModule.customsClearance,
            compact: true,
            label: l.customsClearanceExtractReceiptBtn,
            onDataExtracted: (res) => _applyExtractedPayment(res.extractedFields),
          ),
        ],
      ),
      content: SelectionArea(
        child: SizedBox(
          width: 520,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Variance Comparison Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (diff.abs() > 500 ? AppTheme.orange : AppTheme.emerald).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: diff.abs() > 500 ? AppTheme.orange : AppTheme.emerald),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l.customsClearanceEstimatorDutyBoxLabel(est.toStringAsFixed(2)), style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(l.customsClearanceNafezaDutyBoxLabel(act.toStringAsFixed(2)), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald)),
                        ],
                      ),
                      const Divider(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l.customsClearanceVarianceBoxLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            '${diff >= 0 ? "+" : ""}${diff.toStringAsFixed(2)} EGP ($diffPercent%)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: diff.abs() > 500 ? AppTheme.crimson : AppTheme.emerald,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _actualPaidCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l.customsClearanceActualPaidInput, border: const OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? l.poRecRequired : null,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _receiptCtrl,
                  decoration: InputDecoration(
                    labelText: l.customsClearanceBankReceiptInput,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.copy, size: 16),
                      tooltip: l.customsClearanceCopyFieldTooltip,
                      onPressed: () => CopyHelper.copy(context, _receiptCtrl.text),
                    ),
                  ),
                  validator: (v) => v == null || v.isEmpty ? l.poRecRequired : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _varianceReasonCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: l.customsClearanceVarianceReasonInput, border: const OutlineInputBorder()),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald),
          onPressed: _isLoading
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _isLoading = true);
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  try {
                    await ref.read(customsClearanceProvider.notifier).submitDutyPayment(
                          widget.record.customsClearanceId,
                          {
                            'bank_receipt_no': _receiptCtrl.text.trim(),
                            'actual_duty_total': double.tryParse(_actualPaidCtrl.text) ?? widget.record.totalDutyPayable,
                            'duty_variance_reason': _varianceReasonCtrl.text.trim().isNotEmpty ? _varianceReasonCtrl.text.trim() : null,
                          },
                        );
                    navigator.pop();
                    messenger.showSnackBar(
                      SnackBar(content: Text(l.customsClearancePaymentSuccess), backgroundColor: AppTheme.emerald),
                    );
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(l.customsClearancePaymentError(e.toString())), backgroundColor: AppTheme.crimson),
                    );
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(l.customsClearanceConfirmPaymentBtn, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class _FinalReleaseDialog extends ConsumerStatefulWidget {
  final CustomsClearanceModel record;
  const _FinalReleaseDialog({required this.record});

  @override
  ConsumerState<_FinalReleaseDialog> createState() => _FinalReleaseDialogState();
}

class _FinalReleaseDialogState extends ConsumerState<_FinalReleaseDialog> {
  final TextEditingController _releaseNoCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _releaseNoCtrl.text = widget.record.releasePermitNo ?? 'REL-${widget.record.clearanceCode}';
  }

  @override
  void dispose() {
    _releaseNoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.verified_user, color: Colors.indigo),
          const SizedBox(width: 8),
          Text(l.customsClearanceFinalReleaseDialogTitle),
        ],
      ),
      content: SelectionArea(
        child: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.customsClearanceFinalReleaseDialogDesc),
              const SizedBox(height: 14),
              TextFormField(
                controller: _releaseNoCtrl,
                decoration: InputDecoration(
                  labelText: l.customsClearanceReleasePermitInput,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    tooltip: l.customsClearanceCopyFieldTooltip,
                    onPressed: () => CopyHelper.copy(context, _releaseNoCtrl.text),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() => _isLoading = true);
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  try {
                    await ref.read(customsClearanceProvider.notifier).completeRelease(
                          widget.record.customsClearanceId,
                          {
                            'release_permit_no': _releaseNoCtrl.text.trim(),
                          },
                        );
                    navigator.pop();
                    messenger.showSnackBar(
                      SnackBar(content: Text(l.customsClearanceReleaseSuccess), backgroundColor: AppTheme.emerald),
                    );
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(l.customsClearanceReleaseError(e.toString())), backgroundColor: AppTheme.crimson),
                    );
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(l.customsClearanceConfirmReleaseBtn, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
