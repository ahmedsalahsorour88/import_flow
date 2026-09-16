import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/dedicated_stage_scaffold.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../widgets/formal_letter_generator_dialog.dart';
import '../widgets/invoice_bl_matcher_tab.dart';

/// Stage 3 of Draft Documents: Smart Invoice vs B/L Match Screen (Full-Width View)
class SmartInvoiceBLMatchScreen extends ConsumerStatefulWidget {
  final int? initialImportFileId;

  const SmartInvoiceBLMatchScreen({
    super.key,
    this.initialImportFileId,
  });

  @override
  ConsumerState<SmartInvoiceBLMatchScreen> createState() => _SmartInvoiceBLMatchScreenState();
}

class _SmartInvoiceBLMatchScreenState extends ConsumerState<SmartInvoiceBLMatchScreen> {
  int? _selectedImportFileId;

  @override
  void initState() {
    super.initState();
    _selectedImportFileId = widget.initialImportFileId;
    Future.microtask(() => _refreshData());
  }

  @override
  void didUpdateWidget(covariant SmartInvoiceBLMatchScreen oldWidget) {
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
      stageCode: 'STEP_08_MATCH',
      titleAr: 'المطابقة الذكية بين الفاتورة التجارية وبوليصة الشحن',
      titleEn: 'Smart Invoice vs B/L Match',
      headerIcon: Icons.auto_awesome,
      headerColor: Colors.deepPurple,
      selectedImportFileId: _selectedImportFileId,
      onShipmentStatusChanged: _refreshData,
      headerActions: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.charcoal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onPressed: () => FormalLetterGeneratorDialog.show(context, importFileId: _selectedImportFileId),
          icon: const Icon(Icons.description, size: 16, color: AppTheme.cobalt),
          label: Text(l.formalLetterDialogTitle),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70),
          tooltip: l.refresh,
          onPressed: _refreshData,
        ),
      ],
      body: InvoiceBLMatcherTab(
        selectedImportFileId: _selectedImportFileId,
        onImportFileChanged: (newId) {
          setState(() {
            _selectedImportFileId = newId;
          });
        },
      ),
    );
  }
}
