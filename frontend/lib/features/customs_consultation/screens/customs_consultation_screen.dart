import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/change_diff_dialog.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
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
  bool _isSaving = false;

  // History Tab Filter State
  String _searchQuery = '';
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialIndex);
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
          // Auto-fetch broker from file
          if (file.brokerId != null) {
            _selectedBrokerId = file.brokerId;
            _selectedBrokerName = file.brokerName ?? '';
            final partners = ref.read(partnersProvider).value ?? [];
            final bPartner = partners.where((p) => p.providerId == file.brokerId).firstOrNull;
            if (bPartner != null) {
              _brokerContactPerson = bPartner.contactPerson;
            }
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

    // Collect all line items
    final List<POLineItemModel> lines = [];
    for (final po in matchingPOs) {
      lines.addAll(po.items);
    }

    if (lines.isEmpty) {
      return [];
    }

    // Compute total FOB in EGP
    double totalFobEgp = 0.0;
    for (final l in lines) {
      totalFobEgp += (l.totalPrice * exchangeRate);
    }

    final List<CustomsItemCalcRow> result = [];
    for (final l in lines) {
      final hs = (l.hsCode != null && l.hsCode!.trim().isNotEmpty) ? l.hsCode!.trim() : 'UNASSIGNED';
      
      // Match tariff
      CustomsTariffModel? matchedTariff;
      if (l.tariffId != null) {
        matchedTariff = tariffsList.where((t) => t.tariffId == l.tariffId).firstOrNull;
      }
      if (matchedTariff == null && hs != 'UNASSIGNED') {
        matchedTariff = tariffsList.where((t) => t.hsCode.replaceAll('.', '').trim() == hs.replaceAll('.', '').trim()).firstOrNull;
      }

      final double dutyRate = matchedTariff?.customsDutyRate ?? (l.dutyRate ?? 5.0);
      final double vatRate = matchedTariff?.vatRate ?? (l.vatRate ?? 14.0);
      final double scheduleTaxRate = matchedTariff?.scheduleTaxRate ?? 0.0;
      final double devRate = matchedTariff?.developmentFeeRate ?? 0.0;
      final double svcRate = matchedTariff?.customsServiceFeeRate ?? 1.0;

      final double fobEgp = l.totalPrice * exchangeRate;
      final double freightShare = totalFobEgp > 0 ? (fobEgp / totalFobEgp * totalFreightEgp) : 0.0;
      final double insuranceShare = totalFobEgp > 0 ? (fobEgp / totalFobEgp * totalInsuranceEgp) : 0.0;
      final double cifEgp = fobEgp + freightShare + insuranceShare;

      final double dutyAmountEgp = cifEgp * (dutyRate / 100.0);
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
        dutyRate: dutyRate,
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
      _tabController.animateTo(0);
    });
  }

  Future<void> _saveConsultation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBrokerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ يرجى اختيار المستخلص الجمركي المعني (Customs Broker)'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_checklist.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ يرجى إضافة بند واحد على الأقل في قائمة الفحص الجمركي'), backgroundColor: Colors.orange),
      );
      return;
    }

    final titleToSave = _titleController.text.trim();
    final estimatedDuties = double.tryParse(_estimatedDutiesController.text.trim()) ?? 0.0;

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
        'notes': _notesController.text.trim(),
        'checklist_items': _checklist.map((item) => item.toJson()).toList(),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ حدث خطأ أثناء الحفظ: $e'), backgroundColor: Colors.red),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('مركز الاستشارة والفحص الجمركي (BP-009 / BP-010 – Customs Workspace)'),
        backgroundColor: AppTheme.charcoal,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.cobalt,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.assignment_turned_in), text: 'Customs Workspace (مركز الاستشارة والفحص)'),
            Tab(icon: Icon(Icons.history), text: 'Saved Consultations Log (سجل الدراسات المحفوظة)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
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
                      _buildMetricBadge('المستندات المعتمدة', '${approvedDocs.toInt()}', Colors.green),
                      const SizedBox(width: 12),
                      _buildMetricBadge('عوائق التخليص (Blocking)', '$blockingCount', blockingCount > 0 ? Colors.red : Colors.green),
                      const Spacer(),
                      if (_editingConsultationId != null) ...[
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange.shade800,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          onPressed: () {
                            setState(() {
                              _editingConsultationId = null;
                              _editingConsultationCode = null;
                              _titleController.text = 'دراسة المراجعة الجمركية الأولية لخط إنتاج ومعدات الشحنة';
                              _initializeDefaultChecklist();
                            });
                          },
                          icon: const Icon(Icons.cancel),
                          label: const Text('إلغاء التعديل والعودة كدراسة جديدة'),
                        ),
                        const SizedBox(width: 10),
                      ],
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
                          _editingConsultationId != null ? 'حفظ تعديلات الاستشارة الجمركية' : 'حفظ دراسة الاستشارة الجمركية',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

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
                                    Text('محرك حساب الرسوم والضرائب الجمركية للشحنة (MD-008 Customs Calculation Engine)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
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
                                    DataColumn(label: Text('بيان الصنف والمواصفات')),
                                    DataColumn(label: Text('الكمية والوحدة')),
                                    DataColumn(label: Text('القيمة (FOB EGP)')),
                                    DataColumn(label: Text('القيمة الجمركية (CIF EGP)')),
                                    DataColumn(label: Text('ضريبة الوارد')),
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
                                        DataCell(SizedBox(width: 180, child: Text(line.description, overflow: TextOverflow.ellipsis))),
                                        DataCell(Text('${line.qty.toStringAsFixed(0)} ${line.unit}')),
                                        DataCell(Text(line.fobEgp.toStringAsFixed(2))),
                                        DataCell(Text(line.cifEgp.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold))),
                                        DataCell(Text('${line.dutyRate}% (${line.dutyAmountEgp.toStringAsFixed(2)})')),
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
                                              final confirm =
                                                  await showDialog<bool>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: const Row(
                                                    children: [
                                                      Icon(
                                                          Icons.warning_rounded,
                                                          color: Colors.orange,
                                                          size: 22),
                                                      SizedBox(width: 8),
                                                      Text('تأكيد حذف الدراسة',
                                                          style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                    ],
                                                  ),
                                                  content: Text(
                                                    'هل أنت متأكد من حذف دراسة الاستشارة الجمركية "${session.consultationCode}"؟',
                                                    style: const TextStyle(
                                                        fontSize: 13),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              ctx, false),
                                                      child:
                                                          const Text('إلغاء'),
                                                    ),
                                                    ElevatedButton.icon(
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                              backgroundColor:
                                                                  AppTheme
                                                                      .crimson,
                                                              foregroundColor:
                                                                  Colors.white),
                                                      icon: const Icon(
                                                          Icons.delete_rounded,
                                                          size: 16),
                                                      label:
                                                          const Text('حذف'),
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              ctx, true),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (confirm == true && mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        '⚠️ خاصية الحذف ستُتاح في الإصدار القادم'),
                                                    backgroundColor:
                                                        Colors.orange,
                                                  ),
                                                );
                                              }
                                            },
                                            viewTooltip: 'عرض تفاصيل الاستشارة',
                                            editTooltip:
                                                'تعديل الدراسة الجمركية',
                                            printTooltip:
                                                'طباعة تقرير الاستشارة',
                                            deleteTooltip:
                                                'حذف الدراسة (Soft Delete)',
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
