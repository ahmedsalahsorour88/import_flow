import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/services/file_save_helper.dart';
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
    required List<dynamic> calcLines,
    required NafezaFeeBreakdownResult nafezaResult,
    required List<CustomsBrokerQuoteItemModel> brokerQuoteItems,
  }) async {
    final buffer = StringBuffer();
    // Write UTF-8 BOM for instant Arabic Excel compatibility
    buffer.write('\uFEFF');

    // 1. Header Information
    buffer.writeln('Sorour Logistics ERP — تقرير دراسة الاستشارة الجمركية وبيان نافذة الرسمي');
    buffer.writeln('عنوان الدراسة:,"$title"');
    buffer.writeln('ملف الشحنة:,"${importFileCode ?? 'غير محدد'}"');
    buffer.writeln('المستخلص الجمركي:,"$brokerName"');
    buffer.writeln('تاريخ الاستخراج:,"${DateTime.now().toLocal().toString().split('.').first}"');
    buffer.writeln('عملة الفاتورة:,"$currency",سعر الصرف الجمركي:,"$exchangeRate EGP"');
    buffer.writeln('إجمالي النولون:,"$totalFreightEgp EGP",إجمالي التأمين:,"$totalInsuranceEgp EGP"');
    buffer.writeln('');

    // 2. HS Code Itemized Customs Breakdown Table
    buffer.writeln('=== جدول تفاصيل بنود التعريفة والضرائب الجمركية للشحنة ===');
    buffer.writeln('بند التعريفة (HS Code),بيان الصنف والمواصفات,الكمية,الوحدة,القيمة ($currency),FOB (EGP),النولون (EGP),التأمين (EGP),CIF الجمركي (EGP),ضريبة الوارد %,مبلغ الوارد (EGP),ض.قيمة مضافة %,مبلغ VAT (EGP),ض.جدول %,خدمات/تنمية %,إجمالي الضرائب والرسوم (EGP),الاشتراطات والعروض');

    for (final line in calcLines) {
      final hs = line.hsCode;
      final desc = line.description.replaceAll('"', '""');
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
      final sRate = line.scheduleTaxRate.toStringAsFixed(1);
      final svc = (line.customsServiceFeeAmountEgp + line.developmentFeeAmountEgp).toStringAsFixed(2);
      final lineTot = line.totalTaxesAndDutiesEgp.toStringAsFixed(2);
      final reqs = line.regulatoryAuthority != null ? '${line.regulatoryAuthority} - ${line.priorApprovalNote ?? ''}' : 'مطابق';

      buffer.writeln('"$hs","$desc",$qty,"$unit",$fPrice,$fob,$frt,$ins,$cif,$dRate%,$dAmt,$vRate%,$vAmt,$sRate%,$svc,$lineTot,"$reqs"');
    }
    buffer.writeln('');

    // 3. Nafeza Statement Fee Breakdown (تفاصيل بنود التحصيل والإقرارات الرسمية)
    buffer.writeln('=== تفاصيل بنود التحصيل والإقرارات الرسمية (Nafeza Statement Fee Breakdown) ===');
    buffer.writeln('مجموعة التحصيل,كود البند,اسم البند / نوع الرسم,نوع الحساب,المبلغ المحسوب (ج.م)');

    for (final group in nafezaResult.groups) {
      for (final item in group.items) {
        final calcTypeLabel = item.calculationType == 'flat' ? 'قطعي' : (item.calculationType == 'reference' ? 'مرجعي' : 'مشتق');
        buffer.writeln('"تحصيل ${group.groupName}","[${item.code}]","${item.nameAr}","$calcTypeLabel",${item.calculatedAmount.toStringAsFixed(2)}');
      }
      buffer.writeln('"إجمالي تحصيل ${group.groupName}","","","",${group.totalAmount.toStringAsFixed(2)}');
    }
    buffer.writeln('"إجمالي بيان نافذة الرسمي (Grand Total)","","","",${nafezaResult.grandTotal.toStringAsFixed(2)}');
    buffer.writeln('');

    // 4. Broker Clearance & Logistics Quotes (عرض أسعار المخلص)
    if (brokerQuoteItems.isNotEmpty) {
      buffer.writeln('=== تفاصيل عرض أسعار التخليص الجمركي والنقل للمستخلص ($brokerName) ===');
      buffer.writeln('اسم المصروف / الخدمة,التصنيف,الوحدة,سعر الوحدة,العملة,الكمية,الحالة,الإجمالي (EGP)');
      double brokerTotal = 0.0;
      for (final q in brokerQuoteItems) {
        final total = q.isApplicable ? q.totalAmount : 0.0;
        if (q.isApplicable) brokerTotal += total;
        buffer.writeln('"${q.expenseName}","${q.category}","${q.unitType}",${q.unitPrice},"${q.currency}",${q.qty},"${q.isApplicable ? 'مطبق' : 'غير مطبق'}",${total.toStringAsFixed(2)}');
      }
      buffer.writeln('"إجمالي عرض أسعار المخلص المطبق","","","","","",,"${brokerTotal.toStringAsFixed(2)}"');
      buffer.writeln('');
    }

    // Save dialog via FileSaveHelper
    final defaultFileName = 'Customs_Study_${DateTime.now().millisecondsSinceEpoch}.csv';
    return FileSaveHelper.saveText(
      context: null,
      textContent: buffer.toString(),
      defaultFileName: defaultFileName,
      dialogTitle: 'حفظ دراسة الجمارك وبيان نافذة بصيغة Excel / CSV',
      allowedExtensions: ['csv', 'xlsx'],
    );
  }
}
