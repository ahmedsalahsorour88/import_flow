import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/vertical_stage_scaffold.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../providers/import_documentation_provider.dart';
import '../widgets/coo_review_tab.dart';
import '../widgets/customs_document_approval_tab.dart';
import '../widgets/draft_bl_review_tab.dart';
import '../widgets/inspection_review_tab.dart';
import '../widgets/invoice_bl_matcher_tab.dart';
import '../widgets/po_reconciliation_tab.dart';
import '../../cargo_insurance/screens/cargo_insurance_screen.dart';


class ShipmentDraftDocsScreen extends ConsumerStatefulWidget {
  final int initialSubTab;
  final int? initialImportFileId;

  const ShipmentDraftDocsScreen({
    super.key,
    this.initialSubTab = 0,
    this.initialImportFileId,
  });

  @override
  ConsumerState<ShipmentDraftDocsScreen> createState() => _ShipmentDraftDocsScreenState();
}

class _ShipmentDraftDocsScreenState extends ConsumerState<ShipmentDraftDocsScreen> {
  // Active Vertical Sub-Tab:
  // 0: 🛡️ مركز اعتماد المستندات الجمركية (Docs Customs Approval Hub)
  // 1: 📦 مطابقة الفاتورة والباكينج (PO & Packing Reconciliation)
  // 2: 📄 مسودة بوليصة الشحن (Draft B/L Review & Dual Approval)
  // 3: ⚡ الاستخراج ومطابقة الفاتورة والبوليصة (Smart Invoice vs. B/L Reconciliation)
  // 4: 📜 مسودة شهادة المنشأ و EUR.1 (Draft COO / EUR.1 Review)
  // 5: 🛡️ شهادات الفحص والمطابقة (Inspection & Conformity Review)
  // NOTE: Original Docs Collection & CargoX have been moved to OriginalDocsAndCargoXScreen (Phase 4)
  int _selectedSubTab = 0;
  int? _selectedImportFileId;

  @override
  void initState() {
    super.initState();
    _selectedSubTab = widget.initialSubTab;
    _selectedImportFileId = widget.initialImportFileId;
    Future.microtask(() {
      _refreshData();
    });
  }

  @override
  void didUpdateWidget(covariant ShipmentDraftDocsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSubTab != widget.initialSubTab) {
      setState(() {
        _selectedSubTab = widget.initialSubTab;
      });
    }
  }

  Future<void> _refreshData() async {
    await ref.read(importFilesProvider.notifier).fetchImportFiles();
    final files = ref.read(importFilesProvider).value ?? [];
    ref.read(shipmentDocumentsProvider.notifier).fetchShipmentDocuments();
    if (_selectedImportFileId == null && files.isNotEmpty && mounted) {
      setState(() {
        _selectedImportFileId = files.first.importFileId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [

      const VerticalNavTabItem(
        icon: Icons.verified_user,
        titleEn: 'Docs Customs Approval & Rectifications Hub',
        titleAr: 'مركز اعتماد المستندات وتعديلات المورد',
      ),
      const VerticalNavTabItem(
        icon: Icons.fact_check_outlined,
        titleEn: 'PO & Packing Reconciliation',
        titleAr: 'مطابقة الفاتورة وقائمة التعبئة',
      ),
      const VerticalNavTabItem(
        icon: Icons.assignment_turned_in_outlined,
        titleEn: 'Draft B/L Review & Approval',
        titleAr: 'مسودة بوليصة الشحن والاعتماد',
      ),
      const VerticalNavTabItem(
        icon: Icons.auto_awesome,
        titleEn: 'Smart Invoice vs B/L Match',
        titleAr: 'استخراج ومطابقة الفاتورة والبوليصة',
      ),
      const VerticalNavTabItem(
        icon: Icons.flag_circle_outlined,
        titleEn: 'Draft COO & EUR.1 Review',
        titleAr: 'مسودة شهادة المنشأ و EUR.1',
      ),
      const VerticalNavTabItem(
        icon: Icons.security_outlined,
        titleEn: 'Inspection Review',
        titleAr: 'شهادات الفحص والمطابقة',
      ),
      const VerticalNavTabItem(
        icon: Icons.shield_outlined,
        titleEn: 'Cargo Insurance Certificate',
        titleAr: 'وثيقة وشهادة التأمين على البضائع',
      ),
    ];

    return VerticalStageScaffold(
      stageCode: 'PHASE-3',
      titleEn: 'Shipment Draft Documents Review',
      titleAr: 'مراجعة وتدقيق مسودات مستندات الشحن — المرحلة 3',
      headerIcon: Icons.folder_open_outlined,
      headerColor: AppTheme.emerald,
      tabs: tabs,
      selectedIndex: _selectedSubTab,
      onTabSelected: (index) => setState(() => _selectedSubTab = index),
      selectedImportFileId: _selectedImportFileId,
      onShipmentStatusChanged: _refreshData,
      headerActions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70),
          tooltip: context.l10n.refresh,
          onPressed: _refreshData,
        ),
      ],
      body: _buildCurrentSubTabContent(),
    );
  }

  Widget _buildCurrentSubTabContent() {
    switch (_selectedSubTab) {
      case 0:
        return CustomsDocumentApprovalTab(initialImportFileId: _selectedImportFileId);
      case 1:
        return POReconciliationTab(initialImportFileId: _selectedImportFileId);
      case 2:
        return DraftBLReviewTab(initialImportFileId: _selectedImportFileId);
      case 3:
        return InvoiceBLMatcherTab(
          selectedImportFileId: _selectedImportFileId,
          onImportFileChanged: (newId) {
            setState(() {
              _selectedImportFileId = newId;
            });
          },
        );
      case 4:
        return COOReviewTab(initialImportFileId: _selectedImportFileId);
      case 5:
        return InspectionReviewTab(initialImportFileId: _selectedImportFileId);
      case 6:
        return CargoInsuranceScreen(
          key: ValueKey('cargo_insurance_embedded_$_selectedImportFileId'),
          initialImportFileId: _selectedImportFileId,
          isEmbedded: true,
        );
      default:
        return CustomsDocumentApprovalTab(initialImportFileId: _selectedImportFileId);
    }
  }
}

