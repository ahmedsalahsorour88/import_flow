import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../theme/app_theme.dart';
import '../utils/container_requirement_engine.dart';
import 'file_save_helper.dart';
import '../../features/purchase_orders/utils/po_packing_matcher.dart';

/// Centralized service for exporting 3D Container Simulation views (PNG)
/// and comprehensive Container Loading Plan reports (PDF) across the ERP.
class ContainerLoadPlanExportService {
  /// Captures visual render from a GlobalKey bound to RepaintBoundary.
  static Future<Uint8List?> captureRenderBoundary(GlobalKey repaintKey) async {
    try {
      final boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  /// Exports high-resolution PNG image of the 3D container simulation views.
  static Future<void> exportSimulationImage({
    required BuildContext context,
    required GlobalKey repaintKey,
    required String displayName,
    required bool isArabic,
  }) async {
    try {
      final pngBytes = await captureRenderBoundary(repaintKey);
      if (pngBytes == null || pngBytes.isEmpty) {
        throw Exception(isArabic ? 'لم يتم العثور على عنصر المحاكاة المرئي للالتقاط' : 'Simulation visual element not found for capture');
      }

      if (!context.mounted) return;
      await FileSaveHelper.exportAndSaveFile(
        context: context,
        bytes: pngBytes,
        stageName: isArabic ? 'محاكي الحاوية 3D' : '3D Container Planner',
        importFileNameOrCode: displayName,
        extension: 'png',
        customDialogTitle: isArabic ? 'تنزيل صور محاكاة ورص الحاوية (PNG)' : 'Download Simulation Views / Images (PNG)',
        showNotification: true,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${isArabic ? "خطأ في تصدير الصورة: " : "Error exporting image: "}$e'),
            backgroundColor: AppTheme.crimson,
          ),
        );
      }
    }
  }

  /// Exports complete multi-page Container Loading Plan (PDF) with metrics, specs, 3D views image, and placement coordinates.
  static Future<void> exportLoadingPlanPdf({
    required BuildContext context,
    required GlobalKey repaintKey,
    required String displayName,
    required String? poNumber,
    required String? companyName,
    required String? supplierName,
    required List<ContainerPackingResult> plan,
    required String fleetSummary,
    required double totalPlanWeight,
    required double totalPlanVolume,
    required int totalPkgs,
    required bool isArabic,
  }) async {
    try {
      // 1. Capture 3D container render image
      final capturedImageBytes = await captureRenderBoundary(repaintKey);

      // 2. Setup PDF document
      final pdf = pw.Document();
      pw.Font arabicFont;
      pw.Font arabicBold;
      try {
        arabicFont = await PdfGoogleFonts.cairoRegular();
        arabicBold = await PdfGoogleFonts.cairoBold();
      } catch (_) {
        arabicFont = pw.Font.helvetica();
        arabicBold = pw.Font.helveticaBold();
      }

      final theme = pw.ThemeData.withFont(base: arabicFont, bold: arabicBold);

      // 3. MultiPage in Landscape for container diagrams and coordinate tables
      pdf.addPage(
        pw.MultiPage(
          theme: theme,
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          header: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#1E293B'),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            isArabic
                                ? 'تقرير ومخطط رص الحاويات وتوزيع الشحنة (Container Loading Plan)'
                                : 'Container Load Planner & Stacking Plan Report',
                            style: pw.TextStyle(color: PdfColors.white, fontSize: 13, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Sorour Logistics ERP — 3D Container Load Simulation',
                            style: const pw.TextStyle(color: PdfColors.grey400, fontSize: 8.5),
                          ),
                        ],
                      ),
                      pw.Text(
                        displayName,
                        style: pw.TextStyle(color: PdfColor.fromHex('#38BDF8'), fontSize: 11, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),
              ],
            );
          },
          footer: (pw.Context ctx) {
            return pw.Container(
              padding: const pw.EdgeInsets.only(top: 6),
              decoration: const pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    '${isArabic ? "تاريخ الإصدار: " : "Generated: "}${DateTime.now().toString().substring(0, 19)}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    '${isArabic ? "صفحة " : "Page "}${ctx.pageNumber} ${isArabic ? "من " : "of "}${ctx.pagesCount}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                ],
              ),
            );
          },
          build: (pw.Context ctx) {
            final content = <pw.Widget>[];

            // Metadata Key-Value Grid Table
            content.add(
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.2),
                  1: const pw.FlexColumnWidth(2.0),
                  2: const pw.FlexColumnWidth(1.2),
                  3: const pw.FlexColumnWidth(2.0),
                },
                children: [
                  pw.TableRow(
                    children: [
                      _buildPdfCell(isArabic ? 'أمر الشراء / المرجع' : 'PO Reference', isHeader: true),
                      _buildPdfCell(displayName),
                      _buildPdfCell(isArabic ? 'الرقم الداخلي للنظام' : 'Internal Code', isHeader: true),
                      _buildPdfCell(poNumber ?? '-'),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _buildPdfCell(isArabic ? 'الشركة المستوردة' : 'Importing Company', isHeader: true),
                      _buildPdfCell(companyName ?? '-'),
                      _buildPdfCell(isArabic ? 'المورد الأجنبي' : 'Supplier', isHeader: true),
                      _buildPdfCell(supplierName ?? '-'),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _buildPdfCell(isArabic ? 'أسطول الحاويات المطلوب' : 'Required Fleet', isHeader: true),
                      _buildPdfCell(fleetSummary),
                      _buildPdfCell(isArabic ? 'إجمالي الطرود' : 'Total Packages', isHeader: true),
                      _buildPdfCell('$totalPkgs ${isArabic ? "طرد" : "pkgs"}'),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _buildPdfCell(isArabic ? 'إجمالي الحجم (CBM)' : 'Total Volume', isHeader: true),
                      _buildPdfCell('${totalPlanVolume.toStringAsFixed(3)} m³'),
                      _buildPdfCell(isArabic ? 'إجمالي الوزن القائم' : 'Total Gross Weight', isHeader: true),
                      _buildPdfCell('${PoPackingMatcher.formatWeight(totalPlanWeight)} kg'),
                    ],
                  ),
                ],
              ),
            );

            content.add(pw.SizedBox(height: 10));

            // Section 1: Fleet Container Summary
            content.add(
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#334155'),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  isArabic ? '🚢 ملخص الحاويات ومعدلات استغلال المساحة والوزن' : '🚢 Container Fleet Utilization & Specifications',
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 9.5, fontWeight: pw.FontWeight.bold),
                ),
              ),
            );
            content.add(pw.SizedBox(height: 4));

            final containerSummaryHeaders = [
              '#',
              isArabic ? 'نوع ومواصفات الحاوية' : 'Container Specification',
              isArabic ? 'الأبعاد الداخلية (سم)' : 'Internal Dims (cm)',
              isArabic ? 'عدد الطرود' : 'Packages Placed',
              isArabic ? 'إجمالي الوزن' : 'Gross Wt (kg)',
              isArabic ? 'استغلال الوزن %' : 'Payload Util %',
              isArabic ? 'الحجم (م³)' : 'Volume (m³)',
              isArabic ? 'استغلال الحجم %' : 'Volume Util %',
              isArabic ? 'الحالة' : 'Status',
            ];

            final containerSummaryRows = plan.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final res = entry.value;
              final spacePct = res.spec.internalVolumeCbm > 0 ? ((res.totalVolume / res.spec.internalVolumeCbm) * 100).toStringAsFixed(1) : '0.0';
              final weightPct = res.spec.maxPayloadKg > 0 ? ((res.totalWeight / res.spec.maxPayloadKg) * 100).toStringAsFixed(1) : '0.0';
              final status = res.containerCode == 'FAILED'
                  ? (isArabic ? 'فشل الرص' : 'Failed')
                  : (isArabic ? 'جاهزة للشحن' : 'Ready');

              return [
                '$idx',
                '${res.spec.name} (${res.spec.code})',
                '${res.spec.internalLength.toStringAsFixed(0)} × ${res.spec.internalWidth.toStringAsFixed(0)} × ${res.spec.internalHeight.toStringAsFixed(0)}',
                '${res.placedItems.length}',
                '${PoPackingMatcher.formatWeight(res.totalWeight)} kg',
                '$weightPct%',
                '${res.totalVolume.toStringAsFixed(3)} m³',
                '$spacePct%',
                status,
              ];
            }).toList();

            content.add(
              pw.TableHelper.fromTextArray(
                headers: containerSummaryHeaders,
                data: containerSummaryRows,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, color: PdfColors.white),
                headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#475569')),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3.5),
                cellAlignment: pw.Alignment.centerRight,
                headerAlignment: pw.Alignment.centerRight,
                oddRowDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#F8FAFC')),
              ),
            );

            // Embedded 3D Views Render Image (if captured)
            if (capturedImageBytes != null) {
              content.add(pw.SizedBox(height: 12));
              content.add(
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#334155'),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text(
                    isArabic ? '🖼️ محاكاة ومخطط رص الحاوية (Simulation Views: Side & Top Projections)' : '🖼️ 3D Simulation Views (Side & Top Projections)',
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 9.5, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              );
              content.add(pw.SizedBox(height: 4));
              content.add(
                pw.Container(
                  height: 200,
                  alignment: pw.Alignment.center,
                  decoration: pw.BoxDecoration(
                    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Image(
                    pw.MemoryImage(capturedImageBytes),
                    fit: pw.BoxFit.contain,
                  ),
                ),
              );
            }

            // Section 2: Loading Sequence & Detailed Stacking Coordinates Table
            for (int cIdx = 0; cIdx < plan.length; cIdx++) {
              final res = plan[cIdx];
              if (res.containerCode == 'FAILED') continue;

              content.add(pw.SizedBox(height: 12));
              content.add(
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#1E293B'),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text(
                    isArabic
                        ? '📐 مخطط التحميل وإحداثيات الرص — حاوية #${cIdx + 1} (${res.spec.code}) — إجمالي ${res.placedItems.length} طرد'
                        : '📐 Stacking Plan & Loading Coordinates — Container #${cIdx + 1} (${res.spec.code}) — Total ${res.placedItems.length} Pkgs',
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 9.5, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              );
              content.add(pw.SizedBox(height: 4));

              final coordHeaders = [
                '#',
                isArabic ? 'كود الطرد / الصنف' : 'Package / Item Code',
                isArabic ? 'الأبعاد طول×عرض×ارتفاع (سم)' : 'Dims L×W×H (cm)',
                isArabic ? 'الوزن (كجم)' : 'Weight (kg)',
                isArabic ? 'الإحداثيات الثلاثية (X | Y | Z)' : '3D Coordinates (X | Y | Z)',
                isArabic ? 'طريقة الرص' : 'Stacking Mode',
              ];

              final coordRows = res.placedItems.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final placed = entry.value;
                return [
                  '$idx',
                  placed.item.description ?? placed.item.itemId,
                  '${placed.length.toStringAsFixed(0)} × ${placed.width.toStringAsFixed(0)} × ${placed.height.toStringAsFixed(0)}',
                  PoPackingMatcher.formatWeight(placed.item.weight),
                  'X: ${placed.x.toStringAsFixed(0)} | Y: ${placed.y.toStringAsFixed(0)} | Z: ${placed.z.toStringAsFixed(0)}',
                  placed.item.isStackable ? (isArabic ? 'رص عمودي' : 'Stackable') : (isArabic ? 'أرضي فقط' : 'Floor Only'),
                ];
              }).toList();

              content.add(
                pw.TableHelper.fromTextArray(
                  headers: coordHeaders,
                  data: coordRows,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, color: PdfColors.white),
                  headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#475569')),
                  cellStyle: const pw.TextStyle(fontSize: 8),
                  cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  cellAlignment: pw.Alignment.centerRight,
                  headerAlignment: pw.Alignment.centerRight,
                  oddRowDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#F8FAFC')),
                ),
              );
            }

            return content;
          },
        ),
      );

      final pdfBytes = await pdf.save();
      if (!context.mounted) return;

      await FileSaveHelper.exportAndSaveFile(
        context: context,
        bytes: pdfBytes,
        stageName: isArabic ? 'محاكي الحاوية 3D' : '3D Container Planner',
        importFileNameOrCode: '$displayName - Loading Plan',
        extension: 'pdf',
        customDialogTitle: isArabic ? 'تنزيل مخطط تحميل ورص الحاوية (PDF)' : 'Download Container Loading Plan (PDF)',
        showNotification: true,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${isArabic ? "خطأ في تصدير ملف PDF: " : "Error exporting PDF: "}$e'),
            backgroundColor: AppTheme.crimson,
          ),
        );
      }
    }
  }

  static pw.Widget _buildPdfCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      color: isHeader ? PdfColor.fromHex('#F1F5F9') : PdfColors.white,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColor.fromHex('#1E293B') : PdfColors.grey800,
        ),
      ),
    );
  }
}
