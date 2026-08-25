import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/widgets/extraction_progress_dialog.dart';

/// Data class representing an extracted freight quotation option.
class ExtractedQuotationOption {
  final int optionId;
  final String carrierName;
  final String? forwarderName;
  final String? vesselName;
  final String? voyageNumber;
  final String containerType;
  final double oceanFreight;
  final double? localCharges;
  final double? exwCharges;
  final double totalEstimatedCost;
  final String currency;
  final String? incoterm;
  final String? originPort;
  final String? destinationPort;
  final int? transitDays;
  final bool isDirect;
  final int? freeTimeDays;
  final String? etdDate;
  final String? etaDate;
  final String? notes;
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

/// Advanced Freight Quotations Extractor Dialog supporting Text & OCR Scans.
class FreightQuotationsExtractorDialog extends StatefulWidget {
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
  State<FreightQuotationsExtractorDialog> createState() => _FreightQuotationsExtractorDialogState();
}

class _FreightQuotationsExtractorDialogState extends State<FreightQuotationsExtractorDialog>
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

  static const String _sampleQuoteText = '''
Dear Ahmed,
Please find below our best rates for your shipment:

Route: Shanghai – El Dekheila
Local charges: Approx. USD 880/40HQ
Ocean freight:
• WHL: USD 6,700/40HQ  ETD: 28/AUG
  Transit time: 29 days, DIRECT
  Free time: 21 days FT

• YML: USD 6,180/40HQ  ETD: 27/AUG
  Transit time: 48 days, INDIRECT
  Free time: 21 days FT

• MSC: USD 6,950/40HQ  ETD: 30/AUG
  Transit time: 27 days, DIRECT
  Free time: 14 days FT (INCL OWS)

Cancellation fee: \$100/cntr
Best regards,
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
    });

    final progressCtrl = ExtractionProgressController();
    progressCtrl.update(
      percent: 0.20,
      status: 'جاري فحص وتحليل نصوص البريد الإلكتروني...',
      stepLabel: 'المرحلة 1 من 3: معالجة النصوص',
      currentStep: 1,
    );

    ExtractionProgressDialog.show(
      context: context,
      title: 'استخراج عروض أسعار الشحن من النص',
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

    final List<ExtractedQuotationOption> parsedList = [];

    if (rawRateOptions.isNotEmpty) {
      for (int i = 0; i < rawRateOptions.length; i++) {
        final optMap = rawRateOptions[i] as Map<String, dynamic>;
        parsedList.add(ExtractedQuotationOption.fromMap(optMap, i + 1));
      }
    } else if (extracted['freight_rate'] != null || extracted['ocean_freight'] != null) {
      parsedList.add(ExtractedQuotationOption.fromMap(extracted, 1));
    }

    setState(() {
      _primaryMetadata = extracted;
      _options = parsedList;
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

    widget.onAddQuotations(selected);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _options.where((o) => o.isSelected).length;
    final hasResults = _options.isNotEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 820,
        constraints: const BoxConstraints(maxHeight: 780),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: AppTheme.charcoal,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppTheme.cobalt, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'استخراج عروض أسعار الشحن الذكي (Text & OCR)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
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
                      height: 240,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Tab 0: Raw Text
                          _buildTextInputTab(),
                          // Tab 1: File OCR
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
                      _buildResultsHeader(selectedCount),
                      const SizedBox(height: 10),
                      if (_primaryMetadata != null) _buildGlobalMetadataBanner(),
                      const SizedBox(height: 10),
                      ..._options.map((opt) => _buildOptionCard(opt)),
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
                    child: const Text('إلغاء'),
                  ),
                  const Spacer(),
                  if (hasResults)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emerald,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: selectedCount > 0 ? _addSelectedAndClose : null,
                      icon: const Icon(Icons.playlist_add_check, color: Colors.white),
                      label: Text(
                        '➕ إضافة كافة العروض المحددة ($selectedCount)',
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
        const SizedBox(height: 10),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.cobalt,
            padding: const EdgeInsets.symmetric(vertical: 12),
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
        const SizedBox(height: 10),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.cobalt,
            padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildResultsHeader(int selectedCount) {
    final allSelected = _options.isNotEmpty && selectedCount == _options.length;

    return Row(
      children: [
        Checkbox(
          value: allSelected,
          tristate: selectedCount > 0 && selectedCount < _options.length,
          onChanged: (val) => _toggleSelectAll(val ?? false),
        ),
        Text(
          'تحديد الكل (${_options.length} عروض مستخرجة)',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.emerald.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.emerald.withOpacity(0.3)),
          ),
          child: Text(
            'محدد: $selectedCount من ${_options.length}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.emerald),
          ),
        ),
      ],
    );
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

  Widget _buildOptionCard(ExtractedQuotationOption opt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: opt.isSelected ? AppTheme.cobalt.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: opt.isSelected ? AppTheme.cobalt.withOpacity(0.4) : Colors.grey.shade200,
          width: opt.isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: opt.isSelected,
            onChanged: (val) => setState(() => opt.isSelected = val ?? false),
          ),
          // Carrier & Type
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.directions_boat, size: 16, color: AppTheme.cobalt),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        opt.carrierName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.cobalt.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        opt.containerType,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.cobalt),
                      ),
                    ),
                  ],
                ),
                if (opt.notes != null && opt.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(opt.notes!, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Direct / Transit badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: opt.isDirect ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: opt.isDirect ? Colors.green.shade200 : Colors.orange.shade200),
            ),
            child: Text(
              opt.isDirect ? '🚀 مباشر' : '🔄 ترانزيت',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: opt.isDirect ? Colors.green.shade800 : Colors.orange.shade800,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Price Details
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'النولون: \$${opt.oceanFreight.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green),
                ),
                if (opt.localCharges != null && opt.localCharges! > 0)
                  Text(
                    'رسوم محلية: \$${opt.localCharges!.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                Text(
                  'الإجمالي: \$${opt.totalEstimatedCost.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Transit & Demurrage
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (opt.transitDays != null)
                  Text('ترانزيت: ${opt.transitDays} يوم', style: const TextStyle(fontSize: 11)),
                if (opt.freeTimeDays != null)
                  Text('سماح: ${opt.freeTimeDays} يوم', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Individual Add Button
          IconButton(
            tooltip: 'إضافة هذا العرض فقط',
            icon: const Icon(Icons.add_circle, color: AppTheme.emerald, size: 24),
            onPressed: () {
              widget.onAddQuotations([opt]);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
