import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/dedicated_stage_scaffold.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../widgets/formal_letter_generator_dialog.dart';
import '../widgets/inspection_review_tab.dart';

/// Stage 5 of Draft Documents: Inspection & Conformity Review (COC) Screen (Full-Width View)
class DraftInspectionReviewScreen extends ConsumerStatefulWidget {
  final int? initialImportFileId;

  const DraftInspectionReviewScreen({
    super.key,
    this.initialImportFileId,
  });

  @override
  ConsumerState<DraftInspectionReviewScreen> createState() => _DraftInspectionReviewScreenState();
}

class _DraftInspectionReviewScreenState extends ConsumerState<DraftInspectionReviewScreen> {
  int? _selectedImportFileId;

  @override
  void initState() {
    super.initState();
    _selectedImportFileId = widget.initialImportFileId;
    Future.microtask(() => _refreshData());
  }

  @override
  void didUpdateWidget(covariant DraftInspectionReviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialImportFileId != widget.initialImportFileId && widget.initialImportFileId != null) {
      setState(() {
        _selectedImportFileId = widget.initialImportFileId;
      });
    }
  }

  Future<void> _refreshData() async {
    if (!ref.read(importFilesProvider).isLoading) {
      await ref.read(importFilesProvider.notifier).fetchImportFiles();
    }
    final files = ref.read(importFilesProvider).valueOrNull ?? [];
    if (_selectedImportFileId == null && files.isNotEmpty && mounted) {
      setState(() {
        _selectedImportFileId = files.first.importFileId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return DedicatedStageScaffold(
      stageCode: 'STEP_08_COC',
      titleAr: 'شهادات الفحص والتفتيش المسبق والمطابقة (COC)',
      titleEn: 'Inspection & Conformity Review (COC)',
      headerIcon: Icons.security_outlined,
      headerColor: Colors.indigo,
      selectedImportFileId: _selectedImportFileId,
      onShipmentStatusChanged: _refreshData,
      headerActions: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onPressed: () => FormalLetterGeneratorDialog.show(context, importFileId: _selectedImportFileId),
          icon: const Icon(Icons.description, size: 16, color: Colors.indigo),
          label: Text(l.formalLetterDialogTitle),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70),
          tooltip: l.refresh,
          onPressed: _refreshData,
        ),
      ],
      body: InspectionReviewTab(
        initialImportFileId: _selectedImportFileId,
      ),
    );
  }
}
