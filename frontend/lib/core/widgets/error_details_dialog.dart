import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class ParsedErrorInfo {
  final String summary;
  final List<String> errorPoints;
  final String rawTechnicalLog;

  ParsedErrorInfo({
    required this.summary,
    required this.errorPoints,
    required this.rawTechnicalLog,
  });
}

class ErrorFormatter {
  static final Map<String, String> _fieldTranslations = {
    'importer_name': 'اسم الشركة المستوردة',
    'importer_tax_id': 'الرقم الضريبي للمستورد',
    'importer_address': 'عنوان المستورد',
    'exporter_name': 'اسم المورد / المصدر الأجنبي',
    'exporter_reg_type': 'نوع التسجيل للمصدر',
    'exporter_reg_id': 'المعرف الضريبي / السجل للمصدر',
    'exporter_country': 'دولة المورد',
    'exporter_country_code': 'كود الدولة',
    'exporter_address': 'عنوان المصدر بالخارج',
    'exporter_phone': 'هاتف المصدر',
    'cargox_id': 'معرف CargoX للمصدر',
    'proforma_invoice_no': 'رقم الفاتورة المبدئية',
    'proforma_invoice_date': 'تاريخ الفاتورة المبدئية',
    'invoice_date': 'تاريخ الفاتورة',
    'invoice_type': 'نوع الفاتورة',
    'po_number': 'رقم أمر الشراء (PO)',
    'po_date': 'تاريخ أمر الشراء',
    'pol_name': 'ميناء الشحن (POL)',
    'pod_name': 'ميناء الوصول (POD)',
    'customs_broker_name': 'اسم المخلص الجمركي',
    'customs_broker_phone': 'هاتف المخلص الجمركي',
    'requested_date': 'تاريخ الطلب',
    'acid_number': 'رقم الـ ACID (19 رقماً)',
    'generated_date': 'تاريخ إصدار الـ ACID',
    'expiry_date': 'تاريخ انتهاء الصلاحية',
    'items': 'بنود وعروض الشحن',
    'cargo_ready_date': 'تاريخ جاهزية البضاعة (CRD)',
    'title': 'مسمى الدراسة / الملف',
  };

  static ParsedErrorInfo parse(dynamic error, {String defaultMessage = 'حدث خطأ أثناء تنفيذ العملية'}) {
    final points = <String>[];
    String summary = defaultMessage;
    String rawLog = error.toString();

    if (error is DioException) {
      final res = error.response;
      if (res?.data != null) {
        final data = res!.data;
        if (data is Map) {
          final detail = data['detail'];
          if (detail is String) {
            summary = detail;
            points.add(detail);
          } else if (detail is List) {
            summary = 'يوجد أخطاء في التحقق من صحة البيانات المدخلة:';
            for (var item in detail) {
              if (item is Map) {
                final locList = (item['loc'] as List?)
                        ?.where((p) => p.toString() != 'body')
                        .map((p) => _fieldTranslations[p.toString()] ?? p.toString())
                        .toList() ??
                    [];
                final fieldPath = locList.join(' ➔ ');
                final msg = item['msg']?.toString() ?? 'قيمة غير صالحة';
                
                String localizedMsg = msg;
                if (msg.contains('Field required') || msg.contains('field required')) {
                  localizedMsg = 'هذا الحقل إلزامي ويجب تعبئته';
                } else if (msg.contains('valid date')) {
                  localizedMsg = 'صيغة التاريخ غير صالحة (يجب أن تكون YYYY-MM-DD)';
                } else if (msg.contains('at least')) {
                  localizedMsg = 'القيمة قصيرة جداً وغير مكتملة';
                }

                if (fieldPath.isNotEmpty) {
                  points.add('حقل [$fieldPath]: $localizedMsg');
                } else {
                  points.add(localizedMsg);
                }
              } else {
                points.add(item.toString());
              }
            }
          } else if (data['message'] != null) {
            summary = data['message'].toString();
            points.add(summary);
          }
        }
      } else if (error.type == DioExceptionType.connectionError ||
                 error.message?.contains('XMLHttpRequest') == true ||
                 error.message?.contains('connection error') == true) {
        summary = 'تعذر الاتصال بخادم الباك إند أو تم رفض الطلب من المتصفح (CORS / Network Error).';
        points.add('تأكد من تشغيل خادم الباك إند (FastAPI) على العنوان: http://127.0.0.1:8000');
        points.add('إذا كنت تستخدم متصفح الويب (Chrome)، يرجى التأكد من تطابق العنوان (localhost / 127.0.0.1).');
      } else if (error.type == DioExceptionType.connectionTimeout ||
                 error.type == DioExceptionType.receiveTimeout) {
        summary = 'انتهت مهلة الاتصال بالخادم.';
        points.add('الخادم استغرق وقتاً أطول من المعتاد للاستجابة. يرجى إعادة المحاولة.');
      } else {
        summary = error.message ?? defaultMessage;
        points.add(summary);
      }
    } else {
      points.add(error.toString());
    }

    if (points.isEmpty) {
      points.add(summary);
    }

    return ParsedErrorInfo(
      summary: summary,
      errorPoints: points,
      rawTechnicalLog: rawLog,
    );
  }
}

Future<void> showErrorDetailsDialog(
  BuildContext context, {
  required String title,
  required dynamic error,
  String? subtitle,
}) async {
  final parsed = ErrorFormatter.parse(error, defaultMessage: subtitle ?? 'يرجى مراجعة الأخطاء التالية وتصحيحها:');

  await showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          bool showTechnical = false;

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppTheme.crimson, width: 1.5),
            ),
            titlePadding: EdgeInsets.zero,
            title: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: AppTheme.crimson,
                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            content: SizedBox(
              width: 580,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppTheme.crimson, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              parsed.summary,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.charcoal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '📋 قائمة النقاط المطلوب معالجتها واستكمالها:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppTheme.charcoal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...parsed.errorPoints.map((pt) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(' 🔴 ', style: TextStyle(fontSize: 10)),
                            Expanded(
                              child: Text(
                                pt,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 14),
                    const Divider(),
                    // Technical log expander
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            setState(() => showTechnical = !showTechnical);
                          },
                          icon: Builder(builder: (context) {
                            final icon = showTechnical ? Icons.expand_less : Icons.expand_more;
                            return Icon(icon, size: 18, color: Colors.grey.shade700);
                          }),
                          label: Builder(builder: (context) {
                            final label = showTechnical
                                ? 'إخفاء السجل التقني'
                                : 'عرض السجل التقني المفصل (Technical Log)';
                            return Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700));
                          }),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 16),
                          tooltip: 'نسخ نص الخطأ بالكامل',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: parsed.rawTechnicalLog));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('📋 تم نسخ تفاصيل الخطأ إلى الحافظة!'),
                                backgroundColor: AppTheme.charcoal,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    if (showTechnical) ...[
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: SelectableText(
                          parsed.rawTechnicalLog,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Colors.greenAccent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cobalt,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.check),
                label: const Text('فهمت، سأقوم بمعالجة الأخطاء (Fix & Retry)'),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          );
        },
      );
    },
  );
}
