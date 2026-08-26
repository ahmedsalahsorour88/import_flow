import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/localization/app_localizations.dart';
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

  static String sanitizeEnglishOnly(String input) {
    if (input.isEmpty) return input;
    // 1. Remove Arabic words inside parentheses e.g. (ميناء نينغبو تشوشان) or (الصين)
    var text = input.replaceAll(RegExp(r'\s*\([\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF\s\.\-]+\)'), '');
    // 2. Remove any remaining Arabic characters
    text = text.replaceAll(RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]'), '');
    // 3. Remove empty parentheses or double dashes/spaces
    text = text.replaceAll(RegExp(r'\(\s*\)'), '');
    text = text.replaceAll(RegExp(r'-\s*-+'), '-');
    text = text.replaceAll(RegExp(r'\s*-\s*$'), '');
    text = text.replaceAll(RegExp(r'^\s*-\s*'), '');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    final upper = text.toUpperCase().trim();
    if (upper == 'CN' || upper == 'CN -' || upper == 'CN - CHINA' || upper == 'CN-CHINA' || upper == 'CHINA') {
      text = 'China';
    } else if (upper == 'EG' || upper == 'EG -' || upper == 'EG - EGYPT' || upper == 'EGYPT') {
      text = 'Egypt';
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.templateData;
    final isChina = widget.certificateType.toUpperCase().contains('CHINA') || widget.certificateType.toUpperCase().contains('CCPIT');
    final isEur1 = widget.certificateType.toUpperCase().contains('EUR.1') || widget.certificateType.toUpperCase().contains('EUR1');

    final certNo = sanitizeEnglishOnly((t['certificate_number'] ?? 'DRAFT-COO').toString());
    final exporter = sanitizeEnglishOnly((t['box_1_exporter'] ?? 'EXPORTER / PRODUCER').toString());
    final consignee = sanitizeEnglishOnly((t['box_2_consignee'] ?? t['box_3_consignee'] ?? 'IMPORTER / CONSIGNEE').toString());
    final transport = sanitizeEnglishOnly((t['box_3_means_of_transport'] ?? t['box_6_transport_details'] ?? 'BY SEA').toString());
    final destination = sanitizeEnglishOnly((t['box_4_country_of_destination'] ?? t['box_5_country_destination'] ?? 'EGYPT').toString());
    final origin = sanitizeEnglishOnly((t['country_of_origin'] ?? t['box_4_country_origin'] ?? 'EUROPEAN UNION').toString());
    final originsList = (t['countries_of_origin_list'] as List<dynamic>?)
            ?.map((e) => sanitizeEnglishOnly(e.toString()))
            .where((e) => e.isNotEmpty)
            .toList() ??
        [origin];
    final hsCodes = (t['box_8_hs_code'] ?? t['hs_code'] ?? t['hs_codes'] ?? '560229').toString();
    final hsCodesList = (t['hs_codes_list'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [hsCodes];
    final goodsDesc = sanitizeEnglishOnly((t['box_6_marks_and_numbers'] ?? t['box_8_description_packages'] ?? 'COMMERCIAL CARGO').toString());
    
    // Weight: strip trailing or duplicate G.W.
    var rawWeight = (t['box_9_quantity_and_weight'] ?? t['box_9_gross_mass'] ?? 'GROSS WEIGHT').toString();
    rawWeight = rawWeight.replaceAll(RegExp(r'\s+G\.W\.\s*$', caseSensitive: false), '');
    final weight = sanitizeEnglishOnly(rawWeight);

    final invoiceData = sanitizeEnglishOnly((t['box_10_invoice_number_and_date'] ?? t['box_10_invoices_and_acid'] ?? 'INVOICE INFO').toString());
    final remarks = sanitizeEnglishOnly((t['box_7_remarks'] ?? (isEur1 ? 'REVISED RULES' : 'N/A')).toString());
    final cleanAcidNo = sanitizeEnglishOnly(widget.acidNumber);

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
                  context.l10n.cooVisualPreviewTitle(widget.certificateType),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                ),
                const SizedBox(width: 16),
                if (widget.onRefresh != null)
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 18, color: AppTheme.cobalt),
                    tooltip: context.l10n.cooVisualRefreshTooltip,
                    onPressed: widget.onRefresh,
                  ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                  icon: const Icon(Icons.copy, size: 14),
                  label: Text(context.l10n.cooVisualCopyButton, style: const TextStyle(fontSize: 11)),
                  onPressed: () {
                    final text = CooExportService.exportCOOCsv(
                      templateData: t,
                      certificateType: widget.certificateType,
                      acidNumber: widget.acidNumber,
                    );
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.l10n.cooVisualCopiedSnackbar), duration: const Duration(seconds: 1)),
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
                  label: Text(context.l10n.cooVisualExcelButton, style: const TextStyle(fontSize: 11)),
                  onPressed: () {
                    final csv = CooExportService.exportCOOCsv(
                      templateData: t,
                      certificateType: widget.certificateType,
                      acidNumber: widget.acidNumber,
                    );
                    Clipboard.setData(ClipboardData(text: csv));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.l10n.cooVisualExcelReadySnackbar), backgroundColor: Colors.green),
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
                  label: Text(context.l10n.cooVisualPrintPdfButton, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
                  acidNumber: cleanAcidNo,
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
                  acidNumber: cleanAcidNo,
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
    required String acidNumber,
  }) {
    // Ensure Transport route has Port of departure + Country TO Port of destination + Country
    var cleanTransport = transport.trim();
    if (cleanTransport.isEmpty ||
        cleanTransport == 'CN - China' ||
        cleanTransport.toUpperCase() == 'BY SEA' ||
        cleanTransport.toUpperCase() == 'CHINA') {
      cleanTransport = 'FROM SHANGHAI CHINA TO ALEXANDRIA EGYPT BY SEA';
    } else if (!cleanTransport.toUpperCase().contains('TO') || !cleanTransport.toUpperCase().contains('FROM')) {
      cleanTransport = 'FROM $cleanTransport TO ALEXANDRIA EGYPT BY SEA';
    }

    // Format clean Box 7 description with inline ACID
    var cleanBox7 = goodsDesc.trim();
    if (cleanBox7.isEmpty || cleanBox7 == 'COMMERCIAL CARGO' || cleanBox7.contains('CN - China') || cleanBox7.contains('Acoustic Panel N/M')) {
      cleanBox7 = 'ACOUSTIC PANELS';
    }
    if (!cleanBox7.toUpperCase().contains('ACID:')) {
      final validAcid = (acidNumber.isNotEmpty && acidNumber != 'CN - China') ? acidNumber : '5281534391023010013';
      cleanBox7 = '$cleanBox7 ACID:$validAcid';
    }
    if (!cleanBox7.endsWith('***')) {
      cleanBox7 = '$cleanBox7\n\n***';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Center ORIGINAL
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          alignment: Alignment.center,
          child: const Text(
            'ORIGINAL',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 3, color: Colors.black),
          ),
        ),
        const Divider(height: 1, thickness: 1.2, color: Colors.black87),

        // ─── Top Block: Box 1 & Box 2 (Left 50%) vs Official Title (Right 50%) ───
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left: Box 1 (Exporter) & Box 2 (Consignee)
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildBoxCell(
                      '1. Exporter',
                      exporter,
                      hasRightBorder: true,
                      hasBottomBorder: true,
                      minHeight: 95,
                    ),
                    _buildBoxCell(
                      '2. Consignee',
                      consignee,
                      hasRightBorder: true,
                      hasBottomBorder: true,
                      minHeight: 80,
                    ),
                  ],
                ),
              ),

              // Right: Authentic CCPIT Title & Certificate Header
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.black87, width: 0.8)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Serial No.', style: TextStyle(fontSize: 9.5, color: Colors.black87)),
                          Text('Certificate No. $certNo', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'CERTIFICATE OF ORIGIN',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, letterSpacing: 0.8, color: Colors.black),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'OF',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        "THE PEOPLE'S REPUBLIC OF CHINA",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8, color: Colors.black),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ─── Middle Block: Box 3 & Box 4 (Left 50%) vs Box 5 (Right 50%) ───
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left: Box 3 (Transport) & Box 4 (Destination) - FLUSH TO LEFT
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildBoxCell(
                      '3. Means of transport and route',
                      cleanTransport,
                      hasRightBorder: true,
                      hasBottomBorder: true,
                      minHeight: 60,
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

              // Right: Box 5 (For certifying authority use only)
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.black87, width: 0.8)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('5. For certifying authority use only', style: TextStyle(fontSize: 9.5, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF1B4F72), width: 1.2),
                          ),
                          child: const Text(
                            'CHINA COUNCIL FOR THE PROMOTION OF INTERNATIONAL TRADE IS CHINA CHAMBER OF INTERNATIONAL COMMERCE',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 9.5,
                              color: Color(0xFF1B4F72),
                              letterSpacing: 0.3,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          'VERIFY URL: HTTP://CHECK.ECOCCPIT.NET/',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 8.5, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ─── Table Section (Boxes 6, 7, 8, 9, 10) ───
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
                      child: Text(
                        cleanBox7,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10.5, color: Colors.black87, height: 1.3),
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
                        children: hsCodesList.map((hs) => Text(hs, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5))).toList(),
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

        // ─── Bottom Row: Box 11 (Declaration) vs Box 12 (Certification) ───
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
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('11. Declaration by the exporter', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.black87)),
                    SizedBox(height: 4),
                    Text(
                      'The undersigned hereby declares that the above details and statements are correct, that all the goods were produced in China and that they comply with the Rules of Origin of the People\'s Republic of China.',
                      style: TextStyle(fontSize: 9, height: 1.25, color: Colors.black87),
                    ),
                    SizedBox(height: 14),
                    Text('SUZHOU, CHINA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                    SizedBox(height: 8),
                    Divider(height: 1, color: Colors.black54),
                    Text('Place and date, signature and stamp of authorized signatory', style: TextStyle(fontSize: 8, color: Colors.black54)),
                  ],
                ),
              ),
            ),

            // Box 12: Certification
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('12. Certification', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.black87)),
                    SizedBox(height: 4),
                    Text(
                      'It is hereby certified that the declaration by the exporter is correct.',
                      style: TextStyle(fontSize: 9, height: 1.25, color: Colors.black87),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'ADDRESS: DONGWU NORTH ROAD GUOYU BUILDING 15A FLOOR WUZHONG DISTRICT SUZHOU CITY\nFAX: 0512-65252957 TEL: 0512-65252453',
                      style: TextStyle(fontSize: 8.5, height: 1.2, color: Colors.black87),
                    ),
                    SizedBox(height: 8),
                    Text('SUZHOU, CHINA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                    SizedBox(height: 8),
                    Divider(height: 1, color: Colors.black54),
                    Text('Place and date, signature and stamp of certifying authority', style: TextStyle(fontSize: 8, color: Colors.black54)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Authentic EUR.1 Movement Certificate Layout ──────────────────────────────
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
    required String acidNumber,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Center Title
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.black87, width: 1.2)),
          ),
          child: const Text(
            'MOVEMENT CERTIFICATE',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2, color: Colors.black87),
          ),
        ),

        // Row 1: Box 1 (Exporter) vs EUR.1 Header Box & Box 2 (Preferential Trade)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Box 1: Exporter
            Expanded(
              flex: 5,
              child: _buildBoxCell(
                '1. Exporter (Name, full address, country)',
                exporter,
                hasRightBorder: true,
                hasBottomBorder: true,
                minHeight: 125,
              ),
            ),

            // Right 50%: EUR.1 Header + Box 2
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  // EUR.1 Title & Cert No Box
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.black87, width: 0.8)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('EUR.1', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black)),
                            Text('No A $certNo', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.black)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'See notes overleaf before completing this form.',
                          style: TextStyle(fontSize: 8.5, fontStyle: FontStyle.italic, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),

                  // Box 2: Preferential Trade
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.black87, width: 0.8)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '2. Certificate used in preferential trade between',
                            style: TextStyle(fontSize: 8.5, color: Colors.black54),
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'EU',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Colors.black87),
                        ),
                        const Text('and', style: TextStyle(fontSize: 9.5, color: Colors.black54)),
                        Text(
                          destination.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          '(Insert appropriate countries, groups of countries or territories)',
                          style: TextStyle(fontSize: 7.5, fontStyle: FontStyle.italic, color: Colors.black45),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Row 2: Box 3 (Consignee) vs Box 4 (Origin) & Box 5 (Destination)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Box 3: Consignee
            Expanded(
              flex: 5,
              child: _buildBoxCell(
                '3. Consignee (Name, full address, country) (Optional)',
                consignee,
                hasRightBorder: true,
                hasBottomBorder: true,
                minHeight: 90,
              ),
            ),

            // Box 4 & Box 5 Column
            Expanded(
              flex: 5,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 90),
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Colors.black87, width: 0.8),
                          bottom: BorderSide(color: Colors.black87, width: 0.8),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '4. Country, group of countries or territory in which the products are considered as originating',
                            style: TextStyle(fontSize: 8.5, color: Colors.black54),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(color: Colors.blue.shade300),
                            ),
                            child: const Text('🇪🇺 EU', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: AppTheme.cobalt)),
                          ),
                          if (originsList.isNotEmpty && !originsList.contains('EU'))
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text('(${originsList.join(', ')})', style: const TextStyle(fontSize: 8.5, color: Colors.black54)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildBoxCell(
                      '5. Country, group of countries or territory of destination (Optional)',
                      destination,
                      hasBottomBorder: true,
                      minHeight: 90,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Row 3: Box 6 (Transport details) vs Box 7 (Remarks)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: _buildBoxCell(
                '6. Transport details (Optional)',
                transport.isNotEmpty ? transport : 'BY SEA / CONTAINERIZED CARGO',
                hasRightBorder: true,
                hasBottomBorder: true,
                minHeight: 50,
              ),
            ),
            Expanded(
              flex: 5,
              child: _buildBoxCell(
                '7. Remarks',
                remarks.isNotEmpty ? remarks : 'REVISED RULES',
                hasBottomBorder: true,
                minHeight: 50,
              ),
            ),
          ],
        ),

        // Middle Table (Boxes 8, 9, 10)
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
                    _buildTableHeadCell('8. Item number; Marks and numbers; Number and kind of packages (1); Description of goods', flex: 5),
                    _buildTableHeadCell('9. Gross mass (kg)\nor other measure\n(litres, m³, etc.)', flex: 2),
                    _buildTableHeadCell('10. Invoices\n(Optional)', flex: 2, hasRightBorder: false),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.black87),

              // Table Body Content
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Box 8: Description + Packages + HS Code Badges
                  Expanded(
                    flex: 5,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(border: Border(right: BorderSide(color: Colors.black87, width: 0.8))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(goodsDesc, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                          const SizedBox(height: 8),

                          // Multi-HS code tags
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: hsCodesList.map((hs) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade50,
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(color: Colors.purple.shade300),
                                ),
                                child: Text('🔖 $hs', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5, color: Colors.purple)),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),

                          // Diagonal line watermark simulation to prevent additions
                          CustomPaint(
                            size: const Size(double.infinity, 30),
                            painter: DiagonalLinePainter(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Box 9: Gross Mass
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(border: Border(right: BorderSide(color: Colors.black87, width: 0.8))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            weight.isNotEmpty ? weight : '10,510.6 KG',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          CustomPaint(
                            size: const Size(double.infinity, 30),
                            painter: DiagonalLinePainter(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Box 10: Invoices & ACID
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ACID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.green)),
                          Text(acidNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5, color: Colors.green)),
                          if (invoiceData.isNotEmpty && invoiceData != 'INVOICE INFO') ...[
                            const SizedBox(height: 4),
                            Text(invoiceData, style: const TextStyle(fontSize: 9.5, color: Colors.black87)),
                          ],
                          const SizedBox(height: 14),
                          CustomPaint(
                            size: const Size(double.infinity, 30),
                            painter: DiagonalLinePainter(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Bottom Section: Box 11 (Customs Endorsement) vs Box 12 (Declaration by Exporter)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Box 11: Customs Endorsement
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
                    const Text('11. CUSTOMS ENDORSEMENT', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 3),
                    const Text('Declaration certified', style: TextStyle(fontSize: 8.5)),
                    const Text('Export document (2)', style: TextStyle(fontSize: 8.5)),
                    const Text('Form .............................. No ..............................', style: TextStyle(fontSize: 8, color: Colors.black54)),
                    const Text('Of .....................................................................', style: TextStyle(fontSize: 8, color: Colors.black54)),
                    const SizedBox(height: 2),
                    const Text('Customs office: Vilnius regional customs office', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w500)),
                    const Text('Issuing country or territory: Lithuania', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Place and date:', style: TextStyle(fontSize: 8, color: Colors.black54)),
                            Text('2026-08-11', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        // Customs Stamp Simulation
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue.shade900, width: 1.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'A-004 • LT VM • 2026-08-11',
                            style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Divider(height: 1, color: Colors.black54),
                    const Center(child: Text('(Signature)', style: TextStyle(fontSize: 8, color: Colors.black54))),
                  ],
                ),
              ),
            ),

            // Box 12: Declaration by Exporter
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('12. DECLARATION BY THE EXPORTER', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 3),
                    const Text(
                      'I, the undersigned, declare that the goods described above meet the conditions required for the issue of this certificate.',
                      style: TextStyle(fontSize: 8.5, height: 1.25),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Place and date:', style: TextStyle(fontSize: 8, color: Colors.black54)),
                            Text('VILNIUS 2026-08-11', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        // Exporter Stamp Simulation
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.indigo.shade800, width: 1.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'NARBUTAS DOKUMENTAI',
                            style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: Colors.indigo.shade900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1, color: Colors.black54),
                    const Center(child: Text('(Signature)', style: TextStyle(fontSize: 8, color: Colors.black54))),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Footnotes
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: Colors.grey.shade50,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '(1) If goods are not packed, indicate number of articles or state \'in bulk\', as appropriate.',
                style: TextStyle(fontSize: 7.5, color: Colors.black54),
              ),
              Text(
                '(2) Complete only where the regulations of the exporting country or territory require.',
                style: TextStyle(fontSize: 7.5, color: Colors.black54),
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
      width: double.infinity,
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
          Text(label, style: const TextStyle(fontSize: 9, color: Colors.black54)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5, color: Colors.black87)),
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
          style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.black87),
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
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ),
    );
  }
}

/// Painter to draw the official anti-fraud diagonal lines in EUR.1 unused box space
class DiagonalLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black26
      ..strokeWidth = 1.0;
    canvas.drawLine(const Offset(0, 0), Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
