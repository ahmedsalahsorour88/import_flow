import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../services/draft_bl_export_service.dart';

class VisualDraftBLSheet extends StatelessWidget {
  final Map<String, dynamic> systemData;
  final Map<String, dynamic> draftData;
  final String? draftBlNumber;
  final String? bookingNumber;

  const VisualDraftBLSheet({
    super.key,
    required this.systemData,
    required this.draftData,
    this.draftBlNumber,
    this.bookingNumber,
  });

  @override
  Widget build(BuildContext context) {
    final blNo = (draftData['draft_bl_number'] ?? draftBlNumber ?? systemData['draft_bl_number'] ?? 'DRAFT-BL').toString();
    final bkgNo = (draftData['booking_no'] ?? bookingNumber ?? systemData['booking_no'] ?? 'BKG-REF').toString();
    final shipper = (draftData['shipper'] ?? systemData['shipper'] ?? 'G.I. Industrial Holding S.p.A.').toString();
    final consignee = (draftData['consignee'] ?? systemData['consignee'] ?? 'ECO ASSOCIATES for Trading and Contracting').toString();
    final notifyParty = (draftData['notify_party'] ?? systemData['notify_party'] ?? consignee).toString();
    final shippingLine = (draftData['shipping_line'] ?? systemData['shipping_line'] ?? 'MEDITERRANEAN SHIPPING COMPANY').toString();
    final vessel = (draftData['vessel_name'] ?? systemData['vessel_name'] ?? 'MSC PORTO III').toString();
    final voyage = (draftData['voyage_number'] ?? systemData['voyage_number'] ?? 'AB635A').toString();
    final pol = (draftData['pol'] ?? systemData['pol'] ?? 'Genoa Port (ميناء جنوى)').toString();
    final pod = (draftData['pod'] ?? systemData['pod'] ?? 'El Dekheila Port (ميناء الدخيلة)').toString();
    final placeOfDelivery = (draftData['place_of_delivery'] ?? systemData['place_of_delivery'] ?? pod).toString();
    final freightTerms = (draftData['freight_terms'] ?? systemData['freight_terms'] ?? 'FREIGHT PREPAID').toString().toUpperCase();

    final acid = (draftData['acid_number'] ?? systemData['acid_number'] ?? '7595528271019210013').toString();
    final taxId = (draftData['importer_tax_id'] ?? systemData['importer_tax_id'] ?? '759552827').toString();
    final regType = (draftData['shipper_reg_type'] ?? systemData['shipper_reg_type'] ?? 'VAT NUMBER').toString();
    final regId = (draftData['shipper_reg_id'] ?? systemData['shipper_reg_id'] ?? 'IT000458921').toString();
    final country = (draftData['shipper_country'] ?? systemData['shipper_country'] ?? 'ITALY').toString();
    final countryCode = (draftData['shipper_country_code'] ?? systemData['shipper_country_code'] ?? 'IT').toString();

    final goodsDesc = (draftData['goods_description'] ?? systemData['goods_description'] ?? 'AIR CONDITIONING UNITS & CHILLERS').toString();
    final grossWeight = (draftData['total_gross_weight_kg'] ?? systemData['total_gross_weight_kg'] ?? '20030.00').toString();
    final netWeight = (draftData['total_net_weight_kg'] ?? systemData['total_net_weight_kg'] ?? '18500.00').toString();
    final cbm = (draftData['cbm'] ?? systemData['cbm'] ?? '65.40').toString();
    final pkgCount = (draftData['qty_pkg'] ?? systemData['packages_count'] ?? '31').toString();
    final containerSummary = (draftData['container_summary'] ?? systemData['container_summary'] ?? 'BEAU5851356 (40\' HIGH CUBE) / Seal: 177345').toString();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Toolbar: Actions & Download Buttons
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.description, color: AppTheme.charcoal, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'معاينة شكل مسودة البوليصة المعتمدة (Draft Bill of Lading Sheet)',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                            ),
                            Text(
                              'عرض رسمي مطابق لنموذج الخط الملاحي والبيانات المستخرجة ومعايير نافذة (ACID)',
                              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await DraftBLExportService.exportDraftBLToPdf(
                            systemData: systemData,
                            draftData: draftData,
                            draftBlNumber: draftBlNumber,
                            bookingNumber: bookingNumber,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('✔ تم تصدير مسودة البوليصة بصيغة PDF بنجاح'), backgroundColor: Colors.green),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('خطأ أثناء تصدير PDF: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 16),
                      label: const Text('تنزيل PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.crimson,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final res = await DraftBLExportService.exportDraftBLToExcel(
                            systemData: systemData,
                            draftData: draftData,
                            draftBlNumber: draftBlNumber,
                            bookingNumber: bookingNumber,
                          );
                          if (context.mounted && res != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('✔ تم حفظ مسودة البوليصة بصيغة Excel / CSV بنجاح ($res)'), backgroundColor: Colors.green),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('خطأ أثناء تصدير Excel: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.table_chart, color: Colors.white, size: 16),
                      label: const Text('تنزيل Excel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Authentic B/L Container Sheet
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 850),
                child: Container(
                  width: 850,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black87, width: 1.5),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Header Banner
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.grey.shade100,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  shippingLine.toUpperCase(),
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.8),
                                ),
                                const Text(
                                  'BILL OF LADING (DRAFT — NOT NEGOTIABLE)',
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.red),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('B/L NO: $blNo', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                Text('BOOKING REF: $bkgNo', style: TextStyle(fontSize: 11, color: Colors.grey.shade800)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, thickness: 1.2, color: Colors.black87),

                      // 2. Shipper & Carrier Agent Row
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Shipper
                            Expanded(
                              flex: 3,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  border: Border(right: BorderSide(color: Colors.black87, width: 1)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('SHIPPER / EXPORTER:', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                                    const SizedBox(height: 4),
                                    Text(shipper, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                            // Carrier Endorsement
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("CARRIER'S AGENTS ENDORSEMENTS:", style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                                    const SizedBox(height: 4),
                                    const Text("SHIPPER'S LOAD, STOW AND COUNT; FCL/FCL; SAID TO CONTAIN", style: TextStyle(fontSize: 9.5)),
                                    const Text("Lloyd's/IMO Number: 9720198", style: TextStyle(fontSize: 9.5)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, thickness: 1, color: Colors.black87),

                      // 3. Consignee & POD Agent Row
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Consignee
                            Expanded(
                              flex: 3,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  border: Border(right: BorderSide(color: Colors.black87, width: 1)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('CONSIGNEE (This B/L is not negotiable unless marked "To Order"):', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                                    const SizedBox(height: 4),
                                    Text(consignee, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                            // POD Agent
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('PORT OF DISCHARGE AGENT:', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                                    const SizedBox(height: 4),
                                    Text('$shippingLine (Egypt Agency)', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
                                    const Text('Alexandria Port, Egypt', style: TextStyle(fontSize: 9.5)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, thickness: 1, color: Colors.black87),

                      // 4. Notify Party
                      Container(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('NOTIFY PARTIES (No responsibility shall attach to Carrier or to its Agent for failure to notify):', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                            const SizedBox(height: 4),
                            Text(notifyParty, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const Divider(height: 1, thickness: 1, color: Colors.black87),

                      // 5. Transit Details Row
                      IntrinsicHeight(
                        child: Row(
                          children: [
                            _buildCell('VESSEL AND VOYAGE NO', '$vessel — $voyage', flex: 2),
                            _buildCell('PORT OF LOADING (POL)', pol, flex: 2),
                            _buildCell('PORT OF DISCHARGE (POD)', pod, flex: 2),
                            _buildCell('PLACE OF DELIVERY', placeOfDelivery, flex: 2),
                          ],
                        ),
                      ),
                      const Divider(height: 1, thickness: 1.2, color: Colors.black87),

                      // 6. Section Banner
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        color: Colors.grey.shade200,
                        child: const Text(
                          'PARTICULARS FURNISHED BY THE SHIPPER — NOT CHECKED BY CARRIER — CARRIER NOT RESPONSIBLE',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                      ),
                      const Divider(height: 1, thickness: 1, color: Colors.black87),

                      // 7. Table Header
                      Container(
                        color: Colors.grey.shade100,
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              _buildTableHead('Container Numbers, Seal Numbers', flex: 2),
                              _buildTableHead('Description of Packages and Goods (Egyptian ACID Block)', flex: 4),
                              _buildTableHead('Gross Cargo Weight', flex: 2),
                              _buildTableHead('Measurement', flex: 1),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1, thickness: 1, color: Colors.black87),

                      // 8. Particulars Body
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Container & Seals
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  border: Border(right: BorderSide(color: Colors.black87, width: 1)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(containerSummary, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Text('Marks & Numbers: N/A', style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                                    Text('FCL / FCL', style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                                  ],
                                ),
                              ),
                            ),
                            // Description & ACID Block
                            Expanded(
                              flex: 4,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  border: Border(right: BorderSide(color: Colors.black87, width: 1)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('$pkgCount Packages / $goodsDesc', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),

                                    // Egyptian Customs ACID Box
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        border: Border.all(color: Colors.blue.shade300),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(Icons.verified, size: 14, color: AppTheme.cobalt),
                                              SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  'EGYPTIAN CUSTOMS ADVANCED INFORMATION (ACID BLOCK):',
                                                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppTheme.cobalt),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          SelectableText('ACID: $acid', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.black87)),
                                          SelectableText('EGYPTIAN IMPORTER TAX ID: $taxId', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.black87)),
                                          SelectableText('SHIPPER REGISTRATION TYPE: $regType', style: const TextStyle(fontSize: 10, color: Colors.black87)),
                                          SelectableText('SHIPPER ID: $regId', style: const TextStyle(fontSize: 10, color: Colors.black87)),
                                          SelectableText('SHIPPER COUNTRY: $country (CODE: $countryCode)', style: const TextStyle(fontSize: 10, color: Colors.black87)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      freightTerms,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Gross Weight
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  border: Border(right: BorderSide(color: Colors.black87, width: 1)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('$grossWeight KGS', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text('Net: $netWeight KGS', style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                                  ],
                                ),
                              ),
                            ),
                            // Measurement
                            Expanded(
                              flex: 1,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('$cbm CBM', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, thickness: 1.2, color: Colors.black87),

                      // 9. Total Summary Row
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.grey.shade100,
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            Text('Total Items: $pkgCount Packages', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            Text('Total Gross Weight: $grossWeight KGS', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            Text('Total Measurement: $cbm CBM', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            Text('Freight: $freightTerms', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                          ],
                        ),
                      ),
                      const Divider(height: 1, thickness: 1, color: Colors.black87),

                      // 10. Footer Signatures & Date
                      Container(
                        padding: const EdgeInsets.all(8),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('ImportFlow ERP Draft B/L Certification Engine (BP-016)', style: TextStyle(fontSize: 9.5, color: Colors.grey)),
                                Text('Generated: ${DateTime.now().toLocal().toString().substring(0, 19)}', style: const TextStyle(fontSize: 9.5, color: Colors.grey)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('SIGNED FOR THE CARRIER / AGENT:', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text('Mediterranean Shipping Co. (Egypt)', style: TextStyle(fontSize: 10, color: Colors.grey.shade800)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(String title, String val, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: Colors.black87, width: 1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
            const SizedBox(height: 2),
            Text(val, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHead(String title, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: Colors.black87, width: 1)),
        ),
        child: Text(
          title,
          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
