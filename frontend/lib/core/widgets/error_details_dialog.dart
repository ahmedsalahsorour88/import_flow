import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/api_constants.dart';
import '../theme/app_theme.dart';

class ValidationIssueItem {
  final String fieldName;
  final String issueDescription;
  final String? recommendation;
  final bool isBlocking;
  final VoidCallback? onFix;

  ValidationIssueItem({
    required this.fieldName,
    required this.issueDescription,
    this.recommendation,
    this.isBlocking = false,
    this.onFix,
  });
}

class ParsedErrorInfo {
  final String summary;
  final List<ValidationIssueItem> validationIssues;
  final List<String> errorPoints;
  final String rawTechnicalLog;
  final bool isConnectionError;

  ParsedErrorInfo({
    required this.summary,
    required this.validationIssues,
    required this.errorPoints,
    required this.rawTechnicalLog,
    this.isConnectionError = false,
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
    'customs_broker_id': 'المستخلص الجمركي المعني',
    'customs_broker_phone': 'هاتف المخلص الجمركي',
    'requested_date': 'تاريخ الطلب',
    'acid_number': 'رقم الـ ACID (19 رقماً)',
    'generated_date': 'تاريخ إصدار الـ ACID',
    'expiry_date': 'تاريخ انتهاء الصلاحية',
    'items': 'بنود وعروض الشحن',
    'cargo_ready_date': 'تاريخ جاهزية البضاعة (CRD)',
    'title': 'موضوع / عنوان الاستشارة الجمركية',
    'consultation_title': 'عنوان الاستشارة الجمركية',
    'amount': 'المبلغ أو القيمة المالية',
    'currency': 'العملة',
  };

  static ParsedErrorInfo parse(
    dynamic error, {
    String defaultMessage = 'حدث خطأ أثناء معالجة الطلب',
    List<ValidationIssueItem>? customIssues,
  }) {
    final points = <String>[];
    final issues = <ValidationIssueItem>[...(customIssues ?? [])];
    String summary = defaultMessage;
    String rawLog = error.toString();
    bool isConn = false;

    if (error is DioException) {
      final res = error.response;
      if (res?.data != null) {
        final data = res!.data;
        if (data is Map) {
          final detail = data['detail'];
          if (detail is String) {
            summary = detail;
            points.add(detail);
            issues.add(ValidationIssueItem(
              fieldName: 'استجابة الخادم',
              issueDescription: detail,
              recommendation: 'يرجى مراجعة وتصحيح البيانات وفقاً لإرشادات الخادم.',
              isBlocking: true,
            ));
          } else if (detail is List) {
            summary = 'يوجد أخطاء في التحقق من صحة البيانات المدخلة (Validation Errors):';
            for (var item in detail) {
              if (item is Map) {
                final locList = (item['loc'] as List?)
                        ?.where((p) => p.toString() != 'body')
                        .map((p) => _fieldTranslations[p.toString()] ?? p.toString())
                        .toList() ??
                    [];
                final rawField = (item['loc'] as List?)?.last?.toString() ?? 'حقل غير محدد';
                final fieldPath = locList.join(' ➔ ');
                final msg = item['msg']?.toString() ?? 'قيمة غير صالحة';

                String localizedMsg = msg;
                String rec = 'يرجى إدخال قيمة صحيحة ومطابقة للشروط.';
                if (msg.contains('Field required') || msg.contains('field required')) {
                  localizedMsg = 'هذا الحقل إلزامي ولا يمكن تركه فارغاً.';
                  rec = 'قم بتعبئة هذا الحقل قبل حفظ البيانات.';
                } else if (msg.contains('valid date')) {
                  localizedMsg = 'صيغة التاريخ غير صالحة.';
                  rec = 'تأكد من صيغة التاريخ بالتنسيق: YYYY-MM-DD.';
                } else if (msg.contains('at least')) {
                  localizedMsg = 'القيمة المدخلة قصيرة جداً.';
                  rec = 'أدخل نصاً واضحاً ومكتملاً.';
                }

                final displayField = fieldPath.isNotEmpty ? fieldPath : (_fieldTranslations[rawField] ?? rawField);
                points.add('[$displayField]: $localizedMsg');
                issues.add(ValidationIssueItem(
                  fieldName: displayField,
                  issueDescription: localizedMsg,
                  recommendation: rec,
                  isBlocking: true,
                ));
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
          error.message?.contains('connection error') == true ||
          error.message?.contains('Failed to fetch') == true) {
        isConn = true;
        final targetUri = error.requestOptions.uri.toString().isNotEmpty 
            ? error.requestOptions.uri.toString() 
            : ApiConstants.baseUrl;
        summary = 'تعذر الاتصال بالخادم الخلفي (Backend API Connection Error / CORS)';
        points.add('خادم الباك إند (FastAPI) غير متاح حالياً أو متوقف.');
        points.add('العنوان المستهدف: $targetUri');
        points.add('إذا كنت تعمل على متصفح الويب، تأكد من تشغيل السيرفر ومن عدم حظر طلبات CORS.');

        issues.add(ValidationIssueItem(
          fieldName: 'اتصال الخادم (Backend Server)',
          issueDescription: 'تعذر الوصول إلى $targetUri (${error.message ?? 'XMLHttpRequest onError'}).',
          recommendation: 'تأكد من تشغيل خادم FastAPI عبر الأمر: python run_server.py أو uvicorn main:app --reload وعمل تحديث للصفحة (F5).',
          isBlocking: true,
        ));
      } else if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        isConn = true;
        summary = 'انتهت مهلة استجابة الخادم (Connection Timeout).';
        points.add('استغرق الخادم وقتاً أطول من المعتاد. يرجى إعادة المحاولة.');
        issues.add(ValidationIssueItem(
          fieldName: 'مهلة الاتصال',
          issueDescription: 'انتهت المهلة المحددة للطلب دون تلقي رد من الخادم.',
          recommendation: 'تحقق من سرعة الاتصال بالشبكة وأعد المحاولة.',
          isBlocking: true,
        ));
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
      validationIssues: issues,
      errorPoints: points,
      rawTechnicalLog: rawLog,
      isConnectionError: isConn,
    );
  }
}

Future<void> showErrorDetailsDialog(
  BuildContext context, {
  required String title,
  required dynamic error,
  String? subtitle,
  List<ValidationIssueItem>? validationIssues,
  Future<void> Function()? onRetry,
  VoidCallback? onFixAction,
}) async {
  final parsed = ErrorFormatter.parse(
    error,
    defaultMessage: subtitle ?? 'يرجى مراجعة الأخطاء وتصحيحها لتتمكن من استكمال العملية بنجاح:',
    customIssues: validationIssues,
  );

  bool showTechnical = false;
  bool isRetrying = false;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
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
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
            content: SizedBox(
              width: 680,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: parsed.isConnectionError ? Colors.orange.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: parsed.isConnectionError ? Colors.orange.shade300 : Colors.red.shade200,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            parsed.isConnectionError ? Icons.wifi_off_rounded : Icons.warning_amber_rounded,
                            color: parsed.isConnectionError ? Colors.orange.shade900 : AppTheme.crimson,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  parsed.summary,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: parsed.isConnectionError ? Colors.orange.shade900 : AppTheme.charcoal,
                                    fontSize: 13.5,
                                  ),
                                ),
                                if (parsed.isConnectionError) ...[
                                  const SizedBox(height: 6),
                                  const Text(
                                    '💡 الخادم الخلفي (FastAPI) غير متاح حالياً. يرجى التأكد من تشغيل السيرفر المحلي وإعادة المحاولة.',
                                    style: TextStyle(fontSize: 11.5, color: Colors.black87),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (parsed.validationIssues.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.playlist_remove, color: AppTheme.crimson, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '📋 جدول الأخطاء وعوائق الاستكمال المطلوب تصحيحها (${parsed.validationIssues.length}):',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                              color: AppTheme.charcoal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Table(
                          columnWidths: const {
                            0: FlexColumnWidth(1.4),
                            1: FlexColumnWidth(2.0),
                            2: FlexColumnWidth(2.2),
                          },
                          border: TableBorder(
                            horizontalInside: BorderSide(color: Colors.grey.shade200),
                          ),
                          children: [
                            TableRow(
                              decoration: BoxDecoration(color: Colors.grey.shade100),
                              children: const [
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  child: Text('الحقل / الشرط', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  child: Text('وصف الخطأ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  child: Text('الإجراء المقترح للتصحيح', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ],
                            ),
                            ...parsed.validationIssues.map((issue) {
                              return TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    child: Row(
                                      children: [
                                        Icon(
                                          issue.isBlocking ? Icons.cancel : Icons.error_outline,
                                          size: 14,
                                          color: issue.isBlocking ? AppTheme.crimson : Colors.orange.shade800,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            issue.fieldName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    child: Text(
                                      issue.issueDescription,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: issue.isBlocking ? AppTheme.crimson : AppTheme.charcoal,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    child: Text(
                                      issue.recommendation ?? '—',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              setState(() => showTechnical = !showTechnical);
                            },
                            icon: Icon(
                              showTechnical ? Icons.expand_less : Icons.expand_more,
                              size: 18,
                              color: Colors.grey.shade700,
                            ),
                            label: Text(
                              showTechnical
                                  ? 'إخفاء السجل التقني المفصل'
                                  : 'عرض السجل التقني المفصل للمطورين (Diagnostic Log)',
                              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                            ),
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            icon: const Icon(Icons.copy, size: 14, color: AppTheme.cobalt),
                            label: const Text('نسخ تقرير الفحص', style: TextStyle(fontSize: 11, color: AppTheme.cobalt)),
                            onPressed: () {
                              final report = '''
=== تقرير فحص ومعالجة أخطاء Sorour Logistics ERP ===
التاريخ والوقت: ${DateTime.now().toIso8601String()}
العنوان: $title
الملخص: ${parsed.summary}
نوع الخطأ: ${parsed.isConnectionError ? 'Connection / CORS Error' : 'Validation / Server Error'}
------------------------------------------------
الأخطاء والنواقص (${parsed.validationIssues.length}):
${parsed.validationIssues.map((i) => '- [${i.fieldName}]: ${i.issueDescription} -> ${i.recommendation}').join('\n')}
------------------------------------------------
السجل التقني الكامل:
${parsed.rawTechnicalLog}
================================================
''';
                              Clipboard.setData(ClipboardData(text: report));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('📋 تم نسخ تقرير الفحص التشخيصي إلى الحافظة!'),
                                  backgroundColor: AppTheme.charcoal,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
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
            actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            actions: [
              if (onRetry != null)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: isRetrying
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.refresh, size: 18),
                  label: Text(isRetrying ? 'جارٍ إعادة المحاولة...' : 'إعادة المحاولة الآن (Retry)'),
                  onPressed: isRetrying
                      ? null
                      : () async {
                          setState(() => isRetrying = true);
                          try {
                            await onRetry();
                            if (context.mounted) Navigator.of(ctx).pop();
                          } catch (retryErr) {
                            if (context.mounted) {
                              setState(() => isRetrying = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('❌ فشلت إعادة المحاولة: $retryErr'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                ),
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
