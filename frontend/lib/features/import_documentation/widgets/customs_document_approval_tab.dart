import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/copyable_data_helper.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../models/docs_customs_approval_model.dart';
import '../providers/docs_customs_approval_provider.dart';
import '../screens/central_docs_archive_screen.dart';

class CustomsDocumentApprovalTab extends ConsumerStatefulWidget {
  final int? initialImportFileId;

  const CustomsDocumentApprovalTab({super.key, this.initialImportFileId});

  @override
  ConsumerState<CustomsDocumentApprovalTab> createState() => _CustomsDocumentApprovalTabState();
}

class _CustomsDocumentApprovalTabState extends ConsumerState<CustomsDocumentApprovalTab> {
  int? _selectedImportFileId;
  CrossDocumentMatrixResultModel? _matrixResult;
  bool _isRunningMatrixCheck = false;
  String _selectedStatusFilter = 'All';
  int _activeViewIndex = 0; // 0: Dual-Tier Sign-off & Audit, 1: Central Archive & Rectifications Hub

  @override
  void initState() {
    super.initState();
    _selectedImportFileId = widget.initialImportFileId;
    Future.microtask(() {
      _refresh();
    });
  }

  @override
  void didUpdateWidget(covariant CustomsDocumentApprovalTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialImportFileId != oldWidget.initialImportFileId &&
        widget.initialImportFileId != null) {
      setState(() {
        _selectedImportFileId = widget.initialImportFileId;
        _matrixResult = null;
      });
      _refresh();
    }
  }

  Future<void> _refresh() async {
    if (!ref.read(importFilesProvider).isLoading) {
      await ref.read(importFilesProvider.notifier).fetchImportFiles();
    }
    final files = ref.read(importFilesProvider).valueOrNull ?? [];
    if (_selectedImportFileId == null && files.isNotEmpty && mounted) {
      setState(() {
        _selectedImportFileId = files.first.importFileId;
      });
    }
    if (!ref.read(docsCustomsApprovalProvider).isLoading) {
      ref.read(docsCustomsApprovalProvider.notifier).fetchApprovals(
            importFileId: _selectedImportFileId,
            overallStatus: _selectedStatusFilter == 'All' ? null : _selectedStatusFilter,
          );
    }
    if (!ref.read(discrepancyTicketsProvider).isLoading) {
      ref.read(discrepancyTicketsProvider.notifier).fetchTickets(
            importFileId: _selectedImportFileId,
          );
    }
  }

  Future<void> _handleRunMatrixCheck() async {
    if (_selectedImportFileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.customsApprovalSelectFileForMatrixWarning)),
      );
      return;
    }

    setState(() => _isRunningMatrixCheck = true);
    try {
      final res = await ref.read(docsCustomsApprovalProvider.notifier).runMatrixCheck(_selectedImportFileId!);
      if (!mounted) return;
      setState(() => _matrixResult = res);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.customsApprovalMatrixCheckCompleted(
            _getLocalizedCompliance(res.overallCompliance, context.l10n),
          )),
          backgroundColor: res.overallCompliance == 'Fully Compliant' ? AppTheme.emerald : AppTheme.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.customsApprovalMatrixCheckFailed(e.toString())), backgroundColor: AppTheme.crimson),
      );
    } finally {
      if (mounted) {
        setState(() => _isRunningMatrixCheck = false);
      }
    }
  }

  Future<void> _handleAutoGenerate() async {
    if (_selectedImportFileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.customsApprovalSelectFileWarning)),
      );
      return;
    }

    try {
      await ref.read(docsCustomsApprovalProvider.notifier).autoGenerateChecklist(_selectedImportFileId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.customsApprovalStandardListGeneratedSuccess), backgroundColor: AppTheme.emerald),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.customsApprovalGenerateFailed(e.toString())), backgroundColor: AppTheme.crimson),
      );
    }
  }

  void _showCommercialReviewDialog(CustomsDocumentApprovalModel item) {
    showDialog(
      context: context,
      builder: (c) => _CommercialReviewDialog(item: item, importFileId: _selectedImportFileId),
    );
  }

  void _showCustomsBrokerReviewDialog(CustomsDocumentApprovalModel item) {
    showDialog(
      context: context,
      builder: (c) => _CustomsBrokerReviewDialog(item: item, importFileId: _selectedImportFileId),
    );
  }

  void _showRaiseTicketDialog([CustomsDocumentApprovalModel? item]) {
    if (_selectedImportFileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.customsApprovalSelectFileForTicketWarning)),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (c) => _RaiseTicketDialog(
        importFileId: _selectedImportFileId!,
        approvalItem: item,
      ),
    );
  }

  void _showResolveTicketDialog(DiscrepancyRectificationTicketModel ticket) {
    showDialog(
      context: context,
      builder: (c) => _ResolveTicketDialog(ticket: ticket, importFileId: _selectedImportFileId),
    );
  }

  static String _getLocalizedDocType(String docType, AppLocalizations l) {
    switch (docType) {
      case 'Commercial Invoice':
        return l.customsApprovalDocCommercialInvoice;
      case 'Packing List':
        return l.customsApprovalDocPackingList;
      case 'Bill of Lading':
        return l.customsApprovalDocBillOfLading;
      case 'Certificate of Origin':
        return l.customsApprovalDocCertificateOfOrigin;
      case 'EUR.1':
        return l.customsApprovalDocEur1;
      case 'Inspection Certificate':
        return l.customsApprovalDocInspectionCertificate;
      case 'Bank Form 4':
        return l.customsApprovalDocBankForm4;
      case 'Proforma Invoice':
        return l.customsApprovalDocProformaInvoice;
      default:
        return docType;
    }
  }

  static String _getLocalizedOverallStatus(String status, AppLocalizations l) {
    switch (status) {
      case 'Approved for Clearance':
        return l.customsApprovalStatusApprovedForClearance;
      case 'Rectification Required':
        return l.customsApprovalStatusRectificationRequired;
      case 'Conditionally Approved':
        return l.customsApprovalStatusConditionallyApproved;
      case 'Under Review':
        return l.customsApprovalStatusUnderReview;
      case 'Pending Review':
        return l.customsApprovalStatusPendingReview;
      case 'Draft':
        return l.customsApprovalStatusDraft;
      case 'Rejected':
        return l.customsApprovalStatusRejected;
      case 'Approved':
        return l.customsApprovalStatusApproved;
      case 'Pending':
        return l.customsApprovalStatusPending;
      default:
        return status;
    }
  }

  static String _getLocalizedCommercialStatus(String status, AppLocalizations l) {
    switch (status) {
      case 'Approved':
        return l.customsApprovalStatusApproved;
      case 'Under Review':
        return l.customsApprovalStatusUnderReview;
      case 'Rejected':
        return l.customsApprovalStatusRejected;
      case 'Pending':
        return l.customsApprovalStatusPending;
      default:
        return status;
    }
  }

  static String _getLocalizedBrokerStatus(String status, AppLocalizations l) {
    switch (status) {
      case 'Approved':
        return l.customsApprovalStatusApproved;
      case 'Conditionally Approved':
        return l.customsApprovalStatusConditionallyApproved;
      case 'Rejected':
        return l.customsApprovalStatusRejected;
      case 'Pending':
        return l.customsApprovalStatusPending;
      default:
        return status;
    }
  }

  static String _getLocalizedSeverity(String severity, AppLocalizations l) {
    switch (severity) {
      case 'Critical':
        return l.customsApprovalSevCriticalBadge;
      case 'Major':
        return l.customsApprovalSevMajorBadge;
      case 'Minor':
        return l.customsApprovalSevMinorBadge;
      default:
        return severity;
    }
  }

  static String _getLocalizedTicketStatus(String status, AppLocalizations l) {
    switch (status) {
      case 'Open':
        return l.customsApprovalTicketStatusOpen;
      case 'Resolved':
        return l.customsApprovalStatusResolved;
      case 'Waived':
        return l.customsApprovalStatusWaived;
      case 'Closed':
        return l.customsApprovalStatusClosed;
      default:
        return status;
    }
  }

  static String _getLocalizedCompliance(String compliance, AppLocalizations l) {
    switch (compliance) {
      case 'Fully Compliant':
        return l.customsApprovalComplianceFullyCompliant;
      case 'Non-Compliant':
        return l.customsApprovalComplianceNonCompliant;
      case 'Discrepancies Found':
        return l.customsApprovalComplianceDiscrepancies;
      case 'Critical Blocker':
        return l.customsApprovalComplianceCriticalBlocker;
      default:
        return compliance;
    }
  }

  @override
  Widget build(BuildContext context) {
    final importFiles = ref.watch(importFilesProvider).valueOrNull ?? [];
    final approvalsState = ref.watch(docsCustomsApprovalProvider);
    final ticketsState = ref.watch(discrepancyTicketsProvider);

    return Column(
      children: [
        // --- Control Toolbar ---
        Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(
                    width: 320,
                    child: SearchableDropdownField<int>(
                      value: _selectedImportFileId,
                      labelText: context.l10n.customsApprovalImportFileLabel,
                      searchHintText: context.l10n.customsApprovalSearchFileHint,
                      items: importFiles.map((f) {
                        return SearchableDropdownItem(
                          value: f.importFileId,
                          label: '${f.primaryNameWithCode} - ${f.companyName} (${f.supplierName})',
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedImportFileId = val;
                          _matrixResult = null;
                        });
                        _refresh();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.cobalt,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onPressed: _isRunningMatrixCheck ? null : _handleRunMatrixCheck,
                    icon: _isRunningMatrixCheck
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.auto_awesome),
                    label: Text(context.l10n.customsApprovalRunAiMatrixButton),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.charcoal,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    onPressed: _handleAutoGenerate,
                    icon: const Icon(Icons.playlist_add_check),
                    label: Text(context.l10n.customsApprovalAutoGenerateStandardListButton),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    onPressed: () => _showRaiseTicketDialog(),
                    icon: const Icon(Icons.report_problem_outlined),
                    label: Text(context.l10n.customsApprovalRaiseTicketButton),
                  ),
                  const SizedBox(width: 16),
                  const VerticalDivider(width: 1, thickness: 1),
                  const SizedBox(width: 12),
                  // Status Filter Dropdown
                  DropdownButton<String>(
                    value: _selectedStatusFilter,
                    underline: const SizedBox.shrink(),
                    icon: const Icon(Icons.filter_list, size: 18, color: AppTheme.charcoal),
                    borderRadius: BorderRadius.circular(8),
                    items: [
                      DropdownMenuItem(value: 'All', child: Text(context.l10n.customsApprovalFilterAll)),
                      DropdownMenuItem(value: 'Pending', child: Text(context.l10n.customsApprovalFilterPending)),
                      DropdownMenuItem(value: 'Approved', child: Text(context.l10n.customsApprovalFilterApproved)),
                      DropdownMenuItem(value: 'Rejected', child: Text(context.l10n.customsApprovalFilterRejected)),
                      DropdownMenuItem(value: 'Discrepancy', child: Text(context.l10n.customsApprovalFilterDiscrepancy)),
                    ],
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() => _selectedStatusFilter = val);
                      _refresh();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),

        // --- Sub-View Switcher Bar ---
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  avatar: Icon(Icons.verified_user, size: 16, color: _activeViewIndex == 0 ? Colors.white : AppTheme.cobalt),
                  label: Text(context.l10n.customsApprovalTabDualSignoff, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  selected: _activeViewIndex == 0,
                  selectedColor: AppTheme.cobalt,
                  labelStyle: TextStyle(color: _activeViewIndex == 0 ? Colors.white : AppTheme.charcoal),
                  onSelected: (selected) {
                    if (selected) setState(() => _activeViewIndex = 0);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  avatar: Icon(Icons.inventory_2_outlined, size: 16, color: _activeViewIndex == 1 ? Colors.white : AppTheme.emerald),
                  label: Text(context.l10n.customsApprovalTabCentralArchive, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  selected: _activeViewIndex == 1,
                  selectedColor: AppTheme.emerald,
                  labelStyle: TextStyle(color: _activeViewIndex == 1 ? Colors.white : AppTheme.charcoal),
                  onSelected: (selected) {
                    if (selected) setState(() => _activeViewIndex = 1);
                  },
                ),
              ],
            ),
          ),
        ),

        // --- Live Matrix Banner (if available and in view 0) ---
        if (_activeViewIndex == 0 && _matrixResult != null)
          SelectionArea(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _matrixResult!.overallCompliance == 'Fully Compliant'
                    ? AppTheme.emerald.withOpacity(0.12)
                    : AppTheme.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _matrixResult!.overallCompliance == 'Fully Compliant'
                      ? AppTheme.emerald
                      : AppTheme.orange,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _matrixResult!.overallCompliance == 'Fully Compliant'
                        ? Icons.verified
                        : Icons.warning_amber_rounded,
                    color: _matrixResult!.overallCompliance == 'Fully Compliant'
                        ? AppTheme.emerald
                        : AppTheme.orange,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CopyableText(
                          context.l10n.customsApprovalMatrixComplianceResult(
                            _getLocalizedCompliance(_matrixResult!.overallCompliance, context.l10n),
                            _matrixResult!.passedChecks,
                            _matrixResult!.totalChecks,
                          ),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _matrixResult!.overallCompliance == 'Fully Compliant'
                                ? AppTheme.emerald
                                : AppTheme.orange,
                          ),
                          isSelectable: false,
                        ),
                        if (_matrixResult!.recommendations.isNotEmpty)
                          CopyableText(
                            context.l10n.customsApprovalMatrixRecommendations(_matrixResult!.recommendations.join(' | ')),
                            style: const TextStyle(fontSize: 11, color: Colors.black87),
                            isSelectable: false,
                          ),
                      ],
                    ),
                  ),
                  CopyableText(
                    context.l10n.customsApprovalMatrixOpenTicketsCount(_matrixResult!.openTicketsCount),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    isSelectable: false,
                  ),
                ],
              ),
            ),
          ),

        // --- Main Workspace: View 0 (Split Matrix) vs View 1 (Central Archive & Rectifications) ---
        if (_activeViewIndex == 1)
          Expanded(
            child: CentralDocsArchiveScreen(
              initialImportFileId: _selectedImportFileId,
              isEmbedded: true,
            ),
          )
        else
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Left Column: Dual-Tier Approvals ---
                  Expanded(
                    flex: 3,
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: SelectionArea(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            Row(
                              children: [
                                const Icon(Icons.verified_user, color: AppTheme.cobalt),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    context.l10n.customsApprovalDualTierHeader,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.refresh, size: 20),
                                  onPressed: _refresh,
                                  tooltip: context.l10n.refresh,
                                ),
                              ],
                            ),
                            const Divider(),
                            Expanded(
                              child: approvalsState.when(
                                loading: () => const Center(child: CircularProgressIndicator()),
                                error: (e, _) => Center(child: Text(context.l10n.customsApprovalError(e.toString()), style: const TextStyle(color: Colors.red))),
                                data: (approvals) {
                                  if (approvals.isEmpty) {
                                    return Center(
                                      child: Text(context.l10n.customsApprovalNoDocuments),
                                    );
                                  }
                                  return ListView.separated(
                                    itemCount: approvals.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final item = approvals[index];
                                      return _buildApprovalRow(item);
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // --- Right Column: Matrix Checks & Discrepancy Tickets ---
                Expanded(
                  flex: 2,
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: SelectionArea(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.confirmation_number_outlined, color: AppTheme.orange),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    context.l10n.customsApprovalTicketsHeader,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.add, size: 16),
                                  label: Text(context.l10n.customsApprovalNewTicketButton),
                                  onPressed: () => _showRaiseTicketDialog(),
                                ),
                              ],
                            ),
                            const Divider(),
                            Expanded(
                              child: ticketsState.when(
                                loading: () => const Center(child: CircularProgressIndicator()),
                                error: (e, _) => Center(child: Text(context.l10n.customsApprovalError(e.toString()), style: const TextStyle(color: Colors.red))),
                                data: (tickets) {
                                  if (tickets.isEmpty) {
                                    return Center(
                                      child: Text(context.l10n.customsApprovalNoTickets),
                                    );
                                  }
                                  return ListView.separated(
                                    itemCount: tickets.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final t = tickets[index];
                                      return _buildTicketCard(t);
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApprovalRow(CustomsDocumentApprovalModel item) {
    final l = context.l10n;
    Color overallColor = AppTheme.orange;
    if (item.overallStatus == 'Approved for Clearance') overallColor = AppTheme.emerald;
    if (item.overallStatus == 'Rectification Required' || item.overallStatus == 'Rejected') overallColor = AppTheme.crimson;

    final localizedDocType = _getLocalizedDocType(item.documentType, l);
    final localizedOverallStatus = _getLocalizedOverallStatus(item.overallStatus, l);
    final localizedCommercialStatus = _getLocalizedCommercialStatus(item.commercialStatus, l);
    final localizedBrokerStatus = _getLocalizedBrokerStatus(item.customsStatus, l);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.cobalt.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: CopyableText(
                    localizedDocType,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.cobalt),
                    overflow: TextOverflow.ellipsis,
                    isSelectable: false,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (item.documentReferenceNo != null)
                Flexible(
                  child: CopyableText(
                    l.customsApprovalDocRef(item.documentReferenceNo!),
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                    isSelectable: false,
                  ),
                ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: overallColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: overallColor.withOpacity(0.5)),
                ),
                child: CopyableText(
                  localizedOverallStatus,
                  style: TextStyle(color: overallColor, fontWeight: FontWeight.bold, fontSize: 11),
                  isSelectable: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              // Tier 1: Commercial Review
              InkWell(
                onTap: () => _showCommercialReviewDialog(item),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: item.commercialStatus == 'Approved'
                        ? AppTheme.emerald.withOpacity(0.08)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: item.commercialStatus == 'Approved' ? AppTheme.emerald : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.commercialStatus == 'Approved' ? Icons.check_circle : Icons.person_outline,
                        size: 16,
                        color: item.commercialStatus == 'Approved' ? AppTheme.emerald : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l.customsApprovalCommercialReviewStatus(localizedCommercialStatus),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: item.commercialStatus == 'Approved' ? AppTheme.emerald : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Tier 2: Customs Broker Sign-off
              InkWell(
                onTap: () => _showCustomsBrokerReviewDialog(item),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: item.customsStatus == 'Approved'
                        ? AppTheme.emerald.withOpacity(0.08)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: item.customsStatus == 'Approved' ? AppTheme.emerald : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.customsStatus == 'Approved' ? Icons.verified : Icons.gavel,
                        size: 16,
                        color: item.customsStatus == 'Approved' ? AppTheme.emerald : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l.customsApprovalBrokerReviewStatus(localizedBrokerStatus),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: item.customsStatus == 'Approved' ? AppTheme.emerald : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(DiscrepancyRectificationTicketModel ticket) {
    final l = context.l10n;
    final isResolved = ticket.status == 'Resolved';
    final localizedSeverity = _getLocalizedSeverity(ticket.severity, l);
    final localizedTicketStatus = _getLocalizedTicketStatus(ticket.status, l);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isResolved ? AppTheme.emerald.withOpacity(0.06) : AppTheme.orange.withOpacity(0.06),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isResolved ? AppTheme.emerald.withOpacity(0.4) : AppTheme.orange.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                CopyableText(
                  ticket.ticketCode,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal),
                  isSelectable: false,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: ticket.severity == 'Critical' ? AppTheme.crimson : AppTheme.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: CopyableText(
                    localizedSeverity,
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    isSelectable: false,
                  ),
                ),
                CopyableText(
                  localizedTicketStatus,
                  style: TextStyle(
                    color: isResolved ? AppTheme.emerald : AppTheme.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  isSelectable: false,
                ),
              ],
            ),
            const SizedBox(height: 4),
            CopyableText(
              ticket.description,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              isSelectable: false,
            ),
            if (ticket.expectedValue != null || ticket.foundValue != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: CopyableText(
                  l.customsApprovalTicketExpectedVsFound(ticket.expectedValue ?? "-", ticket.foundValue ?? "-"),
                  style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                  isSelectable: false,
                ),
              ),
            if (!isResolved)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  icon: const Icon(Icons.check_circle_outline, size: 14),
                  label: Text(l.customsApprovalResolveTicketButton, style: const TextStyle(fontSize: 11)),
                  onPressed: () => _showResolveTicketDialog(ticket),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// --- Commercial Review Dialog ---
class _CommercialReviewDialog extends StatefulWidget {
  final CustomsDocumentApprovalModel item;
  final int? importFileId;

  const _CommercialReviewDialog({required this.item, this.importFileId});

  @override
  State<_CommercialReviewDialog> createState() => _CommercialReviewDialogState();
}

class _CommercialReviewDialogState extends State<_CommercialReviewDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _selectedStatus = 'Approved';
  bool _isSubmitting = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _nameCtrl.text = context.l10n.customsApprovalDefaultCommercialReviewer;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      return AlertDialog(
        title: Text(context.l10n.customsApprovalCommercialDialogTitle(
          _CustomsDocumentApprovalTabState._getLocalizedDocType(widget.item.documentType, context.l10n),
        )),
        content: Form(
          key: _formKey,
          child: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(labelText: context.l10n.customsApprovalCommercialReviewerLabel, border: const OutlineInputBorder()),
                  validator: (v) => v == null || v.trim().isEmpty ? context.l10n.customsApprovalRequiredField : null,
                ),
                const SizedBox(height: 12),
                SearchableDropdownField<String>(
                  value: _selectedStatus,
                  labelText: context.l10n.customsApprovalCommercialDecisionLabel,
                  searchHintText: context.l10n.customsApprovalSelectDecisionHint,
                  items: [
                    SearchableDropdownItem(value: 'Approved', label: context.l10n.customsApprovalDecisionCommercialApproved),
                    SearchableDropdownItem(value: 'Under Review', label: context.l10n.customsApprovalDecisionCommercialUnderReview),
                    SearchableDropdownItem(value: 'Rejected', label: context.l10n.customsApprovalDecisionCommercialRejected),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedStatus = val);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: context.l10n.customsApprovalCommercialNotesLabel, border: const OutlineInputBorder()),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, foregroundColor: Colors.white),
            onPressed: _isSubmitting
                ? null
                : () async {
                    if (!_formKey.currentState!.validate()) return;
                    setState(() => _isSubmitting = true);
                    try {
                      await ref.read(docsCustomsApprovalProvider.notifier).submitCommercialReview(
                            approvalId: widget.item.approvalId,
                            reviewerName: _nameCtrl.text.trim(),
                            status: _selectedStatus,
                            notes: _notesCtrl.text.trim(),
                            importFileId: widget.importFileId,
                          );
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.l10n.customsApprovalError(e.toString())), backgroundColor: AppTheme.crimson),
                        );
                      }
                    } finally {
                      setState(() => _isSubmitting = false);
                    }
                  },
            child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : Text(context.l10n.customsApprovalSaveApprovalButton),
          ),
        ],
      );
    });
  }
}

// --- Customs Broker Review Dialog ---
class _CustomsBrokerReviewDialog extends StatefulWidget {
  final CustomsDocumentApprovalModel item;
  final int? importFileId;

  const _CustomsBrokerReviewDialog({required this.item, this.importFileId});

  @override
  State<_CustomsBrokerReviewDialog> createState() => _CustomsBrokerReviewDialogState();
}

class _CustomsBrokerReviewDialogState extends State<_CustomsBrokerReviewDialog> {
  final _formKey = GlobalKey<FormState>();
  final _brokerCtrl = TextEditingController();
  final _reviewerCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _selectedStatus = 'Approved';
  bool _isSubmitting = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _brokerCtrl.text = context.l10n.customsApprovalDefaultBrokerOffice;
      _reviewerCtrl.text = context.l10n.customsApprovalDefaultLegalOfficer;
    }
  }

  @override
  void dispose() {
    _brokerCtrl.dispose();
    _reviewerCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      return AlertDialog(
        title: Text(context.l10n.customsApprovalBrokerDialogTitle(
          _CustomsDocumentApprovalTabState._getLocalizedDocType(widget.item.documentType, context.l10n),
        )),
        content: Form(
          key: _formKey,
          child: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _brokerCtrl,
                  decoration: InputDecoration(labelText: context.l10n.customsApprovalBrokerOfficeLabel, border: const OutlineInputBorder()),
                  validator: (v) => v == null || v.trim().isEmpty ? context.l10n.customsApprovalRequiredField : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _reviewerCtrl,
                  decoration: InputDecoration(labelText: context.l10n.customsApprovalBrokerReviewerNameLabel, border: const OutlineInputBorder()),
                  validator: (v) => v == null || v.trim().isEmpty ? context.l10n.customsApprovalRequiredField : null,
                ),
                const SizedBox(height: 12),
                SearchableDropdownField<String>(
                  value: _selectedStatus,
                  labelText: context.l10n.customsApprovalBrokerDecisionLabel,
                  searchHintText: context.l10n.customsApprovalSelectDecisionHint,
                  items: [
                    SearchableDropdownItem(value: 'Approved', label: context.l10n.customsApprovalDecisionBrokerApproved),
                    SearchableDropdownItem(value: 'Conditionally Approved', label: context.l10n.customsApprovalDecisionBrokerConditionallyApproved),
                    SearchableDropdownItem(value: 'Rejected', label: context.l10n.customsApprovalDecisionBrokerRejected),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedStatus = val);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: context.l10n.customsApprovalBrokerNotesLabel, border: const OutlineInputBorder()),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white),
            onPressed: _isSubmitting
                ? null
                : () async {
                    if (!_formKey.currentState!.validate()) return;
                    setState(() => _isSubmitting = true);
                    try {
                      await ref.read(docsCustomsApprovalProvider.notifier).submitCustomsBrokerReview(
                            approvalId: widget.item.approvalId,
                            brokerName: _brokerCtrl.text.trim(),
                            reviewerName: _reviewerCtrl.text.trim(),
                            status: _selectedStatus,
                            notes: _notesCtrl.text.trim(),
                            importFileId: widget.importFileId,
                          );
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.l10n.customsApprovalError(e.toString())), backgroundColor: AppTheme.crimson),
                        );
                      }
                    } finally {
                      setState(() => _isSubmitting = false);
                    }
                  },
            child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : Text(context.l10n.customsApprovalBrokerSaveStampButton),
          ),
        ],
      );
    });
  }
}

// --- Raise Ticket Dialog ---
class _RaiseTicketDialog extends StatefulWidget {
  final int importFileId;
  final CustomsDocumentApprovalModel? approvalItem;

  const _RaiseTicketDialog({required this.importFileId, this.approvalItem});

  @override
  State<_RaiseTicketDialog> createState() => _RaiseTicketDialogState();
}

class _RaiseTicketDialogState extends State<_RaiseTicketDialog> {
  final _formKey = GlobalKey<FormState>();
  String _issueCategory = 'HS Code Mismatch';
  String _severity = 'Major';
  final _descCtrl = TextEditingController();
  final _expectedCtrl = TextEditingController();
  final _foundCtrl = TextEditingController();
  final _actionCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    _expectedCtrl.dispose();
    _foundCtrl.dispose();
    _actionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      return AlertDialog(
        title: Text(context.l10n.customsApprovalRaiseTicketDialogTitle),
        content: Form(
          key: _formKey,
          child: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SearchableDropdownField<String>(
                    value: _issueCategory,
                    labelText: context.l10n.customsApprovalIssueCategoryLabel,
                    searchHintText: context.l10n.customsApprovalSelectCategoryHint,
                    items: [
                      SearchableDropdownItem(value: 'HS Code Mismatch', label: context.l10n.customsApprovalCatHsMismatch),
                      SearchableDropdownItem(value: 'Weight Discrepancy', label: context.l10n.customsApprovalCatWeightDiscrepancy),
                      SearchableDropdownItem(value: 'CBM Discrepancy', label: context.l10n.customsApprovalCatCbmDiscrepancy),
                      SearchableDropdownItem(value: 'Value Mismatch', label: context.l10n.customsApprovalCatValueMismatch),
                      SearchableDropdownItem(value: 'Missing ACID', label: context.l10n.customsApprovalCatMissingAcid),
                      SearchableDropdownItem(value: 'Incoterm Conflict', label: context.l10n.customsApprovalCatIncotermConflict),
                      SearchableDropdownItem(value: 'Other', label: context.l10n.customsApprovalCatOther),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _issueCategory = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  SearchableDropdownField<String>(
                    value: _severity,
                    labelText: context.l10n.customsApprovalSeverityLabel,
                    searchHintText: context.l10n.customsApprovalSelectSeverityHint,
                    items: [
                      SearchableDropdownItem(value: 'Critical', label: context.l10n.customsApprovalSevCritical),
                      SearchableDropdownItem(value: 'Major', label: context.l10n.customsApprovalSevMajor),
                      SearchableDropdownItem(value: 'Minor', label: context.l10n.customsApprovalSevMinor),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _severity = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(labelText: context.l10n.customsApprovalIssueDescLabel, border: const OutlineInputBorder()),
                    validator: (v) => v == null || v.trim().length < 5 ? context.l10n.customsApprovalIssueDescMinLength : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _expectedCtrl,
                          decoration: InputDecoration(labelText: context.l10n.customsApprovalExpectedValueLabel, border: const OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _foundCtrl,
                          decoration: InputDecoration(labelText: context.l10n.customsApprovalFoundValueLabel, border: const OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _actionCtrl,
                    decoration: InputDecoration(labelText: context.l10n.customsApprovalSupplierActionLabel, border: const OutlineInputBorder()),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.orange, foregroundColor: Colors.white),
            onPressed: _isSubmitting
                ? null
                : () async {
                    if (!_formKey.currentState!.validate()) return;
                    setState(() => _isSubmitting = true);
                    try {
                      await ref.read(discrepancyTicketsProvider.notifier).createTicket({
                        'import_file_id': widget.importFileId,
                        'approval_id': widget.approvalItem?.approvalId,
                        'issue_category': _issueCategory,
                        'severity': _severity,
                        'description': _descCtrl.text.trim(),
                        'expected_value': _expectedCtrl.text.trim(),
                        'found_value': _foundCtrl.text.trim(),
                        'supplier_action_required': _actionCtrl.text.trim(),
                      });
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.l10n.customsApprovalError(e.toString())), backgroundColor: AppTheme.crimson),
                        );
                      }
                    } finally {
                      setState(() => _isSubmitting = false);
                    }
                  },
            child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : Text(context.l10n.customsApprovalCreateTicketSubmitButton),
          ),
        ],
      );
    });
  }
}

// --- Resolve Ticket Dialog ---
class _ResolveTicketDialog extends StatefulWidget {
  final DiscrepancyRectificationTicketModel ticket;
  final int? importFileId;

  const _ResolveTicketDialog({required this.ticket, this.importFileId});

  @override
  State<_ResolveTicketDialog> createState() => _ResolveTicketDialogState();
}

class _ResolveTicketDialogState extends State<_ResolveTicketDialog> {
  final _formKey = GlobalKey<FormState>();
  final _responseCtrl = TextEditingController();
  final _resolverCtrl = TextEditingController();
  String _newStatus = 'Resolved';
  bool _isSubmitting = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _resolverCtrl.text = context.l10n.customsApprovalDefaultComplianceOfficer;
    }
  }

  @override
  void dispose() {
    _responseCtrl.dispose();
    _resolverCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      return AlertDialog(
        title: Text(context.l10n.customsApprovalResolveTicketDialogTitle(widget.ticket.ticketCode)),
        content: Form(
          key: _formKey,
          child: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _responseCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: context.l10n.customsApprovalSupplierResponseLabel, border: const OutlineInputBorder()),
                  validator: (v) => v == null || v.trim().isEmpty ? context.l10n.customsApprovalRequiredField : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _resolverCtrl,
                  decoration: InputDecoration(labelText: context.l10n.customsApprovalResolverNameLabel, border: const OutlineInputBorder()),
                  validator: (v) => v == null || v.trim().isEmpty ? context.l10n.customsApprovalRequiredField : null,
                ),
                const SizedBox(height: 12),
                SearchableDropdownField<String>(
                  value: _newStatus,
                  labelText: context.l10n.customsApprovalFinalStatusLabel,
                  searchHintText: context.l10n.customsApprovalSelectStatusHint,
                  items: [
                    SearchableDropdownItem(value: 'Resolved', label: context.l10n.customsApprovalStatusResolved),
                    SearchableDropdownItem(value: 'Waived', label: context.l10n.customsApprovalStatusWaived),
                    SearchableDropdownItem(value: 'Closed', label: context.l10n.customsApprovalStatusClosed),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _newStatus = val);
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white),
            onPressed: _isSubmitting
                ? null
                : () async {
                    if (!_formKey.currentState!.validate()) return;
                    setState(() => _isSubmitting = true);
                    try {
                      await ref.read(discrepancyTicketsProvider.notifier).resolveTicket(
                            widget.ticket.ticketId,
                            {
                              'supplier_response': _responseCtrl.text.trim(),
                              'resolved_by': _resolverCtrl.text.trim(),
                              'new_status': _newStatus,
                            },
                            importFileId: widget.importFileId,
                          );
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.l10n.customsApprovalError(e.toString())), backgroundColor: AppTheme.crimson),
                        );
                      }
                    } finally {
                      setState(() => _isSubmitting = false);
                    }
                  },
            child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : Text(context.l10n.customsApprovalConfirmResolveTicketButton),
          ),
        ],
      );
    });
  }
}
