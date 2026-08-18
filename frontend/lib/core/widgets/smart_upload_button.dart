import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../constants/api_constants.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Supported module names (must match backend SUPPORTED_MODULES)
// ─────────────────────────────────────────────────────────────────────────────

enum SmartUploadModule {
  purchaseOrder('purchase-order', 'أمر الشراء'),
  importFile('import-file', 'ملف الاستيراد'),
  cargoShipping('cargo-shipping', 'بيانات الشحنة (B/L)'),
  customsClearance('customs-clearance', 'الإقرار الجمركي'),
  freightQuotation('freight-quotation', 'عرض سعر الشحن'),
  freightBooking('freight-booking', 'تأكيد الحجز'),
  customsConsultation('customs-consultation', 'الاستشارة الجمركية'),
  cooCertificate('coo-certificate', 'شهادة المنشأ'),
  inspectionCertificate('inspection-certificate', 'شهادة الفحص'),
  financialDocument('financial-document', 'مستند مالي'),
  warehouseReceiving('warehouse-receiving', 'استلام المستودع'),
  demurrage('demurrage', 'رسوم الوقوف');

  const SmartUploadModule(this.apiValue, this.arabicLabel);
  final String apiValue;
  final String arabicLabel;
}

// ─────────────────────────────────────────────────────────────────────────────
// Result model
// ─────────────────────────────────────────────────────────────────────────────

class SmartUploadResult {
  final int? sessionId;
  final String? sessionRef;
  final String moduleName;
  final String filename;
  final String fileType;
  final String extractionStatus;
  final double confidenceScore;
  final Map<String, dynamic> extractedFields;
  final List<String> missingFields;
  final String? extractionNotes;
  final String? rawTextPreview;

  const SmartUploadResult({
    this.sessionId,
    this.sessionRef,
    required this.moduleName,
    required this.filename,
    required this.fileType,
    required this.extractionStatus,
    required this.confidenceScore,
    required this.extractedFields,
    required this.missingFields,
    this.extractionNotes,
    this.rawTextPreview,
  });

  factory SmartUploadResult.fromJson(Map<String, dynamic> json) {
    return SmartUploadResult(
      sessionId: json['session_id'],
      sessionRef: json['session_ref'],
      moduleName: json['module_name'] ?? '',
      filename: json['filename'] ?? '',
      fileType: json['file_type'] ?? '',
      extractionStatus: json['extraction_status'] ?? 'FAILED',
      confidenceScore: (json['confidence_score'] ?? 0.0).toDouble(),
      extractedFields: Map<String, dynamic>.from(json['extracted_fields'] ?? {}),
      missingFields: List<String>.from(json['missing_fields'] ?? []),
      extractionNotes: json['extraction_notes'],
      rawTextPreview: json['raw_text_preview'],
    );
  }

  bool get isSuccess => extractionStatus == 'SUCCESS';
  bool get isPartial => extractionStatus == 'PARTIAL';
  bool get isFailed => extractionStatus == 'FAILED';
  int get confidencePercent => (confidenceScore * 100).round();
}

// ─────────────────────────────────────────────────────────────────────────────
// SmartUploadButton Widget
// ─────────────────────────────────────────────────────────────────────────────

/// A reusable upload button that:
/// 1. Opens FilePicker for PDF / Excel / Word
/// 2. Uploads to /api/v1/smart-upload/parse/{module}
/// 3. Shows a preview dialog with extracted fields
/// 4. Calls [onDataExtracted] with confirmed fields
class SmartUploadButton extends StatefulWidget {
  final SmartUploadModule module;
  final String? label;
  final void Function(SmartUploadResult result)? onDataExtracted;
  final bool compact;

  const SmartUploadButton({
    super.key,
    required this.module,
    this.label,
    this.onDataExtracted,
    this.compact = false,
  });

  @override
  State<SmartUploadButton> createState() => _SmartUploadButtonState();
}

class _SmartUploadButtonState extends State<SmartUploadButton> {
  bool _isLoading = false;

  Future<void> _handleUpload() async {
    // 1 — Pick file(s) (supports selecting Commercial Invoice + Packing List together)
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'doc', 'xlsx', 'xls', 'txt', 'csv'],
      allowMultiple: true,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final validFiles = result.files.where((f) => f.bytes != null).toList();
    if (validFiles.isEmpty) {
      _showError('تعذر قراءة الملفات المحددة. يرجى المحاولة مرة أخرى.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2 — Upload & parse (single or multi-file)
      final SmartUploadResult uploadResult;
      if (validFiles.length == 1) {
        uploadResult = await _uploadAndParseSingle(validFiles.first.name, validFiles.first.bytes!);
      } else {
        uploadResult = await _uploadAndParseMulti(validFiles);
      }

      setState(() => _isLoading = false);

      if (!mounted) return;

      // 3 — Show preview dialog
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => SmartUploadPreviewDialog(
          result: uploadResult,
          onConfirm: () {
            Navigator.of(ctx).pop();
            widget.onDataExtracted?.call(uploadResult);
          },
          onCancel: () => Navigator.of(ctx).pop(),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('فشل استخراج البيانات: ${_friendlyError(e)}');
    }
  }

  Future<SmartUploadResult> _uploadAndParseSingle(String filename, Uint8List bytes) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 180),
        receiveTimeout: const Duration(seconds: 180),
        sendTimeout: const Duration(seconds: 180),
      ),
    );
    final endpoint = '${ApiConstants.baseUrl}/smart-upload/parse/${widget.module.apiValue}';

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
      'save_session': 'true',
    });

    final response = await dio.post(endpoint, data: formData);
    return SmartUploadResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SmartUploadResult> _uploadAndParseMulti(List<PlatformFile> files) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 180),
        receiveTimeout: const Duration(seconds: 180),
        sendTimeout: const Duration(seconds: 180),
      ),
    );
    final endpoint = '${ApiConstants.baseUrl}/smart-upload/parse-multi/${widget.module.apiValue}';

    final multiFiles = files
        .map((f) => MultipartFile.fromBytes(f.bytes!, filename: f.name))
        .toList();

    final formData = FormData.fromMap({
      'files': multiFiles,
      'save_session': 'true',
    });

    final response = await dio.post(endpoint, data: formData);
    return SmartUploadResult.fromJson(response.data as Map<String, dynamic>);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.crimson,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String _friendlyError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['detail'] != null) return data['detail'].toString();
      return 'خطأ في الاتصال بالخادم (${e.response?.statusCode})';
    }
    return e.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return Tooltip(
        message: 'رفع ${widget.module.arabicLabel}',
        child: IconButton(
          icon: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cobalt),
                )
              : const Icon(Icons.upload_file_rounded, color: AppTheme.cobalt),
          onPressed: _isLoading ? null : _handleUpload,
        ),
      );
    }

    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.cobalt,
        side: const BorderSide(color: AppTheme.cobalt),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cobalt),
            )
          : const Icon(Icons.upload_file_rounded, size: 18),
      label: Text(
        _isLoading ? 'جاري الاستخراج...' : (widget.label ?? 'رفع وثيقة'),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      onPressed: _isLoading ? null : _handleUpload,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SmartUploadPreviewDialog
// ─────────────────────────────────────────────────────────────────────────────

/// Shows extracted fields to the user for review before applying to the form.
class SmartUploadPreviewDialog extends StatelessWidget {
  final SmartUploadResult result;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const SmartUploadPreviewDialog({
    super.key,
    required this.result,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color statusColor;
    IconData statusIcon;
    String statusLabel;
    switch (result.extractionStatus) {
      case 'SUCCESS':
        statusColor = AppTheme.emerald;
        statusIcon = Icons.check_circle_rounded;
        statusLabel = 'استخراج كامل';
        break;
      case 'PARTIAL':
        statusColor = AppTheme.orange;
        statusIcon = Icons.warning_amber_rounded;
        statusLabel = 'استخراج جزئي';
        break;
      default:
        statusColor = AppTheme.crimson;
        statusIcon = Icons.error_rounded;
        statusLabel = 'فشل الاستخراج';
    }

    final nonNullFields = result.extractedFields.entries
        .where((e) => e.value != null && e.value.toString().trim().isNotEmpty && e.value.toString() != '[]')
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─ Header ─────────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'نتيجة الاستخراج — $statusLabel',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        Text(
                          '${result.filename} · دقة الاستخراج: ${result.confidencePercent}%',
                          style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.charcoal.withOpacity(0.6)),
                        ),
                      ],
                    ),
                  ),
                  // Confidence bar
                  SizedBox(
                    width: 80,
                    child: Column(
                      children: [
                        Text('${result.confidencePercent}%',
                            style: TextStyle(fontWeight: FontWeight.bold, color: statusColor)),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: result.confidenceScore,
                          color: statusColor,
                          backgroundColor: statusColor.withOpacity(0.2),
                          minHeight: 6,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ─ Fields List ────────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (nonNullFields.isNotEmpty) ...[
                      Text('الحقول المستخرجة (${nonNullFields.length})',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppTheme.charcoal.withOpacity(0.6),
                            fontWeight: FontWeight.w600,
                          )),
                      const SizedBox(height: 8),
                      ...nonNullFields.map((e) => _FieldRow(
                            label: _formatFieldName(e.key),
                            value: _formatValue(e.value),
                          )),
                    ] else
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'لم يتم استخراج أي بيانات من هذا الملف.\nتأكد من أن الملف يحتوي على نص قابل للقراءة.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.crimson),
                          ),
                        ),
                      ),

                    // Quick Registration Actions for Supplier & Importer
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (result.extractedFields['supplier_name'] != null)
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.cobalt,
                              side: const BorderSide(color: AppTheme.cobalt),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                            label: Text(
                              'تسجيل "${result.extractedFields['supplier_name']}" كمورد جديد',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () => _showRegisterSupplierDialog(context, result.extractedFields),
                          ),
                        if (result.extractedFields['importer_name'] != null)
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.emerald,
                              side: const BorderSide(color: AppTheme.emerald),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            icon: const Icon(Icons.domain_add_rounded, size: 16),
                            label: Text(
                              'تسجيل "${result.extractedFields['importer_name']}" كشركة مستوردة',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () => _showRegisterImporterDialog(context, result.extractedFields),
                          ),
                      ],
                    ),

                    // Missing fields warning
                    if (result.missingFields.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.orange.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.orange.withOpacity(0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline, color: AppTheme.orange, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'الحقول التالية لم تُستخرج: ${result.missingFields.map(_formatFieldName).join('، ')}',
                                style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.orange),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Notes
                    if (result.extractionNotes != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        result.extractionNotes!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.charcoal.withOpacity(0.5),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ─ Actions ────────────────────────────────────────────────────
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onCancel,
                    child: const Text('إلغاء'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: AppTheme.cobalt),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('تعبئة النموذج'),
                    onPressed: nonNullFields.isEmpty ? null : onConfirm,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFieldName(String key) {
    final labels = {
      'po_number': 'رقم أمر الشراء / الفاتورة',
      'order_date': 'تاريخ أمر الشراء / الفاتورة',
      'supplier_name': 'اسم المورد / الشركة',
      'currency': 'العملة',
      'total_amount': 'الإجمالي الفعلي',
      'bl_number': 'رقم سند الشحن',
      'vessel_name': 'اسم السفينة',
      'voyage_number': 'رقم الرحلة',
      'loading_port': 'ميناء الشحن',
      'discharge_port': 'ميناء التفريغ',
      'acid_number': 'رقم إقرار الشحنة (ACID)',
      'country_of_origin': 'بلد المنشأ',
      'payment_terms': 'شروط الدفع والتعاقد',
      'items': 'جدول البنود المالية والكميات',
      'packing_list_items': 'بيانات طرود التعبئة والأبعاد (Packing List)',
      'delivery_port': 'ميناء الشحن / التوصيل',
      'eta': 'تاريخ الوصول',
      'total_gross_weight_kg': 'الوزن الإجمالي (كجم)',
      'total_cbm': 'الحجم (م³)',
      'containers': 'الحاويات',
      'shipper': 'الشاحن',
      'consignee': 'المرسل إليه',
      'declaration_no': 'رقم الإقرار الجمركي',
      'declaration_date': 'تاريخ الإقرار',
      'hs_code': 'بند التعريفة',
      'commodity_description': 'وصف البضاعة',
      'origin_country': 'بلد المنشأ',
      'customs_value_egp': 'القيمة الجمركية (ج.م)',
      'exchange_rate': 'سعر الصرف',
      'import_duty': 'ضريبة الوارد',
      'vat_amount': 'ضريبة القيمة المضافة',
      'total_taxes': 'إجمالي الضرائب',
      'invoice_number': 'رقم الفاتورة',
      'invoice_date': 'تاريخ الفاتورة',
      'invoice_value': 'قيمة الفاتورة',
      'certificate_number': 'رقم الشهادة',
      'issue_date': 'تاريخ الإصدار',
      'carrier_name': 'اسم الناقل البحرى / الجوي',
      'freight_rate': 'سعر الشحن',
      'transit_days': 'أيام العبور',
      'validity_date': 'تاريخ الصلاحية',
      'booking_number': 'رقم الحجز',
      'si_cutoff': 'موعد إغلاق SI',
      'amount': 'المبلغ',
      'bank_name': 'اسم البنك',
      'swift_code': 'SWIFT',
      'result': 'نتيجة الفحص',
    };
    return labels[key] ?? key.replaceAll('_', ' ');
  }

  String _formatValue(dynamic value) {
    if (value is List) {
      if (value.isEmpty) return '(فارغ)';
      return '${value.length} عنصر';
    }
    if (value is Map) return '{...}';
    return value.toString();
  }

  void _showRegisterSupplierDialog(BuildContext context, Map<String, dynamic> ext) {
    final suppName = ext['supplier_name']?.toString() ?? '';
    final country = ext['supplier_country']?.toString() ?? ext['country_of_origin']?.toString() ?? '';
    final phone = ext['supplier_phone']?.toString() ?? '';
    final email = ext['supplier_email']?.toString() ?? '';
    final address = ext['supplier_address']?.toString() ?? '';
    final taxId = ext['supplier_tax_id']?.toString() ?? '';

    final nameCtrl = TextEditingController(text: suppName);
    final countryCtrl = TextEditingController(text: country);
    final phoneCtrl = TextEditingController(text: phone);
    final emailCtrl = TextEditingController(text: email);
    final addressCtrl = TextEditingController(text: address);
    final taxIdCtrl = TextEditingController(text: taxId);
    bool isSaving = false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Row(
            children: [
              Icon(Icons.person_add_alt_1_rounded, color: AppTheme.cobalt),
              SizedBox(width: 8),
              Text('تسجيل مورد أجنبي جديد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'اسم الشركة الموردة *'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: countryCtrl,
                          decoration: const InputDecoration(labelText: 'دولة المنشأ / المقر'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: taxIdCtrl,
                          decoration: const InputDecoration(labelText: 'الرقم الضريبي / VAT'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: phoneCtrl,
                          decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: emailCtrl,
                          decoration: const InputDecoration(labelText: 'البريد / الموقع الإلكتروني'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: addressCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'العنوان التفصيلي للمورد'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white),
              icon: isSaving
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded, size: 16),
              label: const Text('حفظ المورد بالنظام'),
              onPressed: isSaving
                  ? null
                  : () async {
                      setDialogState(() => isSaving = true);
                      try {
                        final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 180), receiveTimeout: const Duration(seconds: 180)));
                        final cty = countryCtrl.text.trim().isNotEmpty ? countryCtrl.text.trim() : 'United Kingdom';
                        final ctyCode = cty.length >= 2 ? cty.substring(0, 2).toUpperCase() : 'GB';
                        final exporterId = taxIdCtrl.text.trim().isNotEmpty ? taxIdCtrl.text.trim() : 'EXP-${DateTime.now().millisecondsSinceEpoch}';
                        await dio.post(
                          '${ApiConstants.baseUrl}/suppliers',
                          data: {
                            'company_name': nameCtrl.text.trim(),
                            'supplier_type': 'Manufacturer',
                            'registration_type': 'Foreign Exporter',
                            'foreign_exporter_id': exporterId,
                            'foreign_exporter_country': cty,
                            'foreign_exporter_country_code': ctyCode,
                            'address': addressCtrl.text.trim().isNotEmpty ? addressCtrl.text.trim() : 'Exporter Address',
                            'phone': phoneCtrl.text.trim(),
                            'email': emailCtrl.text.trim(),
                          },
                        );
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('تم تسجيل المورد "${nameCtrl.text.trim()}" بنجاح!'),
                              backgroundColor: AppTheme.emerald,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        String msg = '$e';
                        if (e is DioException && e.response?.data != null) {
                          final data = e.response!.data;
                          if (data is Map && data['detail'] != null) {
                            msg = data['detail'].toString();
                          }
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('فشل حفظ المورد: $msg'), backgroundColor: AppTheme.crimson, duration: const Duration(seconds: 5)),
                        );
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  void _showRegisterImporterDialog(BuildContext context, Map<String, dynamic> ext) {
    final impName = ext['importer_name']?.toString() ?? '';
    final taxId = ext['importer_tax_id']?.toString() ?? '';
    final phone = ext['importer_phone']?.toString() ?? '';
    final email = ext['importer_email']?.toString() ?? '';
    final address = ext['importer_address']?.toString() ?? '';

    final nameCtrl = TextEditingController(text: impName);
    final taxIdCtrl = TextEditingController(text: taxId);
    final phoneCtrl = TextEditingController(text: phone);
    final emailCtrl = TextEditingController(text: email);
    final addressCtrl = TextEditingController(text: address);
    bool isSaving = false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Row(
            children: [
              Icon(Icons.domain_add_rounded, color: AppTheme.cobalt),
              SizedBox(width: 8),
              Text('تسجيل شركة مستوردة جديدة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'اسم الشركة المستوردة *'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: taxIdCtrl,
                          decoration: const InputDecoration(labelText: 'الرقم الضريبي للمستورد *'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: phoneCtrl,
                          decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'البريد الإلكتروني للشركة'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: addressCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'العنوان التفصيلي كائن بمصر'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white),
              icon: isSaving
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded, size: 16),
              label: const Text('حفظ الشركة بالنظام'),
              onPressed: isSaving
                  ? null
                  : () async {
                      setDialogState(() => isSaving = true);
                      try {
                        final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 180), receiveTimeout: const Duration(seconds: 180)));
                        await dio.post(
                          '${ApiConstants.baseUrl}/import-companies',
                          data: {
                            'importer_name': nameCtrl.text.trim(),
                            'address': addressCtrl.text.trim().isNotEmpty ? addressCtrl.text.trim() : 'Cairo, Egypt',
                            'country': 'Egypt',
                            'importer_id': 'IMP-${DateTime.now().millisecondsSinceEpoch}',
                            'importer_id_expiry': '2030-12-31',
                            'vat_id': taxIdCtrl.text.trim().isNotEmpty ? taxIdCtrl.text.trim() : '000000000',
                            'vat_id_expiry': '2030-12-31',
                            'registration_number': '000000',
                            'registration_expiry': '2030-12-31',
                            'phone': phoneCtrl.text.trim(),
                            'email': emailCtrl.text.trim(),
                          },
                        );
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('تم تسجيل الشركة المستوردة "${nameCtrl.text.trim()}" بنجاح!'),
                              backgroundColor: AppTheme.emerald,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        String msg = '$e';
                        if (e is DioException && e.response?.data != null) {
                          final data = e.response!.data;
                          if (data is Map && data['detail'] != null) {
                            msg = data['detail'].toString();
                          }
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('فشل حفظ الشركة: $msg'), backgroundColor: AppTheme.crimson, duration: const Duration(seconds: 5)),
                        );
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper Widget
// ─────────────────────────────────────────────────────────────────────────────

class _FieldRow extends StatelessWidget {
  final String label;
  final String value;

  const _FieldRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 190,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.charcoal,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                color: AppTheme.charcoal.withOpacity(0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
