import '../widgets/broker_quote_details_card.dart';
import '../widgets/blocking_issues_dialog.dart';
import '../widgets/broker_price_lists_tab.dart';
import '../widgets/saved_consultations_tab.dart';
import '../widgets/nafeza_fee_breakdown_card.dart';
import '../widgets/consultation_details_dialog.dart';
import '../widgets/post_save_status_dialog.dart';
import '../widgets/consultation_metric_badge.dart';
import '../widgets/add_checklist_item_dialog.dart';
import '../widgets/add_custom_expense_dialog.dart';
import '../widgets/recalculation_variance_comparison_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/change_diff_dialog.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/error_details_dialog.dart';
import '../../../core/widgets/vertical_stage_scaffold.dart';
import '../../currencies/models/currency_model.dart';
import '../../currencies/providers/currencies_provider.dart';
import '../../customs_clearance_quotations/screens/customs_clearance_quotations_screen.dart';
import '../../customs_tariff/models/customs_tariff_model.dart';
import '../../customs_tariff/providers/customs_tariff_provider.dart';
import '../../external_service_providers/providers/partners_provider.dart';
import '../../import_files/models/import_file_model.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../../projects/providers/projects_provider.dart';
import '../../purchase_orders/models/purchase_order_model.dart';
import '../../purchase_orders/providers/purchase_orders_provider.dart';
import '../models/customs_consultation_model.dart';
import '../providers/customs_consultation_provider.dart';
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
  final bool isTaxReviewMode;
  const CustomsConsultationScreen({
    super.key,
    this.initialIndex = 0,
    this.isTaxReviewMode = false,
  });

  @override
  ConsumerState<CustomsConsultationScreen> createState() => _CustomsConsultationScreenState();
}

class _CustomsConsultationScreenState extends ConsumerState<CustomsConsultationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form State
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _estimatedDutiesController = TextEditingController(text: '0.0');

  // Customs Calculator State Controllers
  final TextEditingController _exchangeRateController = TextEditingController(text: '50.0');
  final TextEditingController _freightEgpController = TextEditingController(text: '0.0');
  final TextEditingController _insuranceEgpController = TextEditingController(text: '0.0');
  String _customsCurrency = 'USD';
  bool _isCustomsCalculatorExpanded = true;

  // Customs Recalculation & Forecast Variance State
  CustomsRecalculationResponseModel? _recalculationResult;
  bool _isRecalculating = false;
  DateTime _studyDate = DateTime.now();

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

  bool _isSaving = false;

  // History Tab Filter State

  bool _hasCustomTitle = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    final tabCount = widget.isTaxReviewMode ? 2 : 4;
    final initialIdx = widget.initialIndex < tabCount ? widget.initialIndex : 0;
    _tabController = TabController(length: tabCount, vsync: this, initialIndex: initialIdx);
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
      if (!widget.isTaxReviewMode) {
        ref.read(clearanceExpenseTypesProvider.notifier).fetchExpenseTypes();
        ref.read(brokerPriceListsProvider.notifier).fetchPriceLists();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasCustomTitle && _editingConsultationId == null) {
      final l = context.l10n;
      _titleController.text = widget.isTaxReviewMode
          ? l.defaultTaxReviewSessionTitle
          : l.defaultCustomsConsultationTitle;
    }
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
        documentType: 'Proforma Invoice',
        isRequired: true,
        isBlockingShipment: true,
        responsibleParty: 'Supplier / Exporter',
        status: 'Approved',
        remarks: 'الفاتورة المبدئية معتمدة ومطابقة للبند الجمركي.',
      ),
      CustomsChecklistItemModel(
        documentType: 'Packing List',
        isRequired: true,
        isBlockingShipment: true,
        responsibleParty: 'Supplier / Exporter',
        status: 'Approved',
        remarks: 'محدثة بإجمالي الأوزان الأحجام والطرود.',
      ),
      CustomsChecklistItemModel(
        documentType: 'Certificate of Origin',
        isRequired: true,
        isBlockingShipment: true,
        responsibleParty: 'Customs Broker',
        status: 'Pending',
        remarks: 'مطلوب توثيق السفارة والغرفة التجارية.',
      ),
      CustomsChecklistItemModel(
        documentType: 'GOEIC Inspection',
        isRequired: true,
        isBlockingShipment: true,
        responsibleParty: 'Customs Broker',
        regulatoryAgency: 'GOEIC',
        status: 'Pending',
        remarks: 'يتطلب فحص ظاهري وعينات المعمل فور الوصول.',
      ),
      CustomsChecklistItemModel(
        documentType: 'NTRA Telecommunications Approval',
        isRequired: false,
        isBlockingShipment: false,
        responsibleParty: 'Importer Team',
        regulatoryAgency: 'NTRA',
        status: 'Pending',
        remarks: 'تنطبق في حال وجود وحدات تحكم لاسلكية.',
      ),
    ]);
  }

  String _getLocalizedDocType(String docType, bool isArabic) {
    if (!isArabic) return docType;
    switch (docType) {
      case 'Proforma Invoice':
        return 'الفاتورة المبدئية';
      case 'Packing List':
        return 'بيان التعبئة';
      case 'Certificate of Origin':
        return 'شهادة المنشأ';
      case 'GOEIC Inspection':
        return 'فحص هيئة الرقابة على الصادرات والواردات (GOEIC)';
      case 'NTRA Telecommunications Approval':
        return 'موافقة الجهاز القومي لتنظيم الاتصالات (NTRA)';
      default:
        return docType;
    }
  }

  String _getLocalizedRemarks(String? remarks, bool isArabic) {
    if (remarks == null || remarks.isEmpty) return '';
    if (!isArabic) {
      if (remarks.contains('الفاتورة المبدئية')) return 'Proforma invoice approved and matches customs tariff HS code.';
      if (remarks.contains('محدثة بإجمالي')) return 'Updated with total weights, volumes, and package quantities.';
      if (remarks.contains('توثيق السفارة')) return 'Embassy and chamber of commerce authentication required.';
      if (remarks.contains('فحص ظاهري')) return 'Visual inspection and laboratory sampling required upon arrival.';
      if (remarks.contains('تنطبق في حال وجود وحدات تحكم')) return 'Applies in case wireless remote control modules exist.';
    } else {
      if (remarks.contains('Proforma invoice approved')) return 'الفاتورة المبدئية معتمدة ومطابقة للبند الجمركي.';
      if (remarks.contains('Updated with total weights')) return 'محدثة بإجمالي الأوزان والأحجام والطرود.';
      if (remarks.contains('Embassy and chamber of commerce')) return 'مطلوب توثيق السفارة والغرفة التجارية.';
      if (remarks.contains('Visual inspection and laboratory')) return 'يتطلب فحص ظاهري وعينات المعمل فور الوصول.';
      if (remarks.contains('Applies in case wireless')) return 'تنطبق في حال وجود وحدات تحكم لاسلكية.';
    }
    return remarks;
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

    // Auto-update estimated duties controller
    final calcLines = _calculateCustomsLines();
    final double totalTaxes = calcLines.fold(0.0, (s, l) => s + l.totalTaxesAndDutiesEgp);
    if (totalTaxes > 0) {
      _estimatedDutiesController.text = totalTaxes.toStringAsFixed(2);
    }
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
    // One checklist item per document type, listing unique HS Codes inside.
    final acidHsCodes =
        calcLines.where((l) => l.requiresAcid).map((l) => l.hsCode).toSet().toList();
    final cooHsCodes =
        calcLines.where((l) => l.requiresCoo).map((l) => l.hsCode).toSet().toList();
    final goeicHsCodes =
        calcLines.where((l) => l.requiresInspection).map((l) => l.hsCode).toSet().toList();

    // Group unique HS Codes per regulatory authority
    final Map<String, Set<String>> authHsMap = {};
    for (final line in calcLines) {
      if (line.regulatoryAuthority != null &&
          line.regulatoryAuthority!.trim().isNotEmpty) {
        authHsMap
            .putIfAbsent(line.regulatoryAuthority!, () => <String>{})
            .add(line.hsCode);
      }
    }

    int addedCount = 0;

    // Helper to format HS Codes nicely for display
    String formatHsCodeList(List<String> list) {
      if (list.isEmpty) return '';
      if (list.length <= 2) return list.join(' | ');
      return '${list.take(2).join(" | ")} (+${list.length - 2})';
    }

    // 1. ACID — one consolidated item for the entire shipment
    if (acidHsCodes.isNotEmpty) {
      const docName = 'قيد رقم ACID المسبق للشحنة الكاملة (Nafeza / CargoX)';
      final hasExisting = _checklist.any((c) => c.documentType == docName);
      if (!hasExisting) {
        _checklist.add(CustomsChecklistItemModel(
          documentType: docName,
          hsCode: formatHsCodeList(acidHsCodes),
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
          hsCode: formatHsCodeList(cooHsCodes),
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
          hsCode: formatHsCodeList(goeicHsCodes),
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
      final hsList = entry.value.toList();
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
          hsCode: formatHsCodeList(hsList),
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
      final l = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ ${l.hsRequirementsSyncedToast(calcLines.length, addedCount)}',
          ),
          backgroundColor: AppTheme.emerald,
        ),
      );
    }
  }

  Future<void> _fetchReconciledFinalInvoiceAndRecalculate() async {
    final l = context.l10n;
    if (_selectedImportFileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ ${l.selectImportFileFirstToast}'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isRecalculating = true);
    try {
      final fx = double.tryParse(_exchangeRateController.text.trim());
      final freight = double.tryParse(_freightEgpController.text.trim());
      final ins = double.tryParse(_insuranceEgpController.text.trim());
      final dateStr = '${_studyDate.year}-${_studyDate.month.toString().padLeft(2, '0')}-${_studyDate.day.toString().padLeft(2, '0')}';

      final res = await ref.read(customsConsultationsProvider.notifier).recalculateFromReconciliation(
        importFileId: _selectedImportFileId!,
        exchangeRate: fx,
        freightEgp: freight,
        insuranceEgp: ins,
        estimateDate: dateStr,
      );

      setState(() {
        _recalculationResult = res;
        _isCustomsCalculatorExpanded = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    res.isReconciled
                        ? '✅ (${res.finalInvoiceNumber ?? ""})'
                        : 'ℹ️',
                  ),
                ),
              ],
            ),
            backgroundColor: res.isReconciled ? AppTheme.emerald : AppTheme.cobalt,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $e'),
            backgroundColor: AppTheme.crimson,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRecalculating = false);
      }
    }
  }

  void _applyAndSaveRecalculatedFees() {
    if (_recalculationResult == null) return;
    setState(() {
      _estimatedDutiesController.text = _recalculationResult!.finalTotalTaxesEgp.toStringAsFixed(2);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '💾 تم اعتماد وتطبيق قيمة الرسوم الجمركية والضرائب الجديدة (${_recalculationResult!.finalTotalTaxesEgp.toStringAsFixed(2)} EGP). يمكنك الآن حفظ أو تحديث الدراسة الجمركية.',
        ),
        backgroundColor: AppTheme.emerald,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  List<CustomsItemCalcRow> _calculateCustomsLines() {
    final loc = context.l10n;
    final allPOs = ref.watch(purchaseOrdersProvider).purchaseOrders;
    final tariffsList = ref.watch(customsTariffProvider).value ?? [];

    ImportFileModel? file;
    List<PurchaseOrderModel> matchingPOs = [];
    if (_selectedImportFileId != null) {
      final importFiles = ref.watch(importFilesProvider).value ?? [];
      file = importFiles.where((f) => f.importFileId == _selectedImportFileId).firstOrNull;
      if (file != null) {
        matchingPOs = allPOs.where((p) =>
            (p.importFileId != null && p.importFileId == file!.importFileId) ||
            (file!.importFileCode.isNotEmpty && p.importFileCode != null && p.importFileCode == file!.importFileCode) ||
            (file!.poIds != null && p.poId != null && file!.poIds!.contains(p.poId))).toList();
      }
    } else if (_selectedPoId != null) {
      matchingPOs = allPOs.where((p) => p.poId == _selectedPoId).toList();
    }

    final double exchangeRate = double.tryParse(_exchangeRateController.text.trim()) ?? 50.0;
    final double totalFreightEgp = double.tryParse(_freightEgpController.text.trim()) ?? 0.0;
    final double totalInsuranceEgp = double.tryParse(_insuranceEgpController.text.trim()) ?? 0.0;

    // 1. Calculate Aggregate Total of ALL Invoices attached to the Import File
    double totalInvoicesForeign = 0.0;
    if (file != null && file.invoicesData.isNotEmpty) {
      for (final inv in file.invoicesData) {
        totalInvoicesForeign += inv.amount;
      }
    }

    // 2. Collect all line items paired with their parent PO
    final List<Map<String, dynamic>> flatLineEntries = [];
    for (final po in matchingPOs) {
      for (final item in po.items) {
        flatLineEntries.add({
          'item': item,
          'po': po,
        });
      }
    }

    // Pre-index tariffs for instant O(1) lookups
    final Map<int, CustomsTariffModel> tariffById = {
      for (final t in tariffsList) t.tariffId: t,
    };
    final Map<String, CustomsTariffModel> tariffByNormalizedHs = {
      for (final t in tariffsList) t.hsCode.replaceAll('.', '').trim(): t,
    };

    // Case A: No PO Line items, but Invoices exist on the Import File
    if (flatLineEntries.isEmpty) {
      if (totalInvoicesForeign > 0 && file != null) {
        final List<CustomsItemCalcRow> result = [];
        final int invCount = file.invoicesData.length;
        for (int i = 0; i < invCount; i++) {
          final inv = file.invoicesData[i];
          final double invForeign = inv.amount;
          final double fobEgp = invForeign * exchangeRate;
          final double freightShare = invCount > 0 ? (totalFreightEgp / invCount) : 0.0;
          final double insuranceShare = invCount > 0 ? (totalInsuranceEgp / invCount) : 0.0;
          final double cifEgp = fobEgp + freightShare + insuranceShare;

          final double effectiveDutyRate = 5.0;
          final double dutyAmountEgp = cifEgp * (effectiveDutyRate / 100.0);
          final double vatRate = 14.0;
          final double vatBaseEgp = cifEgp + dutyAmountEgp;
          final double vatAmountEgp = vatBaseEgp * (vatRate / 100.0);
          final double svcRate = 1.0;
          final double svcAmountEgp = cifEgp * (svcRate / 100.0);
          final double totalLineTaxes = dutyAmountEgp + vatAmountEgp + svcAmountEgp;

          result.add(CustomsItemCalcRow(
            hsCode: '8479.89.90',
            description: 'Commercial Invoice #${inv.invoiceNo} (${file.supplierName})',
            qty: 1,
            unit: 'SET',
            foreignPrice: invForeign,
            fobEgp: fobEgp,
            freightEgp: freightShare,
            insuranceEgp: insuranceShare,
            cifEgp: cifEgp,
            dutyRate: effectiveDutyRate,
            baseDutyRate: effectiveDutyRate,
            dutyAmountEgp: dutyAmountEgp,
            vatRate: vatRate,
            vatBaseEgp: vatBaseEgp,
            vatAmountEgp: vatAmountEgp,
            scheduleTaxRate: 0.0,
            scheduleTaxAmountEgp: 0.0,
            developmentFeeRate: 0.0,
            developmentFeeAmountEgp: 0.0,
            customsServiceFeeRate: svcRate,
            customsServiceFeeAmountEgp: svcAmountEgp,
            totalTaxesAndDutiesEgp: totalLineTaxes,
            requiresCoo: true,
            requiresInspection: false,
            requiresAcid: true,
            regulatoryAuthority: null,
            priorApprovalNote: null,
            countryOfOrigin: null,
            appliedAgreementName: null,
            hasExemption: false,
            exemptionConditionsNote: null,
            requiredDocument: null,
          ));
        }
        return result;
      }
      return [];
    }

    // Case B: PO Line items exist -> Scale proportionally to Total Invoices if Invoices exist
    final double poItemsFobSum = flatLineEntries.fold(0.0, (s, e) => s + (e['item'] as POLineItemModel).totalPrice);
    final double effectiveFobForeign = totalInvoicesForeign > 0 ? totalInvoicesForeign : poItemsFobSum;
    final double totalFobEgp = effectiveFobForeign * exchangeRate;
    final double scaleFactor = (totalInvoicesForeign > 0 && poItemsFobSum > 0) ? (totalInvoicesForeign / poItemsFobSum) : 1.0;

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
      
      // Match tariff via O(1) lookup
      CustomsTariffModel? matchedTariff;
      if (l.tariffId != null) {
        matchedTariff = tariffById[l.tariffId];
      }
      if (matchedTariff == null && hs != 'UNASSIGNED') {
        matchedTariff = tariffByNormalizedHs[hs.replaceAll('.', '').trim()];
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
          appliedAgreementName = loc.agreementEur1;
          requiredDocument = loc.agreementEur1Doc;
          effectiveDutyRate = 0.0;
          exemptionConditionsNote = loc.agreementEur1Exemption(baseDutyRate);
        } else if (mercosurCountries.contains(originCode)) {
          hasExemption = true;
          appliedAgreementName = loc.agreementMercosur;
          requiredDocument = loc.agreementMercosurDoc;
          effectiveDutyRate = 0.0;
          exemptionConditionsNote = loc.agreementMercosurExemption(baseDutyRate);
        } else if (gaftaCountries.contains(originCode)) {
          hasExemption = true;
          appliedAgreementName = loc.agreementGafta;
          requiredDocument = loc.agreementGaftaDoc;
          effectiveDutyRate = 0.0;
          exemptionConditionsNote = loc.agreementGaftaExemption(baseDutyRate);
        } else if (originCode == 'TR') {
          hasExemption = true;
          appliedAgreementName = loc.agreementTurkey;
          requiredDocument = loc.agreementTurkeyDoc;
          effectiveDutyRate = 0.0;
          exemptionConditionsNote = loc.agreementTurkeyExemption(baseDutyRate);
        } else if (originCode == 'GB' || originCode == 'UK') {
          hasExemption = true;
          appliedAgreementName = loc.agreementUk;
          requiredDocument = loc.agreementUkDoc;
          effectiveDutyRate = 0.0;
          exemptionConditionsNote = loc.agreementUkExemption(baseDutyRate);
        }
      }

      final double vatRate = matchedTariff?.vatRate ?? (l.vatRate ?? 14.0);
      final double scheduleTaxRate = matchedTariff?.scheduleTaxRate ?? 0.0;
      final double devRate = matchedTariff?.developmentFeeRate ?? 0.0;
      final double svcRate = matchedTariff?.customsServiceFeeRate ?? 1.0;

      final double lineForeignPrice = l.totalPrice * scaleFactor;
      final double fobEgp = lineForeignPrice * exchangeRate;
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
        description: l.descriptionAr.isNotEmpty ? l.descriptionAr : (matchedTariff?.hsDescription ?? loc.defaultImportItemDescription),
        qty: l.quantity,
        unit: l.unitOfMeasure,
        foreignPrice: lineForeignPrice,
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
      builder: (context) => AddChecklistItemDialog(
        onItemAdded: (item) {
          setState(() => _checklist.add(item));
        },
      ),
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

      if (!mounted) return;
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
        final l = context.l10n;
        setState(() {
          _brokerPriceListId = null;
          _brokerPriceListTitle = l.customPriceListNoRegisteredTitle;
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
    showDialog(
      context: context,
      builder: (ctx) => AddCustomExpenseDialog(
        onExpenseAdded: (item) {
          setState(() => _brokerQuoteItems.add(item));
        },
      ),
    );
  }

  void _applyExtractedQuotationToConsultation(Map<String, dynamic> extracted) {
    final l = context.l10n;
    setState(() {
      // 1. Try to match and select broker if name matches partners
      final brokerName = extracted['broker_name']?.toString().toLowerCase() ?? '';
      if (brokerName.isNotEmpty) {
        final partners = ref.read(partnersProvider).value ?? [];
        final matchedPartner = partners.where((p) =>
            p.partnerName.toLowerCase().contains(brokerName) ||
            brokerName.contains(p.partnerName.toLowerCase())).firstOrNull;
        if (matchedPartner != null) {
          _selectedBrokerId = matchedPartner.partnerId;
          _selectedBrokerName = matchedPartner.partnerName;
        }
      }

      // 2. Add or update items in _brokerQuoteItems
      void upsertQuoteItem(String name, String category, double amount) {
        if (amount <= 0) return;
        final existingIdx = _brokerQuoteItems.indexWhere((i) => i.expenseName.contains(name) || i.category.contains(category));
        if (existingIdx != -1) {
          final itm = _brokerQuoteItems[existingIdx];
          _brokerQuoteItems[existingIdx] = itm.copyWith(
            unitPrice: amount,
            qty: 1.0,
            isApplicable: true,
            totalAmount: amount,
          );
        } else {
          _brokerQuoteItems.add(CustomsBrokerQuoteItemModel(
            expenseName: name,
            category: category,
            unitType: 'Fixed',
            unitPrice: amount,
            currency: 'EGP',
            qty: 1.0,
            isApplicable: true,
            totalAmount: amount,
          ));
        }
      }

      final clearanceFee = (extracted['clearance_fee'] is num) ? (extracted['clearance_fee'] as num).toDouble() : (double.tryParse(extracted['clearance_fee']?.toString() ?? '') ?? 0.0);
      final inlandFee = (extracted['inland_transport_fee'] is num) ? (extracted['inland_transport_fee'] as num).toDouble() : (double.tryParse(extracted['inland_transport_fee']?.toString() ?? '') ?? 0.0);
      final inspectionFee = (extracted['inspection_fee'] is num) ? (extracted['inspection_fee'] as num).toDouble() : (double.tryParse(extracted['inspection_fee']?.toString() ?? '') ?? 0.0);
      final portExp = (extracted['port_expenses'] is num) ? (extracted['port_expenses'] as num).toDouble() : (double.tryParse(extracted['port_expenses']?.toString() ?? '') ?? 0.0);
      final miscFee = (extracted['miscellaneous_fee'] is num) ? (extracted['miscellaneous_fee'] as num).toDouble() : (double.tryParse(extracted['miscellaneous_fee']?.toString() ?? '') ?? 0.0);

      upsertQuoteItem('Clearance Fees', 'Clearance Agency Fees', clearanceFee);
      upsertQuoteItem('Inland Transport', 'Inland Transportation', inlandFee);
      upsertQuoteItem('Customs Inspection', 'Customs Inspection', inspectionFee);
      upsertQuoteItem('Port & Handling', 'Port & Terminal', portExp);
      upsertQuoteItem('Other Fees', 'Miscellaneous', miscFee);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✔ ${l.brokerQuoteExtractedToast(extracted['broker_name'] ?? l.defaultCustomsBrokerName)}'),
        backgroundColor: AppTheme.emerald,
      ),
    );
  }

  Future<void> _saveConsultation() async {
    final l = context.l10n;
    final validationErrors = <ValidationIssueItem>[];

    final titleToSave = _titleController.text.trim();
    if (titleToSave.isEmpty) {
      validationErrors.add(ValidationIssueItem(
        fieldName: l.consultationTitleFieldValidation,
        issueDescription: l.consultationTitleFieldIssue,
        recommendation: l.consultationTitleFieldRec,
        isBlocking: true,
      ));
    }

    if (!widget.isTaxReviewMode && _selectedBrokerId == null) {
      validationErrors.add(ValidationIssueItem(
        fieldName: l.customsBrokerFieldValidation,
        issueDescription: l.customsBrokerFieldIssue,
        recommendation: l.customsBrokerFieldRec,
        isBlocking: true,
      ));
    }

    if (!widget.isTaxReviewMode && _checklist.isEmpty) {
      validationErrors.add(ValidationIssueItem(
        fieldName: l.checklistFieldValidation,
        issueDescription: l.checklistFieldIssue,
        recommendation: l.checklistFieldRec,
        isBlocking: true,
      ));
    }

    if (validationErrors.isNotEmpty) {
      await showErrorDetailsDialog(
        context,
        title: '⚠️ ${l.customsStudyValidationAlertsTitle}',
        error: l.completeRequiredDataErrorMsg,
        validationIssues: validationErrors,
      );
      return;
    }

    final estimatedDuties = double.tryParse(_estimatedDutiesController.text.trim()) ?? 0.0;
    final totalBrokerFees = widget.isTaxReviewMode ? 0.0 : _brokerQuoteItems.fold(0.0, (sum, itm) => sum + (itm.isApplicable ? itm.totalAmount : 0.0));

    // Change Diff Confirmation Dialog for Edits
    if (_editingConsultationId != null) {
      final oldConsultation = (ref.read(customsConsultationsProvider).value ?? [])
          .where((c) => c.consultationId == _editingConsultationId)
          .firstOrNull;

      if (oldConsultation != null) {
        final List<FieldChangeItem> changes = [];

        if (FieldChangeItem.isDifferent(oldConsultation.title, titleToSave)) {
          changes.add(FieldChangeItem(
            section: l.diffSectionGeneralData,
            fieldName: l.titleField,
            oldValue: oldConsultation.title,
            newValue: titleToSave,
          ));
        }

        if (FieldChangeItem.isDifferent(oldConsultation.brokerName, _selectedBrokerName)) {
          changes.add(FieldChangeItem(
            section: l.diffSectionCustomsBroker,
            fieldName: l.customsBrokerFieldValidation,
            oldValue: oldConsultation.brokerName,
            newValue: _selectedBrokerName,
          ));
        }

        if (FieldChangeItem.isDifferent(oldConsultation.estimatedDutiesEgp, estimatedDuties)) {
          changes.add(FieldChangeItem(
            section: l.diffSectionFinancialEstimates,
            fieldName: l.diffFieldEstimatedDuties,
            oldValue: '${oldConsultation.estimatedDutiesEgp.toStringAsFixed(2)} EGP',
            newValue: '${estimatedDuties.toStringAsFixed(2)} EGP',
          ));
        }

        if (FieldChangeItem.isDifferent(oldConsultation.importFileId, _selectedImportFileId)) {
          changes.add(FieldChangeItem(
            section: l.diffSectionOperationalLink,
            fieldName: l.diffFieldLinkedImportFile,
            oldValue: oldConsultation.importFileCode ?? (oldConsultation.importFileId != null ? 'ID: ${oldConsultation.importFileId}' : null),
            newValue: _selectedImportFileId != null ? 'ID: $_selectedImportFileId' : null,
          ));
        }

        if (FieldChangeItem.isDifferent(oldConsultation.checklistItems.length, _checklist.length)) {
          changes.add(FieldChangeItem(
            section: l.diffSectionChecklist,
            fieldName: l.diffFieldTotalChecklistDocs,
            oldValue: '${oldConsultation.checklistItems.length}',
            newValue: '${_checklist.length}',
          ));
        }

        if (changes.isNotEmpty) {
          final confirmed = await showChangeDiffConfirmationDialog(
            context,
            title: l.reviewCustomsStudyDiffTitle,
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
        'broker_id': _selectedBrokerId ?? 1,
        'broker_name': _selectedBrokerName.isNotEmpty ? _selectedBrokerName : 'Customs Review',
        'broker_contact_person': _brokerContactPerson,
        if (_selectedImportFileId != null) 'import_file_id': _selectedImportFileId,
        if (_selectedPoId != null) 'po_id': _selectedPoId,
        if (_selectedProjectId != null) 'project_id': _selectedProjectId,
        'estimated_duties_egp': estimatedDuties,
        'total_broker_fees_egp': totalBrokerFees,
        if (_brokerPriceListId != null && !widget.isTaxReviewMode) 'broker_price_list_id': _brokerPriceListId,
        'notes': _notesController.text.trim(),
        'checklist_items': _checklist.map((item) => item.toJson()).toList(),
        'broker_quote_items': widget.isTaxReviewMode ? [] : _brokerQuoteItems.map((item) => item.toJson()).toList(),
      };

      if (_editingConsultationId != null) {
        final updated = await ref
            .read(customsConsultationsProvider.notifier)
            .updateConsultation(_editingConsultationId!, payload);
        if (mounted && updated != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '✅ ${l.customsStudyUpdatedSuccess} (${updated.consultationCode})'),
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
            if (mounted) showDialog(context: context, builder: (ctx) => PostSaveStatusDialog(saved: updated));
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
                  '✅ ${l.customsStudySavedSuccess} (${created.consultationCode})'),
              backgroundColor: AppTheme.emerald,
            ),
          );
          _tabController.animateTo(1);
          // Show post-save checklist status summary
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) showDialog(context: context, builder: (ctx) => PostSaveStatusDialog(saved: created));
          });
        }
      }
    } catch (e) {
      if (mounted) {
        await showErrorDetailsDialog(
          context,
          title: '❌ ${l.unableToSaveCustomsStudy}',
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

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
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

    // Calculation Lines & Totals
    final calcLines = _calculateCustomsLines();
    final double exchangeRate = double.tryParse(_exchangeRateController.text.trim()) ?? 50.0;
    final double totalFreightEgp = double.tryParse(_freightEgpController.text.trim()) ?? 0.0;
    final double totalInsuranceEgp = double.tryParse(_insuranceEgpController.text.trim()) ?? 0.0;
    final totalFobEgp = calcLines.fold(0.0, (s, l) => s + l.fobEgp);
    final totalCifEgp = calcLines.fold(0.0, (s, l) => s + l.cifEgp);
    final totalDutyEgp = calcLines.fold(0.0, (s, l) => s + l.dutyAmountEgp);
    final totalVatEgp = calcLines.fold(0.0, (s, l) => s + l.vatAmountEgp);
    final totalTaxesAndDutiesEgp = calcLines.fold(0.0, (s, l) => s + l.totalTaxesAndDutiesEgp);

    final tabs = widget.isTaxReviewMode
        ? [
            VerticalNavTabItem(
              icon: Icons.calculate_outlined,
              titleEn: 'Customs Duty Workspace',
              titleAr: l.taxReviewWorkspaceTab,
            ),
            VerticalNavTabItem(
              icon: Icons.history_edu_outlined,
              titleEn: 'Tax Review Log',
              titleAr: l.taxReviewLogTab,
              badge: (consultationsState.value?.length ?? 0) > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.cobalt.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${consultationsState.value!.where((s) => s.estimatedDutiesEgp > 0).length}',
                        style: const TextStyle(color: AppTheme.cobalt, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    )
                  : null,
            ),
          ]
        : [
            VerticalNavTabItem(
              icon: Icons.gavel_outlined,
              titleEn: 'Customs Workspace',
              titleAr: l.customsWorkspaceTab,
            ),
            VerticalNavTabItem(
              icon: Icons.history_edu_outlined,
              titleEn: 'Consultations Log',
              titleAr: l.consultationsLogTab,
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
            VerticalNavTabItem(
              icon: Icons.price_change_outlined,
              titleEn: 'Broker Price Lists & Catalog',
              titleAr: l.brokerPriceListsTab,
            ),
            VerticalNavTabItem(
              icon: Icons.request_quote_rounded,
              titleEn: 'Clearance Quotes & AI Extractor',
              titleAr: l.clearanceQuotesTab,
            ),
          ];

    return VerticalStageScaffold(
      stageCode: '',
      titleEn: widget.isTaxReviewMode
          ? 'Customs Duty Review & Tax Calculation Workspace'
          : 'Customs Broker Consultation & Inspection Workspace',
      titleAr: widget.isTaxReviewMode
          ? l.customsDutyReviewTitle
          : l.customsStudiesTitle,
      headerIcon: widget.isTaxReviewMode ? Icons.calculate_outlined : Icons.gavel_outlined,
      headerColor: widget.isTaxReviewMode ? Colors.teal : AppTheme.cobalt,
      tabs: tabs,
      selectedIndex: _tabController.index,
      onTabSelected: (index) {
        setState(() => _tabController.index = index);
      },
      selectedImportFileId: _selectedImportFileId,
      onShipmentStatusChanged: () {
        ref.read(importFilesProvider.notifier).fetchImportFiles();
      },
      headerActions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70),
          tooltip: l.liveRefresh,
          onPressed: () {
            ref.read(customsConsultationsProvider.notifier).fetchConsultations();
            ref.read(importFilesProvider.notifier).fetchImportFiles();
            ref.read(purchaseOrdersProvider.notifier).fetchPurchaseOrders();
            ref.read(customsTariffProvider.notifier).fetchTariffs();
            ref.read(currenciesProvider.notifier).fetchCurrencies();
            ref.read(shippingScenariosProvider.notifier).fetchSessions();
            ref.read(partnersProvider.notifier).fetchPartners();
            ref.read(projectsProvider.notifier).fetchProjects();
            if (!widget.isTaxReviewMode) {
              ref.read(clearanceExpenseTypesProvider.notifier).fetchExpenseTypes();
              ref.read(brokerPriceListsProvider.notifier).fetchPriceLists();
            }
          },
        ),
      ],
      body: IndexedStack(
        index: _tabController.index,
        children: [
          // TAB 1: CUSTOMS CONSULTATION / DUTY WORKSPACE
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live Metrics Bar & Actions (Responsive Wrap)
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ConsultationMetricBadge(title: l.customsInspectionReadiness, value: '$liveReadinessPct%', color: Colors.blue),
                      ConsultationMetricBadge(title: l.itemsAndDocsCount, value: '${_checklist.length}', color: Colors.grey),
                      ConsultationMetricBadge(
                        title: l.blockingIssuesCount,
                        value: '$blockingCount',
                        color: blockingCount > 0 ? Colors.red : Colors.green,
                        onTap: () => showBlockingIssuesDialog(context, _checklist, (val) => setState(() { _checklist.clear(); _checklist.addAll(val); })),
                      ),
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
                          if (!widget.isTaxReviewMode) {
                            ref.read(clearanceExpenseTypesProvider.notifier).fetchExpenseTypes();
                            ref.read(brokerPriceListsProvider.notifier).fetchPriceLists();
                          }
                        },
                        icon: const Icon(Icons.refresh, size: 16, color: AppTheme.cobalt),
                        label: Text(l.liveRefresh, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),

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
                            _titleController.text = widget.isTaxReviewMode
                                ? l.defaultTaxReviewSessionTitle
                                : l.defaultCustomsConsultationTitle;
                            _selectedImportFileId = null;
                            _selectedPoId = null;
                            _selectedProjectId = null;
                            _selectedBrokerId = null;
                            _initializeDefaultChecklist();
                          });
                        },
                        icon: const Icon(Icons.cleaning_services_outlined, size: 16, color: Colors.blueGrey),
                        label: Text(l.clearAndStartNew, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),

                      // 3. Smart Clearance Quote Extractor Button (Clearance Mode Only)
                      if (!widget.isTaxReviewMode)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C5CE7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.auto_awesome, size: 16),
                          label: Text(l.smartClearanceQuoteExtractor, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            showSmartClearanceExtractorDialog(
                              context,
                              ref,
                              onExtracted: _applyExtractedQuotationToConsultation,
                            );
                          },
                        ),

                      // 4. Save Draft & Continue Later
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
                        label: Text(l.saveDraftContinueLater, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),

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
                          _editingConsultationId != null
                              ? l.saveConsultationChanges
                              : (widget.isTaxReviewMode ? l.saveTaxReviewSession : l.saveCustomsStudy),
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
                                  l.activeEditModeBannerTitle(_editingConsultationCode ?? ''),
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange.shade900),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l.activeEditModeBannerSub,
                                  style: const TextStyle(fontSize: 12, color: Colors.black87),
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
                            label: Text(l.saveConsultationChanges, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                            label: Text(l.saveAsNewCopy, style: const TextStyle(fontSize: 12)),
                            onPressed: () {
                              setState(() {
                                _editingConsultationId = null;
                                _editingConsultationCode = null;
                                _titleController.text = '${_titleController.text} (${l.modifiedCopySuffix})';
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('📋 ${l.convertedToNewStudyToast}'), backgroundColor: Colors.blue),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            tooltip: l.cancelEditTooltip,
                            onPressed: () {
                              setState(() {
                                _editingConsultationId = null;
                                _editingConsultationCode = null;
                                _titleController.text = widget.isTaxReviewMode
                                    ? l.defaultTaxReviewSessionTitle
                                    : l.defaultCustomsConsultationTitle;
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
                              Text(
                                widget.isTaxReviewMode
                                    ? l.taxReviewWorkspaceTab
                                    : l.customsWorkspaceTab,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                              ),
                              if (_editingConsultationCode != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(6)),
                                  child: Text('${l.statusCol}: $_editingConsultationCode', style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold, fontSize: 12)),
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
                                  decoration: InputDecoration(labelText: '${l.titleField} *', border: const OutlineInputBorder()),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? l.requiredField : null,
                                ),
                              ),
                              if (!widget.isTaxReviewMode) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: SearchableDropdownField<int?>(
                                    value: _selectedBrokerId,
                                    labelText: '${l.customsBrokerLabel} *',
                                    searchHintText: '${l.search} ${l.customsBrokerLabel}...',
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
                                    validator: (v) => v == null ? l.requiredField : null,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: SearchableDropdownField<int?>(
                                  value: _selectedImportFileId,
                                  labelText: l.linkImportFile,
                                  searchHintText: '${l.search} ${l.linkImportFile}...',
                                  items: [
                                    SearchableDropdownItem<int?>(
                                      value: null,
                                      label: '-- ${l.allFiles} --',
                                    ),
                                    ...(ref.watch(importFilesProvider).value ?? []).map((f) => SearchableDropdownItem<int?>(
                                          value: f.importFileId,
                                          label: '[${f.importFileCode}] ${f.customFileNumber ?? f.poNumber ?? "File #${f.importFileId}"}',
                                          subtitle: '${f.companyName} | ${l.customsBrokerLabel}: ${f.brokerName ?? ""} | ${f.invoicesData.length} Invoices',
                                        )),
                                  ],
                                  onChanged: _onImportFileChanged,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _estimatedDutiesController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: '${l.totalTaxesAndDutiesCol} (EGP)',
                                    border: const OutlineInputBorder(),
                                    prefixIcon: const Icon(Icons.calculate, color: AppTheme.cobalt),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_selectedImportFileId != null) ...[
                            Builder(builder: (context) {
                              final importFiles = ref.watch(importFilesProvider).value ?? [];
                              final selFile = importFiles.where((f) => f.importFileId == _selectedImportFileId).firstOrNull;
                              if (selFile == null) return const SizedBox.shrink();

                              final invCount = selFile.invoicesData.length;
                              final double totalInvAmt = selFile.invoicesData.fold(0.0, (s, inv) => s + inv.amount);

                              return Container(
                                margin: const EdgeInsets.only(top: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.cobalt.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.cobalt.withOpacity(0.2)),
                                ),
                                child: Wrap(
                                  spacing: 16,
                                  runSpacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.receipt_long, size: 16, color: AppTheme.cobalt),
                                        const SizedBox(width: 6),
                                        Text(
                                          'إجمالي الفواتير المربوطة: $invCount فواتير (${totalInvAmt > 0 ? totalInvAmt.toStringAsFixed(2) : "0.00"} $_customsCurrency)',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                                        ),
                                      ],
                                    ),
                                    if (selFile.poNumber != null && selFile.poNumber!.isNotEmpty)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.shopping_cart_checkout, size: 16, color: AppTheme.emerald),
                                          const SizedBox(width: 6),
                                          Text('أمر الشراء: ${selFile.poNumber}', style: const TextStyle(fontSize: 12, color: AppTheme.charcoal)),
                                        ],
                                      ),
                                    if (selFile.projectNames != null && selFile.projectNames!.isNotEmpty)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.business, size: 16, color: AppTheme.charcoal),
                                          const SizedBox(width: 6),
                                          Text('المشروع: ${selFile.projectNames}', style: const TextStyle(fontSize: 12, color: AppTheme.charcoal)),
                                        ],
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // BROKER CLEARANCE & LOGISTICS QUOTE DETAILS CARD (Clearance Mode Only)
                  if (!widget.isTaxReviewMode) ...[
                    BrokerQuoteDetailsCard(
                      selectedBrokerId: _selectedBrokerId,
                      isLoadingPriceList: _isLoadingPriceList,
                      brokerQuoteItems: _brokerQuoteItems,
                      brokerPriceListTitle: _brokerPriceListTitle,
                      categoryFilter: _brokerExpenseCategoryFilter,
                      isExpanded: _isBrokerQuoteExpanded,
                      currenciesList: currenciesList,
                      onToggleExpanded: () => setState(() => _isBrokerQuoteExpanded = !_isBrokerQuoteExpanded),
                      onCategoryChanged: (cat) => setState(() => _brokerExpenseCategoryFilter = cat),
                      onAddCustomExpense: _addCustomBrokerExpenseRow,
                      onApplyAll: () {
                        setState(() {
                          for (int i = 0; i < _brokerQuoteItems.length; i++) {
                            final itm = _brokerQuoteItems[i];
                            final lineTotal = itm.unitPrice * itm.qty;
                            _brokerQuoteItems[i] = itm.copyWith(isApplicable: true, totalAmount: lineTotal);
                          }
                        });
                      },
                      onDisableAll: () {
                        setState(() {
                          for (int i = 0; i < _brokerQuoteItems.length; i++) {
                            _brokerQuoteItems[i] = _brokerQuoteItems[i].copyWith(isApplicable: false, totalAmount: 0.0);
                          }
                        });
                      },
                      onUpdateItem: _updateBrokerQuoteItem,
                    ),
                    const SizedBox(height: 20),
                  ],

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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(l.customsCalculationEngine, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
                                    Text(l.customsCalculationEngineSub, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              if (widget.isTaxReviewMode) ...[
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.emerald,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  ),
                                  onPressed: _isRecalculating ? null : _fetchReconciledFinalInvoiceAndRecalculate,
                                  icon: _isRecalculating
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Icon(Icons.flash_on, color: Colors.white, size: 16),
                                  label: Text(
                                    l.fetchReconciledFinalInvoice,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                                onPressed: () => _syncHsRequirementsToChecklist(silent: false),
                                icon: const Icon(Icons.sync_alt, color: Colors.white, size: 16),
                                label: Text(l.syncHsRequirementsToChecklist, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(_isCustomsCalculatorExpanded ? Icons.expand_less : Icons.expand_more, color: AppTheme.charcoal),
                                tooltip: l.view,
                                onPressed: () => setState(() => _isCustomsCalculatorExpanded = !_isCustomsCalculatorExpanded),
                              ),
                            ],
                          ),
                          if (_isCustomsCalculatorExpanded) ...[
                            const Divider(height: 24),
                            // Inputs Bar: Currency, Exchange Rate, Study Date, Freight, Insurance
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: SearchableDropdownField<String>(
                                    value: _customsCurrency,
                                    labelText: l.quoteCurrencyCol,
                                    items: (ref.watch(currenciesProvider).value ?? []).isNotEmpty
                                        ? (ref.watch(currenciesProvider).value ?? [])
                                            .map((c) => SearchableDropdownItem<String>(
                                                  value: c.currencyCode,
                                                  label: '${c.currencyCode} - ${c.currencyName}',
                                                ))
                                            .toList()
                                        : const [
                                            SearchableDropdownItem(value: 'USD', label: 'USD'),
                                            SearchableDropdownItem(value: 'EUR', label: 'EUR'),
                                            SearchableDropdownItem(value: 'GBP', label: 'GBP'),
                                            SearchableDropdownItem(value: 'CNY', label: 'CNY'),
                                            SearchableDropdownItem(value: 'EGP', label: 'EGP'),
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
                                    decoration: InputDecoration(labelText: '${l.customsExchangeRate} (EGP)', border: const OutlineInputBorder()),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: _studyDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2030),
                                      );
                                      if (picked != null) {
                                        setState(() => _studyDate = picked);
                                      }
                                    },
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: l.studyDateLabel,
                                        border: const OutlineInputBorder(),
                                        prefixIcon: const Icon(Icons.calendar_today, color: AppTheme.cobalt, size: 18),
                                      ),
                                      child: Text(
                                        '${_studyDate.year}-${_studyDate.month.toString().padLeft(2, '0')}-${_studyDate.day.toString().padLeft(2, '0')}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _freightEgpController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(labelText: '${l.freightEgpLabel} (EGP)', border: const OutlineInputBorder()),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _insuranceEgpController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(labelText: '${l.insuranceEgpLabel} (EGP)', border: const OutlineInputBorder()),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                              ],
                            ),
                            if (_recalculationResult != null) ...[
                              const SizedBox(height: 16),
                              RecalculationVarianceComparisonCard(
                                recalculationResult: _recalculationResult!,
                                onApplyNewFees: _applyAndSaveRecalculatedFees,
                                onClose: () => setState(() => _recalculationResult = null),
                              ),
                            ],
                            const SizedBox(height: 16),

                            // HS Code Line Items Calculation Table
                            if (calcLines.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline, color: AppTheme.cobalt),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(l.noResultsFound, style: const TextStyle(color: AppTheme.charcoal, fontWeight: FontWeight.w600))),
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
                                  columns: [
                                    DataColumn(label: Text(l.customsTariffItemCol)),
                                    DataColumn(label: Text(l.itemDescriptionAndOriginCol)),
                                    DataColumn(label: Text(l.quantityAndUnitCol)),
                                    DataColumn(label: Text(l.fobEgpCol)),
                                    DataColumn(label: Text(l.cifEgpCol)),
                                    DataColumn(label: Text(l.customsDutyCol)),
                                    DataColumn(label: Text(l.vatCol)),
                                    DataColumn(label: Text(l.otherTaxesCol)),
                                    DataColumn(label: Text(l.totalTaxesAndDutiesCol)),
                                    DataColumn(label: Text(l.regulatoryRequirementsCol)),
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
                                                      line.countryOfOrigin!,
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
                                                    line.appliedAgreementName ?? "Exemption",
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
                                              '⚠️ HS Code: ${line.hsCode}${line.countryOfOrigin != null ? " - ${line.countryOfOrigin}" : ""}',
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
                                                line.appliedAgreementName ?? 'Exemption',
                                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (line.exemptionConditionsNote != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          line.exemptionConditionsNote!,
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.charcoal),
                                        ),
                                      ],
                                      if (line.requiredDocument != null) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          line.requiredDocument!,
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                                        ),
                                      ],
                                      if (line.priorApprovalNote != null && line.priorApprovalNote!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          line.priorApprovalNote!,
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
                                    ConsultationMetricBadge(title: l.fobEgpCol, value: '${totalFobEgp.toStringAsFixed(2)} EGP', color: Colors.grey.shade800),
                                    ConsultationMetricBadge(title: l.cifEgpCol, value: '${totalCifEgp.toStringAsFixed(2)} EGP', color: AppTheme.cobalt),
                                    ConsultationMetricBadge(title: l.customsDutyCol, value: '${totalDutyEgp.toStringAsFixed(2)} EGP', color: Colors.indigo),
                                    ConsultationMetricBadge(title: l.vatCol, value: '${totalVatEgp.toStringAsFixed(2)} EGP', color: Colors.teal),
                                    ConsultationMetricBadge(title: l.totalTaxesAndDutiesCol, value: '${totalTaxesAndDutiesEgp.toStringAsFixed(2)} EGP', color: AppTheme.crimson),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                                      onPressed: () {
                                        setState(() {
                                          _estimatedDutiesController.text = totalTaxesAndDutiesEgp.toStringAsFixed(2);
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('✅ ${l.applyAndLinkFinancialEstimate}: ${totalTaxesAndDutiesEgp.toStringAsFixed(2)} EGP'), backgroundColor: AppTheme.emerald),
                                        );
                                      },
                                      icon: const Icon(Icons.done_all, color: Colors.white, size: 16),
                                      label: Text(l.applyAndLinkFinancialEstimate, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                              const SizedBox(height: 16),

                              // NAFEZA STATEMENT FEE BREAKDOWN CARD (تفاصيل بنود التحصيل والإقرارات الرسمية)
                              NafezaFeeBreakdownCard(
                                calcLines: calcLines,
                                totalDutyEgp: totalDutyEgp,
                                totalVatEgp: totalVatEgp,
                                totalServiceFeeEgp: calcLines.fold(0.0, (s, l) => s + l.customsServiceFeeAmountEgp),
                                totalScheduleTaxEgp: calcLines.fold(0.0, (s, l) => s + l.scheduleTaxAmountEgp),
                                totalFreightEgp: totalFreightEgp,
                                totalInsuranceEgp: totalInsuranceEgp,
                                exchangeRate: exchangeRate,
                                editingConsultationId: _editingConsultationId,
                                editingConsultationCode: _editingConsultationCode,
                                selectedBrokerId: _selectedBrokerId,
                                selectedBrokerName: _selectedBrokerName,
                                title: _titleController.text.trim(),
                                checklist: _checklist,
                                brokerQuoteItems: _brokerQuoteItems,
                                selectedImportFileId: _selectedImportFileId,
                                customsCurrency: _customsCurrency,
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
                              Text(l.customsChecklistTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
                              const Spacer(),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                                onPressed: _addChecklistItem,
                                icon: const Icon(Icons.add, color: Colors.white),
                                label: Text(l.addNewChecklistItem, style: const TextStyle(color: Colors.white)),
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
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isNarrow = constraints.maxWidth < 850;
                                    if (isNarrow) {
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Wrap(
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: [
                                              if (item.hsCode != null && item.hsCode!.isNotEmpty)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(color: AppTheme.cobalt.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                                                  child: Text(item.hsCode!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                                                ),
                                              Text(_getLocalizedDocType(item.documentType, isArabic), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                            ],
                                          ),
                                          if (item.regulatoryAgency != null)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2.0),
                                              child: Text('${l.responsiblePartyLabel}: ${item.regulatoryAgency}', style: const TextStyle(fontSize: 11, color: Colors.purple, fontWeight: FontWeight.bold)),
                                            ),
                                          if (item.remarks != null && item.remarks!.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2.0),
                                              child: Text(_getLocalizedRemarks(item.remarks, isArabic), style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                                            ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: SearchableDropdownField<String>(
                                                  value: item.responsibleParty,
                                                  labelText: l.responsiblePartyLabel,
                                                  items: [
                                                    SearchableDropdownItem(value: 'Customs Broker', label: isArabic ? 'مخلص جمركي' : 'Customs Broker'),
                                                    SearchableDropdownItem(value: 'Supplier / Exporter', label: isArabic ? 'المورد / المصدر' : 'Supplier / Exporter'),
                                                    SearchableDropdownItem(value: 'Importer Team', label: isArabic ? 'فريق المستورد' : 'Importer Team'),
                                                    SearchableDropdownItem(value: 'Freight Forwarder', label: isArabic ? 'شركة الشحن' : 'Freight Forwarder'),
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
                                                child: SearchableDropdownField<String>(
                                                  value: item.status,
                                                  labelText: l.statusCol,
                                                  items: [
                                                    SearchableDropdownItem(value: 'Pending', label: isArabic ? 'قيد الانتظار' : 'Pending'),
                                                    SearchableDropdownItem(value: 'Received', label: isArabic ? 'مستلم' : 'Received'),
                                                    SearchableDropdownItem(value: 'Verified', label: isArabic ? 'تم التحقق' : 'Verified'),
                                                    SearchableDropdownItem(value: 'Approved', label: isArabic ? 'معتمد' : 'Approved'),
                                                    SearchableDropdownItem(value: 'Rejected', label: isArabic ? 'مرفوض' : 'Rejected'),
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
                                                tooltip: item.isBlockingShipment ? l.blockingConditionTooltip : l.nonBlockingConditionTooltip,
                                                onPressed: () {
                                                  setState(() {
                                                    _checklist[index] = item.copyWith(isBlockingShipment: !item.isBlockingShipment);
                                                  });
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                                                onPressed: () {
                                                  setState(() {
                                                    _checklist.removeAt(index);
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    }

                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Wrap(
                                                crossAxisAlignment: WrapCrossAlignment.center,
                                                spacing: 6,
                                                runSpacing: 4,
                                                children: [
                                                  if (item.hsCode != null && item.hsCode!.isNotEmpty)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(color: AppTheme.cobalt.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                                                      child: Text(item.hsCode!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                                                    ),
                                                  Text(_getLocalizedDocType(item.documentType, isArabic), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                ],
                                              ),
                                              if (item.regulatoryAgency != null)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 2.0),
                                                  child: Text('${l.responsiblePartyLabel}: ${item.regulatoryAgency}', style: const TextStyle(fontSize: 11, color: Colors.purple, fontWeight: FontWeight.bold)),
                                                ),
                                              if (item.remarks != null && item.remarks!.isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 2.0),
                                                  child: Text(_getLocalizedRemarks(item.remarks, isArabic), style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                                                ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        SizedBox(
                                          width: 190,
                                          child: SearchableDropdownField<String>(
                                            value: item.responsibleParty,
                                            labelText: l.responsiblePartyLabel,
                                            items: [
                                              SearchableDropdownItem(value: 'Customs Broker', label: isArabic ? 'مخلص جمركي' : 'Customs Broker'),
                                              SearchableDropdownItem(value: 'Supplier / Exporter', label: isArabic ? 'المورد / المصدر' : 'Supplier / Exporter'),
                                              SearchableDropdownItem(value: 'Importer Team', label: isArabic ? 'فريق المستورد' : 'Importer Team'),
                                              SearchableDropdownItem(value: 'Freight Forwarder', label: isArabic ? 'شركة الشحن' : 'Freight Forwarder'),
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
                                        SizedBox(
                                          width: 160,
                                          child: SearchableDropdownField<String>(
                                            value: item.status,
                                            labelText: l.statusCol,
                                            items: [
                                              SearchableDropdownItem(value: 'Pending', label: isArabic ? 'قيد الانتظار' : 'Pending'),
                                              SearchableDropdownItem(value: 'Received', label: isArabic ? 'مستلم' : 'Received'),
                                              SearchableDropdownItem(value: 'Verified', label: isArabic ? 'تم التحقق' : 'Verified'),
                                              SearchableDropdownItem(value: 'Approved', label: isArabic ? 'معتمد' : 'Approved'),
                                              SearchableDropdownItem(value: 'Rejected', label: isArabic ? 'مرفوض' : 'Rejected'),
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
                                          tooltip: item.isBlockingShipment ? l.blockingConditionTooltip : l.nonBlockingConditionTooltip,
                                          onPressed: () {
                                            setState(() {
                                              _checklist[index] = item.copyWith(isBlockingShipment: !item.isBlockingShipment);
                                            });
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                                          onPressed: () {
                                            setState(() {
                                              _checklist.removeAt(index);
                                            });
                                          },
                                        ),
                                      ],
                                    );
                                  },
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

          SavedConsultationsTab(
            isTaxReviewOnly: widget.isTaxReviewMode,
            onEdit: _loadConsultationForEdit,
            onViewDetails: showConsultationDetailsDialog,
          ),
          if (!widget.isTaxReviewMode) ...[
            // TAB 3: BROKER PRICE LISTS & CATALOG MANAGEMENT
            const BrokerPriceListsTab(),
            // TAB 4: CLEARANCE QUOTATIONS & SMART AI EXTRACTOR
            const CustomsClearanceQuotationsScreen(embedded: true),
          ],
        ],
      ),
    );
  }
}

