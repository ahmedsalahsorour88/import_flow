import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/cargox_model.dart';

class CargoXPdfService {
  /// Generate printable & exportable PDF for Customs Commercial Invoice
  static Future<Uint8List> generateCustomsInvoicePdf({
    required CustomsInvoiceTrackModel track,
    required StandardInvoicePayloadModel payload,
  }) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    final emerald = PdfColor.fromHex('#27AE60');
    final darkBlue = PdfColor.fromHex('#2C3E50');
    final greyBg = PdfColor.fromHex('#F4F6F7');
    final borderGrey = PdfColor.fromHex('#BDC3C7');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 12),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 1)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'CUSTOMS COMMERCIAL INVOICE',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: darkBlue),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Egyptian Customs & CargoX Standard (ACID: \)',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: pw.BoxDecoration(
                  color: emerald,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  track.trackCode,
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                ),
              ),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 10),
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400, width: 0.5)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Sorour Logistics ERP — ImportFlow Compliance Engine',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
              pw.Text(
                'Page \ of ',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ],
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 12),

          // 1. Seller & Buyer Metadata Cards
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Seller Box
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: borderGrey, width: 0.5),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'EXPORTER / SELLER (المصدر):',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: darkBlue),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(payload.sellerName ?? 'N/A', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      if (payload.sellerTaxId != null && payload.sellerTaxId!.isNotEmpty)
                        pw.Text('Tax / Reg ID: ', style: const pw.TextStyle(fontSize: 8)),
                      if (payload.sellerAddress != null && payload.sellerAddress!.isNotEmpty)
                        pw.Text(payload.sellerAddress!, style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('Country: ', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              // Buyer Box
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: borderGrey, width: 0.5),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'IMPORTER / BUYER (المستورد):',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: darkBlue),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(payload.buyerName ?? 'N/A', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      if (payload.buyerTaxId != null && payload.buyerTaxId!.isNotEmpty)
                        pw.Text('VAT / Tax ID: ', style: const pw.TextStyle(fontSize: 8)),
                      if (payload.buyerAddress != null && payload.buyerAddress!.isNotEmpty)
                        pw.Text(payload.buyerAddress!, style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('ACID: ', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: emerald)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 10),

          // 2. Shipment Terms
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: greyBg,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              border: pw.Border.all(color: borderGrey, width: 0.5),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildMetaItem('Invoice #:', payload.invoiceNumber ?? 'N/A'),
                _buildMetaItem('Date:', payload.invoiceDate ?? 'N/A'),
                _buildMetaItem('Incoterm:', payload.incoterm ?? 'EXW'),
                _buildMetaItem('POL:', payload.originPort ?? 'Origin'),
                _buildMetaItem('POD:', payload.destinationPort ?? 'EGALY'),
                _buildMetaItem('Currency:', payload.currencyCode),
              ],
            ),
          ),

          pw.SizedBox(height: 12),

          // 3. Line Items Table
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: borderGrey, width: 0.5),
            headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: darkBlue),
            headerDecoration: pw.BoxDecoration(color: greyBg),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            cellHeight: 20,
            headers: [
              '#',
              'HS Code',
              'Manufacturer',
              'Description of Goods',
              'Qty',
              'Unit',
              'Unit Price',
              'Net Wt (kg)',
              'Gross Wt (kg)',
              'Total Amount',
            ],
            data: payload.items.map((i) {
              return [
                '',
                i.hsCode,
                i.manufacturer ?? payload.sellerName ?? '',
                i.description,
                '',
                i.qtyUnit,
                i.unitPrice.toStringAsFixed(4),
                i.netWeightKg.toStringAsFixed(1),
                i.grossWeightKg.toStringAsFixed(1),
                '\ ',
              ];
            }).toList(),
          ),

          pw.SizedBox(height: 12),

          // 4. Financial Totals & Weights Summary
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Weights Card
              pw.Container(
                width: 220,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderGrey, width: 0.5),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Cargo Weight Summary:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Net Weight:', style: const pw.TextStyle(fontSize: 8)),
                        pw.Text('\ ', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Gross Weight:', style: const pw.TextStyle(fontSize: 8)),
                        pw.Text('\ ', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),

              // Totals Card
              pw.Container(
                width: 240,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: greyBg,
                  border: pw.Border.all(color: emerald, width: 1),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('\ ', style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                    if (payload.freightCost > 0) ...[
                      pw.SizedBox(height: 2),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Freight:', style: const pw.TextStyle(fontSize: 9)),
                          pw.Text('\ ', style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                    ],
                    pw.Divider(color: emerald, thickness: 0.5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('TOTAL (CIF/FOB):', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: darkBlue)),
                        pw.Text(
                          '\ ',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: emerald),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 24),

          // 5. Signatures
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Authorized Exporter Signature:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 35),
                  pw.Container(width: 180, height: 1, color: PdfColors.grey600),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Egyptian Customs Clearance Stamp:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 35),
                  pw.Container(width: 180, height: 1, color: PdfColors.grey600),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generate printable & exportable PDF for Customs Packing List
  static Future<Uint8List> generateCustomsPackingListPdf({
    required CustomsInvoiceTrackModel track,
    required Map<String, dynamic> packingListData,
  }) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    final emerald = PdfColor.fromHex('#27AE60');
    final darkBlue = PdfColor.fromHex('#2C3E50');
    final greyBg = PdfColor.fromHex('#F4F6F7');
    final borderGrey = PdfColor.fromHex('#BDC3C7');

    final itemsList = (packingListData['items'] as List<dynamic>?) ?? [];
    final totalGross = (packingListData['total_gross_weight'] as num?)?.toDouble() ?? track.customsGrossWeight;
    final totalNet = (packingListData['total_net_weight'] as num?)?.toDouble() ?? track.customsNetWeight;
    final totalPackages = (packingListData['total_packages'] as num?)?.toInt() ?? itemsList.length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 12),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 1)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'CUSTOMS PACKING LIST / قائمة التعبئة الجمركية',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: darkBlue),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Egyptian Customs & CargoX Standard (ACID: \)',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: pw.BoxDecoration(
                  color: darkBlue,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  track.trackCode,
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                ),
              ),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 10),
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400, width: 0.5)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Sorour Logistics ERP — Customs Clearance & Packing Engine',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
              pw.Text(
                'Page \ of ',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ],
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 12),

          // Metadata Grid
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: greyBg,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              border: pw.Border.all(color: borderGrey, width: 0.5),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetaItem('Shipper / Exporter:', packingListData['seller_name']?.toString() ?? 'N/A'),
                    _buildMetaItem('Importer / Consignee:', packingListData['buyer_name']?.toString() ?? 'N/A'),
                    _buildMetaItem('ACID Number:', packingListData['acid_number']?.toString() ?? 'N/A'),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetaItem('Total Packages / CTN:', '\ PKGS'),
                    _buildMetaItem('Total Net Weight:', '\ KGS'),
                    _buildMetaItem('Total Gross Weight:', '\ KGS'),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 14),

          // Packing List Table
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: borderGrey, width: 0.5),
            headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: darkBlue),
            headerDecoration: pw.BoxDecoration(color: greyBg),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            cellHeight: 20,
            headers: [
              '#',
              'Package #',
              'HS Tariff Code',
              'Product Code',
              'Description of Goods',
              'Quantity',
              'Unit',
              'Net Wt (kg)',
              'Gross Wt (kg)',
            ],
            data: itemsList.map((i) {
              final idx = itemsList.indexOf(i) + 1;
              return [
                '',
                i['package_no']?.toString() ?? 'PKG ',
                i['hs_code']?.toString() ?? '',
                i['product_code']?.toString() ?? '',
                i['description']?.toString() ?? 'Goods',
                '',
                i['qty_unit']?.toString() ?? 'PCS',
                '',
                '',
              ];
            }).toList(),
          ),

          pw.SizedBox(height: 14),

          // Totals Box
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: greyBg,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              border: pw.Border.all(color: darkBlue, width: 1),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Text('Total Packages: \ PKGS', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: darkBlue)),
                pw.Text('Total Net Weight: \ KGS', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: darkBlue)),
                pw.Text('Total Gross Weight: \ KGS', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: emerald)),
              ],
            ),
          ),

          pw.SizedBox(height: 24),

          // Signatures
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Authorized Exporter / Packer:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 35),
                  pw.Container(width: 180, height: 1, color: PdfColors.grey600),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Customs Warehouse Officer Stamp:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 35),
                  pw.Container(width: 180, height: 1, color: PdfColors.grey600),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildMetaItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
        pw.SizedBox(height: 1),
        pw.Text(value, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }
}
