import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/localization/app_localizations.dart';
import '../../../core/services/file_save_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';
import '../../import_files/models/import_file_model.dart';
import '../../import_files/providers/import_files_provider.dart';

enum ReportTemplateMode {
  custom,
  eco,
  scas,
}

class DynamicReportColumn {
  final String id;
  final String categoryId;
  bool isVisible;

  DynamicReportColumn({
    required this.id,
    required this.categoryId,
    this.isVisible = true,
  });
}

class ReportColumnCategory {
  final String id;
  final IconData icon;

  const ReportColumnCategory({
    required this.id,
    required this.icon,
  });
}

class DynamicReportBuilderScreen extends ConsumerStatefulWidget {
  const DynamicReportBuilderScreen({super.key});

  static const List<String> kEcoPresetColumnIds = [
    'ecoBroker',
    'ecoShipmentNo',
    'ecoSupplier',
    'ecoProject',
    'ecoPiValue',
    'ecoShippingDate',
    'ecoArrivalPort',
    'ecoArrivalWarehouse',
    'ecoSara',
    'ecoMaro',
    'ecoReadyToPickUp',
    'ecoLatestUpdate',
    'ecoSwiftDate',
    'ecoSwiftAmount',
    'ecoShippingCompany',
    'ecoAcid',
  ];

  static const List<String> kScasPresetColumnIds = [
    'scasProjectFileAcid',
    'scasExFactory',
    'scasOrderToOrigin',
    'scasPickUpDate',
    'scasDeparturePort',
    'scasArrivalAlexPort',
    'scasOrigInvoice',
    'scasOrigPackingList',
    'scasOrigCoo',
    'scasOrigBl',
    'scasOrigInsurance',
    'scasInsertNafeza',
    'scasBankForm4',
    'scasDeclare3A',
    'scasMaterialReceived',
  ];

  @override
  ConsumerState<DynamicReportBuilderScreen> createState() => _DynamicReportBuilderScreenState();
}

class _DynamicReportBuilderScreenState extends ConsumerState<DynamicReportBuilderScreen> {
  ReportTemplateMode _templateMode = ReportTemplateMode.eco;
  DateTime _lastUpdatedAt = DateTime.now();

  late final List<DynamicReportColumn> _masterColumns;

  String _filterMode = 'All';
  String _filterPriority = 'All';
  final String _filterStatus = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _masterColumns = _buildMasterColumnCatalog();
    _refreshData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshData() {
    setState(() {
      _lastUpdatedAt = DateTime.now();
    });
    Future.microtask(() {
      ref.read(importFilesProvider.notifier).fetchImportFiles();
    });
  }

  String _formatDateTime(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min:$s';
  }

  List<DynamicReportColumn> _buildMasterColumnCatalog() {
    return [
      // File & Project
      DynamicReportColumn(id: 'importFileCode', categoryId: 'file_project', isVisible: true),
      DynamicReportColumn(id: 'customFileNumber', categoryId: 'file_project', isVisible: true),
      DynamicReportColumn(id: 'companyName', categoryId: 'file_project', isVisible: true),
      DynamicReportColumn(id: 'supplierName', categoryId: 'file_project', isVisible: true),
      DynamicReportColumn(id: 'brokerName', categoryId: 'file_project', isVisible: true),
      DynamicReportColumn(id: 'projectNames', categoryId: 'file_project', isVisible: true),
      DynamicReportColumn(id: 'owner', categoryId: 'file_project', isVisible: false),
      DynamicReportColumn(id: 'status', categoryId: 'file_project', isVisible: true),
      DynamicReportColumn(id: 'currentStage', categoryId: 'file_project', isVisible: true),
      DynamicReportColumn(id: 'progressPercent', categoryId: 'file_project', isVisible: true),
      DynamicReportColumn(id: 'priority', categoryId: 'file_project', isVisible: false),
      DynamicReportColumn(id: 'nextAction', categoryId: 'file_project', isVisible: false),
      DynamicReportColumn(id: 'fileOpeningDate', categoryId: 'file_project', isVisible: false),
      DynamicReportColumn(id: 'notes', categoryId: 'file_project', isVisible: false),
      DynamicReportColumn(id: 'updatedAt', categoryId: 'file_project', isVisible: false),

      // Commercial & PO
      DynamicReportColumn(id: 'poNumber', categoryId: 'commercial_po', isVisible: false),
      DynamicReportColumn(id: 'piNumber', categoryId: 'commercial_po', isVisible: false),
      DynamicReportColumn(id: 'piValue', categoryId: 'commercial_po', isVisible: true),
      DynamicReportColumn(id: 'incotermCode', categoryId: 'commercial_po', isVisible: true),
      DynamicReportColumn(id: 'estimatedCost', categoryId: 'commercial_po', isVisible: false),

      // Shipping & Logistics
      DynamicReportColumn(id: 'shipmentMode', categoryId: 'shipping_logistics', isVisible: true),
      DynamicReportColumn(id: 'shippingLine', categoryId: 'shipping_logistics', isVisible: false),
      DynamicReportColumn(id: 'portOfLoading', categoryId: 'shipping_logistics', isVisible: false),
      DynamicReportColumn(id: 'portOfDischarge', categoryId: 'shipping_logistics', isVisible: false),
      DynamicReportColumn(id: 'cargoReadyDate', categoryId: 'shipping_logistics', isVisible: false),
      DynamicReportColumn(id: 'requiredEta', categoryId: 'shipping_logistics', isVisible: true),
      DynamicReportColumn(id: 'targetFreeDays', categoryId: 'shipping_logistics', isVisible: false),

      // Packages & CBM
      DynamicReportColumn(id: 'totalPackages', categoryId: 'packages_cbm', isVisible: false),
      DynamicReportColumn(id: 'grossWeightKg', categoryId: 'packages_cbm', isVisible: false),
      DynamicReportColumn(id: 'totalCbm', categoryId: 'packages_cbm', isVisible: false),

      // Customs & Nafeza
      DynamicReportColumn(id: 'acidNumber', categoryId: 'customs_nafeza', isVisible: true),
      DynamicReportColumn(id: 'acidIssueDate', categoryId: 'customs_nafeza', isVisible: false),
      DynamicReportColumn(id: 'acidExpiryDate', categoryId: 'customs_nafeza', isVisible: false),
      DynamicReportColumn(id: 'form46No', categoryId: 'customs_nafeza', isVisible: false),
      DynamicReportColumn(id: 'customsReleaseStatus', categoryId: 'customs_nafeza', isVisible: false),
      DynamicReportColumn(id: 'customsReleasedAt', categoryId: 'customs_nafeza', isVisible: false),

      // Banking & Swift
      DynamicReportColumn(id: 'form4No', categoryId: 'banking_swift', isVisible: true),
      DynamicReportColumn(id: 'form4ReceivedDate', categoryId: 'banking_swift', isVisible: false),
      DynamicReportColumn(id: 'swiftNo', categoryId: 'banking_swift', isVisible: false),
      DynamicReportColumn(id: 'swiftDate', categoryId: 'banking_swift', isVisible: false),
      DynamicReportColumn(id: 'swiftAmount', categoryId: 'banking_swift', isVisible: false),

      // SCAS Tracker
      DynamicReportColumn(id: 'scasProjectFileAcid', categoryId: 'scas_tracker', isVisible: false),
      DynamicReportColumn(id: 'scasExFactory', categoryId: 'scas_tracker', isVisible: false),
      DynamicReportColumn(id: 'scasOrderToOrigin', categoryId: 'scas_tracker', isVisible: false),
      DynamicReportColumn(id: 'scasPickUpDate', categoryId: 'scas_tracker', isVisible: false),
      DynamicReportColumn(id: 'scasDeparturePort', categoryId: 'scas_tracker', isVisible: false),
      DynamicReportColumn(id: 'scasArrivalAlexPort', categoryId: 'scas_tracker', isVisible: false),
      DynamicReportColumn(id: 'scasOrigInvoice', categoryId: 'scas_tracker', isVisible: false),
      DynamicReportColumn(id: 'scasOrigPackingList', categoryId: 'scas_tracker', isVisible: false),
      DynamicReportColumn(id: 'scasOrigCoo', categoryId: 'scas_tracker', isVisible: false),
      DynamicReportColumn(id: 'scasOrigBl', categoryId: 'scas_tracker', isVisible: false),
      DynamicReportColumn(id: 'scasOrigInsurance', categoryId: 'scas_tracker', isVisible: false),
      DynamicReportColumn(id: 'scasInsertNafeza', categoryId: 'scas_tracker', isVisible: false),
      DynamicReportColumn(id: 'scasBankForm4', categoryId: 'scas_tracker', isVisible: false),
      DynamicReportColumn(id: 'scasDeclare3A', categoryId: 'scas_tracker', isVisible: false),
      DynamicReportColumn(id: 'scasMaterialReceived', categoryId: 'scas_tracker', isVisible: false),

      // ECO Radar
      DynamicReportColumn(id: 'ecoBroker', categoryId: 'eco_radar', isVisible: false),
      DynamicReportColumn(id: 'ecoShipmentNo', categoryId: 'eco_radar', isVisible: false),
      DynamicReportColumn(id: 'ecoSupplier', categoryId: 'eco_radar', isVisible: false),
      DynamicReportColumn(id: 'ecoProject', categoryId: 'eco_radar', isVisible: false),
      DynamicReportColumn(id: 'ecoPiValue', categoryId: 'eco_radar', isVisible: false),
      DynamicReportColumn(id: 'ecoShippingDate', categoryId: 'eco_radar', isVisible: false),
      DynamicReportColumn(id: 'ecoArrivalPort', categoryId: 'eco_radar', isVisible: false),
      DynamicReportColumn(id: 'ecoArrivalWarehouse', categoryId: 'eco_radar', isVisible: false),
      DynamicReportColumn(id: 'ecoSara', categoryId: 'eco_radar', isVisible: false),
      DynamicReportColumn(id: 'ecoMaro', categoryId: 'eco_radar', isVisible: false),
      DynamicReportColumn(id: 'ecoReadyToPickUp', categoryId: 'eco_radar', isVisible: false),
      DynamicReportColumn(id: 'ecoLatestUpdate', categoryId: 'eco_radar', isVisible: false),
      DynamicReportColumn(id: 'ecoSwiftDate', categoryId: 'eco_radar', isVisible: false),
      DynamicReportColumn(id: 'ecoSwiftAmount', categoryId: 'eco_radar', isVisible: false),
      DynamicReportColumn(id: 'ecoShippingCompany', categoryId: 'eco_radar', isVisible: false),
      DynamicReportColumn(id: 'ecoAcid', categoryId: 'eco_radar', isVisible: false),
    ];
  }

  List<DynamicReportColumn> _getActiveColumns() {
    switch (_templateMode) {
      case ReportTemplateMode.eco:
        return DynamicReportBuilderScreen.kEcoPresetColumnIds.map((id) => DynamicReportColumn(id: id, categoryId: 'eco_radar', isVisible: true)).toList();
      case ReportTemplateMode.scas:
        return DynamicReportBuilderScreen.kScasPresetColumnIds.map((id) => DynamicReportColumn(id: id, categoryId: 'scas_tracker', isVisible: true)).toList();
      case ReportTemplateMode.custom:
        return _masterColumns.where((c) => c.isVisible).toList();
    }
  }

  String _getCategoryTitle(BuildContext context, String catId) {
    final l = context.l10n;
    switch (catId) {
      case 'file_project': return l.dynCatFileAndProject;
      case 'commercial_po': return l.dynCatCommercialAndPo;
      case 'shipping_logistics': return l.dynCatShippingAndLogistics;
      case 'packages_cbm': return l.dynCatPackagesAndCbm;
      case 'customs_nafeza': return l.dynCatCustomsAndNafeza;
      case 'banking_swift': return l.dynCatBankingAndSwift;
      case 'scas_tracker': return l.dynCatScasTracking;
      case 'eco_radar': return l.dynCatEcoTracking;
      default: return catId;
    }
  }

  String _getColumnLabel(BuildContext context, String colId) {
    final l = context.l10n;
    switch (colId) {
      case 'importFileCode': return l.dynColImportFileCode;
      case 'customFileNumber': return l.dynColCustomFileNumber;
      case 'companyName': return l.dynColCompanyName;
      case 'supplierName': return l.dynColSupplierName;
      case 'brokerName': return l.dynColBrokerName;
      case 'projectNames': return l.dynColProjectNames;
      case 'owner': return l.dynColOwner;
      case 'status': return l.dynColStatus;
      case 'currentStage': return l.dynColCurrentStage;
      case 'progressPercent': return l.dynColProgressPercent;
      case 'priority': return l.dynColPriority;
      case 'nextAction': return l.dynColNextAction;
      case 'fileOpeningDate': return l.dynColFileOpeningDate;
      case 'notes': return l.dynColNotes;
      case 'updatedAt': return l.dynColUpdatedAt;
      case 'poNumber': return l.dynColPoNumber;
      case 'piNumber': return l.dynColPiNumber;
      case 'piValue': return l.dynColPiValue;
      case 'incotermCode': return l.dynColIncotermCode;
      case 'estimatedCost': return l.dynColEstimatedCost;
      case 'shipmentMode': return l.dynColShipmentMode;
      case 'shippingLine': return l.dynColShippingLine;
      case 'portOfLoading': return l.dynColPortOfLoading;
      case 'portOfDischarge': return l.dynColPortOfDischarge;
      case 'cargoReadyDate': return l.dynColCargoReadyDate;
      case 'requiredEta': return l.dynColRequiredEta;
      case 'targetFreeDays': return l.dynColTargetFreeDays;
      case 'totalPackages': return l.dynColTotalPackages;
      case 'grossWeightKg': return l.dynColGrossWeightKg;
      case 'totalCbm': return l.dynColTotalCbm;
      case 'acidNumber': return l.dynColAcidNumber;
      case 'acidIssueDate': return l.dynColAcidIssueDate;
      case 'acidExpiryDate': return l.dynColAcidExpiryDate;
      case 'form46No': return l.dynColForm46No;
      case 'customsReleaseStatus': return l.dynColCustomsReleaseStatus;
      case 'customsReleasedAt': return l.dynColCustomsReleasedAt;
      case 'form4No': return l.dynColForm4No;
      case 'form4ReceivedDate': return l.dynColForm4ReceivedDate;
      case 'swiftNo': return l.dynColSwiftNo;
      case 'swiftDate': return l.dynColSwiftDate;
      case 'swiftAmount': return l.dynColSwiftAmount;
      case 'ecoBroker': return l.dynColEcoBroker;
      case 'ecoShipmentNo': return l.dynColEcoShipmentNo;
      case 'ecoSupplier': return l.dynColEcoSupplier;
      case 'ecoProject': return l.dynColEcoProject;
      case 'ecoPiValue': return l.dynColEcoPiValue;
      case 'ecoShippingDate': return l.dynColEcoShippingDate;
      case 'ecoArrivalPort': return l.dynColEcoArrivalPort;
      case 'ecoArrivalWarehouse': return l.dynColEcoArrivalWarehouse;
      case 'ecoSara': return l.dynColEcoSara;
      case 'ecoMaro': return l.dynColEcoMaro;
      case 'ecoReadyToPickUp': return l.dynColEcoReadyToPickUp;
      case 'ecoLatestUpdate': return l.dynColEcoLatestUpdate;
      case 'ecoSwiftDate': return l.dynColEcoSwiftDate;
      case 'ecoSwiftAmount': return l.dynColEcoSwiftAmount;
      case 'ecoShippingCompany': return l.dynColEcoShippingCompany;
      case 'ecoAcid': return l.dynColEcoAcid;
      case 'scasProjectFileAcid': return l.dynColScasProjectFileAcid;
      case 'scasExFactory': return l.dynColScasExFactory;
      case 'scasOrderToOrigin': return l.dynColScasOrderToOrigin;
      case 'scasPickUpDate': return l.dynColScasPickUpDate;
      case 'scasDeparturePort': return l.dynColScasDeparturePort;
      case 'scasArrivalAlexPort': return l.dynColScasArrivalAlexPort;
      case 'scasOrigInvoice': return l.dynColScasOrigInvoice;
      case 'scasOrigPackingList': return l.dynColScasOrigPackingList;
      case 'scasOrigCoo': return l.dynColScasOrigCoo;
      case 'scasOrigBl': return l.dynColScasOrigBl;
      case 'scasOrigInsurance': return l.dynColScasOrigInsurance;
      case 'scasInsertNafeza': return l.dynColScasInsertNafeza;
      case 'scasBankForm4': return l.dynColScasBankForm4;
      case 'scasDeclare3A': return l.dynColScasDeclare3A;
      case 'scasMaterialReceived': return l.dynColScasMaterialReceived;
      default: return colId;
    }
  }

  String _getTemplateTitle(BuildContext context) {
    final l = context.l10n;
    switch (_templateMode) {
      case ReportTemplateMode.eco: return l.dynTemplateEco;
      case ReportTemplateMode.scas: return l.dynTemplateScas;
      case ReportTemplateMode.custom: return l.dynTemplateCustom;
    }
  }

  List<ImportFileModel> _filterFiles(List<ImportFileModel> files) {
    return files.where((f) {
      if (_filterMode != 'All' && f.shipmentMode != _filterMode) return false;
      if (_filterPriority != 'All' && f.priority != _filterPriority) return false;
      if (_filterStatus != 'All' && f.status != _filterStatus) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchCode = f.importFileCode.toLowerCase().contains(q) || (f.customFileNumber?.toLowerCase().contains(q) ?? false);
        final matchComp = f.companyName.toLowerCase().contains(q);
        final matchSup = f.supplierName.toLowerCase().contains(q);
        final matchProj = f.projectNames?.toLowerCase().contains(q) ?? false;
        final matchAcid = f.acidNumber?.toLowerCase().contains(q) ?? false;
        final matchBroker = f.brokerName?.toLowerCase().contains(q) ?? false;
        if (!matchCode && !matchComp && !matchSup && !matchProj && !matchAcid && !matchBroker) return false;
      }
      return true;
    }).toList();
  }

  String _getCellValue(ImportFileModel file, String colId) {
    switch (colId) {
      // File & Project
      case 'importFileCode':
        return file.importFileCode;
      case 'customFileNumber':
        return file.customFileNumber ?? file.importFileCode;
      case 'companyName':
        return file.companyName;
      case 'supplierName':
        return file.supplierName;
      case 'brokerName':
        return file.brokerName ?? '-';
      case 'projectNames':
        return file.projectNames ?? '-';
      case 'owner':
        return file.owner;
      case 'status':
        return file.status;
      case 'currentStage':
        return file.currentStage;
      case 'progressPercent':
        return '${file.progressPercent.toInt()}%';
      case 'priority':
        return file.priority;
      case 'nextAction':
        return file.nextAction;
      case 'fileOpeningDate':
        return file.fileOpeningDate ?? '-';
      case 'notes':
        return file.notes ?? '-';
      case 'updatedAt':
        return file.updatedAt.length >= 16 ? file.updatedAt.substring(0, 16) : file.updatedAt;

      // Commercial & PO
      case 'poNumber':
        return file.poNumber ?? (file.poIds != null && file.poIds!.isNotEmpty ? file.poIds!.join(', ') : '-');
      case 'piNumber':
        return file.piNumber ?? (file.invoicesData.isNotEmpty ? file.invoicesData.first.invoiceNo : '-');
      case 'piValue':
        return file.invoicesData.isNotEmpty
            ? '${file.invoicesData.first.currency} ${file.invoicesData.first.amount.toStringAsFixed(2)}'
            : '${file.estimatedCostCurrency} ${file.estimatedCost.toStringAsFixed(2)}';
      case 'incotermCode':
        return file.incotermCode;
      case 'estimatedCost':
        return '${file.estimatedCostCurrency} ${file.estimatedCost.toStringAsFixed(2)}';

      // Shipping & Logistics
      case 'shipmentMode':
        return file.shipmentMode;
      case 'shippingLine':
        return file.selectedScenario ?? (file.shippingInstructionsNotes ?? '-');
      case 'portOfLoading':
        return file.portOfLoading ?? '-';
      case 'portOfDischarge':
        return file.portOfDischarge ?? '-';
      case 'cargoReadyDate':
        return file.cargoReadyDate ?? '-';
      case 'requiredEta':
        return file.requiredEta ?? '-';
      case 'targetFreeDays':
        return '${file.targetFreeDays} Days';

      // Packages & CBM
      case 'totalPackages':
        return file.packingListsData.isNotEmpty
            ? file.packingListsData.fold<int>(0, (sum, p) => sum + p.totalPackages).toString()
            : '-';
      case 'grossWeightKg':
        return file.packingListsData.isNotEmpty
            ? '${file.packingListsData.fold<double>(0.0, (sum, p) => sum + p.grossWeightKg).toStringAsFixed(1)} kg'
            : '-';
      case 'totalCbm':
        return file.packingListsData.isNotEmpty
            ? '${file.packingListsData.fold<double>(0.0, (sum, p) => sum + p.cbm).toStringAsFixed(2)} CBM'
            : '-';

      // Customs & Nafeza
      case 'acidNumber':
        return file.acidNumber ?? '-';
      case 'acidIssueDate':
        return file.acidIssueDate ?? '-';
      case 'acidExpiryDate':
        return file.acidExpiryDate ?? '-';
      case 'form46No':
        return file.form46No ?? '-';
      case 'customsReleaseStatus':
        return file.isCustomsReleased ? 'مفرج عنه (Released)' : (file.status == 'Under Clearance' ? 'قيد التخليص' : file.status);
      case 'customsReleasedAt':
        return file.customsReleasedAt ?? '-';

      // Banking & Swift
      case 'form4No':
        return file.form4No ?? '-';
      case 'form4ReceivedDate':
        return file.form4ReceivedDate ?? '-';
      case 'swiftNo':
        return file.swiftNo ?? '-';
      case 'swiftDate':
        return file.swiftNo != null ? (file.form4ReceivedDate ?? file.fileOpeningDate ?? '-') : '-';
      case 'swiftAmount':
        return file.swiftNo != null
            ? (file.invoicesData.isNotEmpty
                ? '${file.invoicesData.first.currency} ${file.invoicesData.first.amount.toStringAsFixed(2)}'
                : '${file.estimatedCostCurrency} ${file.estimatedCost.toStringAsFixed(2)}')
            : '-';

      // ECO Specific
      case 'ecoBroker':
        return file.brokerName ?? '-';
      case 'ecoShipmentNo':
        return file.customFileNumber ?? file.importFileCode;
      case 'ecoSupplier':
        return file.supplierName;
      case 'ecoProject':
        return file.projectNames ?? '-';
      case 'ecoPiValue':
        return file.invoicesData.isNotEmpty
            ? '${file.invoicesData.first.currency} ${file.invoicesData.first.amount.toStringAsFixed(2)}'
            : '${file.estimatedCostCurrency} ${file.estimatedCost.toStringAsFixed(2)}';
      case 'ecoShippingDate':
        return file.cargoReadyDate != null ? '${file.cargoReadyDate} ${file.portOfLoading ?? ""}'.trim() : (file.portOfLoading ?? '-');
      case 'ecoArrivalPort':
        return file.requiredEta != null ? '${file.requiredEta} ${file.portOfDischarge ?? ""}'.trim() : (file.portOfDischarge ?? '-');
      case 'ecoArrivalWarehouse':
        return file.customsReleasedAt ?? (file.updatedAt.length >= 10 ? file.updatedAt.substring(0, 10) : '-');
      case 'ecoSara':
        return file.owner.isNotEmpty ? file.owner : 'SARA';
      case 'ecoMaro':
        return file.nextAction.isNotEmpty ? file.nextAction : (file.notes ?? 'MARO');
      case 'ecoReadyToPickUp':
        return file.cargoReadyDate ?? '-';
      case 'ecoLatestUpdate':
        return file.currentStage;
      case 'ecoSwiftDate':
        return file.swiftNo != null ? (file.form4ReceivedDate ?? '-') : '-';
      case 'ecoSwiftAmount':
        return file.swiftNo != null
            ? (file.invoicesData.isNotEmpty
                ? '${file.invoicesData.first.currency} ${file.invoicesData.first.amount.toStringAsFixed(2)}'
                : '${file.estimatedCostCurrency} ${file.estimatedCost.toStringAsFixed(2)}')
            : '-';
      case 'ecoShippingCompany':
        return file.selectedScenario ?? file.shipmentMode;
      case 'ecoAcid':
        return file.acidNumber != null ? 'ACID: ${file.acidNumber}' : '-';

      // SCAS Specific
      case 'scasProjectFileAcid':
        final proj = file.projectNames ?? 'General Project';
        final fCode = file.customFileNumber ?? file.importFileCode;
        final acid = file.acidNumber != null ? 'ACID: ${file.acidNumber}' : '';
        return '$proj\n$fCode\n$acid'.trim();
      case 'scasExFactory':
        final dateVal = file.cargoReadyDate ?? file.fileOpeningDate ?? '-';
        final valStr = file.invoicesData.isNotEmpty
            ? '${file.invoicesData.first.currency} ${file.invoicesData.first.amount.toStringAsFixed(2)}'
            : '${file.estimatedCostCurrency} ${file.estimatedCost.toStringAsFixed(2)}';
        return '$dateVal\n$valStr';
      case 'scasOrderToOrigin':
        final stage = file.currentStage.toLowerCase();
        return (stage.contains('feasibility') || stage.contains('planning')) ? 'Pending' : 'Done';
      case 'scasPickUpDate':
        return file.cargoReadyDate ?? file.fileOpeningDate ?? '-';
      case 'scasDeparturePort':
        return file.fileOpeningDate ?? '-';
      case 'scasArrivalAlexPort':
        return file.requiredEta ?? '-';
      case 'scasOrigInvoice':
        return file.invoicesData.isNotEmpty
            ? 'Received\n${file.invoicesData.first.date ?? file.invoicesData.first.invoiceNo}'
            : 'Received';
      case 'scasOrigPackingList':
        return file.packingListsData.isNotEmpty
            ? 'Received\n${file.packingListsData.first.date ?? file.packingListsData.first.plNo}'
            : 'Received';
      case 'scasOrigCoo':
        return file.supplierName.isNotEmpty ? 'Received\nOrigin OK' : 'Received';
      case 'scasOrigBl':
        return file.selectedScenario != null && file.selectedScenario!.isNotEmpty
            ? 'Received\n${file.selectedScenario}'
            : 'Received Express';
      case 'scasOrigInsurance':
        final inc = file.incotermCode.toUpperCase();
        return (inc == 'CIF' || inc == 'CIP') ? 'Covered (Origin)' : 'Received / Issued';
      case 'scasInsertNafeza':
        return file.acidNumber != null ? 'Done\n(${file.acidIssueDate ?? "Active"})' : 'Pending ACID';
      case 'scasBankForm4':
        return file.form4No != null ? 'Received (Form 4)\nNo: ${file.form4No}' : 'Pending Bank';
      case 'scasDeclare3A':
        return file.form46No != null ? 'Done (Form 46)\nNo: ${file.form46No}' : 'Pending 46';
      case 'scasMaterialReceived':
        return file.isCustomsReleased
            ? 'Delivered / Store\n(${file.customsReleasedAt ?? "Released"})'
            : (file.status == 'Under Clearance' ? 'In Clearance (Port)' : file.status);

      default:
        return '-';
    }
  }

  Future<void> _exportToCSV(List<ImportFileModel> files) async {
    final l = context.l10n;
    final visibleCols = _getActiveColumns();
    const bom = '\uFEFF';
    final timestampStr = _formatDateTime(_lastUpdatedAt);
    final headerMeta = '# ${l.dynTemplatePresetLabel}: ${_getTemplateTitle(context)} | ${l.dynLastUpdatedLabel(timestampStr)} | Records: ${files.length}';
    final headerRow = visibleCols.map((c) => _getColumnLabel(context, c.id)).join(',');

    final rows = files.map((f) {
      return visibleCols.map((c) {
        final val = _getCellValue(f, c.id).replaceAll('\n', ' / ');
        return '"${val.replaceAll('"', '""')}"';
      }).join(',');
    }).toList();

    final csvContent = '$bom$headerMeta\n$headerRow\n${rows.join('\n')}';
    final filename = 'Reports_${_templateMode.name.toUpperCase()}_${DateTime.now().millisecondsSinceEpoch}.csv';

    await FileSaveHelper.saveText(
      context: context,
      textContent: csvContent,
      defaultFileName: filename,
      dialogTitle: 'تصدير التقرير بصيغة Excel / CSV',
      allowedExtensions: ['csv', 'xlsx'],
    );
  }

  Future<void> _exportToPDF(List<ImportFileModel> files) async {
    final l = context.l10n;
    final visibleCols = _getActiveColumns();
    final doc = pw.Document();
    final timestampStr = _formatDateTime(_lastUpdatedAt);
    final templateTitle = _getTemplateTitle(context);

    final headers = visibleCols.map((c) => _getColumnLabel(context, c.id)).toList();
    final tableData = files.map((f) {
      return visibleCols.map((c) => _getCellValue(f, c.id).replaceAll('\n', ' ')).toList();
    }).toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(18),
        build: (pw.Context pdfContext) => [
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blueGrey800, width: 2)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      l.dynPdfReportTitle,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey800,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      '${l.dynTemplatePresetLabel}: $templateTitle | ${l.dynLastUpdatedLabel(timestampStr)} | Records: ${files.length}',
                      style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.blueGrey200, width: 0.5),
            columnWidths: {
              for (int i = 0; i < headers.length; i++)
                i: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                children: headers.map((h) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: pw.Text(
                    h,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textDirection: pw.TextDirection.rtl,
                  ),
                )).toList(),
              ),
              ...tableData.asMap().entries.map((entry) {
                final isEven = entry.key.isEven;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: isEven ? PdfColors.blueGrey50 : PdfColors.white,
                  ),
                  children: entry.value.map((cell) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                    child: pw.Text(
                      cell,
                      style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.blueGrey900),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  )).toList(),
                );
              }),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(l.dynPdfConfidential, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              pw.Text('${files.length} records', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            ],
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    final filename = 'Reports_${_templateMode.name.toUpperCase()}_${DateTime.now().millisecondsSinceEpoch}.pdf';

    if (!mounted) return;
    await FileSaveHelper.saveBytes(
      context: context,
      bytes: bytes,
      defaultFileName: filename,
      dialogTitle: 'تصدير التقرير بصيغة PDF',
      allowedExtensions: ['pdf'],
    );
  }

  Future<void> _copyDataToClipboard(List<ImportFileModel> files) async {
    final visibleCols = _getActiveColumns();
    final headers = visibleCols.map((c) => _getColumnLabel(context, c.id)).join('\t');
    final rows = files.map((f) {
      return visibleCols.map((c) => _getCellValue(f, c.id).replaceAll('\n', ' / ')).join('\t');
    }).join('\n');

    final content = '$headers\n$rows';
    await Clipboard.setData(ClipboardData(text: content));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ بيانات ${files.length} شحنة إلى الحافظة بنجاح (جاهزة للصق المباشر في Excel)'),
        backgroundColor: AppTheme.emerald,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showColumnPicker() {
    final l = context.l10n;
    String filterText = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final categories = [
              'file_project',
              'commercial_po',
              'shipping_logistics',
              'packages_cbm',
              'customs_nafeza',
              'banking_swift',
              'scas_tracker',
              'eco_radar',
            ];

            return Container(
              height: MediaQuery.of(context).size.height * 0.82,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.view_column, color: AppTheme.cobalt, size: 26),
                      const SizedBox(width: 10),
                      Text(l.dynColumnPickerTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const Spacer(),
                      IconButton(onPressed: () => Navigator.pop(c), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'اختر الحقول المطلوب إدراجها بالتقرير، أو استخدم القوالب الجاهزة (ECO / SCAS)',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: l.dynSearchColumnsPlaceholder,
                            prefixIcon: const Icon(Icons.search, size: 20),
                            isDense: true,
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (val) {
                            setSheetState(() => filterText = val.trim().toLowerCase());
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                        onPressed: () {
                          setSheetState(() {
                            for (var col in _masterColumns) {
                              col.isVisible = true;
                            }
                          });
                          setState(() {});
                        },
                        icon: const Icon(Icons.select_all, size: 18),
                        label: Text(l.dynSelectAll),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                        onPressed: () {
                          setSheetState(() {
                            for (var col in _masterColumns) {
                              col.isVisible = false;
                            }
                          });
                          setState(() {});
                        },
                        icon: const Icon(Icons.deselect, size: 18),
                        label: Text(l.dynDeselectAll),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, catIdx) {
                        final catId = categories[catIdx];
                        final catCols = _masterColumns.where((col) {
                          if (col.categoryId != catId) return false;
                          if (filterText.isEmpty) return true;
                          final label = _getColumnLabel(context, col.id).toLowerCase();
                          return label.contains(filterText) || col.id.toLowerCase().contains(filterText);
                        }).toList();

                        if (catCols.isEmpty) return const SizedBox.shrink();

                        final allChecked = catCols.every((c) => c.isVisible);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              initiallyExpanded: true,
                              title: Row(
                                children: [
                                  Text(
                                    _getCategoryTitle(context, catId),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.cobalt.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${catCols.where((c) => c.isVisible).length}/${catCols.length}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.cobalt),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(allChecked ? Icons.check_box : Icons.check_box_outline_blank, color: AppTheme.cobalt),
                                tooltip: allChecked ? l.dynDeselectAll : l.dynSelectAll,
                                onPressed: () {
                                  setSheetState(() {
                                    final target = !allChecked;
                                    for (var col in catCols) {
                                      col.isVisible = target;
                                    }
                                  });
                                  setState(() {});
                                },
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: catCols.map((col) {
                                      return FilterChip(
                                        selected: col.isVisible,
                                        label: Text(_getColumnLabel(context, col.id), style: const TextStyle(fontSize: 12)),
                                        selectedColor: AppTheme.cobalt.withOpacity(0.2),
                                        checkmarkColor: AppTheme.cobalt,
                                        onSelected: (val) {
                                          setSheetState(() => col.isVisible = val);
                                          setState(() {});
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, minimumSize: const Size.fromHeight(48)),
                    onPressed: () {
                      setState(() {
                        _templateMode = ReportTemplateMode.custom;
                      });
                      Navigator.pop(c);
                    },
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: Text(l.dynApplyColumnsBtn, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final importFilesState = ref.watch(importFilesProvider);
    final activeCols = _getActiveColumns();
    final timestampFormatted = _formatDateTime(_lastUpdatedAt);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppTheme.charcoal,
        title: Row(
          children: [
            const Icon(Icons.assessment, color: AppTheme.cobalt),
            const SizedBox(width: 10),
            Text(l.dynReportBuilderTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: AppTheme.emerald),
                  const SizedBox(width: 6),
                  Text(
                    l.dynLastUpdatedLabel(timestampFormatted),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'تحديث البيانات والوقت',
            onPressed: _refreshData,
          ),
          const BackToDashboardButton(),
        ],
      ),
      body: SelectionArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Template Selector and Action Toolbar Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Template Selection Chips
                          Text('${l.dynTemplatePresetLabel}:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(width: 10),
                          ChoiceChip(
                            label: Row(
                              children: [
                                const Icon(Icons.radar, size: 16),
                                const SizedBox(width: 6),
                                Text(l.dynTemplateEco),
                              ],
                            ),
                            selected: _templateMode == ReportTemplateMode.eco,
                            selectedColor: AppTheme.cobalt.withOpacity(0.2),
                            onSelected: (val) {
                              if (val) setState(() => _templateMode = ReportTemplateMode.eco);
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Row(
                              children: [
                                const Icon(Icons.assignment_turned_in, size: 16),
                                const SizedBox(width: 6),
                                Text(l.dynTemplateScas),
                              ],
                            ),
                            selected: _templateMode == ReportTemplateMode.scas,
                            selectedColor: AppTheme.cobalt.withOpacity(0.2),
                            onSelected: (val) {
                              if (val) setState(() => _templateMode = ReportTemplateMode.scas);
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Row(
                              children: [
                                const Icon(Icons.tune, size: 16),
                                const SizedBox(width: 6),
                                Text(l.dynTemplateCustom),
                              ],
                            ),
                            selected: _templateMode == ReportTemplateMode.custom,
                            selectedColor: AppTheme.cobalt.withOpacity(0.2),
                            onSelected: (val) {
                              if (val) setState(() => _templateMode = ReportTemplateMode.custom);
                            },
                          ),

                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _templateMode == ReportTemplateMode.custom ? AppTheme.cobalt : Colors.grey.shade700,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            onPressed: _showColumnPicker,
                            icon: const Icon(Icons.view_column, color: Colors.white, size: 18),
                            label: Text(
                              _templateMode == ReportTemplateMode.custom
                                  ? l.dynCustomizeColumnsBtn(activeCols.length, _masterColumns.length)
                                  : 'تخصيص أعمدة التقرير',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),

                          const Spacer(),

                          importFilesState.when(
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                            data: (files) {
                              final filtered = _filterFiles(files);
                              return Row(
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.emerald,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    ),
                                    onPressed: () => _exportToCSV(filtered),
                                    icon: const Icon(Icons.table_chart, color: Colors.white, size: 18),
                                    label: Text(l.dynExportExcelBtn(filtered.length), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFC0392B),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    ),
                                    onPressed: () => _exportToPDF(filtered),
                                    icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 18),
                                    label: Text(l.dynExportPdfBtn(filtered.length), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.charcoal,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    ),
                                    onPressed: () => _copyDataToClipboard(filtered),
                                    icon: const Icon(Icons.copy, color: Colors.white, size: 18),
                                    label: const Text('نسخ كـ Excel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      // Search and Filters Row
                      Row(
                        children: [
                          // Search Input
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'ابحث بكود الملف، العميل، المورد، المشروع، رقم ACID أو المخلص...',
                                prefixIcon: const Icon(Icons.search, size: 20),
                                isDense: true,
                                border: const OutlineInputBorder(),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                              ),
                              onChanged: (v) => setState(() => _searchQuery = v.trim()),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Filter Mode
                          SizedBox(
                            width: 150,
                            child: DropdownButtonFormField<String>(
                              value: _filterMode,
                              decoration: InputDecoration(labelText: l.dynFilterModeLabel, isDense: true, border: const OutlineInputBorder()),
                              items: [
                                DropdownMenuItem(value: 'All', child: Text(l.dynModeAll)),
                                DropdownMenuItem(value: 'Sea FCL', child: Text(l.dynModeSeaFcl)),
                                DropdownMenuItem(value: 'Sea LCL', child: Text(l.dynModeSeaLcl)),
                                DropdownMenuItem(value: 'Air', child: Text(l.dynModeAir)),
                                DropdownMenuItem(value: 'Courier', child: Text(l.dynModeCourier)),
                                DropdownMenuItem(value: 'Land', child: Text(l.dynModeLand)),
                                DropdownMenuItem(value: 'Multimodal', child: Text(l.dynModeMultimodal)),
                              ],
                              onChanged: (v) => setState(() => _filterMode = v!),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Filter Priority
                          SizedBox(
                            width: 140,
                            child: DropdownButtonFormField<String>(
                              value: _filterPriority,
                              decoration: InputDecoration(labelText: l.dynFilterPriorityLabel, isDense: true, border: const OutlineInputBorder()),
                              items: [
                                DropdownMenuItem(value: 'All', child: Text(l.dynPriorityAll)),
                                DropdownMenuItem(value: 'High', child: Text(l.dynPriorityHigh)),
                                DropdownMenuItem(value: 'Critical', child: Text(l.dynPriorityCritical)),
                                DropdownMenuItem(value: 'Medium', child: Text(l.dynPriorityMedium)),
                              ],
                              onChanged: (v) => setState(() => _filterPriority = v!),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Active Columns Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.cobalt.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.cobalt.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.view_column, size: 16, color: AppTheme.cobalt),
                                const SizedBox(width: 6),
                                Text(
                                  'الأعمدة: ${activeCols.length}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.cobalt),
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
              const SizedBox(height: 12),

              // Live Table Preview
              Expanded(
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: importFilesState.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text(l.dynFetchReportError(err.toString()), style: const TextStyle(color: AppTheme.crimson))),
                    data: (files) {
                      final filtered = _filterFiles(files);
                      if (filtered.isEmpty) {
                        return Center(child: Text(l.dynNoMatchingShipments));
                      }

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(AppTheme.charcoal.withOpacity(0.06)),
                            headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.charcoal, fontSize: 12),
                            dataTextStyle: const TextStyle(fontSize: 12, color: AppTheme.charcoal),
                            columns: activeCols.map((c) {
                              return DataColumn(
                                label: Text(
                                  _getColumnLabel(context, c.id),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              );
                            }).toList(),
                            rows: filtered.asMap().entries.map((entry) {
                              final isEven = entry.key.isEven;
                              final file = entry.value;

                              return DataRow(
                                color: WidgetStateProperty.all(isEven ? Colors.grey.shade50 : Colors.white),
                                cells: activeCols.map((col) {
                                  final textVal = _getCellValue(file, col.id);

                                  // Highlighted columns
                                  final isCode = col.id == 'importFileCode' || col.id == 'ecoShipmentNo';
                                  final isStatus = col.id == 'status' || col.id == 'currentStage';

                                  return DataCell(
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Text(
                                        textVal,
                                        style: TextStyle(
                                          fontWeight: isCode ? FontWeight.bold : FontWeight.normal,
                                          color: isCode
                                              ? AppTheme.cobalt
                                              : (isStatus ? AppTheme.charcoal : Colors.grey.shade900),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

