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
import '../widgets/add_checklist_item_dialog.dart';
import '../widgets/add_custom_broker_expense_row_dialog.dart';
import '../widgets/consultation_metric_badge.dart';
import '../widgets/consultation_status_badges.dart';
import '../widgets/post_save_status_dialog.dart';

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

  void _addChecklistItem() async {
    final newItem = await showDialog<CustomsChecklistItemModel>(
      context: context,
      builder: (context) => const AddChecklistItemDialog(),
    );
    if (newItem != null) {
      setState(() {
        _checklist.add(newItem);
      });
    }
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

  void _addCustomBrokerExpenseRow() async {
    final newItem = await showDialog<CustomsBrokerQuoteItemModel>(
      context: context,
      builder: (context) => const AddCustomBrokerExpenseRowDialog(),
    );
    if (newItem != null) {
      setState(() {
        _brokerQuoteItems.add(newItem);
        _calculateBrokerQuote();
      });
    }
  }

  Widget ConsultationStatusBadge(status: String status) {
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

  Widget ConsultationDocStatusBadge(status: String status) {
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
