import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../import_files/models/import_file_model.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../../import_files/widgets/import_file_form_dialog.dart';

class SmartCloneShipmentDialog extends ConsumerStatefulWidget {
  final ImportFileModel sourceFile;

  const SmartCloneShipmentDialog({
    super.key,
    required this.sourceFile,
  });

  static Future<void> show(BuildContext context, ImportFileModel sourceFile) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SmartCloneShipmentDialog(sourceFile: sourceFile),
    );
  }

  @override
  ConsumerState<SmartCloneShipmentDialog> createState() => _SmartCloneShipmentDialogState();
}

class _SmartCloneShipmentDialogState extends ConsumerState<SmartCloneShipmentDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _newCodeController;
  late final TextEditingController _newNameController;
  late final TextEditingController _newInvoiceController;
  late final TextEditingController _newFreightCostController;
  late final TextEditingController _notesController;

  bool _copyInvoices = true;
  bool _copyPackingLists = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final src = widget.sourceFile;
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    _newCodeController = TextEditingController(text: '${src.importFileCode}-C$timestamp');
    _newNameController = TextEditingController(
      text: src.notes != null && src.notes!.isNotEmpty
          ? '${src.notes!.split("\n").first} (نسخة جديدة)'
          : '${src.importFileCode} - شحنة جديدة',
    );
    _newInvoiceController = TextEditingController();
    _newFreightCostController = TextEditingController();
    _notesController = TextEditingController(text: 'مستنسخة كقالب من الشحنة: ${src.importFileCode}');
  }

  @override
  void dispose() {
    _newCodeController.dispose();
    _newNameController.dispose();
    _newInvoiceController.dispose();
    _newFreightCostController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleClone({bool openFullForm = false}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final src = widget.sourceFile;
      final payload = {
        'target_import_file_code': _newCodeController.text.trim(),
        'target_custom_file_number': null,
        'copy_invoices_data': _copyInvoices,
        'copy_packing_lists': _copyPackingLists,
        'copy_attachments': false,
        'notes': _notesController.text.trim(),
      };

      // Call clone API through notifier
      final clonedFile = await ref.read(importFilesProvider.notifier).cloneImportFile(
        src.importFileId,
        payload,
      );

      if (!mounted) return;

      Navigator.of(context).pop();

      final clonedCode = clonedFile?.importFileCode ?? _newCodeController.text.trim();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم استنساخ الشحنة بنجاح برقم: $clonedCode',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppTheme.emerald,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (openFullForm && mounted && clonedFile != null) {
        showDialog(
          context: context,
          builder: (ctx) => ImportFileFormDialog(fileToEdit: clonedFile),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final src = widget.sourceFile;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.cobalt.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.copy_rounded, color: AppTheme.cobalt, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.inqCloneDialogTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.charcoal,
                          ),
                        ),
                        Text(
                          'استنساخ الشحنة ${src.importFileCode} كقالب تشغيلي',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Confirmation & Guidance Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.emerald.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.emerald.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: AppTheme.emerald, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'تم استنساخ بيانات الشحنة ${src.importFileCode} بنجاح، يُرجى مراجعة التواريخ والأسعار الجديدة قبل الحفظ.',
                        style: const TextStyle(
                          color: AppTheme.emerald,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.crimson.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.crimson.withOpacity(0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppTheme.crimson, fontSize: 12),
                  ),
                ),
              ],

              // Main Body: 2 Columns (Copied Data Template vs New Input Form)
              Expanded(
                child: Form(
                  key: _formKey,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Column 1: Copied Data Summary (Template Values)
                      Expanded(
                        flex: 4,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ListView(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.lock_outline, size: 16, color: AppTheme.cobalt),
                                  const SizedBox(width: 6),
                                  Text(
                                    l.inqCloneCopiedDataTitle,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppTheme.cobalt,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              _buildSummaryTile('المورد الأجنبي', src.supplierName),
                              _buildSummaryTile('الشركة المستوردة', src.companyName),
                              _buildSummaryTile('بند التعريفة', src.hsCode ?? 'غير محدد'),
                              _buildSummaryTile('تصنيف الصنف', src.productCategory ?? 'عام'),
                              _buildSummaryTile('شرط التسليم', src.incotermCode),
                              _buildSummaryTile('أسلوب الشحن', src.shipmentMode),
                              _buildSummaryTile(
                                'مسار الشحن',
                                '${src.portOfLoading ?? "غير محدد"} → ${src.portOfDischarge ?? "الإسكندرية"}',
                              ),
                              _buildSummaryTile(
                                'الخط الملاحي',
                                src.selectedScenario ?? 'غير محدد',
                              ),
                              const SizedBox(height: 10),
                              const Divider(height: 16),
                              // Options Checkboxes
                              CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                title: const Text('نسخ بنود الفاتورة كأصناف مبدئية', style: TextStyle(fontSize: 12)),
                                value: _copyInvoices,
                                activeColor: AppTheme.cobalt,
                                onChanged: (v) => setState(() => _copyInvoices = v ?? true),
                              ),
                              CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                title: const Text('نسخ أوزان وأحجام قائمة التعبئة', style: TextStyle(fontSize: 12)),
                                value: _copyPackingLists,
                                activeColor: AppTheme.cobalt,
                                onChanged: (v) => setState(() => _copyPackingLists = v ?? true),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Column 2: Cleared Fields Requiring New Input
                      Expanded(
                        flex: 6,
                        child: ListView(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.edit_outlined, size: 16, color: AppTheme.charcoal),
                                const SizedBox(width: 6),
                                Text(
                                  l.inqCloneClearedDataTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppTheme.charcoal,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16),

                            // New Shipment Name
                            TextFormField(
                              controller: _newNameController,
                              decoration: InputDecoration(
                                labelText: l.inqCloneNewShipmentName,
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.badge_outlined, size: 18),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'يرجى إدخال اسم الشحنة الجديدة';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // New Import File Code
                            TextFormField(
                              controller: _newCodeController,
                              decoration: InputDecoration(
                                labelText: l.inqCloneNewFileCode,
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.qr_code, size: 18),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'يرجى إدخال كود الشحنة الجديد';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // New Invoice Number
                            TextFormField(
                              controller: _newInvoiceController,
                              decoration: InputDecoration(
                                labelText: l.inqCloneNewInvoiceNumber,
                                hintText: 'رقم الفاتورة الجديد (اختياري الآن)',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.receipt_outlined, size: 18),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // New Freight Cost with Last Recorded Cost Hint
                            TextFormField(
                              controller: _newFreightCostController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: l.inqCloneNewFreightCost,
                                helperText: '${l.inqCloneLastRecordedCost}: ${src.estimatedCost.toStringAsFixed(0)} ${src.estimatedCostCurrency}',
                                helperStyle: const TextStyle(
                                  color: AppTheme.cobalt,
                                  fontWeight: FontWeight.bold,
                                ),
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.monetization_on_outlined, size: 18),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Notes
                            TextFormField(
                              controller: _notesController,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'ملاحظات وتوجيهات الشحنة',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 20),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('إلغاء'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: Text(l.inqCloneOpenFormBtn),
                    onPressed: _isLoading ? null : () => _handleClone(openFullForm: true),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check, size: 16),
                    label: Text(l.inqCloneConfirmBtn),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emerald,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _isLoading ? null : () => _handleClone(openFullForm: false),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
            ),
          ),
        ],
      ),
    );
  }
}
