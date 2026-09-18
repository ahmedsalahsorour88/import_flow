import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../import_files/models/import_file_model.dart';
import 'draft_bl_review_tab.dart';

class DraftBLReviewDialog extends StatelessWidget {
  final ImportFileModel file;

  const DraftBLReviewDialog({
    super.key,
    required this.file,
  });

  static Future<void> show(
    BuildContext context,
    ImportFileModel file,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => DraftBLReviewDialog(file: file),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;
    final dialogWidth = (media.width * 0.94).clamp(900.0, 1500.0);
    final dialogHeight = (media.height * 0.90).clamp(600.0, 950.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  color: AppTheme.charcoal,
                  border: Border(
                    bottom: BorderSide(color: Colors.white10),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.fact_check_rounded,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 10,
                            runSpacing: 4,
                            children: [
                              const Text(
                                'مراجعة مسودة بوليصة الشحن والاعتماد المزدوج (SH-02)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.cobalt.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppTheme.cobalt.withOpacity(0.5)),
                                ),
                                child: Text(
                                  file.primaryNameWithCode,
                                  style: const TextStyle(
                                    color: AppTheme.cobalt,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'مطابقة آلية لـ 20 حقلاً حرجاً مع أمر الشراء والفاتورة التجارية ومنع غرامات التعديل الجمركي',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      tooltip: 'إغلاق',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Content Body
              Expanded(
                child: DraftBLReviewTab(
                  initialImportFileId: file.importFileId,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
