import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/services/file_save_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../import_files/models/import_file_model.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../models/original_documents_collection_model.dart';
import '../providers/original_documents_collection_provider.dart';

String _formatDateTime(DateTime dt) {
  final str = dt.toIso8601String();
  if (str.length >= 16) {
    return str.substring(0, 16).replaceAll('T', ' ');
  }
  return str;
}

class OriginalDocumentsCollectionTab extends ConsumerStatefulWidget {
  final int? initialImportFileId;

  const OriginalDocumentsCollectionTab({super.key, this.initialImportFileId});

  @override
  ConsumerState<OriginalDocumentsCollectionTab> createState() =>
      _OriginalDocumentsCollectionTabState();
}

class _OriginalDocumentsCollectionTabState
    extends ConsumerState<OriginalDocumentsCollectionTab> {
  final _formKey = GlobalKey<FormState>();

  ImportFileModel? _selectedImportFile;
  OriginalDocumentsCollectionSessionModel? _existingSession;

  List<CourierEntryModel> _couriers = [];
  List<OriginalDocumentItemModel> _documents = [];

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isExporting = false;

  String _sessionStatus = 'DRAFT';
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _overrideReasonController = TextEditingController();
  final TextEditingController _registrySearchController = TextEditingController();
  String _registryStatusFilter = 'All';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(importFilesProvider.notifier).fetchImportFiles();
      ref.read(originalDocumentsSessionsProvider.notifier).fetchSessions();
      if (widget.initialImportFileId != null) {
        _loadInitialFile(widget.initialImportFileId!);
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _overrideReasonController.dispose();
    _registrySearchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialFile(int fileId) async {
    final filesAsync = ref.read(importFilesProvider);
    filesAsync.whenData((files) {
      final match = files.where((f) => f.importFileId == fileId).firstOrNull;
      if (match != null) {
        _onSelectImportFile(match);
      }
    });
  }

  Future<void> _onSelectImportFile(ImportFileModel file) async {
    final l = context.l10n;
    setState(() {
      _selectedImportFile = file;
      _existingSession = null;
      _couriers = [];
      _documents = [];
      _notesController.clear();
      _overrideReasonController.clear();
      _isLoading = true;
    });

    try {
      final notifier = ref.read(originalDocumentsSessionsProvider.notifier);
      final autoData = await notifier.fetchAutoPopulate(file.importFileId);

      if (!mounted) return;
      setState(() {
        if (autoData.existingSession != null) {
          _existingSession = autoData.existingSession;
          _couriers = List.from(autoData.existingSession!.couriersList);
          _documents = List.from(autoData.existingSession!.documentsList);
          _sessionStatus = autoData.existingSession!.status;
          _notesController.text = autoData.existingSession!.notes ?? '';
          _overrideReasonController.text =
              autoData.existingSession!.discrepancyOverrideReason ?? '';
        } else {
          _couriers = List.from(autoData.defaultCouriers);
          _documents = List.from(autoData.requiredDocuments);
          _sessionStatus = 'DRAFT';
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.errorFetchingArchiveData(e)), backgroundColor: Colors.red),
      );
    }
  }

  void _addCourier() {
    setState(() {
      _couriers.add(
        CourierEntryModel(
          courierNo: '',
          courierCompany: 'DHL',
          dispatchDate: DateTime.now().toIso8601String().substring(0, 10),
          isReceived: false,
        ),
      );
    });
  }

  void _removeCourier(int index) {
    setState(() {
      _couriers.removeAt(index);
    });
  }

  void _addCustomDocument() {
    final l = context.l10n;
    setState(() {
      _documents.add(
        OriginalDocumentItemModel(
          category: 'Commercial',
          documentName: l.defaultNewCustomDocName,
          isRequired: 'Yes',
          responsibleParty: 'Supplier',
          status: 'Pending',
        ),
      );
    });
  }

  void _removeDocument(int index) {
    setState(() {
      _documents.removeAt(index);
    });
  }

  Future<void> _handleSaveSession({bool isConfirmComplete = false}) async {
    final l = context.l10n;
    if (_selectedImportFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.selectImportFileFirstWarning), backgroundColor: Colors.red),
      );
      return;
    }

    if (isConfirmComplete) {
      final unverified = _documents.where((d) => !d.isVerified && d.isRequired == 'Yes').toList();
      if (unverified.isNotEmpty && _overrideReasonController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.unverifiedMandatoryDocsWarning),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(originalDocumentsSessionsProvider.notifier);
      final payload = {
        'import_file_id': _selectedImportFile!.importFileId,
        'import_file_code': _selectedImportFile!.importFileCode,
        'acid_number': _selectedImportFile!.acidNumber,
        'importer_name': _selectedImportFile!.companyName,
        'supplier_name': _selectedImportFile!.supplierName,
        'status': isConfirmComplete ? 'FULLY_VERIFIED' : _sessionStatus,
        'couriers_list': _couriers.map((c) => c.toJson()).toList(),
        'documents_list': _documents.map((d) => d.toJson()).toList(),
        'discrepancy_override_reason': _overrideReasonController.text.trim(),
        'notes': _notesController.text.trim(),
      };

      final saved = await notifier.saveOrUpsertSession(payload);
      if (!mounted) return;
      setState(() {
        _existingSession = saved;
        _sessionStatus = saved.status;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.sessionSavedSuccess(saved.collectionCode)),
          backgroundColor: const Color(0xFF27AE60),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.sessionSaveError(e)), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleExportExcel() async {
    final l = context.l10n;
    if (_selectedImportFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.selectImportFileFirstWarning), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isExporting = true);
    try {
      final notifier = ref.read(originalDocumentsSessionsProvider.notifier);
      final bytes = await notifier.downloadExcel(_selectedImportFile!.importFileId);

      if (!mounted) return;
      final defaultName = 'Original_Documents_${_selectedImportFile!.importFileCode}.xlsx';
      await FileSaveHelper.saveBytes(
        context: context,
        bytes: bytes,
        defaultFileName: defaultName,
        dialogTitle: 'حفظ مستندات وأصول الشحنة بصيغة Excel',
        allowedExtensions: ['xlsx', 'xls'],
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.excelExportError(e)), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  String _getDocCategoryLabel(String category, AppLocalizations l) {
    switch (category) {
      case 'Commercial':
        return l.docCatCommercial;
      case 'Certificate':
        return l.docCatCertificate;
      case 'Shipping':
        return l.docCatShipping;
      case 'Egypt Import':
        return l.docCatEgyptImport;
      case 'Banking':
        return l.docCatBanking;
      case 'Regulatory':
        return l.docCatRegulatory;
      case 'Other':
        return l.docCatOther;
      default:
        return category;
    }
  }

  String _getCourierCompanyLabel(String company, AppLocalizations l) {
    switch (company) {
      case 'Hand Delivery':
        return l.courierCompanyHandDelivery;
      case 'Other':
        return l.courierCompanyOther;
      default:
        return company;
    }
  }

  String _getResponsiblePartyLabel(String party, AppLocalizations l) {
    switch (party) {
      case 'Supplier':
        return l.partySupplier;
      case 'Freight Forwarder':
        return l.partyFreightForwarder;
      case 'Customs Broker':
        return l.partyCustomsBroker;
      case 'Bank':
        return l.partyBank;
      case 'Importer':
        return l.partyImporter;
      case 'Carrier':
      case 'Shipping Line':
        return l.partyCarrier;
      default:
        return party;
    }
  }

  String _getStatusLabel(String status, AppLocalizations l) {
    switch (status) {
      case 'Verified':
        return l.statusBadgeVerified;
      case 'Received':
        return l.statusBadgeReceived;
      case 'In Transit':
        return l.statusBadgeInTransit;
      case 'Discrepant':
        return l.statusBadgeDiscrepant;
      case 'DRAFT':
        return l.filterStatusDraft;
      case 'PARTIALLY_RECEIVED':
        return l.filterStatusPartiallyReceived;
      case 'FULLY_RECEIVED':
        return l.filterStatusFullyReceived;
      case 'FULLY_VERIFIED':
        return l.filterStatusFullyVerified;
      case 'Pending':
      default:
        return l.statusBadgePending;
    }
  }

  String _getRegistryStatusFilterLabel(String filter, AppLocalizations l) {
    switch (filter) {
      case 'All':
        return l.filterStatusAll;
      case 'DRAFT':
        return l.filterStatusDraft;
      case 'PARTIALLY_RECEIVED':
        return l.filterStatusPartiallyReceived;
      case 'FULLY_RECEIVED':
        return l.filterStatusFullyReceived;
      case 'FULLY_VERIFIED':
        return l.filterStatusFullyVerified;
      default:
        return filter;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final filesAsync = ref.watch(importFilesProvider);
    final sessionsAsync = ref.watch(originalDocumentsSessionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(l),
              if (_isLoading) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
              ],
              const SizedBox(height: 16),
              _buildFileSelector(l, filesAsync),
              if (_selectedImportFile != null) ...[
                const SizedBox(height: 16),
                _buildStatisticsCards(l),
                const SizedBox(height: 16),
                _buildCouriersManagementCard(l),
                const SizedBox(height: 16),
                _buildDocumentsCollectionGrid(l),
                const SizedBox(height: 16),
                _buildSessionNotesCard(l),
                const SizedBox(height: 16),
                _buildActionToolbar(l),
              ],
              const SizedBox(height: 24),
              _buildRegistrySection(l, sessionsAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.cobalt.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.markunread_mailbox_outlined, color: AppTheme.cobalt, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.originalDocsHubTitle,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                ),
                const SizedBox(height: 4),
                Text(
                  l.originalDocsHubSubtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          if (_existingSession != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF27AE60).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF27AE60)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Color(0xFF27AE60), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    l.savedSessionBadge(_existingSession!.collectionCode),
                    style: const TextStyle(color: Color(0xFF27AE60), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileSelector(AppLocalizations l, AsyncValue<List<ImportFileModel>> filesAsync) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: filesAsync.when(
        data: (files) {
          return Row(
            children: [
              Expanded(
                child: SearchableDropdownField<int>(
                  labelText: l.selectImportFileLabel,
                  hintText: l.selectImportFileHint,
                  value: _selectedImportFile?.importFileId,
                  items: files
                      .map((f) => SearchableDropdownItem<int>(
                            value: f.importFileId,
                            label: '${f.importFileCode} — ${f.supplierName} (${f.companyName}) [ACID: ${f.acidNumber ?? "N/A"}]',
                            searchValue: '${f.importFileCode} ${f.supplierName} ${f.companyName} ${f.acidNumber ?? ""}',
                          ))
                      .toList(),
                  onChanged: (fileId) {
                    if (fileId != null) {
                      final match = files.where((f) => f.importFileId == fileId).firstOrNull;
                      if (match != null) _onSelectImportFile(match);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => ref.read(importFilesProvider.notifier).fetchImportFiles(),
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(l.refreshDataTooltip),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cobalt,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ],
          );
        },
        loading: () => const LinearProgressIndicator(),
        error: (e, _) => Text(l.errorFetchingImportFiles(e), style: const TextStyle(color: Colors.red)),
      ),
    );
  }

  Widget _buildStatisticsCards(AppLocalizations l) {
    final totalDocs = _documents.length;
    final receivedDocs = _documents.where((d) => d.isReceived).length;
    final verifiedDocs = _documents.where((d) => d.isVerified).length;
    final pendingDocs = totalDocs - receivedDocs;
    final completionPct = totalDocs > 0 ? (verifiedDocs / totalDocs * 100).toStringAsFixed(1) : '0.0';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _statCard(l.statTotalRequiredDocs, '$totalDocs', Icons.description_outlined, AppTheme.charcoal),
          const SizedBox(width: 12),
          _statCard(l.statReceivedOriginals, '$receivedDocs', Icons.inbox_outlined, const Color(0xFF3498DB)),
          const SizedBox(width: 12),
          _statCard(l.statVerifiedDocs, '$verifiedDocs', Icons.verified_outlined, const Color(0xFF27AE60)),
          const SizedBox(width: 12),
          _statCard(l.statPendingDocs, '$pendingDocs', Icons.hourglass_empty_outlined, const Color(0xFFE67E22)),
          const SizedBox(width: 12),
          _statCard(l.statReadinessRate, '$completionPct%', Icons.pie_chart_outline, const Color(0xFF8E44AD)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouriersManagementCard(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_shipping_outlined, color: AppTheme.cobalt, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    l.courierDispatchPackagesHeader,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.charcoal),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _addCourier,
                icon: const Icon(Icons.add, size: 16),
                label: Text(l.addCourierAwbBtn),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cobalt,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_couriers.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: Text(l.noCouriersRegisteredMsg,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _couriers.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, idx) {
                final c = _couriers[idx];
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppTheme.cobalt.withOpacity(0.15),
                      child: Text('${idx + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        initialValue: c.courierNo,
                        decoration: InputDecoration(
                          labelText: l.courierTrackingNoField,
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (val) => c.courierNo = val.trim(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: ['DHL', 'FedEx', 'Aramex', 'UPS', 'Naqel', 'SMSA', 'Hand Delivery', 'Other'].contains(c.courierCompany)
                            ? c.courierCompany
                            : 'DHL',
                        decoration: InputDecoration(
                          labelText: l.courierCompanyField,
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                        items: ['DHL', 'FedEx', 'Aramex', 'UPS', 'Naqel', 'SMSA', 'Hand Delivery', 'Other']
                            .map((company) => DropdownMenuItem(
                                  value: company,
                                  child: Text(_getCourierCompanyLabel(company, l), style: const TextStyle(fontSize: 12)),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => c.courierCompany = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        initialValue: c.dispatchDate,
                        decoration: InputDecoration(
                          labelText: l.dispatchDateField,
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (val) => c.dispatchDate = val.trim(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: c.isReceived,
                          activeColor: const Color(0xFF27AE60),
                          onChanged: (val) {
                            setState(() {
                              c.isReceived = val ?? false;
                              if (c.isReceived && (c.receivedDate == null || c.receivedDate!.isEmpty)) {
                                c.receivedDate = DateTime.now().toIso8601String().substring(0, 10);
                              }
                            });
                          },
                        ),
                        Text(l.isReceivedCheckbox, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        initialValue: c.receivedBy,
                        decoration: InputDecoration(
                          labelText: l.receivedByNameField,
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (val) => c.receivedBy = val.trim(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      tooltip: l.deleteCourierTooltip,
                      onPressed: () => _removeCourier(idx),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDocumentsCollectionGrid(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.table_view_outlined, color: Color(0xFF27AE60), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    l.physicalDocsVerificationMatrixHeader,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.charcoal),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _addCustomDocument,
                icon: const Icon(Icons.add, size: 16),
                label: Text(l.addCustomDocBtn),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27AE60),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFF2C3E50)),
              headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              dataRowMinHeight: 48,
              dataRowMaxHeight: 56,
              columns: [
                DataColumn(label: Text(l.colCourierNo)),
                DataColumn(label: Text(l.colDocCategory)),
                DataColumn(label: Text(l.colDocName)),
                DataColumn(label: Text(l.colRequirement)),
                DataColumn(label: Text(l.colResponsibleParty)),
                DataColumn(label: Text(l.colPhysicalReceived)),
                DataColumn(label: Text(l.colReceivedDate)),
                DataColumn(label: Text(l.colVerified)),
                DataColumn(label: Text(l.colAuditor)),
                DataColumn(label: Text(l.colDocStatus)),
                DataColumn(label: Text(l.colRemarks)),
                DataColumn(label: Text(l.colAction)),
              ],
              rows: List.generate(_documents.length, (index) {
                final doc = _documents[index];
                return DataRow(
                  cells: [
                    // Courier No
                    DataCell(
                      SizedBox(
                        width: 140,
                        child: DropdownButtonFormField<String>(
                          value: _couriers.any((c) => c.courierNo == doc.courierNo && c.courierNo.isNotEmpty)
                              ? doc.courierNo
                              : null,
                          isDense: true,
                          hint: Text(l.selectCourierPlaceholder, style: const TextStyle(fontSize: 11)),
                          decoration: const InputDecoration(border: InputBorder.none),
                          items: _couriers
                              .where((c) => c.courierNo.isNotEmpty)
                              .map((c) => DropdownMenuItem(value: c.courierNo, child: Text(c.courierNo, style: const TextStyle(fontSize: 11))))
                              .toList(),
                          onChanged: (val) {
                            setState(() => doc.courierNo = val);
                          },
                        ),
                      ),
                    ),
                    // Category
                    DataCell(
                      SizedBox(
                        width: 110,
                        child: DropdownButtonFormField<String>(
                          value: doc.category,
                          isDense: true,
                          decoration: const InputDecoration(border: InputBorder.none),
                          items: ['Commercial', 'Certificate', 'Shipping', 'Egypt Import', 'Banking', 'Regulatory', 'Other']
                              .map((cat) => DropdownMenuItem(
                                    value: cat,
                                    child: Text(_getDocCategoryLabel(cat, l), style: const TextStyle(fontSize: 11)),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => doc.category = val);
                          },
                        ),
                      ),
                    ),
                    // Document Name
                    DataCell(
                      SizedBox(
                        width: 170,
                        child: TextFormField(
                          initialValue: doc.documentName,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(border: InputBorder.none),
                          onChanged: (val) => doc.documentName = val.trim(),
                        ),
                      ),
                    ),
                    // Required
                    DataCell(_buildRequiredBadge(doc.isRequired, l)),
                    // Responsible Party
                    DataCell(Text(_getResponsiblePartyLabel(doc.responsibleParty, l), style: const TextStyle(fontSize: 11))),
                    // Received Checkbox
                    DataCell(
                      Checkbox(
                        value: doc.isReceived,
                        activeColor: const Color(0xFF3498DB),
                        onChanged: (val) {
                          setState(() {
                            doc.isReceived = val ?? false;
                            if (doc.isReceived && (doc.receivedDate == null || doc.receivedDate!.isEmpty)) {
                              doc.receivedDate = DateTime.now().toIso8601String().substring(0, 10);
                            }
                            if (doc.isReceived && doc.status == 'Pending') {
                              doc.status = 'Received';
                            }
                          });
                        },
                      ),
                    ),
                    // Received Date
                    DataCell(
                      SizedBox(
                        width: 100,
                        child: TextFormField(
                          initialValue: doc.receivedDate,
                          style: const TextStyle(fontSize: 11),
                          decoration: const InputDecoration(hintText: 'YYYY-MM-DD', border: InputBorder.none),
                          onChanged: (val) => doc.receivedDate = val.trim(),
                        ),
                      ),
                    ),
                    // Verified Checkbox
                    DataCell(
                      Checkbox(
                        value: doc.isVerified,
                        activeColor: const Color(0xFF27AE60),
                        onChanged: (val) {
                          setState(() {
                            doc.isVerified = val ?? false;
                            if (doc.isVerified) {
                              doc.isReceived = true;
                              doc.status = 'Verified';
                              if (doc.verificationDate == null || doc.verificationDate!.isEmpty) {
                                doc.verificationDate = DateTime.now().toIso8601String().substring(0, 10);
                              }
                              if (doc.verifiedBy == null || doc.verifiedBy!.isEmpty) {
                                doc.verifiedBy = 'Kamal';
                              }
                            } else {
                              doc.status = doc.isReceived ? 'Received' : 'Pending';
                            }
                          });
                        },
                      ),
                    ),
                    // Verified By
                    DataCell(
                      SizedBox(
                        width: 100,
                        child: TextFormField(
                          initialValue: doc.verifiedBy,
                          style: const TextStyle(fontSize: 11),
                          decoration: InputDecoration(hintText: l.hintAuditor, border: InputBorder.none),
                          onChanged: (val) => doc.verifiedBy = val.trim(),
                        ),
                      ),
                    ),
                    // Status Badge
                    DataCell(_buildStatusBadge(doc.status, l)),
                    // Remarks
                    DataCell(
                      SizedBox(
                        width: 140,
                        child: TextFormField(
                          initialValue: doc.remarks,
                          style: const TextStyle(fontSize: 11),
                          decoration: InputDecoration(hintText: l.hintRemarks, border: InputBorder.none),
                          onChanged: (val) => doc.remarks = val.trim(),
                        ),
                      ),
                    ),
                    // Actions
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                        onPressed: () => _removeDocument(index),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionNotesCard(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _notesController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: l.sessionNotesLabel,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _overrideReasonController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: l.overrideReasonLabel,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequiredBadge(String req, AppLocalizations l) {
    Color bg = Colors.grey.shade200;
    Color fg = Colors.grey.shade800;
    String label = l.reqBadgeNo;
    if (req == 'Yes') {
      bg = Colors.red.shade50;
      fg = Colors.red.shade700;
      label = l.reqBadgeYes;
    } else if (req == 'Conditional') {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade800;
      label = l.reqBadgeConditional;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatusBadge(String status, AppLocalizations l) {
    Color bg = Colors.grey.shade100;
    Color fg = Colors.grey.shade700;
    switch (status) {
      case 'Verified':
      case 'FULLY_VERIFIED':
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        break;
      case 'Received':
      case 'FULLY_RECEIVED':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
        break;
      case 'In Transit':
      case 'PARTIALLY_RECEIVED':
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
        break;
      case 'Discrepant':
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        break;
      case 'DRAFT':
      case 'Pending':
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade700;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(_getStatusLabel(status, l), style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildActionToolbar(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : () => _handleSaveSession(isConfirmComplete: false),
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: Text(l.saveDraftSessionBtn),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.charcoal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : () => _handleSaveSession(isConfirmComplete: true),
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: Text(l.completeCollectionBtn),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27AE60),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _isExporting ? null : _handleExportExcel,
                  icon: const Icon(Icons.table_chart, size: 18, color: Color(0xFF27AE60)),
                  label: Text(l.exportExcelBtn, style: const TextStyle(color: Color(0xFF27AE60), fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF27AE60)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrySection(AppLocalizations l, AsyncValue<List<OriginalDocumentsCollectionSessionModel>> sessionsAsync) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history_edu_outlined, color: AppTheme.cobalt, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      l.collectionRegistryHeader,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.charcoal),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _registrySearchController,
                        decoration: InputDecoration(
                          hintText: l.searchRegistryHint,
                          prefixIcon: const Icon(Icons.search, size: 18),
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          ref.read(originalDocumentsSessionsProvider.notifier).fetchSessions(
                                search: val,
                                status: _registryStatusFilter,
                              );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<String>(
                      value: _registryStatusFilter,
                      items: ['All', 'DRAFT', 'PARTIALLY_RECEIVED', 'FULLY_RECEIVED', 'FULLY_VERIFIED']
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(_getRegistryStatusFilterLabel(s, l), style: const TextStyle(fontSize: 12)),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _registryStatusFilter = val);
                          ref.read(originalDocumentsSessionsProvider.notifier).fetchSessions(
                                search: _registrySearchController.text,
                                status: val,
                              );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          sessionsAsync.when(
            data: (sessions) {
              if (sessions.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  child: Text(l.noRegisteredSessionsFound, style: TextStyle(color: Colors.grey.shade600)),
                );
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF2F4F4)),
                  headingTextStyle: const TextStyle(color: AppTheme.charcoal, fontWeight: FontWeight.bold, fontSize: 12),
                  columns: [
                    DataColumn(label: Text(l.colSessionCode)),
                    DataColumn(label: Text(l.colImportFile)),
                    DataColumn(label: Text(l.colAcidNumber)),
                    DataColumn(label: Text(l.colSupplierName)),
                    DataColumn(label: Text(l.colTotalDocs)),
                    DataColumn(label: Text(l.colReceivedDocs)),
                    DataColumn(label: Text(l.colVerifiedDocs)),
                    DataColumn(label: Text(l.colCompletionPercentage)),
                    DataColumn(label: Text(l.colDocStatus)),
                    DataColumn(label: Text(l.colUpdatedAt)),
                  ],
                  rows: sessions.map((s) {
                    return DataRow(
                      cells: [
                        DataCell(Text(s.collectionCode, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(s.importFileCode)),
                        DataCell(Text(s.acidNumber ?? '—')),
                        DataCell(Text(s.supplierName ?? '—')),
                        DataCell(Text('${s.totalDocumentsCount}')),
                        DataCell(Text('${s.receivedDocumentsCount}')),
                        DataCell(Text('${s.verifiedDocumentsCount}')),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: s.completionPercentage == 100 ? Colors.green.shade100 : Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('${s.completionPercentage}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: s.completionPercentage == 100 ? Colors.green.shade800 : Colors.amber.shade900,
                                )),
                          ),
                        ),
                        DataCell(_buildStatusBadge(s.status, l)),
                        DataCell(Text(_formatDateTime(s.updatedAt))),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text(l.errorFetchingRegistry(e), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
