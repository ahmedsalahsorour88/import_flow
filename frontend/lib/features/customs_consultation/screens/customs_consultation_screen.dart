import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/change_diff_dialog.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/error_details_dialog.dart';
import '../../../core/widgets/vertical_stage_scaffold.dart';
import '../../currencies/models/currency_model.dart';
import '../../currencies/providers/currencies_provider.dart';
import '../../customs_tariff/models/customs_tariff_model.dart';
import '../../customs_tariff/providers/customs_tariff_provider.dart';
import '../../external_service_providers/providers/partners_provider.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../../projects/providers/projects_provider.dart';
import '../../purchase_orders/models/purchase_order_model.dart';
import '../../purchase_orders/providers/purchase_orders_provider.dart';
import '../models/customs_consultation_model.dart';
import '../providers/customs_consultation_provider.dart';
import 'package:printing/printing.dart';
import '../services/customs_consultation_pdf_service.dart';
import '../services/customs_export_service.dart';
import '../../../core/widgets/row_actions_pill.dart';
import '../../shipping_scenarios/providers/shipping_scenarios_provider.dart';

class CustomsItemCalcRow {
  final String hsCode;
  final String description;
  final double qty;
  final String unit;
  final double foreignPrice;
  final double fobEgp;
  final double freightEgp;
  final double insuranceEgp;
  final double cifEgp;
  final double dutyRate;
  final double baseDutyRate;
  final double dutyAmountEgp;
  final double vatRate;
  final double vatBaseEgp;
  final double vatAmountEgp;
  final double scheduleTaxRate;
  final double scheduleTaxAmountEgp;
  final double developmentFeeRate;
  final double developmentFeeAmountEgp;
  final double customsServiceFeeRate;
  final double customsServiceFeeAmountEgp;
  final double totalTaxesAndDutiesEgp;
  final bool requiresCoo;
  final bool requiresInspection;
  final bool requiresAcid;
  final String? regulatoryAuthority;
  final String? priorApprovalNote;
  final String? countryOfOrigin;
  final String? appliedAgreementName;
  final bool hasExemption;
  final String? exemptionConditionsNote;
  final String? requiredDocument;

  CustomsItemCalcRow({
    required this.hsCode,
    required this.description,
    required this.qty,
    required this.unit,
    required this.foreignPrice,
    required this.fobEgp,
    required this.freightEgp,
    required this.insuranceEgp,
    required this.cifEgp,
    required this.dutyRate,
    required this.baseDutyRate,
    required this.dutyAmountEgp,
    required this.vatRate,
    required this.vatBaseEgp,
    required this.vatAmountEgp,
    required this.scheduleTaxRate,
    required this.scheduleTaxAmountEgp,
    required this.developmentFeeRate,
    required this.developmentFeeAmountEgp,
    required this.customsServiceFeeRate,
    required this.customsServiceFeeAmountEgp,
    required this.totalTaxesAndDutiesEgp,
    required this.requiresCoo,
    required this.requiresInspection,
    required this.requiresAcid,
    this.regulatoryAuthority,
    this.priorApprovalNote,
    this.countryOfOrigin,
    this.appliedAgreementName,
    this.hasExemption = false,
    this.exemptionConditionsNote,
    this.requiredDocument,
  });
}

class CustomsConsultationScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  const CustomsConsultationScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<CustomsConsultationScreen> createState() => _CustomsConsultationScreenState();
}

class _CustomsConsultationScreenState extends ConsumerState<CustomsConsultationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form State
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController(text: 'دراسة المراجعة الجمركية الأولية لخط إنتاج ومعدات الشحنة');
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _estimatedDutiesController = TextEditingController(text: '0.0');

  // Customs Calculator State Controllers
  final TextEditingController _exchangeRateController = TextEditingController(text: '50.0');
  final TextEditingController _freightEgpController = TextEditingController(text: '0.0');
  final TextEditingController _insuranceEgpController = TextEditingController(text: '0.0');
  String _customsCurrency = 'USD';
  bool _isCustomsCalculatorExpanded = true;

  int? _editingConsultationId;
  String? _editingConsultationCode;

  int? _selectedBrokerId;
  String _selectedBrokerName = '';
  String? _brokerContactPerson;
  int? _selectedImportFileId;
  int? _selectedPoId;
  int? _selectedProjectId;

  final List<CustomsChecklistItemModel> _checklist = [];
  final List<CustomsBrokerQuoteItemModel> _brokerQuoteItems = [];
  int? _brokerPriceListId;
  String? _brokerPriceListTitle;
  bool _isBrokerQuoteExpanded = true;
  bool _isLoadingPriceList = false;
  String _brokerExpenseCategoryFilter = 'All';

  // Management Tab State
  int _managementSubTabIndex = 0;
  int? _selectedMgmtBrokerId;
  String _mgmtExpenseSearch = '';
  String _mgmtExpenseCategory = 'All';
  bool _isSaving = false;

  // History Tab Filter State
  String _searchQuery = '';
  String _statusFilter = 'All';
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialIndex);
    _initializeDefaultChecklist();
    Future.microtask(() {
      ref.read(customsConsultationsProvider.notifier).fetchConsultations();
      ref.read(importFilesProvider.notifier).fetchImportFiles();
      ref.read(purchaseOrdersProvider.notifier).fetchPurchaseOrders();
      ref.read(customsTariffProvider.notifier).fetchTariffs();
      ref.read(currenciesProvider.notifier).fetchCurrencies();
      ref.read(shippingScenariosProvider.notifier).fetchSessions();
      ref.read(partnersProvider.notifier).fetchPartners();
      ref.read(projectsProvider.notifier).fetchProjects();
      ref.read(clearanceExpenseTypesProvider.notifier).fetchExpenseTypes();
      ref.read(brokerPriceListsProvider.notifier).fetchPriceLists();
    });
  }

  @override
  void didUpdateWidget(CustomsConsultationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _tabController.animateTo(widget.initialIndex);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    _estimatedDutiesController.dispose();
    _exchangeRateController.dispose();
    _freightEgpController.dispose();
    _insuranceEgpController.dispose();
    super.dispose();
  }

  void _initializeDefaultChecklist() {
    _checklist.clear();
    _checklist.addAll([
      CustomsChecklistItemModel(
        documentType: 'Proforma Invoice (الفاتورة المبدئية)',
        isRequired: true,
        isBlockingShipment: true,
        responsibleParty: 'Supplier / Exporter',
        status: 'Approved',
        remarks: 'الفاتورة المبدئية معتمدة ومطابقة للبند الجمركي.',
      ),
      CustomsChecklistItemModel(
        documentType: 'Packing List (قائمة التعبئة والتغليف)',
        isRequired: true,
        isBlockingShipment: true,
        responsibleParty: 'Supplier / Exporter',
        status: 'Approved',
        remarks: 'محدثة بإجمالي الأوزان الأحجام والطرود.',
      ),
      CustomsChecklistItemModel(
        documentType: 'Certificate of Origin (شهادة المنشأ COO)',
        isRequired: true,
        isBlockingShipment: true,
        responsibleParty: 'Customs Broker',
        status: 'Pending',
        remarks: 'مطلوب توثيق السفارة والغرفة التجارية.',
      ),
      CustomsChecklistItemModel(
        documentType: 'GOEIC Inspection (عرض هيئة الصادرات والواردات)',
        isRequired: true,
        isBlockingShipment: true,
        responsibleParty: 'Customs Broker',
        regulatoryAgency: 'GOEIC (هيئة الرقابة على الصادرات والواردات)',
        status: 'Pending',
        remarks: 'يتطلب فحص ظاهري وعينات المعمل فور الوصول.',
      ),
      CustomsChecklistItemModel(
        documentType: 'NTRA Telecommunications Approval (موافقة جهاز الاتصالات)',
        isRequired: false,
        isBlockingShipment: false,
        responsibleParty: 'Importer Team',
        regulatoryAgency: 'NTRA (الجهاز القومي لتنظيم الاتصالات)',
        status: 'Pending',
        remarks: 'تنطبق في حال وجود وحدات تحكم لاسلكية.',
      ),
    ]);
  }

  void _onImportFileChanged(int? fileId) {
    setState(() {
      _selectedImportFileId = fileId;
      if (fileId != null) {
        final importFiles = ref.read(importFilesProvider).value ?? [];
        final file = importFiles.where((f) => f.importFileId == fileId).firstOrNull;
        if (file != null) {
          final fCode = file.customFileNumber ?? file.importFileCode;
          _titleController.text = '[$fCode] ${file.companyName}';

          // Auto-fetch broker from file
          if (file.brokerId != null) {
            _selectedBrokerId = file.brokerId;
            _selectedBrokerName = file.brokerName ?? '';
            final partners = ref.read(partnersProvider).value ?? [];
            final bPartner = partners.where((p) => p.providerId == file.brokerId).firstOrNull;
            if (bPartner != null) {
              _brokerContactPerson = bPartner.contactPerson;
            }
            _loadBrokerPriceList(file.brokerId!, preserveExisting: true);
          }
          if (file.poIds != null && file.poIds!.isNotEmpty) {
            _selectedPoId = file.poIds!.first;
          }
          if (file.projectIds.isNotEmpty) {
            _selectedProjectId = file.projectIds.first;
          }

          // ── Auto-fetch Currency & Exchange Rate ──────────────────────
          final allPOs = ref.read(purchaseOrdersProvider).purchaseOrders;
          final currencies = ref.read(currenciesProvider).value ?? [];

          final matchingPOs = allPOs.where((p) =>
              (p.importFileId != null && p.importFileId == file.importFileId) ||
              (file.importFileCode.isNotEmpty && p.importFileCode != null && p.importFileCode == file.importFileCode) ||
              (file.poIds != null && p.poId != null && file.poIds!.contains(p.poId))).toList();

          String? detectedCurrency;

          // 1. Try matching POs first (PO currency_id or currency_code)
          for (final po in matchingPOs) {
            if (po.currencyId > 0) {
              final c = currencies.where((c) => c.currencyId == po.currencyId).firstOrNull;
              if (c != null && c.currencyCode.isNotEmpty) {
                detectedCurrency = c.currencyCode;
                break;
              }
            }
            if (po.currencyCode != null && po.currencyCode!.isNotEmpty) {
              detectedCurrency = po.currencyCode;
              break;
            }
          }

          // 2. If not found in POs, try invoicesData
          if (detectedCurrency == null && file.invoicesData.isNotEmpty) {
            final invCur = file.invoicesData.first.currency;
            if (invCur.isNotEmpty) {
              detectedCurrency = invCur;
            }
          }

          if (detectedCurrency != null && detectedCurrency.isNotEmpty) {
            _customsCurrency = detectedCurrency;
            _updateExchangeRateForCurrency(detectedCurrency);
          }
        }
      }
    });

    // Auto-fetch highest freight from linked shipping scenarios
    if (fileId != null) {
      _autoFetchFreightFromScenarios(fileId);
    }

    _syncHsRequirementsToChecklist(silent: true);
  }

  void _onPoChanged(int? poId) {
    setState(() {
      _selectedPoId = poId;
      if (poId != null) {
        final allPOs = ref.read(purchaseOrdersProvider).purchaseOrders;
        final po = allPOs.where((p) => p.poId == poId).firstOrNull;
        if (po != null) {
          final currencies = ref.read(currenciesProvider).value ?? [];
          String? detectedCurrency;
          if (po.currencyId > 0) {
            final c = currencies.where((c) => c.currencyId == po.currencyId).firstOrNull;
            if (c != null && c.currencyCode.isNotEmpty) {
              detectedCurrency = c.currencyCode;
            }
          }
          if (detectedCurrency == null && po.currencyCode != null && po.currencyCode!.isNotEmpty) {
            detectedCurrency = po.currencyCode;
          }
          if (detectedCurrency != null && detectedCurrency.isNotEmpty) {
            _customsCurrency = detectedCurrency;
            _updateExchangeRateForCurrency(detectedCurrency);
          }
        }
      }
    });
    _syncHsRequirementsToChecklist(silent: true);
  }

  void _updateExchangeRateForCurrency(String currencyCode) {
    final currencies = ref.read(currenciesProvider).value ?? [];
    final matchedCurrency = currencies
        .where((c) => c.currencyCode.toUpperCase() == currencyCode.toUpperCase())
        .firstOrNull;
    if (matchedCurrency != null) {
      final rate = matchedCurrency.latestCustomsRate ??
          matchedCurrency.latestCommercialRate;
      if (rate != null && rate > 0) {
        _exchangeRateController.text = rate.toStringAsFixed(4);
      }
    }
  }

  /// Finds the highest totalQuotationAmount across all shipping scenario items
  /// linked to [fileId], converts it to EGP using the customs exchange rate,
  /// and auto-populates the freight field.
  void _autoFetchFreightFromScenarios(int fileId) {
    final allSessions = ref.read(shippingScenariosProvider).sessions;
    final linkedSessions =
        allSessions.where((s) => s.importFileId == fileId).toList();
    if (linkedSessions.isEmpty) return;

    double highestQuotation = 0.0;
    String highestCurrency = 'USD';
    for (final session in linkedSessions) {
      for (final item in session.items) {
        if (item.totalQuotationAmount > highestQuotation) {
          highestQuotation = item.totalQuotationAmount;
          highestCurrency = item.quotationCurrency;
        }
      }
    }
    if (highestQuotation <= 0) return;

    // Convert to EGP using the customs exchange rate
    final currencies = ref.read(currenciesProvider).value ?? [];
    final matchedCurrency =
        currencies.where((c) => c.currencyCode == highestCurrency).firstOrNull;
    final rate = matchedCurrency?.latestCustomsRate ??
        (double.tryParse(_exchangeRateController.text) ?? 50.0);
    final freightEgp = highestQuotation * rate;

    setState(() {
      _freightEgpController.text = freightEgp.toStringAsFixed(2);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🚢 تم استدعاء النولون تلقائياً من سيناريوهات الشحن: '
            '${highestQuotation.toStringAsFixed(2)} $highestCurrency × '
            '${rate.toStringAsFixed(4)} = ${freightEgp.toStringAsFixed(2)} EGP',
          ),
          backgroundColor: AppTheme.cobalt,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _syncHsRequirementsToChecklist({bool silent = false}) {
    final calcLines = _calculateCustomsLines();
    if (calcLines.isEmpty) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '⚠️ لم يتم العثور على بنود أوامر شراء مرتبطة بهذا الملف لاحتساب شروطها'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // ── Consolidate: group all HS Codes by document type ────────────────
    // One checklist item per document type, listing all related HS Codes inside.
    final acidHsCodes =
        calcLines.where((l) => l.requiresAcid).map((l) => l.hsCode).toList();
    final cooHsCodes =
        calcLines.where((l) => l.requiresCoo).map((l) => l.hsCode).toList();
    final goeicHsCodes =
        calcLines.where((l) => l.requiresInspection).map((l) => l.hsCode).toList();

    // Group per regulatory authority
    final Map<String, List<String>> authHsMap = {};
    for (final line in calcLines) {
      if (line.regulatoryAuthority != null &&
          line.regulatoryAuthority!.trim().isNotEmpty) {
        authHsMap
            .putIfAbsent(line.regulatoryAuthority!, () => [])
            .add(line.hsCode);
      }
    }

    int addedCount = 0;

    // 1. ACID — one consolidated item for the entire shipment
    if (acidHsCodes.isNotEmpty) {
      const docName = 'قيد رقم ACID المسبق للشحنة الكاملة (Nafeza / CargoX)';
      final hasExisting = _checklist.any((c) => c.documentType == docName);
      if (!hasExisting) {
        _checklist.add(CustomsChecklistItemModel(
          documentType: docName,
          hsCode: acidHsCodes.join(' | '),
          isRequired: true,
          isBlockingShipment: true,
          responsibleParty: 'Importer Team',
          regulatoryAgency: 'Nafeza / CargoX',
          status: 'Approved',
          remarks:
              'يشمل بنود: ${acidHsCodes.join(" ، ")} — رقم القيد الجمركي المبدئي إلزامي لإصدار بوليصة الشحن.',
        ));
        addedCount++;
      }
    }

    // 2. COO — one consolidated item for the entire shipment
    if (cooHsCodes.isNotEmpty) {
      const docName =
          'شهادة المنشأ الموثقة للشحنة الكاملة (Certificate of Origin — COO)';
      final hasExisting = _checklist.any((c) => c.documentType == docName);
      if (!hasExisting) {
        _checklist.add(CustomsChecklistItemModel(
          documentType: docName,
          hsCode: cooHsCodes.join(' | '),
          isRequired: true,
          isBlockingShipment: true,
          responsibleParty: 'Supplier / Exporter',
          regulatoryAgency: 'Chamber of Commerce / Embassy',
          status: 'Pending',
          remarks:
              'يشمل بنود: ${cooHsCodes.join(" ، ")} — شهادة منشأ واحدة لكامل الشحنة، تصدر من الغرفة التجارية وتُوثق بالسفارة المصرية.',
        ));
        addedCount++;
      }
    }

    // 3. GOEIC — one consolidated item for the entire shipment
    if (goeicHsCodes.isNotEmpty) {
      const docName =
          'عرض وفحص هيئة الرقابة على الصادرات والواردات (GOEIC) للشحنة الكاملة';
      final hasExisting = _checklist.any((c) => c.documentType == docName);
      if (!hasExisting) {
        _checklist.add(CustomsChecklistItemModel(
          documentType: docName,
          hsCode: goeicHsCodes.join(' | '),
          isRequired: true,
          isBlockingShipment: true,
          responsibleParty: 'Customs Broker',
          regulatoryAgency: 'GOEIC (هيئة الصادرات والواردات)',
          status: 'Pending',
          remarks:
              'يشمل بنود: ${goeicHsCodes.join(" ، ")} — فحص ظاهري وسحب عينات معمل لكامل الشحنة.',
        ));
        addedCount++;
      }
    }

    // 4. Per regulatory authority — one consolidated item per authority
    for (final entry in authHsMap.entries) {
      final authority = entry.key;
      final hsList = entry.value;
      final docName = 'موافقة $authority الفنية المسبقة';
      final hasExisting = _checklist.any((c) => c.documentType == docName);
      if (!hasExisting) {
        final priorNote = calcLines
            .where((l) => l.regulatoryAuthority == authority)
            .map((l) => l.priorApprovalNote)
            .where((n) => n != null)
            .firstOrNull;
        _checklist.add(CustomsChecklistItemModel(
          documentType: docName,
          hsCode: hsList.join(' | '),
          isRequired: true,
          isBlockingShipment: true,
          responsibleParty: 'Importer Team',
          regulatoryAgency: authority,
          status: 'Pending',
          remarks:
              'يشمل بنود: ${hsList.join(" ، ")} — ${priorNote ?? "يتطلب موافقة فنية مسبقة واستخراج تصريح الإفراج الجمركي."}',
        ));
        addedCount++;
      }
    }

    // Recalculate estimated duties and update field
    final grandTotal =
        calcLines.fold(0.0, (s, l) => s + l.totalTaxesAndDutiesEgp);
    _estimatedDutiesController.text = grandTotal.toStringAsFixed(2);

    setState(() {});

    if (!silent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ تمت مزامنة اشتراطات ${calcLines.length} بند HS Code — '
            'تم إضافة $addedCount مستند موحد لقائمة فحص الشحنة بنجاح!',
          ),
          backgroundColor: AppTheme.emerald,
        ),
      );
    }
  }

  List<CustomsItemCalcRow> _calculateCustomsLines() {
    final allPOs = ref.watch(purchaseOrdersProvider).purchaseOrders;
    final tariffsList = ref.watch(customsTariffProvider).value ?? [];

    List<PurchaseOrderModel> matchingPOs = [];
    if (_selectedImportFileId != null) {
      final importFiles = ref.watch(importFilesProvider).value ?? [];
      final file = importFiles.where((f) => f.importFileId == _selectedImportFileId).firstOrNull;
      if (file != null) {
        matchingPOs = allPOs.where((p) =>
            (p.importFileId != null && p.importFileId == file.importFileId) ||
            (file.importFileCode.isNotEmpty && p.importFileCode != null && p.importFileCode == file.importFileCode) ||
            (file.poIds != null && p.poId != null && file.poIds!.contains(p.poId))).toList();
      }
    } else if (_selectedPoId != null) {
      matchingPOs = allPOs.where((p) => p.poId == _selectedPoId).toList();
    }

    final double exchangeRate = double.tryParse(_exchangeRateController.text.trim()) ?? 50.0;
    final double totalFreightEgp = double.tryParse(_freightEgpController.text.trim()) ?? 0.0;
    final double totalInsuranceEgp = double.tryParse(_insuranceEgpController.text.trim()) ?? 0.0;

    // Collect all line items paired with their parent PO
    final List<Map<String, dynamic>> flatLineEntries = [];
    for (final po in matchingPOs) {
      for (final item in po.items) {
        flatLineEntries.add({
          'item': item,
          'po': po,
        });
      }
    }

    if (flatLineEntries.isEmpty) {
      return [];
    }

    // Compute total FOB in EGP
    double totalFobEgp = 0.0;
    for (final entry in flatLineEntries) {
      final l = entry['item'] as POLineItemModel;
      totalFobEgp += (l.totalPrice * exchangeRate);
    }

    // Known Agreement Origin Sets
    const euCountries = {
      'DE', 'FR', 'IT', 'ES', 'NL', 'BE', 'AT', 'PL', 'SE', 'DK',
      'FI', 'IE', 'PT', 'GR', 'CZ', 'HU', 'RO', 'BG', 'SK', 'HR',
      'SI', 'LT', 'LV', 'EE', 'CY', 'MT', 'LU'
    };
    const mercosurCountries = {'BR', 'AR', 'UY', 'PY'};
    const gaftaCountries = {
      'SA', 'AE', 'JO', 'KW', 'OM', 'QA', 'BH', 'LB', 'IQ', 'SY',
      'YE', 'SD', 'LY', 'TN', 'DZ', 'MA', 'PS', 'EG'
    };

    final List<CustomsItemCalcRow> result = [];
    for (final entry in flatLineEntries) {
      final POLineItemModel l = entry['item'] as POLineItemModel;
      final PurchaseOrderModel po = entry['po'] as PurchaseOrderModel;
      final hs = (l.hsCode != null && l.hsCode!.trim().isNotEmpty) ? l.hsCode!.trim() : 'UNASSIGNED';
      
      // Match tariff
      CustomsTariffModel? matchedTariff;
      if (l.tariffId != null) {
        matchedTariff = tariffsList.where((t) => t.tariffId == l.tariffId).firstOrNull;
      }
      if (matchedTariff == null && hs != 'UNASSIGNED') {
        matchedTariff = tariffsList.where((t) => t.hsCode.replaceAll('.', '').trim() == hs.replaceAll('.', '').trim()).firstOrNull;
      }

      // Country of origin resolution
      final String rawOrigin = (l.countryOfOrigin != null && l.countryOfOrigin!.trim().isNotEmpty)
          ? l.countryOfOrigin!.trim()
          : (po.countryOfOrigin != null && po.countryOfOrigin!.trim().isNotEmpty ? po.countryOfOrigin!.trim() : '');

      String originCode = '';
      if (rawOrigin.isNotEmpty) {
        if (rawOrigin.contains(' - ')) {
          originCode = rawOrigin.split(' - ').first.trim().toUpperCase();
        } else if (rawOrigin.length >= 2) {
          originCode = rawOrigin.substring(0, 2).toUpperCase();
        } else {
          originCode = rawOrigin.toUpperCase();
        }
      }

      final double baseDutyRate = matchedTariff?.customsDutyRate ?? (l.dutyRate ?? 5.0);
      double effectiveDutyRate = baseDutyRate;
      bool hasExemption = false;
      String? appliedAgreementName;
      String? requiredDocument;
      String? exemptionConditionsNote;

      if (originCode.isNotEmpty) {
        if (euCountries.contains(originCode)) {
          hasExemption = true;
          appliedAgreementName = 'اتفاقية الشراكة المصرية الأوروبية (EUR.1)';
          requiredDocument = 'شهادة حركة البضائع EUR.1 أصلية أو إعلان الفاتورة للمصدر المعتمد';
          effectiveDutyRate = 0.0;
          exemptionConditionsNote = 'إعفاء جمركي كامل لضريبة الوارد (0% بدلاً من $baseDutyRate%) بموجب اتفاقية الشراكة المصرية الأوروبية.';
        } else if (mercosurCountries.contains(originCode)) {
          hasExemption = true;
          appliedAgreementName = 'اتفاقية التجارة الحرة مع دول الميركسور (Mercosur)';
          requiredDocument = 'شهادة منشأ الميركسور الأصلية المستوفاة لنموذج التصديق وقواعد المنشأ';
          effectiveDutyRate = 0.0;
          exemptionConditionsNote = 'إعفاء جمركي كامل لضريبة الوارد (0% بدلاً من $baseDutyRate%) بموجب اتفاقية التجارة الحرة مع تجمع الميركسور.';
        } else if (gaftaCountries.contains(originCode)) {
          hasExemption = true;
          appliedAgreementName = 'منطقة التجارة الحرة العربية الكبرى (GAFTA)';
          requiredDocument = 'شهادة منشأ عربية موحدة معتمدة من الغرفة التجارية والجمارك';
          effectiveDutyRate = 0.0;
          exemptionConditionsNote = 'إعفاء جمركي كامل لضريبة الوارد (0% بدلاً من $baseDutyRate%) بموجب اتفاقية تيسير وتنمية التبادل التجاري بين الدول العربية.';
        } else if (originCode == 'TR') {
          hasExemption = true;
          appliedAgreementName = 'اتفاقية التجارة الحرة مع تركيا (Turkey FTA)';
          requiredDocument = 'شهادة حركة البضائع EUR.1 التركية الرسمية';
          effectiveDutyRate = 0.0;
          exemptionConditionsNote = 'إعفاء جمركي كامل للمنتجات الصناعية (0% بدلاً من $baseDutyRate%) بموجب اتفاقية التجارة الحرة بين مصر وتركيا.';
        } else if (originCode == 'GB' || originCode == 'UK') {
          hasExemption = true;
          appliedAgreementName = 'اتفاقية المشاركة المصرية البريطانية (UK FTA)';
          requiredDocument = 'إعلان منشأ المملكة المتحدة على الفاتورة أو شهادة EUR.1';
          effectiveDutyRate = 0.0;
          exemptionConditionsNote = 'إعفاء جمركي كامل (0% بدلاً من $baseDutyRate%) بموجب اتفاقية المشاركة المصرية البريطانية.';
        }
      }

      final double vatRate = matchedTariff?.vatRate ?? (l.vatRate ?? 14.0);
      final double scheduleTaxRate = matchedTariff?.scheduleTaxRate ?? 0.0;
      final double devRate = matchedTariff?.developmentFeeRate ?? 0.0;
      final double svcRate = matchedTariff?.customsServiceFeeRate ?? 1.0;

      final double fobEgp = l.totalPrice * exchangeRate;
      final double freightShare = totalFobEgp > 0 ? (fobEgp / totalFobEgp * totalFreightEgp) : 0.0;
      final double insuranceShare = totalFobEgp > 0 ? (fobEgp / totalFobEgp * totalInsuranceEgp) : 0.0;
      final double cifEgp = fobEgp + freightShare + insuranceShare;

      final double dutyAmountEgp = cifEgp * (effectiveDutyRate / 100.0);
      final double vatBaseEgp = cifEgp + dutyAmountEgp;
      final double vatAmountEgp = vatBaseEgp * (vatRate / 100.0);
      final double scheduleTaxAmountEgp = cifEgp * (scheduleTaxRate / 100.0);
      final double devFeeAmountEgp = cifEgp * (devRate / 100.0);
      final double svcAmountEgp = cifEgp * (svcRate / 100.0);

      final double totalLineTaxes = dutyAmountEgp + vatAmountEgp + scheduleTaxAmountEgp + devFeeAmountEgp + svcAmountEgp;

      result.add(CustomsItemCalcRow(
        hsCode: hs,
        description: l.descriptionAr.isNotEmpty ? l.descriptionAr : (matchedTariff?.hsDescription ?? 'صنف مستورد'),
        qty: l.quantity,
        unit: l.unitOfMeasure,
        foreignPrice: l.totalPrice,
        fobEgp: fobEgp,
        freightEgp: freightShare,
        insuranceEgp: insuranceShare,
        cifEgp: cifEgp,
        dutyRate: effectiveDutyRate,
        baseDutyRate: baseDutyRate,
        dutyAmountEgp: dutyAmountEgp,
        vatRate: vatRate,
        vatBaseEgp: vatBaseEgp,
        vatAmountEgp: vatAmountEgp,
        scheduleTaxRate: scheduleTaxRate,
        scheduleTaxAmountEgp: scheduleTaxAmountEgp,
        developmentFeeRate: devRate,
        developmentFeeAmountEgp: devFeeAmountEgp,
        customsServiceFeeRate: svcRate,
        customsServiceFeeAmountEgp: svcAmountEgp,
        totalTaxesAndDutiesEgp: totalLineTaxes,
        requiresCoo: matchedTariff?.requiresCoo ?? true,
        requiresInspection: matchedTariff?.requiresInspection ?? false,
        requiresAcid: matchedTariff?.requiresAcid ?? true,
        regulatoryAuthority: matchedTariff?.regulatoryAuthority,
        priorApprovalNote: matchedTariff?.priorApprovalNote,
        countryOfOrigin: rawOrigin.isNotEmpty ? rawOrigin : null,
        appliedAgreementName: appliedAgreementName,
        hasExemption: hasExemption,
        exemptionConditionsNote: exemptionConditionsNote,
        requiredDocument: requiredDocument,
      ));
    }

    return result;
  }

  void _addChecklistItem() {
    showDialog(
      context: context,
      builder: (context) {
        final docController = TextEditingController();
        final hsController = TextEditingController();
        final agencyController = TextEditingController();
        final remarksController = TextEditingController();
        bool isReq = true;
        bool isBlock = true;
        String party = 'Customs Broker';
        String itemStatus = 'Pending';

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('إضافة بند جديد في قائمة الفحص الجمركي (Customs Checklist)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: docController,
                        decoration: const InputDecoration(labelText: 'نوع المستند / الموافقة الجمركية *', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: hsController,
                        decoration: const InputDecoration(labelText: 'بند التعريفة الجمركية المرتبط (HS Code)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      SearchableDropdownField<String>(
                        value: party,
                        labelText: 'الجهة المسؤولة عن المستند',
                        items: const [
                          SearchableDropdownItem(value: 'Customs Broker', label: 'Customs Broker (المستخلص الجمركي)'),
                          SearchableDropdownItem(value: 'Supplier / Exporter', label: 'Supplier / Exporter (المورد الخارجي)'),
                          SearchableDropdownItem(value: 'Importer Team', label: 'Importer Team (فريق الاستيراد)'),
                          SearchableDropdownItem(value: 'Freight Forwarder', label: 'Freight Forwarder (شركة الشحن)'),
                        ],
                        onChanged: (v) => setDialogState(() => party = v!),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: agencyController,
                        decoration: const InputDecoration(labelText: 'الجهة الرقابية / العرض الجمركي (GOEIC, NTRA, Food Safety...)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      SearchableDropdownField<String>(
                        value: itemStatus,
                        labelText: 'حالة المستند المبدئية',
                        items: const [
                          SearchableDropdownItem(value: 'Pending', label: 'Pending (قيد الانتظار)'),
                          SearchableDropdownItem(value: 'Received', label: 'Received (تم الاستلام)'),
                          SearchableDropdownItem(value: 'Verified', label: 'Verified (تم التدقيق)'),
                          SearchableDropdownItem(value: 'Approved', label: 'Approved (معتمد جمركياً)'),
                          SearchableDropdownItem(value: 'Rejected', label: 'Rejected (مرفوض / يتطلب إجراء)'),
                        ],
                        onChanged: (v) => setDialogState(() => itemStatus = v!),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Checkbox(
                            value: isReq,
                            onChanged: (v) => setDialogState(() => isReq = v!),
                          ),
                          const Text('مستند إجباري (Required)'),
                          const Spacer(),
                          Checkbox(
                            value: isBlock,
                            onChanged: (v) => setDialogState(() => isBlock = v!),
                          ),
                          const Text('يعطل الشحنة (Blocking Shipment)'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: remarksController,
                        decoration: const InputDecoration(labelText: 'ملاحظات المستخلص / المتطلبات', border: OutlineInputBorder()),
                        maxLines: 2,
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
                    if (docController.text.trim().isEmpty) return;
                    setState(() {
                      _checklist.add(CustomsChecklistItemModel(
                        documentType: docController.text.trim(),
                        hsCode: hsController.text.trim().isNotEmpty ? hsController.text.trim() : null,
                        isRequired: isReq,
                        isBlockingShipment: isBlock,
                        responsibleParty: party,
                        status: itemStatus,
                        regulatoryAgency: agencyController.text.trim().isNotEmpty ? agencyController.text.trim() : null,
                        remarks: remarksController.text.trim().isNotEmpty ? remarksController.text.trim() : null,
                      ));
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('إضافة البند', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _loadConsultationForEdit(CustomsConsultationModel session) {
    setState(() {
      _editingConsultationId = session.consultationId;
      _editingConsultationCode = session.consultationCode;
      _titleController.text = session.title;
      _selectedBrokerId = session.brokerId;
      _selectedBrokerName = session.brokerName;
      _brokerContactPerson = session.brokerContactPerson;
      _selectedImportFileId = session.importFileId;
      _selectedPoId = session.poId;
      _selectedProjectId = session.projectId;
      _estimatedDutiesController.text = session.estimatedDutiesEgp.toStringAsFixed(2);
      _notesController.text = session.notes ?? '';
      _checklist.clear();
      _checklist.addAll(session.checklistItems);
      _brokerQuoteItems.clear();
      _brokerQuoteItems.addAll(session.brokerQuoteItems.map((q) => q.copyWith()));
      _brokerPriceListId = session.brokerPriceListId;
      _tabController.animateTo(0);
    });
  }


  Future<void> _loadBrokerPriceList(int brokerId, {bool preserveExisting = false}) async {
    if (preserveExisting && _brokerQuoteItems.isNotEmpty) return;

    setState(() => _isLoadingPriceList = true);
    try {
      final activePl = await ref
          .read(brokerPriceListsProvider.notifier)
          .getActivePriceListForBroker(brokerId);

      if (activePl != null && activePl.items.isNotEmpty) {
        setState(() {
          _brokerPriceListId = activePl.priceListId;
          _brokerPriceListTitle = activePl.title;
          _brokerQuoteItems.clear();
          for (final itm in activePl.items) {
            _brokerQuoteItems.add(CustomsBrokerQuoteItemModel(
              expenseTypeId: itm.expenseTypeId,
              expenseName: itm.expenseName,
              category: itm.category,
              unitType: itm.unitType,
              unitPrice: itm.standardPrice,
              currency: itm.currency,
              qty: 1.0,
              isApplicable: false, // Default to false until enabled
              totalAmount: 0.0,
              notes: itm.notes,
            ));
          }
        });
      } else {
        // Fallback to Master Expense Catalog
        final catalog = ref.read(clearanceExpenseTypesProvider).value ?? [];
        setState(() {
          _brokerPriceListId = null;
          _brokerPriceListTitle = 'قائمة أسعار مخصصة (لم يتم العثور على قائمة معتمدة مسجلة)';
          _brokerQuoteItems.clear();
          for (final exp in catalog) {
            _brokerQuoteItems.add(CustomsBrokerQuoteItemModel(
              expenseTypeId: exp.expenseId,
              expenseName: exp.nameAr,
              category: exp.category,
              unitType: exp.defaultUnit,
              unitPrice: 0.0, // defaults to 0.0 as requested
              currency: exp.defaultCurrency,
              qty: 1.0,
              isApplicable: false,
              totalAmount: 0.0,
            ));
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading broker price list: $e');
    } finally {
      if (mounted) setState(() => _isLoadingPriceList = false);
    }
  }

  void _updateBrokerQuoteItem(int index, CustomsBrokerQuoteItemModel updated) {
    setState(() {
      final lineTotal = updated.isApplicable ? (updated.unitPrice * updated.qty) : 0.0;
      _brokerQuoteItems[index] = updated.copyWith(totalAmount: lineTotal);
    });
  }

  void _addCustomBrokerExpenseRow() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '0.0');
    final qtyCtrl = TextEditingController(text: '1.0');
    String selectedCategory = 'Other Fees (مصاريف أخرى)';
    String selectedUnit = 'Fixed (مبلغ ثابت)';
    String selectedCurrency = 'EGP';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.add_circle, color: AppTheme.cobalt),
              SizedBox(width: 8),
              Text('إضافة بند مصروف تخليص / نقل مخصص', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'اسم البند / نوع المصروف *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                SearchableDropdownField<String>(
                  value: selectedCategory,
                  labelText: 'التصنيف',
                  searchHintText: 'ابحث عن التصنيف...',
                  items: const [
                    SearchableDropdownItem(value: 'Clearance Fees (أتعاب ومصاريف تخليص)', label: 'أتعاب ومصاريف تخليص'),
                    SearchableDropdownItem(value: 'Procedures & Approvals (إجراءات وموافقات وفحص)', label: 'إجراءات وموافقات وفحص'),
                    SearchableDropdownItem(value: 'Inland Transport (نقل بري وشاحنات)', label: 'نقل بري وشاحنات'),
                    SearchableDropdownItem(value: 'Port & Handling (موانئ وتعتيق وتفريغ)', label: 'موانئ وتعتيق وتفريغ'),
                    SearchableDropdownItem(value: 'Other Fees (مصاريف أخرى)', label: 'مصاريف أخرى'),
                  ],
                  onChanged: (v) => setDlgState(() => selectedCategory = v ?? selectedCategory),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'السعر', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SearchableDropdownField<String>(
                        value: selectedCurrency,
                        labelText: 'العملة',
                        searchHintText: 'ابحث عن العملة...',
                        items: const [
                          SearchableDropdownItem(value: 'EGP', label: 'EGP'),
                          SearchableDropdownItem(value: 'USD', label: 'USD'),
                          SearchableDropdownItem(value: 'EUR', label: 'EUR'),
                        ],
                        onChanged: (v) => setDlgState(() => selectedCurrency = v ?? 'EGP'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: qtyCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'الكمية', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald),
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                final qty = double.tryParse(qtyCtrl.text.trim()) ?? 1.0;
                setState(() {
                  _brokerQuoteItems.add(CustomsBrokerQuoteItemModel(
                    expenseName: name,
                    category: selectedCategory,
                    unitType: selectedUnit,
                    unitPrice: price,
                    currency: selectedCurrency,
                    qty: qty,
                    isApplicable: true,
                    totalAmount: price * qty,
                  ));
                });
                Navigator.pop(ctx);
              },
              child: const Text('إضافة البند للعرض', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveConsultation() async {
    final validationErrors = <ValidationIssueItem>[];

    final titleToSave = _titleController.text.trim();
    if (titleToSave.isEmpty) {
      validationErrors.add(ValidationIssueItem(
        fieldName: 'عنوان / موضوع الاستشارة الجمركية',
        issueDescription: 'حقل إلزامي لا يمكن تركه فارغاً.',
        recommendation: 'يرجى كتابة عنوان واضح وموجز لموضوع دراسة الفحص والاستشارة الجمركية.',
        isBlocking: true,
      ));
    }

    if (_selectedBrokerId == null) {
      validationErrors.add(ValidationIssueItem(
        fieldName: 'المستخلص الجمركي المعني (Customs Broker)',
        issueDescription: 'لم يتم تحديد المستخلص الجمركي المسؤول عن دراسة الملف.',
        recommendation: 'يرجى اختيار المستخلص الجمركي من القائمة المنسدلة.',
        isBlocking: true,
      ));
    }

    if (_checklist.isEmpty) {
      validationErrors.add(ValidationIssueItem(
        fieldName: 'قائمة الفحص والمستندات الجمركية',
        issueDescription: 'قائمة فحص المستندات والاشتراطات فارغة تماماً.',
        recommendation: 'يرجى إضافة مستند أو اشتراط واحد على الأقل في قائمة الفحص.',
        isBlocking: true,
      ));
    }

    if (validationErrors.isNotEmpty) {
      await showErrorDetailsDialog(
        context,
        title: '⚠️ تنبيهات واستيفاء بيانات الاستشارة الجمركية',
        error: 'يرجى استكمال البيانات الإلزامية التالية لتتمكن من حفظ دراسة الاستشارة بنجاح.',
        validationIssues: validationErrors,
      );
      return;
    }

    final estimatedDuties = double.tryParse(_estimatedDutiesController.text.trim()) ?? 0.0;
    final totalBrokerFees = _brokerQuoteItems.fold(0.0, (sum, itm) => sum + (itm.isApplicable ? itm.totalAmount : 0.0));

    // Change Diff Confirmation Dialog for Edits
    if (_editingConsultationId != null) {
      final oldConsultation = (ref.read(customsConsultationsProvider).value ?? [])
          .where((c) => c.consultationId == _editingConsultationId)
          .firstOrNull;

      if (oldConsultation != null) {
        final List<FieldChangeItem> changes = [];

        if (FieldChangeItem.isDifferent(oldConsultation.title, titleToSave)) {
          changes.add(FieldChangeItem(
            section: 'البيانات العامة للدراسة',
            fieldName: 'عنوان الاستشارة الجمركية',
            oldValue: oldConsultation.title,
            newValue: titleToSave,
          ));
        }

        if (FieldChangeItem.isDifferent(oldConsultation.brokerName, _selectedBrokerName)) {
          changes.add(FieldChangeItem(
            section: 'المستخلص الجمركي',
            fieldName: 'المستخلص الجمركي المعني',
            oldValue: oldConsultation.brokerName,
            newValue: _selectedBrokerName,
          ));
        }

        if (FieldChangeItem.isDifferent(oldConsultation.estimatedDutiesEgp, estimatedDuties)) {
          changes.add(FieldChangeItem(
            section: 'التقديرات المالية',
            fieldName: 'الرسوم الجمركية والضرائب التقديرية',
            oldValue: '${oldConsultation.estimatedDutiesEgp.toStringAsFixed(2)} EGP',
            newValue: '${estimatedDuties.toStringAsFixed(2)} EGP',
          ));
        }

        if (FieldChangeItem.isDifferent(oldConsultation.importFileId, _selectedImportFileId)) {
          changes.add(FieldChangeItem(
            section: 'الربط التشغيلي',
            fieldName: 'ملف الشحنة المرتبط',
            oldValue: oldConsultation.importFileCode ?? (oldConsultation.importFileId != null ? 'ID: ${oldConsultation.importFileId}' : null),
            newValue: _selectedImportFileId != null ? 'ID: $_selectedImportFileId' : null,
          ));
        }

        if (FieldChangeItem.isDifferent(oldConsultation.checklistItems.length, _checklist.length)) {
          changes.add(FieldChangeItem(
            section: 'قائمة فحص المستندات',
            fieldName: 'إجمالي عدد المستندات والاشتراطات',
            oldValue: '${oldConsultation.checklistItems.length} مستند',
            newValue: '${_checklist.length} مستند',
          ));
        }

        if (changes.isNotEmpty) {
          final confirmed = await showChangeDiffConfirmationDialog(
            context,
            title: 'مراجعة وتأكيد تعديلات الاستشارة الجمركية',
            itemReference: _editingConsultationCode ?? titleToSave,
            changes: changes,
          );
          if (!confirmed) return;
        }
      }
    }

    setState(() => _isSaving = true);
    try {
      final payload = {
        'title': titleToSave,
        'broker_id': _selectedBrokerId,
        'broker_name': _selectedBrokerName,
        'broker_contact_person': _brokerContactPerson,
        if (_selectedImportFileId != null) 'import_file_id': _selectedImportFileId,
        if (_selectedPoId != null) 'po_id': _selectedPoId,
        if (_selectedProjectId != null) 'project_id': _selectedProjectId,
        'estimated_duties_egp': estimatedDuties,
        'total_broker_fees_egp': totalBrokerFees,
        if (_brokerPriceListId != null) 'broker_price_list_id': _brokerPriceListId,
        'notes': _notesController.text.trim(),
        'checklist_items': _checklist.map((item) => item.toJson()).toList(),
        'broker_quote_items': _brokerQuoteItems.map((item) => item.toJson()).toList(),
      };

      if (_editingConsultationId != null) {
        final updated = await ref
            .read(customsConsultationsProvider.notifier)
            .updateConsultation(_editingConsultationId!, payload);
        if (mounted && updated != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '✅ تم تحديث دراسة الاستشارة الجمركية بنجاح! كود: ${updated.consultationCode}'),
              backgroundColor: AppTheme.emerald,
            ),
          );
          setState(() {
            _editingConsultationId = null;
            _editingConsultationCode = null;
          });
          _tabController.animateTo(1);
          // Show post-save checklist status summary
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) _showPostSaveStatusDialog(updated);
          });
        }
      } else {
        final created = await ref
            .read(customsConsultationsProvider.notifier)
            .createConsultation(payload);
        if (mounted && created != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '✅ تم حفظ دراسة الاستشارة الجمركية بنجاح! كود الدراسة: ${created.consultationCode}'),
              backgroundColor: AppTheme.emerald,
            ),
          );
          _tabController.animateTo(1);
          // Show post-save checklist status summary
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) _showPostSaveStatusDialog(created);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        await showErrorDetailsDialog(
          context,
          title: '❌ تعذر حفظ دراسة الاستشارة الجمركية',
          error: e,
          onRetry: () async {
            await _saveConsultation();
          },
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Shows a post-save status dialog summarising each checklist item's state.
  void _showPostSaveStatusDialog(CustomsConsultationModel saved) {
    if (!mounted) return;
    final approved =
        saved.checklistItems.where((i) => i.status == 'Approved').toList();
    final pending =
        saved.checklistItems.where((i) => i.status == 'Pending').toList();
    final blocking = saved.checklistItems
        .where((i) => i.isBlockingShipment && i.status != 'Approved')
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              blocking.isNotEmpty
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_rounded,
              color: blocking.isNotEmpty ? Colors.orange : AppTheme.emerald,
              size: 26,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تقرير حالة مستندات الاستشارة الجمركية',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    saved.consultationCode,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.cobalt,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Metrics
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _buildMetricBadge(
                        '✅ معتمدة', '${approved.length} مستند', Colors.green),
                    _buildMetricBadge(
                        '⏳ قيد الانتظار',
                        '${pending.length} مستند',
                        Colors.orange),
                    _buildMetricBadge(
                        '🚫 عوائق التخليص',
                        '${blocking.length} بند',
                        blocking.isNotEmpty ? Colors.red : Colors.green),
                    _buildMetricBadge(
                        '📊 نسبة الجاهزية',
                        '${saved.readinessPercentage.toStringAsFixed(0)}%',
                        Colors.blue),
                  ],
                ),
                const SizedBox(height: 16),

                if (blocking.isNotEmpty) ...
                  [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🚫 المستندات العائقة للتخليص الجمركي (Blocking Issues):',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                          const SizedBox(height: 8),
                          ...blocking.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  const Icon(Icons.block,
                                      color: Colors.red, size: 14),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.documentType,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12),
                                        ),
                                        if (item.hsCode != null &&
                                            item.hsCode!.isNotEmpty)
                                          Text(
                                            'بنود: ${item.hsCode}',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: AppTheme.cobalt),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildDocItemStatusBadge(item.status),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                if (pending.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '⏳ المستندات قيد الانتظار:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange),
                        ),
                        const SizedBox(height: 8),
                        ...pending.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Icon(Icons.hourglass_empty,
                                    color: Colors.orange.shade700, size: 14),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.documentType,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12),
                                      ),
                                      if (item.hsCode != null &&
                                          item.hsCode!.isNotEmpty)
                                        Text(
                                          'بنود: ${item.hsCode}',
                                          style: TextStyle(
                                              fontSize: 10, color: AppTheme.cobalt),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildDocItemStatusBadge(item.status),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (blocking.isEmpty && pending.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified_rounded,
                            color: Colors.green, size: 32),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🎉 الشحنة جاهزة للتخليص الجمركي!',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                    fontSize: 14),
                              ),
                              Text(
                                'جميع المستندات معتمدة ولا توجد عوائق للتخليص.',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.green),
                              ),
                            ],
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
          TextButton.icon(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(ctx),
            label: const Text('إغلاق والعودة لسجل الدراسات'),
          ),
        ],
      ),
    );
  }

  void _showConsultationDetailsDialog(CustomsConsultationModel session) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.verified_user, color: AppTheme.cobalt),
              const SizedBox(width: 8),
              Expanded(
                child: Text('تفاصيل الاستشارة الجمركية: ${session.consultationCode}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              _buildStatusBadge(session.overallStatus),
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
                        Text('العنوان: ${session.title}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 6),
                        Text('المستخلص الجمركي: ${session.brokerName} ${session.brokerContactPerson != null ? "(${session.brokerContactPerson})" : ""}'),
                        const SizedBox(height: 6),
                        Text('الرسوم الجمركية والضرائب التقديرية: ${session.estimatedDutiesEgp.toStringAsFixed(2)} EGP'),
                        if (session.notes != null && session.notes!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text('ملاحظات: ${session.notes}'),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildMetricBadge('نسبة الجاهزية الجمركية', '${session.readinessPercentage}%', Colors.blue),
                      const SizedBox(width: 8),
                      _buildMetricBadge('إجمالي المستندات', '${session.totalDocumentsCount}', Colors.grey),
                      const SizedBox(width: 8),
                      _buildMetricBadge('المستندات المعتمدة', '${session.approvedDocumentsCount}', Colors.green),
                      const SizedBox(width: 8),
                      _buildMetricBadge('عوائق شحن (Blocking)', '${session.blockingIssuesCount}', session.blockingIssuesCount > 0 ? Colors.red : Colors.green),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (session.brokerQuoteItems.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('💰 تفاصيل عرض أسعار التخليص الجمركي والنقل للمستخلص:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppTheme.cobalt.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text('إجمالي مصاريف المخلص: ${session.totalBrokerFeesEgp.toStringAsFixed(2)} EGP', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Table(
                      border: TableBorder.all(color: Colors.grey.shade300),
                      columnWidths: const {
                        0: FlexColumnWidth(2.8),
                        1: FlexColumnWidth(1.8),
                        2: FlexColumnWidth(1.2),
                        3: FlexColumnWidth(0.8),
                        4: FlexColumnWidth(1.4),
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(color: AppTheme.cobalt.withOpacity(0.08)),
                          children: const [
                            Padding(padding: EdgeInsets.all(8), child: Text('نوع المصروف / الخدمة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Padding(padding: EdgeInsets.all(8), child: Text('التصنيف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Padding(padding: EdgeInsets.all(8), child: Text('سعر البند', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Padding(padding: EdgeInsets.all(8), child: Text('الكمية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Padding(padding: EdgeInsets.all(8), child: Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          ],
                        ),
                        ...session.brokerQuoteItems.where((q) => q.isApplicable).map((quote) {
                          return TableRow(
                            children: [
                              Padding(padding: const EdgeInsets.all(6), child: Text(quote.expenseName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                              Padding(padding: const EdgeInsets.all(6), child: Text(quote.category.split('(').first.trim(), style: const TextStyle(fontSize: 10))),
                              Padding(padding: const EdgeInsets.all(6), child: Text('${quote.unitPrice.toStringAsFixed(2)} ${quote.currency}', style: const TextStyle(fontSize: 11))),
                              Padding(padding: const EdgeInsets.all(6), child: Text('${quote.qty}', style: const TextStyle(fontSize: 11))),
                              Padding(
                                padding: const EdgeInsets.all(6),
                                child: Text('${quote.totalAmount.toStringAsFixed(2)} ${quote.currency}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald, fontSize: 11)),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ],

                  const Text('قائمة فحص المستندات والاشتراطات الجمركية (Checklist):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Table(
                    border: TableBorder.all(color: Colors.grey.shade300),
                    columnWidths: const {
                      0: FlexColumnWidth(2.5),
                      1: FlexColumnWidth(1.2),
                      2: FlexColumnWidth(1.2),
                      3: FlexColumnWidth(2),
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: AppTheme.charcoal.withOpacity(0.08)),
                        children: const [
                          Padding(padding: EdgeInsets.all(8), child: Text('نوع المستند', style: TextStyle(fontWeight: FontWeight.bold))),
                          Padding(padding: EdgeInsets.all(8), child: Text('الجهة المسؤولة', style: TextStyle(fontWeight: FontWeight.bold))),
                          Padding(padding: EdgeInsets.all(8), child: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
                          Padding(padding: EdgeInsets.all(8), child: Text('ملاحظات', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      ),
                      ...session.checklistItems.map((doc) {
                        return TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                children: [
                                  if (doc.isBlockingShipment) const Icon(Icons.block, color: Colors.red, size: 14),
                                  if (doc.isBlockingShipment) const SizedBox(width: 4),
                                  Expanded(child: Text(doc.documentType, style: const TextStyle(fontWeight: FontWeight.w600))),
                                ],
                              ),
                            ),
                            Padding(padding: const EdgeInsets.all(8), child: Text(doc.responsibleParty)),
                            Padding(padding: const EdgeInsets.all(8), child: _buildDocItemStatusBadge(doc.status)),
                            Padding(padding: const EdgeInsets.all(8), child: Text(doc.remarks ?? '-')),
                          ],
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.charcoal),
              onPressed: () async {
                await Printing.layoutPdf(
                  onLayout: (format) => CustomsConsultationPdfService.generateConsultationPdf(session),
                  name: 'Customs_Consultation_${session.consultationCode}',
                );
              },
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 14),
              label: const Text('📄 طباعة / حفظ PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald),
              onPressed: () async {
                final nafezaRes = CustomsExportService.computeNafezaFeeBreakdown(
                  totalDutyEgp: session.estimatedDutiesEgp * 0.45,
                  totalVatEgp: session.estimatedDutiesEgp * 0.45,
                  totalServiceFeeEgp: session.estimatedDutiesEgp * 0.10,
                  totalScheduleTaxEgp: 0.0,
                );
                try {
                  final saved = await CustomsExportService.exportCustomsStudyToExcel(
                    context: context,
                    title: session.title,
                    importFileCode: session.importFileCode,
                    brokerName: session.brokerName,
                    currency: 'EGP',
                    exchangeRate: 1.0,
                    totalFreightEgp: 0.0,
                    totalInsuranceEgp: 0.0,
                    calcLines: [],
                    nafezaResult: nafezaRes,
                    brokerQuoteItems: session.brokerQuoteItems,
                  );
                  if (saved != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('✅ تم تصدير دراسة الاستشارة بنجاح: $saved'), backgroundColor: AppTheme.emerald),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ خطأ: $e'), backgroundColor: Colors.red));
                  }
                }
              },
              icon: const Icon(Icons.table_chart, color: Colors.white, size: 14),
              label: const Text('📊 تصدير EXCEL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final consultationsState = ref.watch(customsConsultationsProvider);
    final partnersState = ref.watch(partnersProvider);
    final partnersList = partnersState.value ?? [];
    final brokersList = partnersList.where((p) => p.partnerType.contains('Customs') || p.partnerType.contains('Broker')).toList();
    final projectsList = ref.watch(projectsProvider).value ?? [];
    final poList = ref.watch(purchaseOrdersProvider).purchaseOrders;
    final List<CurrencyModel> currenciesList = ref.watch(currenciesProvider).value ?? [];

    // Live Checklist Statistics
    final totalDocs = _checklist.length;
    final approvedDocs = _checklist.where((i) => i.status == 'Approved').length;
    final blockingCount = _checklist.where((i) => i.isBlockingShipment && i.status != 'Approved').length;
    final liveReadinessPct = totalDocs > 0 ? ((approvedDocs / totalDocs) * 100).toInt() : 0;

    // Live Customs Calculations
    final calcLines = _calculateCustomsLines();
    final double totalFobEgp = calcLines.fold(0.0, (s, l) => s + l.fobEgp);
    final double totalCifEgp = calcLines.fold(0.0, (s, l) => s + l.cifEgp);
    final double totalDutyEgp = calcLines.fold(0.0, (s, l) => s + l.dutyAmountEgp);
    final double totalVatEgp = calcLines.fold(0.0, (s, l) => s + l.vatAmountEgp);
    final double totalTaxesAndDutiesEgp = calcLines.fold(0.0, (s, l) => s + l.totalTaxesAndDutiesEgp);
    final double exchangeRate = double.tryParse(_exchangeRateController.text.trim()) ?? 50.0;
    final double totalFreightEgp = double.tryParse(_freightEgpController.text.trim()) ?? 0.0;
    final double totalInsuranceEgp = double.tryParse(_insuranceEgpController.text.trim()) ?? 0.0;

    final tabs = [
      const VerticalNavTabItem(
        icon: Icons.gavel_outlined,
        titleEn: 'Customs Workspace',
        titleAr: 'مركز الاستشارة والفحص الجمركي',
      ),
      VerticalNavTabItem(
        icon: Icons.history_edu_outlined,
        titleEn: 'Consultations Log',
        titleAr: 'سجل الدراسات المحفوظة',
        badge: (consultationsState.value?.length ?? 0) > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.cobalt.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${consultationsState.value!.length}',
                  style: const TextStyle(color: AppTheme.cobalt, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              )
            : null,
      ),
      const VerticalNavTabItem(
        icon: Icons.price_change_outlined,
        titleEn: 'Broker Price Lists & Catalog',
        titleAr: 'قوائم الأسعار وتكويد المصروفات',
      ),
    ];

    return VerticalStageScaffold(
      stageCode: '',
      titleEn: 'Customs Broker Consultation & Inspection Workspace',
      titleAr: 'مركز الاستشارة والفحص الجمركي',
      headerIcon: Icons.gavel_outlined,
      headerColor: AppTheme.cobalt,
      tabs: tabs,
      selectedIndex: _tabController.index,
      onTabSelected: (index) {
        setState(() => _tabController.index = index);
      },
      headerActions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70),
          tooltip: 'تحديث البيانات (Refresh)',
          onPressed: () {
            ref.read(customsConsultationsProvider.notifier).fetchConsultations();
            ref.read(importFilesProvider.notifier).fetchImportFiles();
            ref.read(purchaseOrdersProvider.notifier).fetchPurchaseOrders();
            ref.read(customsTariffProvider.notifier).fetchTariffs();
            ref.read(currenciesProvider.notifier).fetchCurrencies();
            ref.read(shippingScenariosProvider.notifier).fetchSessions();
            ref.read(partnersProvider.notifier).fetchPartners();
            ref.read(projectsProvider.notifier).fetchProjects();
            ref.read(clearanceExpenseTypesProvider.notifier).fetchExpenseTypes();
            ref.read(brokerPriceListsProvider.notifier).fetchPriceLists();
          },
        ),
      ],
      body: IndexedStack(
        index: _tabController.index,
        children: [
          // TAB 1: CUSTOMS CONSULTATION WORKSPACE
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live Metrics Bar
                  Row(
                    children: [
                      _buildMetricBadge('جاهزية الفحص الجمركي', '$liveReadinessPct%', Colors.blue),
                      const SizedBox(width: 12),
                      _buildMetricBadge('عدد البنود والمستندات', '${_checklist.length}', Colors.grey),
                      const SizedBox(width: 12),
                      _buildMetricBadge(
                        'عوائق التخليص (Blocking)',
                        '$blockingCount',
                        blockingCount > 0 ? Colors.red : Colors.green,
                        onTap: _showBlockingIssuesDialog,
                      ),
                      const Spacer(),
                      // 1. Live Refresh
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.charcoal,
                          side: BorderSide(color: Colors.grey.shade400),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onPressed: () {
                          ref.read(customsConsultationsProvider.notifier).fetchConsultations();
                          ref.read(importFilesProvider.notifier).fetchImportFiles();
                          ref.read(purchaseOrdersProvider.notifier).fetchPurchaseOrders();
                          ref.read(customsTariffProvider.notifier).fetchTariffs();
                          ref.read(currenciesProvider.notifier).fetchCurrencies();
                          ref.read(shippingScenariosProvider.notifier).fetchSessions();
                          ref.read(partnersProvider.notifier).fetchPartners();
                          ref.read(projectsProvider.notifier).fetchProjects();
                          ref.read(clearanceExpenseTypesProvider.notifier).fetchExpenseTypes();
                          ref.read(brokerPriceListsProvider.notifier).fetchPriceLists();
                        },
                        icon: const Icon(Icons.refresh, size: 16, color: AppTheme.cobalt),
                        label: const Text('إعادة تحميل حية 🔄', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),

                      // 2. Clear Form & Start New
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade800,
                          side: BorderSide(color: Colors.grey.shade400),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onPressed: () {
                          setState(() {
                            _editingConsultationId = null;
                            _editingConsultationCode = null;
                            _titleController.text = 'دراسة المراجعة الجمركية الأولية لخط إنتاج ومعدات الشحنة';
                            _selectedImportFileId = null;
                            _selectedPoId = null;
                            _selectedProjectId = null;
                            _selectedBrokerId = null;
                            _initializeDefaultChecklist();
                          });
                        },
                        icon: const Icon(Icons.cleaning_services_outlined, size: 16, color: Colors.blueGrey),
                        label: const Text('تفريغ وبدء تسجيل جديد 🔄', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),

                      // 3. Save Draft & Continue Later
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEFF6FF),
                          foregroundColor: AppTheme.cobalt,
                          elevation: 0,
                          side: const BorderSide(color: AppTheme.cobalt),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onPressed: _isSaving ? null : _saveConsultation,
                        icon: const Icon(Icons.save_outlined, size: 16, color: AppTheme.cobalt),
                        label: const Text('حفظ مؤقت ومتابعة لاحقة 💾', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),

                      // 4. Final Save / Update
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _editingConsultationId != null ? Colors.orange.shade700 : AppTheme.emerald,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                        onPressed: _isSaving ? null : _saveConsultation,
                        icon: _isSaving
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Icon(_editingConsultationId != null ? Icons.save_as : Icons.save, color: Colors.white),
                        label: Text(
                          _editingConsultationId != null ? 'حفظ تعديلات الاستشارة الجمركية' : 'حفظ دراسة الاستشارة الجمركية ✅',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Active Edit Mode Banner
                  if (_editingConsultationId != null) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade400, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.edit_note_rounded, color: Colors.orange, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'وضع التعديل النشط: أنت الآن تقوم بتعديل دراسة الاستشارة الجمركية رقم ($_editingConsultationCode)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange.shade900),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'قم بتعديل بيانات الفحص والمستندات والرسوم ثم اضغط "حفظ التعديلات" لتحديث الدراسة نفسها، أو "حفظ كنسخة جديدة" لإنشاء دراسة منفصلة.',
                                  style: TextStyle(fontSize: 12, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            icon: const Icon(Icons.save_as_rounded, size: 16),
                            label: const Text('حفظ التعديلات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            onPressed: _isSaving ? null : _saveConsultation,
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue.shade800,
                              side: BorderSide(color: Colors.blue.shade400),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            label: const Text('حفظ كنسخة جديدة', style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              setState(() {
                                _editingConsultationId = null;
                                _editingConsultationCode = null;
                                _titleController.text = '${_titleController.text} (نسخة معدلة)';
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('📋 تم تحويل الجلسة إلى دراسة جديدة منفصلة، اضغط "حفظ دراسة الاستشارة الجمركية" للحفظ'), backgroundColor: Colors.blue),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            tooltip: 'إلغاء التعديل والعودة كدراسة جديدة فارغة',
                            onPressed: () {
                              setState(() {
                                _editingConsultationId = null;
                                _editingConsultationCode = null;
                                _titleController.text = 'دراسة المراجعة الجمركية الأولية لخط إنتاج ومعدات الشحنة';
                                _initializeDefaultChecklist();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Session Setup Header Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('بيانات الجلسة والمستخلص الجمركي المعني (Customs Broker)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
                              if (_editingConsultationCode != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(6)),
                                  child: Text('جاري تعديل الدراسة: $_editingConsultationCode', style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _titleController,
                                  decoration: const InputDecoration(labelText: 'عنوان الاستشارة / موضوع الدراسة *', border: OutlineInputBorder()),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال عنوان الدراسة' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: SearchableDropdownField<int?>(
                                  value: _selectedBrokerId,
                                  labelText: 'المستخلص الجمركي (Customs Broker) *',
                                  searchHintText: 'ابحث عن المستخلص الجمركي...',
                                  items: brokersList
                                      .map((b) => SearchableDropdownItem<int?>(
                                            value: b.providerId,
                                            label: b.partnerName,
                                            subtitle: b.contactPerson,
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      final b = brokersList.firstWhere((element) => element.providerId == val);
                                      setState(() {
                                        _selectedBrokerId = val;
                                        _selectedBrokerName = b.partnerName;
                                        _brokerContactPerson = b.contactPerson;
                                      });
                                    }
                                  },
                                  validator: (v) => v == null ? 'مطلوب تحديد المستخلص' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: SearchableDropdownField<int?>(
                                  value: _selectedImportFileId,
                                  labelText: 'ملف الشحنة الاستيرادية (Import File)',
                                  searchHintText: 'ابحث عن ملف الشحنة...',
                                  items: [
                                    const SearchableDropdownItem<int?>(
                                      value: null,
                                      label: '-- بدون ربط بملف شحنة --',
                                    ),
                                    ...(ref.watch(importFilesProvider).value ?? []).map((f) => SearchableDropdownItem<int?>(
                                          value: f.importFileId,
                                          label: '[${f.importFileCode}] ${f.customFileNumber ?? f.poNumber ?? "File #${f.importFileId}"}',
                                          subtitle: '${f.companyName} | المستخلص: ${f.brokerName ?? "غير محدد"}',
                                        )),
                                  ],
                                  onChanged: _onImportFileChanged,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SearchableDropdownField<int?>(
                                  value: _selectedPoId,
                                  labelText: 'ربط بأمر الشراء (Purchase Order - اختياري)',
                                  searchHintText: 'ابحث عن أمر الشراء...',
                                  items: [
                                    const SearchableDropdownItem<int?>(value: null, label: 'بدون ربط (مستقل)'),
                                    ...poList.map((po) => SearchableDropdownItem<int?>(value: po.poId, label: '${po.poNumber} - ${po.supplierName}')),
                                  ],
                                  onChanged: _onPoChanged,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SearchableDropdownField<int?>(
                                  value: _selectedProjectId,
                                  labelText: 'ربط بالمشروع (Project - اختياري)',
                                  searchHintText: 'ابحث عن المشروع...',
                                  items: [
                                    const SearchableDropdownItem<int?>(value: null, label: 'بدون ربط مشروع'),
                                    ...projectsList.map((pj) => SearchableDropdownItem<int?>(value: pj.projectId, label: '${pj.projectCode} - ${pj.projectName}')),
                                  ],
                                  onChanged: (val) => setState(() => _selectedProjectId = val),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _estimatedDutiesController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'تقدير الرسوم الجمركية والضرائب (EGP)',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.calculate, color: AppTheme.cobalt),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // BROKER CLEARANCE & LOGISTICS QUOTE DETAILS CARD
                  _buildBrokerQuoteDetailsCard(currenciesList),
                  const SizedBox(height: 20),

                  // CUSTOMS CALCULATION ENGINE CARD (MD-008 Customs Engine)
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calculate, color: AppTheme.cobalt, size: 22),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('محرك حساب الرسوم والضرائب الجمركية للشحنة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
                                    Text('يستدعي بنود HS Code والقيم والاشتراطات تلقائياً من ملف الشحنة وأوامر الشراء المربوطة ويحسب الجمارك والـ VAT ورسم التنمية', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                                onPressed: () => _syncHsRequirementsToChecklist(silent: false),
                                icon: const Icon(Icons.sync_alt, color: Colors.white, size: 16),
                                label: const Text('⚡ مزامنة اشتراطات الـ HS Codes مع قائمة المستندات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(_isCustomsCalculatorExpanded ? Icons.expand_less : Icons.expand_more, color: AppTheme.charcoal),
                                tooltip: _isCustomsCalculatorExpanded ? 'طي محرك الحساب' : 'توسيع محرك الحساب',
                                onPressed: () => setState(() => _isCustomsCalculatorExpanded = !_isCustomsCalculatorExpanded),
                              ),
                            ],
                          ),
                          if (_isCustomsCalculatorExpanded) ...[
                            const Divider(height: 24),
                            // Inputs Bar: Currency, Exchange Rate, Freight, Insurance
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: SearchableDropdownField<String>(
                                    value: _customsCurrency,
                                    labelText: 'عملة الفاتورة (Currency)',
                                    items: (ref.watch(currenciesProvider).value ?? []).isNotEmpty
                                        ? (ref.watch(currenciesProvider).value ?? [])
                                            .map((c) => SearchableDropdownItem<String>(
                                                  value: c.currencyCode,
                                                  label: '${c.currencyCode} - ${c.currencyName}',
                                                ))
                                            .toList()
                                        : const [
                                            SearchableDropdownItem(value: 'USD', label: 'USD - دولار أمريكي'),
                                            SearchableDropdownItem(value: 'EUR', label: 'EUR - يورو أوروبي'),
                                            SearchableDropdownItem(value: 'GBP', label: 'GBP - جنيه إسترليني'),
                                            SearchableDropdownItem(value: 'CNY', label: 'CNY - يوان صيني'),
                                            SearchableDropdownItem(value: 'EGP', label: 'EGP - جنيه مصري'),
                                          ],
                                    onChanged: (v) {
                                      if (v != null) {
                                        setState(() {
                                          _customsCurrency = v;
                                          _updateExchangeRateForCurrency(v);
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _exchangeRateController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'سعر الصرف الجمركي (Exchange Rate EGP)', border: OutlineInputBorder()),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _freightEgpController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'النولون البحري/الجوي (Freight EGP)', border: OutlineInputBorder()),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _insuranceEgpController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'التأمين البحري (Insurance EGP)', border: OutlineInputBorder()),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),

                              ],
                            ),
                            const SizedBox(height: 16),

                            // HS Code Line Items Calculation Table
                            if (calcLines.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                                child: const Row(
                                  children: [
                                    Icon(Icons.info_outline, color: AppTheme.cobalt),
                                    SizedBox(width: 10),
                                    Text('يرجى اختيار ملف شحنة أو أمر شراء يحتوي على بنود وأسعار وأكواد HS Code لتفعيل محرك الحساب التلقائي.', style: TextStyle(color: AppTheme.charcoal, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              )
                            else ...[
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columnSpacing: 14,
                                  headingRowColor: WidgetStateProperty.all(AppTheme.charcoal.withOpacity(0.06)),
                                  headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.charcoal, fontSize: 12),
                                  columns: const [
                                    DataColumn(label: Text('بند التعريفة (HS Code)')),
                                    DataColumn(label: Text('بيان الصنف والمنشأ')),
                                    DataColumn(label: Text('الكمية والوحدة')),
                                    DataColumn(label: Text('القيمة (FOB EGP)')),
                                    DataColumn(label: Text('القيمة الجمركية (CIF EGP)')),
                                    DataColumn(label: Text('ضريبة الوارد (الإعفاء)')),
                                    DataColumn(label: Text('VAT (القيمة المضافة)')),
                                    DataColumn(label: Text('ض.جدول / تنمية / خدمات')),
                                    DataColumn(label: Text('إجمالي الضرائب والرسوم')),
                                    DataColumn(label: Text('الاشتراطات والعروض')),
                                  ],
                                  rows: calcLines.map((line) {
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(color: AppTheme.cobalt.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                                            child: Text(line.hsCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                                          ),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: 190,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(line.description, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                                                if (line.countryOfOrigin != null && line.countryOfOrigin!.isNotEmpty)
                                                  Container(
                                                    margin: const EdgeInsets.only(top: 2),
                                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue.shade50,
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(color: Colors.blue.shade200),
                                                    ),
                                                    child: Text(
                                                      'المنشأ: ${line.countryOfOrigin}',
                                                      style: TextStyle(fontSize: 10, color: Colors.blue.shade900, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        DataCell(Text('${line.qty.toStringAsFixed(0)} ${line.unit}')),
                                        DataCell(Text(line.fobEgp.toStringAsFixed(2))),
                                        DataCell(Text(line.cifEgp.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold))),
                                        DataCell(
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              if (line.hasExemption) ...[
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      '${line.baseDutyRate}%',
                                                      style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 11),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${line.dutyRate}% (${line.dutyAmountEgp.toStringAsFixed(2)})',
                                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                                    ),
                                                  ],
                                                ),
                                                Container(
                                                  margin: const EdgeInsets.only(top: 2),
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green.shade50,
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(color: Colors.green.shade300),
                                                  ),
                                                  child: Text(
                                                    '✨ إعفاء: ${line.appliedAgreementName ?? "اتفاقية"}',
                                                    style: TextStyle(fontSize: 9.5, color: Colors.green.shade900, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ] else ...[
                                                Text('${line.dutyRate}% (${line.dutyAmountEgp.toStringAsFixed(2)})'),
                                              ],
                                            ],
                                          ),
                                        ),
                                        DataCell(Text('${line.vatRate}% (${line.vatAmountEgp.toStringAsFixed(2)})')),
                                        DataCell(Text('${(line.scheduleTaxAmountEgp + line.developmentFeeAmountEgp + line.customsServiceFeeAmountEgp).toStringAsFixed(2)} EGP')),
                                        DataCell(Text('${line.totalTaxesAndDutiesEgp.toStringAsFixed(2)} EGP', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.crimson))),
                                        DataCell(
                                          Row(
                                            children: [
                                              if (line.requiresAcid)
                                                Container(
                                                  margin: const EdgeInsets.only(left: 4),
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                  decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(4)),
                                                  child: const Text('ACID', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                                                ),
                                              if (line.requiresCoo)
                                                Container(
                                                  margin: const EdgeInsets.only(left: 4),
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                  decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)),
                                                  child: const Text('COO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                                                ),
                                              if (line.requiresInspection)
                                                Container(
                                                  margin: const EdgeInsets.only(left: 4),
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                  decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(4)),
                                                  child: const Text('GOEIC', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
                                                ),
                                              if (line.regulatoryAuthority != null)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                  decoration: BoxDecoration(color: Colors.purple.shade100, borderRadius: BorderRadius.circular(4)),
                                                  child: Text(line.regulatoryAuthority!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple)),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Exemption & Documentary Requirements Alerts for applicable HS Codes
                              ...calcLines.where((l) => l.hasExemption || l.priorApprovalNote != null || (l.regulatoryAuthority != null && l.regulatoryAuthority!.isNotEmpty)).map((line) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.amber.shade700, width: 1.2),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '⚠️ تنبيه إعفاء وشروط مستندية مطلوبة للمورد الخارجي (HS Code: ${line.hsCode}${line.countryOfOrigin != null ? " - ${line.countryOfOrigin}" : ""}):',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber.shade900),
                                            ),
                                          ),
                                          if (line.hasExemption)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade100,
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: Colors.green.shade700),
                                              ),
                                              child: Text(
                                                '✅ إعفاء جمركي مطبق: ${line.appliedAgreementName}',
                                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '• توجد اتفاقيات وشروط مستندية يجب طلب استيفائها من المورد الخارجي (مثل شهادة EUR.1 الأصلي أو منشأ الميركسور) قبل تطبيق الإعفاء الجمركي:',
                                        style: TextStyle(fontSize: 11, color: Colors.amber.shade900, fontWeight: FontWeight.w600),
                                      ),
                                      if (line.exemptionConditionsNote != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          '  - الشروط والاتفاقية: ${line.exemptionConditionsNote!}',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.charcoal),
                                        ),
                                      ],
                                      if (line.requiredDocument != null) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          '  - المستند الإلزامي من المورد: ${line.requiredDocument!}',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                                        ),
                                      ],
                                      if (line.priorApprovalNote != null && line.priorApprovalNote!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          '  - شروط وموافقات مسبقة / إفراج جهات: ${line.priorApprovalNote!}',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.charcoal, height: 1.3),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 16),

                              // Calculation Financial Summary Matrix
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.charcoal.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.cobalt.withOpacity(0.3)),
                                ),
                                child: Wrap(
                                  spacing: 16,
                                  runSpacing: 12,
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    _buildMetricBadge('إجمالي FOB بالجنيه', '${totalFobEgp.toStringAsFixed(2)} EGP', Colors.grey.shade800),
                                    _buildMetricBadge('إجمالي القيمة الجمركية (CIF Base)', '${totalCifEgp.toStringAsFixed(2)} EGP', AppTheme.cobalt),
                                    _buildMetricBadge('إجمالي ضريبة الوارد (Customs Duty)', '${totalDutyEgp.toStringAsFixed(2)} EGP', Colors.indigo),
                                    _buildMetricBadge('إجمالي ضريبة القيمة المضافة (VAT)', '${totalVatEgp.toStringAsFixed(2)} EGP', Colors.teal),
                                    _buildMetricBadge('إجمالي الرسوم والضرائب الجمركية', '${totalTaxesAndDutiesEgp.toStringAsFixed(2)} EGP', AppTheme.crimson),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                                      onPressed: () {
                                        setState(() {
                                          _estimatedDutiesController.text = totalTaxesAndDutiesEgp.toStringAsFixed(2);
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('✅ تم تحديث وربط التقدير المالي للرسوم الجمركية: ${totalTaxesAndDutiesEgp.toStringAsFixed(2)} EGP'), backgroundColor: AppTheme.emerald),
                                        );
                                      },
                                      icon: const Icon(Icons.done_all, color: Colors.white, size: 16),
                                      label: const Text('اعتماد وربط التقدير المالي للدراسة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                              const SizedBox(height: 16),

                              // NAFEZA STATEMENT FEE BREAKDOWN CARD (تفاصيل بنود التحصيل والإقرارات الرسمية)
                              _buildNafezaFeeBreakdownCard(
                                calcLines: calcLines,
                                totalDutyEgp: totalDutyEgp,
                                totalVatEgp: totalVatEgp,
                                totalServiceFeeEgp: calcLines.fold(0.0, (s, l) => s + l.customsServiceFeeAmountEgp),
                                totalScheduleTaxEgp: calcLines.fold(0.0, (s, l) => s + l.scheduleTaxAmountEgp),
                                totalFreightEgp: totalFreightEgp,
                                totalInsuranceEgp: totalInsuranceEgp,
                                exchangeRate: exchangeRate,
                              ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Checklist Table & Controls
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
                              const Text('قائمة فحص واشتراطات المستندات الجمركية (Customs Checklist)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
                              const Spacer(),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                                onPressed: _addChecklistItem,
                                icon: const Icon(Icons.add, color: Colors.white),
                                label: const Text('إضافة بند جديد للفحص', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 10),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _checklist.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = _checklist[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              if (item.hsCode != null && item.hsCode!.isNotEmpty)
                                                Container(
                                                  margin: const EdgeInsets.only(left: 6),
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(color: AppTheme.cobalt.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                                                  child: Text(item.hsCode!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                                                ),
                                              Expanded(child: Text(item.documentType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                            ],
                                          ),
                                          if (item.regulatoryAgency != null)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2.0),
                                              child: Text('الجهة: ${item.regulatoryAgency}', style: const TextStyle(fontSize: 11, color: Colors.purple, fontWeight: FontWeight.bold)),
                                            ),
                                          if (item.remarks != null && item.remarks!.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2.0),
                                              child: Text(item.remarks!, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: SearchableDropdownField<String>(
                                        value: item.responsibleParty,
                                        labelText: 'الجهة',
                                        items: const [
                                          SearchableDropdownItem(value: 'Customs Broker', label: 'Customs Broker'),
                                          SearchableDropdownItem(value: 'Supplier / Exporter', label: 'Supplier / Exporter'),
                                          SearchableDropdownItem(value: 'Importer Team', label: 'Importer Team'),
                                          SearchableDropdownItem(value: 'Freight Forwarder', label: 'Freight Forwarder'),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() {
                                              _checklist[index] = item.copyWith(responsibleParty: val);
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: SearchableDropdownField<String>(
                                        value: item.status,
                                        labelText: 'الحالة',
                                        items: const [
                                          SearchableDropdownItem(value: 'Pending', label: 'Pending'),
                                          SearchableDropdownItem(value: 'Received', label: 'Received'),
                                          SearchableDropdownItem(value: 'Verified', label: 'Verified'),
                                          SearchableDropdownItem(value: 'Approved', label: 'Approved'),
                                          SearchableDropdownItem(value: 'Rejected', label: 'Rejected'),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() {
                                              _checklist[index] = item.copyWith(status: val);
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(item.isBlockingShipment ? Icons.block : Icons.check_circle_outline, color: item.isBlockingShipment ? Colors.red : Colors.grey, size: 20),
                                      tooltip: item.isBlockingShipment ? 'بند يعطل الشحنة (Blocking)' : 'بند غير معطل',
                                      onPressed: () {
                                        setState(() {
                                          _checklist[index] = item.copyWith(isBlockingShipment: !item.isBlockingShipment);
                                        });
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.grey, size: 20),
                                      onPressed: () {
                                        setState(() {
                                          _checklist.removeAt(index);
                                        });
                                      },
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

          // TAB 2: SAVED CONSULTATIONS HISTORY REGISTRY (Premium Design)
          consultationsState.when(
            loading: () => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.cobalt),
                  SizedBox(height: 16),
                  Text('جارٍ تحميل سجل الدراسات الجمركية...',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            error: (err, stack) => Center(child: Text('❌ Error: $err')),
            data: (sessions) {
              final filtered = sessions.where((s) {
                final matchQuery = _searchQuery.isEmpty ||
                    s.consultationCode
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()) ||
                    s.title
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()) ||
                    s.brokerName
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase());
                final matchStatus =
                    _statusFilter == 'All' || s.overallStatus == _statusFilter;
                return matchQuery && matchStatus;
              }).toList();

              // Aggregate metrics for header strip
              final totalCount = sessions.length;
              final readyCount = sessions
                  .where((s) => s.overallStatus == 'Clearance Ready')
                  .length;
              final blockedCount = sessions
                  .where(
                      (s) => s.overallStatus == 'Blocked' || s.hasBlockingIssues)
                  .length;
              final avgReadiness = sessions.isEmpty
                  ? 0.0
                  : sessions.fold(
                          0.0, (s, c) => s + c.readinessPercentage) /
                      sessions.length;

              return Column(
                children: [
                  // ── Metrics & Toolbar Strip ──────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.charcoal.withOpacity(0.03),
                      border:
                          Border(bottom: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      children: [
                        _buildMetricBadge(
                            'إجمالي الدراسات', '$totalCount دراسة', AppTheme.charcoal),
                        const SizedBox(width: 10),
                        _buildMetricBadge(
                            'جاهزة للتخليص', '$readyCount', AppTheme.emerald),
                        const SizedBox(width: 10),
                        _buildMetricBadge(
                            'عوائق مفتوحة',
                            '$blockedCount',
                            blockedCount > 0
                                ? AppTheme.crimson
                                : Colors.grey),
                        const SizedBox(width: 10),
                        _buildMetricBadge(
                            'متوسط الجاهزية',
                            '${avgReadiness.toStringAsFixed(0)}%',
                            AppTheme.cobalt),
                        const Spacer(),
                        // Search field
                        SizedBox(
                          width: 260,
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'بحث بالكود أو العنوان أو المستخلص...',
                              prefixIcon:
                                  const Icon(Icons.search, size: 18),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              isDense: true,
                            ),
                            onChanged: (v) =>
                                setState(() => _searchQuery = v),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Status Filter
                        SizedBox(
                          width: 175,
                          child: SearchableDropdownField<String>(
                            value: _statusFilter,
                            labelText: 'تصفية الحالة',
                            items: const [
                              SearchableDropdownItem(
                                  value: 'All', label: 'جميع الحالات'),
                              SearchableDropdownItem(
                                  value: 'Pending Review',
                                  label: 'Pending Review'),
                              SearchableDropdownItem(
                                  value: 'In Progress',
                                  label: 'In Progress'),
                              SearchableDropdownItem(
                                  value: 'Action Required',
                                  label: 'Action Required'),
                              SearchableDropdownItem(
                                  value: 'Clearance Ready',
                                  label: 'Clearance Ready'),
                              SearchableDropdownItem(
                                  value: 'Blocked', label: 'Blocked'),
                            ],
                            onChanged: (v) =>
                                setState(() => _statusFilter = v!),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const SizedBox(width: 10),
                        FilterChip(
                          avatar: Icon(_showInactive ? Icons.visibility_off : Icons.visibility, size: 16),
                          label: Text(_showInactive ? 'إخفاء المؤرشفة' : 'إظهار المؤرشفة'),
                          selected: _showInactive,
                          selectedColor: Colors.red.shade100,
                          onSelected: (val) {
                            setState(() => _showInactive = val);
                            ref.read(customsConsultationsProvider.notifier).fetchConsultations(includeInactive: val);
                          },
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.cobalt.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${filtered.length} نتيجة',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.cobalt),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Data Table ──────────────────────────────────────────
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.folder_open_rounded,
                                    size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isNotEmpty ||
                                          _statusFilter != 'All'
                                      ? 'لا توجد نتائج مطابقة للبحث أو التصفية'
                                      : 'لا توجد دراسات استشارة جمركية محفوظة بعد',
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'قم بإنشاء دراسة جديدة من تبويب "Customs Workspace"',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade400),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            padding:
                                const EdgeInsets.fromLTRB(16, 12, 16, 24),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side:
                                    BorderSide(color: Colors.grey.shade200),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowHeight: 48,
                                  dataRowMinHeight: 60,
                                  dataRowMaxHeight: 76,
                                  horizontalMargin: 16,
                                  columnSpacing: 20,
                                  dividerThickness: 0.5,
                                  headingRowColor: WidgetStateProperty.all(
                                      AppTheme.charcoal),
                                  headingTextStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 0.3,
                                  ),
                                  columns: const [
                                    DataColumn(
                                      label: SizedBox(
                                        width: 168,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.bolt_rounded,
                                                size: 14, color: Colors.amber),
                                            SizedBox(width: 4),
                                            Text('العمليات',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    DataColumn(label: Text('📋 كود الدراسة')),
                                    DataColumn(label: Text('📁 ملف الشحنة')),
                                    DataColumn(label: Text('📝 عنوان الدراسة')),
                                    DataColumn(
                                        label: Text('🧑‍💼 المستخلص الجمركي')),
                                    DataColumn(
                                        label: Text('💰 الرسوم التقديرية')),
                                    DataColumn(
                                        label: Text('📊 جاهزية المستندات')),
                                    DataColumn(label: Text('🔖 الحالة العامة')),
                                  ],
                                  rows: filtered.asMap().entries.map((entry) {
                                    final idx = entry.key;
                                    final session = entry.value;
                                    final isEven = idx.isEven;
                                    final rowColor = isEven
                                        ? Colors.white
                                        : Colors.grey.shade50;
                                    final readinessPct =
                                        session.readinessPercentage;
                                    final hasBlocking =
                                        session.hasBlockingIssues ||
                                            session.blockingIssuesCount > 0;

                                    return DataRow(
                                      color:
                                          WidgetStateProperty.all(rowColor),
                                      onSelectChanged: (_) =>
                                          _showConsultationDetailsDialog(
                                              session),
                                      cells: [
                                        // ⚡ 1. Actions
                                        DataCell(
                                          RowActionsPill(
                                            onView: () =>
                                                _showConsultationDetailsDialog(
                                                    session),
                                            onEdit: () =>
                                                _loadConsultationForEdit(
                                                    session),
                                            onPrint: () {
                                              Printing.layoutPdf(
                                                onLayout: (format) =>
                                                    CustomsConsultationPdfService.generateConsultationPdf(session),
                                                name: 'Customs_Consultation_${session.consultationCode}',
                                              );
                                            },
                                             onDelete: () async {
                                               final messenger = ScaffoldMessenger.of(context);
                                               if (session.isActive == false) {
                                                 final confirm = await showDialog<bool>(
                                                   context: context,
                                                   builder: (ctx) => AlertDialog(
                                                     title: const Row(
                                                       children: [
                                                         Icon(Icons.restore_from_trash_rounded, color: Colors.green, size: 22),
                                                         SizedBox(width: 8),
                                                         Text('استعادة دراسة الاستشارة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                       ],
                                                     ),
                                                     content: Text(
                                                       'هل ترغب في استعادة وتفعيل دراسة الاستشارة الجمركية "${session.consultationCode} - ${session.title}"؟',
                                                       style: const TextStyle(fontSize: 13),
                                                     ),
                                                     actions: [
                                                       TextButton(
                                                         onPressed: () => Navigator.pop(ctx, false),
                                                         child: const Text('إلغاء'),
                                                       ),
                                                       ElevatedButton.icon(
                                                         style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white),
                                                         icon: const Icon(Icons.restore_rounded, size: 16),
                                                         label: const Text('استعادة وتفعيل'),
                                                         onPressed: () => Navigator.pop(ctx, true),
                                                       ),
                                                     ],
                                                   ),
                                                 );
                                                 if (confirm == true) {
                                                   try {
                                                     await ref.read(customsConsultationsProvider.notifier).restoreConsultation(session.consultationId);
                                                     if (mounted) {
                                                       messenger.showSnackBar(
                                                         SnackBar(
                                                           content: Text('♻️ تم استعادة وتفعيل دراسة الاستشارة (${session.consultationCode}) بنجاح'),
                                                           backgroundColor: AppTheme.emerald,
                                                         ),
                                                       );
                                                     }
                                                   } catch (e) {
                                                     if (mounted) {
                                                       messenger.showSnackBar(
                                                         SnackBar(
                                                           content: Text('❌ خطأ أثناء الاستعادة: $e'),
                                                           backgroundColor: AppTheme.crimson,
                                                         ),
                                                       );
                                                     }
                                                   }
                                                 }
                                               } else {
                                                 final confirm = await showDialog<bool>(
                                                   context: context,
                                                   builder: (ctx) => AlertDialog(
                                                     title: const Row(
                                                       children: [
                                                         Icon(Icons.warning_rounded, color: Colors.orange, size: 22),
                                                         SizedBox(width: 8),
                                                         Text('تأكيد حذف الدراسة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                       ],
                                                     ),
                                                     content: Text(
                                                       'هل أنت متأكد من حذف دراسة الاستشارة الجمركية "${session.consultationCode} - ${session.title}"؟\n\nسيتم أرشفة الدراسة مع إمكانية استعادتها لاحقاً.',
                                                       style: const TextStyle(fontSize: 13),
                                                     ),
                                                     actions: [
                                                       TextButton(
                                                         onPressed: () => Navigator.pop(ctx, false),
                                                         child: const Text('إلغاء'),
                                                       ),
                                                       ElevatedButton.icon(
                                                         style: ElevatedButton.styleFrom(
                                                           backgroundColor: AppTheme.crimson,
                                                           foregroundColor: Colors.white,
                                                         ),
                                                         icon: const Icon(Icons.delete_rounded, size: 16),
                                                         label: const Text('حذف وأرشفة'),
                                                         onPressed: () => Navigator.pop(ctx, true),
                                                       ),
                                                     ],
                                                   ),
                                                 );
                                                 if (confirm == true) {
                                                   try {
                                                     await ref.read(customsConsultationsProvider.notifier).softDeleteConsultation(session.consultationId);
                                                     if (mounted) {
                                                       messenger.showSnackBar(
                                                         SnackBar(
                                                           content: Text('🗑️ تم حذف وأرشفة دراسة الاستشارة (${session.consultationCode}) بنجاح'),
                                                           backgroundColor: AppTheme.emerald,
                                                         ),
                                                       );
                                                     }
                                                   } catch (e) {
                                                     if (mounted) {
                                                       messenger.showSnackBar(
                                                         SnackBar(
                                                           content: Text('❌ خطأ أثناء الحذف: $e'),
                                                           backgroundColor: AppTheme.crimson,
                                                         ),
                                                       );
                                                     }
                                                   }
                                                 }
                                               }
                                             },
                                             deleteTooltip: session.isActive == false ? 'استعادة الدراسة المحذوفة' : 'حذف الدراسة (Soft Delete)',
                                          ),
                                        ),

                                        // 2. Consultation Code
                                        DataCell(
                                          InkWell(
                                            onTap: () =>
                                                _showConsultationDetailsDialog(
                                                    session),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppTheme.cobalt
                                                    .withOpacity(0.08),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                    color: AppTheme.cobalt
                                                        .withOpacity(0.25)),
                                              ),
                                              child: Text(
                                                session.consultationCode,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.cobalt,
                                                    fontSize: 12),
                                              ),
                                            ),
                                          ),
                                        ),

                                        // 3. Import File
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppTheme.charcoal
                                                  .withOpacity(0.07),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              session.importFileCode ??
                                                  (session.importFileId != null
                                                      ? 'IMP-${session.importFileId}'
                                                      : '—'),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.charcoal,
                                                  fontSize: 12),
                                            ),
                                          ),
                                        ),

                                        // 4. Title
                                        DataCell(
                                          SizedBox(
                                            width: 180,
                                            child: Text(
                                              session.title,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                              style: const TextStyle(
                                                  fontSize: 12),
                                            ),
                                          ),
                                        ),

                                        // 5. Broker
                                        DataCell(
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                session.brokerName,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12),
                                              ),
                                              if (session.brokerContactPerson !=
                                                  null)
                                                Text(
                                                  session.brokerContactPerson!,
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      color:
                                                          Colors.grey.shade600),
                                                ),
                                            ],
                                          ),
                                        ),

                                        // 6. Estimated Duties
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppTheme.crimson
                                                  .withOpacity(0.08),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              '${session.estimatedDutiesEgp.toStringAsFixed(0)} EGP',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.crimson,
                                                  fontSize: 12),
                                            ),
                                          ),
                                        ),

                                        // 7. Readiness Progress Bar
                                        DataCell(
                                          SizedBox(
                                            width: 145,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      '${readinessPct.toStringAsFixed(0)}%',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 11,
                                                        color: readinessPct >=
                                                                80
                                                            ? AppTheme.emerald
                                                            : (readinessPct >=
                                                                    50
                                                                ? Colors.orange
                                                                : AppTheme
                                                                    .crimson),
                                                      ),
                                                    ),
                                                    if (hasBlocking)
                                                      Container(
                                                        padding: const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 5,
                                                            vertical: 1),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: AppTheme.crimson
                                                              .withOpacity(0.12),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(4),
                                                        ),
                                                        child: Text(
                                                          '${session.blockingIssuesCount} عائق',
                                                          style: const TextStyle(
                                                              color: AppTheme
                                                                  .crimson,
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  child: LinearProgressIndicator(
                                                    value:
                                                        (readinessPct / 100)
                                                            .clamp(0.0, 1.0),
                                                    minHeight: 6,
                                                    backgroundColor:
                                                        Colors.grey.shade200,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                            Color>(
                                                      readinessPct >= 80
                                                          ? AppTheme.emerald
                                                          : (readinessPct >= 50
                                                              ? Colors.orange
                                                              : AppTheme
                                                                  .crimson),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  '${session.approvedDocumentsCount}/${session.totalDocumentsCount} مستند معتمد',
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      color:
                                                          Colors.grey.shade600),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        // 8. Status Badge
                                        DataCell(
                                            _buildStatusBadge(
                                                session.overallStatus)),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              );
            },
          ),

          // TAB 3: BROKER PRICE LISTS & CATALOG MANAGEMENT
          _buildPriceListsAndCatalogTab(),
        ],
      ),
    );
  }



  Widget _buildNafezaFeeBreakdownCard({
    required List<CustomsItemCalcRow> calcLines,
    required double totalDutyEgp,
    required double totalVatEgp,
    required double totalServiceFeeEgp,
    required double totalScheduleTaxEgp,
    required double totalFreightEgp,
    required double totalInsuranceEgp,
    required double exchangeRate,
  }) {
    final nafezaResult = CustomsExportService.computeNafezaFeeBreakdown(
      totalDutyEgp: totalDutyEgp,
      totalVatEgp: totalVatEgp,
      totalServiceFeeEgp: totalServiceFeeEgp,
      totalScheduleTaxEgp: totalScheduleTaxEgp,
    );

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.cobalt.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar matching Image 2
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.cobalt.withOpacity(0.08),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(9), topRight: Radius.circular(9)),
              border: Border(bottom: BorderSide(color: AppTheme.cobalt.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: AppTheme.cobalt, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'تفاصيل بنود التحصيل والإقرارات الرسمية (Nafeza Statement Fee Breakdown)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.cobalt),
                  ),
                ),
                Text(
                  '${nafezaResult.grandTotal.toStringAsFixed(2)} EGP إجمالي البيان:',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.cobalt),
                ),
                const SizedBox(width: 12),
                // PDF Export Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.charcoal,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: () async {
                    final session = CustomsConsultationModel(
                      consultationId: _editingConsultationId ?? 0,
                      consultationCode: _editingConsultationCode ?? 'DRAFT-STMT',
                      brokerId: _selectedBrokerId ?? 0,
                      brokerName: _selectedBrokerName.isNotEmpty ? _selectedBrokerName : 'مستخلص جمركي معتمد',
                      title: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : 'دراسة استشارة جمركية',
                      overallStatus: 'Pending Review',
                      estimatedDutiesEgp: nafezaResult.grandTotal,
                      totalBrokerFeesEgp: _brokerQuoteItems.fold(0.0, (s, i) => s + (i.isApplicable ? i.totalAmount : 0.0)),
                      checklistItems: _checklist,
                      brokerQuoteItems: _brokerQuoteItems,
                      createdAt: DateTime.now().toIso8601String(),
                      updatedAt: DateTime.now().toIso8601String(),
                    );
                    await Printing.layoutPdf(
                      onLayout: (format) => CustomsConsultationPdfService.generateConsultationPdf(session),
                      name: 'Nafeza_Statement_${DateTime.now().millisecondsSinceEpoch}',
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 14),
                  label: const Text('📄 حفظ PDF', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                // Excel Export Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emerald,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: () async {
                    try {
                      final savedFile = await CustomsExportService.exportCustomsStudyToExcel(
                        context: context,
                        title: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : 'دراسة استشارة جمركية',
                        importFileCode: _selectedImportFileId != null ? 'IMP-$_selectedImportFileId' : null,
                        brokerName: _selectedBrokerName.isNotEmpty ? _selectedBrokerName : 'غير محدد',
                        currency: _customsCurrency,
                        exchangeRate: exchangeRate,
                        totalFreightEgp: totalFreightEgp,
                        totalInsuranceEgp: totalInsuranceEgp,
                        calcLines: calcLines,
                        nafezaResult: nafezaResult,
                        brokerQuoteItems: _brokerQuoteItems,
                      );
                      if (savedFile != null && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('✅ تم تصدير وحفظ شيت الإكسيل بنجاح: $savedFile'), backgroundColor: AppTheme.emerald),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('❌ خطأ أثناء التصدير: $e'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  icon: const Icon(Icons.table_chart, color: Colors.white, size: 14),
                  label: const Text('📊 تصدير EXCEL', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // Grouped Fee Items Matching Image 2
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: nafezaResult.groups.map((group) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      // Group Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade100.withOpacity(0.4),
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'تحصيل ${group.groupName}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal),
                            ),
                            Text(
                              '${group.totalAmount.toStringAsFixed(2)} ج.م',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal),
                            ),
                          ],
                        ),
                      ),
                      // Items inside group
                      ...group.items.map((item) {
                        final typeLabel = item.calculationType == 'flat'
                            ? 'قطعي'
                            : (item.calculationType == 'reference' ? 'مرجعي' : 'مشتق');
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Row(
                            children: [
                              // Code Badge
                              Container(
                                width: 44,
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Text(
                                  '[${item.code}]',
                                  style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Item Name
                              Expanded(
                                child: Text(
                                  item.nameAr,
                                  style: const TextStyle(fontSize: 12, color: AppTheme.charcoal, fontWeight: FontWeight.w500),
                                ),
                              ),
                              // Calculation Type
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: item.calculationType == 'flat' ? Colors.blue.shade50 : Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  typeLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: item.calculationType == 'flat' ? Colors.blue.shade800 : Colors.teal.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Amount
                              SizedBox(
                                width: 110,
                                child: Text(
                                  '${item.calculatedAmount.toStringAsFixed(2)} ج.م',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrokerCostRow({
    required int index,
    required CustomsBrokerQuoteItemModel item,
    required List<CurrencyModel> currenciesList,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: item.isApplicable ? AppTheme.emerald.withOpacity(0.04) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: item.isApplicable ? AppTheme.emerald.withOpacity(0.3) : Colors.grey.shade300),
      ),
      child: Row(
        children: [
          // Title & Category
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.expenseName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.category.split('(').first.trim()} | ${item.unitType}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Price field
          Expanded(
            flex: 2,
            child: TextFormField(
              key: ValueKey('price_${item.expenseTypeId ?? item.expenseName}_${item.unitPrice}'),
              initialValue: item.unitPrice == 0.0 ? '' : item.unitPrice.toString(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'سعر البند',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              onChanged: (v) {
                final p = double.tryParse(v) ?? 0.0;
                _updateBrokerQuoteItem(index, item.copyWith(unitPrice: p));
              },
            ),
          ),
          const SizedBox(width: 8),
          // Currency dropdown
          Expanded(
            flex: 2,
            child: SearchableDropdownField<String>(
              value: currenciesList.any((c) => c.currencyCode == item.currency)
                  ? item.currency
                  : (currenciesList.isNotEmpty ? currenciesList.first.currencyCode : 'EGP'),
              labelText: 'العملة',
              items: currenciesList
                  .map((c) => SearchableDropdownItem(
                        value: c.currencyCode,
                        label: '${c.currencyCode} (${c.currencySymbol})',
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  _updateBrokerQuoteItem(index, item.copyWith(currency: v));
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          // Qty field
          Expanded(
            flex: 1,
            child: TextFormField(
              key: ValueKey('qty_${item.expenseTypeId ?? item.expenseName}_${item.qty}'),
              initialValue: item.qty == 0.0 ? '1' : (item.qty == item.qty.roundToDouble() ? item.qty.toInt().toString() : item.qty.toString()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'الكمية',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              onChanged: (v) {
                final q = double.tryParse(v) ?? 1.0;
                _updateBrokerQuoteItem(index, item.copyWith(qty: q));
              },
            ),
          ),
          const SizedBox(width: 10),
          // Applicable switch
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: item.isApplicable,
                activeColor: AppTheme.emerald,
                onChanged: (v) => _updateBrokerQuoteItem(index, item.copyWith(isApplicable: v)),
              ),
              Text(
                item.isApplicable ? 'مطبق' : 'غير مطبق',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: item.isApplicable ? AppTheme.emerald : Colors.red.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          // Line total display
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: item.isApplicable ? AppTheme.emerald.withOpacity(0.12) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.isApplicable
                    ? '${(item.unitPrice * item.qty).toStringAsFixed(2)} ${item.currency}'
                    : '0.00 ${item.currency}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: item.isApplicable ? AppTheme.emerald : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrokerQuoteDetailsCard(List<CurrencyModel> currenciesList) {
    if (_selectedBrokerId == null) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '💡 يرجى تحديد المستخلص الجمركي أعلاه لاستدعاء قائمة أسعار التخليص والنقل الخاصة به تلقائياً وتفعيل بنود المصروفات.',
                  style: TextStyle(fontSize: 13, color: AppTheme.charcoal),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoadingPriceList) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: const Padding(
          padding: EdgeInsets.all(30),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(strokeWidth: 2.5),
                SizedBox(width: 14),
                Text('جاري جلب قائمة أسعار التخليص والنقل للمستخلص...', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      );
    }

    final totalBrokerFees = _brokerQuoteItems.fold(0.0, (sum, itm) => sum + (itm.isApplicable ? itm.totalAmount : 0.0));
    final appliedCount = _brokerQuoteItems.where((i) => i.isApplicable).length;

    // Filter items by category
    final categories = [
      'All',
      'Clearance Fees (أتعاب ومصاريف تخليص)',
      'Procedures & Approvals (إجراءات وموافقات وفحص)',
      'Inland Transport (نقل بري وشاحنات)',
      'Port & Handling (موانئ وتعتيق وتفريغ)',
      'Other Fees (مصاريف أخرى)',
    ];

    final filteredItems = _brokerExpenseCategoryFilter == 'All'
        ? _brokerQuoteItems
        : _brokerQuoteItems.where((i) => i.category == _brokerExpenseCategoryFilter).toList();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.request_quote, color: AppTheme.cobalt, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💰 تفاصيل عرض أسعار التخليص الجمركي والنقل للمستخلص (Customs Broker Quote Details)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal),
                      ),
                      if (_brokerPriceListTitle != null)
                        Text(
                          '📋 المصدر: $_brokerPriceListTitle (${_brokerQuoteItems.length} بنود مسعرة)',
                          style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade700),
                        ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: AppTheme.cobalt),
                  onPressed: _addCustomBrokerExpenseRow,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('إضافة بند مخصص', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(_isBrokerQuoteExpanded ? Icons.expand_less : Icons.expand_more, color: AppTheme.charcoal),
                  tooltip: _isBrokerQuoteExpanded ? 'طي عرض الأسعار' : 'توسيع عرض الأسعار',
                  onPressed: () => setState(() => _isBrokerQuoteExpanded = !_isBrokerQuoteExpanded),
                ),
              ],
            ),
            if (_isBrokerQuoteExpanded) ...[
              const Divider(height: 20),

              // Category Filter Bar & Bulk Actions
              Row(
                children: [
                  const Text('تصفية الفئات: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: categories.map((cat) {
                          final isSelected = _brokerExpenseCategoryFilter == cat;
                          final label = cat == 'All' ? 'الكل (${_brokerQuoteItems.length})' : cat.split('(').first.trim();
                          return Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: ChoiceChip(
                              label: Text(label, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                              selected: isSelected,
                              selectedColor: AppTheme.cobalt.withOpacity(0.15),
                              onSelected: (_) => setState(() => _brokerExpenseCategoryFilter = cat),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        for (int i = 0; i < _brokerQuoteItems.length; i++) {
                          final itm = _brokerQuoteItems[i];
                          final lineTotal = itm.unitPrice * itm.qty;
                          _brokerQuoteItems[i] = itm.copyWith(isApplicable: true, totalAmount: lineTotal);
                        }
                      });
                    },
                    icon: const Icon(Icons.check_box_outlined, size: 14, color: AppTheme.emerald),
                    label: const Text('تطبيق الكل', style: TextStyle(fontSize: 11, color: AppTheme.emerald)),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        for (int i = 0; i < _brokerQuoteItems.length; i++) {
                          _brokerQuoteItems[i] = _brokerQuoteItems[i].copyWith(isApplicable: false, totalAmount: 0.0);
                        }
                      });
                    },
                    icon: const Icon(Icons.disabled_by_default_outlined, size: 14, color: Colors.red),
                    label: const Text('تعطيل الكل', style: TextStyle(fontSize: 11, color: Colors.red)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Items List
              if (filteredItems.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                  child: const Text('لا توجد بنود مصروفات في هذا التصنيف. يمكنك النقر على "إضافة بند مخصص" لإدراج مصروف جديد.'),
                )
              else
                ...filteredItems.map((item) {
                  final idx = _brokerQuoteItems.indexOf(item);
                  return _buildBrokerCostRow(
                    index: idx,
                    item: item,
                    currenciesList: currenciesList,
                  );
                }).toList(),

              const Divider(height: 24),

              // Summary Bar matching Image 4 design
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.cobalt.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.cobalt.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_balance_wallet, color: AppTheme.cobalt, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '💰 إجمالي عرض أسعار المخلص الجمركي والنقل المطبق ($appliedCount بند مطبق):',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                        ),
                      ],
                    ),
                    Text(
                      '${totalBrokerFees.toStringAsFixed(2)} EGP',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.cobalt),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }


  Widget _buildPriceListsAndCatalogTab() {
    final priceListsAsync = ref.watch(brokerPriceListsProvider);
    final expenseTypesAsync = ref.watch(clearanceExpenseTypesProvider);
    final brokersList = (ref.watch(partnersProvider).value ?? [])
        .where((p) => p.partnerType.toLowerCase().contains('customs broker') || p.partnerType.toLowerCase().contains('مخلص'))
        .toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sub-Tab Switcher (Segmented Control)
          Row(
            children: [
              ChoiceChip(
                label: const Text('📋 قوائم أسعار المخلصين (Broker Price Lists)', style: TextStyle(fontWeight: FontWeight.bold)),
                selected: _managementSubTabIndex == 0,
                selectedColor: AppTheme.cobalt.withOpacity(0.18),
                onSelected: (_) => setState(() => _managementSubTabIndex = 0),
              ),
              const SizedBox(width: 12),
              ChoiceChip(
                label: const Text('🏷️ دليل وتكويد بنود المصروفات (Clearance Expense Catalog)', style: TextStyle(fontWeight: FontWeight.bold)),
                selected: _managementSubTabIndex == 1,
                selectedColor: AppTheme.cobalt.withOpacity(0.18),
                onSelected: (_) => setState(() => _managementSubTabIndex = 1),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Sub-Tab Content
          Expanded(
            child: _managementSubTabIndex == 0
                ? _buildBrokerPriceListsView(priceListsAsync, brokersList)
                : _buildExpenseCatalogView(expenseTypesAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildBrokerPriceListsView(AsyncValue<List<BrokerPriceListModel>> priceListsAsync, List<dynamic> brokersList) {
    return priceListsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('❌ Error: $e')),
      data: (priceLists) {
        final filteredLists = priceLists.where((pl) {
          if (_selectedMgmtBrokerId != null && pl.brokerId != _selectedMgmtBrokerId) return false;
          return true;
        }).toList();

        return Column(
          children: [
            // Filter Bar
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 300,
                      child: SearchableDropdownField<int?>(
                        value: _selectedMgmtBrokerId,
                        labelText: 'تصفية حسب المخلص الجمركي',
                        searchHintText: 'ابحث عن مخلص...',
                        items: [
                          const SearchableDropdownItem(value: null, label: 'جميع المخلصين'),
                          ...brokersList.map((b) => SearchableDropdownItem<int?>(
                                value: b.providerId,
                                label: b.partnerName,
                              )),
                        ],
                        onChanged: (v) => setState(() => _selectedMgmtBrokerId = v),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                      onPressed: () => _showPriceListFormDialog(brokersList: brokersList),
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('إنشاء قائمة أسعار جديدة لمخلص', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Price Lists Table / Grid
            Expanded(
              child: filteredLists.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('لا توجد قوائم أسعار مسجلة للمخلصين المحددين.', style: TextStyle(color: Colors.grey, fontSize: 14)),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => _showPriceListFormDialog(brokersList: brokersList),
                            icon: const Icon(Icons.add),
                            label: const Text('إضافة قائمة أسعار الآن'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredLists.length,
                      itemBuilder: (ctx, idx) {
                        final pl = filteredLists[idx];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: ExpansionTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: AppTheme.cobalt.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                              child: const Icon(Icons.price_change, color: AppTheme.cobalt),
                            ),
                            title: Row(
                              children: [
                                Text(pl.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: pl.isActive ? Colors.green.shade100 : Colors.red.shade100, borderRadius: BorderRadius.circular(4)),
                                  child: Text(pl.isActive ? 'سارية' : 'مؤرشفة', style: TextStyle(color: pl.isActive ? Colors.green.shade900 : Colors.red.shade900, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                const Spacer(),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.cobalt,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                  onPressed: () => _showPriceListFormDialog(existingPriceList: pl, brokersList: brokersList),
                                  icon: const Icon(Icons.edit, color: Colors.white, size: 14),
                                  label: const Text('تعديل الأسعار والبنود', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                  tooltip: 'أرشفة قائمة الأسعار',
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('تأكيد أرشفة قائمة الأسعار'),
                                        content: Text('هل أنت متأكد من رغبتك في أرشفة قائمة الأسعار "${pl.title}"؟'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text('أرشفة', style: TextStyle(color: Colors.white)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await ref.read(brokerPriceListsProvider.notifier).softDeletePriceList(pl.priceListId);
                                    }
                                  },
                                ),
                              ],
                            ),
                            subtitle: Text('المخلص: ${pl.brokerName} | الميناء: ${pl.portName ?? "عام"} | السريان: من ${pl.effectiveFrom} ${pl.effectiveTo != null ? "إلى ${pl.effectiveTo}" : "(مفتوح)"} | عدد البنود: ${pl.items.length}'),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (pl.notes != null && pl.notes!.isNotEmpty) ...[
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.amber.shade200)),
                                        child: Text('📝 ملاحظات وشروط: ${pl.notes}', style: const TextStyle(fontSize: 12)),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    Table(
                                      border: TableBorder.all(color: Colors.grey.shade300),
                                      columnWidths: const {
                                        0: FlexColumnWidth(3.0),
                                        1: FlexColumnWidth(2.0),
                                        2: FlexColumnWidth(1.2),
                                        3: FlexColumnWidth(1.5),
                                        4: FlexColumnWidth(2.0),
                                      },
                                      children: [
                                        TableRow(
                                          decoration: BoxDecoration(color: AppTheme.charcoal.withOpacity(0.08)),
                                          children: const [
                                            Padding(padding: EdgeInsets.all(6), child: Text('اسم المصروف / البند', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                            Padding(padding: EdgeInsets.all(6), child: Text('التصنيف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                            Padding(padding: EdgeInsets.all(6), child: Text('الوحدة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                            Padding(padding: EdgeInsets.all(6), child: Text('السعر المعتمد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                            Padding(padding: EdgeInsets.all(6), child: Text('نطاق السعر / ملاحظات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                          ],
                                        ),
                                        ...pl.items.map((itm) => TableRow(
                                              children: [
                                                Padding(padding: const EdgeInsets.all(6), child: Text(itm.expenseName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                                Padding(padding: const EdgeInsets.all(6), child: Text(itm.category.split('(').first.trim(), style: const TextStyle(fontSize: 10))),
                                                Padding(padding: const EdgeInsets.all(6), child: Text(itm.unitType, style: const TextStyle(fontSize: 10))),
                                                Padding(padding: const EdgeInsets.all(6), child: Text('${itm.standardPrice.toStringAsFixed(2)} ${itm.currency}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald, fontSize: 11))),
                                                Padding(
                                                  padding: const EdgeInsets.all(6),
                                                  child: Text(
                                                    itm.minPrice != null && itm.maxPrice != null
                                                        ? '${itm.minPrice!.toStringAsFixed(0)} - ${itm.maxPrice!.toStringAsFixed(0)} ${itm.currency}'
                                                        : (itm.notes ?? '-'),
                                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                                  ),
                                                ),
                                              ],
                                            )),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExpenseCatalogView(AsyncValue<List<ClearanceExpenseTypeModel>> expenseTypesAsync) {
    return expenseTypesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('❌ Error: $e')),
      data: (expenses) {
        final filtered = expenses.where((exp) {
          if (_mgmtExpenseCategory != 'All' && exp.category != _mgmtExpenseCategory) return false;
          if (_mgmtExpenseSearch.isNotEmpty) {
            final q = _mgmtExpenseSearch.toLowerCase();
            return exp.expenseCode.toLowerCase().contains(q) || exp.nameAr.toLowerCase().contains(q) || (exp.nameEn?.toLowerCase().contains(q) ?? false);
          }
          return true;
        }).toList();

        return Column(
          children: [
            // Toolbar
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 250,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'بحث في دليل المصروفات...',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                        onChanged: (v) => setState(() => _mgmtExpenseSearch = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 250,
                      child: SearchableDropdownField<String>(
                        value: _mgmtExpenseCategory,
                        labelText: 'تصفية التصنيف',
                        searchHintText: 'ابحث...',
                        items: const [
                          SearchableDropdownItem(value: 'All', label: 'جميع التصنيفات'),
                          SearchableDropdownItem(value: 'Clearance Fees (أتعاب ومصاريف تخليص)', label: 'أتعاب ومصاريف تخليص'),
                          SearchableDropdownItem(value: 'Procedures & Approvals (إجراءات وموافقات وفحص)', label: 'إجراءات وموافقات وفحص'),
                          SearchableDropdownItem(value: 'Inland Transport (نقل بري وشاحنات)', label: 'نقل بري وشاحنات'),
                          SearchableDropdownItem(value: 'Port & Handling (موانئ وتعتيق وتفريغ)', label: 'موانئ وتعتيق وتفريغ'),
                          SearchableDropdownItem(value: 'Other Fees (مصاريف أخرى)', label: 'مصاريف أخرى'),
                        ],
                        onChanged: (v) => setState(() => _mgmtExpenseCategory = v ?? 'All'),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                      onPressed: _showAddExpenseTypeDialog,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('تكويد نوع مصروف جديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Table of Expenses
            Expanded(
              child: Card(
                elevation: 2,
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppTheme.charcoal),
                    headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    columns: const [
                      DataColumn(label: Text('الكود')),
                      DataColumn(label: Text('اسم المصروف (عربي)')),
                      DataColumn(label: Text('اسم المصروف (إنجليزي)')),
                      DataColumn(label: Text('التصنيف')),
                      DataColumn(label: Text('وحدة الحساب')),
                      DataColumn(label: Text('العملة الافتراضية')),
                    ],
                    rows: filtered.map((exp) {
                      return DataRow(
                        cells: [
                          DataCell(Text(exp.expenseCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                          DataCell(Text(exp.nameAr, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(exp.nameEn ?? '-')),
                          DataCell(Text(exp.category.split('(').first.trim())),
                          DataCell(Text(exp.defaultUnit)),
                          DataCell(Text(exp.defaultCurrency)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddExpenseTypeDialog() {
    final codeCtrl = TextEditingController();
    final nameArCtrl = TextEditingController();
    final nameEnCtrl = TextEditingController();
    String category = 'Clearance Fees (أتعاب ومصاريف تخليص)';
    String defaultUnit = 'Per Invoice (لكل فاتورة)';
    String currency = 'EGP';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('تكويد نوع مصروف جديد في الدليل', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(labelText: 'كود المصروف (مثال: EXP-CLR-050)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameArCtrl,
                  decoration: const InputDecoration(labelText: 'اسم المصروف بالعربية *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameEnCtrl,
                  decoration: const InputDecoration(labelText: 'اسم المصروف بالإنجليزية (اختياري)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                SearchableDropdownField<String>(
                  value: category,
                  labelText: 'التصنيف',
                  searchHintText: 'ابحث عن التصنيف...',
                  items: const [
                    SearchableDropdownItem(value: 'Clearance Fees (أتعاب ومصاريف تخليص)', label: 'Clearance Fees (أتعاب ومصاريف تخليص)'),
                    SearchableDropdownItem(value: 'Procedures & Approvals (إجراءات وموافقات وفحص)', label: 'Procedures & Approvals (إجراءات وموافقات وفحص)'),
                    SearchableDropdownItem(value: 'Inland Transport (نقل بري وشاحنات)', label: 'Inland Transport (نقل بري وشاحنات)'),
                    SearchableDropdownItem(value: 'Port & Handling (موانئ وتعتيق وتفريغ)', label: 'Port & Handling (موانئ وتعتيق وتفريغ)'),
                    SearchableDropdownItem(value: 'Other Fees (مصاريف أخرى)', label: 'Other Fees (مصاريف أخرى)'),
                  ],
                  onChanged: (v) => setDlgState(() => category = v ?? category),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: defaultUnit,
                        decoration: const InputDecoration(labelText: 'وحدة الحساب الافتراضية', border: OutlineInputBorder()),
                        onChanged: (v) => defaultUnit = v,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SearchableDropdownField<String>(
                        value: currency,
                        labelText: 'العملة الافتراضية',
                        searchHintText: 'ابحث عن العملة...',
                        items: const [
                          SearchableDropdownItem(value: 'EGP', label: 'EGP'),
                          SearchableDropdownItem(value: 'USD', label: 'USD'),
                          SearchableDropdownItem(value: 'EUR', label: 'EUR'),
                        ],
                        onChanged: (v) => setDlgState(() => currency = v ?? 'EGP'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald),
              onPressed: () async {
                final nameAr = nameArCtrl.text.trim();
                if (nameAr.isEmpty) return;
                try {
                  await ref.read(clearanceExpenseTypesProvider.notifier).createExpenseType({
                    'expense_code': codeCtrl.text.trim().isNotEmpty ? codeCtrl.text.trim() : 'EXP-${DateTime.now().millisecondsSinceEpoch % 1000}',
                    'name_ar': nameAr,
                    'name_en': nameEnCtrl.text.trim().isNotEmpty ? nameEnCtrl.text.trim() : null,
                    'category': category,
                    'default_unit': defaultUnit,
                    'default_currency': currency,
                    'display_order': 99,
                    'is_active': true,
                  });
                  if (mounted) Navigator.pop(ctx);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
                }
              },
              child: const Text('حفظ المصروف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }


  void _showPriceListFormDialog({
    BrokerPriceListModel? existingPriceList,
    required List<dynamic> brokersList,
  }) {
    if (brokersList.isEmpty && existingPriceList == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد مخلصين جمركيين مسجلين في الشركاء.'), backgroundColor: Colors.orange),
      );
      return;
    }

    final isEditing = existingPriceList != null;
    int? selectedBroker = existingPriceList?.brokerId ?? (brokersList.isNotEmpty ? brokersList.first.providerId : null);
    final titleCtrl = TextEditingController(text: existingPriceList?.title ?? 'بيان أسعار التخليص والنقل لميناء الإسكندرية لعام 2026');
    final portCtrl = TextEditingController(text: existingPriceList?.portName ?? 'ميناء الإسكندرية والدخيلة');
    final notesCtrl = TextEditingController(text: existingPriceList?.notes ?? '');
    final dateCtrl = TextEditingController(text: existingPriceList?.effectiveFrom ?? DateTime.now().toIso8601String().split('T').first);
    int version = existingPriceList?.version ?? 1;

    // Load items either from existing price list or from master expense catalog
    final catalog = ref.read(clearanceExpenseTypesProvider).value ?? [];
    final List<Map<String, dynamic>> itemsState = [];

    if (isEditing) {
      for (final itm in existingPriceList.items) {
        itemsState.add({
          'item_id': itm.itemId,
          'expense_type_id': itm.expenseTypeId,
          'expense_name': itm.expenseName,
          'category': itm.category,
          'unit_type': itm.unitType,
          'standard_price': itm.standardPrice,
          'currency': itm.currency,
          'min_price': itm.minPrice,
          'max_price': itm.maxPrice,
          'notes': itm.notes ?? '',
          'is_active': itm.isActive,
        });
      }
    } else {
      for (final exp in catalog) {
        itemsState.add({
          'expense_type_id': exp.expenseId,
          'expense_name': exp.nameAr,
          'category': exp.category,
          'unit_type': exp.defaultUnit,
          'standard_price': 0.0,
          'currency': exp.defaultCurrency,
          'min_price': null,
          'max_price': null,
          'notes': '',
          'is_active': true,
        });
      }
    }

    String itemSearchQuery = '';
    String selectedCategoryFilter = 'All';

    final standardRatesMap = <String, double>{
      'أتعاب تخليص LCL': 1250.0,
      'واحد طن LCL مصاريف تخليص': 4750.0,
      'لكل طن زيادة LCL': 1000.0,
      'أتعاب تخليص حاوية 20 قدم': 2500.0,
      'مصاريف تخليص أول حاوية 20 قدم': 7500.0,
      'مصاريف تخليص كل حاوية 20 قدم زيادة': 1500.0,
      'أتعاب تخليص حاوية 40 قدم': 2500.0,
      'مصاريف تخليص أول حاوية 40 قدم': 7500.0,
      'مصاريف تخليص كل حاوية 40 قدم زيادة': 2000.0,
      'بريد - دمغات': 250.0,
      'عرض الواردات + اعتماد الإيلاك': 3000.0,
      'ACID رسوم استخراج وإصدار': 1000.0,
      'زراعة ومهمل وسيل': 1150.0,
      'أمن عام + مندوب الأمن العام + سحب العينات': 1500.0,
      'عرض أمن عام للقاهرة': 5000.0,
      'وثيقة تأمين': 500.0,
      '(X-Ray) عرض إكس راي': 250.0,
      'تطبيق الاتفاقيات التفضيلية': 1000.0,
      'الإفراج تحت التحفظ': 350.0,
      'غسيل جمركي': 250.0,
      'مطافئ': 1000.0,
      'دمغة وموازين': 1000.0,
      'مفرقعات': 1000.0,
      'إفراج نهائي': 500.0,
      'إشعاع': 1000.0,
      'عرض زراعة مشمول': 1500.0,
      'عرض مصلحة الكيمياء': 1500.0,
      'سحب إذن / تصوير / تعديل منافستو': 750.0,
      'مصاريف وزن قماش': 1500.0,
      'إنهاء إجراءات زيادة الوزن': 750.0,
      'سيارة 1 طن (دبابة) إسكندرية - قاهرة': 6150.0,
      'سيارة جامبو حتى 4 طن إسكندرية - قاهرة': 8200.0,
      'سيارة فرداني حتى 7 طن إسكندرية - قاهرة': 14150.0,
      'حاوية 20 قدم حتى 10 طن إسكندرية - قاهرة': 14800.0,
      'حاوية 20 قدم أكثر من 10 طن إسكندرية - قاهرة': 18400.0,
      'حاويتين 20*2 قدم إسكندرية - قاهرة': 23300.0,
      'حاوية 40 قدم إسكندرية - قاهرة': 18400.0,
      'بياتة شاحنة 20*2': 4200.0,
      'بياتة شاحنة 40*1': 3600.0,
      'بياتة شاحنة 20*1': 3000.0,
      'تعتيق ميناء أبوقير': 4250.0,
      'نقل الحاوية للوزن داخل الميناء': 3500.0,
      'كشف عمال وكلارك': 1250.0,
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final filteredItems = itemsState.where((itm) {
            final name = (itm['expense_name'] as String).toLowerCase();
            final cat = (itm['category'] as String);
            final matchSearch = itemSearchQuery.isEmpty || name.contains(itemSearchQuery.toLowerCase());
            final matchCat = selectedCategoryFilter == 'All' || cat == selectedCategoryFilter;
            return matchSearch && matchCat;
          }).toList();

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              width: 950,
              height: 750,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Header
                  Row(
                    children: [
                      Icon(isEditing ? Icons.edit_note : Icons.add_circle, color: AppTheme.cobalt, size: 26),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isEditing ? 'تعديل وتحديث أسعار قائمة المستخلص: ${existingPriceList.title}' : 'إنشاء وتحديد أسعار قائمة جديدة للمستخلص الجمركي',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.charcoal),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, color: Colors.grey),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Header Form Inputs
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.charcoal.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            if (!isEditing)
                              Expanded(
                                flex: 2,
                                child: SearchableDropdownField<int?>(
                                  value: selectedBroker,
                                  labelText: 'المستخلص الجمركي *',
                                  searchHintText: 'ابحث عن المستخلص...',
                                  items: brokersList.map((b) => SearchableDropdownItem<int?>(value: b.providerId, label: b.partnerName)).toList(),
                                  onChanged: (v) => setDlgState(() => selectedBroker = v),
                                ),
                              )
                            else
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade300)),
                                  child: Text('المستخلص: ${existingPriceList.brokerName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: titleCtrl,
                                decoration: const InputDecoration(labelText: 'عنوان قائمة الأسعار *', isDense: true, border: OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: portCtrl,
                                decoration: const InputDecoration(labelText: 'الميناء المعني', isDense: true, border: OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: dateCtrl,
                                decoration: const InputDecoration(labelText: 'تاريخ السريان', isDense: true, border: OutlineInputBorder()),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: notesCtrl,
                          decoration: const InputDecoration(labelText: 'ملاحظات وشروط عامة', isDense: true, border: OutlineInputBorder()),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Table Toolbar: Search, Category Filter & Quick Actions
                  Row(
                    children: [
                      // Search Box
                      SizedBox(
                        width: 220,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'بحث في بنود المصروفات...',
                            prefixIcon: const Icon(Icons.search, size: 16),
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          onChanged: (v) => setDlgState(() => itemSearchQuery = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Category Filter
                      SizedBox(
                        width: 250,
                        child: SearchableDropdownField<String>(
                          value: selectedCategoryFilter,
                          labelText: 'تصفية التصنيف',
                          searchHintText: 'ابحث عن التصنيف...',
                          items: const [
                            SearchableDropdownItem(value: 'All', label: 'جميع التصنيفات'),
                            SearchableDropdownItem(value: 'Clearance Fees (أتعاب ومصاريف تخليص)', label: 'أتعاب ومصاريف تخليص'),
                            SearchableDropdownItem(value: 'Procedures & Approvals (إجراءات وموافقات وفحص)', label: 'إجراءات وموافقات وفحص'),
                            SearchableDropdownItem(value: 'Inland Transport (نقل بري وشاحنات)', label: 'نقل بري وشاحنات'),
                            SearchableDropdownItem(value: 'Port & Handling (موانئ وتعتيق وتفريغ)', label: 'موانئ وتعتيق وتفريغ'),
                            SearchableDropdownItem(value: 'Other Fees (مصاريف أخرى)', label: 'مصاريف أخرى'),
                          ],
                          onChanged: (v) => setDlgState(() => selectedCategoryFilter = v ?? 'All'),
                        ),
                      ),
                      const Spacer(),
                      // Quick Fill Button
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(foregroundColor: AppTheme.cobalt),
                        onPressed: () {
                          setDlgState(() {
                            for (var itm in itemsState) {
                              final name = itm['expense_name'] as String;
                              for (var entry in standardRatesMap.entries) {
                                if (name.contains(entry.key) || entry.key.contains(name)) {
                                  itm['standard_price'] = entry.value;
                                  break;
                                }
                              }
                            }
                          });
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('⚡ تم استدعاء وتعبئة الأسعار الاسترشادية القياسية المصرية بنجاح!'), backgroundColor: AppTheme.cobalt),
                          );
                        },
                        icon: const Icon(Icons.flash_on, size: 14),
                        label: const Text('تعبئة بالأسعار الاسترشادية', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 6),
                      // Zero Out Button
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade800),
                        onPressed: () {
                          setDlgState(() {
                            for (var itm in itemsState) {
                              itm['standard_price'] = 0.0;
                            }
                          });
                        },
                        icon: const Icon(Icons.clear_all, size: 14),
                        label: const Text('تصفير الكل', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Interactive Items Table
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: ListView.separated(
                          itemCount: filteredItems.length,
                          separatorBuilder: (ctx, idx) => Divider(height: 1, color: Colors.grey.shade200),
                          itemBuilder: (ctx, idx) {
                            final itm = filteredItems[idx];
                            final realIdx = itemsState.indexOf(itm);
                            final standardPrice = (itm['standard_price'] as num?)?.toDouble() ?? 0.0;

                            return Container(
                              color: idx.isEven ? Colors.white : Colors.grey.shade50,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: Row(
                                children: [
                                  // Item Name & Category
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          itm['expense_name'],
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal),
                                        ),
                                        Text(
                                          '${(itm['category'] as String).split('(').first.trim()} | ${itm['unit_type']}',
                                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Standard Price Input
                                  SizedBox(
                                    width: 130,
                                    child: TextFormField(
                                      key: ValueKey('dlg_price_${itm['expense_type_id']}_$standardPrice'),
                                      initialValue: standardPrice == 0.0 ? '' : standardPrice.toString(),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(
                                        labelText: 'السعر المعتمد *',
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      ),
                                      onChanged: (v) {
                                        final p = double.tryParse(v) ?? 0.0;
                                        itemsState[realIdx]['standard_price'] = p;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Currency Dropdown
                                  SizedBox(
                                    width: 85,
                                    child: DropdownButtonFormField<String>(
                                      value: itm['currency'] ?? 'EGP',
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: 'EGP', child: Text('EGP', style: TextStyle(fontSize: 11))),
                                        DropdownMenuItem(value: 'USD', child: Text('USD', style: TextStyle(fontSize: 11))),
                                        DropdownMenuItem(value: 'EUR', child: Text('EUR', style: TextStyle(fontSize: 11))),
                                      ],
                                      onChanged: (v) => setDlgState(() => itemsState[realIdx]['currency'] = v ?? 'EGP'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Notes / Min-Max Input
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      key: ValueKey('dlg_notes_${itm['expense_type_id']}'),
                                      initialValue: itm['notes'] ?? '',
                                      decoration: const InputDecoration(
                                        labelText: 'ملاحظات / نطاق السعر',
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      ),
                                      onChanged: (v) => itemsState[realIdx]['notes'] = v,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Actions Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'إجمالي بنود المصروفات بالقائمة: ${itemsState.length} بند (${itemsState.where((i) => (i['standard_price'] as num) > 0).length} بند مسعر بقيمة)',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('إلغاء'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.emerald,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            onPressed: () async {
                              final title = titleCtrl.text.trim();
                              if (title.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('يرجى كتابة عنوان قائمة الأسعار.'), backgroundColor: Colors.red),
                                );
                                return;
                              }

                              final broker = brokersList.firstWhere(
                                (element) => element.providerId == selectedBroker,
                                orElse: () => null,
                              );
                              final brokerName = broker?.partnerName ?? (existingPriceList?.brokerName ?? 'مستخلص');

                              final itemsPayload = itemsState.map((itm) => {
                                if (itm['item_id'] != null) 'item_id': itm['item_id'],
                                'expense_type_id': itm['expense_type_id'],
                                'expense_name': itm['expense_name'],
                                'category': itm['category'],
                                'unit_type': itm['unit_type'],
                                'standard_price': itm['standard_price'],
                                'currency': itm['currency'],
                                'min_price': itm['min_price'],
                                'max_price': itm['max_price'],
                                'notes': itm['notes'],
                                'is_active': itm['is_active'] ?? true,
                              }).toList();

                              try {
                                if (isEditing) {
                                  await ref.read(brokerPriceListsProvider.notifier).updatePriceList(
                                    existingPriceList.priceListId,
                                    {
                                      'title': title,
                                      'port_name': portCtrl.text.trim(),
                                      'effective_from': dateCtrl.text.trim(),
                                      'version': version,
                                      'is_active': existingPriceList.isActive,
                                      'notes': notesCtrl.text.trim(),
                                      'items': itemsPayload,
                                    },
                                  );
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('✅ تم تحديث وتعديل أسعار القائمة بنجاح!'), backgroundColor: AppTheme.emerald),
                                    );
                                  }
                                } else {
                                  if (selectedBroker == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('الرجاء اختيار المستخلص الجمركي'), backgroundColor: Colors.orange),
                                    );
                                    return;
                                  }
                                  await ref.read(brokerPriceListsProvider.notifier).createPriceList({
                                    'title': title,
                                    'broker_id': selectedBroker,
                                    'broker_name': brokerName,
                                    'port_name': portCtrl.text.trim(),
                                    'effective_from': dateCtrl.text.trim(),
                                    'version': 1,
                                    'is_active': true,
                                    'notes': notesCtrl.text.trim(),
                                    'items': itemsPayload,
                                  });
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('✅ تم إنشاء قائمة أسعار المخلص وحفظ الأسعار بنجاح!'), backgroundColor: AppTheme.emerald),
                                    );
                                  }
                                }
                                if (mounted) Navigator.pop(ctx);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('خطأ أثناء الحفظ: $e'), backgroundColor: Colors.red),
                                );
                              }
                            },
                            icon: const Icon(Icons.save, color: Colors.white, size: 18),
                            label: Text(
                              isEditing ? 'حفظ تعديلات القائمة' : 'إنشاء وحفظ قائمة الأسعار',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildMetricBadge(String title, String value, Color color, {VoidCallback? onTap}) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                Icon(Icons.open_in_new, size: 12, color: color),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: badge,
      );
    }
    return badge;
  }

  /// Interactive Modal to review and correct Blocking Clearance Issues
  void _showBlockingIssuesDialog() {
    final blockingItems = _checklist.where((i) => i.isBlockingShipment && i.status != 'Approved').toList();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.crimson, width: 1.5),
              ),
              titlePadding: EdgeInsets.zero,
              title: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  color: AppTheme.crimson,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.block, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'شاشة فحص وتصحيح عوائق التخليص الجمركي (${blockingItems.length} عائق)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              content: SizedBox(
                width: 720,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: AppTheme.crimson, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'هذه المستندات والاشتراطات مصنفة كـ (Blocking) ولا يمكن الإفراج عن الشحنة بدون استيفائها أو اعتمادها من المستخلص/الجهة الرقابية.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.charcoal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (blockingItems.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              '🎉 تم استيفاء واعتماد كافة عوائق التخليص بنجاح!',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald),
                            ),
                          ),
                        )
                      else
                        ...blockingItems.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
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
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.crimson.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'عائق ${idx + 1}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          color: AppTheme.crimson,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        item.documentType,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.5,
                                          color: AppTheme.charcoal,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'الحالة: ${item.status}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          color: Colors.orange.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'الجهة المعنية / المتطلب: ${item.requiredText} | الجهة المصدرة: ${item.regulatoryAgency ?? "غير محدد"}',
                                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                                ),
                                if (item.remarks != null && item.remarks!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'ملاحظات: ${item.remarks}',
                                    style: const TextStyle(fontSize: 11.5, color: Colors.blueGrey, fontStyle: FontStyle.italic),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.emerald,
                                        side: const BorderSide(color: AppTheme.emerald),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      ),
                                      icon: const Icon(Icons.check_circle_outline, size: 16),
                                      label: const Text('اعتماد واستيفاء البند الآن (Mark as Approved)', style: TextStyle(fontSize: 11.5)),
                                      onPressed: () {
                                        setState(() {
                                          final realIndex = _checklist.indexWhere((c) => c.documentType == item.documentType);
                                          if (realIndex != -1) {
                                            _checklist[realIndex] = _checklist[realIndex].copyWith(
                                              status: 'Approved',
                                              verifiedDate: DateTime.now().toString().split(' ')[0],
                                            );
                                          }
                                        });
                                        setModalState(() {
                                          blockingItems.removeWhere((i) => i.documentType == item.documentType);
                                        });
                                      },
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
              actions: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.cobalt,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text('تم الانتهاء والعودة للنموذج'),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = Colors.grey;
    if (status == 'Clearance Ready') bg = Colors.green;
    if (status == 'Blocked') bg = Colors.red;
    if (status == 'Action Required') bg = Colors.orange;
    if (status == 'In Progress') bg = Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(color: bg, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _buildDocItemStatusBadge(String status) {
    Color bg = Colors.grey;
    if (status == 'Approved') bg = Colors.green;
    if (status == 'Rejected') bg = Colors.red;
    if (status == 'Verified') bg = Colors.blue;
    if (status == 'Received') bg = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
      child: Text(status, style: TextStyle(color: bg, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }
}
