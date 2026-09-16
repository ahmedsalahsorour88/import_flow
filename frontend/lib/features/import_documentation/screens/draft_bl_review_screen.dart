import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/dedicated_stage_scaffold.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../providers/import_documentation_provider.dart';
import '../widgets/draft_bl_review_tab.dart';
import '../widgets/formal_letter_generator_dialog.dart';
import '../widgets/search_and_clone_draft_bl_dialog.dart';

/// Stage 2 of Draft Documents: Draft B/L Review & Approval Screen (Full-Width View)
class DraftBLReviewScreen extends ConsumerStatefulWidget {
  final int? initialImportFileId;

  const DraftBLReviewScreen({
    super.key,
    this.initialImportFileId,
  });

  @override
  ConsumerState<DraftBLReviewScreen> createState() => _DraftBLReviewScreenState();
}

class _DraftBLReviewScreenState extends ConsumerState<DraftBLReviewScreen> {
  int? _selectedImportFileId;

  @override
  void initState() {
    super.initState();
    _selectedImportFileId = widget.initialImportFileId;
    Future.microtask(() => _refreshData());
  }

  @override
  void didUpdateWidget(covariant DraftBLReviewScreen oldWidget) {
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

  void _openSearchAndCloneDialog() {
    final allReviews = ref.read(draftBLReviewsProvider).valueOrNull ?? [];
    showDialog(
      context: context,
      builder: (ctx) => SearchAndCloneDraftBlDialog(
        reviews: allReviews,
        onSelectReview: (r) {
          setState(() {
            _selectedImportFileId = r.importFileId ?? _selectedImportFileId;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyD, control: true): _openSearchAndCloneDialog,
      },
      child: Focus(
        autofocus: true,
        child: DedicatedStageScaffold(
          stageCode: 'STEP_08_BL',
          titleAr: 'مراجعة وتدقيق مسودة بوليصة الشحن (B/L)',
          titleEn: 'Draft B/L Review & Approval',
          headerIcon: Icons.assignment_turned_in_outlined,
          headerColor: AppTheme.emerald,
          selectedImportFileId: _selectedImportFileId,
          onShipmentStatusChanged: _refreshData,
          headerActions: [
            IconButton(
              key: const Key('searchAndCloneDraftBlBtn'),
              icon: const Icon(Icons.copy_all, color: Colors.white70),
              tooltip: l.searchAndCloneDraftBlBtn,
              onPressed: _openSearchAndCloneDialog,
            ),
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
          body: DraftBLReviewTab(
            initialImportFileId: _selectedImportFileId,
          ),
        ),
      ),
    );
  }
}
