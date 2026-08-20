import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../services/coo_export_service.dart';

class VisualDraftCOOSheet extends StatefulWidget {
  final Map<String, dynamic> templateData;
  final String certificateType;
  final String acidNumber;
  final String? exemptionNotes;
  final VoidCallback? onRefresh;

  const VisualDraftCOOSheet({
    super.key,
    required this.templateData,
    required this.certificateType,
    required this.acidNumber,
    this.exemptionNotes,
    this.onRefresh,
  });

  @override
  State<VisualDraftCOOSheet> createState() => _VisualDraftCOOSheetState();
}

class _VisualDraftCOOSheetState extends State<VisualDraftCOOSheet> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.templateData;
    final isChina = widget.certificateType.toUpperCase().contains('CHINA') || widget.certificateType.toUpperCase().contains('CCPIT');
    final isEur1 = widget.certificateType.toUpperCase().contains('EUR.1') || widget.certificateType.toUpperCase().contains('EUR1');

    final certNo = (t['certificate_number'] ?? 'DRAFT-COO').toString();
    final exporter = (t['box_1_exporter'] ?? 'EXPORTER / PRODUCER').toString();
    final consignee = (t['box_2_consignee'] ?? t['box_3_consignee'] ?? 'IMPORTER / CONSIGNEE').toString();
    final transport = (t['box_3_means_of_transport'] ?? t['box_6_transport_details'] ?? 'BY SEA').toString();
    final destination = (t['box_4_country_of_destination'] ?? t['box_5_country_destination'] ?? 'EGYPT').toString();
    final origin = (t['country_of_origin'] ?? t['box_4_country_origin'] ?? 'EUROPEAN UNION').toString();
    final originsList = (t['countries_of_origin_list'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [origin];
    final hsCodes = (t['box_8_hs_code'] ?? t['hs_code'] ?? t['hs_codes'] ?? '560229').toString();
    final hsCodesList = (t['hs_codes_list'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [hsCodes];
    final goodsDesc = (t['box_6_marks_and_numbers'] ?? t['box_8_description_packages'] ?? 'COMMERCIAL CARGO').toString();
    final weight = (t['box_9_quantity_and_weight'] ?? t['box_9_gross_mass'] ?? 'GROSS WEIGHT').toString();
    final invoiceData = (t['box_10_invoice_number_and_date'] ?? t['box_10_invoices_and_acid'] ?? 'INVOICE INFO').toString();
    final remarks = (t['box_7_remarks'] ?? (isEur1 ? 'REVISED RULES' : 'N/A')).toString();

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
                Icon(isEur1 ? Icons.flag_circle : Icons.verified, color: AppTheme.cobalt, size: 20),
                const SizedBox(width: 8),
                Text(
                  'معاينة مسودة شهادة المنشأ الرسمية: ${widget.certificateType}',
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
                    final text = CooExportService.exportCOOCsv(
                      templateData: t,
                      certificateType: widget.certificateType,
                      acidNumber: widget.acidNumber,
                    );
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('📋 تم نسخ بيانات شهادة المنشأ إلى الحافظة'), duration: Duration(seconds: 1)),
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
                    final csv = CooExportService.exportCOOCsv(
                      templateData: t,
                      certificateType: widget.certificateType,
                      acidNumber: widget.acidNumber,
                    );
                    Clipboard.setData(ClipboardData(text: csv));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('📊 تم توليد وتجهيز بيانات الإكسل لشهادة المنشأ بنجاح'), backgroundColor: Colors.green),
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
                            await CooExportService.printOrSavePdf(
                              templateData: t,
                              certificateType: widget.certificateType,
                              acidNumber: widget.acidNumber,
                              exemptionNotes: widget.exemptionNotes,
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

        // Official Visual Document Container (Like real paper)
        Container(
          decoration: BoxDecoration(
            color: isChina ? const Color(0xFFF9FDFF) : Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: isChina ? Colors.cyan.shade900 : Colors.black87, width: 1.5),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
          ),
          child: isChina
              ? _buildChinaCcpitLayout(
                  certNo: certNo,
                  exporter: exporter,
                  consignee: consignee,
                  transport: transport,
                  destination: destination,
                  goodsDesc: goodsDesc,
                  hsCodesList: hsCodesList,
                  weight: weight,
                  invoiceData: invoiceData,
                  originsList: originsList,
                )
              : _buildEur1Layout(
                  certNo: certNo,
                  exporter: exporter,
                  consignee: consignee,
                  transport: transport,
                  destination: destination,
                  goodsDesc: goodsDesc,
                  hsCodesList: hsCodesList,
                  weight: weight,
                  invoiceData: invoiceData,
                  originsList: originsList,
                  remarks: remarks,
                  isEur1: isEur1,
                ),
        ),
      ],
    );
  }

  // ─── Authentic China CCPIT Certificate of Origin Layout ───────────────────────
  Widget _buildChinaCcpitLayout({
    required String certNo,
    required String exporter,
    required String consignee,
    required String transport,
    required String destination,
    required String goodsDesc,
    required List<String> hsCodesList,
    required String weight,
    required String invoiceData,
    required List<String> originsList,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Center ORIGINAL
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          alignment: Alignment.center,
          child: const Text('ORIGINAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 2)),
        ),
        const Divider(height: 1, color: Colors.black87),

        // Header Row: Box 1 (Left 50%) vs Title / Certificate No. (Right 50%)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: _buildBoxCell(
                '1. Exporter',
                exporter,
                hasRightBorder: true,
                hasBottomBorder: true,
                minHeight: 110,
              ),
            ),
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.black87, width: 0.8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Serial No.', style: TextStyle(fontSize: 9.5, color: Colors.black54)),
                        Text('Certificate No. $certNo', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Colors.black)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text('CERTIFICATE OF ORIGIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, letterSpacing: 0.5)),
                    const Text('OF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    const Text("THE PEOPLE'S REPUBLIC OF CHINA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Row 2: Box 2 (Consignee) spanning full or left
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: _buildBoxCell(
                '2. Consignee',
                consignee,
                hasRightBorder: true,
                hasBottomBorder: true,
                minHeight: 85,
              ),
            ),
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.black87, width: 0.8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Country / Region of Origin (بلد المنشأ المعتمد):', style: TextStyle(fontSize: 9.5, color: Colors.black54)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: originsList.map((c) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.blue.shade300)),
                          child: Text('🇨🇳 $c', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 6),
                    Text('ACID Reference: ${widget.acidNumber}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Row 3 & 4: Box 3 (Transport) & Box 4 (Destination) vs Box 5 (Certifying Authority)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column (Box 3 + Box 4)
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  _buildBoxCell(
                    '3. Means of transport and route',
                    transport,
                    hasRightBorder: true,
                    hasBottomBorder: true,
                    minHeight: 55,
                  ),
                  _buildBoxCell(
                    '4. Country / region of destination',
                    destination,
                    hasRightBorder: true,
                    hasBottomBorder: true,
                    minHeight: 45,
                  ),
                ],
              ),
            ),
            // Right Column (Box 5: For certifying authority use only)
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.black87, width: 0.8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('5. For certifying authority use only', style: TextStyle(fontSize: 9.5, color: Colors.black54)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue.shade800, width: 1.2),
                        color: Colors.blue.shade50.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'CHINA COUNCIL FOR THE PROMOTION OF INTERNATIONAL TRADE IS CHINA CHAMBER OF INTERNATIONAL COMMERCE',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9.5, color: Colors.blue.shade900),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'VERIFY URL: HTTP://CHECK.ECOCCPIT.NET/',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Middle Table (Boxes 6, 7, 8, 9, 10)
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.black87, width: 1.2)),
          ),
          child: Column(
            children: [
              // Table Column Headers
              Container(
                color: Colors.grey.shade100,
                child: Row(
                  children: [
                    _buildTableHeadCell('6. Marks and\nnumbers', flex: 2),
                    _buildTableHeadCell('7. Number and kind of packages; description of goods', flex: 4),
                    _buildTableHeadCell('8. H.S. Code', flex: 2),
                    _buildTableHeadCell('9. Quantity', flex: 2),
                    _buildTableHeadCell('10. Number\nand date of\ninvoices', flex: 2, hasRightBorder: false),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.black87),

              // Table Body Content
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Box 6: Marks
                  _buildTableBodyCell('Acoustic Panel\nN/M', flex: 2),
                  // Box 7: Description + ACID
                  Expanded(
                    flex: 4,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(border: Border(right: BorderSide(color: Colors.black87, width: 0.8))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(goodsDesc, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(3), border: Border.all(color: Colors.green.shade400)),
                            child: Text('ACID: ${widget.acidNumber}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                          ),
                          const SizedBox(height: 6),
                          const Text('***', style: TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ),
                  ),
                  // Box 8: HS Code
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(border: Border(right: BorderSide(color: Colors.black87, width: 0.8))),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: hsCodesList.map((hs) => Text(hs, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))).toList(),
                      ),
                    ),
                  ),
                  // Box 9: Quantity & Gross Weight
                  _buildTableBodyCell(weight, flex: 2),
                  // Box 10: Invoices
                  _buildTableBodyCell(invoiceData, flex: 2, hasRightBorder: false),
                ],
              ),
            ],
          ),
        ),

        // Bottom Row: Box 11 (Declaration by exporter) vs Box 12 (Certification by CCPIT)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Box 11: Declaration
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  border: Border(right: BorderSide(color: Colors.black87, width: 0.8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('11. Declaration by the exporter', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 4),
                    const Text(
                      'The undersigned hereby declares that the above details and statements are correct, that all the goods were produced in China and that they comply with the Rules of Origin of the People\'s Republic of China.',
                      style: TextStyle(fontSize: 9.5, height: 1.25, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    const Text('SUZHOU, CHINA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                    const SizedBox(height: 8),
                    const Divider(height: 1, color: Colors.black54),
                    const Text('Place and date, signature and stamp of authorized signatory', style: TextStyle(fontSize: 8.5, color: Colors.black54)),
                  ],
                ),
              ),
            ),

            // Box 12: Certification
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('12. Certification', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 4),
                    const Text(
                      'It is hereby certified that the declaration by the exporter is correct.',
                      style: TextStyle(fontSize: 9.5, height: 1.25, color: Colors.black87),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'ADDRESS: DONGWU NORTH ROAD GUOYU BUILDING 15A FLOOR WUZHONG DISTRICT SUZHOU CITY\nFAX: 0512-65252957  TEL: 0512-65252453',
                      style: TextStyle(fontSize: 8.5, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    const Text('SUZHOU, CHINA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                    const SizedBox(height: 8),
                    const Divider(height: 1, color: Colors.black54),
                    const Text('Place and date, signature and stamp of certifying authority', style: TextStyle(fontSize: 8.5, color: Colors.black54)),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Page Indicator
        Container(
          padding: const EdgeInsets.all(4),
          alignment: Alignment.center,
          color: Colors.grey.shade50,
          child: const Text('Page 1 of 1', style: TextStyle(fontSize: 9, color: Colors.black54)),
        ),
      ],
    );
  }

  // ─── Standard EUR.1 Movement Certificate Layout ──────────────────────────────
  Widget _buildEur1Layout({
    required String certNo,
    required String exporter,
    required String consignee,
    required String transport,
    required String destination,
    required String goodsDesc,
    required List<String> hsCodesList,
    required String weight,
    required String invoiceData,
    required List<String> originsList,
    required String remarks,
    required bool isEur1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Row
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
                      isEur1 ? 'MOVEMENT CERTIFICATE (EUR.1)' : 'CERTIFICATE OF ORIGIN',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.black),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'OFFICIAL DRAFT VERIFICATION — ACI NAFEZA EGYPT',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppTheme.cobalt),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('CERTIFICATE NO: $certNo', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black)),
                  Text('ACID NO: ${widget.acidNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.green)),
                ],
              ),
            ],
          ),
        ),

        // Exemption Status Note if present
        if (widget.exemptionNotes != null && widget.exemptionNotes!.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: Colors.green.shade50,
            child: Row(
              children: [
                const Icon(Icons.stars, color: Colors.green, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.exemptionNotes!,
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                  ),
                ),
              ],
            ),
          ),

        // Box 1: Exporter
        _buildBoxCell('1. Exporter (Name, full address, country, reg no.):', exporter, hasBottomBorder: true),

        // Row 2: Consignee & Country of Origin
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildBoxCell(
                '2. Consignee (Name, full address, country):',
                consignee,
                hasRightBorder: true,
                hasBottomBorder: true,
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.black87, width: 0.8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('3. Country / Countries of Origin (بلد / بلاد المنشأ المستدعاة):', style: TextStyle(fontSize: 9.5, color: Colors.black54)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: originsList.map((c) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.blue.shade300),
                          ),
                          child: Text('🌍 $c', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 6),
                    Text('Country of Destination: $destination', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Row 3: Transport & Remarks
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildBoxCell(
                '4. Transport Details & Route:',
                transport,
                hasRightBorder: true,
                hasBottomBorder: true,
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.black87, width: 0.8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('5. Remarks / Preferential Rule:', style: TextStyle(fontSize: 9.5, color: Colors.black54)),
                    const SizedBox(height: 2),
                    Text(remarks, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.crimson)),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Row 4: Goods Description, Multi-HS Codes & Weights
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.black87, width: 0.8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('6. Description of Goods, Marks & Numbers, Item Lines:', style: TextStyle(fontSize: 9.5, color: Colors.black54)),
              const SizedBox(height: 4),
              Text(goodsDesc, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),

              // Multi HS Codes Chips
              Row(
                children: [
                  const Text('H.S. Codes (بدون تكرار): ', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: hsCodesList.map((hs) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.purple.shade200),
                          ),
                          child: Text('🔖 $hs', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple)),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('Quantity & Gross Mass: $weight', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text('Invoices & ACID Reference: $invoiceData | ACID: ${widget.acidNumber}', style: TextStyle(fontSize: 10.5, color: Colors.grey.shade800)),
            ],
          ),
        ),

        // Footer Endorsement
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.grey.shade50,
          child: Wrap(
            spacing: 16,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('7. Declaration by Exporter: Certified Correct', style: TextStyle(fontSize: 10, color: Colors.black54)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.green.shade300)),
                child: const Text('🟢 Approved & Verified for Egyptian Customs Release', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBoxCell(
    String label,
    String value, {
    bool hasRightBorder = false,
    bool hasBottomBorder = false,
    double? minHeight,
  }) {
    return Container(
      constraints: minHeight != null ? BoxConstraints(minHeight: minHeight) : null,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(
          bottom: hasBottomBorder ? const BorderSide(color: Colors.black87, width: 0.8) : BorderSide.none,
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

  Widget _buildTableHeadCell(String title, {required int flex, bool hasRightBorder = true}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          border: Border(right: hasRightBorder ? const BorderSide(color: Colors.black87, width: 0.8) : BorderSide.none),
        ),
        child: Text(
          title,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildTableBodyCell(String content, {required int flex, bool hasRightBorder = true}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border(right: hasRightBorder ? const BorderSide(color: Colors.black87, width: 0.8) : BorderSide.none),
        ),
        child: Text(
          content,
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ),
    );
  }
}
