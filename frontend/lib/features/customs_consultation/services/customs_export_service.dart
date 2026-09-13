import 'package:flutter/material.dart';
import '../../../core/services/file_save_helper.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/copyable_data_helper.dart';
import '../../../core/services/display_name_resolver.dart';
import '../../import_files/models/import_file_model.dart';
import '../models/customs_consultation_model.dart';

class NafezaFeeItem {
  final String code;
  final String nameAr;
  final String calculationType; // 'flat', 'reference', 'derived'
  final double calculatedAmount;

  NafezaFeeItem({
    required this.code,
    required this.nameAr,
    required this.calculationType,
    required this.calculatedAmount,
  });
}

class NafezaFeeGroup {
  final String groupName;
  final double totalAmount;
  final List<NafezaFeeItem> items;

  NafezaFeeGroup({
    required this.groupName,
    required this.totalAmount,
    required this.items,
  });
}

class NafezaFeeBreakdownResult {
  final double grandTotal;
  final List<NafezaFeeGroup> groups;

  NafezaFeeBreakdownResult({
    required this.grandTotal,
    required this.groups,
  });
}

class CustomsExportService {
  /// Computes the 5 official Nafeza collection groups and their items
  static NafezaFeeBreakdownResult computeNafezaFeeBreakdown({
    required double totalDutyEgp,
    required double totalVatEgp,
    required double totalServiceFeeEgp,
    required double totalScheduleTaxEgp,
    double extraAdminFeesEgp = 750.0,
  }) {
    final List<NafezaFeeGroup> groups = [];

    // 1. تحصيل رسم مستخلص
    final group1Items = [
      NafezaFeeItem(code: '77', nameAr: 'ضريبة مهن حرة', calculationType: 'flat', calculatedAmount: 50.0),
    ];
    final group1Total = group1Items.fold(0.0, (s, i) => s + i.calculatedAmount);
    groups.add(NafezaFeeGroup(groupName: 'رسم مستخلص', totalAmount: group1Total, items: group1Items));

    // 2. تحصيل ضريبة جمارك
    final group2Items = [
      NafezaFeeItem(code: '250', nameAr: 'رسم طباعة بيان جمركي موحد', calculationType: 'flat', calculatedAmount: 55.0),
      NafezaFeeItem(code: '798', nameAr: 'رسم نموذج 19 ك م', calculationType: 'flat', calculatedAmount: 35.0),
      NafezaFeeItem(code: '60', nameAr: 'دمغة إقرار مميكن', calculationType: 'flat', calculatedAmount: 4.50),
      NafezaFeeItem(code: '74', nameAr: 'رسم خدمات مميكنة', calculationType: 'flat', calculatedAmount: 20.0),
      NafezaFeeItem(code: '107', nameAr: 'رسم تنمية محررات', calculationType: 'flat', calculatedAmount: 2.0),
      NafezaFeeItem(code: '1', nameAr: 'ضريبة الوارد', calculationType: 'reference', calculatedAmount: totalDutyEgp),
      NafezaFeeItem(code: '3', nameAr: 'رسم مصاريف إدارية', calculationType: 'flat', calculatedAmount: extraAdminFeesEgp),
    ];
    final group2Total = group2Items.fold(0.0, (s, i) => s + i.calculatedAmount);
    groups.add(NafezaFeeGroup(groupName: 'ضريبة جمارك', totalAmount: group2Total, items: group2Items));

    // 3. تحصيل أ.ت.ص
    final group3Items = [
      NafezaFeeItem(code: '37', nameAr: 'ضريبة أ.ت.ص', calculationType: 'reference', calculatedAmount: totalServiceFeeEgp),
    ];
    final group3Total = group3Items.fold(0.0, (s, i) => s + i.calculatedAmount);
    groups.add(NafezaFeeGroup(groupName: 'أ.ت.ص', totalAmount: group3Total, items: group3Items));

    // 4. تحصيل ض.مبيعات
    final group4Items = [
      NafezaFeeItem(code: '232', nameAr: 'تحت حساب قيمة مضافة', calculationType: 'flat', calculatedAmount: 100.0),
      NafezaFeeItem(code: '32', nameAr: 'ضريبة قيمة مضافة', calculationType: 'reference', calculatedAmount: totalVatEgp),
    ];
    final group4Total = group4Items.fold(0.0, (s, i) => s + i.calculatedAmount);
    groups.add(NafezaFeeGroup(groupName: 'ض.مبيعات', totalAmount: group4Total, items: group4Items));

    // 5. تحصيل رسوم النافذة الموحدة
    const fee390 = 1081.0;
    const fee392 = 3457.0;
    const fee394 = (fee390 + fee392) * 0.14; // 14% VAT on Nafeza Services = 635.32 EGP
    final group5Items = [
      NafezaFeeItem(code: '397', nameAr: 'صندوق تكريم الشهداء', calculationType: 'flat', calculatedAmount: 5.0),
      NafezaFeeItem(code: '390', nameAr: 'خدمات جمركية', calculationType: 'flat', calculatedAmount: fee390),
      NafezaFeeItem(code: '392', nameAr: 'خدمات معلوماتية', calculationType: 'flat', calculatedAmount: fee392),
      NafezaFeeItem(code: '394', nameAr: 'ضريبة قيمة مضافة على خدمات نافذة', calculationType: 'derived', calculatedAmount: fee394),
    ];
    final group5Total = group5Items.fold(0.0, (s, i) => s + i.calculatedAmount);
    groups.add(NafezaFeeGroup(groupName: 'رسوم النافذة الموحدة', totalAmount: group5Total, items: group5Items));

    final grandTotal = groups.fold(0.0, (s, g) => s + g.totalAmount);
    return NafezaFeeBreakdownResult(grandTotal: grandTotal, groups: groups);
  }

  /// Exports Customs Calculation Lines to a TSV string with UTF-8 BOM and localized headers
  static Future<String> exportCustomsLinesTsv({
    required BuildContext context,
    required List<CustomsItemCalcRow> calcLines,
    required String currency,
    bool copyToClipboard = true,
  }) async {
    final l = context.l10n;
    final buffer = StringBuffer();
    buffer.write('\uFEFF');
    final headers = [
      l.customsTaxTsvHeaderHsCode,
      l.customsTaxTsvHeaderDescription,
      l.customsTaxTsvHeaderOrigin,
      l.customsTaxTsvHeaderQty,
      l.customsTaxTsvHeaderUnit,
      l.customsTaxTsvHeaderForeignPrice,
      l.customsTaxTsvHeaderFobEgp,
      l.customsTaxTsvHeaderFreightEgp,
      l.customsTaxTsvHeaderInsuranceEgp,
      l.customsTaxTsvHeaderCifEgp,
      l.customsTaxTsvHeaderDutyRate,
      l.customsTaxTsvHeaderDutyAmount,
      l.customsTaxTsvHeaderVatRate,
      l.customsTaxTsvHeaderVatAmount,
      l.customsTaxTsvHeaderScheduleTax,
      l.customsTaxTsvHeaderCustomsFees,
      l.customsTaxTsvHeaderTotalTaxes,
      l.customsTaxTsvHeaderRegulatoryConditions,
    ];
    buffer.writeln(headers.join('\t'));

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    for (final line in calcLines) {
      final conditions = line.regulatoryAuthority != null
          ? '${line.regulatoryAuthority} - ${line.priorApprovalNote ?? ""}'
          : (isArabic ? 'مستوفى' : 'Compliant');
      final row = [
        line.hsCode,
        line.description,
        line.countryOfOrigin ?? '-',
        line.qty.toStringAsFixed(0),
        line.unit,
        line.foreignPrice.toStringAsFixed(2),
        line.fobEgp.toStringAsFixed(2),
        line.freightEgp.toStringAsFixed(2),
        line.insuranceEgp.toStringAsFixed(2),
        line.cifEgp.toStringAsFixed(2),
        '${line.dutyRate}%',
        line.dutyAmountEgp.toStringAsFixed(2),
        '${line.vatRate}%',
        line.vatAmountEgp.toStringAsFixed(2),
        line.scheduleTaxAmountEgp.toStringAsFixed(2),
        (line.customsServiceFeeAmountEgp + line.developmentFeeAmountEgp).toStringAsFixed(2),
        line.totalTaxesAndDutiesEgp.toStringAsFixed(2),
        conditions,
      ];
      buffer.writeln(row.join('\t'));
    }

    final result = buffer.toString();
    if (copyToClipboard && context.mounted) {
      await CopyHelper.copy(context, result, customMessage: l.customsTaxCopiedTsvSuccess);
    }
    return result;
  }

  /// Builds a comprehensive structured plain-text dossier for the customs assessment and Nafeza breakdown
  static String buildCustomsDutyDossier({
    required BuildContext context,
    required String title,
    required String? importFileCode,
    required String brokerName,
    required String currency,
    required double exchangeRate,
    required double totalFreightEgp,
    required double totalInsuranceEgp,
    required List<CustomsItemCalcRow> calcLines,
    required NafezaFeeBreakdownResult nafezaResult,
  }) {
    final l = context.l10n;
    final buffer = StringBuffer();
    final now = DateTime.now().toLocal().toString().split('.').first;
    final totalFobEgp = calcLines.fold(0.0, (s, l) => s + l.fobEgp);
    final totalCifEgp = calcLines.fold(0.0, (s, l) => s + l.cifEgp);
    final totalDutyEgp = calcLines.fold(0.0, (s, l) => s + l.dutyAmountEgp);
    final totalVatEgp = calcLines.fold(0.0, (s, l) => s + l.vatAmountEgp);
    final totalTaxesAndDuties = calcLines.fold(0.0, (s, l) => s + l.totalTaxesAndDutiesEgp);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final egpLabel = isArabic ? 'ج.م' : 'EGP';

    buffer.writeln('====================================================');
    buffer.writeln('📋 ${l.customsTaxDossierTitle}');
    buffer.writeln('====================================================');
    buffer.writeln('${l.titleField}: $title');
    buffer.writeln('${isArabic ? "ملف الشحنة" : "Import File"}: ${importFileCode ?? "-"}');
    buffer.writeln('${l.customsBrokerLabel}: $brokerName');
    buffer.writeln('${l.exchangeRateLabel}: $exchangeRate $egpLabel ($currency)');
    buffer.writeln('${isArabic ? "التاريخ" : "Date"}: $now');
    buffer.writeln('----------------------------------------------------');
    buffer.writeln('💰 ${l.sectionFinancialEstimates}:');
    buffer.writeln('  • ${l.fobEgpCol}: ${totalFobEgp.toStringAsFixed(2)} $egpLabel');
    buffer.writeln('  • ${l.freightDataHeader}: ${totalFreightEgp.toStringAsFixed(2)} $egpLabel');
    buffer.writeln('  • ${l.insuranceEgpLabel}: ${totalInsuranceEgp.toStringAsFixed(2)} $egpLabel');
    buffer.writeln('  • ${l.cifEgpCol}: ${totalCifEgp.toStringAsFixed(2)} $egpLabel');
    buffer.writeln('  • ${l.customsDutyCol}: ${totalDutyEgp.toStringAsFixed(2)} $egpLabel');
    buffer.writeln('  • ${l.vatCol}: ${totalVatEgp.toStringAsFixed(2)} $egpLabel');
    buffer.writeln('  • ${l.totalTaxesAndDutiesCol}: ${totalTaxesAndDuties.toStringAsFixed(2)} $egpLabel');
    buffer.writeln('  • ${l.nafezaDeclarationBreakdown}: ${nafezaResult.grandTotal.toStringAsFixed(2)} $egpLabel');
    buffer.writeln('----------------------------------------------------');
    buffer.writeln('📦 ${l.customsTaxTsvHeaderHsCode} (${calcLines.length}):');
    for (var i = 0; i < calcLines.length; i++) {
      final line = calcLines[i];
      buffer.writeln('  [${i + 1}] ${line.hsCode} | ${line.description}');
      buffer.writeln('      ${l.quantityAndUnitCol}: ${line.qty.toStringAsFixed(0)} ${line.unit} | CIF: ${line.cifEgp.toStringAsFixed(2)} $egpLabel');
      buffer.writeln('      ${l.customsDutyCol}: ${line.dutyRate}% (${line.dutyAmountEgp.toStringAsFixed(2)} $egpLabel) | VAT: ${line.vatRate}% (${line.vatAmountEgp.toStringAsFixed(2)} $egpLabel)');
      buffer.writeln('      ${l.totalTaxesAndDutiesCol}: ${line.totalTaxesAndDutiesEgp.toStringAsFixed(2)} $egpLabel');
      if (line.regulatoryAuthority != null || line.priorApprovalNote != null) {
        buffer.writeln('      ${l.customsTaxTsvHeaderRegulatoryConditions}: ${line.regulatoryAuthority ?? ""} - ${line.priorApprovalNote ?? ""}');
      }
    }
    buffer.writeln('----------------------------------------------------');
    buffer.writeln('🏛️ ${l.nafezaDeclarationBreakdown}:');
    for (final g in nafezaResult.groups) {
      buffer.writeln('  • ${l.nafezaCollectionPrefix} ${g.groupName}: ${g.totalAmount.toStringAsFixed(2)} $egpLabel');
      for (final itm in g.items) {
        buffer.writeln('      [${itm.code}] ${itm.nameAr}: ${itm.calculatedAmount.toStringAsFixed(2)} $egpLabel (${itm.calculationType})');
      }
    }
    buffer.writeln('====================================================');
    return buffer.toString();
  }

  /// Copies the customs assessment dossier to clipboard
  static Future<void> copyCustomsDutyDossier({
    required BuildContext context,
    required String title,
    required String? importFileCode,
    required String brokerName,
    required String currency,
    required double exchangeRate,
    required double totalFreightEgp,
    required double totalInsuranceEgp,
    required List<CustomsItemCalcRow> calcLines,
    required NafezaFeeBreakdownResult nafezaResult,
  }) async {
    final dossier = buildCustomsDutyDossier(
      context: context,
      title: title,
      importFileCode: importFileCode,
      brokerName: brokerName,
      currency: currency,
      exchangeRate: exchangeRate,
      totalFreightEgp: totalFreightEgp,
      totalInsuranceEgp: totalInsuranceEgp,
      calcLines: calcLines,
      nafezaResult: nafezaResult,
    );
    final l = context.l10n;
    await CopyHelper.copy(context, dossier, customMessage: l.customsTaxCopiedDossierSuccess);
  }

  /// Exports Customs Tax Review Sessions to a TSV string with UTF-8 BOM
  static Future<String> exportConsultationsLogTsv({
    required BuildContext context,
    required List<CustomsConsultationModel> sessions,
    List<ImportFileModel>? shipments,
    bool copyToClipboard = true,
  }) async {
    final l = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final buffer = StringBuffer();
    buffer.write('\uFEFF');
    final headers = [
      l.customsTaxLogTsvHeaderCode,
      l.customsTaxLogTsvHeaderFile,
      l.customsTaxLogTsvHeaderTitle,
      l.customsTaxLogTsvHeaderBroker,
      l.customsTaxLogTsvHeaderEstimatedDuties,
      l.customsTaxLogTsvHeaderReadiness,
      l.customsTaxLogTsvHeaderStatus,
      l.customsTaxLogTsvHeaderCreatedDate,
    ];
    buffer.writeln(headers.join('\t'));

    for (final s in sessions) {
      final rawFileCode = s.importFileCode ?? (s.importFileId != null ? 'IMP-${s.importFileId}' : '-');
      final fileCodeStr = (rawFileCode != '-' && shipments != null)
          ? DisplayNameResolver.resolveShipmentTitleByCode(rawFileCode, shipments: shipments, isArabic: isArabic)
          : rawFileCode;
      final dateStr = s.createdAt.split('T').first.split(' ').first;
      final row = [
        s.consultationCode,
        fileCodeStr,
        s.title,
        s.brokerName,
        s.estimatedDutiesEgp.toStringAsFixed(2),
        '${s.readinessPercentage.toStringAsFixed(0)}%',
        s.overallStatus,
        dateStr,
      ];
      buffer.writeln(row.join('\t'));
    }

    final result = buffer.toString();
    if (copyToClipboard && context.mounted) {
      await CopyHelper.copy(context, result, customMessage: l.customsTaxCopiedTsvSuccess);
    }
    return result;
  }

  /// Exports Customs Tax Review Sessions to Excel/CSV file with UTF-8 BOM
  static Future<String?> exportConsultationsLogExcel({
    required BuildContext context,
    required List<CustomsConsultationModel> sessions,
    List<ImportFileModel>? shipments,
  }) async {
    final l = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final buffer = StringBuffer();
    buffer.write('\uFEFF');
    buffer.writeln('"${l.taxReviewLogTab}"');
    buffer.writeln('"${l.date}: ${DateTime.now().toLocal().toString().split('.').first}"');
    buffer.writeln('');

    final headers = [
      l.customsTaxLogTsvHeaderCode,
      l.customsTaxLogTsvHeaderFile,
      l.customsTaxLogTsvHeaderTitle,
      l.customsTaxLogTsvHeaderBroker,
      l.customsTaxLogTsvHeaderEstimatedDuties,
      l.customsTaxLogTsvHeaderReadiness,
      l.customsTaxLogTsvHeaderStatus,
      l.customsTaxLogTsvHeaderCreatedDate,
    ];
    buffer.writeln(headers.map((h) => '"$h"').join(','));

    for (final s in sessions) {
      final rawFileCode = s.importFileCode ?? (s.importFileId != null ? 'IMP-${s.importFileId}' : '-');
      final fileCodeStr = (rawFileCode != '-' && shipments != null)
          ? DisplayNameResolver.resolveShipmentTitleByCode(rawFileCode, shipments: shipments, isArabic: isArabic)
          : rawFileCode;
      final dateStr = s.createdAt.split('T').first.split(' ').first;
      final row = [
        s.consultationCode,
        fileCodeStr,
        s.title.replaceAll('"', '""'),
        s.brokerName.replaceAll('"', '""'),
        s.estimatedDutiesEgp.toStringAsFixed(2),
        '${s.readinessPercentage.toStringAsFixed(0)}%',
        s.overallStatus,
        dateStr,
      ];
      buffer.writeln(row.map((r) => '"$r"').join(','));
    }

    final defaultFileName = 'Customs_Tax_Review_Log_${DateTime.now().millisecondsSinceEpoch}.csv';
    return FileSaveHelper.saveText(
      context: context,
      textContent: buffer.toString(),
      defaultFileName: defaultFileName,
      dialogTitle: l.customsTaxExportExcelDialogTitle,
      allowedExtensions: ['csv', 'xlsx'],
    );
  }

  /// Builds a text dossier summary of the visible consultations log
  static String buildConsultationsLogDossier({
    required BuildContext context,
    required List<CustomsConsultationModel> sessions,
    List<ImportFileModel>? shipments,
  }) {
    final l = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final egpLabel = isArabic ? 'ج.م' : 'EGP';
    final buffer = StringBuffer();
    final now = DateTime.now().toLocal().toString().split('.').first;
    buffer.writeln('====================================================');
    buffer.writeln('📊 ${l.taxReviewLogTab} — ${l.customsTaxDossierTitle}');
    buffer.writeln('====================================================');
    buffer.writeln('${l.date}: $now');
    buffer.writeln('${l.totalStudiesMetric}: ${sessions.length}');
    buffer.writeln('----------------------------------------------------');
    for (var i = 0; i < sessions.length; i++) {
      final s = sessions[i];
      final rawFileCode = s.importFileCode ?? (s.importFileId != null ? 'IMP-${s.importFileId}' : '-');
      final fileCodeStr = (rawFileCode != '-' && shipments != null)
          ? DisplayNameResolver.resolveShipmentTitleByCode(rawFileCode, shipments: shipments, isArabic: isArabic)
          : rawFileCode;
      buffer.writeln('[${i + 1}] ${s.consultationCode} | $fileCodeStr | ${s.title}');
      buffer.writeln('    ${l.customsBrokerLabel}: ${s.brokerName} | ${l.statusCol}: ${s.overallStatus}');
      buffer.writeln('    ${l.customsDutyCol}: ${s.estimatedDutiesEgp.toStringAsFixed(2)} $egpLabel | ${l.customsInspectionReadiness}: ${s.readinessPercentage.toStringAsFixed(0)}%');
    }
    buffer.writeln('====================================================');
    return buffer.toString();
  }

  /// Copies the consultations log dossier summary to clipboard
  static Future<void> copyConsultationsLogDossier({
    required BuildContext context,
    required List<CustomsConsultationModel> sessions,
    List<ImportFileModel>? shipments,
  }) async {
    final dossier = buildConsultationsLogDossier(context: context, sessions: sessions, shipments: shipments);
    final l = context.l10n;
    await CopyHelper.copy(context, dossier, customMessage: l.customsTaxCopiedDossierSuccess);
  }

  /// Exports the complete customs calculation & Nafeza statement to an Excel-compatible CSV file (UTF-8 BOM)
  static Future<String?> exportCustomsStudyToExcel({
    required BuildContext context,
    required String title,
    required String? importFileCode,
    required String brokerName,
    required String currency,
    required double exchangeRate,
    required double totalFreightEgp,
    required double totalInsuranceEgp,
    required List<CustomsItemCalcRow> calcLines,
    required NafezaFeeBreakdownResult nafezaResult,
    required List<CustomsBrokerQuoteItemModel> brokerQuoteItems,
  }) async {
    final l = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final egpLabel = isArabic ? 'ج.م' : 'EGP';
    final buffer = StringBuffer();
    // Write UTF-8 BOM for instant Arabic Excel compatibility
    buffer.write('\uFEFF');

    // 1. Header Information
    buffer.writeln(isArabic
        ? 'Sorour Logistics ERP — تقرير دراسة الاستشارة الجمركية وبيان نافذة الرسمي'
        : 'Sorour Logistics ERP — Customs Assessment & Official Nafeza Statement');
    buffer.writeln('${l.titleField}:,"$title"');
    buffer.writeln('${isArabic ? "ملف الشحنة" : "Import File"}:,"${importFileCode ?? (isArabic ? "غير محدد" : "Unassigned")}"');
    buffer.writeln('${l.customsBrokerLabel}:,"$brokerName"');
    buffer.writeln('${isArabic ? "التاريخ" : "Date"}:,"${DateTime.now().toLocal().toString().split('.').first}"');
    buffer.writeln('${isArabic ? "العملة" : "Currency"}:,"$currency",${l.exchangeRateLabel}:,"$exchangeRate $egpLabel"');
    buffer.writeln('${l.freightDataHeader}:,"$totalFreightEgp $egpLabel",${l.insuranceEgpLabel}:,"$totalInsuranceEgp $egpLabel"');
    buffer.writeln('');

    // 2. HS Code Itemized Customs Breakdown Table
    buffer.writeln(isArabic
        ? '=== جدول تفاصيل بنود التعريفة والضرائب الجمركية للشحنة ==='
        : '=== HS Code Customs Tariff & Tax Breakdown ===');
    final tableHeaders = [
      l.customsTaxTsvHeaderHsCode,
      l.customsTaxTsvHeaderDescription,
      l.customsTaxTsvHeaderOrigin,
      l.customsTaxTsvHeaderQty,
      l.customsTaxTsvHeaderUnit,
      '${l.customsTaxTsvHeaderForeignPrice} ($currency)',
      l.customsTaxTsvHeaderFobEgp,
      l.customsTaxTsvHeaderFreightEgp,
      l.customsTaxTsvHeaderInsuranceEgp,
      l.customsTaxTsvHeaderCifEgp,
      l.customsTaxTsvHeaderDutyRate,
      l.customsTaxTsvHeaderDutyAmount,
      l.customsTaxTsvHeaderVatRate,
      l.customsTaxTsvHeaderVatAmount,
      l.customsTaxTsvHeaderScheduleTax,
      l.customsTaxTsvHeaderCustomsFees,
      l.customsTaxTsvHeaderTotalTaxes,
      l.customsTaxTsvHeaderRegulatoryConditions,
    ];
    buffer.writeln(tableHeaders.map((h) => '"$h"').join(','));

    for (final line in calcLines) {
      final hs = line.hsCode;
      final desc = line.description.replaceAll('"', '""');
      final orig = line.countryOfOrigin ?? '-';
      final qty = line.qty;
      final unit = line.unit;
      final fPrice = line.foreignPrice.toStringAsFixed(2);
      final fob = line.fobEgp.toStringAsFixed(2);
      final frt = line.freightEgp.toStringAsFixed(2);
      final ins = line.insuranceEgp.toStringAsFixed(2);
      final cif = line.cifEgp.toStringAsFixed(2);
      final dRate = line.dutyRate.toStringAsFixed(1);
      final dAmt = line.dutyAmountEgp.toStringAsFixed(2);
      final vRate = line.vatRate.toStringAsFixed(1);
      final vAmt = line.vatAmountEgp.toStringAsFixed(2);
      final sAmt = line.scheduleTaxAmountEgp.toStringAsFixed(2);
      final svcAmt = (line.customsServiceFeeAmountEgp + line.developmentFeeAmountEgp).toStringAsFixed(2);
      final lineTot = line.totalTaxesAndDutiesEgp.toStringAsFixed(2);
      final reqs = line.regulatoryAuthority != null
          ? '${line.regulatoryAuthority} - ${line.priorApprovalNote ?? ""}'.replaceAll('"', '""')
          : (isArabic ? 'مستوفى' : 'Compliant');

      buffer.writeln('"$hs","$desc","$orig",$qty,"$unit",$fPrice,$fob,$frt,$ins,$cif,"$dRate%",$dAmt,"$vRate%",$vAmt,$sAmt,$svcAmt,$lineTot,"$reqs"');
    }
    buffer.writeln('');

    // 3. Nafeza Statement Fee Breakdown
    buffer.writeln(isArabic
        ? '=== تفاصيل بنود التحصيل والإقرارات الرسمية نافذة ==='
        : '=== Official Nafeza Statement Fee Breakdown ===');
    buffer.writeln('"${isArabic ? "مجموعة التحصيل" : "Collection Group"}","${isArabic ? "كود البند" : "Item Code"}","${isArabic ? "اسم البند" : "Item Name"}","${isArabic ? "نوع الحساب" : "Calc Type"}","${isArabic ? "المبلغ (ج.م)" : "Amount (EGP)"}"');

    for (final group in nafezaResult.groups) {
      for (final item in group.items) {
        final calcTypeLabel = item.calculationType == 'flat'
            ? l.nafezaCalculationFlat
            : (item.calculationType == 'reference' ? l.nafezaCalculationReference : l.nafezaCalculationDerived);
        buffer.writeln('"${l.nafezaCollectionPrefix} ${group.groupName}","[${item.code}]","${item.nameAr}","$calcTypeLabel",${item.calculatedAmount.toStringAsFixed(2)}');
      }
      buffer.writeln('"${isArabic ? "إجمالي تحصيل" : "Total"} ${group.groupName}","","","",${group.totalAmount.toStringAsFixed(2)}');
    }
    buffer.writeln('"${isArabic ? "إجمالي بيان نافذة الرسمي" : "Grand Total Nafeza Statement"}","","","",${nafezaResult.grandTotal.toStringAsFixed(2)}');
    buffer.writeln('');

    // 4. Broker Clearance & Logistics Quotes (عرض أسعار المخلص)
    if (brokerQuoteItems.isNotEmpty) {
      buffer.writeln('=== ${isArabic ? "تفاصيل عرض أسعار التخليص الجمركي والنقل" : "Clearance & Logistics Quotation"} ($brokerName) ===');
      buffer.writeln('"${isArabic ? "اسم المصروف" : "Expense Name"}","${isArabic ? "التصنيف" : "Category"}","${isArabic ? "الوحدة" : "Unit"}",${isArabic ? "سعر الوحدة" : "Unit Price"},"${isArabic ? "العملة" : "Currency"}",${isArabic ? "الكمية" : "Quantity"},"${isArabic ? "الحالة" : "Status"}",${isArabic ? "الإجمالي ($egpLabel)" : "Total ($egpLabel)"}');
      double brokerTotal = 0.0;
      for (final q in brokerQuoteItems) {
        final total = q.isApplicable ? q.totalAmount : 0.0;
        if (q.isApplicable) brokerTotal += total;
        final statusLabel = q.isApplicable ? (isArabic ? 'مطبق' : 'Applied') : (isArabic ? 'غير مطبق' : 'Not Applied');
        buffer.writeln('"${q.expenseName}","${q.category}","${q.unitType}",${q.unitPrice},"${q.currency}",${q.qty},"$statusLabel",${total.toStringAsFixed(2)}');
      }
      buffer.writeln('"${isArabic ? "إجمالي عرض أسعار المخلص المطبق" : "Total Applied Broker Fees"}","","","","","",,"${brokerTotal.toStringAsFixed(2)}"');
      buffer.writeln('');
    }

    // Save dialog via FileSaveHelper
    final cleanCode = (importFileCode != null && importFileCode.trim().isNotEmpty)
        ? importFileCode.replaceAll(RegExp(r'[^0-9A-Za-z_-]'), '_')
        : '${DateTime.now().millisecondsSinceEpoch}';
    final defaultFileName = 'Customs_Tax_Review_${cleanCode}_${DateTime.now().millisecondsSinceEpoch}.csv';
    return FileSaveHelper.saveText(
      context: context,
      textContent: buffer.toString(),
      defaultFileName: defaultFileName,
      dialogTitle: l.customsTaxExportExcelDialogTitle,
      allowedExtensions: ['csv', 'xlsx'],
    );
  }
}

