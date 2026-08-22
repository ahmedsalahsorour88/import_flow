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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.isTaxReviewMode
          ? 'مراجعة واحتساب الضرائب والرسوم الجمركية للشحنة'
          : 'دراسة المراجعة الجمركية الأولية لخط إنتاج ومعدات الشحنة',
    );
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

  Future<void> _fetchReconciledFinalInvoiceAndRecalculate() async {
    if (_selectedImportFileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ يرجى اختيار ملف الشحنة الاستيرادية أولاً لاستدعاء الفاتورة النهائية.'),
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
                        ? '✅ تم استدعاء بنود وقيم الفاتورة والباكينج ليست النهائية المعتمدة بنجاح (${res.finalInvoiceNumber ?? ""}) وإعادة احتساب الرسوم بدقة.'
                        : 'ℹ️ تم احتساب الرسوم بناءً على بنود أمر الشراء المبدئي لعدم وجود جلسة مطابقة نهائية معتمدة بعد.',
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
            content: Text('❌ تعذر استدعاء وإعادة احتساب البنود: $e'),
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

    // Pre-index tariffs for instant O(1) lookups
    final Map<int, CustomsTariffModel> tariffById = {
      for (final t in tariffsList) t.tariffId: t,
    };
    final Map<String, CustomsTariffModel> tariffByNormalizedHs = {
      for (final t in tariffsList) t.hsCode.replaceAll('.', '').trim(): t,
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
            unitType: 'Fixed (مبلغ مقطوع)',
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

      upsertQuoteItem('أتعاب التخليص الجمركي', 'Clearance Agency Fees', clearanceFee);
      upsertQuoteItem('النقل الداخلي للمصنع/المستودع', 'Inland Transportation', inlandFee);
      upsertQuoteItem('مصاريف فحص وعرض جمركي', 'Customs Inspection', inspectionFee);
      upsertQuoteItem('رسوم موانئ وأرضيات', 'Port & Terminal', portExp);
      upsertQuoteItem('نثريات ومصروفات إدارية', 'Miscellaneous', miscFee);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✔ تم استخلاص وتطبيق بنود مقايسة التخليص بنجاح (${extracted['broker_name'] ?? 'مكتب تخليص'})'),
        backgroundColor: AppTheme.emerald,
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

    if (!widget.isTaxReviewMode && _selectedBrokerId == null) {
      validationErrors.add(ValidationIssueItem(
        fieldName: 'المستخلص الجمركي المعني (Customs Broker)',
        issueDescription: 'لم يتم تحديد المستخلص الجمركي المسؤول عن دراسة الملف.',
        recommendation: 'يرجى اختيار المستخلص الجمركي من القائمة المنسدلة.',
        isBlocking: true,
      ));
    }

    if (!widget.isTaxReviewMode && _checklist.isEmpty) {
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
        title: '⚠️ تنبيهات واستيفاء بيانات الدراسة',
        error: 'يرجى استكمال البيانات الإلزامية التالية لتتمكن من حفظ الدراسة بنجاح.',
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
            title: 'مراجعة وتأكيد تعديلات الدراسة الجمركية',
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
        'broker_name': _selectedBrokerName.isNotEmpty ? _selectedBrokerName : 'مراجعة الضرائب الجمركية',
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
                  '✅ تم تحديث مراجعة الضرائب الجمركية بنجاح! كود: ${updated.consultationCode}'),
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
                  '✅ تم حفظ مراجعة الضرائب والرسوم الجمركية بنجاح! كود: ${created.consultationCode}'),
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
          title: '❌ تعذر حفظ مراجعة الضرائب الجمركية',
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
            const VerticalNavTabItem(
              icon: Icons.calculate_outlined,
              titleEn: 'Customs Duty Workspace',
              titleAr: 'مركز احتساب ومراجعة الضرائب',
            ),
            VerticalNavTabItem(
              icon: Icons.history_edu_outlined,
              titleEn: 'Tax Review Log',
              titleAr: 'سجل مراجعات الضرائب المحفوظة',
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
            const VerticalNavTabItem(
              icon: Icons.request_quote_rounded,
              titleEn: 'Clearance Quotes & AI Extractor',
              titleAr: 'عروض التخليص والاستخراج الذكي',
            ),
          ];

    return VerticalStageScaffold(
      stageCode: '',
      titleEn: widget.isTaxReviewMode
          ? 'Customs Duty Review & Tax Calculation Workspace'
          : 'Customs Broker Consultation & Inspection Workspace',
      titleAr: widget.isTaxReviewMode
          ? 'مركز مراجعة واحتساب الضرائب والرسوم الجمركية'
          : 'مركز الاستشارة والفحص الجمركي',
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
                      ConsultationMetricBadge(title: 'جاهزية الفحص الجمركي', value: '$liveReadinessPct%', color: Colors.blue),
                      ConsultationMetricBadge(title: 'عدد البنود والمستندات', value: '${_checklist.length}', color: Colors.grey),
                      ConsultationMetricBadge(
                        title: 'عوائق التخليص (Blocking)',
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
                        label: const Text('إعادة تحميل حية 🔄', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                                ? 'مراجعة واحتساب الضرائب والرسوم الجمركية للشحنة'
                                : 'دراسة المراجعة الجمركية الأولية لخط إنتاج ومعدات الشحنة';
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
                          label: const Text('🤖 استخراج ذكي لمقايسة تخليص', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                        label: const Text('حفظ مؤقت ومتابعة لاحقة 💾', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                              ? 'حفظ تعديلات المراجعة الجمركية'
                              : (widget.isTaxReviewMode ? 'حفظ جلسة مراجعة الضرائب الجمركية ✅' : 'حفظ دراسة الاستشارة الجمركية ✅'),
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
                                _titleController.text = widget.isTaxReviewMode
                                    ? 'مراجعة واحتساب الضرائب والرسوم الجمركية للشحنة'
                                    : 'دراسة المراجعة الجمركية الأولية لخط إنتاج ومعدات الشحنة';
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
                                    ? 'بيانات ملف الشحنة وأوامر الشراء المربوطة بمراجعة الضرائب'
                                    : 'بيانات الجلسة والمستخلص الجمركي المعني (Customs Broker)',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                              ),
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
                                  decoration: const InputDecoration(labelText: 'عنوان موضوع المراجعة / الدراسة *', border: OutlineInputBorder()),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال عنوان الدراسة' : null,
                                ),
                              ),
                              if (!widget.isTaxReviewMode) ...[
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
                                    labelText: 'تقدير الرسوم والضرائب (EGP)',
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
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('محرك حساب الرسوم والضرائب الجمركية للشحنة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
                                    Text('يستدعي بنود HS Code والقيم والاشتراطات تلقائياً من ملف الشحنة وأوامر الشراء المربوطة ويحسب الجمارك والـ VAT ورسم التنمية', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                                  label: const Text(
                                    '⚡ استدعاء بنود وقيم الفاتورة والباكينج ليست النهائية المعتمدة',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
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
                            // Inputs Bar: Currency, Exchange Rate, Study Date, Freight, Insurance
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
                                      decoration: const InputDecoration(
                                        labelText: 'تاريخ الدراسة الجمركية (Study Date)',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.calendar_today, color: AppTheme.cobalt, size: 18),
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
                                    ConsultationMetricBadge(title: 'إجمالي FOB بالجنيه', value: '${totalFobEgp.toStringAsFixed(2)} EGP', color: Colors.grey.shade800),
                                    ConsultationMetricBadge(title: 'إجمالي القيمة الجمركية (CIF Base)', value: '${totalCifEgp.toStringAsFixed(2)} EGP', color: AppTheme.cobalt),
                                    ConsultationMetricBadge(title: 'إجمالي ضريبة الوارد (Customs Duty)', value: '${totalDutyEgp.toStringAsFixed(2)} EGP', color: Colors.indigo),
                                    ConsultationMetricBadge(title: 'إجمالي ضريبة القيمة المضافة (VAT)', value: '${totalVatEgp.toStringAsFixed(2)} EGP', color: Colors.teal),
                                    ConsultationMetricBadge(title: 'إجمالي الرسوم والضرائب الجمركية', value: '${totalTaxesAndDutiesEgp.toStringAsFixed(2)} EGP', color: AppTheme.crimson),
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
                                              Text(item.documentType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
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
                                                  Text(item.documentType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                                        const SizedBox(width: 12),
                                        SizedBox(
                                          width: 190,
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
                                        SizedBox(
                                          width: 160,
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

