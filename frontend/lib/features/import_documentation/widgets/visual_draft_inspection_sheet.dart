import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../services/inspection_export_service.dart';

class VisualDraftInspectionSheet extends StatefulWidget {
  final Map<String, dynamic> templateData;
  final String agency;
  final String certType;
  final String acidNumber;
  final List<String> standards;
  final VoidCallback? onRefresh;

  const VisualDraftInspectionSheet({
    super.key,
    required this.templateData,
    required this.agency,
    required this.certType,
    required this.acidNumber,
    required this.standards,
    this.onRefresh,
  });

  @override
  State<VisualDraftInspectionSheet> createState() => _VisualDraftInspectionSheetState();
}

class _VisualDraftInspectionSheetState extends State<VisualDraftInspectionSheet> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.templateData;
    final cocNo = (t['coc_number'] ?? 'DRAFT-COC').toString();
    final importer = (t['importer_name_and_address'] ?? 'IMPORTER INFO').toString();
    final exporter = (t['exporter_name_and_address'] ?? 'EXPORTER INFO').toString();
    final origin = (t['country_of_origin'] ?? 'UNKNOWN').toString();
    final originsList = (t['countries_of_origin_list'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [origin];
    final hsCodes = (t['hs_code'] ?? '560229').toString();
    final hsCodesList = (t['hs_codes_list'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [hsCodes];
    final totalValue = (t['total_value'] ?? 'N/A').toString();
    final portOfEntry = (t['port_of_entry'] ?? 'Alexandria').toString();
    final dateInsp = (t['date_of_inspection'] ?? DateTime.now().toString().split(' ')[0]).toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Icon(Icons.security, color: AppTheme.cobalt, size: 20),
                const SizedBox(width: 8),
                Text(
                  'مسودة شهادة الفحص والمطابقة: ${widget.agency} (${widget.certType})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                ),
                const SizedBox(width: 16),
                if (widget.onRefresh != null)
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 18, color: AppTheme.cobalt),
                    tooltip: 'تحديث حي للبيانات المستدعاة',
                    onPressed: widget.onRefresh,
                  ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                  icon: const Icon(Icons.copy, size: 14),
                  label: const Text('نسخ البيانات 📋', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    final text = InspectionExportService.exportInspectionCsv(
                      templateData: t,
                      agency: widget.agency,
                      certType: widget.certType,
                      acidNumber: widget.acidNumber,
                      standards: widget.standards,
                    );
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('📋 تم نسخ بيانات شهادة الفحص إلى الحافظة'), duration: Duration(seconds: 1)),
                    );
                  },
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: Colors.green.shade800,
                    side: BorderSide(color: Colors.green.shade600),
                  ),
                  icon: const Icon(Icons.table_chart_outlined, size: 14, color: Colors.green),
                  label: const Text('حفظ إكسل (Excel / CSV) 📊', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    final csv = InspectionExportService.exportInspectionCsv(
                      templateData: t,
                      agency: widget.agency,
                      certType: widget.certType,
                      acidNumber: widget.acidNumber,
                      standards: widget.standards,
                    );
                    Clipboard.setData(ClipboardData(text: csv));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('📊 تم تجهيز بيانات الإكسل لشهادة الفحص بنجاح'), backgroundColor: Colors.green),
                    );
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.cobalt,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: _isExporting
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.picture_as_pdf, size: 14, color: Colors.white),
                  label: const Text('حفظ وطباعة PDF 🖨️', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: _isExporting
                      ? null
                      : () async {
                          setState(() => _isExporting = true);
                          try {
                            await InspectionExportService.printOrSavePdf(
                              templateData: t,
                              agency: widget.agency,
                              certType: widget.certType,
                              acidNumber: widget.acidNumber,
                              standards: widget.standards,
                            );
                          } finally {
                            if (mounted) setState(() => _isExporting = false);
                          }
                        },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Official Visual Document Container
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.black87, width: 1.5),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Banner
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: const Border(bottom: BorderSide(color: Colors.black87, width: 1.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.agency.toUpperCase()} — CERTIFICATE OF CONFORMITY (COC / VOC)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.black),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'EGYPT MANDATORY VERIFICATION OF CONFORMITY (GOEIC / NFSA)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppTheme.cobalt),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('COC NO: $cocNo', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black)),
                        Text('ACID NO: ${widget.acidNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.green)),
                      ],
                    ),
                  ],
                ),
              ),

              // Parties Grid
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildBoxCell(
                      'Importer (Name, Address & Tax ID):',
                      importer,
                      hasRightBorder: true,
                    ),
                  ),
                  Expanded(
                    child: _buildBoxCell(
                      'Exporter & Producer (Name & Address):',
                      exporter,
                    ),
                  ),
                ],
              ),

              // Meta Row with multi-origin and multi-HS codes
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.black87, width: 0.8)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Country / Countries of Origin (بلاد المنشأ المستدعاة):', style: TextStyle(fontSize: 9.5, color: Colors.black54)),
                          const SizedBox(height: 3),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: originsList.map((c) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.blue.shade300)),
                                child: Text('🌍 $c', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('H.S. Codes (بنود التعريفة بدون تكرار):', style: TextStyle(fontSize: 9.5, color: Colors.black54)),
                          const SizedBox(height: 3),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: hsCodesList.map((hs) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.purple.shade200)),
                                child: Text('🔖 $hs', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.purple)),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Value & Port Row
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.black87, width: 0.8)),
                ),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    Text('Total Declared Value: $totalValue', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                    Text('Port of Entry: $portOfEntry', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                    Text('Inspection Date: $dateInsp', style: const TextStyle(fontSize: 11, color: Colors.black87)),
                  ],
                ),
              ),

              // Egyptian Standards List Box
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.black87, width: 0.8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Egyptian Mandatory Standards & Test Protocols (ES Standards Tested):', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 6),
                    ...widget.standards.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green, size: 14),
                              const SizedBox(width: 6),
                              Expanded(child: Text(s, style: const TextStyle(fontSize: 10.5, color: Colors.black87))),
                            ],
                          ),
                        )),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.green.shade600)),
                      child: const Row(
                        children: [
                          Icon(Icons.verified, color: Colors.green, size: 16),
                          SizedBox(width: 6),
                          Text('CONFORMITY ASSESSMENT RESULT: CONFORMING & SAFE FOR RELEASE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey.shade50,
                child: Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    Text('Authorized Agency: ${widget.agency}', style: const TextStyle(fontSize: 10, color: Colors.black54)),
                    const Text('Egyptian Customs Compliance (GOEIC / NFSA)', style: TextStyle(fontSize: 10, color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBoxCell(String label, String value, {bool hasRightBorder = false}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(
          bottom: const BorderSide(color: Colors.black87, width: 0.8),
          right: hasRightBorder ? const BorderSide(color: Colors.black87, width: 0.8) : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9.5, color: Colors.black54)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87)),
        ],
      ),
    );
  }
}
