import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/container_requirement_engine.dart';
import '../../../core/widgets/master_data_toolbar.dart';
import '../../../core/widgets/row_actions_pill.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/error_details_dialog.dart';
import '../../../core/widgets/extraction_progress_dialog.dart';
import '../../external_service_providers/providers/partners_provider.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../../purchase_orders/providers/purchase_orders_provider.dart';
import '../../transport_locations/providers/transport_locations_provider.dart';
import '../models/freight_quotation_model.dart';
import '../providers/freight_quotations_provider.dart';
import '../widgets/freight_quotations_extractor_dialog.dart';

class FreightQuotationsScreen extends ConsumerStatefulWidget {
  final int? initialImportFileId;
  const FreightQuotationsScreen({super.key, this.initialImportFileId});

  @override
  ConsumerState<FreightQuotationsScreen> createState() => _FreightQuotationsScreenState();
}

class _FreightQuotationsScreenState extends ConsumerState<FreightQuotationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form State
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController(text: 'طلب عرض سعر شحن حاويات لمعدات وآلات خط الإنتاج');
  final TextEditingController _cbmController = TextEditingController(text: '128.5');
  final TextEditingController _weightController = TextEditingController(text: '48500.0');
  final TextEditingController _notesController = TextEditingController();

  DateTime _crdDate = DateTime.now().add(const Duration(days: 15));
  String _shippingMethod = 'Ocean FCL';
  String _polName = 'Shanghai Port (CN SHA), China';
  String _podName = 'Alexandria Port (EG ALX), Egypt';
  int? _selectedImportFileId;
  int? _selectedPoId;
  int? _selectedProjectId;

  final List<FreightQuotationItemModel> _quotations = [];
  bool _isSaving = false;
  bool _isStackable = true;

  // ── Smart AI Extractor State (Text & OCR) ──────────────────────────────
  bool _isFreightExtractorExpanded = true;
  bool _isFreightExtracting = false;
  final TextEditingController _rawFreightQuoteController = TextEditingController();
  List<ExtractedQuotationOption> _extractedOptions = [];
  Map<String, dynamic>? _extractedFreightMetadata;
  PlatformFile? _pickedFreightFile;
  String? _extractorError;

  // Search & Filter
  String _searchQuery = '';
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.initialImportFileId != null) {
      _selectedImportFileId = widget.initialImportFileId;
    }
    Future.microtask(() {
      ref.read(freightQuotationsProvider.notifier).fetchRFQs();
      ref.read(importFilesProvider.notifier).fetchImportFiles().then((_) {
        if (widget.initialImportFileId != null && mounted) {
          setState(() {
            _populateFromImportFile(widget.initialImportFileId!);
          });
        }
      });
    });
  }

  void _populateFromImportFile(int fileId) {
    final importFilesList = ref.read(importFilesProvider).value ?? [];
    final selectedFile = importFilesList.where((f) => f.importFileId == fileId).firstOrNull;
    if (selectedFile == null) return;

    // 1. Title (عنوان طلب عرض السعر)
    if (selectedFile.customFileNumber != null && selectedFile.customFileNumber!.trim().isNotEmpty) {
      _titleController.text = selectedFile.customFileNumber!.trim();
    } else if (selectedFile.poNumber != null && selectedFile.poNumber!.trim().isNotEmpty) {
      _titleController.text = '${selectedFile.poNumber} - ${selectedFile.supplierName}';
    } else {
      _titleController.text = '[${selectedFile.importFileCode}] ${selectedFile.supplierName}';
    }

    // 2. Shipping Method (وسيلة الشحن)
    final sm = selectedFile.shipmentMode.trim();
    if (sm == 'Sea FCL' || sm == 'Sea') {
      _shippingMethod = 'Ocean FCL';
    } else if (sm == 'Sea LCL') {
      _shippingMethod = 'Ocean LCL';
    } else if (sm == 'Air') {
      _shippingMethod = 'Air Freight';
    } else if (sm == 'Courier') {
      _shippingMethod = 'Courier Express';
    } else if (sm == 'Land') {
      _shippingMethod = 'Inland Trucking';
    } else if (sm == 'Multimodal' || sm == 'Multi-Modal') {
      _shippingMethod = 'Multi-Modal';
    } else if (sm.isNotEmpty) {
      _shippingMethod = sm;
    }

    // 3. Cargo Ready Date (تاريخ جاهزية البضاعة CRD)
    if (selectedFile.cargoReadyDate != null && selectedFile.cargoReadyDate!.trim().isNotEmpty) {
      final parsedDate = DateTime.tryParse(selectedFile.cargoReadyDate!.trim());
      if (parsedDate != null) {
        _crdDate = parsedDate;
      }
    }

    // 4. Port of Loading (ميناء التحميل POL)
    if (selectedFile.portOfLoading != null && selectedFile.portOfLoading!.trim().isNotEmpty) {
      _polName = selectedFile.portOfLoading!.trim();
    }

    // 5. Port of Discharge (ميناء الوصول POD)
    if (selectedFile.portOfDischarge != null && selectedFile.portOfDischarge!.trim().isNotEmpty) {
      _podName = selectedFile.portOfDischarge!.trim();
    }

    // 6. CBM & Weight calculation (إجمالي الحجم والوزن القائم)
    double calcCbm = 0.0;
    double calcWeight = 0.0;
    bool? foundStackable;

    if (selectedFile.packingListsData.isNotEmpty) {
      for (var pl in selectedFile.packingListsData) {
        calcCbm += pl.cbm;
        calcWeight += pl.grossWeightKg;
        if (pl.isStackable != null) {
          foundStackable = pl.isStackable;
        }
      }
    }
    if (calcCbm == 0 && calcWeight == 0) {
      final allPOs = ref.read(purchaseOrdersProvider).purchaseOrders;
      final filePoIds = selectedFile.poIds ?? [];
      for (var po in allPOs) {
        if (filePoIds.contains(po.poId) || po.importFileId == selectedFile.importFileId) {
          if (po.packingListItems.isNotEmpty) {
            for (var pl in po.packingListItems) {
              calcCbm += (pl.totalCbm > 0 ? pl.totalCbm : pl.calculatedCbm);
              calcWeight += (pl.totalGrossWeightKg > 0 ? pl.totalGrossWeightKg : (pl.grossWeightUnitKg * pl.qtyPkg));
            }
          } else {
            calcCbm += po.totalCbm;
            calcWeight += po.totalGrossWeightKg;
          }
        }
      }
    }
    if (calcCbm > 0) _cbmController.text = calcCbm.toStringAsFixed(2);
    if (calcWeight > 0) _weightController.text = calcWeight.toStringAsFixed(1);
    if (foundStackable != null) _isStackable = foundStackable;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _cbmController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    _rawFreightQuoteController.dispose();
    super.dispose();
  }

  void _addQuotationDialog({
    String? prefillCarrierName,
    int? prefillProviderId,
    double? prefillOceanCost,
    double? prefillLocalCost,
    int? prefillTransitDays,
    int? prefillFreeDays,
    String? prefillRemarks,
  }) {
    final partnersState = ref.read(partnersProvider);
    final partnersList = partnersState.value ?? [];
    final carriersList = partnersList.where((p) => p.partnerType.contains('Shipping Line') || p.partnerType.contains('Freight')).toList();

    if (carriersList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ يرجى إضافة ناقلين بحريين (Shipping Lines) في دليل الشركاء أولاً'), backgroundColor: Colors.orange),
      );
      return;
    }

    // Try to find matching carrier if prefill name provided
    int? matchedProviderId = prefillProviderId;
    String matchedProviderName = carriersList.first.partnerName;
    if (prefillProviderId != null) {
      final found = carriersList.where((c) => c.providerId == prefillProviderId).firstOrNull;
      if (found != null) matchedProviderName = found.partnerName;
    } else if (prefillCarrierName != null && prefillCarrierName.isNotEmpty) {
      final nameLower = prefillCarrierName.toLowerCase();
      final found = carriersList.where((c) => c.partnerName.toLowerCase().contains(nameLower) || nameLower.contains(c.partnerName.toLowerCase())).firstOrNull;
      if (found != null) {
        matchedProviderId = found.providerId;
        matchedProviderName = found.partnerName;
      } else {
        matchedProviderId = carriersList.first.providerId;
      }
    } else {
      matchedProviderId = carriersList.first.providerId;
    }

    showDialog(
      context: context,
      builder: (context) {
        int? selectedProviderId = matchedProviderId;
        String selectedProviderName = matchedProviderName;
        final vesselController = TextEditingController();
        final voyageController = TextEditingController();
        final oceanCostController = TextEditingController(text: prefillOceanCost != null ? prefillOceanCost.toStringAsFixed(0) : '3000.0');
        final localCostController = TextEditingController(text: prefillLocalCost != null ? prefillLocalCost.toStringAsFixed(0) : '400.0');
        final inlandCostController = TextEditingController(text: '0.0');
        final freeDaysController = TextEditingController(text: prefillFreeDays?.toString() ?? '14');
        final remarksController = TextEditingController(text: prefillRemarks ?? '');

        // Calculate arrival from transit days if available
        DateTime sailingDate = _crdDate.add(const Duration(days: 4));
        DateTime arrivalDate = prefillTransitDays != null
            ? sailingDate.add(Duration(days: prefillTransitDays))
            : sailingDate.add(const Duration(days: 24));

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.directions_boat, color: AppTheme.cobalt),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    prefillCarrierName != null ? 'مراجعة وتأكيد عرض السعر المستخرج' : 'إضافة عرض سعر ناقل / شركة شحن (Add Freight Quote)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  )),
                ],
              ),
              content: SizedBox(
                width: 550,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (prefillCarrierName != null && prefillCarrierName.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.cobalt.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.cobalt.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome, color: AppTheme.cobalt, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(
                                '🤖 تم استخراج هذا العرض تلقائياً من النص. راجع البيانات قبل الإضافة.',
                                style: TextStyle(fontSize: 12, color: AppTheme.cobalt.withOpacity(0.8)),
                              )),
                            ],
                          ),
                        ),
                      SearchableDropdownField<int?>(
                        value: selectedProviderId,
                        labelText: 'شركة الشحن / الخط الملاحي *',
                        searchHintText: 'ابحث عن الشركة...',
                        items: carriersList.map((c) => SearchableDropdownItem<int?>(value: c.providerId, label: c.partnerName)).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final c = carriersList.firstWhere((p) => p.providerId == val);
                            setDialogState(() {
                              selectedProviderId = val;
                              selectedProviderName = c.partnerName;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: vesselController,
                              decoration: const InputDecoration(labelText: 'اسم السفينة (Vessel Name)', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: voyageController,
                              decoration: const InputDecoration(labelText: 'رقم الرحلة (Voyage No)', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: oceanCostController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'نولون البحر (Ocean Freight USD) *', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: localCostController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'المصاريف المحلية (USD)', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: inlandCostController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'النقل الداخلي (USD)', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final d = await showDatePicker(context: context, initialDate: sailingDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                                if (d != null) setDialogState(() => sailingDate = d);
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(labelText: 'تاريخ الإبحار (Sailing Date)', border: OutlineInputBorder()),
                                child: Text(sailingDate.toString().substring(0, 10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final d = await showDatePicker(context: context, initialDate: arrivalDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                                if (d != null) setDialogState(() => arrivalDate = d);
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(labelText: 'تاريخ الوصول (ETA Arrival)', border: OutlineInputBorder()),
                                child: Text(arrivalDate.toString().substring(0, 10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: freeDaysController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'أيام السماح بالجمارك (Free Days)', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: remarksController,
                        decoration: const InputDecoration(labelText: 'ملاحظات العرض', border: OutlineInputBorder()),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                  onPressed: () {
                    final oceanCost = double.tryParse(oceanCostController.text.trim()) ?? 0.0;
                    final localCost = double.tryParse(localCostController.text.trim()) ?? 0.0;
                    final inlandCost = double.tryParse(inlandCostController.text.trim()) ?? 0.0;
                    final totalCost = oceanCost + localCost + inlandCost;
                    final transitDays = arrivalDate.difference(sailingDate).inDays;

                    setState(() {
                      _quotations.add(FreightQuotationItemModel(
                        providerId: selectedProviderId!,
                        providerName: selectedProviderName,
                        vesselName: vesselController.text.trim().isNotEmpty ? vesselController.text.trim() : null,
                        voyageNumber: voyageController.text.trim().isNotEmpty ? voyageController.text.trim() : null,
                        oceanFreightCost: oceanCost,
                        localChargesCost: localCost,
                        inlandCost: inlandCost,
                        totalCost: totalCost,
                        sailingDate: sailingDate.toString().substring(0, 10),
                        estimatedArrivalDate: arrivalDate.toString().substring(0, 10),
                        transitDays: transitDays > 0 ? transitDays : 1,
                        freeDaysAtPod: int.tryParse(freeDaysController.text.trim()) ?? 14,
                        remarks: remarksController.text.trim().isNotEmpty ? remarksController.text.trim() : null,
                      ));
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('إضافة العرض', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// ─── Freight Quotations Smart Extractor Dialog (Text & OCR) ─────────────
  void _showFreightExtractorDialog() {
    FreightQuotationsExtractorDialog.show(
      context,
      onAddQuotations: (selectedOptions) {
        final partners = ref.read(partnersProvider).valueOrNull ?? [];
        final defaultSailingDate = DateTime.now().add(const Duration(days: 7));

        setState(() {
          for (final opt in selectedOptions) {
            int providerId = 0;
            String providerName = opt.carrierName;

            final matchedPartner = partners.cast<dynamic>().firstWhere(
              (p) {
                final name = (p.name ?? '').toString().toLowerCase();
                final optName = opt.carrierName.toLowerCase();
                return name.contains(optName) || optName.contains(name);
              },
              orElse: () => null,
            );

            if (matchedPartner != null) {
              providerId = matchedPartner.id as int? ?? 0;
              providerName = matchedPartner.name as String? ?? opt.carrierName;
            }

            final transitDays = opt.transitDays ?? 28;
            final arrivalDate = defaultSailingDate.add(Duration(days: transitDays));

            _quotations.add(
              FreightQuotationItemModel(
                providerId: providerId,
                providerName: providerName,
                vesselName: null,
                voyageNumber: opt.containerType,
                oceanFreightCost: opt.oceanFreight,
                localChargesCost: opt.localCharges ?? 0.0,
                inlandCost: opt.exwCharges ?? 0.0,
                totalCost: opt.totalEstimatedCost,
                sailingDate: defaultSailingDate.toString().substring(0, 10),
                estimatedArrivalDate: arrivalDate.toString().substring(0, 10),
                transitDays: transitDays,
                freeDaysAtPod: opt.freeTimeDays ?? 14,
                remarks: [
                  if (opt.notes != null && opt.notes!.isNotEmpty) opt.notes,
                  if (opt.containerType.isNotEmpty) 'نوع الحاوية: ${opt.containerType}',
                  if (!opt.isDirect) 'خط سير غير مباشر (ترانزيت)',
                ].join(' | '),
              ),
            );
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تمت إضافة ${selectedOptions.length} عرض/عروض أسعار بنجاح إلى المقارنة!'),
            backgroundColor: AppTheme.emerald,
          ),
        );
      },
    );
  }


  static const String _sampleFreightQuoteText = '''
Dear Ahmed,
Please find below our best rates for your shipment:

Route: Shanghai – Alexandria
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

  void _loadSampleFreightQuote() {
    setState(() {
      _rawFreightQuoteController.text = _sampleFreightQuoteText.trim();
      _extractorError = null;
    });
  }

  Future<void> _extractFreightFromText() async {
    final text = _rawFreightQuoteController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ يرجى لصق أو كتابة نص رسالة/إيميل عرض السعر أولاً'), backgroundColor: AppTheme.orange),
      );
      return;
    }

    setState(() {
      _isFreightExtracting = true;
      _extractorError = null;
      _extractedOptions = [];
      _extractedFreightMetadata = null;
    });

    final progressCtrl = ExtractionProgressController();
    progressCtrl.update(
      percent: 0.20,
      status: 'جاري فحص وتحليل نصوص عروض الأسعار...',
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

      _processExtractedFreightData(response.data);
    } on DioException catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      setState(() => _extractorError = 'خطأ في الاتصال بالخادم: ${e.message}');
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      setState(() => _extractorError = 'حدث خطأ أثناء الاستخراج: $e');
    } finally {
      if (mounted) setState(() => _isFreightExtracting = false);
    }
  }

  Future<void> _extractFreightFromFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'webp', 'xlsx', 'xls', 'docx', 'doc', 'txt'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.bytes == null) return;

      setState(() {
        _pickedFreightFile = file;
        _isFreightExtracting = true;
        _extractorError = null;
        _extractedOptions = [];
        _extractedFreightMetadata = null;
      });

      final fileSizeFormatted = file.size > 1024 * 1024
          ? '${(file.size / (1024 * 1024)).toStringAsFixed(2)} MB'
          : '${(file.size / 1024).toStringAsFixed(1)} KB';

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

      _processExtractedFreightData(response.data);
    } on DioException catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      setState(() => _extractorError = 'خطأ في معالجة الملف بالـ OCR: ${e.message}');
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      setState(() => _extractorError = 'حدث خطأ أثناء معالجة المستند: $e');
    } finally {
      if (mounted) setState(() => _isFreightExtracting = false);
    }
  }

  void _processExtractedFreightData(dynamic data) {
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

    if (data['raw_text'] != null && (data['raw_text'] as String).isNotEmpty) {
      _rawFreightQuoteController.text = data['raw_text'] as String;
    }

    // Auto-populate POL / POD if detected
    if (extracted['origin_port'] != null && (extracted['origin_port'] as String).isNotEmpty) {
      final originStr = extracted['origin_port'].toString();
      final ports = ref.read(transportLocationsProvider).value ?? [];
      final matched = ports.where((p) => p.locationName.toLowerCase().contains(originStr.toLowerCase()) || originStr.toLowerCase().contains(p.locationName.toLowerCase())).firstOrNull;
      if (matched != null) {
        _polName = matched.locationName;
      }
    }
    if (extracted['destination_port'] != null && (extracted['destination_port'] as String).isNotEmpty) {
      final destStr = extracted['destination_port'].toString();
      final ports = ref.read(transportLocationsProvider).value ?? [];
      final matched = ports.where((p) => p.locationName.toLowerCase().contains(destStr.toLowerCase()) || destStr.toLowerCase().contains(p.locationName.toLowerCase())).firstOrNull;
      if (matched != null) {
        _podName = matched.locationName;
      }
    }

    setState(() {
      _extractedFreightMetadata = extracted;
      _extractedOptions = parsedList;
      if (parsedList.isEmpty) {
        _extractorError = 'لم يتم العثور على أية عروض أسعار صالحة في النص/المستند المدخل. يرجى التحقق من النص.';
      }
    });

    if (parsedList.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✨ تم بنجاح استخراج ${parsedList.length} عرض/عروض أسعار! يمكنك مراجعتها وإضافتها فوراً.'),
          backgroundColor: AppTheme.emerald,
        ),
      );
    }
  }

  void _addAllExtractedQuotations() {
    if (_extractedOptions.isEmpty) return;
    final partners = ref.read(allPartnersProvider).value ?? ref.read(partnersProvider).valueOrNull ?? [];

    setState(() {
      for (final opt in _extractedOptions) {
        int providerId = 0;
        String providerName = opt.carrierName;

        final matchedPartner = partners.cast<dynamic>().firstWhere(
          (p) {
            final name = (p.partnerName ?? p.name ?? '').toString().toLowerCase();
            final optName = opt.carrierName.toLowerCase();
            return name.contains(optName) || optName.contains(name);
          },
          orElse: () => null,
        );

        if (matchedPartner != null) {
          providerId = matchedPartner.providerId as int? ?? matchedPartner.id as int? ?? 0;
          providerName = matchedPartner.partnerName as String? ?? matchedPartner.name as String? ?? opt.carrierName;
        }

        final transitDays = opt.transitDays ?? 28;
        DateTime sailingDate = DateTime.now().add(const Duration(days: 7));
        if (opt.etdDate != null && opt.etdDate!.isNotEmpty) {
          final parsed = DateTime.tryParse(opt.etdDate!);
          if (parsed != null) sailingDate = parsed;
        }

        DateTime arrivalDate = sailingDate.add(Duration(days: transitDays));
        if (opt.etaDate != null && opt.etaDate!.isNotEmpty) {
          final parsed = DateTime.tryParse(opt.etaDate!);
          if (parsed != null) arrivalDate = parsed;
        }

        _quotations.add(
          FreightQuotationItemModel(
            providerId: providerId,
            providerName: providerName,
            vesselName: opt.vesselName,
            voyageNumber: opt.voyageNumber ?? opt.containerType,
            oceanFreightCost: opt.oceanFreight,
            localChargesCost: opt.localCharges ?? 0.0,
            inlandCost: opt.exwCharges ?? 0.0,
            totalCost: opt.totalEstimatedCost,
            sailingDate: sailingDate.toString().substring(0, 10),
            estimatedArrivalDate: arrivalDate.toString().substring(0, 10),
            transitDays: transitDays,
            freeDaysAtPod: opt.freeTimeDays ?? 14,
            remarks: [
              if (opt.notes != null && opt.notes!.isNotEmpty) opt.notes,
              if (opt.containerType.isNotEmpty) 'نوع الحاوية: ${opt.containerType}',
              if (!opt.isDirect) 'خط سير غير مباشر (ترانزيت)',
            ].join(' | '),
          ),
        );
      }
      _extractedOptions = [];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚀 تم نقل وإدراج كافة عروض الأسعار بنجاح إلى جدول المقارنة!'),
        backgroundColor: AppTheme.emerald,
      ),
    );
  }

  void _addSingleExtractedQuotation(ExtractedQuotationOption opt) {
    final partners = ref.read(allPartnersProvider).value ?? ref.read(partnersProvider).valueOrNull ?? [];

    int providerId = 0;
    String providerName = opt.carrierName;

    final matchedPartner = partners.cast<dynamic>().firstWhere(
      (p) {
        final name = (p.partnerName ?? p.name ?? '').toString().toLowerCase();
        final optName = opt.carrierName.toLowerCase();
        return name.contains(optName) || optName.contains(name);
      },
      orElse: () => null,
    );

    if (matchedPartner != null) {
      providerId = matchedPartner.providerId as int? ?? matchedPartner.id as int? ?? 0;
      providerName = matchedPartner.partnerName as String? ?? matchedPartner.name as String? ?? opt.carrierName;
    }

    final transitDays = opt.transitDays ?? 28;
    DateTime sailingDate = DateTime.now().add(const Duration(days: 7));
    if (opt.etdDate != null && opt.etdDate!.isNotEmpty) {
      final parsed = DateTime.tryParse(opt.etdDate!);
      if (parsed != null) sailingDate = parsed;
    }

    DateTime arrivalDate = sailingDate.add(Duration(days: transitDays));
    if (opt.etaDate != null && opt.etaDate!.isNotEmpty) {
      final parsed = DateTime.tryParse(opt.etaDate!);
      if (parsed != null) arrivalDate = parsed;
    }

    setState(() {
      _quotations.add(
        FreightQuotationItemModel(
          providerId: providerId,
          providerName: providerName,
          vesselName: opt.vesselName,
          voyageNumber: opt.voyageNumber ?? opt.containerType,
          oceanFreightCost: opt.oceanFreight,
          localChargesCost: opt.localCharges ?? 0.0,
          inlandCost: opt.exwCharges ?? 0.0,
          totalCost: opt.totalEstimatedCost,
          sailingDate: sailingDate.toString().substring(0, 10),
          estimatedArrivalDate: arrivalDate.toString().substring(0, 10),
          transitDays: transitDays,
          freeDaysAtPod: opt.freeTimeDays ?? 14,
          remarks: [
            if (opt.notes != null && opt.notes!.isNotEmpty) opt.notes,
            if (opt.containerType.isNotEmpty) 'نوع الحاوية: ${opt.containerType}',
            if (!opt.isDirect) 'خط سير غير مباشر (ترانزيت)',
          ].join(' | '),
        ),
      );
      _extractedOptions.removeWhere((o) => o.optionId == opt.optionId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ تمت إضافة عرض [${opt.carrierName} - ${opt.containerType}] إلى جدول المقارنة!'),
        backgroundColor: AppTheme.emerald,
      ),
    );
  }

  /// ─── Smart Inline Freight Quotation Extractor Card (SWIFT MT103 Style) ────
  Widget _buildInlineFreightQuotationsExtractorWidget() {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueGrey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar with Cobalt Gradient & Icons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.cobalt, Colors.blue.shade700],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                    SizedBox(width: 6),
                    Icon(Icons.bolt, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      '(Freight Quotation AI) استخراج وقراءة عروض أسعار الشحن والنولون ⚡ ✨',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(_isFreightExtractorExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.white),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: _isFreightExtractorExpanded ? 'طي الأداة' : 'توسيع الأداة',
                  onPressed: () => setState(() => _isFreightExtractorExpanded = !_isFreightExtractorExpanded),
                ),
              ],
            ),
          ),

          // Collapsible Body
          if (_isFreightExtractorExpanded)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 650;

                      // Text Area with bottom Action Overlay
                      final textArea = Stack(
                        children: [
                          TextField(
                            controller: _rawFreightQuoteController,
                            maxLines: 5,
                            minLines: 4,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.4),
                            decoration: InputDecoration(
                              hintText: 'لصق نص رسالة أو إيميل عرض السعر من الخط الملاحي أو شركة الشحن...\n(مثال: Route: Shanghai - Alexandria | WHL: USD 6700/40HQ | Transit: 29 days, DIRECT | Free time: 21 days FT)',
                              hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 40),
                            ),
                          ),
                          Positioned(
                            left: 8,
                            bottom: 8,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () async {
                                    final d = await Clipboard.getData(Clipboard.kTextPlain);
                                    if (d != null && d.text != null && d.text!.isNotEmpty) {
                                      _rawFreightQuoteController.text = d.text!;
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.paste, size: 12, color: Colors.black87),
                                        SizedBox(width: 4),
                                        Text('لصق نص العرض', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () {
                                    _rawFreightQuoteController.clear();
                                    setState(() {
                                      _extractedOptions = [];
                                      _extractedFreightMetadata = null;
                                      _extractorError = null;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.clear, size: 12, color: Colors.black54),
                                        SizedBox(width: 4),
                                        Text('تفريغ', style: TextStyle(fontSize: 11, color: Colors.black54)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: _loadSampleFreightQuote,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade50,
                                      border: Border.all(color: Colors.amber.shade300),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.lightbulb_outline, size: 12, color: Colors.amber),
                                        SizedBox(width: 4),
                                        Text('نموذج تجريبي', style: TextStyle(fontSize: 11, color: Colors.brown, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );

                      // Action Buttons
                      final actionButtons = Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.shade800,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.upload_file, size: 16, color: Colors.white),
                            label: const Text('رفع مستند عرض السعر 📄', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: _isFreightExtracting ? null : _extractFreightFromFile,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.cobalt,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: _isFreightExtracting
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.bolt, size: 16, color: Colors.amber),
                            label: const Text('استخراج وتحليل عروض السعر ⚡', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: _isFreightExtracting ? null : _extractFreightFromText,
                          ),
                        ],
                      );

                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            textArea,
                            const SizedBox(height: 10),
                            actionButtons,
                          ],
                        );
                      } else {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: textArea),
                            const SizedBox(width: 14),
                            SizedBox(width: 220, child: actionButtons),
                          ],
                        );
                      }
                    },
                  ),

                  // Error Banner
                  if (_extractorError != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_extractorError!, style: TextStyle(color: Colors.red.shade800, fontSize: 11))),
                        ],
                      ),
                    ),
                  ],

                  // Extracted Options Live Results Card
                  if (_extractedOptions.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: AppTheme.emerald, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'تم استخراج ${_extractedOptions.length} عرض/عروض أسعار بنجاح! راجع العروض أدناه ثم أضفها لجدول المقارنة:',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal),
                                ),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.emerald,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                ),
                                icon: const Icon(Icons.add_task, size: 14, color: Colors.white),
                                label: Text(
                                  '🚀 إضافة كافة العروض (${_extractedOptions.length})',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                                onPressed: _addAllExtractedQuotations,
                              ),
                            ],
                          ),
                          if (_pickedFreightFile != null || _extractedFreightMetadata != null) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                if (_pickedFreightFile != null)
                                  Chip(
                                    avatar: const Icon(Icons.attach_file, size: 14, color: AppTheme.cobalt),
                                    label: Text('الملف: ${_pickedFreightFile!.name}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                                    backgroundColor: Colors.white,
                                    padding: EdgeInsets.zero,
                                  ),
                                if (_extractedFreightMetadata?['origin_port'] != null)
                                  Chip(
                                    avatar: const Icon(Icons.flight_takeoff, size: 14, color: Colors.blue),
                                    label: Text('ميناء الشحن: ${_extractedFreightMetadata!['origin_port']}', style: const TextStyle(fontSize: 10.5)),
                                    backgroundColor: Colors.white,
                                    padding: EdgeInsets.zero,
                                  ),
                                if (_extractedFreightMetadata?['destination_port'] != null)
                                  Chip(
                                    avatar: const Icon(Icons.flight_land, size: 14, color: Colors.green),
                                    label: Text('ميناء الوصول: ${_extractedFreightMetadata!['destination_port']}', style: const TextStyle(fontSize: 10.5)),
                                    backgroundColor: Colors.white,
                                    padding: EdgeInsets.zero,
                                  ),
                                if (_extractedFreightMetadata?['local_charges'] != null)
                                  Chip(
                                    avatar: const Icon(Icons.monetization_on, size: 14, color: Colors.orange),
                                    label: Text('المصاريف المحلية: \$${_extractedFreightMetadata!['local_charges']}', style: const TextStyle(fontSize: 10.5)),
                                    backgroundColor: Colors.white,
                                    padding: EdgeInsets.zero,
                                  ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _extractedOptions.map((opt) {
                              return Container(
                                width: 340,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${opt.carrierName} (${opt.containerType})',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.cobalt),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: opt.isDirect ? Colors.green.shade50 : Colors.orange.shade50,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: opt.isDirect ? Colors.green.shade200 : Colors.orange.shade200),
                                          ),
                                          child: Text(
                                            opt.isDirect ? 'مباشر (Direct)' : 'ترانزيت (Transit)',
                                            style: TextStyle(fontSize: 10, color: opt.isDirect ? Colors.green.shade800 : Colors.orange.shade800, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('نولون: \$${opt.oceanFreight.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                        if (opt.localCharges != null && opt.localCharges! > 0)
                                          Text('محلي: \$${opt.localCharges!.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                                        Text('الإجمالي: \$${opt.totalEstimatedCost.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('⏱️ ترانزيت: ${opt.transitDays ?? "-"} يوم', style: const TextStyle(fontSize: 10.5, color: Colors.black87)),
                                        Text('⏳ سماح: ${opt.freeTimeDays ?? 14} يوم FT', style: const TextStyle(fontSize: 10.5, color: Colors.black87)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.cobalt,
                                          side: const BorderSide(color: AppTheme.cobalt),
                                          padding: const EdgeInsets.symmetric(vertical: 6),
                                        ),
                                        icon: const Icon(Icons.add, size: 14),
                                        label: const Text('+ إضافة هذا العرض للجدول', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        onPressed: () => _addSingleExtractedQuotation(opt),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _saveRFQ() async {
    if (!_formKey.currentState!.validate()) return;
    if (_quotations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ يرجى إضافة عرض سعر واحد على الأقل للمقارنة'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final payload = {
        'title': _titleController.text.trim(),
        'shipping_method': _shippingMethod,
        'crd_date': _crdDate.toString().substring(0, 10),
        'pol_name': _polName,
        'pod_name': _podName,
        'import_file_id': _selectedImportFileId,
        'po_id': _selectedPoId,
        'project_id': _selectedProjectId,
        'total_cbm': double.tryParse(_cbmController.text.trim()) ?? 0.0,
        'total_gross_weight_kg': double.tryParse(_weightController.text.trim()) ?? 0.0,
        'chargeable_weight_kg': double.tryParse(_weightController.text.trim()) ?? 0.0,
        'notes': _notesController.text.trim(),
        'quotations': _quotations.map((q) => q.toJson()).toList(),
      };

      final created = await ref.read(freightQuotationsProvider.notifier).createRFQ(payload);
      if (mounted && created != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ تم حفظ طلب مقارنة أسعار الشحن! كود الطلب: ${created.rfqCode}'), backgroundColor: AppTheme.emerald),
        );
        _tabController.animateTo(1);
      }
    } catch (e) {
      if (mounted) {
        await showErrorDetailsDialog(
          context,
          title: '❌ تعذر حفظ طلب مقارنة أسعار الشحن',
          error: e,
          onRetry: () async {
            await _saveRFQ();
          },
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showRFQDetailsDialog(FreightRFQRequestModel rfq) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.directions_boat, color: AppTheme.cobalt),
              const SizedBox(width: 8),
              Expanded(
                child: Text('تفاصيل طلب عرض أسعار الشحن: ${rfq.rfqCode}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              _buildStatusBadge(rfq.status),
            ],
          ),
          content: SizedBox(
            width: 750,
            height: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('العنوان: ${rfq.title}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 6),
                        Text('وسيلة الشحن: ${rfq.shippingMethod} | CRD: ${rfq.crdDate}'),
                        const SizedBox(height: 4),
                        Text('من: ${rfq.polName} ➔ إلى: ${rfq.podName}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildMetricBadge('أقل نولون شحن', '\$${rfq.lowestFreightCost}', Colors.green),
                      const SizedBox(width: 8),
                      _buildMetricBadge('متوسط نولون الشحن', '\$${rfq.averageFreightCost}', Colors.blue),
                      const SizedBox(width: 8),
                      _buildMetricBadge('أسرع ترانزيت', '${rfq.fastestTransitDays} أيام', Colors.orange),
                      const SizedBox(width: 8),
                      _buildMetricBadge('العرض المعتمد', rfq.awardedProviderName ?? 'لم يعتمد بعد', AppTheme.cobalt),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('عروض أسعار الناقلين والمقارنة التفصيلية (Quotations List):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Table(
                    border: TableBorder.all(color: Colors.grey.shade300),
                    columnWidths: const {
                      0: FlexColumnWidth(2.5),
                      1: FlexColumnWidth(1.2),
                      2: FlexColumnWidth(1.2),
                      3: FlexColumnWidth(1.2),
                      4: FlexColumnWidth(1.5),
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: AppTheme.charcoal.withOpacity(0.05)),
                        children: const [
                          Padding(padding: EdgeInsets.all(8.0), child: Text('الخط الملاحي / السفينة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: EdgeInsets.all(8.0), child: Text('إجمالي التكلفة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: EdgeInsets.all(8.0), child: Text('الترانزيت', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: EdgeInsets.all(8.0), child: Text('أيام السماح', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: EdgeInsets.all(8.0), child: Text('الحالة / القرار', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        ],
                      ),
                      ...rfq.quotations.map(
                        (q) => TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(q.providerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  if (q.vesselName != null) Text('السفينة: ${q.vesselName}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                            ),
                            Padding(padding: const EdgeInsets.all(8.0), child: Text('\$${q.totalCost}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                            Padding(padding: const EdgeInsets.all(8.0), child: Text('${q.transitDays} يوم', style: const TextStyle(fontSize: 11))),
                            Padding(padding: const EdgeInsets.all(8.0), child: Text('${q.freeDaysAtPod} يوم', style: const TextStyle(fontSize: 11))),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: q.isAwarded
                                  ? const Chip(label: Text('المعتمد 🎯', style: TextStyle(color: Colors.white, fontSize: 10)), backgroundColor: AppTheme.emerald)
                                  : ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2)),
                                      onPressed: () async {
                                        final nav = Navigator.of(context);
                                        await ref.read(freightQuotationsProvider.notifier).awardQuotation(rfq.rfqId, q.quotationId!);
                                        nav.pop();
                                      },
                                      child: const Text('اعتماد هذا العرض', style: TextStyle(color: Colors.white, fontSize: 10)),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final portsState = ref.watch(transportLocationsProvider);
    final rfqsState = ref.watch(freightQuotationsProvider);

    final portsList = portsState.value ?? [];

    final double lowestCost = _quotations.isNotEmpty ? _quotations.map((q) => q.totalCost).reduce((a, b) => a < b ? a : b) : 0.0;
    final int fastestTransit = _quotations.isNotEmpty ? _quotations.map((q) => q.transitDays).reduce((a, b) => a < b ? a : b) : 0;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppTheme.charcoal,
        title: const Row(
          children: [
            Icon(Icons.directions_boat, color: AppTheme.cobalt),
            SizedBox(width: 10),
            Text('إدارة ومقارنة عروض أسعار الشحن', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.cobalt,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.request_quote), text: 'Freight RFQ Evaluator (طلب ومقارنة العروض)'),
            Tab(icon: Icon(Icons.history), text: 'Saved RFQs History Log (سجل الطلبات المحفوظة)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: FREIGHT RFQ EVALUATOR
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live Metrics Header Bar
                  Row(
                    children: [
                      _buildMetricBadge('أقل سعر شحن متوفر', '\$$lowestCost', Colors.green),
                      const SizedBox(width: 12),
                      _buildMetricBadge('أسرع زمن ترانزيت', '$fastestTransit أيام', Colors.blue),
                      const SizedBox(width: 12),
                      _buildMetricBadge('عدد عروض الناقلين', '${_quotations.length}', Colors.grey),
                      const Spacer(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.emerald,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                        onPressed: _isSaving ? null : _saveRFQ,
                        icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save, color: Colors.white),
                        label: const Text('حفظ وتثبيت طلب مقارنة النولون', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // ── Smart AI Freight Quotations Extractor (Text & OCR Box) ──
                  _buildInlineFreightQuotationsExtractorWidget(),

                  // RFQ Configuration Header Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('بيانات شحنة طلب عرض الأسعار (Freight RFQ Setup)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
                          const Divider(),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: SearchableDropdownField<int?>(
                                  value: _selectedImportFileId,
                                  labelText: 'Import File (ملف الشحنة الاستيرادية)',
                                  searchHintText: 'ابحث عن ملف الشحنة...',
                                  items: [
                                    const SearchableDropdownItem<int?>(
                                      value: null,
                                      label: '-- None / غير مرتبط بملف شحنة --',
                                    ),
                                    ...(ref.watch(importFilesProvider).value ?? []).map((f) => SearchableDropdownItem<int?>(
                                          value: f.importFileId,
                                          label: '[${f.importFileCode}] ${f.customFileNumber ?? f.poNumber ?? "File #${f.importFileId}"}',
                                        )),
                                  ],
                                  onChanged: (v) {
                                    setState(() {
                                      _selectedImportFileId = v;
                                      if (v != null) {
                                        _populateFromImportFile(v);
                                      }
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _titleController,
                                  decoration: const InputDecoration(labelText: 'عنوان طلب عرض الأسعار *', border: OutlineInputBorder()),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال العنوان' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: SearchableDropdownField<String>(
                                  value: _shippingMethod,
                                  labelText: 'وسيلة الشحن (Shipping Method) *',
                                  searchHintText: 'ابحث عن الوسيلة...',
                                  items: const [
                                    SearchableDropdownItem(value: 'Ocean FCL', label: 'Ocean FCL (شحن بحري كامل)'),
                                    SearchableDropdownItem(value: 'Ocean LCL', label: 'Ocean LCL (شحن بحري جزئي)'),
                                    SearchableDropdownItem(value: 'Air Freight', label: 'Air Freight (شحن جوي)'),
                                    SearchableDropdownItem(value: 'Courier Express', label: 'Courier Express (بريد سريع / شحن سريع)'),
                                    SearchableDropdownItem(value: 'Inland Trucking', label: 'Inland Trucking (شحن بري)'),
                                    SearchableDropdownItem(value: 'Multi-Modal', label: 'Multi-Modal (نقل متعدد الوسائط)'),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => _shippingMethod = val);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: InkWell(
                                  onTap: () async {
                                    final d = await showDatePicker(context: context, initialDate: _crdDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                                    if (d != null) setState(() => _crdDate = d);
                                  },
                                  child: InputDecorator(
                                    decoration: const InputDecoration(labelText: 'تاريخ جاهزية البضاعة (CRD) *', border: OutlineInputBorder()),
                                    child: Text(_crdDate.toString().substring(0, 10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: SearchableDropdownField<String>(
                                  value: _polName.isNotEmpty ? _polName : (portsList.isNotEmpty ? portsList.first.locationName : 'Shanghai Port (CN SHA), China'),
                                  labelText: 'ميناء التحميل (POL) *',
                                  searchHintText: 'ابحث عن ميناء التحميل...',
                                  items: [
                                    if (_polName.isNotEmpty && !portsList.any((p) => p.locationName == _polName))
                                      SearchableDropdownItem<String>(value: _polName, label: _polName),
                                    ...portsList.map((p) => SearchableDropdownItem<String>(value: p.locationName, label: p.locationName)),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => _polName = val);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SearchableDropdownField<String>(
                                  value: _podName.isNotEmpty ? _podName : (portsList.length > 1 ? portsList[1].locationName : 'Alexandria Port (EG ALX), Egypt'),
                                  labelText: 'ميناء الوصول (POD) *',
                                  searchHintText: 'ابحث عن ميناء الوصول...',
                                  items: [
                                    if (_podName.isNotEmpty && !portsList.any((p) => p.locationName == _podName))
                                      SearchableDropdownItem<String>(value: _podName, label: _podName),
                                    ...portsList.map((p) => SearchableDropdownItem<String>(value: p.locationName, label: p.locationName)),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => _podName = val);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _cbmController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'إجمالي الحجم (CBM)', border: OutlineInputBorder()),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _weightController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'الوزن القائم (Gross Wt kg)', border: OutlineInputBorder()),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),

                          // Container Recommendation Engine (MD-019.1 Banner)
                          Builder(builder: (context) {
                            final double curCbm = double.tryParse(_cbmController.text.trim()) ?? 0.0;
                            final double curWeight = double.tryParse(_weightController.text.trim()) ?? 0.0;
                            final dualRec = ContainerRequirementEngine.calculateBoth(totalCbm: curCbm, totalWeightKg: curWeight);
                            final containerRec = _isStackable ? dualRec.stackableResult : dualRec.nonStackableResult;

                            return Container(
                              margin: const EdgeInsets.only(top: 14),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.cobalt.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.cobalt.withOpacity(0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.inventory_2, color: AppTheme.cobalt, size: 22),
                                      const SizedBox(width: 10),
                                      const Text(
                                        '🚚 نوع التحميل والتخزين (Cargo Stacking): ',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                                      ),
                                      const SizedBox(width: 8),
                                      ChoiceChip(
                                        label: const Text('📦 قابل للرص (Stackable)'),
                                        selected: _isStackable,
                                        selectedColor: AppTheme.cobalt,
                                        labelStyle: TextStyle(color: _isStackable ? Colors.white : AppTheme.charcoal, fontWeight: FontWeight.bold, fontSize: 11),
                                        onSelected: (val) => setState(() => _isStackable = true),
                                      ),
                                      const SizedBox(width: 8),
                                      ChoiceChip(
                                        label: const Text('🚫 غير قابل للرص (Non-Stackable)'),
                                        selected: !_isStackable,
                                        selectedColor: Colors.orange.shade800,
                                        labelStyle: TextStyle(color: !_isStackable ? Colors.white : AppTheme.charcoal, fontWeight: FontWeight.bold, fontSize: 11),
                                        onSelected: (val) => setState(() => _isStackable = false),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              '🚚 اقتراح أعداد وأنواع الحاويات التلقائي:',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              containerRec.recommendationSummary,
                                              style: TextStyle(fontSize: 12, color: _isStackable ? Colors.blue.shade900 : Colors.orange.shade900, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.cobalt,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        icon: const Icon(Icons.table_chart, size: 14, color: Colors.white),
                                        label: const Text('مقارنة الحالتين (Matrix)', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                                        onPressed: () => _showContainerComparisonDialog(context, dualRec, curCbm, curWeight),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Quotations List Table
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('عروض أسعار الخطوط الملاحية والشركات المنافسة (Quotations List)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
                              const Spacer(),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.cobalt,
                                  side: const BorderSide(color: AppTheme.cobalt),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                ),
                                onPressed: _showFreightExtractorDialog,
                                icon: const Icon(Icons.auto_awesome, size: 18),
                                label: const Text('🤖 استخراج عروض الأسعار (نصوص & OCR)'),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                                onPressed: _addQuotationDialog,
                                icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                                label: const Text('إضافة عرض سعر ناقل', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 10),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _quotations.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final q = _quotations[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(q.providerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          if (q.vesselName != null) Text('السفينة: ${q.vesselName} | الرحلة: ${q.voyageNumber ?? "-"}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: Text('نولون: \$${q.oceanFreightCost} + \$${q.localChargesCost}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: Text('الإجمالي: \$${q.totalCost}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: Text('ترانزيت: ${q.transitDays} يوم (${q.freeDaysAtPod} يوم سماح)', style: const TextStyle(fontSize: 11)),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.grey, size: 20),
                                      onPressed: () => setState(() => _quotations.removeAt(index)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // TAB 2: SAVED RFQ HISTORY LOG
          rfqsState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('❌ Error: $err')),
            data: (rfqs) {
              final filtered = rfqs.where((r) {
                final matchQuery = _searchQuery.isEmpty ||
                    r.rfqCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    r.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    r.polName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    r.podName.toLowerCase().contains(_searchQuery.toLowerCase());
                final matchStatus = _statusFilter == 'All' || r.status == _statusFilter;
                return matchQuery && matchStatus;
              }).toList();

              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Data Actions Toolbar
                    MasterDataToolbarWidget(
                      moduleEndpoint: 'freight-quotations',
                      title: 'Freight_Quotations',
                      onRefreshNeeded: () => ref.read(freightQuotationsProvider.notifier).fetchRFQs(),
                    ),
                    const SizedBox(height: 12),

                    // Search & Filter
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'البحث برقم طلب RFQ أو العنوان أو اسم الميناء...',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) => setState(() => _searchQuery = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 220,
                          child: SearchableDropdownField<String>(
                            value: _statusFilter,
                            labelText: 'تصفية حسب الحالة',
                            searchHintText: 'ابحث عن الحالة...',
                            items: const [
                              SearchableDropdownItem(value: 'All', label: 'جميع الحالات'),
                              SearchableDropdownItem(value: 'Draft', label: 'Draft'),
                              SearchableDropdownItem(value: 'RFQ Issued', label: 'RFQ Issued'),
                              SearchableDropdownItem(value: 'Quotations Received', label: 'Quotations Received'),
                              SearchableDropdownItem(value: 'Awarded', label: 'Awarded'),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _statusFilter = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('لا توجد طلبات عروض أسعار شحن مطابقة للبحث.'))
                          : SingleChildScrollView(
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(AppTheme.charcoal.withOpacity(0.05)),
                                columns: const [
                                  DataColumn(label: Text('كود RFQ', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('ملف الشحنة', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('عنوان الطلب والميناء', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('أقل سعر', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('أسرع ترانزيت', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('العرض المعتمد', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('⚡ العمليات', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: filtered.map((rfq) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(rfq.rfqCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppTheme.charcoal.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            rfq.importFileCode ?? (rfq.importFileId != null ? 'IMP-${rfq.importFileId}' : '-'),
                                            style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.charcoal, fontSize: 12),
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(rfq.title)),
                                      DataCell(Text('\$${rfq.lowestFreightCost}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                                      DataCell(Text('${rfq.fastestTransitDays} يوم')),
                                      DataCell(Text(rfq.awardedProviderName ?? 'لم يعتمد')),
                                      DataCell(_buildStatusBadge(rfq.status)),
                                      DataCell(
                                        RowActionsPill(
                                          onView: () => _showRFQDetailsDialog(rfq),
                                          onEdit: () => _showRFQDetailsDialog(rfq),
                                          onPrint: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('طباعة مقارنة وعروض أسعار الشحن: ${rfq.rfqCode} (${rfq.title})'),
                                                backgroundColor: AppTheme.charcoal,
                                                duration: const Duration(seconds: 2),
                                              ),
                                            );
                                          },
                                          onDelete: () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text('تأكيد الإجراء'),
                                                content: Text('هل أنت متأكد من حذف أو إلغاء طلب عرض السعر (${rfq.rfqCode})؟'),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                                                  ElevatedButton(
                                                    onPressed: () => Navigator.pop(ctx, true),
                                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson),
                                                    child: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white)),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true && context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('تم حذف طلب عرض الأسعار بنجاح')),
                                              );
                                            }
                                          },
                                          deleteTooltip: 'حذف طلب عرض السعر',
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBadge(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = Colors.grey;
    if (status == 'Awarded') bg = Colors.green;
    if (status == 'Quotations Received') bg = Colors.blue;
    if (status == 'RFQ Issued') bg = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(color: bg, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  void _showContainerComparisonDialog(BuildContext context, ContainerDualRecommendationResult dualRec, double totalCbm, double totalWeightKg) {
    showDialog(
      context: context,
      builder: (context) {
        return DefaultTabController(
          length: 2,
          child: AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.inventory_2, color: AppTheme.cobalt),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('تحليل خيارات الحاويات وسيناريوهات التحميل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('إجمالي الشحنة: ${totalCbm.toStringAsFixed(2)} m³ | ${totalWeightKg.toStringAsFixed(0)} kg', style: const TextStyle(fontSize: 12, color: AppTheme.cobalt, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 750,
              height: 480,
              child: Column(
                children: [
                  Container(
                    color: AppTheme.charcoal,
                    child: const TabBar(
                      indicatorColor: AppTheme.cobalt,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      tabs: [
                        Tab(icon: Icon(Icons.layers), text: '📦 قابل للرص (Stackable)'),
                        Tab(icon: Icon(Icons.view_array), text: '🚫 غير قابل للرص - طبقة واحدة (Non-Stackable)'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildComparisonTable(dualRec.stackableResult),
                        _buildComparisonTable(dualRec.nonStackableResult),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
            ],
          ),
        );
      },
    );
  }

  Widget _buildComparisonTable(ContainerRecommendationResult rec) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: rec.isStackable ? AppTheme.emerald.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: rec.isStackable ? AppTheme.emerald : Colors.orange.shade800),
            ),
            child: Text('التوصية المعتمدة: ${rec.recommendationSummary}', style: TextStyle(fontWeight: FontWeight.bold, color: rec.isStackable ? AppTheme.emerald : Colors.orange.shade900)),
          ),
          const SizedBox(height: 12),
          Table(
            border: TableBorder.all(color: Colors.grey.shade300),
            columnWidths: const {
              0: FlexColumnWidth(2.0),
              1: FlexColumnWidth(1.2),
              2: FlexColumnWidth(1.5),
              3: FlexColumnWidth(1.5),
              4: FlexColumnWidth(1.5),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: AppTheme.charcoal.withOpacity(0.08)),
                children: const [
                  Padding(padding: EdgeInsets.all(8.0), child: Text('نوع الحاوية (Spec)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8.0), child: Text('العدد المطلوبة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8.0), child: Text('استغلال المساحة %', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8.0), child: Text('استغلال الوزن %', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8.0), child: Text('التوصية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                ],
              ),
              ...rec.comparisonDetails.map((detail) {
                final spec = detail['spec'] as ContainerSpec;
                final int count = detail['reqCount'] as int;
                final double volUtil = detail['spaceUtil'] as double;
                final double weightUtil = detail['payloadUtil'] as double;
                final isBest = spec.code == rec.recommendedContainerCode;

                return TableRow(
                  decoration: isBest ? BoxDecoration(color: AppTheme.emerald.withOpacity(0.12)) : null,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(spec.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isBest ? AppTheme.emerald : AppTheme.charcoal)),
                          Text('السعة: ${spec.internalVolumeCbm} CBM | الحمولة: ${spec.maxPayloadKg} kg', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('$count x ${spec.code}', style: TextStyle(fontWeight: FontWeight.bold, color: isBest ? AppTheme.emerald : AppTheme.charcoal)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('${volUtil.toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.bold, color: volUtil > 90 ? Colors.green : Colors.orange)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('${weightUtil.toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.bold, color: weightUtil > 90 ? Colors.green : Colors.orange)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: isBest
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: AppTheme.emerald, borderRadius: BorderRadius.circular(4)),
                              child: const Text('🌟 الخيار الأنسب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                            )
                          : const Text('بديل قابل للتطبيق', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

