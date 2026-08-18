// TODO: Refactor to ConsumerWidget to use dioProvider/uploadDioProvider
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../constants/api_constants.dart';
import '../theme/app_theme.dart';
import 'universal_entity_extractor_dialog.dart';
import '../../features/customs_tariff/widgets/tariff_form_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  // ── Entity Verification ─────────────────────────────────────────────────
  final bool? supplierVerified;
  final int? supplierId;
  final String? supplierCode;
  final bool? importerVerified;
  final int? importerDbId;
  final String? importerCode;

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
    // verification
    this.supplierVerified,
    this.supplierId,
    this.supplierCode,
    this.importerVerified,
    this.importerDbId,
    this.importerCode,
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
      // verification
      supplierVerified: json['supplier_verified'] as bool?,
      supplierId: json['supplier_id'] as int?,
      supplierCode: json['supplier_code'] as String?,
      importerVerified: json['importer_verified'] as bool?,
      importerDbId: json['importer_id'] as int?,
      importerCode: json['importer_code'] as String?,
    );
  }

  bool get isSuccess => extractionStatus == 'SUCCESS';
  bool get isPartial => extractionStatus == 'PARTIAL';
  bool get isFailed => extractionStatus == 'FAILED';
  int get confidencePercent => (confidenceScore * 100).round();

  SmartUploadResult copyWith({
    int? sessionId,
    String? sessionRef,
    String? moduleName,
    String? filename,
    String? fileType,
    String? extractionStatus,
    double? confidenceScore,
    Map<String, dynamic>? extractedFields,
    List<String>? missingFields,
    String? extractionNotes,
    String? rawTextPreview,
    bool? supplierVerified,
    int? supplierId,
    String? supplierCode,
    bool? importerVerified,
    int? importerDbId,
    String? importerCode,
  }) {
    return SmartUploadResult(
      sessionId: sessionId ?? this.sessionId,
      sessionRef: sessionRef ?? this.sessionRef,
      moduleName: moduleName ?? this.moduleName,
      filename: filename ?? this.filename,
      fileType: fileType ?? this.fileType,
      extractionStatus: extractionStatus ?? this.extractionStatus,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      extractedFields: extractedFields ?? this.extractedFields,
      missingFields: missingFields ?? this.missingFields,
      extractionNotes: extractionNotes ?? this.extractionNotes,
      rawTextPreview: rawTextPreview ?? this.rawTextPreview,
      supplierVerified: supplierVerified ?? this.supplierVerified,
      supplierId: supplierId ?? this.supplierId,
      supplierCode: supplierCode ?? this.supplierCode,
      importerVerified: importerVerified ?? this.importerVerified,
      importerDbId: importerDbId ?? this.importerDbId,
      importerCode: importerCode ?? this.importerCode,
    );
  }
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
  double _progressPercent = 0.0;
  String _progressLabel = '';

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

    setState(() {
      _isLoading = true;
      _progressPercent = 0.05;
      _progressLabel = 'جاري تحضير الملف...';
    });

    try {
      // 2 — Upload & parse (single or multi-file) with live percentage tracking
      final SmartUploadResult uploadResult;
      if (validFiles.length == 1) {
        uploadResult = await _uploadAndParseSingle(validFiles.first.name, validFiles.first.bytes!);
      } else {
        uploadResult = await _uploadAndParseMulti(validFiles);
      }

      setState(() {
        _progressPercent = 1.0;
        _progressLabel = 'اكتمل بنجاح 100%';
        _isLoading = false;
      });

      if (!mounted) return;

      // 3 — Show preview dialog
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => SmartUploadPreviewDialog(
          result: uploadResult,
          onConfirm: (confirmedResult) {
            Navigator.of(ctx).pop();
            widget.onDataExtracted?.call(confirmedResult);
          },
          onCancel: () => Navigator.of(ctx).pop(),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _progressPercent = 0.0;
        _progressLabel = '';
      });
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

    final response = await dio.post(
      endpoint,
      data: formData,
      onSendProgress: (sent, total) {
        if (total > 0 && mounted) {
          final uploadRatio = sent / total;
          setState(() {
            // Upload phase is 0% -> 60%, AI parsing phase is 60% -> 95%
            _progressPercent = 0.05 + (uploadRatio * 0.55);
            if (_progressPercent < 0.6) {
              _progressLabel = 'جاري الرفع: ${(_progressPercent * 100).round()}%';
            } else {
              _progressLabel = 'جاري التحليل واستخراج البيانات: 75%';
            }
          });
        }
      },
    );
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

    final response = await dio.post(
      endpoint,
      data: formData,
      onSendProgress: (sent, total) {
        if (total > 0 && mounted) {
          final uploadRatio = sent / total;
          setState(() {
            _progressPercent = 0.05 + (uploadRatio * 0.55);
            if (_progressPercent < 0.6) {
              _progressLabel = 'جاري رفع ${files.length} ملفات: ${(_progressPercent * 100).round()}%';
            } else {
              _progressLabel = 'جاري المعالجة والمطابقة: 80%';
            }
          });
        }
      },
    );
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
    final percentInt = (_progressPercent * 100).round().clamp(0, 100);

    if (widget.compact) {
      return Tooltip(
        message: _isLoading ? _progressLabel : 'رفع ${widget.module.arabicLabel}',
        child: _isLoading
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.cobalt.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cobalt, width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        value: _progressPercent > 0 ? _progressPercent : null,
                        strokeWidth: 2,
                        color: AppTheme.cobalt,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$percentInt%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.cobalt,
                      ),
                    ),
                  ],
                ),
              )
            : IconButton(
                icon: const Icon(Icons.upload_file_rounded, color: AppTheme.cobalt),
                onPressed: _handleUpload,
              ),
      );
    }

    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: _isLoading ? AppTheme.cobalt : AppTheme.cobalt,
        side: BorderSide(color: AppTheme.cobalt, width: _isLoading ? 1.5 : 1.0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: _isLoading ? AppTheme.cobalt.withOpacity(0.06) : null,
      ),
      icon: _isLoading
          ? Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    value: _progressPercent > 0 ? _progressPercent : null,
                    strokeWidth: 2.5,
                    backgroundColor: AppTheme.cobalt.withOpacity(0.2),
                    color: AppTheme.cobalt,
                  ),
                ),
                Text(
                  '$percentInt%',
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.cobalt,
                  ),
                ),
              ],
            )
          : const Icon(Icons.upload_file_rounded, size: 18),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _isLoading
                ? (_progressLabel.isNotEmpty ? _progressLabel : 'جاري الاستخراج $percentInt%')
                : (widget.label ?? 'رفع وثيقة'),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: _isLoading ? FontWeight.bold : FontWeight.w600,
              color: AppTheme.cobalt,
            ),
          ),
          if (_isLoading) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.cobalt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$percentInt%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
      onPressed: _isLoading ? null : _handleUpload,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SmartUploadPreviewDialog
// ─────────────────────────────────────────────────────────────────────────────

/// Shows extracted fields to the user for review before applying to the form.
class SmartUploadPreviewDialog extends StatefulWidget {
  final SmartUploadResult result;
  final ValueChanged<SmartUploadResult> onConfirm;
  final VoidCallback onCancel;

  const SmartUploadPreviewDialog({
    super.key,
    required this.result,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<SmartUploadPreviewDialog> createState() => _SmartUploadPreviewDialogState();
}

class _SmartUploadPreviewDialogState extends State<SmartUploadPreviewDialog> {
  late Map<String, dynamic> _currentFields;

  @override
  void initState() {
    super.initState();
    _currentFields = Map<String, dynamic>.from(widget.result.extractedFields);
  }

  void _showAddCustomFieldModal() {
    String selectedPreset = 'custom';
    final keyCtrl = TextEditingController();
    final valCtrl = TextEditingController();

    final presets = {
      'hs_code': 'بند التعريفة الجمركية (HS Code)',
      'acid_number': 'رقم إقرار الشحنة المسبق (ACID)',
      'bl_number': 'رقم بوليصة الشحن (B/L Number)',
      'container_number': 'رقم الحاوية (Container Number)',
      'loading_port': 'ميناء الشحن (Port of Loading)',
      'discharge_port': 'ميناء التفريغ (Port of Discharge)',
      'carrier_name': 'اسم الخط الملاحي / الناقل (Carrier)',
      'lc_number': 'رقم الاعتماد المستندي (LC Number)',
      'payment_terms': 'شروط السداد والدفع (Payment Terms)',
      'notes': 'ملاحظات وشروط خاصة (Special Notes)',
      'custom': '➕ بيان / حقل مخصص آخر (Custom Field)',
    };

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Row(
            children: [
              Icon(Icons.add_box_rounded, color: AppTheme.cobalt),
              SizedBox(width: 8),
              Text('إضافة بيان / حقل إضافي يدوياً', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('اختر نوع البيان أو أدخل بياناً مخصصاً:', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedPreset,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'نوع البيان المطلوب إضافته', isDense: true),
                  items: presets.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setModalState(() {
                        selectedPreset = v;
                        if (v != 'custom') {
                          keyCtrl.text = v;
                        } else {
                          keyCtrl.clear();
                        }
                      });
                    }
                  },
                ),
                if (selectedPreset == 'custom') ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: keyCtrl,
                    decoration: const InputDecoration(labelText: 'اسم الحقل / البيان الجديد (Field Name) *', hintText: 'مثلاً: vessel_name أو رقم_الشهادة'),
                  ),
                ],
                const SizedBox(height: 10),
                TextField(
                  controller: valCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'القيمة / البيان (Field Value) *', hintText: 'أدخل القيمة المراد إضافتها للنموذج...'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white),
              icon: const Icon(Icons.check, size: 16),
              label: const Text('إضافة للبيانات'),
              onPressed: () {
                final k = keyCtrl.text.trim();
                final v = valCtrl.text.trim();
                if (k.isNotEmpty && v.isNotEmpty) {
                  setState(() {
                    _currentFields[k] = v;
                  });
                  Navigator.pop(ctx);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditFieldModal(String key, dynamic value) {
    final valCtrl = TextEditingController(text: value?.toString() ?? '');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(Icons.edit_note_rounded, color: AppTheme.cobalt),
            const SizedBox(width: 8),
            Expanded(child: Text('تعديل قيمة: ${_formatFieldName(key)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: valCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'القيمة المحدثة',
              hintText: 'أدخل القيمة الصحيحة...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, foregroundColor: Colors.white),
            icon: const Icon(Icons.save, size: 16),
            label: const Text('حفظ التعديل'),
            onPressed: () {
              setState(() {
                _currentFields[key] = valCtrl.text.trim();
              });
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = widget.result;

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

    final nonNullFields = _currentFields.entries
        .where((e) => e.value != null && e.value.toString().trim().isNotEmpty && e.value.toString() != '[]' && e.key != 'hs_code_compliance_warning')
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'الحقول المستخرجة والبيانات المعتمدة (${nonNullFields.length})',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppTheme.charcoal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.emerald,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.add, size: 15),
                          label: const Text('➕ إضافة بيان / حقل إضافي يدوياً', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                          onPressed: _showAddCustomFieldModal,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // ── Entity Verification Panel ──────────────────────────
                    if (result.supplierVerified != null || result.importerVerified != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.charcoal.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.charcoal.withOpacity(0.12)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.verified_user_rounded, size: 15, color: AppTheme.charcoal),
                                SizedBox(width: 6),
                                Text(
                                  'التحقق من تسجيل الأطراف في قاعدة البيانات',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (result.supplierVerified != null)
                              _EntityVerificationRow(
                                icon: Icons.factory_rounded,
                                label: 'المورد الأجنبي',
                                entityName: _currentFields['supplier_name']?.toString() ??
                                    _currentFields['shipper']?.toString() ?? '—',
                                isVerified: result.supplierVerified!,
                                entityCode: result.supplierCode,
                                verifiedTooltip: result.supplierCode != null
                                    ? 'مسجل بالكود: ${result.supplierCode}'
                                    : 'مسجل في النظام',
                                unverifiedTooltip: 'غير موجود في الموردين — يلزم التسجيل',
                                onRegisterTap: result.supplierVerified! ? null : () =>
                                    UniversalEntityExtractorDialog.show(context, initialTarget: EntityTarget.supplier),
                              ),
                            if (result.supplierVerified != null && result.importerVerified != null)
                              const SizedBox(height: 6),
                            if (result.importerVerified != null)
                              _EntityVerificationRow(
                                icon: Icons.domain_rounded,
                                label: 'الشركة المستوردة',
                                entityName: _currentFields['importer_name']?.toString() ??
                                    _currentFields['consignee']?.toString() ?? '—',
                                isVerified: result.importerVerified!,
                                entityCode: result.importerCode,
                                verifiedTooltip: result.importerCode != null
                                    ? 'مسجلة بالكود: ${result.importerCode}'
                                    : 'مسجلة في النظام',
                                unverifiedTooltip: 'غير موجودة في الشركات المستوردة — يلزم التسجيل',
                                onRegisterTap: result.importerVerified! ? null : () =>
                                    UniversalEntityExtractorDialog.show(context, initialTarget: EntityTarget.company),
                              ),
                          ],
                        ),
                      ),
                    ],

                    if (nonNullFields.isNotEmpty) ...[
                      ...nonNullFields.map((e) => _FieldRow(
                            fieldKey: e.key,
                            label: _formatFieldName(e.key),
                            value: _formatValue(e.value),
                            isCustom: !['po_number', 'order_date', 'supplier_name', 'currency', 'total_amount', 'incoterms', 'country_of_origin', 'items', 'packing_list_items'].contains(e.key),
                            onEdit: () => _showEditFieldModal(e.key, e.value),
                            onRemove: () {
                              setState(() {
                                _currentFields.remove(e.key);
                              });
                            },
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

                    // HS Code Compliance & Registration Warning with Smart Nafeza Trigger
                    if (_currentFields['hs_code_compliance_warning'] != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade400, width: 1.2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _currentFields['hs_code_compliance_warning'].toString(),
                                    style: TextStyle(
                                      color: Colors.amber.shade900,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Consumer(
                              builder: (context, ref, _) => ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  visualDensity: VisualDensity.compact,
                                ),
                                icon: const Icon(Icons.auto_fix_high, size: 16),
                                label: const Text('✨ استدعاء Smart Nafeza & Diff Engine لتسجيل البند'),
                                onPressed: () => showTariffDialog(context, ref, initialModeIndex: 0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

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
                    onPressed: widget.onCancel,
                    child: const Text('إلغاء'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: AppTheme.cobalt),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('تعبئة النموذج'),
                    onPressed: nonNullFields.isEmpty ? null : () => widget.onConfirm(result.copyWith(extractedFields: _currentFields)),
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
}


// ─── _EntityVerificationRow ───────────────────────────────────────────────────
class _EntityVerificationRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String entityName;
  final bool isVerified;
  final String? entityCode;
  final String verifiedTooltip;
  final String unverifiedTooltip;
  final VoidCallback? onRegisterTap;

  const _EntityVerificationRow({
    required this.icon,
    required this.label,
    required this.entityName,
    required this.isVerified,
    this.entityCode,
    required this.verifiedTooltip,
    required this.unverifiedTooltip,
    this.onRegisterTap,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = isVerified ? AppTheme.emerald : AppTheme.crimson;
    final badgeIcon = isVerified ? Icons.check_circle_rounded : Icons.cancel_rounded;
    final badgeLabel = isVerified ? 'مؤكد' : 'غير مؤكد';
    final tooltip = isVerified ? verifiedTooltip : unverifiedTooltip;

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: badgeColor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: badgeColor.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: badgeColor),
            const SizedBox(width: 8),
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                entityName,
                style: const TextStyle(fontSize: 11.5, color: AppTheme.charcoal),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(badgeIcon, size: 13, color: badgeColor),
                  const SizedBox(width: 4),
                  Text(
                    badgeLabel,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor),
                  ),
                ],
              ),
            ),
            if (!isVerified && onRegisterTap != null) ...[
              const SizedBox(width: 6),
              InkWell(
                onTap: onRegisterTap,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.cobalt.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 13, color: AppTheme.cobalt),
                      SizedBox(width: 3),
                      Text('سجّل', style: TextStyle(fontSize: 10.5, color: AppTheme.cobalt, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String? fieldKey;
  final String label;
  final String value;
  final bool isCustom;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  const _FieldRow({
    this.fieldKey,
    required this.label,
    required this.value,
    this.isCustom = false,
    this.onEdit,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.5),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isCustom ? Colors.blue.shade50.withOpacity(0.5) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isCustom ? Colors.blue.shade200 : Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 180,
            child: Row(
              children: [
                if (isCustom)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.star, size: 12, color: Colors.blue),
                  ),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isCustom ? Colors.blue.shade900 : AppTheme.charcoal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.charcoal.withOpacity(0.85),
                fontWeight: isCustom ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          if (onEdit != null && value != '{...}' && !value.contains('عنصر'))
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.cobalt),
              tooltip: 'تعديل البيان',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onEdit,
            ),
          if (onRemove != null && isCustom) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 16, color: AppTheme.crimson),
              tooltip: 'حذف البيان',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onRemove,
            ),
          ],
        ],
      ),
    );
  }
}
