import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../constants/api_constants.dart';
import '../theme/app_theme.dart';

class MasterDataToolbarWidget extends StatefulWidget {
  final String moduleEndpoint; // e.g. "import-companies", "suppliers", "external-service-providers", "projects"
  final String title;
  final VoidCallback onRefreshNeeded;
  final VoidCallback? onDownloadTemplate;
  final VoidCallback? onImportExcel;
  final VoidCallback? onExportExcel;
  final VoidCallback? onExportPdf;

  const MasterDataToolbarWidget({
    super.key,
    required this.moduleEndpoint,
    required this.title,
    required this.onRefreshNeeded,
    this.onDownloadTemplate,
    this.onImportExcel,
    this.onExportExcel,
    this.onExportPdf,
  });

  @override
  State<MasterDataToolbarWidget> createState() => _MasterDataToolbarWidgetState();
}

class _MasterDataToolbarWidgetState extends State<MasterDataToolbarWidget> {
  bool _isUploading = false;

  Future<void> _downloadFile(String actionEndpoint, String defaultFileName) async {
    final url = '${ApiConstants.baseUrl}/${widget.moduleEndpoint}/$actionEndpoint';
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloading $defaultFileName from: $url'),
          backgroundColor: AppTheme.cobalt,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handleImportExcel() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not read file bytes'), backgroundColor: AppTheme.crimson),
          );
        }
        return;
      }

      setState(() => _isUploading = true);

      final dio = Dio();
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
      });

      final response = await dio.post(
        '${ApiConstants.baseUrl}/${widget.moduleEndpoint}/import-excel',
        data: formData,
      );

      setState(() => _isUploading = false);

      if (mounted) {
        final message = response.data['message'] ?? 'Import complete';
        final List errors = response.data['errors'] ?? [];

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(errors.isEmpty ? Icons.check_circle : Icons.warning_amber,
                    color: errors.isEmpty ? AppTheme.emerald : AppTheme.orange),
                const SizedBox(width: 8),
                Text(errors.isEmpty ? 'Import Successful' : 'Import Completed with Alerts'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (errors.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Alerts / Errors:', style: TextStyle(color: AppTheme.crimson, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    ...errors.map((err) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text('• $err', style: const TextStyle(fontSize: 12)),
                        )),
                  ]
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  widget.onRefreshNeeded();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e'), backgroundColor: AppTheme.crimson),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.table_chart_outlined, color: AppTheme.cobalt, size: 20),
              const SizedBox(width: 8),
              Text(
                'Data Actions & Export/Import',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade800),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 0. Live Refresh Button
              ElevatedButton.icon(
                onPressed: widget.onRefreshNeeded,
                icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
                label: const Text('إعادة تحميل حية 🔄', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.charcoal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(width: 8),

              // 1. Download Template
              OutlinedButton.icon(
                onPressed: widget.onDownloadTemplate ?? () => _downloadFile('excel-template', '${widget.title}_Template.xlsx'),
                icon: const Icon(Icons.download, size: 16, color: AppTheme.charcoal),
                label: const Text('Download Excel Template', style: TextStyle(fontSize: 12, color: AppTheme.charcoal)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
              ),
              const SizedBox(width: 8),

              // 2. Upload Excel
              ElevatedButton.icon(
                onPressed: _isUploading ? null : (widget.onImportExcel ?? _handleImportExcel),
                icon: _isUploading
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.upload_file, size: 16, color: Colors.white),
                label: Text(_isUploading ? 'Uploading...' : 'Import Excel', style: const TextStyle(fontSize: 12, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emerald,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(width: 8),

              // 3. Export Excel
              ElevatedButton.icon(
                onPressed: widget.onExportExcel ?? () => _downloadFile('export-excel', '${widget.title}_Report.xlsx'),
                icon: const Icon(Icons.description, size: 16, color: Colors.white),
                label: const Text('Export Excel', style: TextStyle(fontSize: 12, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cobalt,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(width: 8),

              // 4. Export PDF
              ElevatedButton.icon(
                onPressed: widget.onExportPdf ?? () => _downloadFile('export-pdf', '${widget.title}_Report.pdf'),
                icon: const Icon(Icons.picture_as_pdf, size: 16, color: Colors.white),
                label: const Text('Export PDF', style: TextStyle(fontSize: 12, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
