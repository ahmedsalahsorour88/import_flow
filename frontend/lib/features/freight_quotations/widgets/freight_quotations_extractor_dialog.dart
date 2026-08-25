import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/widgets/extraction_progress_dialog.dart';
import '../../../core/widgets/universal_entity_extractor_dialog.dart';
import '../../external_service_providers/providers/partners_provider.dart';
import '../../transport_locations/providers/transport_locations_provider.dart';

/// Data class representing an extracted freight quotation option.
class ExtractedQuotationOption {
  final int optionId;
  String carrierName;
  String? forwarderName;
  String? vesselName;
  String? voyageNumber;
  String containerType;
  double oceanFreight;
  double? localCharges;
  double? exwCharges;
  double totalEstimatedCost;
  String currency;
  String? incoterm;
  String? originPort;
  String? destinationPort;
  int? transitDays;
  bool isDirect;
  int? freeTimeDays;
  String? etdDate;
  String? etaDate;
  String? notes;
  bool isSelected;

  ExtractedQuotationOption({
    required this.optionId,
    required this.carrierName,
    this.forwarderName,
    this.vesselName,
    this.voyageNumber,
    required this.containerType,
    required this.oceanFreight,
    this.localCharges,
    this.exwCharges,
    required this.totalEstimatedCost,
    this.currency = 'USD',
    this.incoterm,
    this.originPort,
    this.destinationPort,
    this.transitDays,
    this.isDirect = true,
    this.freeTimeDays,
    this.etdDate,
    this.etaDate,
    this.notes,
    this.isSelected = true,
  });

  factory ExtractedQuotationOption.fromMap(Map<String, dynamic> map, int id) {
    final ocean = (map['ocean_freight'] as num?)?.toDouble() ??
        (map['freight_rate'] as num?)?.toDouble() ??
        0.0;
    final local = (map['local_charges'] as num?)?.toDouble();
    final exw = (map['exw_charges'] as num?)?.toDouble();
    final total = (map['total_estimated_cost'] as num?)?.toDouble() ?? (ocean + (local ?? 0.0));

    return ExtractedQuotationOption(
      optionId: id,
      carrierName: (map['carrier_name'] ?? 'Shipping Line').toString(),
      forwarderName: map['forwarder_name']?.toString(),
      vesselName: map['vessel_name']?.toString(),
      voyageNumber: map['voyage_number']?.toString(),
      containerType: (map['container_type'] ?? '40HQ').toString(),
      oceanFreight: ocean,
      localCharges: local,
      exwCharges: exw,
      totalEstimatedCost: total,
      currency: (map['currency'] ?? 'USD').toString(),
      incoterm: map['incoterm']?.toString(),
      originPort: map['origin_port']?.toString(),
      destinationPort: map['destination_port']?.toString(),
      transitDays: map['transit_days'] as int?,
      isDirect: map['is_direct'] as bool? ?? true,
      freeTimeDays: (map['free_time_days'] ?? map['free_days_demurrage']) as int?,
      etdDate: map['etd_date']?.toString(),
      etaDate: map['eta_date']?.toString(),
      notes: map['notes']?.toString(),
      isSelected: true,
    );
  }
}

/// Advanced Freight Quotations Extractor Dialog supporting Text & OCR Scans,
/// Party Verification (Forwarder & Carrier in DB), and Manual Custom Fields.
class FreightQuotationsExtractorDialog extends ConsumerStatefulWidget {
  final void Function(List<ExtractedQuotationOption> selectedOptions) onAddQuotations;

  const FreightQuotationsExtractorDialog({
    super.key,
    required this.onAddQuotations,
  });

  static Future<void> show(
    BuildContext context, {
    required void Function(List<ExtractedQuotationOption> selectedOptions) onAddQuotations,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => FreightQuotationsExtractorDialog(
        onAddQuotations: onAddQuotations,
      ),
    );
  }

  @override
  ConsumerState<FreightQuotationsExtractorDialog> createState() => _FreightQuotationsExtractorDialogState();
}

class _FreightQuotationsExtractorDialogState extends ConsumerState<FreightQuotationsExtractorDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _textController = TextEditingController();

  bool _isExtracting = false;
  String? _error;

  // Selected file for OCR upload
  PlatformFile? _pickedFile;

  // Extracted Results
  List<ExtractedQuotationOption> _options = [];
  Map<String, dynamic>? _primaryMetadata;
  Map<String, String> _customFields = {};
  double _confidenceScore = 1.0;

  static const String _sampleQuoteText = '''
vertexexpress
POL ：NINGBO
POD：DEKHEILA
OF：USD6760/20GP
FREE TIME EXTEND : USD200/ctnr
OF：USD7735/40HQ
FREE TIME EXTEND : USD200/ctnr)
ETD：30-Aug
CARRIER：WHL
TT : 35 DAYS direct
FREE TIME：14 days
Other (21days+USD200/ctnr)
''';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _loadSampleText() {
    setState(() {
      _textController.text = _sampleQuoteText.trim();
      _error = null;
    });
  }

  Future<void> _extractFromText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'يرجى إدخال أو لصق نص عرض السعر أولاً');
      return;
    }

    setState(() {
      _isExtracting = true;
      _error = null;
      _options = [];
      _primaryMetadata = null;
      _customFields = {};
    });

    final progressCtrl = ExtractionProgressController();
    progressCtrl.update(
      percent: 0.20,
      status: 'جاري فحص وتحليل نصوص عروض الشحن والنولون...',
      stepLabel: 'المرحلة 1 من 4: تحليل النص الذكي',
      currentStep: 1,
    );

    ExtractionProgressDialog.show(
      context: context,
      title: 'استخراج وتدقيق عروض أسعار الشحن من النص',
      fileName: 'النص المنسوخ (${text.length} حرف)',
      controller: progressCtrl,
    );

    progressCtrl.startAutoAdvance(targetPercent: 0.90, duration: const Duration(seconds: 2));

    try {
      final dio = Dio();
      final response = await dio.post(
        '${ApiConstants.baseUrl}/smart-upload/parse-text/freight-quotation',
        data: FormData.fromMap({
          'raw_text': text,
          'save_session': false,
        }),
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      progressCtrl.complete();
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      _processExtractedResponse(response.data);
    } on DioException catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      setState(() => _error = 'خطأ في الاتصال بالخادم: ${e.message}');
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      setState(() => _error = 'حدث خطأ أثناء الاستخراج: $e');
    } finally {
      if (mounted) setState(() => _isExtracting = false);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'webp', 'xlsx', 'xls', 'docx', 'doc', 'txt'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedFile = result.files.first;
        _error = null;
      });
    }
  }

  Future<void> _extractFromFileOcr() async {
    if (_pickedFile == null || _pickedFile!.bytes == null) {
      setState(() => _error = 'يرجى اختيار ملف أو صورة عرض السعر أولاً');
      return;
    }

    final file = _pickedFile!;
    final fileSizeFormatted = file.size > 1024 * 1024
        ? '${(file.size / (1024 * 1024)).toStringAsFixed(2)} MB'
        : '${(file.size / 1024).toStringAsFixed(1)} KB';

    setState(() {
      _isExtracting = true;
      _error = null;
      _options = [];
      _primaryMetadata = null;
      _customFields = {};
    });

    final progressCtrl = ExtractionProgressController();
    progressCtrl.update(
      percent: 0.15,
      status: 'جاري رفع الملف وتهيئة الماسح الضوئي (OCR)...',
      stepLabel: 'المرحلة 1 من 4: رفع الملف',
      currentStep: 1,
    );

    ExtractionProgressDialog.show(
      context: context,
      title: 'استخراج عروض أسعار الشحن بالماسح الضوئي (OCR)',
      fileName: file.name,
      fileSize: fileSizeFormatted,
      controller: progressCtrl,
    );

    try {
      final dio = Dio();
      final multipartFile = MultipartFile.fromBytes(file.bytes!, filename: file.name);
      final formData = FormData.fromMap({
        'file': multipartFile,
        'module_name': 'freight-quotation',
        'save_session': false,
      });

      final response = await dio.post(
        '${ApiConstants.baseUrl}/smart-upload/upload',
        data: formData,
        options: Options(receiveTimeout: const Duration(seconds: 60)),
        onSendProgress: (sent, total) {
          if (total > 0) {
            final uploadRatio = sent / total;
            final p = 0.15 + (uploadRatio * 0.35);
            progressCtrl.update(
              percent: p,
              status: 'جاري رفع الملف (${(uploadRatio * 100).round()}%)...',
              stepLabel: 'المرحلة 2 من 4: رفع الملف',
              currentStep: 2,
            );
            if (uploadRatio >= 0.99) {
              progressCtrl.startAutoAdvance(targetPercent: 0.92, duration: const Duration(seconds: 5));
            }
          }
        },
      );

      progressCtrl.complete();
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      _processExtractedResponse(response.data);
    } on DioException catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      setState(() => _error = 'خطأ في معالجة الملف بالـ OCR: ${e.message}');
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      setState(() => _error = 'حدث خطأ أثناء معالجة المستند: $e');
    } finally {
      if (mounted) setState(() => _isExtracting = false);
    }
  }

  void _processExtractedResponse(dynamic data) {
    if (data == null) return;
    final extracted = (data['extracted_fields'] as Map<String, dynamic>?) ?? {};
    final rawRateOptions = (extracted['rate_options'] as List<dynamic>?) ?? [];
    final score = (data['confidence_score'] as num?)?.toDouble() ?? 1.0;

    final List<ExtractedQuotationOption> parsedList = [];

    if (rawRateOptions.isNotEmpty) {
      for (int i = 0; i < rawRateOptions.length; i++) {
        final optMap = rawRateOptions[i] as Map<String, dynamic>;
        parsedList.add(ExtractedQuotationOption.fromMap(optMap, i + 1));
      }
    } else if (extracted['freight_rate'] != null || extracted['ocean_freight'] != null) {
      parsedList.add(ExtractedQuotationOption.fromMap(extracted, 1));
    }

    final Map<String, String> cFields = {};
    final additionalExpenses = (extracted['additional_expenses'] as List<dynamic>?) ?? [];
    for (final item in additionalExpenses) {
      if (item is Map<String, dynamic>) {
        final lbl = (item['label'] ?? item['raw_label'] ?? 'مصروف إضافي').toString();
        final val = (item['formatted_value'] ?? 'USD ${item['amount']}').toString();
        cFields[lbl] = val;
      }
    }

    if (extracted['cancel_fee'] != null) {
      cFields['رسوم الإلغاء (Cancellation Fee)'] = 'USD ${extracted['cancel_fee']}';
    }

    setState(() {
      _confidenceScore = score;
      _primaryMetadata = extracted;
      _options = parsedList;
      _customFields = cFields;
      if (parsedList.isEmpty) {
        _error = 'لم يتم العثور على أية عروض أسعار صالحة في النص/المستند المدخل. يرجى التحقق من الصيغة.';
      }
    });
  }

  void _toggleSelectAll(bool? value) {
    final bool select = value ?? false;
    setState(() {
      for (final opt in _options) {
        opt.isSelected = select;
      }
    });
  }

  void _addSelectedAndClose() {
    final selected = _options.where((o) => o.isSelected).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تحديد عرض سعر واحد على الأقل للإضافة.'),
          backgroundColor: AppTheme.crimson,
        ),
      );
      return;
    }

    // Attach custom fields / additional expenses to selected options notes if not already there
    if (_customFields.isNotEmpty) {
      final customSummary = _customFields.entries.map((e) => '${e.key}: ${e.value}').join(' | ');
      for (final opt in selected) {
        if (opt.notes == null || opt.notes!.isEmpty) {
          opt.notes = customSummary;
        } else if (!opt.notes!.contains(customSummary)) {
          opt.notes = '${opt.notes!} | $customSummary';
        }
      }
    }

    widget.onAddQuotations(selected);
    Navigator.of(context).pop();
  }

  // ─── Manual Custom Field Modal ─────────────────────────────────────────────

  void _showAddCustomFieldModal() {
    String selectedPreset = 'free_time_extend';
    final keyCtrl = TextEditingController(text: 'تمديد فترة السماح (Free Time Extension)');
    final valCtrl = TextEditingController();

    final presets = {
      'free_time_extend': '⏳ تمديد فترة السماح (Free Time Extension - USD/cntr)',
      'thc_charge': '🏗️ رسوم المناولة وتداول الحاويات (THC)',
      'doc_fee': '📄 رسوم بوليصة ومستندات (Doc Fee)',
      'isps_fee': '🛡️ رسوم أمن الميناء (ISPS)',
      'seal_fee': '🔒 رسوم الرصاصة الجمركية (Seal Fee)',
      'vgm_fee': '⚖️ رسوم وزن الحاوية (VGM Fee)',
      'chassis_fee': '🚛 رسوم الشاسيه (Chassis Fee)',
      'forwarder_name': '🏢 وكيل الشحن / الناقل (Freight Forwarder)',
      'carrier_name': '🚢 الخط الملاحي (Shipping Line / Carrier)',
      'origin_port': '⚓ ميناء الشحن / السفر (Port of Loading - POL)',
      'destination_port': '⚓ ميناء الوصول / التفريغ (Port of Discharge - POD)',
      'vessel_name': '🚢 اسم الباخرة (Vessel Name)',
      'voyage_number': '🔢 رقم الرحلة (Voyage Number)',
      'etd_date': '📅 تاريخ الإبحار (ETD - YYYY-MM-DD)',
      'eta_date': '📅 تاريخ الوصول (ETA - YYYY-MM-DD)',
      'transit_days': '⏱ مدة الإبحار (Transit Days)',
      'free_time_days': '⏳ فترة السماح (Free Time Days)',
      'rate_20gp': '💵 نولون الحاوية 20 (Rate USD / 20GP)',
      'rate_40hq': '💵 نولون الحاوية 40 (Rate USD / 40HQ)',
      'local_charges': '💰 مصاريف ورسوم محلية (Local Charges USD)',
      'exw_charges': '🏭 رسوم المصنع والنقل (EXW Charges USD)',
      'notes': '📝 ملاحظات وشروط إضافية (Special Notes)',
      'custom': '➕ بيان / مصروف مخصص آخر (Custom Expense)',
    };

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Row(
            children: [
              Icon(Icons.add_box_rounded, color: AppTheme.emerald),
              SizedBox(width: 8),
              Text('إضافة بيان أو مصروف إضافي يدوياً', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('اختر نوع المصروف/البيان أو أدخل بياناً مخصصاً لعروض الأسعار:', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedPreset,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'نوع البيان / المصروف المطلوب إضافته', isDense: true),
                  items: presets.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 12.5)))).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setModalState(() {
                        selectedPreset = v;
                        if (v != 'custom') {
                          keyCtrl.text = presets[v]!.replaceAll(RegExp(r'^[^\w\s\u0600-\u06FF]+'), '').trim();
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
                    decoration: const InputDecoration(labelText: 'اسم المصروف / البيان الجديد *', hintText: 'مثلاً: Demurrage Tier 2 أو Surcharge'),
                  ),
                ],
                const SizedBox(height: 10),
                TextField(
                  controller: valCtrl,
                  decoration: const InputDecoration(labelText: 'القيمة / التفاصيل (Value) *', hintText: 'مثلاً: USD 200/ctnr أو 21 days'),
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
                    _customFields[k] = v;
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

  void _showEditCustomFieldModal(String key, String currentValue) {
    final valCtrl = TextEditingController(text: currentValue);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(Icons.edit_note_rounded, color: AppTheme.cobalt),
            const SizedBox(width: 8),
            Expanded(child: Text('تعديل: $key', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: TextField(
            controller: valCtrl,
            decoration: const InputDecoration(labelText: 'القيمة المعدلة', isDense: true),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, foregroundColor: Colors.white),
            icon: const Icon(Icons.save, size: 16),
            label: const Text('حفظ التعديل'),
            onPressed: () {
              final v = valCtrl.text.trim();
              if (v.isNotEmpty) {
                setState(() => _customFields[key] = v);
              }
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  // ─── Edit Option Modal ─────────────────────────────────────────────────────

  void _showEditOptionModal(ExtractedQuotationOption opt) {
    final carrierCtrl = TextEditingController(text: opt.carrierName);
    final fwdCtrl = TextEditingController(text: opt.forwarderName ?? '');
    final vesselCtrl = TextEditingController(text: opt.vesselName ?? '');
    final voyageCtrl = TextEditingController(text: opt.voyageNumber ?? '');
    final rateCtrl = TextEditingController(text: opt.oceanFreight.toStringAsFixed(0));
    final localCtrl = TextEditingController(text: opt.localCharges?.toStringAsFixed(0) ?? '');
    final transitCtrl = TextEditingController(text: opt.transitDays?.toString() ?? '');
    final freeTimeCtrl = TextEditingController(text: opt.freeTimeDays?.toString() ?? '');
    final etdCtrl = TextEditingController(text: opt.etdDate ?? '');
    final etaCtrl = TextEditingController(text: opt.etaDate ?? '');
    final notesCtrl = TextEditingController(text: opt.notes ?? '');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(Icons.edit_note_rounded, color: AppTheme.cobalt),
            const SizedBox(width: 8),
            Text('تعديل عرض السعر (${opt.containerType})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: TextField(controller: carrierCtrl, decoration: const InputDecoration(labelText: 'الخط الملاحي *', isDense: true))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: fwdCtrl, decoration: const InputDecoration(labelText: 'وكيل الشحن', isDense: true))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: vesselCtrl, decoration: const InputDecoration(labelText: 'اسم الباخرة', isDense: true))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: voyageCtrl, decoration: const InputDecoration(labelText: 'رقم الرحلة', isDense: true))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: rateCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'النولون البحري USD *', isDense: true))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: localCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'رسوم محلية USD', isDense: true))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: transitCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'مدة الترانزيت (أيام)', isDense: true))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: freeTimeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'فترة السماح (أيام)', isDense: true))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: etdCtrl, decoration: const InputDecoration(labelText: 'تاريخ الإبحار ETD (YYYY-MM-DD)', isDense: true))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: etaCtrl, decoration: const InputDecoration(labelText: 'تاريخ الوصول ETA (YYYY-MM-DD)', isDense: true))),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'الملاحظات والمصروفات الإضافية', isDense: true),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, foregroundColor: Colors.white),
            icon: const Icon(Icons.save, size: 16),
            label: const Text('حفظ التعديلات'),
            onPressed: () {
              setState(() {
                opt.carrierName = carrierCtrl.text.trim();
                opt.forwarderName = fwdCtrl.text.trim().isNotEmpty ? fwdCtrl.text.trim() : null;
                opt.vesselName = vesselCtrl.text.trim().isNotEmpty ? vesselCtrl.text.trim() : null;
                opt.voyageNumber = voyageCtrl.text.trim().isNotEmpty ? voyageCtrl.text.trim() : null;
                opt.oceanFreight = double.tryParse(rateCtrl.text.trim()) ?? opt.oceanFreight;
                opt.localCharges = double.tryParse(localCtrl.text.trim());
                opt.totalEstimatedCost = opt.oceanFreight + (opt.localCharges ?? 0.0);
                opt.transitDays = int.tryParse(transitCtrl.text.trim());
                opt.freeTimeDays = int.tryParse(freeTimeCtrl.text.trim());
                opt.etdDate = etdCtrl.text.trim().isNotEmpty ? etdCtrl.text.trim() : null;
                opt.etaDate = etaCtrl.text.trim().isNotEmpty ? etaCtrl.text.trim() : null;
                opt.notes = notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null;
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
    final selectedCount = _options.where((o) => o.isSelected).length;
    final hasResults = _options.isNotEmpty;

    // Watch partners and ports for live database verification
    final partnersAsync = ref.watch(allPartnersProvider);
    final portsAsync = ref.watch(transportLocationsProvider);

    final partners = partnersAsync.value ?? [];
    final portsList = portsAsync.value ?? [];

    final int confidencePercent = (_confidenceScore * 100).round();
    final bool hasUnmappedWarning = _primaryMetadata?['unmapped_expenses_warning'] != null || _customFields.isNotEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 880,
        constraints: const BoxConstraints(maxHeight: 840),
        child: Column(
          children: [
            // ─── Header Matching Smart Invoice Review UI ─────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.emerald.withOpacity(0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppTheme.emerald, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'نتائج الاستخراج — استخراج كامل (Extraction Results — Full Extraction)',
                          style: TextStyle(
                            color: AppTheme.emerald,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'عروض أسعار الشحن والنولون (Freight Quotations) · معدل الثقة: $confidencePercent%',
                          style: TextStyle(fontSize: 12, color: AppTheme.charcoal.withOpacity(0.65)),
                        ),
                      ],
                    ),
                  ),
                  // Confidence Progress Indicator Badge
                  SizedBox(
                    width: 90,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('$confidencePercent%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald, fontSize: 13)),
                        const SizedBox(height: 3),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _confidenceScore,
                            color: AppTheme.emerald,
                            backgroundColor: AppTheme.emerald.withOpacity(0.2),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black54, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Tab Bar
            TabBar(
              controller: _tabController,
              labelColor: AppTheme.cobalt,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppTheme.cobalt,
              tabs: const [
                Tab(
                  icon: Icon(Icons.text_snippet_outlined, size: 18),
                  text: '📝 لصق نص / بريد إلكتروني',
                ),
                Tab(
                  icon: Icon(Icons.document_scanner_outlined, size: 18),
                  text: '📁 رفع ملف / مستند / صورة (OCR)',
                ),
              ],
            ),

            // Body Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tab Content (Input)
                    SizedBox(
                      height: 220,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTextInputTab(),
                          _buildFileOcrTab(),
                        ],
                      ),
                    ),

                    // Error Box
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.crimson.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.crimson.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppTheme.crimson, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(color: AppTheme.crimson, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Results Section
                    if (hasResults) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 10),

                      // ── Top Header with Add Manual Field Button (Like Invoices) ────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'الحقول المستخرجة (Extracted Fields: ${_calculateTotalFieldsCount()})',
                            style: const TextStyle(
                              color: AppTheme.charcoal,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.emerald,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('➕ Add Manual Field', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: _showAddCustomFieldModal,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── Entity Verification Panel (Like Invoices) ────────────
                      _buildPartiesVerificationPanel(partners, portsList),
                      const SizedBox(height: 12),

                      // ── ⚠️ Unmapped / Special Expenses Warning Alert ─────────
                      if (hasUnmappedWarning) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber.shade400, width: 1.2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 22),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _primaryMetadata?['unmapped_expenses_warning']?.toString() ??
                                          '⚠️ تنبيه: تم اكتشاف مصروفات إضافية في العرض (Free Time Extend: USD 200/ctnr) غير مكودة قياسياً في النولون — يرجى مراجعتها وتوجيهها لتضمينها في دراسة الشحن لعدم فقدان أي تكلفة.',
                                      style: TextStyle(
                                        color: Colors.amber.shade900,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '💡 تم استخراج هذه البنود وتثبيتها أدناه (★) مع إمكانية تعديلها أو حذفها، وسيتم تضمينها تلقائياً في ملاحظات وتكاليف الشحنة.',
                                style: TextStyle(fontSize: 11.5, color: Colors.amber.shade900.withOpacity(0.85)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // ── Standard & Custom Extracted Fields List (Like Invoices) ────
                      _buildExtractedFieldsList(),
                      const SizedBox(height: 12),

                      // ── Green Options Container & Cards (Exact User Design) ──
                      _buildExtractedOptionsGreenContainer(),
                    ],
                  ],
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('إلغاء', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  const Spacer(),
                  if (hasResults)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cobalt,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: selectedCount > 0 ? _addSelectedAndClose : null,
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: Text(
                        '➕ تعبئة وإضافة العروض المحددة ($selectedCount)',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Verification Panel ────────────────────────────────────────────────────

  Widget _buildPartiesVerificationPanel(List partners, List portsList) {
    final rawForwarder = _primaryMetadata?['forwarder_name']?.toString() ??
        _options.firstOrNull?.forwarderName ??
        '';
    final rawCarrier = _primaryMetadata?['carrier_name']?.toString() ??
        _options.firstOrNull?.carrierName ??
        '';
    final rawPol = _primaryMetadata?['origin_port']?.toString() ??
        _options.firstOrNull?.originPort ??
        '';
    final rawPod = _primaryMetadata?['destination_port']?.toString() ??
        _options.firstOrNull?.destinationPort ??
        '';

    // Verify Forwarder in partners
    final matchedForwarder = rawForwarder.isNotEmpty
        ? partners.where((p) {
            final pName = (p.partnerName as String).toLowerCase();
            final rf = rawForwarder.toLowerCase();
            return pName.contains(rf) || rf.contains(pName);
          }).firstOrNull
        : null;

    // Verify Carrier in partners
    final matchedCarrier = rawCarrier.isNotEmpty
        ? partners.where((p) {
            final pName = (p.partnerName as String).toLowerCase();
            final rc = rawCarrier.toLowerCase();
            final scac = (p.scacCode ?? '').toString().toLowerCase();
            return pName.contains(rc) || rc.contains(pName) || (scac.isNotEmpty && rc.contains(scac));
          }).firstOrNull
        : null;

    return Container(
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
              Icon(Icons.verified_user_rounded, size: 16, color: AppTheme.charcoal),
              SizedBox(width: 6),
              Text(
                'التحقق من أطراف الشحن والموانئ في قاعدة البيانات (Verify Parties in DB)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Forwarder Verification Row
          if (rawForwarder.isNotEmpty) ...[
            _buildPartyRow(
              icon: Icons.business_rounded,
              title: 'وكيل الشحن / الناقل (Freight Forwarder)',
              name: rawForwarder,
              isVerified: matchedForwarder != null,
              code: matchedForwarder?.partnerCode ?? (matchedForwarder != null ? 'PRV-${matchedForwarder.providerId}' : null),
              onRegister: () => UniversalEntityExtractorDialog.show(
                context,
                initialTarget: EntityTarget.partner,
                onSaved: () => ref.invalidate(allPartnersProvider),
              ),
            ),
            const SizedBox(height: 6),
          ],

          // Shipping Line Verification Row
          if (rawCarrier.isNotEmpty) ...[
            _buildPartyRow(
              icon: Icons.directions_boat_rounded,
              title: 'الخط الملاحي (Shipping Line)',
              name: rawCarrier,
              isVerified: matchedCarrier != null,
              code: matchedCarrier?.partnerCode ?? (matchedCarrier != null ? 'PRV-${matchedCarrier.providerId}' : null),
              onRegister: () => UniversalEntityExtractorDialog.show(
                context,
                initialTarget: EntityTarget.partner,
                onSaved: () => ref.invalidate(allPartnersProvider),
              ),
            ),
            const SizedBox(height: 6),
          ],

          // Ports Row
          Row(
            children: [
              if (rawPol.isNotEmpty)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.flight_takeoff, size: 14, color: AppTheme.cobalt),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'POL: $rawPol',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.cobalt),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (rawPol.isNotEmpty && rawPod.isNotEmpty) const SizedBox(width: 8),
              if (rawPod.isNotEmpty)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.flight_land, size: 14, color: AppTheme.emerald),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'POD: $rawPod',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.emerald),
                            overflow: TextOverflow.ellipsis,
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

  Widget _buildPartyRow({
    required IconData icon,
    required String title,
    required String name,
    required bool isVerified,
    String? code,
    required VoidCallback onRegister,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isVerified ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isVerified ? const Color(0xFF86EFAC) : const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isVerified ? AppTheme.emerald : AppTheme.crimson),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
                Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (isVerified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.emerald.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 12, color: AppTheme.emerald),
                  const SizedBox(width: 4),
                  Text(
                    code != null ? 'مسجل ($code)' : 'مسجل في النظام',
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.emerald),
                  ),
                ],
              ),
            )
          else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.crimson.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cancel_rounded, size: 12, color: AppTheme.crimson),
                  SizedBox(width: 4),
                  Text('غير مسجل (Unconfirmed)', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.crimson)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.cobalt,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.add, size: 14),
              label: const Text('سجّل +', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              onPressed: onRegister,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextInputTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'الصق نص الإيميل أو عرض السعر الوارد من شركة الشحن:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.charcoal),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _loadSampleText,
              icon: const Icon(Icons.content_paste_go, size: 14, color: AppTheme.cobalt),
              label: const Text('📋 تحميل نص تجريبي', style: TextStyle(fontSize: 11, color: AppTheme.cobalt)),
            ),
            if (_textController.text.isNotEmpty)
              TextButton.icon(
                onPressed: () => setState(() {
                  _textController.clear();
                  _options = [];
                  _primaryMetadata = null;
                  _error = null;
                }),
                icon: const Icon(Icons.clear_all, size: 14, color: Colors.grey),
                label: const Text('مسح', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          child: TextField(
            controller: _textController,
            maxLines: null,
            expands: true,
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: 'مثال:\nRoute: Shanghai - El Dekheila\nWHL: USD 6700/40HQ BY WHL\nTransit: 29 days direct | Free time: 21 days\nLocal: USD 880/40HQ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.all(12),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.cobalt,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _isExtracting ? null : _extractFromText,
          icon: _isExtracting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.search, color: Colors.white),
          label: Text(
            _isExtracting ? 'جاري التحليل والاستخراج...' : '🔍 استخراج عروض الأسعار من النص',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildFileOcrTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: InkWell(
            onTap: _pickFile,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _pickedFile != null ? AppTheme.cobalt : Colors.grey.shade300, width: 1.5),
              ),
              child: Center(
                child: _pickedFile == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload_outlined, size: 42, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          const Text(
                            'اضغط هنا لاختيار ملف عرض السعر أو اسحب وأفلت الملف',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'يدعم PDF، صور (PNG, JPG, WEBP)، مستندات Word، وجداول Excel',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_getFileIcon(_pickedFile!.name), size: 36, color: AppTheme.cobalt),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _pickedFile!.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                          const SizedBox(width: 20),
                          OutlinedButton.icon(
                            onPressed: _pickFile,
                            icon: const Icon(Icons.refresh, size: 14),
                            label: const Text('تغيير الملف', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.cobalt,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: (_isExtracting || _pickedFile == null) ? null : _extractFromFileOcr,
          icon: _isExtracting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.document_scanner, color: Colors.white),
          label: Text(
            _isExtracting ? 'جاري المسح الضوئي (OCR)...' : '🚀 قراءة واستخراج بالماسح الضوئي (OCR Scan)',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  IconData _getFileIcon(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.webp')) {
      return Icons.image;
    }
    if (lower.endsWith('.xlsx') || lower.endsWith('.xls')) return Icons.table_chart;
    return Icons.insert_drive_file;
  }

  Widget _buildGlobalMetadataBanner() {
    final origin = _primaryMetadata!['origin_port'] ?? 'غير محدد';
    final dest = _primaryMetadata!['destination_port'] ?? 'غير محدد';
    final inco = _primaryMetadata!['incoterm'] ?? 'FOB';
    final curr = _primaryMetadata!['currency'] ?? 'USD';
    final ref = _primaryMetadata!['quotation_ref'];
    final forwarder = _primaryMetadata!['forwarder_name'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.charcoal.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.charcoal.withOpacity(0.12)),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.route, size: 16, color: AppTheme.cobalt),
              const SizedBox(width: 6),
              Text(
                '$origin ➜ $dest',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_shipping, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text('الشرط: $inco', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.attach_money, size: 16, color: Colors.grey),
              Text('العملة: $curr', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          if (forwarder != null && forwarder.toString().isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.business, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('الشركة/الوكيل: $forwarder', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          if (ref != null && ref.toString().isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.tag, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('المرجع: $ref', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildExtractedOptionsGreenContainer() {
    final pol = _primaryMetadata?['origin_port']?.toString() ?? _options.firstOrNull?.originPort;
    final pod = _primaryMetadata?['destination_port']?.toString() ?? _options.firstOrNull?.destinationPort;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Header Row ────────────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppTheme.emerald, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'تم استخراج ${_options.length} عرض/عروض أسعار بنجاح! راجع العروض أدناه ثم أضفها لدراسة المفاضلة:',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.charcoal),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emerald,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 1,
                ),
                icon: const Icon(Icons.add_task, size: 15, color: Colors.white),
                label: Text(
                  'إضافة كافة العروض (${_options.length}) 🚀 +',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                ),
                onPressed: () {
                  for (final opt in _options) {
                    opt.isSelected = true;
                  }
                  _addSelectedAndClose();
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Ports Chips Row ───────────────────────────────────────────────
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              if (pol != null && pol.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black87, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flight_takeoff, size: 15, color: AppTheme.cobalt),
                      const SizedBox(width: 6),
                      Text(
                        'ميناء الشحن: $pol',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                      ),
                    ],
                  ),
                ),
              if (pod != null && pod.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black87, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flight_land, size: 15, color: AppTheme.emerald),
                      const SizedBox(width: 6),
                      Text(
                        'ميناء الوصول: $pod',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Quotation Cards Grid / Wrap ──────────────────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 580;
              final cardWidth = isWide ? (constraints.maxWidth - 12) / 2 : double.infinity;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _options.map((opt) {
                  return SizedBox(
                    width: cardWidth,
                    child: _buildQuotationCardMatched(opt),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuotationCardMatched(ExtractedQuotationOption opt) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Title & Direct/Transit Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${opt.carrierName} (${opt.containerType})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.cobalt,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: opt.isDirect ? const Color(0xFFF0FDF4) : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: opt.isDirect ? const Color(0xFF86EFAC) : Colors.orange.shade200,
                  ),
                ),
                child: Text(
                  opt.isDirect ? 'مباشر (Direct)' : 'ترانزيت (Transit)',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: opt.isDirect ? Colors.green.shade800 : Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(height: 8, thickness: 1),
          const SizedBox(height: 6),

          // Price Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'نولون: \$${opt.oceanFreight.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
              if (opt.localCharges != null && opt.localCharges! > 0)
                Text(
                  'محلي: \$${opt.localCharges!.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              Text(
                'الإجمالي: \$${opt.totalEstimatedCost.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Transit & Demurrage Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '⏱️ ترانزيت: ${opt.transitDays ?? "-"} يوم',
                style: const TextStyle(fontSize: 11, color: Colors.black87),
              ),
              Text(
                '⏳ سماح: ${opt.freeTimeDays ?? 14} يوم FT',
                style: const TextStyle(fontSize: 11, color: Colors.black87),
              ),
            ],
          ),

          // Extra Notes / Unmapped Expenses Pill (if any)
          if (opt.notes != null && opt.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Text(
                '★ ${opt.notes!}',
                style: const TextStyle(fontSize: 10.5, color: AppTheme.cobalt, fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const SizedBox(height: 8),

          // Full-width Add Button (Outlined Blue Button with + icon)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.cobalt,
                side: const BorderSide(color: AppTheme.cobalt, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              icon: const Icon(Icons.add, size: 16),
              label: const Text(
                '+ إضافة هذا العرض للسيناريو',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                widget.onAddQuotations([opt]);
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }

  int _calculateTotalFieldsCount() {
    int count = 0;
    if (_primaryMetadata != null) {
      if (_primaryMetadata!['origin_port'] != null) count++;
      if (_primaryMetadata!['destination_port'] != null) count++;
      if (_primaryMetadata!['carrier_name'] != null) count++;
      if (_primaryMetadata!['forwarder_name'] != null) count++;
      if (_primaryMetadata!['etd_date'] != null) count++;
      if (_primaryMetadata!['transit_days'] != null) count++;
      if (_primaryMetadata!['free_days_demurrage'] != null) count++;
    }
    count += _options.length;
    count += _customFields.length;
    return count;
  }

  Widget _buildExtractedFieldsList() {
    final pol = _primaryMetadata?['origin_port']?.toString() ?? _options.firstOrNull?.originPort;
    final pod = _primaryMetadata?['destination_port']?.toString() ?? _options.firstOrNull?.destinationPort;
    final carrier = _primaryMetadata?['carrier_name']?.toString() ?? _options.firstOrNull?.carrierName;
    final fwd = _primaryMetadata?['forwarder_name']?.toString() ?? _options.firstOrNull?.forwarderName;
    final etd = _primaryMetadata?['etd_date']?.toString() ?? _options.firstOrNull?.etdDate;
    final transit = _primaryMetadata?['transit_days']?.toString() ?? _options.firstOrNull?.transitDays?.toString();
    final freeTime = _primaryMetadata?['free_days_demurrage']?.toString() ?? _options.firstOrNull?.freeTimeDays?.toString();

    return Column(
      children: [
        // Standard Fields
        if (pol != null && pol.isNotEmpty)
          _buildFieldRow(label: 'POL (Port of Loading)', value: pol, isCustom: false),
        if (pod != null && pod.isNotEmpty)
          _buildFieldRow(label: 'POD (Port of Discharge)', value: pod, isCustom: false),
        if (carrier != null && carrier.isNotEmpty)
          _buildFieldRow(label: 'Carrier (الخط الملاحي)', value: carrier, isCustom: false),
        if (fwd != null && fwd.isNotEmpty)
          _buildFieldRow(label: 'Freight Forwarder (وكيل الشحن)', value: fwd, isCustom: false),
        if (etd != null && etd.isNotEmpty)
          _buildFieldRow(label: 'ETD (تاريخ الإبحار)', value: etd, isCustom: false),
        if (transit != null && transit.isNotEmpty)
          _buildFieldRow(label: 'Transit Time (مدة الإبحار)', value: '$transit days direct', isCustom: false),
        if (freeTime != null && freeTime.isNotEmpty)
          _buildFieldRow(label: 'Free Time (فترة السماح)', value: '$freeTime days', isCustom: false),

        // Custom & Unmapped Starred Fields
        ..._customFields.entries.map(
          (e) => _buildFieldRow(
            label: '★ ${e.key}',
            value: e.value,
            isCustom: true,
            onEdit: () => _showEditCustomFieldModal(e.key, e.value),
            onDelete: () => setState(() => _customFields.remove(e.key)),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldRow({
    required String label,
    required String value,
    required bool isCustom,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isCustom ? const Color(0xFFEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCustom ? const Color(0xFF93C5FD) : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isCustom ? FontWeight.bold : FontWeight.w600,
                color: isCustom ? AppTheme.cobalt : AppTheme.charcoal,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
          if (isCustom) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.cobalt),
              tooltip: 'تعديل هذا البند',
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 16, color: AppTheme.crimson),
              tooltip: 'حذف هذا البند',
              onPressed: onDelete,
            ),
          ] else
            const SizedBox(width: 32),
        ],
      ),
    );
  }
}
