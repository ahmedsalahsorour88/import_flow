import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../models/docs_customs_approval_model.dart';
import '../providers/docs_customs_approval_provider.dart';

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
    await ref.read(importFilesProvider.notifier).fetchImportFiles();
    final files = ref.read(importFilesProvider).value ?? [];
    if (_selectedImportFileId == null && files.isNotEmpty && mounted) {
      setState(() {
        _selectedImportFileId = files.first.importFileId;
      });
    }
    ref.read(docsCustomsApprovalProvider.notifier).fetchApprovals(
          importFileId: _selectedImportFileId,
          overallStatus: _selectedStatusFilter == 'All' ? null : _selectedStatusFilter,
        );
    ref.read(discrepancyTicketsProvider.notifier).fetchTickets(
          importFileId: _selectedImportFileId,
        );
  }

  Future<void> _handleRunMatrixCheck() async {
    if (_selectedImportFileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ برجاء اختيار ملف الشحنة أولاً لإجراء الفحص المتقاطع.')),
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
          content: Text('✅ تم الانتهاء من الفحص المتقاطع الآلي: ${res.overallCompliance}'),
          backgroundColor: res.overallCompliance == 'Fully Compliant' ? AppTheme.emerald : AppTheme.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ فشل إجراء الفحص: $e'), backgroundColor: AppTheme.crimson),
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
        const SnackBar(content: Text('⚠️ برجاء اختيار ملف الشحنة أولاً.')),
      );
      return;
    }

    try {
      await ref.read(docsCustomsApprovalProvider.notifier).autoGenerateChecklist(_selectedImportFileId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ تم توليد قائمة مستندات الاعتماد القياسية بنجاح.'), backgroundColor: AppTheme.emerald),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ خطأ أثناء التوليد: $e'), backgroundColor: AppTheme.crimson),
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
        const SnackBar(content: Text('⚠️ برجاء اختيار ملف الشحنة لربط التذكرة.')),
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

  @override
  Widget build(BuildContext context) {
    final importFiles = ref.watch(importFilesProvider).value ?? [];
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
                      labelText: 'ملف الشحنة المستوردة (Import File)',
                      searchHintText: 'ابحث برقم الملف أو اسم الشركة...',
                      items: importFiles.map((f) {
                        final code = f.customFileNumber ?? f.importFileCode;
                        return SearchableDropdownItem(
                          value: f.importFileId,
                          label: '[$code] ${f.companyName} (${f.supplierName})',
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
                    label: const Text('فحص متقاطع ذكي (AI Matrix Audit)'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.charcoal,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    onPressed: _handleAutoGenerate,
                    icon: const Icon(Icons.playlist_add_check),
                    label: const Text('توليد القائمة القياسية'),
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
                    label: const Text('تذكرة استدراك للمورد'),
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
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('الكل (All)')),
                      DropdownMenuItem(value: 'Pending', child: Text('قيد المراجعة (Pending)')),
                      DropdownMenuItem(value: 'Approved', child: Text('معتمد (Approved)')),
                      DropdownMenuItem(value: 'Rejected', child: Text('مرفوض (Rejected)')),
                      DropdownMenuItem(value: 'Discrepancy', child: Text('يوجد فروق (Discrepancy)')),
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

        // --- Live Matrix Banner (if available) ---
        if (_matrixResult != null)
          Container(
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
                      Text(
                        'نتيجة المطابقة المتقاطعة: ${_matrixResult!.overallCompliance} (${_matrixResult!.passedChecks}/${_matrixResult!.totalChecks} مطابق)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _matrixResult!.overallCompliance == 'Fully Compliant'
                              ? AppTheme.emerald
                              : AppTheme.orange,
                        ),
                      ),
                      if (_matrixResult!.recommendations.isNotEmpty)
                        Text(
                          'توصيات الجمارك: ${_matrixResult!.recommendations.join(' | ')}',
                          style: const TextStyle(fontSize: 11, color: Colors.black87),
                        ),
                    ],
                  ),
                ),
                Text(
                  'تذاكر مفتوحة: ${_matrixResult!.openTicketsCount}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),

        // --- Main Workspace: Split View ---
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
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.verified_user, color: AppTheme.cobalt),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'مصفوفة اعتماد المستندات الجمركية (Dual-Tier Sign-off)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh, size: 20),
                                onPressed: _refresh,
                                tooltip: 'تحديث',
                              ),
                            ],
                          ),
                          const Divider(),
                          Expanded(
                            child: approvalsState.when(
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (e, _) => Center(child: Text('خطأ: $e', style: const TextStyle(color: Colors.red))),
                              data: (approvals) {
                                if (approvals.isEmpty) {
                                  return const Center(
                                    child: Text('لا توجد مستندات مسجلة. اضغط "توليد القائمة القياسية" للبدء.'),
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
                const SizedBox(width: 12),

                // --- Right Column: Matrix Checks & Discrepancy Tickets ---
                Expanded(
                  flex: 2,
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.confirmation_number_outlined, color: AppTheme.orange),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'سجل تذاكر الاستدراك والاستفسارات',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('تذكرة جديدة'),
                                onPressed: () => _showRaiseTicketDialog(),
                              ),
                            ],
                          ),
                          const Divider(),
                          Expanded(
                            child: ticketsState.when(
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (e, _) => Center(child: Text('خطأ: $e', style: const TextStyle(color: Colors.red))),
                              data: (tickets) {
                                if (tickets.isEmpty) {
                                  return const Center(
                                    child: Text('لا توجد تذاكر استدراك مفتوحة. كافة المستندات متطابقة.'),
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
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApprovalRow(CustomsDocumentApprovalModel item) {
    Color overallColor = AppTheme.orange;
    if (item.overallStatus == 'Approved for Clearance') overallColor = AppTheme.emerald;
    if (item.overallStatus == 'Rectification Required' || item.overallStatus == 'Rejected') overallColor = AppTheme.crimson;

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
                  child: Text(
                    item.documentType,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.cobalt),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (item.documentReferenceNo != null)
                Flexible(
                  child: Text(
                    'رقم: ${item.documentReferenceNo}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
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
                child: Text(
                  item.overallStatus,
                  style: TextStyle(color: overallColor, fontWeight: FontWeight.bold, fontSize: 11),
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
                        'المراجعة التجارية: ${item.commercialStatus}',
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
                        'اعتماد المخلص الجمركي: ${item.customsStatus}',
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
    final isResolved = ticket.status == 'Resolved';
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
                Text(
                  ticket.ticketCode,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: ticket.severity == 'Critical' ? AppTheme.crimson : AppTheme.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    ticket.severity,
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  ticket.status,
                  style: TextStyle(
                    color: isResolved ? AppTheme.emerald : AppTheme.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              ticket.description,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            if (ticket.expectedValue != null || ticket.foundValue != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'المتوقع: ${ticket.expectedValue ?? "-"} ➔ الوارد بالمسودة: ${ticket.foundValue ?? "-"}',
                  style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                ),
              ),
            if (!isResolved)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  icon: const Icon(Icons.check_circle_outline, size: 14),
                  label: const Text('تسجيل رد المورد / إغلاق التذكرة', style: TextStyle(fontSize: 11)),
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
  final _nameCtrl = TextEditingController(text: 'Commercial Specialist');
  final _notesCtrl = TextEditingController();
  String _selectedStatus = 'Approved';
  bool _isSubmitting = false;

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
        title: Text('المراجعة التجارية: ${widget.item.documentType}'),
        content: Form(
          key: _formKey,
          child: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'اسم المراجع التجاري *', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.trim().isEmpty ? 'الحقل إلزامي' : null,
                ),
                const SizedBox(height: 12),
                SearchableDropdownField<String>(
                  value: _selectedStatus,
                  labelText: 'قرار المراجعة *',
                  searchHintText: 'اختر القرار...',
                  items: const [
                    SearchableDropdownItem(value: 'Approved', label: 'Approved (معتمد تجارياً)'),
                    SearchableDropdownItem(value: 'Under Review', label: 'Under Review (قيد المراجعة)'),
                    SearchableDropdownItem(value: 'Rejected', label: 'Rejected (مرفوض لوجود أخطاء)'),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedStatus = val);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'ملاحظات المراجعة التجارية', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
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
                          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppTheme.crimson),
                        );
                      }
                    } finally {
                      setState(() => _isSubmitting = false);
                    }
                  },
            child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('حفظ الاعتماد'),
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
  final _brokerCtrl = TextEditingController(text: 'Licensed Customs Broker');
  final _reviewerCtrl = TextEditingController(text: 'Legal Officer');
  final _notesCtrl = TextEditingController();
  String _selectedStatus = 'Approved';
  bool _isSubmitting = false;

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
        title: Text('اعتماد المخلص الجمركي: ${widget.item.documentType}'),
        content: Form(
          key: _formKey,
          child: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _brokerCtrl,
                  decoration: const InputDecoration(labelText: 'مكتب / شركة التخليص الجمركي *', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.trim().isEmpty ? 'الحقل إلزامي' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _reviewerCtrl,
                  decoration: const InputDecoration(labelText: 'اسم المراجع القانوني / المخلص *', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.trim().isEmpty ? 'الحقل إلزامي' : null,
                ),
                const SizedBox(height: 12),
                SearchableDropdownField<String>(
                  value: _selectedStatus,
                  labelText: 'قرار المطابقة الجمركية *',
                  searchHintText: 'اختر القرار...',
                  items: const [
                    SearchableDropdownItem(value: 'Approved', label: 'Approved (معتمد للإفراج الجمركي)'),
                    SearchableDropdownItem(value: 'Conditionally Approved', label: 'Conditionally Approved (معتمد بشرط)'),
                    SearchableDropdownItem(value: 'Rejected', label: 'Rejected (مرفوض جمركياً)'),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedStatus = val);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'ملاحظات وتعهدات التخليص', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
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
                          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppTheme.crimson),
                        );
                      }
                    } finally {
                      setState(() => _isSubmitting = false);
                    }
                  },
            child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('اعتماد رسمي وختم'),
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
        title: const Text('إصدار تذكرة استدراك وتعديل للمورد (Rectification Ticket)'),
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
                    labelText: 'تصنيف الخطأ / التناقض *',
                    searchHintText: 'اختر التصنيف...',
                    items: const [
                      SearchableDropdownItem(value: 'HS Code Mismatch', label: 'HS Code Mismatch (عدم تطابق بند التعريفة)'),
                      SearchableDropdownItem(value: 'Weight Discrepancy', label: 'Weight Discrepancy (اختلاف في الأوزان)'),
                      SearchableDropdownItem(value: 'CBM Discrepancy', label: 'CBM Discrepancy (اختلاف الحجم التكعيبي)'),
                      SearchableDropdownItem(value: 'Value Mismatch', label: 'Value/Currency Mismatch (اختلاف القيمة/العملة)'),
                      SearchableDropdownItem(value: 'Missing ACID', label: 'Missing ACID (غياب رقم الـ ACID)'),
                      SearchableDropdownItem(value: 'Incoterm Conflict', label: 'Incoterm Conflict (تعارض شرط الشحن)'),
                      SearchableDropdownItem(value: 'Other', label: 'Other (أخرى)'),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _issueCategory = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  SearchableDropdownField<String>(
                    value: _severity,
                    labelText: 'درجة الخطورة *',
                    searchHintText: 'اختر درجة الخطورة...',
                    items: const [
                      SearchableDropdownItem(value: 'Critical', label: 'Critical (حرج - يمنع الشحن والإفراج)'),
                      SearchableDropdownItem(value: 'Major', label: 'Major (رئيسي - يتطلب تعديل المسودة)'),
                      SearchableDropdownItem(value: 'Minor', label: 'Minor (بسيط - للتنبيه)'),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _severity = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'وصف الخطأ والتناقض بالتفصيل *', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.trim().length < 5 ? 'الوصف يجب أن يكون 5 أحرف على الأقل' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _expectedCtrl,
                          decoration: const InputDecoration(labelText: 'القيمة الصحيحة المطلوبة', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _foundCtrl,
                          decoration: const InputDecoration(labelText: 'القيمة الخاطئة بالمسودة', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _actionCtrl,
                    decoration: const InputDecoration(labelText: 'الإجراء المطلوب من المورد تنفيذه', border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
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
                          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppTheme.crimson),
                        );
                      }
                    } finally {
                      setState(() => _isSubmitting = false);
                    }
                  },
            child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('إصدار التذكرة'),
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
  final _resolverCtrl = TextEditingController(text: 'Compliance Specialist');
  String _newStatus = 'Resolved';
  bool _isSubmitting = false;

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
        title: Text('إغلاق تذكرة الاستدراك: ${widget.ticket.ticketCode}'),
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
                  decoration: const InputDecoration(labelText: 'رد وتعديل المورد *', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.trim().isEmpty ? 'الحقل إلزامي' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _resolverCtrl,
                  decoration: const InputDecoration(labelText: 'اسم المراجع القائم بالإغلاق *', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.trim().isEmpty ? 'الحقل إلزامي' : null,
                ),
                const SizedBox(height: 12),
                SearchableDropdownField<String>(
                  value: _newStatus,
                  labelText: 'الحالة النهائية *',
                  searchHintText: 'اختر الحالة...',
                  items: const [
                    SearchableDropdownItem(value: 'Resolved', label: 'Resolved (تم تصحيح المسودة)'),
                    SearchableDropdownItem(value: 'Waived', label: 'Waived (تم التنازل مع تعهد)'),
                    SearchableDropdownItem(value: 'Closed', label: 'Closed (مغلقة)'),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
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
                          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppTheme.crimson),
                        );
                      }
                    } finally {
                      setState(() => _isSubmitting = false);
                    }
                  },
            child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('تأكيد الإغلاق'),
          ),
        ],
      );
    });
  }
}
