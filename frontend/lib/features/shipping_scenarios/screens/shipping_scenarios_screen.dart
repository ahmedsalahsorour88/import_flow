import '../widgets/saved_scenarios_registry_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/change_diff_dialog.dart';
import '../../../core/utils/container_requirement_engine.dart';
import '../../../core/widgets/container_load_plan_painter.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/smart_upload_button.dart';
import '../../../core/widgets/error_details_dialog.dart';
import '../../../core/widgets/vertical_stage_scaffold.dart';
import '../../../core/widgets/extraction_progress_dialog.dart';

import '../../external_service_providers/models/partner_model.dart';
import '../../external_service_providers/providers/partners_provider.dart';
import '../../freight_quotations/widgets/freight_quotations_extractor_dialog.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../../projects/providers/projects_provider.dart';
import '../../purchase_orders/models/purchase_order_model.dart';
import '../../purchase_orders/providers/purchase_orders_provider.dart';
import '../../transport_locations/providers/transport_locations_provider.dart';
import '../models/shipping_scenario_model.dart';
import '../providers/shipping_scenarios_provider.dart';
import '../../currencies/models/currency_model.dart';
import '../../currencies/providers/currencies_provider.dart';
import '../../../core/localization/app_localizations.dart';


class ShippingScenariosScreen extends ConsumerStatefulWidget {

  final int initialIndex;
  const ShippingScenariosScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<ShippingScenariosScreen> createState() => _ShippingScenariosScreenState();
}

class _ShippingScenariosScreenState extends ConsumerState<ShippingScenariosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Evaluator Form State
  int? _editingSessionId;
  String? _editingSessionCode;
  int _editFormVersion = 0;
  String _title = '';
  DateTime _cargoReadyDate = DateTime.now().add(const Duration(days: 5));
  String _pickUpAddress = '';
  int _avgForm4Days = 5;
  int _avgClearanceDays = 7;
  int? _selectedImportFileId;
  int? _selectedPoId;
  int? _selectedProjectId;
  final String _sessionNotes = '';

  // Carrier Options List
  final List<ShippingScenarioItemModel> _evalItems = [];
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

  // Track expanded quotes in UI
  final Map<int, bool> _expandedQuotes = {};

  void _loadSessionForEditing(ShippingEvaluationModel sess) {
    setState(() {
      _editFormVersion++;
      _editingSessionId = sess.sessionId;
      _editingSessionCode = sess.sessionCode;
      _title = sess.title ?? '';
      _cargoReadyDate = DateTime.tryParse(sess.cargoReadyDate) ?? DateTime.now();
      _pickUpAddress = sess.pickUpAddress ?? '';
      _avgForm4Days = sess.avgForm4Days;
      _avgClearanceDays = sess.avgClearanceDays;
      _selectedImportFileId = sess.importFileId;
      _selectedPoId = sess.poId;
      _selectedProjectId = sess.projectId;
      _evalItems.clear();
      _evalItems.addAll(sess.items);
      _expandedQuotes.clear();
      for (int i = 0; i < sess.items.length; i++) {
        _expandedQuotes[i] = true;
      }
    });
    _tabController.animateTo(0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📂 تم استدعاء وتحميل كافة بيانات الجلسة (${sess.sessionCode}) للتعديل وإعادة التفعيل!'),
        backgroundColor: AppTheme.cobalt,
      ),
    );
  }

  void _resetFormForNewStudy() {
    setState(() {
      _editFormVersion++;
      _editingSessionId = null;
      _editingSessionCode = null;
      _title = '';
      _cargoReadyDate = DateTime.now().add(const Duration(days: 5));
      _pickUpAddress = '';
      _avgForm4Days = 5;
      _avgClearanceDays = 7;
      _selectedImportFileId = null;
      _selectedPoId = null;
      _selectedProjectId = null;
      _expandedQuotes.clear();
      _initDefaultItems();
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialIndex);
    _initDefaultItems();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData(force: false);
    });
  }

  @override
  void didUpdateWidget(ShippingScenariosScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _tabController.animateTo(widget.initialIndex);
    }
  }

  void _refreshData({bool force = false}) {
    ref.read(shippingScenariosProvider.notifier).fetchSessions();
    if (force || ref.read(projectsProvider).value == null) {
      ref.read(projectsProvider.notifier).fetchProjects();
    }
    if (force || ref.read(purchaseOrdersProvider).purchaseOrders.isEmpty) {
      ref.read(purchaseOrdersProvider.notifier).fetchPurchaseOrders();
    }
    if (force || ref.read(allPartnersProvider).value == null) {
      ref.read(allPartnersProvider.notifier).fetchPartners();
    }
    if (force || ref.read(partnersProvider).value == null) {
      ref.read(partnersProvider.notifier).fetchPartners();
    }
    if (force || ref.read(transportLocationsProvider).value == null) {
      ref.read(transportLocationsProvider.notifier).fetchLocations();
    }
    if (force || ref.read(importFilesProvider).value == null) {
      ref.read(importFilesProvider.notifier).fetchImportFiles();
    }
    if (force || ref.read(currenciesProvider).value == null) {
      ref.read(currenciesProvider.notifier).fetchCurrencies();
    }
  }

  void _initDefaultItems() {
    final crd = _cargoReadyDate;
    _evalItems.clear();
    _evalItems.addAll([
      ShippingScenarioItemModel(
        providerName: 'COSCO Shipping',
        vesselName: 'COSCO UNIVERSE',
        voyageNumber: '042E',
        polName: 'Shanghai Port (ميناء شانغهاي)',
        podName: 'El Dekheila Port (ميناء الدخيلة)',
        sailingDate: crd.add(const Duration(days: 2)).toString().substring(0, 10),
        estimatedArrivalDate: crd.add(const Duration(days: 26)).toString().substring(0, 10),
        expectedLineDelayDays: 2,
        isRecommended: true,
        riskLevel: 'Low',
        notes: 'أقرب موعد إبحار وتوافر حاويات HQ في ميناء شانغهاي',
      ),
      ShippingScenarioItemModel(
        providerName: 'Maersk Line',
        vesselName: 'MAERSK MC-KINNEY MOLLER',
        voyageNumber: '2608W',
        polName: 'Ningbo-Zhoushan Port (ميناء نينغبو)',
        podName: 'Damietta Port (ميناء دمياط)',
        sailingDate: crd.add(const Duration(days: 5)).toString().substring(0, 10),
        estimatedArrivalDate: crd.add(const Duration(days: 32)).toString().substring(0, 10),
        expectedLineDelayDays: 4,
        isRecommended: false,
        riskLevel: 'Medium',
        notes: r'ترانزيت في بيرايوس مع تكلفة شحن أقل بمقدار $300',
      ),
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _rawFreightQuoteController.dispose();
    super.dispose();
  }

  double _calculateTotalQuoteValue(ShippingScenarioItemModel item, List<CurrencyModel> currencies) {
    double total = 0.0;
    final targetCurrency = item.quotationCurrency;
    
    double targetRate = 1.0;
    final mainCurr = currencies.where((c) => c.currencyCode == targetCurrency).firstOrNull;
    if (mainCurr != null) {
      targetRate = mainCurr.latestCommercialRate ?? 1.0;
    }

    double convert(double amount, String sourceCurrency) {
      if (sourceCurrency == targetCurrency) return amount;
      double sourceRate = 1.0;
      final srcCurr = currencies.where((c) => c.currencyCode == sourceCurrency).firstOrNull;
      if (srcCurr != null) {
        sourceRate = srcCurr.latestCommercialRate ?? 1.0;
      }
      return amount * (sourceRate / targetRate);
    }

    if (item.container40ftApplicable) {
      total += convert(item.container40ftPrice * item.container40ftQty, item.container40ftCurrency);
    }
    if (item.container20ftApplicable) {
      total += convert(item.container20ftPrice * item.container20ftQty, item.container20ftCurrency);
    }
    if (item.lclCbmApplicable) {
      total += convert(item.lclCbmPrice * item.lclCbmQty, item.lclCbmCurrency);
    }
    if (item.expressCourierApplicable) {
      total += convert(item.expressCourierPrice, item.expressCourierCurrency);
    }
    if (item.eurAtrApplicable) {
      total += convert(item.eurAtrPrice, item.eurAtrCurrency);
    }
    if (item.solasVgmApplicable) {
      total += convert(item.solasVgmPrice, item.solasVgmCurrency);
    }
    if (item.vgmNotificationApplicable) {
      // Sum container counts only if container type is applicable to fix calculation bugs
      final totalQty = (item.container40ftApplicable ? item.container40ftQty : 0) + 
                       (item.container20ftApplicable ? item.container20ftQty : 0);
      total += convert(item.vgmNotificationPrice * totalQty, item.vgmNotificationCurrency);
    }
    if (item.telexReleaseApplicable) {
      total += convert(item.telexReleasePrice, item.telexReleaseCurrency);
    }
    if (item.insuranceApplicable) {
      total += convert(item.insurancePrice, item.insuranceCurrency);
    }
    if (item.bookingCancellationApplicable) {
      total += convert(item.bookingCancellationPrice, item.bookingCancellationCurrency);
    }

    // 4 Previous fee columns
    if (item.ics2FilingFeeApplicable) {
      total += convert(item.ics2FilingFeePrice, item.ics2FilingFeeCurrency);
    }
    if (item.othersFeeApplicable) {
      total += convert(item.othersFeePrice, item.othersFeeCurrency);
    }
    if (item.documentFeesApplicable) {
      total += convert(item.documentFeesPrice, item.documentFeesCurrency);
    }
    if (item.waiverLetterFeeApplicable) {
      total += convert(item.waiverLetterFeePrice, item.waiverLetterFeeCurrency);
    }

    // 3 New quotation fee items: DTHC, Storage per week, Extra day storage
    if (item.dthcApplicable) {
      total += convert(item.dthcPrice, item.dthcCurrency);
    }
    if (item.storagePerWeekApplicable) {
      total += convert(item.storagePerWeekPrice, item.storagePerWeekCurrency);
    }
    if (item.extraDayStorageApplicable) {
      total += convert(item.extraDayStoragePrice, item.extraDayStorageCurrency);
    }

    return total;
  }

  void _updateItem(int idx, ShippingScenarioItemModel updatedItem, List<CurrencyModel> currencies) {
    final rawTotal = _calculateTotalQuoteValue(updatedItem, currencies);
    final totalAmount = rawTotal.roundToDouble(); // Round to integer values to prevent decimals
    setState(() {
      _evalItems[idx] = updatedItem.copyWith(totalQuotationAmount: totalAmount);
    });
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

    setState(() {
      _extractedFreightMetadata = extracted;
      _extractedOptions = parsedList;
      if (parsedList.isEmpty) {
        _extractorError = 'لم يتم العثور على أية عروض أسعار صالحة في النص/المستند المدخل.';
      }
    });

    if (parsedList.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✨ تم بنجاح استخراج ${parsedList.length} عرض/عروض أسعار! يمكنك مراجعتها وإضافتها فوراً للدراسة.'),
          backgroundColor: AppTheme.emerald,
        ),
      );
    }
  }

  ShippingScenarioItemModel _mapExtractedOptionToScenarioItem({
    required ExtractedQuotationOption opt,
    required DateTime crd,
    required List<PartnerModel> partners,
    required List portsList,
    required bool isRecommended,
  }) {
    final rawCarrier = opt.carrierName;
    final cntrType = opt.containerType;
    final rate = opt.oceanFreight;
    final localCharges = opt.localCharges;
    final cancelFee = opt.exwCharges;
    final freeDays = opt.freeTimeDays ?? 21;
    final transitDays = opt.transitDays ?? 28;
    final isDirect = opt.isDirect;
    final notes = opt.notes;
    final curr = opt.currency;

    // 1. Match Shipping Line (الخط الملاحي)
    final shippingLines = partners.where((p) => p.partnerType.contains('Shipping Line')).toList();
    final matchedLine = shippingLines.where((p) =>
      p.partnerName.toLowerCase().contains(rawCarrier.toLowerCase()) ||
      rawCarrier.toLowerCase().contains(p.partnerName.toLowerCase()) ||
      (p.scacCode != null && rawCarrier.toLowerCase().contains(p.scacCode!.toLowerCase()))
    ).firstOrNull;
    final effectiveCarrierName = matchedLine != null ? matchedLine.partnerName : rawCarrier;

    // 2. Match Freight Forwarder (وكيل الشحن / الناقل)
    final freightForwarders = partners.where((p) => p.partnerType.contains('Freight Forwarder') || p.partnerType.contains('Carrier')).toList();
    final rawForwarder = opt.forwarderName ?? _extractedFreightMetadata?['forwarder_name']?.toString() ?? '';
    final matchedForwarder = rawForwarder.isNotEmpty
        ? freightForwarders.where((p) =>
            p.partnerName.toLowerCase().contains(rawForwarder.toLowerCase()) ||
            rawForwarder.toLowerCase().contains(p.partnerName.toLowerCase())).firstOrNull
        : null;

    // 3. Match Port of Loading POL (ميناء السفر / التحميل)
    final rawPol = (opt.originPort ?? _extractedFreightMetadata?['origin_port']?.toString() ?? '').toLowerCase();
    final dynamic matchedPol = rawPol.isNotEmpty
        ? portsList.where((p) {
            final pName = (p.locationName as String).toLowerCase();
            final unloc = (p.unLocode as String).toLowerCase();
            return rawPol.contains(pName) || pName.contains(rawPol) || (unloc.isNotEmpty && rawPol.contains(unloc));
          }).firstOrNull
        : null;

    // 4. Match Port of Discharge POD (ميناء الوصول / التفريغ)
    final rawPod = (opt.destinationPort ?? _extractedFreightMetadata?['destination_port']?.toString() ?? '').toLowerCase();
    final dynamic matchedPod = rawPod.isNotEmpty
        ? portsList.where((p) {
            final pName = (p.locationName as String).toLowerCase();
            final unloc = (p.unLocode as String).toLowerCase();
            return rawPod.contains(pName) || pName.contains(rawPod) || (unloc.isNotEmpty && rawPod.contains(unloc));
          }).firstOrNull
        : null;

    // 5. Vessel & Voyage (اسم الباخرة ورقم الرحلة)
    final effectiveVessel = (opt.vesselName != null && opt.vesselName!.isNotEmpty)
        ? opt.vesselName!
        : (_extractedFreightMetadata?['vessel_name']?.toString() ?? (isDirect ? 'Direct Line Service' : 'Transshipment Service'));
    final effectiveVoyage = (opt.voyageNumber != null && opt.voyageNumber!.isNotEmpty)
        ? opt.voyageNumber!
        : (_extractedFreightMetadata?['voyage_number']?.toString() ?? '');

    // 6. Sailing Date ETD & Estimated Arrival ETA (تاريخ الإبحار وتاريخ الوصول)
    DateTime sDate = crd.add(const Duration(days: 2));
    if (opt.etdDate != null && opt.etdDate!.isNotEmpty) {
      final parsed = DateTime.tryParse(opt.etdDate!);
      if (parsed != null) sDate = parsed;
    }

    DateTime arrDate = sDate.add(Duration(days: transitDays));
    if (opt.etaDate != null && opt.etaDate!.isNotEmpty) {
      final parsed = DateTime.tryParse(opt.etaDate!);
      if (parsed != null) arrDate = parsed;
    }

    final is40 = cntrType.contains('40');
    final is20 = cntrType.contains('20');

    return ShippingScenarioItemModel(
      providerId: matchedForwarder?.providerId,
      providerName: effectiveCarrierName,
      vesselName: effectiveVessel,
      voyageNumber: effectiveVoyage,
      portOfLoadingId: matchedPol?.locationId,
      polName: matchedPol != null ? matchedPol.locationName : (opt.originPort ?? 'Shanghai Port'),
      portOfDischargeId: matchedPod?.locationId,
      podName: matchedPod != null ? matchedPod.locationName : (opt.destinationPort ?? 'El Dekheila Port'),
      sailingDate: sDate.toString().substring(0, 10),
      estimatedArrivalDate: arrDate.toString().substring(0, 10),
      expectedLineDelayDays: isDirect ? 2 : 5,
      isRecommended: isRecommended,
      riskLevel: isDirect ? 'Low' : 'Medium',
      quotationCurrency: curr,
      freeTimeDays: freeDays,
      container40ftApplicable: is40,
      container40ftPrice: is40 ? rate : 0.0,
      container40ftQty: is40 ? 1 : 0,
      container40ftCurrency: curr,
      container20ftApplicable: is20,
      container20ftPrice: is20 ? rate : 0.0,
      container20ftQty: is20 ? 1 : 0,
      container20ftCurrency: curr,
      bookingCancellationApplicable: cancelFee != null && cancelFee > 0,
      bookingCancellationPrice: cancelFee ?? 0.0,
      bookingCancellationCurrency: curr,
      othersFeeApplicable: localCharges != null && localCharges > 0,
      othersFeePrice: localCharges ?? 0.0,
      othersFeeCurrency: curr,
      notes: [
        if (!isDirect) 'رحلة غير مباشرة (Transshipment)',
        if (notes != null && notes.isNotEmpty) notes,
        if (localCharges != null && localCharges > 0) 'مصاريف محلية / EXW: \$$localCharges',
      ].join(' — '),
    );
  }

  void _addAllExtractedQuotationsToScenarios() {
    if (_extractedOptions.isEmpty) return;
    final crd = _cargoReadyDate;
    final partners = ref.read(allPartnersProvider).value ?? ref.read(partnersProvider).value ?? [];
    final portsList = ref.read(transportLocationsProvider).value ?? [];
    final List<ShippingScenarioItemModel> newItems = [];

    for (int i = 0; i < _extractedOptions.length; i++) {
      final opt = _extractedOptions[i];
      newItems.add(_mapExtractedOptionToScenarioItem(
        opt: opt,
        crd: crd,
        partners: partners,
        portsList: portsList,
        isRecommended: _evalItems.isEmpty && i == 0,
      ));
    }

    setState(() {
      _editFormVersion++;
      _evalItems.addAll(newItems);
      _extractedOptions = [];
      for (int i = 0; i < _evalItems.length; i++) {
        _expandedQuotes[i] = true;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🚀 تم نقل وإدراج ${newItems.length} عروض أسعار بنجاح إلى دراسة ومفاضلة النولون!'),
        backgroundColor: AppTheme.emerald,
      ),
    );
  }

  void _addSingleExtractedQuotationToScenarios(ExtractedQuotationOption opt) {
    final crd = _cargoReadyDate;
    final partners = ref.read(allPartnersProvider).value ?? ref.read(partnersProvider).value ?? [];
    final portsList = ref.read(transportLocationsProvider).value ?? [];

    final newItem = _mapExtractedOptionToScenarioItem(
      opt: opt,
      crd: crd,
      partners: partners,
      portsList: portsList,
      isRecommended: _evalItems.isEmpty,
    );

    setState(() {
      _editFormVersion++;
      _evalItems.add(newItem);
      _expandedQuotes[_evalItems.length - 1] = true;
      _extractedOptions.removeWhere((o) => o.optionId == opt.optionId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ تمت إضافة عرض [${opt.carrierName} - ${opt.containerType}] إلى دراسة المفاضلة!'),
        backgroundColor: AppTheme.emerald,
      ),
    );
  }

  /// ─── Smart Inline Freight Quotation Extractor Card (SWIFT MT103 Style) ────
  Widget _buildInlineFreightQuotationsExtractorWidget() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                                  'تم استخراج ${_extractedOptions.length} عرض/عروض أسعار بنجاح! راجع العروض أدناه ثم أضفها لدراسة المفاضلة:',
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
                                onPressed: _addAllExtractedQuotationsToScenarios,
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
                                        label: const Text('+ إضافة هذا العرض للسيناريو', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        onPressed: () => _addSingleExtractedQuotationToScenarios(opt),
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

  void _applySmartExtractedFreightQuotes(Map<String, dynamic> fields) {
    final crd = _cargoReadyDate;
    final List<dynamic> options = (fields['rate_options'] is List && (fields['rate_options'] as List).isNotEmpty)
        ? fields['rate_options'] as List
        : [fields];

    final List<ShippingScenarioItemModel> newItems = [];
    final partners = ref.read(allPartnersProvider).value ?? ref.read(partnersProvider).value ?? [];
    final portsList = ref.read(transportLocationsProvider).value ?? [];

    for (int i = 0; i < options.length; i++) {
      final optMap = Map<String, dynamic>.from(options[i] as Map);
      final opt = ExtractedQuotationOption.fromMap(optMap, i + 1);
      newItems.add(_mapExtractedOptionToScenarioItem(
        opt: opt,
        crd: crd,
        partners: partners,
        portsList: portsList,
        isRecommended: i == 0,
      ));
    }

    setState(() {
      _editFormVersion++;
      _evalItems.clear();
      _evalItems.addAll(newItems);
      _expandedQuotes.clear();
      for (int i = 0; i < newItems.length; i++) {
        _expandedQuotes[i] = true;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🚀 تم استخراج وإضافة ${newItems.length} عروض أسعار للمفاضلة في السيناريو بنجاح!'),
        backgroundColor: AppTheme.emerald,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = ref.watch(shippingScenariosProvider);
    final projectsState = ref.watch(projectsProvider);
    final poState = ref.watch(purchaseOrdersProvider);
    final partnersState = ref.watch(allPartnersProvider);
    final portsState = ref.watch(transportLocationsProvider);
    final currenciesAsync = ref.watch(currenciesProvider);

    final poList = poState.purchaseOrders;
    final projectsList = projectsState.value ?? [];
    final List<PartnerModel> partnersList = partnersState.value ?? [];
    final List<CurrencyModel> currenciesList = currenciesAsync.value ?? [];

    final List<PartnerModel> freightForwarders = partnersList.where((p) => p.partnerType.contains('Freight Forwarder')).toList();
    final List<PartnerModel> shippingLines = partnersList.where((p) => p.partnerType.contains('Shipping Line')).toList();
    final List<PartnerModel> customsBrokers = partnersList.where((p) => p.partnerType.contains('Customs Broker')).toList();
    final portsList = portsState.value ?? [];

    final tabs = [
      const VerticalNavTabItem(
        icon: Icons.analytics_outlined,
        titleEn: 'Scenarios Evaluator',
        titleAr: 'دراسة وسيناريوهات الشحن',
      ),

      VerticalNavTabItem(
        icon: Icons.history_edu_outlined,
        titleEn: 'Saved Evaluations Log',
        titleAr: 'سجل الدراسات المحفوظة',
        badge: state.sessions.isNotEmpty
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.cobalt.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${state.sessions.length}',
                  style: const TextStyle(color: AppTheme.cobalt, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              )
            : null,
      ),
    ];

    return VerticalStageScaffold(
      stageCode: '',
      titleEn: 'Freight Shipping Scenarios & Carrier Evaluation',
      titleAr: 'دراسات وسيناريوهات الشحن والمفاضلة',
      headerIcon: Icons.alt_route_outlined,
      headerColor: AppTheme.cobalt,
      tabs: tabs,
      selectedIndex: _tabController.index,
      onTabSelected: (index) => setState(() => _tabController.index = index),
      headerActions: [
        SmartUploadButton(
          module: SmartUploadModule.freightQuotation,
          label: '🚀 ${l.extractFreightQuotes}',
          onDataExtracted: (result) {
            _applySmartExtractedFreightQuotes(result.extractedFields);
          },
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70),
          tooltip: l.liveRefresh,
          onPressed: () => _refreshData(force: true),
        ),
      ],
      body: IndexedStack(
        index: _tabController.index,
        children: [
          _buildEvaluatorTab(state, poList, projectsList, freightForwarders, shippingLines, customsBrokers, portsList, currenciesList),
          _buildHistoryRegistryTab(state, poList, projectsList),
        ],
      ),
    );
  }


  Widget _buildEvaluatorTab(
    ShippingScenariosState state,
    List<PurchaseOrderModel> poList,
    List projectsList,
    List<PartnerModel> freightForwarders,
    List<PartnerModel> shippingLines,
    List<PartnerModel> customsBrokers,
    List portsList,
    List<CurrencyModel> currenciesList,
  ) {
    final crd = _cargoReadyDate;
    final l = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // Calculate Scenario lead times

    final calculatedScenarios = _evalItems.asMap().entries.map((entry) {
      final idx = entry.key;
      final item = entry.value;

      final sDate = DateTime.tryParse(item.sailingDate) ?? crd;
      final etaDate = DateTime.tryParse(item.estimatedArrivalDate) ?? sDate.add(const Duration(days: 20));

      final vesselLeadTime = etaDate.difference(sDate).inDays;
      final readyDays = sDate.difference(crd).inDays;
      final totalDays = vesselLeadTime + readyDays + _avgForm4Days + _avgClearanceDays + item.expectedLineDelayDays;

      final expectedWhDate = crd.add(Duration(days: totalDays)).toString().substring(0, 10);

      return {
        'index': idx,
        'item': item,
        'vesselLeadTime': vesselLeadTime,
        'readyDays': readyDays,
        'totalDays': totalDays,
        'expectedWhDate': expectedWhDate,
      };
    }).toList();

    final validScenarios = calculatedScenarios.where((c) => !(c['item'] as ShippingScenarioItemModel).isExcludedFromAverage).toList();
    final avgTotalDays = validScenarios.isNotEmpty
        ? (validScenarios.fold<int>(0, (sum, c) => sum + (c['totalDays'] as int)) / validScenarios.length).round()
        : 0;
    final avgArrivalDate = validScenarios.isNotEmpty
        ? crd.add(Duration(days: avgTotalDays)).toString().substring(0, 10)
        : 'N/A';

    final recItemMap = calculatedScenarios.where((c) => (c['item'] as ShippingScenarioItemModel).isRecommended).firstOrNull;
    final recItem = recItemMap != null ? (recItemMap['item'] as ShippingScenarioItemModel) : null;

    final earliestItemMap = validScenarios.isNotEmpty
        ? validScenarios.reduce((a, b) => (a['totalDays'] as int) < (b['totalDays'] as int) ? a : b)
        : null;
    final latestItemMap = validScenarios.isNotEmpty
        ? validScenarios.reduce((a, b) => (a['totalDays'] as int) > (b['totalDays'] as int) ? a : b)
        : null;

    // Linked PO packing list metrics
    double totalCargoCbm = 0.0;
    double totalCargoWeightKg = 0.0;
    int linkedPlCount = 0;
    bool hasNonStackableItems = false;
    bool hasExplicitPackingList = false;

    List<PurchaseOrderModel> filteredPOs = [];
    if (_selectedImportFileId != null) {
      final importFiles = ref.watch(importFilesProvider).value ?? [];
      final selectedFile = importFiles.where((f) => f.importFileId == _selectedImportFileId).firstOrNull;
      if (selectedFile != null) {
        final filePoIds = selectedFile.poIds ?? [];
        filteredPOs = poList.where((p) =>
            (p.poId != null && filePoIds.contains(p.poId)) ||
            (p.importFileId != null && p.importFileId == selectedFile.importFileId) ||
            (selectedFile.importFileCode.isNotEmpty && p.importFileCode != null && p.importFileCode == selectedFile.importFileCode)).toList();
      }
    } else if (_selectedPoId != null) {
      filteredPOs = poList.where((p) => p.poId == _selectedPoId).toList();
    }

    for (var po in filteredPOs) {
      if (po.packingListItems.isNotEmpty) {
        hasExplicitPackingList = true;
        linkedPlCount += po.packingListItems.length;
        for (var pl in po.packingListItems) {
          totalCargoCbm += (pl.totalCbm > 0 ? pl.totalCbm : pl.calculatedCbm);
          totalCargoWeightKg += (pl.totalGrossWeightKg > 0 ? pl.totalGrossWeightKg : (pl.grossWeightUnitKg * pl.qtyPkg));
          if (!pl.isStackable) hasNonStackableItems = true;
        }
      }
    }

    final containerRec = ContainerRequirementEngine.calculate(
      totalCbm: totalCargoCbm,
      totalWeightKg: totalCargoWeightKg,
      isStackable: _isStackable,
    );

    final dualRec = ContainerRequirementEngine.calculateBoth(
      totalCbm: totalCargoCbm,
      totalWeightKg: totalCargoWeightKg,
    );

    return Form(
      key: _formKey,
      child: Stack(
        children: [
          Positioned.fill(
            child: KeyedSubtree(
              key: ValueKey('evaluator_form_${_editingSessionId ?? "new"}_$_editFormVersion'),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 85),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_editingSessionId != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade400),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.edit_note, color: Colors.orange, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '⚠️ ${l.activeEditStudyBanner}: $_editingSessionCode (${_title.isNotEmpty ? _title : l.noDataFound}). ${l.activeEditStudyHint}',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900, fontSize: 13),
                            ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(foregroundColor: AppTheme.crimson),
                            icon: const Icon(Icons.cancel_outlined, size: 18),
                            label: Text(l.cancelEditAndStartNew, style: const TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              _resetFormForNewStudy();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('🔄 تم إلغاء وضع التعديل وتصفير الحقول لبدء دراسة جديدة.'),
                                  backgroundColor: AppTheme.charcoal,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Top Metrics Cards Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          l.avgWarehouseArrivalMetric,
                          avgArrivalDate,
                          Icons.date_range,
                          AppTheme.emerald,
                          subtitle: isArabic ? 'خلال $avgTotalDays يوم من الجاهزية' : 'Within $avgTotalDays days of readiness',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          l.earliestLineMetric,
                          earliestItemMap != null ? (earliestItemMap["item"] as ShippingScenarioItemModel).providerName : 'N/A',
                          Icons.speed,
                          AppTheme.cobalt,
                          subtitle: earliestItemMap != null ? '${l.estimatedArrivalDateCol}: ${earliestItemMap["expectedWhDate"]}' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          l.latestLineMetric,
                          latestItemMap != null ? (latestItemMap["item"] as ShippingScenarioItemModel).providerName : 'N/A',
                          Icons.warning_amber_rounded,
                          Colors.amber.shade900,
                          subtitle: latestItemMap != null ? '${l.estimatedArrivalDateCol}: ${latestItemMap["expectedWhDate"]}' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          l.recommendedLineMetric,
                          recItem != null ? '${recItem.providerName} (${recItem.vesselName})' : l.unassigned,
                          Icons.stars_rounded,
                          Colors.purple,
                          subtitle: recItemMap != null ? '${l.avgWarehouseArrivalMetric}: ${recItemMap["expectedWhDate"]} (${recItemMap["totalDays"]} d)' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Smart AI Freight Quotations Extractor (Text & OCR Box) ──
                  _buildInlineFreightQuotationsExtractorWidget(),

                  // Study Main Settings Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.tune, color: AppTheme.cobalt, size: 18),
                              const SizedBox(width: 8),
                              Text(l.studySetupAndParameters, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal)),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Parameters Row 1
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  key: ValueKey('title_${_editingSessionId ?? "new"}_$_editFormVersion'),
                                  initialValue: _title,
                                  decoration: InputDecoration(labelText: '${l.studyTitleLabel} *', hintText: 'مثال: دراسة شحن خطوط الشرق الأقصى', isDense: true),
                                  validator: (v) => v == null || v.trim().isEmpty ? l.requiredField : null,
                                  onChanged: (v) => _title = v.trim(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _cargoReadyDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2030),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        _cargoReadyDate = picked;
                                      });
                                    }
                                  },
                                  child: InputDecorator(
                                    decoration: InputDecoration(labelText: '${l.crdLabel} *', isDense: true),
                                    child: Text(_cargoReadyDate.toString().substring(0, 10), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SearchableDropdownField<int?>(
                                  value: _selectedImportFileId,
                                  labelText: l.linkImportFile,
                                  items: [
                                    SearchableDropdownItem<int?>(value: null, label: l.unassigned),
                                    ...(ref.watch(importFilesProvider).value ?? []).map((f) => SearchableDropdownItem<int?>(
                                          value: f.importFileId,
                                          label: '[${f.importFileCode}] ${f.customFileNumber ?? f.poNumber ?? "File #${f.importFileId}"}',
                                        )),
                                  ],
                                  onChanged: (v) {
                                    setState(() {
                                      _selectedImportFileId = v;
                                      if (v != null) {
                                        final importFiles = ref.read(importFilesProvider).value ?? [];
                                        final f = importFiles.where((file) => file.importFileId == v).firstOrNull;
                                        if (f != null) {
                                          final fCode = f.customFileNumber ?? f.importFileCode;
                                          _title = '[$fCode] ${f.companyName}';
                                        }
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Parameters Row 2 (Pick-up Address)
                          TextFormField(
                            key: ValueKey('pickup_addr_${_editingSessionId ?? "new"}_$_editFormVersion'),
                            initialValue: _pickUpAddress,
                            decoration: InputDecoration(
                              labelText: l.pickupAddressLabel,
                              hintText: 'Factory / Industrial Zone, Origin Country',
                              prefixIcon: const Icon(Icons.location_on_outlined, color: AppTheme.cobalt),
                              isDense: true,
                            ),
                            onChanged: (v) => _pickUpAddress = v.trim(),
                          ),
                          const SizedBox(height: 12),

                          // Parameters Row 3 (PO Link & Project Link)
                          Row(
                            children: [
                              Expanded(
                                child: SearchableDropdownField<int?>(
                                  value: _selectedPoId,
                                  labelText: l.linkPurchaseOrder,
                                  items: [
                                    SearchableDropdownItem<int?>(value: null, label: l.unassigned),
                                    ...poList.map((po) => SearchableDropdownItem<int?>(
                                          value: po.poId,
                                          label: '${po.poNumber} (${po.supplierName ?? "Supplier"})',
                                        )),
                                  ],
                                  onChanged: (v) => setState(() => _selectedPoId = v),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SearchableDropdownField<int?>(
                                  value: _selectedProjectId,
                                  labelText: l.linkProject,
                                  items: [
                                    SearchableDropdownItem<int?>(value: null, label: l.unassigned),
                                    ...projectsList.map((p) => SearchableDropdownItem<int?>(
                                          value: p.projectId,
                                          label: '${p.projectCode} - ${p.projectName}',
                                        )),
                                  ],
                                  onChanged: (v) => setState(() => _selectedProjectId = v),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  key: ValueKey('avg_form4_${_editingSessionId ?? "new"}_$_editFormVersion'),
                                  initialValue: _avgForm4Days.toString(),
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(labelText: l.avgForm4DaysLabel, isDense: true, suffixText: 'd'),
                                  onChanged: (v) => _avgForm4Days = int.tryParse(v) ?? 5,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  key: ValueKey('avg_clearance_${_editingSessionId ?? "new"}_$_editFormVersion'),
                                  initialValue: _avgClearanceDays.toString(),
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(labelText: l.avgClearanceDaysLabel, isDense: true, suffixText: 'd'),
                                  onChanged: (v) => _avgClearanceDays = int.tryParse(v) ?? 7,
                                ),
                              ),
                            ],
                          ),

                          // Linked Packing List & Container Engine Section
                          if (_selectedImportFileId != null || _selectedPoId != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.purple.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.inventory_2, color: Colors.purple, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${l.totalShipmentSummary}: ',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                                      ),
                                      Text(
                                        '${totalCargoCbm.toStringAsFixed(3)} m³ | ${totalCargoWeightKg.toStringAsFixed(0)} kg (${filteredPOs.length} POs | $linkedPlCount items)',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  if (hasExplicitPackingList) ...[
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: hasNonStackableItems ? Colors.orange.shade50 : Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: hasNonStackableItems ? Colors.orange.shade300 : Colors.green.shade300),
                                      ),
                                      child: Text(
                                        hasNonStackableItems
                                            ? '⚠️ ${l.nonStackableOption}'
                                            : '✅ ${l.stackableOption}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          color: hasNonStackableItems ? Colors.orange.shade900 : Colors.green.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text('${l.cargoStackingType}: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal)),
                                      const SizedBox(width: 8),
                                      ChoiceChip(
                                        label: Text('📦 ${l.stackableOption}'),
                                        selected: _isStackable,
                                        selectedColor: AppTheme.cobalt,
                                        labelStyle: TextStyle(color: _isStackable ? Colors.white : AppTheme.charcoal, fontWeight: FontWeight.bold, fontSize: 11),
                                        onSelected: (val) => setState(() => _isStackable = true),
                                      ),
                                      const SizedBox(width: 8),
                                      ChoiceChip(
                                        label: Text('🚫 ${l.nonStackableOption}'),
                                        selected: !_isStackable,
                                        selectedColor: Colors.orange.shade800,
                                        labelStyle: TextStyle(color: !_isStackable ? Colors.white : AppTheme.charcoal, fontWeight: FontWeight.bold, fontSize: 11),
                                        onSelected: (val) => setState(() => _isStackable = false),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      Text('${l.approvedRecommendation}: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: (_isStackable ? AppTheme.emerald : Colors.orange.shade800).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: _isStackable ? AppTheme.emerald : Colors.orange.shade800),
                                        ),
                                        child: Text(
                                          containerRec.recommendationSummary,
                                          style: TextStyle(fontWeight: FontWeight.bold, color: _isStackable ? AppTheme.emerald : Colors.orange.shade900, fontSize: 12),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade400)),
                                        child: Text(
                                          _isStackable
                                              ? '${l.nonStackableOption}: ${dualRec.nonStackableResult.requiredContainersCount}x ${dualRec.nonStackableResult.recommendedContainerCode}'
                                              : '${l.stackableOption}: ${dualRec.stackableResult.requiredContainersCount}x ${dualRec.stackableResult.recommendedContainerCode}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 11),
                                        ),
                                      ),
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          side: const BorderSide(color: AppTheme.cobalt),
                                        ),
                                        icon: const Icon(Icons.table_chart, size: 14, color: AppTheme.cobalt),
                                        label: Text(l.compareContainersMatrix, style: const TextStyle(fontSize: 11, color: AppTheme.cobalt, fontWeight: FontWeight.bold)),
                                        onPressed: () => _showContainerComparisonDialog(context, dualRec, totalCargoCbm, totalCargoWeightKg),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.emerald,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        ),
                                        icon: const Icon(Icons.view_in_ar, size: 14, color: Colors.white),
                                        label: Text(
                                          l.visualLoadPlanSimulator,
                                          style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                        onPressed: () => _showVisualLoadPlanDialog(context, filteredPOs, totalCargoCbm, totalCargoWeightKg),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Carrier Options Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l.shippingCarrierOptions, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.charcoal)),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, foregroundColor: Colors.white),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(l.addNewShippingOption),
                        onPressed: () {
                          setState(() {
                            final defaultLineName = shippingLines.isNotEmpty ? shippingLines.first.partnerName : 'COSCO Shipping';
                            _evalItems.add(ShippingScenarioItemModel(
                              providerName: defaultLineName,
                              vesselName: 'VESSEL NEW',
                              polName: 'Shanghai Port (ميناء شانغهاي)',
                              podName: 'El Dekheila Port (ميناء الدخيلة)',
                              sailingDate: crd.add(const Duration(days: 3)).toString().substring(0, 10),
                              estimatedArrivalDate: crd.add(const Duration(days: 28)).toString().substring(0, 10),
                              expectedLineDelayDays: 2,
                            ));
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Carrier Option Cards List
                  ..._evalItems.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    final calc = calculatedScenarios.firstWhere((c) => c['index'] == idx, orElse: () => {});

                    final isExpanded = _expandedQuotes[idx] ?? false;

                    // Automatically compute containers total count for displays
                    final currentContainersCount = (item.container40ftApplicable ? item.container40ftQty : 0) + 
                                                   (item.container20ftApplicable ? item.container20ftQty : 0);

                    return Card(
                      elevation: 1.5,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: item.isRecommended 
                              ? AppTheme.emerald 
                              : (item.isExcludedFromAverage ? Colors.grey.shade400 : Colors.blue.shade200), 
                          width: item.isRecommended ? 2 : 1
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            // Row 1: Freight Forwarder, Shipping Line, Vessel & Voyage
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: item.isRecommended ? AppTheme.emerald : AppTheme.cobalt,
                                  child: Text('${idx + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: SearchableDropdownField<int?>(
                                    value: item.providerId,
                                    labelText: l.freightForwarderCol,
                                    items: [
                                      SearchableDropdownItem<int?>(value: null, label: l.unassigned),
                                      ...freightForwarders.map((p) => SearchableDropdownItem<int?>(
                                            value: p.providerId,
                                            label: p.partnerName,
                                          )),
                                    ],
                                    onChanged: (val) {
                                      final partner = freightForwarders.where((p) => p.providerId == val).firstOrNull;
                                      _updateItem(idx, item.copyWith(
                                        providerId: val,
                                        providerName: partner != null ? partner.partnerName : item.providerName,
                                      ), currenciesList);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: SearchableDropdownField<String>(
                                    value: shippingLines.any((p) => p.partnerName == item.providerName) ? item.providerName : '',
                                    labelText: '${l.shippingLineCol} *',
                                    items: [
                                      SearchableDropdownItem<String>(value: '', label: l.unassigned),
                                      ...shippingLines.map((p) => SearchableDropdownItem<String>(
                                            value: p.partnerName,
                                            label: p.partnerName,
                                          )),
                                    ],
                                    onChanged: (val) {
                                      if (val != null && val.isNotEmpty) {
                                        _updateItem(idx, item.copyWith(providerName: val), currenciesList);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    key: ValueKey('vessel_${_editingSessionId ?? "new"}_${idx}_$_editFormVersion'),
                                    initialValue: item.vesselName,
                                    decoration: InputDecoration(labelText: '${l.vesselNameCol} *', isDense: true),
                                    validator: (v) => v == null || v.trim().isEmpty ? l.requiredField : null,
                                    onChanged: (v) => _updateItem(idx, item.copyWith(vesselName: v.trim()), currenciesList),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    key: ValueKey('voyage_${_editingSessionId ?? "new"}_${idx}_$_editFormVersion'),
                                    initialValue: item.voyageNumber ?? '',
                                    decoration: InputDecoration(labelText: l.voyageCol, isDense: true),
                                    onChanged: (v) => _updateItem(idx, item.copyWith(voyageNumber: v.trim()), currenciesList),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppTheme.crimson),
                                  onPressed: _evalItems.length <= 1
                                      ? null
                                      : () {
                                          setState(() {
                                            _evalItems.removeAt(idx);
                                            _expandedQuotes.remove(idx);
                                          });
                                        },
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Row 2: POL, POD & Customs Broker Selector
                            Row(
                              children: [
                                Expanded(
                                  child: SearchableDropdownField<int?>(
                                    value: item.portOfLoadingId,
                                    labelText: l.portOfLoadingCol,
                                    items: [
                                      SearchableDropdownItem<int?>(value: null, label: l.unassigned),
                                      ...portsList.map((p) => SearchableDropdownItem<int?>(
                                            value: p.locationId,
                                            label: '${p.unLocode} - ${p.locationName} (${p.country})',
                                          )),
                                    ],
                                    onChanged: (val) {
                                      final selectedPort = portsList.where((p) => p.locationId == val).firstOrNull;
                                      _updateItem(idx, item.copyWith(
                                        portOfLoadingId: val,
                                        polName: selectedPort != null ? selectedPort.locationName : item.polName,
                                      ), currenciesList);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SearchableDropdownField<int?>(
                                    value: item.portOfDischargeId,
                                    labelText: l.portOfDischargeCol,
                                    items: [
                                      SearchableDropdownItem<int?>(value: null, label: l.unassigned),
                                      ...portsList.map((p) => SearchableDropdownItem<int?>(
                                            value: p.locationId,
                                            label: '${p.unLocode} - ${p.locationName} (${p.country})',
                                          )),
                                    ],
                                    onChanged: (val) {
                                      final selectedPort = portsList.where((p) => p.locationId == val).firstOrNull;
                                      _updateItem(idx, item.copyWith(
                                        portOfDischargeId: val,
                                        podName: selectedPort != null ? selectedPort.locationName : item.podName,
                                      ), currenciesList);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SearchableDropdownField<int?>(
                                    value: item.customsBrokerId,
                                    labelText: l.customsBrokerLabel,
                                    items: [
                                      SearchableDropdownItem<int?>(value: null, label: l.unassigned),
                                      ...customsBrokers.map((p) => SearchableDropdownItem<int?>(
                                            value: p.providerId,
                                            label: p.partnerName,
                                          )),
                                    ],
                                    onChanged: (val) {
                                      final partner = customsBrokers.where((p) => p.providerId == val).firstOrNull;
                                      _updateItem(idx, item.copyWith(
                                        customsBrokerId: val,
                                        customsBrokerName: partner?.partnerName,
                                      ), currenciesList);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Row 3: Sailing Date, ETA, Delays & Risk
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final sDate = DateTime.tryParse(item.sailingDate) ?? DateTime.now();
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: sDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2030),
                                      );
                                      if (picked != null) {
                                        _updateItem(idx, item.copyWith(sailingDate: picked.toString().substring(0, 10)), currenciesList);
                                      }
                                    },
                                    child: InputDecorator(
                                      decoration: InputDecoration(labelText: '${l.sailingDateCol} *', isDense: true),
                                      child: Text(item.sailingDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final etaDate = DateTime.tryParse(item.estimatedArrivalDate) ?? DateTime.now();
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: etaDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2030),
                                      );
                                      if (picked != null) {
                                        _updateItem(idx, item.copyWith(estimatedArrivalDate: picked.toString().substring(0, 10)), currenciesList);
                                      }
                                    },
                                    child: InputDecorator(
                                      decoration: InputDecoration(labelText: '${l.estimatedArrivalDateCol} *', isDense: true),
                                      child: Text(item.estimatedArrivalDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    key: ValueKey('delay_${_editingSessionId ?? "new"}_${idx}_$_editFormVersion'),
                                    initialValue: item.expectedLineDelayDays.toString(),
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(labelText: l.expectedDelayCol, isDense: true),
                                    onChanged: (v) {
                                      final delay = int.tryParse(v) ?? 0;
                                      _updateItem(idx, item.copyWith(expectedLineDelayDays: delay), currenciesList);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: SearchableDropdownField<String>(
                                    value: item.riskLevel,
                                    labelText: l.riskLevelCol,
                                    items: const [
                                      SearchableDropdownItem(value: 'Low', label: 'Low Risk 🟢'),
                                      SearchableDropdownItem(value: 'Medium', label: 'Medium Risk 🟠'),
                                      SearchableDropdownItem(value: 'High', label: 'High Risk 🔴'),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) {
                                        _updateItem(idx, item.copyWith(riskLevel: v), currenciesList);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                FilterChip(
                                  label: Text(item.isExcludedFromAverage ? 'Excluded 🚫' : 'Included ✅', style: TextStyle(fontSize: 11, color: item.isExcludedFromAverage ? Colors.red.shade800 : AppTheme.cobalt)),
                                  selected: item.isExcludedFromAverage,
                                  onSelected: (val) {
                                    _updateItem(idx, item.copyWith(isExcludedFromAverage: val), currenciesList);
                                  },
                                ),
                              ],
                            ),

                            // Live Calculation & Expand Quote buttons
                            if (calc.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '📍 POL: ${item.polName ?? "-"} ➔ POD: ${item.podName ?? "-"} | Lead Time: ${calc["vesselLeadTime"]}d | WH Days: ${calc["totalDays"]}d',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                                    ),
                                    Row(
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => setState(() => _expandedQuotes[idx] = !isExpanded),
                                          icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more, size: 16, color: AppTheme.cobalt),
                                          label: Text(
                                            isExpanded 
                                                ? l.hideQuote 
                                                : '${l.quoteDetails} [${item.totalQuotationAmount.toStringAsFixed(0)} ${item.quotationCurrency}]',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.cobalt),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text('${l.avgWarehouseArrivalMetric}: ${calc["expectedWhDate"]}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.emerald)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Expandable Quotation Cost Form Section (BP-008 Integration)
                            if (isExpanded) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.request_quote, color: AppTheme.cobalt, size: 18),
                                        const SizedBox(width: 6),
                                        Text(l.quoteDetails, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal)),
                                      ],
                                    ),
                                    const Divider(height: 16),
                                    
                                    // Row A: Free time & Main Quote Currency
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            key: ValueKey('freetime_${_editingSessionId ?? "new"}_${idx}_$_editFormVersion'),
                                            initialValue: item.freeTimeDays.toString(),
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(labelText: l.freeTimeDaysCol, isDense: true, suffixText: 'd'),
                                            onChanged: (v) {
                                              final ft = int.tryParse(v) ?? 14;
                                              _updateItem(idx, item.copyWith(freeTimeDays: ft), currenciesList);
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: SearchableDropdownField<String>(
                                            value: currenciesList.any((c) => c.currencyCode == item.quotationCurrency) ? item.quotationCurrency : (currenciesList.isNotEmpty ? currenciesList.first.currencyCode : 'USD'),
                                            labelText: l.quoteCurrencyCol,
                                            items: currenciesList.map((c) => SearchableDropdownItem(
                                                  value: c.currencyCode,
                                                  label: '${c.currencyCode} - ${c.currencySymbol}',
                                                )).toList(),
                                            onChanged: (v) {
                                              if (v != null) {
                                                _updateItem(idx, item.copyWith(quotationCurrency: v), currenciesList);
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Table/Grid of Cost Items (Redesigned: inputs always visible, toggles at the right side)
                                    _buildCostRow(
                                      rowKey: 'container40ft_$idx',
                                      title: '1. ${l.container40ftItem}',
                                      applicable: item.container40ftApplicable,
                                      price: item.container40ftPrice,
                                      currency: item.container40ftCurrency,
                                      qty: item.container40ftQty.toDouble(),
                                      onApplicableChanged: (v) => _updateItem(idx, item.copyWith(container40ftApplicable: v), currenciesList),
                                      onPriceChanged: (v) => _updateItem(idx, item.copyWith(container40ftPrice: v), currenciesList),
                                      onCurrencyChanged: (v) => _updateItem(idx, item.copyWith(container40ftCurrency: v), currenciesList),
                                      onQtyChanged: (v) => _updateItem(idx, item.copyWith(container40ftQty: v.toInt()), currenciesList),
                                      showQty: true,
                                      isIntegerQty: true,
                                      currenciesList: currenciesList,
                                    ),
                                    _buildCostRow(
                                      rowKey: 'container20ft_$idx',
                                      title: '2. ${l.container20ftItem}',
                                      applicable: item.container20ftApplicable,
                                      price: item.container20ftPrice,
                                      currency: item.container20ftCurrency,
                                      qty: item.container20ftQty.toDouble(),
                                      onApplicableChanged: (v) => _updateItem(idx, item.copyWith(container20ftApplicable: v), currenciesList),
                                      onPriceChanged: (v) => _updateItem(idx, item.copyWith(container20ftPrice: v), currenciesList),
                                      onCurrencyChanged: (v) => _updateItem(idx, item.copyWith(container20ftCurrency: v), currenciesList),
                                      onQtyChanged: (v) => _updateItem(idx, item.copyWith(container20ftQty: v.toInt()), currenciesList),
                                      showQty: true,
                                      isIntegerQty: true,
                                      currenciesList: currenciesList,
                                    ),
                                    _buildCostRow(
                                      rowKey: 'lclCbm_$idx',
                                      title: '3. ${l.lclCbmItem}',
                                      applicable: item.lclCbmApplicable,
                                      price: item.lclCbmPrice,
                                      currency: item.lclCbmCurrency,
                                      qty: item.lclCbmQty,
                                      onApplicableChanged: (v) => _updateItem(idx, item.copyWith(lclCbmApplicable: v), currenciesList),
                                      onPriceChanged: (v) => _updateItem(idx, item.copyWith(lclCbmPrice: v), currenciesList),
                                      onCurrencyChanged: (v) => _updateItem(idx, item.copyWith(lclCbmCurrency: v), currenciesList),
                                      onQtyChanged: (v) => _updateItem(idx, item.copyWith(lclCbmQty: v), currenciesList),
                                      showQty: true,
                                      isIntegerQty: false,
                                      currenciesList: currenciesList,
                                    ),
                                    
                                    // Total containers label
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                      child: Text(
                                        'إجمالي عدد الحاويات المطبقة = $currentContainersCount (40ft: ${item.container40ftApplicable ? item.container40ftQty : 0} | 20ft: ${item.container20ftApplicable ? item.container20ftQty : 0})',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple.shade900),
                                      ),
                                    ),

                                    _buildCostRow(
                                      rowKey: 'expressCourier_$idx',
                                      title: '4. ${l.expressCourierItem}',
                                      applicable: item.expressCourierApplicable,
                                      price: item.expressCourierPrice,
                                      currency: item.expressCourierCurrency,
                                      onApplicableChanged: (v) => _updateItem(idx, item.copyWith(expressCourierApplicable: v), currenciesList),
                                      onPriceChanged: (v) => _updateItem(idx, item.copyWith(expressCourierPrice: v), currenciesList),
                                      onCurrencyChanged: (v) => _updateItem(idx, item.copyWith(expressCourierCurrency: v), currenciesList),
                                      currenciesList: currenciesList,
                                    ),
                                    _buildCostRow(
                                      rowKey: 'eurAtr_$idx',
                                      title: '5. ${l.eurAtrItem}',
                                      applicable: item.eurAtrApplicable,
                                      price: item.eurAtrPrice,
                                      currency: item.eurAtrCurrency,
                                      onApplicableChanged: (v) => _updateItem(idx, item.copyWith(eurAtrApplicable: v), currenciesList),
                                      onPriceChanged: (v) => _updateItem(idx, item.copyWith(eurAtrPrice: v), currenciesList),
                                      onCurrencyChanged: (v) => _updateItem(idx, item.copyWith(eurAtrCurrency: v), currenciesList),
                                      currenciesList: currenciesList,
                                    ),
                                    _buildCostRow(
                                      rowKey: 'solasVgm_$idx',
                                      title: '6. ${l.solasVgmItem}',
                                      applicable: item.solasVgmApplicable,
                                      price: item.solasVgmPrice,
                                      currency: item.solasVgmCurrency,
                                      onApplicableChanged: (v) => _updateItem(idx, item.copyWith(solasVgmApplicable: v), currenciesList),
                                      onPriceChanged: (v) => _updateItem(idx, item.copyWith(solasVgmPrice: v), currenciesList),
                                      onCurrencyChanged: (v) => _updateItem(idx, item.copyWith(solasVgmCurrency: v), currenciesList),
                                      currenciesList: currenciesList,
                                    ),
                                    _buildCostRow(
                                      rowKey: 'vgmNotification_$idx',
                                      title: '7. ${l.vgmNotificationItem}',
                                      applicable: item.vgmNotificationApplicable,
                                      price: item.vgmNotificationPrice,
                                      currency: item.vgmNotificationCurrency,
                                      qty: currentContainersCount.toDouble(),
                                      onApplicableChanged: (v) => _updateItem(idx, item.copyWith(vgmNotificationApplicable: v), currenciesList),
                                      onPriceChanged: (v) => _updateItem(idx, item.copyWith(vgmNotificationPrice: v), currenciesList),
                                      onCurrencyChanged: (v) => _updateItem(idx, item.copyWith(vgmNotificationCurrency: v), currenciesList),
                                      showQty: true,
                                      qtyReadOnly: true,
                                      currenciesList: currenciesList,
                                    ),
                                    _buildCostRow(
                                      rowKey: 'telexRelease_$idx',
                                      title: '8. ${l.telexReleaseItem}',
                                      applicable: item.telexReleaseApplicable,
                                      price: item.telexReleasePrice,
                                      currency: item.telexReleaseCurrency,
                                      onApplicableChanged: (v) => _updateItem(idx, item.copyWith(telexReleaseApplicable: v), currenciesList),
                                      onPriceChanged: (v) => _updateItem(idx, item.copyWith(telexReleasePrice: v), currenciesList),
                                      onCurrencyChanged: (v) => _updateItem(idx, item.copyWith(telexReleaseCurrency: v), currenciesList),
                                      currenciesList: currenciesList,
                                    ),
                                    _buildCostRow(
                                      rowKey: 'insurance_$idx',
                                      title: '9. ${l.insuranceItem}',
                                      applicable: item.insuranceApplicable,
                                      price: item.insurancePrice,
                                      currency: item.insuranceCurrency,
                                      onApplicableChanged: (v) => _updateItem(idx, item.copyWith(insuranceApplicable: v), currenciesList),
                                      onPriceChanged: (v) => _updateItem(idx, item.copyWith(insurancePrice: v), currenciesList),
                                      onCurrencyChanged: (v) => _updateItem(idx, item.copyWith(insuranceCurrency: v), currenciesList),
                                      currenciesList: currenciesList,
                                    ),

                                    _buildCostRow(
                                      rowKey: 'bookingCancellation_$idx',
                                      title: '10. ${l.bookingCancellationItem}',
                                      applicable: item.bookingCancellationApplicable,
                                      price: item.bookingCancellationPrice,
                                      currency: item.bookingCancellationCurrency,
                                      onApplicableChanged: (v) => _updateItem(idx, item.copyWith(bookingCancellationApplicable: v), currenciesList),
                                      onPriceChanged: (v) => _updateItem(idx, item.copyWith(bookingCancellationPrice: v), currenciesList),
                                      onCurrencyChanged: (v) => _updateItem(idx, item.copyWith(bookingCancellationCurrency: v), currenciesList),
                                      currenciesList: currenciesList,
                                    ),

                                    // New Cost Rows
                                    _buildCostRow(
                                      rowKey: 'ics2FilingFee_$idx',
                                      title: '11. ${l.ics2FilingFeeItem}',
                                      applicable: item.ics2FilingFeeApplicable,
                                      price: item.ics2FilingFeePrice,
                                      currency: item.ics2FilingFeeCurrency,
                                      onApplicableChanged: (v) => _updateItem(idx, item.copyWith(ics2FilingFeeApplicable: v), currenciesList),
                                      onPriceChanged: (v) => _updateItem(idx, item.copyWith(ics2FilingFeePrice: v), currenciesList),
                                      onCurrencyChanged: (v) => _updateItem(idx, item.copyWith(ics2FilingFeeCurrency: v), currenciesList),
                                      currenciesList: currenciesList,
                                    ),
                                    _buildCostRow(
                                      rowKey: 'documentFees_$idx',
                                      title: '12. ${l.documentFeesItem}',
                                      applicable: item.documentFeesApplicable,
                                      price: item.documentFeesPrice,
                                      currency: item.documentFeesCurrency,
                                      onApplicableChanged: (v) => _updateItem(idx, item.copyWith(documentFeesApplicable: v), currenciesList),
                                      onPriceChanged: (v) => _updateItem(idx, item.copyWith(documentFeesPrice: v), currenciesList),
                                      onCurrencyChanged: (v) => _updateItem(idx, item.copyWith(documentFeesCurrency: v), currenciesList),
                                      currenciesList: currenciesList,
                                    ),
                                    _buildCostRow(
                                      rowKey: 'waiverLetterFee_$idx',
                                      title: '13. ${l.waiverLetterFeeItem}',
                                      applicable: item.waiverLetterFeeApplicable,
                                      price: item.waiverLetterFeePrice,
                                      currency: item.waiverLetterFeeCurrency,
                                      onApplicableChanged: (v) => _updateItem(idx, item.copyWith(waiverLetterFeeApplicable: v), currenciesList),
                                      onPriceChanged: (v) => _updateItem(idx, item.copyWith(waiverLetterFeePrice: v), currenciesList),
                                      onCurrencyChanged: (v) => _updateItem(idx, item.copyWith(waiverLetterFeeCurrency: v), currenciesList),
                                      currenciesList: currenciesList,
                                    ),
                                    _buildCostRow(
                                      rowKey: 'othersFee_$idx',
                                      title: '14. ${l.othersFeeItem}',
                                      applicable: item.othersFeeApplicable,
                                      price: item.othersFeePrice,
                                      currency: item.othersFeeCurrency,
                                      onApplicableChanged: (v) => _updateItem(idx, item.copyWith(othersFeeApplicable: v), currenciesList),
                                      onPriceChanged: (v) => _updateItem(idx, item.copyWith(othersFeePrice: v), currenciesList),
                                      onCurrencyChanged: (v) => _updateItem(idx, item.copyWith(othersFeeCurrency: v), currenciesList),
                                      currenciesList: currenciesList,
                                    ),
                                     _buildCostRow(
                                       rowKey: 'dthc_$idx',
                                       title: '15. ${l.dthcItem}',
                                       applicable: item.dthcApplicable,
                                       price: item.dthcPrice,
                                       currency: item.dthcCurrency,
                                       onApplicableChanged: (v) => _updateItem(idx, item.copyWith(dthcApplicable: v), currenciesList),
                                       onPriceChanged: (v) => _updateItem(idx, item.copyWith(dthcPrice: v), currenciesList),
                                       onCurrencyChanged: (v) => _updateItem(idx, item.copyWith(dthcCurrency: v), currenciesList),
                                       currenciesList: currenciesList,
                                     ),
                                     _buildCostRow(
                                       rowKey: 'storagePerWeek_$idx',
                                       title: '16. ${l.storagePerWeekItem}',
                                       applicable: item.storagePerWeekApplicable,
                                       price: item.storagePerWeekPrice,
                                       currency: item.storagePerWeekCurrency,
                                       onApplicableChanged: (v) => _updateItem(idx, item.copyWith(storagePerWeekApplicable: v), currenciesList),
                                       onPriceChanged: (v) => _updateItem(idx, item.copyWith(storagePerWeekPrice: v), currenciesList),
                                       onCurrencyChanged: (v) => _updateItem(idx, item.copyWith(storagePerWeekCurrency: v), currenciesList),
                                       currenciesList: currenciesList,
                                     ),
                                     _buildCostRow(
                                       rowKey: 'extraDayStorage_$idx',
                                       title: '17. ${l.extraDayStorageItem}',
                                       applicable: item.extraDayStorageApplicable,
                                       price: item.extraDayStoragePrice,
                                       currency: item.extraDayStorageCurrency,
                                       onApplicableChanged: (v) => _updateItem(idx, item.copyWith(extraDayStorageApplicable: v), currenciesList),
                                       onPriceChanged: (v) => _updateItem(idx, item.copyWith(extraDayStoragePrice: v), currenciesList),
                                       onCurrencyChanged: (v) => _updateItem(idx, item.copyWith(extraDayStorageCurrency: v), currenciesList),
                                       currenciesList: currenciesList,
                                     ),
                                    
                                    const Divider(height: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.cobalt.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppTheme.cobalt.withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${l.totalQuoteValue}:',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                                          ),
                                          Text(
                                            '${item.totalQuotationAmount.toStringAsFixed(0)} ${item.quotationCurrency}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.cobalt),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),

                  // Comparison Summary Table
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.sideBySideComparison, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal)),
                          const SizedBox(height: 10),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(AppTheme.charcoal),
                              headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              columns: [
                                const DataColumn(label: Text('#')),
                                DataColumn(label: Text(l.shippingLineCol)),
                                DataColumn(label: Text(l.totalQuoteValue)),
                                DataColumn(label: Text(l.avgWarehouseArrivalMetric)),
                                DataColumn(label: Text(l.avgTransitMetric)),
                                DataColumn(label: Text(l.customsBrokerLabel)),
                                DataColumn(label: Text('${l.portOfLoadingCol} / ${l.portOfDischargeCol}')),
                                DataColumn(label: Text(l.vesselNameCol)),
                                DataColumn(label: Text(l.sailingDateCol)),
                                DataColumn(label: Text(l.estimatedArrivalDateCol)),
                                const DataColumn(label: Text('Lead Time')),
                                DataColumn(label: Text(l.freeTimeDaysCol)),
                                DataColumn(label: Text(l.expectedDelayCol)),
                                DataColumn(label: Text(l.riskLevelCol)),
                                DataColumn(label: Text(l.statusCol)),
                              ],
                              rows: calculatedScenarios.map((c) {
                                final idx = c['index'] as int;
                                final item = c['item'] as ShippingScenarioItemModel;
                                return DataRow(
                                  cells: [
                                    DataCell(Text('${idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold))),
                                    DataCell(Text(item.providerName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                                    DataCell(Text('${item.totalQuotationAmount.toStringAsFixed(0)} ${item.quotationCurrency}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red))),
                                    DataCell(Text('${c["expectedWhDate"]}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald))),
                                    DataCell(Text('${c["totalDays"]} d', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple))),
                                    DataCell(Text(item.customsBrokerName ?? '-')),
                                    DataCell(Text('${item.polName ?? "-"} ➔ ${item.podName ?? "-"}', style: const TextStyle(fontSize: 11))),
                                    DataCell(Text('${item.vesselName} (${item.voyageNumber ?? "-"})')),
                                    DataCell(Text(item.sailingDate)),
                                    DataCell(Text(item.estimatedArrivalDate)),
                                    DataCell(Text('${c["vesselLeadTime"]} d')),
                                    DataCell(Text('${item.freeTimeDays} d', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                                    DataCell(Text('${item.expectedLineDelayDays} d')),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: item.riskLevel == 'High' ? Colors.red.shade100 : item.riskLevel == 'Medium' ? Colors.orange.shade100 : Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(item.riskLevel, style: TextStyle(color: item.riskLevel == 'High' ? Colors.red.shade900 : item.riskLevel == 'Medium' ? Colors.orange.shade900 : Colors.green.shade900, fontWeight: FontWeight.bold, fontSize: 11)),
                                      ),
                                    ),
                                    DataCell(Text(item.isExcludedFromAverage ? 'Excluded 🚫' : 'Included ✅', style: TextStyle(color: item.isExcludedFromAverage ? Colors.red : AppTheme.cobalt, fontSize: 11))),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

          // Bottom Fixed Action Bar with 3 Standard ERP Action Buttons
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, -2))],
              ),
              child: Row(
                children: [
                  // 1. Live Refresh Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.charcoal,
                      side: BorderSide(color: Colors.grey.shade400),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    icon: const Icon(Icons.refresh, size: 18, color: AppTheme.cobalt),
                    label: Text('${l.liveRefresh} 🔄', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _refreshData(force: true),
                  ),
                  const SizedBox(width: 8),

                  // 2. Clear Form & Start New
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade800,
                      side: BorderSide(color: Colors.grey.shade400),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    icon: const Icon(Icons.cleaning_services_outlined, size: 18, color: Colors.blueGrey),
                    label: Text('${l.clearAndStartNew} 🔄', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: _resetFormForNewStudy,
                  ),
                  const SizedBox(width: 8),

                  // 3. Save Draft & Continue Later
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEFF6FF),
                      foregroundColor: AppTheme.cobalt,
                      elevation: 0,
                      side: const BorderSide(color: AppTheme.cobalt),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    icon: const Icon(Icons.save_outlined, size: 18, color: AppTheme.cobalt),
                    label: Text('${l.saveDraftContinueLater} 💾', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: _isSaving ? null : () => _saveEvaluationSession(context, currenciesList),
                  ),
                  const Spacer(),

                  // 4. Final Submit / Save Study
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                      elevation: 2,
                    ),
                    icon: _isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.check_circle_outline, size: 20),
                    label: Text(
                      _editingSessionId != null ? '${l.saveChanges} 💾' : '${l.saveAndSubmitStudy} ✅',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: _isSaving ? null : () => _saveEvaluationSession(context, currenciesList),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostRow({
    required String rowKey,
    required String title,
    required bool applicable,
    required double price,
    required String currency,
    double qty = 1.0,
    required ValueChanged<bool> onApplicableChanged,
    required ValueChanged<double> onPriceChanged,
    required ValueChanged<String> onCurrencyChanged,
    ValueChanged<double>? onQtyChanged,
    bool showQty = false,
    bool qtyReadOnly = false,
    bool isIntegerQty = true,
    required List<CurrencyModel> currenciesList,
  }) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Title
          Expanded(
            flex: 3,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          // Price field (always visible with stable key)
          Expanded(
            flex: 2,
            child: TextFormField(
              key: ValueKey('price_${rowKey}_${_editingSessionId ?? "new"}_$_editFormVersion'),
              initialValue: price == 0.0 ? '' : price.toString(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l.itemPriceCol, isDense: true),
              onChanged: (v) {
                final p = double.tryParse(v) ?? 0.0;
                onPriceChanged(p);
              },
            ),
          ),
          const SizedBox(width: 8),
          // Currency dropdown (always visible, dynamic list from DB)
          Expanded(
            flex: 2,
            child: SearchableDropdownField<String>(
              value: currenciesList.any((c) => c.currencyCode == currency) ? currency : (currenciesList.isNotEmpty ? currenciesList.first.currencyCode : 'USD'),
              labelText: l.currency,
              items: currenciesList.map((c) => SearchableDropdownItem(
                    value: c.currencyCode,
                    label: '${c.currencyCode} (${c.currencySymbol})',
                  )).toList(),
              onChanged: (v) {
                if (v != null) {
                  onCurrencyChanged(v);
                }
              },
            ),
          ),
          if (showQty) ...[
            const SizedBox(width: 8),
            // Qty field (always visible when showQty is true with stable key)
            Expanded(
              flex: 2,
              child: TextFormField(
                key: qtyReadOnly
                    ? ValueKey('readonly_qty_${rowKey}_$qty')
                    : ValueKey('qty_${rowKey}_${_editingSessionId ?? "new"}_$_editFormVersion'),
                readOnly: qtyReadOnly,
                initialValue: qty == 0.0 ? '' : (isIntegerQty ? qty.toInt().toString() : qty.toString()),
                keyboardType: TextInputType.numberWithOptions(decimal: !isIntegerQty),
                decoration: InputDecoration(labelText: l.quantity, isDense: true),
                onChanged: qtyReadOnly ? null : (v) {
                  final q = double.tryParse(v) ?? 0.0;
                  if (onQtyChanged != null) {
                    onQtyChanged(q);
                  }
                },
              ),
            ),
          ],
          const SizedBox(width: 12),
          // Applicable switch (moved after inputs)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: applicable,
                activeColor: AppTheme.cobalt,
                onChanged: onApplicableChanged,
              ),
              Text(
                applicable ? l.applicable : l.notApplicable,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: applicable ? AppTheme.emerald : Colors.red.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Line total display (dynamically shows 0.0 if not applicable)
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: applicable ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: applicable ? Colors.green.shade200 : Colors.red.shade200),
              ),
              child: Text(
                applicable 
                    ? '${(price * qty).toStringAsFixed(0)} $currency'
                    : '0.0 $currency',
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 11, 
                  color: applicable ? AppTheme.emerald : Colors.red.shade900
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String val, IconData icon, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 6),
          Text(val, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.black87, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }

  Future<void> _saveEvaluationSession(BuildContext context, List<CurrencyModel> currenciesList) async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ يرجى التأكد من استكمال كافة البيانات الإلزامية مثل عنوان الدراسة!'),
          backgroundColor: AppTheme.crimson,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Client-side validation of shipping scenarios items
    final seen = <String>{};
    for (int i = 0; i < _evalItems.length; i++) {
      final item = _evalItems[i];
      if (item.providerName.isEmpty || item.providerName == 'Select Line') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ خيار الشحن #${i + 1}: يرجى اختيار الخط الملاحي (Shipping Line)!'),
            backgroundColor: AppTheme.crimson,
          ),
        );
        return;
      }

      final sDate = DateTime.tryParse(item.sailingDate);
      final etaDate = DateTime.tryParse(item.estimatedArrivalDate);

      if (sDate == null || etaDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ خيار الشحن #${i + 1} (${item.providerName}): يرجى تحديد التواريخ بشكل صحيح!'),
            backgroundColor: AppTheme.crimson,
          ),
        );
        return;
      }

      // Check date constraints: sailing date must be on or after CRD
      final crdDateOnly = DateTime(_cargoReadyDate.year, _cargoReadyDate.month, _cargoReadyDate.day);
      final sailingDateOnly = DateTime(sDate.year, sDate.month, sDate.day);
      if (sailingDateOnly.isBefore(crdDateOnly)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ خيار الشحن #${i + 1} (${item.providerName}): تاريخ الإبحار (${item.sailingDate}) لا يمكن أن يكون قبل تاريخ جاهزية البضاعة (CRD: ${crdDateOnly.toString().substring(0, 10)})!'),
            backgroundColor: AppTheme.crimson,
          ),
        );
        return;
      }

      // Check date constraints: ETA must be after sailing date
      if (!etaDate.isAfter(sDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ خيار الشحن #${i + 1} (${item.providerName}): تاريخ الوصول (ETA: ${item.estimatedArrivalDate}) يجب أن يكون بعد تاريخ الإبحار (${item.sailingDate})!'),
            backgroundColor: AppTheme.crimson,
          ),
        );
        return;
      }

      if (item.expectedLineDelayDays < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ خيار الشحن #${i + 1} (${item.providerName}): أيام التأخير المتوقعة لا يمكن أن تكون سالبة!'),
            backgroundColor: AppTheme.crimson,
          ),
        );
        return;
      }

      // Check duplicates (same Freight Forwarder, Shipping Line, Vessel, and Sailing Date)
      final key = '${item.providerId}_${item.providerName.trim().toLowerCase()}_${item.vesselName.trim().toLowerCase()}_${item.sailingDate}';
      if (seen.contains(key)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ خيار الشحن #${i + 1} (${item.providerName}): مكرر! يوجد خيار آخر بنفس شركة وكيل الشحن والخط الملاحي والرحلة وتاريخ الإبحار.'),
            backgroundColor: AppTheme.crimson,
          ),
        );
        return;
      }
      seen.add(key);
    }

    _formKey.currentState!.save();

    String titleToSave = _title.trim();
    if (_selectedImportFileId != null) {
      final importFiles = ref.read(importFilesProvider).value ?? [];
      final f = importFiles.where((file) => file.importFileId == _selectedImportFileId).firstOrNull;
      if (f != null) {
        final fCode = f.customFileNumber ?? f.importFileCode;
        if (!titleToSave.startsWith('[$fCode]')) {
          titleToSave = '[$fCode] ${f.companyName}';
        }
      }
    }
    if (titleToSave.isEmpty) {
      titleToSave = 'دراسة تقييم خيارات الشحن (${DateTime.now().toString().substring(0, 10)})';
    }

    setState(() => _isSaving = true);

    bool ok = false;
    if (_editingSessionId != null) {
      final oldSession = ref.read(shippingScenariosProvider).sessions.where((s) => s.sessionId == _editingSessionId).firstOrNull;
      if (oldSession != null) {
        final List<FieldChangeItem> changes = [];

        // 1. General & Header Data
        if (FieldChangeItem.isDifferent(oldSession.title, titleToSave)) {
          changes.add(FieldChangeItem(
            section: 'البيانات العامة للدراسة',
            fieldName: 'عنوان دراسة الشحن',
            oldValue: oldSession.title,
            newValue: titleToSave,
          ));
        }

        final newCrd = _cargoReadyDate.toString().substring(0, 10);
        if (FieldChangeItem.isDifferent(oldSession.cargoReadyDate, newCrd)) {
          changes.add(FieldChangeItem(
            section: 'البيانات العامة للدراسة',
            fieldName: 'تاريخ جاهزية البضاعة (CRD)',
            oldValue: oldSession.cargoReadyDate,
            newValue: newCrd,
          ));
        }

        final newPickup = _pickUpAddress.trim().isNotEmpty ? _pickUpAddress.trim() : null;
        if (FieldChangeItem.isDifferent(oldSession.pickUpAddress, newPickup)) {
          changes.add(FieldChangeItem(
            section: 'البيانات العامة للدراسة',
            fieldName: 'موقع وعنوان الاستلام',
            oldValue: oldSession.pickUpAddress,
            newValue: newPickup,
          ));
        }

        if (FieldChangeItem.isDifferent(oldSession.avgForm4Days, _avgForm4Days)) {
          changes.add(FieldChangeItem(
            section: 'البيانات العامة للدراسة',
            fieldName: 'أيام إصدار نموذج 4 المتوقعة',
            oldValue: '${oldSession.avgForm4Days} يوم',
            newValue: '$_avgForm4Days يوم',
          ));
        }

        if (FieldChangeItem.isDifferent(oldSession.avgClearanceDays, _avgClearanceDays)) {
          changes.add(FieldChangeItem(
            section: 'البيانات العامة للدراسة',
            fieldName: 'أيام التخليص الجمركي المتوقعة',
            oldValue: '${oldSession.avgClearanceDays} يوم',
            newValue: '$_avgClearanceDays يوم',
          ));
        }

        if (FieldChangeItem.isDifferent(oldSession.importFileId, _selectedImportFileId)) {
          changes.add(FieldChangeItem(
            section: 'الربط التشغيلي',
            fieldName: 'ملف الاستيراد المرتبط',
            oldValue: oldSession.importFileCode ?? (oldSession.importFileId != null ? 'ID: ${oldSession.importFileId}' : null),
            newValue: _selectedImportFileId != null ? 'ID: $_selectedImportFileId' : null,
          ));
        }

        if (FieldChangeItem.isDifferent(oldSession.poId, _selectedPoId)) {
          changes.add(FieldChangeItem(
            section: 'الربط التشغيلي',
            fieldName: 'أمر الشراء المرتبط (PO)',
            oldValue: oldSession.poNumber ?? (oldSession.poId != null ? 'ID: ${oldSession.poId}' : null),
            newValue: _selectedPoId != null ? 'ID: $_selectedPoId' : null,
          ));
        }

        // 2. Shipping Options / Quotation Items
        if (oldSession.items.length != _evalItems.length) {
          changes.add(FieldChangeItem(
            section: 'عروض أسعار الشحن المقارنة',
            fieldName: 'عدد عروض الشحن المدرجة',
            oldValue: '${oldSession.items.length} عرض',
            newValue: '${_evalItems.length} عرض',
          ));
        } else {
          for (int i = 0; i < _evalItems.length; i++) {
            final o = oldSession.items[i];
            final n = _evalItems[i];
            final quoteTitle = 'عرض #${i + 1} (${n.providerName.isNotEmpty ? n.providerName : "ناقل"})';

            if (FieldChangeItem.isDifferent(o.providerName, n.providerName)) {
              changes.add(FieldChangeItem(
                section: 'عروض أسعار الشحن المقارنة',
                fieldName: '$quoteTitle - وكيل الشحن (Forwarder)',
                oldValue: o.providerName,
                newValue: n.providerName,
              ));
            }
            if (FieldChangeItem.isDifferent(o.vesselName, n.vesselName)) {
              changes.add(FieldChangeItem(
                section: 'عروض أسعار الشحن المقارنة',
                fieldName: '$quoteTitle - الخط الملاحي / الباخرة (Carrier / Vessel)',
                oldValue: o.vesselName,
                newValue: n.vesselName,
              ));
            }
            if (FieldChangeItem.isDifferent(o.sailingDate, n.sailingDate)) {
              changes.add(FieldChangeItem(
                section: 'عروض أسعار الشحن المقارنة',
                fieldName: '$quoteTitle - تاريخ الإبحار (ETD)',
                oldValue: o.sailingDate,
                newValue: n.sailingDate,
              ));
            }
            if (FieldChangeItem.isDifferent(o.estimatedArrivalDate, n.estimatedArrivalDate)) {
              changes.add(FieldChangeItem(
                section: 'عروض أسعار الشحن المقارنة',
                fieldName: '$quoteTitle - تاريخ الوصول المتوقع (ETA)',
                oldValue: o.estimatedArrivalDate,
                newValue: n.estimatedArrivalDate,
              ));
            }
            if (FieldChangeItem.isDifferent(o.freeTimeDays, n.freeTimeDays)) {
              changes.add(FieldChangeItem(
                section: 'عروض أسعار الشحن المقارنة',
                fieldName: '$quoteTitle - أيام السماح (Free Time)',
                oldValue: '${o.freeTimeDays} يوم',
                newValue: '${n.freeTimeDays} يوم',
              ));
            }
            if (FieldChangeItem.isDifferent(o.totalQuotationAmount, n.totalQuotationAmount)) {
              changes.add(FieldChangeItem(
                section: 'عروض أسعار الشحن المقارنة',
                fieldName: '$quoteTitle - إجمالي قيمة العرض (${n.quotationCurrency})',
                oldValue: '${o.totalQuotationAmount.toStringAsFixed(2)} ${o.quotationCurrency}',
                newValue: '${n.totalQuotationAmount.toStringAsFixed(2)} ${n.quotationCurrency}',
              ));
            }
            if (FieldChangeItem.isDifferent(o.isExcludedFromAverage, n.isExcludedFromAverage)) {
              changes.add(FieldChangeItem(
                section: 'عروض أسعار الشحن المقارنة',
                fieldName: '$quoteTitle - استبعاد من المتوسط الحسابي',
                oldValue: o.isExcludedFromAverage ? 'مستبعد' : 'محتسب',
                newValue: n.isExcludedFromAverage ? 'مستبعد' : 'محتسب',
              ));
            }
          }
        }

        if (changes.isNotEmpty) {
          if (!context.mounted) return;
          final confirmed = await showChangeDiffConfirmationDialog(
            context,
            title: 'مراجعة وتأكيد تعديلات دراسة وعروض الشحن',
            itemReference: oldSession.sessionCode.isNotEmpty ? oldSession.sessionCode : titleToSave,
            changes: changes,
          );
          if (!confirmed) {
            setState(() => _isSaving = false);
            return;
          }
        }
      }

      final data = {
        'title': titleToSave,
        'cargo_ready_date': _cargoReadyDate.toString().substring(0, 10),
        if (_pickUpAddress.trim().isNotEmpty) 'pick_up_address': _pickUpAddress.trim(),
        'avg_form4_days': _avgForm4Days,
        'avg_clearance_days': _avgClearanceDays,
        if (_selectedImportFileId != null) 'import_file_id': _selectedImportFileId,
        if (_selectedPoId != null) 'po_id': _selectedPoId,
        if (_selectedProjectId != null) 'project_id': _selectedProjectId,
        'is_active': true,
        'items': _evalItems.map((i) => i.toCreateJson()).toList(),
      };
      ok = await ref.read(shippingScenariosProvider.notifier).updateSession(_editingSessionId!, data);
    } else {
      final session = ShippingEvaluationModel(
        sessionCode: '',
        title: titleToSave,
        cargoReadyDate: _cargoReadyDate.toString().substring(0, 10),
        pickUpAddress: _pickUpAddress.trim().isNotEmpty ? _pickUpAddress.trim() : null,
        avgForm4Days: _avgForm4Days,
        avgClearanceDays: _avgClearanceDays,
        importFileId: _selectedImportFileId,
        poId: _selectedPoId,
        projectId: _selectedProjectId,
        notes: _sessionNotes,
        items: _evalItems,
      );
      ok = await ref.read(shippingScenariosProvider.notifier).createSession(session);
    }

    setState(() => _isSaving = false);

    if (ok && context.mounted) {
      // Find the newly saved study from provider state
      final freshState = ref.read(shippingScenariosProvider);
      final savedSess = freshState.sessions.firstWhere(
        (s) => s.title == titleToSave || s.sessionCode == _editingSessionCode,
        orElse: () => ShippingEvaluationModel(
          sessionCode: _editingSessionCode ?? 'NEW',
          title: titleToSave,
          cargoReadyDate: _cargoReadyDate.toString().substring(0, 10),
          items: _evalItems,
          recommendedScenarioProvider: _evalItems.firstWhere((i) => i.isRecommended, orElse: () => _evalItems.first).providerName,
        ),
      );

      _resetFormForNewStudy();
      _tabController.animateTo(1);

      // Instantly pop up the detailed Arabic/English results summary dialog per user instructions
      _showSaveSuccessReportDialog(context, savedSess);
    } else if (!ok && context.mounted) {
      final err = ref.read(shippingScenariosProvider).errorMessage ?? 'فشلت عملية حفظ الدراسة والنتائج';
      await showErrorDetailsDialog(
        context,
        title: '❌ تعذر حفظ دراسة وتقييم خيارات الشحن',
        error: err,
        onRetry: () async {
          await _saveEvaluationSession(context, currenciesList);
        },
      );
    }
  }

  void _showSaveSuccessReportDialog(BuildContext context, ShippingEvaluationModel sess) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.emerald, size: 28),
            SizedBox(width: 10),
            Text('🏆 تقرير نتائج دراسة الشحن والعروض المحفوظة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 850,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('رمز دراسة الشحن: ${sess.sessionCode}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('عنوان الدراسة: ${sess.title ?? "N/A"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('تاريخ الجاهزية (CRD): ${sess.cargoReadyDate} | مكان الاستلام: ${sess.pickUpAddress ?? "غير محدد"}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('📊 التقرير المقارن للخطوط والرحلات المقيمة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal)),
                const SizedBox(height: 8),
                Table(
                  border: TableBorder.all(color: Colors.grey.shade300),
                  columnWidths: const {
                    0: FlexColumnWidth(1.5),
                    1: FlexColumnWidth(1.1),
                    2: FlexColumnWidth(1.1),
                    3: FlexColumnWidth(1.1),
                    4: FlexColumnWidth(1.2),
                    5: FlexColumnWidth(1.5),
                    6: FlexColumnWidth(1.0),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: AppTheme.charcoal.withOpacity(0.08)),
                      children: const [
                        Padding(padding: EdgeInsets.all(8), child: Text('الناقل / الخط الملاحي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Padding(padding: EdgeInsets.all(8), child: Text('تاريخ الإبحار', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Padding(padding: EdgeInsets.all(8), child: Text('الوصول للميناء', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Padding(padding: EdgeInsets.all(8), child: Text('إجمالي الأيام', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Padding(padding: EdgeInsets.all(8), child: Text('موعد المخزن المتوقع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Padding(padding: EdgeInsets.all(8), child: Text('إجمالي قيمة العرض', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Padding(padding: EdgeInsets.all(8), child: Text('الترشيح', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      ],
                    ),
                    ...sess.items.map((item) {
                      return TableRow(
                        decoration: BoxDecoration(color: item.isRecommended ? Colors.green.shade50.withOpacity(0.5) : null),
                        children: [
                          Padding(padding: const EdgeInsets.all(8), child: Text(item.providerName, style: TextStyle(fontWeight: item.isRecommended ? FontWeight.bold : FontWeight.normal, fontSize: 11))),
                          Padding(padding: const EdgeInsets.all(8), child: Text(item.sailingDate, style: const TextStyle(fontSize: 11))),
                          Padding(padding: const EdgeInsets.all(8), child: Text(item.estimatedArrivalDate, style: const TextStyle(fontSize: 11))),
                          Padding(padding: const EdgeInsets.all(8), child: Text('${item.expectedTotalDaysToWarehouse} يوم', style: const TextStyle(fontSize: 11))),
                          Padding(padding: const EdgeInsets.all(8), child: Text(item.expectedWarehouseArrivalDate, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                          Padding(padding: const EdgeInsets.all(8), child: Text('${item.totalQuotationAmount.toStringAsFixed(0)} ${item.quotationCurrency}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red))),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              item.isRecommended ? '🟢 موصى به' : (item.isExcludedFromAverage ? '🚫 مستبعد' : 'عادي'),
                              style: TextStyle(fontWeight: FontWeight.bold, color: item.isRecommended ? AppTheme.emerald : Colors.grey, fontSize: 10),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                  child: Row(
                    children: [
                      const Icon(Icons.stars, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'الخط الملاحي الموصى به رسميًا للربط والتعاقد: ${sess.recommendedScenarioProvider ?? "لم يحدد بعد"}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: 'دراسة الشحن والأسعار ${sess.sessionCode}: ${sess.title}\nالخط الموصى به: ${sess.recommendedScenarioProvider}\nتاريخ وصول المخزن: ${sess.avgExpectedWarehouseArrivalDate}'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('📋 تم نسخ ملخص النتائج للحافظة!'), backgroundColor: AppTheme.cobalt),
              );
            },
            child: const Text('نسخ ملخص النتائج'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('موافق (تم الحفظ)'),
          ),
        ],
      ),
    );
  }


  void _showContainerComparisonDialog(
    BuildContext context,
    ContainerDualRecommendationResult dualRec,
    double cbm,
    double weightKg,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('🚚 مقارنة حالة الرص القابل وغير القابل للرص (Dual Container Matrix)'),
        content: SizedBox(
          width: 650,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('إجمالي CBM الشحنة: ${cbm.toStringAsFixed(3)} m³ | إجمالي الوزن: ${weightKg.toStringAsFixed(0)} kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 12),
              Table(
                border: TableBorder.all(color: Colors.grey.shade300),
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: AppTheme.charcoal.withOpacity(0.08)),
                    children: const [
                      Padding(padding: EdgeInsets.all(8), child: Text('الخاصية / Scenario', style: TextStyle(fontWeight: FontWeight.bold))),
                      Padding(padding: EdgeInsets.all(8), child: Text('📦 قابل للرص (Stackable)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald))),
                      Padding(padding: EdgeInsets.all(8), child: Text('🚫 غير قابل للرص (Non-Stackable)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.orange))),
                    ],
                  ),
                  TableRow(
                    children: [
                      const Padding(padding: EdgeInsets.all(8), child: Text('نوع الحاوية الموصى بها')),
                      Padding(padding: const EdgeInsets.all(8), child: Text(dualRec.stackableResult.recommendedContainerCode, style: const TextStyle(fontWeight: FontWeight.bold))),
                      Padding(padding: const EdgeInsets.all(8), child: Text(dualRec.nonStackableResult.recommendedContainerCode, style: const TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                  TableRow(
                    children: [
                      const Padding(padding: EdgeInsets.all(8), child: Text('عدد الحاويات المطلوبة')),
                      Padding(padding: const EdgeInsets.all(8), child: Text('${dualRec.stackableResult.requiredContainersCount} حاويات', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                      Padding(padding: const EdgeInsets.all(8), child: Text('${dualRec.nonStackableResult.requiredContainersCount} حاويات', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple))),
                    ],
                  ),
                  TableRow(
                    children: [
                      const Padding(padding: EdgeInsets.all(8), child: Text('نسبة استغلال حجم الحاوية')),
                      Padding(padding: const EdgeInsets.all(8), child: Text('${dualRec.stackableResult.spaceUtilizationPercent.toStringAsFixed(1)}%')),
                      Padding(padding: const EdgeInsets.all(8), child: Text('${dualRec.nonStackableResult.spaceUtilizationPercent.toStringAsFixed(1)}%')),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  void _showVisualLoadPlanDialog(BuildContext context, List<PurchaseOrderModel> pos, double totalCbm, double totalWeight) {
    final List<CargoItem> baseCargoItems = [];
    int itemCounter = 1;

    for (final po in pos) {
      final hasPalletPlan = po.palletPlanItems.isNotEmpty && po.palletPlanItems.any((p) => p.palletCount > 0);
      final hasSinglePallet = po.palletCount > 0 && po.palletLengthCm > 0 && po.palletWidthCm > 0 && po.palletHeightCm > 0;

      if (hasPalletPlan) {
        final double totalGross = po.packingListItems.fold<double>(
          0.0,
          (sum, p) => sum + (p.totalGrossWeightKg > 0 ? p.totalGrossWeightKg : (p.qtyPkg * p.grossWeightUnitKg)),
        );
        final int totalPallets = po.palletPlanItems.fold<int>(0, (sum, p) => sum + p.palletCount);
        final double defaultPalletWeight = totalPallets > 0 && totalGross > 0 ? (totalGross / totalPallets) : 137.5;

        for (final pLine in po.palletPlanItems) {
          final pL = pLine.lengthCm > 0 ? pLine.lengthCm : 120.0;
          final pW = pLine.widthCm > 0 ? pLine.widthCm : 80.0;
          final pH = pLine.heightCm > 0 ? pLine.heightCm : 150.0;
          final pWt = pLine.grossWeightPerPalletKg > 0 ? pLine.grossWeightPerPalletKg : defaultPalletWeight;

          for (int i = 0; i < pLine.palletCount; i++) {
            baseCargoItems.add(CargoItem(
              itemId: 'PLT-$itemCounter',
              length: pL,
              width: pW,
              height: pH,
              weight: pWt,
              isStackable: pLine.isStackable,
              rotate: true,
              packageType: pLine.palletType,
              description: 'بالتة #$itemCounter (${pLine.palletType})${pLine.isStackable ? "" : " [Floor Only]"}',
            ));
            itemCounter++;
          }
        }
      } else if (hasSinglePallet) {
        final double pWt = po.totalGrossWeightKg > 0 ? (po.totalGrossWeightKg / po.palletCount) : 137.5;
        for (int i = 0; i < po.palletCount; i++) {
          baseCargoItems.add(CargoItem(
            itemId: 'PLT-$itemCounter',
            length: po.palletLengthCm,
            width: po.palletWidthCm,
            height: po.palletHeightCm,
            weight: pWt,
            isStackable: po.isPalletStackable,
            rotate: true,
            packageType: po.palletType,
            description: 'بالتة #$itemCounter (${po.palletType})${po.isPalletStackable ? "" : " [Floor Only]"}',
          ));
          itemCounter++;
        }
      } else if (po.packingListItems.isNotEmpty) {
        for (final pl in po.packingListItems) {
          for (int q = 0; q < pl.qtyPkg.toInt(); q++) {
            double lCm = pl.lengthCm;
            double wCm = pl.widthCm;
            double hCm = pl.heightCm;
            if (pl.unit == 'mm') {
              lCm /= 10;
              wCm /= 10;
              hCm /= 10;
            } else if (pl.unit == 'm') {
              lCm *= 100;
              wCm *= 100;
              hCm *= 100;
            }

            baseCargoItems.add(CargoItem(
              itemId: '$itemCounter',
              length: lCm > 0 ? lCm : 100.0,
              width: wCm > 0 ? wCm : 80.0,
              height: hCm > 0 ? hCm : 60.0,
              weight: pl.grossWeightUnitKg > 0 ? pl.grossWeightUnitKg : (pl.totalGrossWeightKg / (pl.qtyPkg > 0 ? pl.qtyPkg : 1)),
              rotate: true,
              isStackable: pl.isStackable,
              packageType: pl.packageType,
            ));
            itemCounter++;
          }
        }
      }
    }

    if (baseCargoItems.isEmpty && totalCbm > 0) {
      final double targetCbm = totalCbm;
      final double targetWeight = totalWeight > 0 ? totalWeight : 1000.0;
      final int numPallets = (targetCbm / 2.0).ceil().clamp(1, 50);
      final double perPalletCbm = targetCbm / numPallets;
      final double perPalletWeight = targetWeight / numPallets;

      double palletHeightCm = (perPalletCbm * 1000000.0) / 12000.0;
      if (palletHeightCm > 260) palletHeightCm = 260;

      for (int i = 0; i < numPallets; i++) {
        baseCargoItems.add(CargoItem(
          itemId: 'PLT-$itemCounter',
          length: 120,
          width: 100,
          height: palletHeightCm.clamp(30.0, 260.0),
          weight: perPalletWeight,
          rotate: true,
          isStackable: true,
          packageType: 'Pallet',
        ));
        itemCounter++;
      }
    }

    if (baseCargoItems.isEmpty) {
      baseCargoItems.add(CargoItem(
        itemId: '1',
        length: 120,
        width: 80,
        height: 100,
        weight: totalWeight > 0 ? totalWeight : 500.0,
        rotate: true,
        isStackable: true,
      ));
    }

    // Default active view mode: null = Actual/Mixed, true = All Stackable, false = All Non-Stackable
    bool? activeStackingMode = baseCargoItems.any((i) => !i.isStackable) ? null : true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            // Compute plan dynamically based on the selected mode
            final plan = ContainerRequirementEngine.planShipment(
              baseCargoItems,
              forceStackable: activeStackingMode,
            );

            // Compute summary metrics for active plan
            final totalPkgs = baseCargoItems.length;
            final stackableInActive = activeStackingMode == true
                ? totalPkgs
                : (activeStackingMode == false ? 0 : baseCargoItems.where((c) => c.isStackable).length);
            final nonStackableInActive = totalPkgs - stackableInActive;

            final totalPlanWeight = plan.fold(0.0, (s, p) => s + p.totalWeight);
            final totalPlanVolume = plan.fold(0.0, (s, p) => s + p.totalVolume);

            // Determine container fleet text (e.g. 2 x 40HC or 2 x 40HC + 1 x 20GP)
            final Map<String, int> containerCounts = {};
            for (final p in plan) {
              if (p.containerCode != 'FAILED') {
                containerCounts[p.containerCode] = (containerCounts[p.containerCode] ?? 0) + 1;
              }
            }
            final fleetSummaryText = containerCounts.entries.map((e) => '${e.value} x ${e.key}').join(' + ');

            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.view_in_ar, color: AppTheme.cobalt, size: 24),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'مخطط ومحاكاة رص الحاويات (Visual 2.5D/3D Container Load Planner)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.charcoal),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.cobalt.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.cobalt),
                    ),
                    child: Text(
                      'الأسطول المطلوب: $fleetSummaryText (${plan.length} حاوية)',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.cobalt),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 980,
                height: 640,
                child: Column(
                  children: [
                    // 1. Scenario / Stacking Mode Switcher (All 3 required states)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '🔄 اختر سيناريو الرص للمعاينة:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal),
                          ),
                          Row(
                            children: [
                              ChoiceChip(
                                label: const Text('📦 1. بضائع تقبل الرص (All Stackable)'),
                                selected: activeStackingMode == true,
                                selectedColor: AppTheme.emerald,
                                labelStyle: TextStyle(
                                  color: activeStackingMode == true ? Colors.white : AppTheme.charcoal,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                                onSelected: (val) {
                                  if (val) setDialogState(() => activeStackingMode = true);
                                },
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text('🚫 2. بضائع لا تقبل الرص (All Non-Stackable)'),
                                selected: activeStackingMode == false,
                                selectedColor: Colors.orange.shade800,
                                labelStyle: TextStyle(
                                  color: activeStackingMode == false ? Colors.white : AppTheme.charcoal,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                                onSelected: (val) {
                                  if (val) setDialogState(() => activeStackingMode = false);
                                },
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text('🔀 3. مزيج يقبل ولا يقبل الرص (Mixed Stacking)'),
                                selected: activeStackingMode == null,
                                selectedColor: AppTheme.cobalt,
                                labelStyle: TextStyle(
                                  color: activeStackingMode == null ? Colors.white : AppTheme.charcoal,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                                onSelected: (val) {
                                  if (val) setDialogState(() => activeStackingMode = null);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 2. Metrics Strip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.charcoal.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              _buildLoadMetricPill('📦 إجمالي الطرود', '$totalPkgs طرد', AppTheme.cobalt),
                              const SizedBox(width: 8),
                              _buildLoadMetricPill('⚖️ إجمالي الوزن', '${totalPlanWeight.toStringAsFixed(0)} kg', AppTheme.charcoal),
                              const SizedBox(width: 8),
                              _buildLoadMetricPill('📐 إجمالي الحجم', '${totalPlanVolume.toStringAsFixed(3)} m³', Colors.orange.shade900),
                            ],
                          ),
                          Row(
                            children: [
                              _buildLoadMetricPill('✅ يقبل الرص', '$stackableInActive طرد', Colors.green.shade800),
                              const SizedBox(width: 8),
                              _buildLoadMetricPill('🚫 لا يقبل الرص', '$nonStackableInActive طرد', Colors.red.shade800),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 3. Table summary of container loads
                    Table(
                      border: TableBorder.all(color: Colors.grey.shade300),
                      columnWidths: const {
                        0: FlexColumnWidth(1.2),
                        1: FlexColumnWidth(1.8),
                        2: FlexColumnWidth(1.2),
                        3: FlexColumnWidth(1.2),
                        4: FlexColumnWidth(2.4),
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(color: AppTheme.charcoal.withOpacity(0.08)),
                          children: const [
                            Padding(padding: EdgeInsets.all(6.0), child: Text('الحاوية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            Padding(padding: EdgeInsets.all(6.0), child: Text('الأصناف والطرود', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            Padding(padding: EdgeInsets.all(6.0), child: Text('الوزن المحمّل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            Padding(padding: EdgeInsets.all(6.0), child: Text('استغلال المساحة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            Padding(padding: EdgeInsets.all(6.0), child: Text('توزيع الرص والسلامة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          ],
                        ),
                        ...plan.asMap().entries.map((entry) {
                          final idx = entry.key + 1;
                          final res = entry.value;
                          final placedIds = res.placedItems.map((p) => p.item.itemId).join(', ');

                          String statusText = '';
                          if (res.containerCode == 'FAILED') {
                            statusText = 'فشل التحميل (طرود كبيرة الحجم/الوزن)';
                          } else {
                            final nonStackInThis = res.placedItems.where((p) => !p.item.isStackable).length;
                            if (nonStackInThis > 0) {
                              statusText = 'تحتوي على $nonStackInThis طرد غير قابل للرص مثبت على الأرضية';
                            } else {
                              statusText = 'رص متعدد الطبقات متوافق (${(res.totalVolume / res.spec.internalVolumeCbm * 100).toStringAsFixed(1)}%)';
                            }
                          }

                          final double spaceUtil = res.spec.internalVolumeCbm > 0 ? (res.totalVolume / res.spec.internalVolumeCbm) * 100 : 0.0;

                          return TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(
                                  res.containerCode == 'FAILED' ? 'فشل الرص' : '$idx: ${res.spec.code}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt, fontSize: 11),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(placedIds.isEmpty ? '-' : placedIds, style: const TextStyle(fontSize: 11)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(res.containerCode == 'FAILED' ? '-' : '${res.totalWeight.toStringAsFixed(0)} kg', style: const TextStyle(fontSize: 11)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text('${spaceUtil.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: statusText.contains('فشل')
                                        ? Colors.red.shade800
                                        : (statusText.contains('غير قابل') ? Colors.brown.shade800 : Colors.green.shade800),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 4. Tab view or list for visual container layout drawings
                    Expanded(
                      child: ListView.builder(
                        itemCount: plan.length,
                        itemBuilder: (ctx, pIdx) {
                          final res = plan[pIdx];
                          if (res.containerCode == 'FAILED') {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade300)),
                              child: Text(
                                'الأصناف التالية تفوق سعة حاويات الشحن: ${res.unplacedItems.map((u) => u.itemId).join(', ')}',
                                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                            );
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'مخطط الحاوية #${pIdx + 1}: ${res.spec.name} (${res.spec.code})',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.cobalt),
                                      ),
                                      Row(
                                        children: [
                                          const Text('🪵 طبالي خشبية أرضية', style: TextStyle(fontSize: 10, color: Colors.brown, fontWeight: FontWeight.bold)),
                                          const SizedBox(width: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                                            child: Text('الأبعاد الداخلية: ${res.spec.internalLength.toStringAsFixed(0)} x ${res.spec.internalWidth.toStringAsFixed(0)} x ${res.spec.internalHeight.toStringAsFixed(0)} cm', style: const TextStyle(fontSize: 10, color: AppTheme.cobalt)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Side View (Left Wall Removed) - High Fidelity Realistic Container
                                  Container(
                                    height: 190,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade900,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: CustomPaint(
                                      painter: ContainerLoadPlanPainter(plan: res, isTopView: false),
                                      child: Container(),
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // Top View (Roof Removed)
                                  Container(
                                    height: 140,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade900,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: CustomPaint(
                                      painter: ContainerLoadPlanPainter(plan: res, isTopView: true),
                                      child: Container(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton.icon(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  label: const Text('إغلاق المخطط'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Widget _buildLoadMetricPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHistoryRegistryTab(ShippingScenariosState state, List poList, List projectsList) {
    return SavedScenariosRegistryTab(
      onEditSession: _loadSessionForEditing,
      onSwitchToEvaluator: () => _tabController.animateTo(0),
    );
  }
}
