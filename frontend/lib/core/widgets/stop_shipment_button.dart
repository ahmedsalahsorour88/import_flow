import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../localization/app_localizations.dart';
import '../theme/app_theme.dart';
import '../../features/import_files/models/import_file_model.dart';
import 'stop_shipment_dialog.dart';

class StopShipmentButton extends ConsumerWidget {
  final ImportFileModel? importFile;
  final String currentPhaseName;
  final VoidCallback? onSuccess;

  const StopShipmentButton({
    super.key,
    required this.importFile,
    required this.currentPhaseName,
    this.onSuccess,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (importFile == null || importFile!.status == 'Closed') {
      return const SizedBox.shrink();
    }

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.crimson,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      onPressed: () {
        StopShipmentDialog.show(
          context,
          importFile: importFile!,
          currentPhaseName: currentPhaseName,
          onSuccess: onSuccess,
        );
      },
      icon: const Icon(Icons.cancel_outlined, size: 16),
      label: Text(
        context.l10n.stopShipmentAtThisStageBtn,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
