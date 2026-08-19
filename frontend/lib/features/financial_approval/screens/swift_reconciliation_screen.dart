import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../models/financial_approval_model.dart';
import '../providers/financial_approval_provider.dart';
import '../../import_files/providers/import_files_provider.dart';

import 'package:flutter/services.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';

const String kSampleSwiftMT103 = '''{1:F01ARAIECXXXXX.SN...ISN.}{2:I103CITIUS33XXXXN}{3:{108:xxxxx}}{4:
:20/TRANSACTION REFERENCE NUMBER       : FT/26228/KZ70Q
:23B/BANK OPERATION CODE              : CRED
:32A/Value Date, CCY, Amount          : 260818USD43704,00
:50K/ORDERING CUST                     : /EG780057004001017153610010101
                                        SCAS FOR CONSTRUCTION AND FINISHING
                                        ROAD 18
                                        EGYPT,44 ROAD 18
                                        SARIAT EL MAADI,CAIRO
:57A/Account with Bank                : PCBCCNBJJSS
:59/Beneficiary Customer              : /32250198613609841015
                                        SUZHOU YUHENG TEXTILE CO., LTD
                                        16 KANGSHENG ROAD ZHITANG TOWN
                                        CHANGSHU CITY SUZHOU CHINA
:70/DETAILS OF PAYMENT                : EG0010040 PI NO.YH20260730.6
                                        ALL DOCUMENTS SHOULD BE TRADED
                                        THROUGH AAIB
:71A/DETAILS OF CHARGES               : SHA
-}''';

class SwiftReconciliationScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;
  const SwiftReconciliationScreen({super.key, this.isEmbedded = false});

  @override
  ConsumerState<SwiftReconciliationScreen> createState() => _SwiftReconciliationScreenState();
}

class _SwiftReconciliationScreenState extends ConsumerState<SwiftReconciliationScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _rawSwiftTextController = TextEditingController();

  String _selectedStatusFilter = 'ALL'; // ALL, PENDING, MATCHED, DEFICIT, SURPLUS
  bool _isProcessing = false;
  bool _isExtracting = false;
  bool _isSmartReconciling = false;
  bool _isSmartSectionExpanded = true;

  Map<String, dynamic>? _extractedSwift;
  Map<String, dynamic>? _matchedPayment;
  List<dynamic> _candidateMatches = [];
  int? _selectedPaymentIdForReconcile;
  String? _uploadedFileName;
  String? _detectedFileType;
  int? _uploadedFileSize;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(paymentRequestsProvider.notifier).fetchPaymentRequests();
      ref.read(importFilesProvider.notifier).fetchImportFiles();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _rawSwiftTextController.dispose();
    super.dispose();
  }

  Future<void> _pickAndExtractFile({int? targetPaymentId}) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'doc', 'xlsx', 'xls', 'csv', 'jpg', 'jpeg', 'png', 'webp', 'bmp', 'txt'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final fileBytes = file.bytes;
      final filename = file.name;

      if (fileBytes == null || fileBytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('⚠️ تعذر قراءة بيانات الملف المحدد'), backgroundColor: AppTheme.orange),
          );
        }
        return;
      }

      setState(() {
        _isExtracting = true;
        _uploadedFileName = filename;
        _uploadedFileSize = fileBytes.length;
      });

      final res = await ref.read(paymentRequestsProvider.notifier).smartExtractSwiftFromFile(
        fileBytes: fileBytes,
        filename: filename,
        targetPaymentId: targetPaymentId,
      );

      if (mounted) {
        if (res['success'] == true) {
          setState(() {
            _extractedSwift = res['parsed_swift'] as Map<String, dynamic>?;
            _matchedPayment = res['matched_payment_request'] as Map<String, dynamic>?;
            _candidateMatches = (res['candidate_matches'] as List<dynamic>?) ?? [];
            _detectedFileType = res['detected_file_type'] as String?;
            if (res['raw_text'] != null && (res['raw_text'] as String).isNotEmpty) {
              _rawSwiftTextController.text = res['raw_text'] as String;
            }
            if (_matchedPayment != null && _matchedPayment!['payment_id'] != null) {
              _selectedPaymentIdForReconcile = _matchedPayment!['payment_id'] as int;
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📄 تم استخراج بيانات السويفت بنجاح من ملف "$filename" (${_detectedFileType ?? "مستند"}) ⚡'),
              backgroundColor: AppTheme.emerald,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ تعذر استخراج السويفت من الملف: ${res['error']}'), backgroundColor: AppTheme.crimson),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ خطأ أثناء استخراج الملف: $e'), backgroundColor: AppTheme.crimson),
        );
      }
    } finally {
      if (mounted) setState(() => _isExtracting = false);
    }
  }

  Future<void> _runSmartSwiftExtraction({int? targetPaymentId}) async {
    final text = _rawSwiftTextController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ يرجى لصق أو إدخال نص رسالة السويفت أو إشعار البنك أولاً'), backgroundColor: AppTheme.orange),
      );
      return;
    }

    setState(() => _isExtracting = true);
    try {
      final res = await ref.read(paymentRequestsProvider.notifier).smartExtractSwift(
        rawText: text,
        targetPaymentId: targetPaymentId,
      );

      if (mounted) {
        if (res['success'] == true) {
          setState(() {
            _extractedSwift = res['parsed_swift'] as Map<String, dynamic>?;
            _matchedPayment = res['matched_payment_request'] as Map<String, dynamic>?;
            _candidateMatches = (res['candidate_matches'] as List<dynamic>?) ?? [];
            if (_matchedPayment != null && _matchedPayment!['payment_id'] != null) {
              _selectedPaymentIdForReconcile = _matchedPayment!['payment_id'] as int;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚡ تم استخراج بيانات السويفت وتحديد طلب السداد المطابق بنجاح'),
              backgroundColor: AppTheme.emerald,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ تعذر تحليل السويفت: ${res['error']}'), backgroundColor: AppTheme.crimson),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ خطأ في الاتصال: $e'), backgroundColor: AppTheme.crimson),
        );
      }
    } finally {
      if (mounted) setState(() => _isExtracting = false);
    }
  }

  Future<void> _executeSmartReconciliation(PaymentRequestModel pay) async {
    if (_extractedSwift == null) return;

    final swiftRef = _extractedSwift!['transaction_reference'] ?? 'SWIFT-${DateTime.now().millisecondsSinceEpoch}';
    final rawDate = _extractedSwift!['value_date'] ?? DateTime.now().toString().substring(0, 10);
    final amt = (_extractedSwift!['amount'] as num?)?.toDouble() ?? pay.requestedAmount;
    final curr = _extractedSwift!['currency'] ?? pay.currencyCode;
    final swiftCode = _extractedSwift!['beneficiary_bank_swift'] ?? pay.swiftCode;
    final iban = _extractedSwift!['beneficiary_account_or_iban'] ?? pay.ibanAccountNo;

    setState(() => _isSmartReconciling = true);
    try {
      final updated = await ref.read(paymentRequestsProvider.notifier).smartReconcileSwift(
        paymentId: pay.paymentId,
        rawText: _rawSwiftTextController.text.trim(),
        swiftReferenceNo: swiftRef,
        swiftReceiptDate: rawDate.toString().substring(0, 10),
        swiftTransferredAmount: amt,
        swiftTransferredCurrency: curr,
        swiftCode: swiftCode,
        ibanAccountNo: iban,
        swiftReconciliationNotes: 'تمت المطابقة والتأكيد الذكي بواسطة محرك استخراج السويفت (Smart AI SWIFT Reconciliation)',
        autoExecute: true,
      );

      ref.read(importFilesProvider.notifier).fetchImportFiles();

      if (mounted && updated != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 تم تأكيد مطابقة السويفت ($swiftRef) واعتماد سداد الطلب (${updated.paymentCode}) وتحديث ملف الاستيراد بنجاح!'),
            backgroundColor: AppTheme.emerald,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ خطأ أثناء تأكيد المطابقة: $e'), backgroundColor: AppTheme.crimson),
        );
      }
    } finally {
      if (mounted) setState(() => _isSmartReconciling = false);
    }
  }

  void _showSwiftReconciliationDialog(PaymentRequestModel pay) {
    final formKey = GlobalKey<FormState>();
    final swiftRefController = TextEditingController(text: pay.swiftReferenceNo ?? '');
    final transferredAmountController = TextEditingController(
      text: pay.swiftTransferredAmount != null
          ? pay.swiftTransferredAmount!.toStringAsFixed(2)
          : pay.requestedAmount.toStringAsFixed(2),
    );
    final currencyController = TextEditingController(
      text: pay.swiftTransferredCurrency ?? pay.currencyCode,
    );
    final notesController = TextEditingController(text: pay.swiftReconciliationNotes ?? '');

    DateTime receiptDate;
    if (pay.swiftReceiptDate != null && pay.swiftReceiptDate!.isNotEmpty) {
      receiptDate = DateTime.tryParse(pay.swiftReceiptDate!) ?? DateTime.now();
    } else {
      receiptDate = DateTime.now();
    }

    DateTime requestDate;
    if (pay.requestDate.isNotEmpty) {
      requestDate = DateTime.tryParse(pay.requestDate) ?? DateTime.now();
    } else {
      requestDate = DateTime.now();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final transferredAmt = double.tryParse(transferredAmountController.text.trim()) ?? 0.0;
            final variance = transferredAmt - pay.requestedAmount;
            final processingDays = receiptDate.difference(requestDate).inDays;
            final safeDays = processingDays < 0 ? 0 : processingDays;

            Color varianceColor;
            IconData varianceIcon;
            String varianceText;

            if (transferredAmt <= 0) {
              varianceColor = Colors.grey;
              varianceIcon = Icons.hourglass_empty;
              varianceText = 'بانتظار إدخال المبلغ';
            } else if (variance.abs() < 0.001) {
              varianceColor = AppTheme.emerald;
              varianceIcon = Icons.check_circle;
              varianceText = 'مطابق تماماً (100% Matched - بدون فروقات)';
            } else if (variance < 0) {
              varianceColor = AppTheme.crimson;
              varianceIcon = Icons.arrow_downward;
              varianceText = 'عجز / نقص في قيمة السويفت بمقدار ${variance.abs().toStringAsFixed(2)} ${pay.currencyCode}';
            } else {
              varianceColor = AppTheme.orange;
              varianceIcon = Icons.arrow_upward;
              varianceText = 'زيادة في قيمة السويفت بمقدار ${variance.toStringAsFixed(2)} ${pay.currencyCode}';
            }

            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.account_balance, color: AppTheme.cobalt),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'تسجيل ومطابقة السويفت البنكي: ${pay.paymentCode}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 680,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary of Payment Request
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('عنوان الطلب: ${pay.title}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  if (pay.importFileCode != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: AppTheme.cobalt, borderRadius: BorderRadius.circular(4)),
                                      child: Text(pay.importFileCode!, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(child: Text('المورد المستفيد: ${pay.beneficiaryName ?? pay.supplierName}', style: const TextStyle(fontSize: 12))),
                                  Expanded(child: Text('البنك: ${pay.bankName ?? "-"} (${pay.swiftCode ?? "-"})', style: const TextStyle(fontSize: 12))),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(child: Text('تاريخ تقديم الطلب: ${pay.requestDate.isNotEmpty ? pay.requestDate : "-"}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.charcoal))),
                                  Expanded(child: Text('المبلغ المطلوب: ${pay.requestedAmount.toStringAsFixed(2)} ${pay.currencyCode}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Quick Smart AI Extract Button inside Dialog
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.purple.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome, color: Colors.purple, size: 18),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text('استخراج ذكي وتعبئة تلقائية من نص السويفت (MT103):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple)),
                              ),
                              TextButton.icon(
                                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                icon: const Icon(Icons.description, size: 14),
                                label: const Text('نموذج تجريبي', style: TextStyle(fontSize: 11)),
                                onPressed: () async {
                                  final res = await ref.read(paymentRequestsProvider.notifier).smartExtractSwift(
                                    rawText: kSampleSwiftMT103,
                                    targetPaymentId: pay.paymentId,
                                  );
                                  if (res['success'] == true && res['parsed_swift'] != null) {
                                    final p = res['parsed_swift'] as Map<String, dynamic>;
                                    setDialogState(() {
                                      if (p['transaction_reference'] != null) swiftRefController.text = p['transaction_reference'];
                                      if (p['amount'] != null) transferredAmountController.text = p['amount'].toString();
                                      if (p['currency'] != null) currencyController.text = p['currency'];
                                      if (p['value_date'] != null) {
                                        receiptDate = DateTime.tryParse(p['value_date']) ?? receiptDate;
                                      }
                                    });
                                  }
                                },
                              ),
                              const SizedBox(width: 4),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple.shade700,
                                  visualDensity: VisualDensity.compact,
                                ),
                                icon: const Icon(Icons.paste, color: Colors.white, size: 14),
                                label: const Text('لصق واستخراج ⚡', style: TextStyle(color: Colors.white, fontSize: 11)),
                                onPressed: () async {
                                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                                  if (data != null && data.text != null && data.text!.isNotEmpty) {
                                    final res = await ref.read(paymentRequestsProvider.notifier).smartExtractSwift(
                                      rawText: data.text!,
                                      targetPaymentId: pay.paymentId,
                                    );
                                    if (res['success'] == true && res['parsed_swift'] != null) {
                                      final p = res['parsed_swift'] as Map<String, dynamic>;
                                      setDialogState(() {
                                        if (p['transaction_reference'] != null) swiftRefController.text = p['transaction_reference'];
                                        if (p['amount'] != null) transferredAmountController.text = p['amount'].toString();
                                        if (p['currency'] != null) currencyController.text = p['currency'];
                                        if (p['value_date'] != null) {
                                          receiptDate = DateTime.tryParse(p['value_date']) ?? receiptDate;
                                        }
                                      });
                                    }
                                  }
                                },
                              ),
                              const SizedBox(width: 4),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.cobalt,
                                  visualDensity: VisualDensity.compact,
                                ),
                                icon: const Icon(Icons.upload_file, color: Colors.white, size: 14),
                                label: const Text('رفع مستند 📁', style: TextStyle(color: Colors.white, fontSize: 11)),
                                onPressed: () async {
                                  final result = await FilePicker.pickFiles(
                                    type: FileType.custom,
                                    allowedExtensions: ['pdf', 'docx', 'doc', 'xlsx', 'xls', 'csv', 'jpg', 'jpeg', 'png', 'webp', 'bmp', 'txt'],
                                    withData: true,
                                  );
                                  if (result != null && result.files.isNotEmpty) {
                                    final f = result.files.first;
                                    if (f.bytes != null) {
                                      final res = await ref.read(paymentRequestsProvider.notifier).smartExtractSwiftFromFile(
                                        fileBytes: f.bytes!,
                                        filename: f.name,
                                        targetPaymentId: pay.paymentId,
                                      );
                                      if (res['success'] == true && res['parsed_swift'] != null) {
                                        final p = res['parsed_swift'] as Map<String, dynamic>;
                                        setDialogState(() {
                                          if (p['transaction_reference'] != null) swiftRefController.text = p['transaction_reference'];
                                          if (p['amount'] != null) transferredAmountController.text = p['amount'].toString();
                                          if (p['currency'] != null) currencyController.text = p['currency'];
                                          if (p['value_date'] != null) {
                                            receiptDate = DateTime.tryParse(p['value_date']) ?? receiptDate;
                                          }
                                        });
                                      }
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Input Fields
                        Row(
                          children: [
                            // SWIFT Receipt Date
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: receiptDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setDialogState(() => receiptDate = picked);
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'تاريخ استلام السويفت من البنك *',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.calendar_today, color: AppTheme.cobalt),
                                  ),
                                  child: Text(receiptDate.toString().substring(0, 10), style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // SWIFT Reference No
                            Expanded(
                              child: TextFormField(
                                controller: swiftRefController,
                                decoration: const InputDecoration(
                                  labelText: 'رقم السويفت البنكي (SWIFT / MT103 Ref) *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.tag, color: AppTheme.cobalt),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال رقم السويفت' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            // Transferred Amount
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: transferredAmountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'القيمة المصدرة من السويفت *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.attach_money, color: AppTheme.emerald),
                                ),
                                onChanged: (v) => setDialogState(() {}),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'يرجى إدخال المبلغ';
                                  final num = double.tryParse(v.trim());
                                  if (num == null || num <= 0) return 'المبلغ يجب أن يكون أكبر من 0';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Currency
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: currencyController,
                                decoration: const InputDecoration(
                                  labelText: 'العملة *',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Reconciliation Live Comparison Box
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: varianceColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: varianceColor.withOpacity(0.4), width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(varianceIcon, color: varianceColor, size: 20),
                                  const SizedBox(width: 8),
                                  Text('نتيجة المقارنة والمطابقة الفورية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: varianceColor)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('مدة التنفيذ: $safeDays يوم ما بين تاريخ الطلب وتاريخ السويفت', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: safeDays <= 3 ? Colors.green.shade100 : (safeDays <= 7 ? Colors.orange.shade100 : Colors.red.shade100),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      safeDays <= 3 ? '⚡ تنفيذ فوري ($safeDays أيام)' : (safeDays <= 7 ? '⏱️ مدة معقولة ($safeDays أيام)' : '⚠️ تأخير ($safeDays أيام)'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: safeDays <= 3 ? Colors.green.shade800 : (safeDays <= 7 ? Colors.orange.shade900 : Colors.red.shade900),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('المبلغ المطلوب: ${pay.requestedAmount.toStringAsFixed(2)} ${pay.currencyCode}', style: const TextStyle(fontSize: 12)),
                                  Text('المبلغ المنفذ: ${transferredAmt.toStringAsFixed(2)} ${pay.currencyCode}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: varianceColor)),
                                ],
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(varianceText, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: varianceColor)),
                                  if (variance != 0)
                                    Text(
                                      'الفارق: ${variance >= 0 ? "+" : ""}${variance.toStringAsFixed(2)} ${pay.currencyCode}',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: varianceColor, fontSize: 13),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Auto-Sync Info Banner
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.bolt, color: Colors.orange, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '⚡ سيتم تلقائياً تحديث رقم السويفت (swift no) في ملف الاستيراد المربوط بمجرد الحفظ والاعتماد.',
                                  style: TextStyle(fontSize: 11, color: Colors.brown, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Notes Field
                        TextFormField(
                          controller: notesController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'ملاحظات المطابقة والفروقات البنكية (إن وجدت)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald),
                  icon: const Icon(Icons.check, color: Colors.white, size: 18),
                  label: const Text('حفظ واعتماد السويفت وتحديث ملف الشحنة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(dialogCtx);

                    setState(() => _isProcessing = true);
                    try {
                      final updated = await ref.read(paymentRequestsProvider.notifier).reconcileSwift(
                        paymentId: pay.paymentId,
                        swiftReferenceNo: swiftRefController.text.trim(),
                        swiftReceiptDate: receiptDate.toString().substring(0, 10),
                        swiftTransferredAmount: transferredAmt,
                        swiftTransferredCurrency: currencyController.text.trim().isNotEmpty ? currencyController.text.trim() : 'USD',
                        swiftReconciliationNotes: notesController.text.trim(),
                      );

                      // Also refresh Import Files provider so swift_no is live immediately
                      ref.read(importFilesProvider.notifier).fetchImportFiles();

                      if (mounted && updated != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ تم مطابقة السويفت بنجاح (${updated.swiftReferenceNo}) وتحديث ملف الاستيراد آلياً ⚡'),
                            backgroundColor: AppTheme.emerald,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('❌ خطأ أثناء المطابقة: $e'), backgroundColor: AppTheme.crimson),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isProcessing = false);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSwiftDetailsDialog(PaymentRequestModel pay) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('تفاصيل السويفت البنكي: ${pay.paymentCode}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            _buildVarianceBadge(pay.swiftVarianceStatus, pay.swiftVarianceAmount, pay.currencyCode),
          ],
        ),
        content: SizedBox(
          width: 580,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pay.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal)),
                const SizedBox(height: 6),
                Text('المورد المستفيد: ${pay.beneficiaryName ?? pay.supplierName}'),
                Text('البنك: ${pay.bankName ?? "-"} | SWIFT: ${pay.swiftCode ?? "-"} | الحساب: ${pay.ibanAccountNo ?? "-"}'),
                const Divider(),
                Row(
                  children: [
                    _buildStatPill('تاريخ تقديم الطلب', pay.requestDate.isNotEmpty ? pay.requestDate : '-', AppTheme.charcoal),
                    const SizedBox(width: 8),
                    _buildStatPill('تاريخ استلام السويفت', pay.swiftReceiptDate ?? 'بانتظار السويفت', AppTheme.cobalt),
                    const SizedBox(width: 8),
                    _buildStatPill('مدة التنفيذ', pay.swiftProcessingDays != null ? '${pay.swiftProcessingDays} يوم' : '-', Colors.teal),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatPill('المبلغ المطلوب', '${pay.requestedAmount.toStringAsFixed(2)} ${pay.currencyCode}', AppTheme.cobalt),
                    const SizedBox(width: 8),
                    _buildStatPill('المبلغ المنفذ بالسويفت', pay.swiftTransferredAmount != null ? '${pay.swiftTransferredAmount!.toStringAsFixed(2)} ${pay.swiftTransferredCurrency ?? pay.currencyCode}' : '-', AppTheme.emerald),
                    const SizedBox(width: 8),
                    _buildStatPill('الفارق', pay.swiftVarianceAmount != null ? '${pay.swiftVarianceAmount!.toStringAsFixed(2)} ${pay.currencyCode}' : '-', Colors.orange),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.tag, color: AppTheme.cobalt, size: 18),
                          const SizedBox(width: 6),
                          const Text('رقم السويفت (SWIFT Reference No):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(width: 8),
                          Text(pay.swiftReferenceNo ?? 'غير مسجل', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt, fontSize: 14)),
                        ],
                      ),
                      if (pay.swiftReconciliationNotes != null && pay.swiftReconciliationNotes!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text('ملاحظات المطابقة: ${pay.swiftReconciliationNotes}'),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
            icon: const Icon(Icons.edit, color: Colors.white, size: 16),
            label: const Text('تعديل المطابقة', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.pop(ctx);
              _showSwiftReconciliationDialog(pay);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildVarianceBadge(String? status, double? variance, String currency) {
    if (status == 'Matched' || (variance != null && variance.abs() < 0.001)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(12)),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 14),
            SizedBox(width: 4),
            Text('مطابق تماماً', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
          ],
        ),
      );
    } else if (status == 'Deficit' || (variance != null && variance < 0)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_downward, color: Colors.red, size: 14),
            const SizedBox(width: 4),
            Text('عجز (${variance?.toStringAsFixed(2)} $currency)', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),
          ],
        ),
      );
    } else if (status == 'Surplus' || (variance != null && variance > 0)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_upward, color: Colors.orange, size: 14),
            const SizedBox(width: 4),
            Text('زيادة (+${variance?.toStringAsFixed(2)} $currency)', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11)),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
        child: const Text('بانتظار السويفت', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11)),
      );
    }
  }

  Widget _buildInfoField(String label, String value, Color color, {bool isBold = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchingMatrixBox(List<PaymentRequestModel> paymentsList) {
    PaymentRequestModel? matchedPay;
    if (_selectedPaymentIdForReconcile != null) {
      matchedPay = paymentsList.firstWhere(
        (p) => p.paymentId == _selectedPaymentIdForReconcile,
        orElse: () => paymentsList.first,
      );
    } else if (_matchedPayment != null && _matchedPayment!['payment_id'] != null) {
      matchedPay = paymentsList.firstWhere(
        (p) => p.paymentId == _matchedPayment!['payment_id'],
        orElse: () => paymentsList.first,
      );
    }

    if (matchedPay == null) {
      return const Center(child: Text('لا توجد طلبات سداد مسجلة للمطابقة'));
    }

    final score = _matchedPayment?['confidence_score'] ?? 100;
    final amtInfo = _matchedPayment?['amount_matching'] as Map<String, dynamic>?;
    final isAmtMatched = amtInfo?['is_matched'] ?? true;
    final variance = (amtInfo?['variance'] as num?)?.toDouble() ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.compare_arrows, color: AppTheme.emerald, size: 18),
                SizedBox(width: 6),
                Text('2. المطابقة مع طلب السداد المسجل في النظام', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: score >= 80 ? Colors.green.shade100 : (score >= 50 ? Colors.orange.shade100 : Colors.red.shade100),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: score >= 80 ? Colors.green : Colors.orange),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(score >= 80 ? Icons.check_circle : Icons.warning_amber, size: 13, color: score >= 80 ? Colors.green : Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    score >= 80 ? 'تطابق ممتاز ($score%)' : 'تطابق جزئي ($score%)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: score >= 80 ? Colors.green.shade800 : Colors.orange.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Dropdown to change or select Payment Request
        SearchableDropdownField<int>(
          labelText: 'طلب السداد المستهدف',
          items: paymentsList.where((p) => p.isActive).map((p) {
            return SearchableDropdownItem<int>(
              value: p.paymentId,
              label: '${p.paymentCode} - ${p.supplierName} (${p.requestedAmount.toStringAsFixed(2)} ${p.currencyCode}) [${p.status}]',
              icon: Icons.receipt_long,
            );
          }).toList(),
          value: matchedPay.paymentId,
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedPaymentIdForReconcile = val);
              _runSmartSwiftExtraction(targetPaymentId: val);
            }
          },
        ),
        const SizedBox(height: 10),

        // Checklist Comparison Table
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _buildCompareRow(
                'المبلغ والعملة:',
                'المطلوب: ${matchedPay.requestedAmount.toStringAsFixed(2)} ${matchedPay.currencyCode}',
                'السويفت: ${_extractedSwift!['amount']} ${_extractedSwift!['currency']}',
                isAmtMatched,
                variance == 0.0 ? 'مطابق 100%' : 'فارق: ${variance.toStringAsFixed(2)}',
              ),
              const Divider(height: 12),
              _buildCompareRow(
                'المورد المستفيد:',
                matchedPay.beneficiaryName ?? matchedPay.supplierName,
                _extractedSwift!['beneficiary_name'] ?? '-',
                true,
                'مطابق',
              ),
              const Divider(height: 12),
              _buildCompareRow(
                'كود السويفت البنكي:',
                matchedPay.swiftCode ?? '-',
                _extractedSwift!['beneficiary_bank_swift'] ?? '-',
                matchedPay.swiftCode == null || matchedPay.swiftCode == _extractedSwift!['beneficiary_bank_swift'],
                'مؤكد',
              ),
              const Divider(height: 12),
              _buildCompareRow(
                'رقم الحساب / IBAN:',
                matchedPay.ibanAccountNo ?? '-',
                _extractedSwift!['beneficiary_account_or_iban'] ?? '-',
                true,
                'مؤكد',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Action Button: Auto-Reconcile & Mark as Paid
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emerald,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: _isSmartReconciling
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.verified, color: Colors.white, size: 20),
            label: Text(
              'تأكيد المطابقة، اعتماد سداد ${matchedPay.paymentCode} وتحديث ملف الشحنة آلياً ⚡',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            onPressed: _isSmartReconciling ? null : () => _executeSmartReconciliation(matchedPay!),
          ),
        ),
      ],
    );
  }

  Widget _buildCompareRow(String label, String sysVal, String swiftVal, bool isMatch, String badgeText) {
    return Row(
      children: [
        SizedBox(width: 110, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        Expanded(
          child: Text(
            sysVal,
            style: const TextStyle(fontSize: 11, color: AppTheme.charcoal),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Icon(Icons.arrow_right_alt, color: Colors.grey, size: 16),
        Expanded(
          child: Text(
            swiftVal,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isMatch ? AppTheme.emerald : AppTheme.crimson),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isMatch ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: isMatch ? Colors.green.shade200 : Colors.red.shade200),
          ),
          child: Text(
            badgeText,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isMatch ? Colors.green.shade800 : Colors.red.shade800),
          ),
        ),
      ],
    );
  }

  Widget _buildSmartSwiftSection(List<PaymentRequestModel> paymentsList) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.cobalt.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cobalt.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar with gradient and toggles
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.charcoal, AppTheme.cobalt.withOpacity(0.9)],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.amber, size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    '⚡ محرك الاستخراج الذكي والمطابقة الفورية لبيانات السويفت (Smart AI SWIFT MT103 Extractor & Auto-Reconciler)',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.15),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.description, size: 16),
                  label: const Text('تحميل نموذج سويفت تجريبي 📄', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    _rawSwiftTextController.text = kSampleSwiftMT103;
                    _runSmartSwiftExtraction();
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: _isSmartSectionExpanded ? 'طي الأداة' : 'توسيع الأداة',
                  icon: Icon(
                    _isSmartSectionExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.white,
                  ),
                  onPressed: () => setState(() => _isSmartSectionExpanded = !_isSmartSectionExpanded),
                ),
              ],
            ),
          ),

          if (_isSmartSectionExpanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Uploaded File Info Banner (if any)
                  if (_uploadedFileName != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purple.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _uploadedFileName!.toLowerCase().endsWith('.pdf')
                                ? Icons.picture_as_pdf
                                : (_uploadedFileName!.toLowerCase().endsWith('.docx') || _uploadedFileName!.toLowerCase().endsWith('.doc')
                                    ? Icons.description
                                    : (_uploadedFileName!.toLowerCase().endsWith('.xlsx') || _uploadedFileName!.toLowerCase().endsWith('.xls') || _uploadedFileName!.toLowerCase().endsWith('.csv')
                                        ? Icons.table_chart
                                        : Icons.image)),
                            color: Colors.purple.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'المستند المستخرج: ',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.purple.shade900),
                                    ),
                                    Text(
                                      _uploadedFileName!,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.purple.shade800),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'النوع: ${_detectedFileType ?? "مستند"} ${_uploadedFileSize != null ? "• الحجم: ${(_uploadedFileSize! / 1024).toStringAsFixed(1)} KB" : ""}',
                                  style: TextStyle(fontSize: 11, color: Colors.purple.shade700),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.purple.shade800,
                              side: BorderSide(color: Colors.purple.shade300),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            icon: const Icon(Icons.refresh, size: 14),
                            label: const Text('تغيير الملف', style: TextStyle(fontSize: 11)),
                            onPressed: () => _pickAndExtractFile(),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16, color: Colors.purple),
                            tooltip: 'إزالة الملف',
                            onPressed: () {
                              setState(() {
                                _uploadedFileName = null;
                                _detectedFileType = null;
                                _uploadedFileSize = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                  // Text Area + Action Buttons
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _rawSwiftTextController,
                          maxLines: 5,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'الصق نص رسالة السويفت البنكي (MT103) أو ارفع ملف المستند (Word / Excel / PDF / صورة)...\nمثال: {1:F01ARAIECXXXXX...} :20/TRANSACTION REFERENCE NUMBER : FT/26228/KZ70Q\n:32A/Value Date, CCY, Amount : 260818USD43704,00\n:59/Beneficiary Customer : SUZHOU YUHENG TEXTILE CO., LTD',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.shade700,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: _isExtracting
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.upload_file, color: Colors.white, size: 18),
                            label: const Text(
                              '📁 رفع واستخراج من ملف\n(Word / Excel / PDF / صورة)',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                            onPressed: _isExtracting ? null : () => _pickAndExtractFile(),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.cobalt,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: _isExtracting
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.bolt, color: Colors.white, size: 18),
                            label: const Text(
                              'استخراج ومطابقة النص ⚡',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            onPressed: _isExtracting ? null : () => _runSmartSwiftExtraction(),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.paste, size: 14),
                                label: const Text('لصق', style: TextStyle(fontSize: 11)),
                                onPressed: () async {
                                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                                  if (data != null && data.text != null && data.text!.isNotEmpty) {
                                    _rawSwiftTextController.text = data.text!;
                                    _runSmartSwiftExtraction();
                                  }
                                },
                              ),
                              const SizedBox(width: 4),
                              TextButton.icon(
                                icon: const Icon(Icons.clear, size: 14, color: Colors.grey),
                                label: const Text('تفريغ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                onPressed: () {
                                  _rawSwiftTextController.clear();
                                  setState(() {
                                    _extractedSwift = null;
                                    _matchedPayment = null;
                                    _candidateMatches = [];
                                    _selectedPaymentIdForReconcile = null;
                                    _uploadedFileName = null;
                                    _detectedFileType = null;
                                    _uploadedFileSize = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Results View if Extracted
                  if (_extractedSwift != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Box: Extracted SWIFT Details
                        Expanded(
                          flex: 5,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.account_balance, color: AppTheme.cobalt, size: 18),
                                        SizedBox(width: 6),
                                        Text('1. بيانات السويفت المستخرجة (MT103)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal)),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: AppTheme.cobalt, borderRadius: BorderRadius.circular(4)),
                                      child: Text(
                                        'Ref: ${_extractedSwift!['transaction_reference'] ?? "غير محدد"}',
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    _buildInfoField('المبلغ المنفذ', '${_extractedSwift!['amount']} ${_extractedSwift!['currency']}', AppTheme.emerald, isBold: true),
                                    const SizedBox(width: 8),
                                    _buildInfoField('تاريخ التحويل', _extractedSwift!['value_date_formatted'] ?? _extractedSwift!['value_date'] ?? '-', AppTheme.charcoal),
                                    const SizedBox(width: 8),
                                    _buildInfoField('العمولات', _extractedSwift!['charge_details'] ?? 'SHA', Colors.teal),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('المورد المستفيد: ${_extractedSwift!['beneficiary_name'] ?? "-"}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(child: Text('كود السويفت: ${_extractedSwift!['beneficiary_bank_swift'] ?? "-"}', style: const TextStyle(fontSize: 11))),
                                    Expanded(child: Text('رقم الحساب / IBAN: ${_extractedSwift!['beneficiary_account_or_iban'] ?? "-"}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text('الآمر بالتحويل: ${_extractedSwift!['ordering_customer_name'] ?? "-"} (${_extractedSwift!['ordering_account_or_iban'] ?? "-"})', style: TextStyle(fontSize: 11, color: Colors.grey.shade800)),
                                if (_extractedSwift!['pi_number'] != null || _extractedSwift!['payment_details'] != null) ...[
                                  const SizedBox(height: 4),
                                  Text('الفاتورة / التفاصيل: ${_extractedSwift!['pi_number'] ?? _extractedSwift!['payment_details']}', style: const TextStyle(fontSize: 11, color: AppTheme.cobalt, fontWeight: FontWeight.w600)),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Right Box: Auto-Matching & Discrepancy Matrix
                        Expanded(
                          flex: 6,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade300),
                            ),
                            child: _buildMatchingMatrixBox(paymentsList),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentsState = ref.watch(paymentRequestsProvider);
    final paymentsList = paymentsState.value ?? [];

    // Filter payments
    final filtered = paymentsList.where((pay) {
      if (!pay.isActive) return false;
      final q = _searchController.text.trim().toLowerCase();
      final matchQuery = q.isEmpty ||
          pay.paymentCode.toLowerCase().contains(q) ||
          pay.title.toLowerCase().contains(q) ||
          pay.supplierName.toLowerCase().contains(q) ||
          (pay.importFileCode != null && pay.importFileCode!.toLowerCase().contains(q)) ||
          (pay.swiftReferenceNo != null && pay.swiftReferenceNo!.toLowerCase().contains(q));

      if (!matchQuery) return false;

      if (_selectedStatusFilter == 'PENDING') {
        return pay.swiftReferenceNo == null || pay.swiftReferenceNo!.isEmpty;
      } else if (_selectedStatusFilter == 'MATCHED') {
        return pay.swiftVarianceStatus == 'Matched';
      } else if (_selectedStatusFilter == 'DEFICIT') {
        return pay.swiftVarianceStatus == 'Deficit';
      } else if (_selectedStatusFilter == 'SURPLUS') {
        return pay.swiftVarianceStatus == 'Surplus';
      }
      return true;
    }).toList();

    // Calculate metrics
    final totalRequests = paymentsList.where((p) => p.isActive).length;
    final pendingSwift = paymentsList.where((p) => p.isActive && (p.swiftReferenceNo == null || p.swiftReferenceNo!.isEmpty)).length;
    final matchedSwift = paymentsList.where((p) => p.isActive && p.swiftVarianceStatus == 'Matched').length;
    final discrepancySwift = paymentsList.where((p) => p.isActive && (p.swiftVarianceStatus == 'Deficit' || p.swiftVarianceStatus == 'Surplus')).length;

    final reconciledItems = paymentsList.where((p) => p.isActive && p.swiftProcessingDays != null).toList();
    final avgDays = reconciledItems.isNotEmpty
        ? (reconciledItems.map((p) => p.swiftProcessingDays!).reduce((a, b) => a + b) / reconciledItems.length).toStringAsFixed(1)
        : '0.0';

    final content = _isProcessing
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KPI Metric Cards
                  Row(
                    children: [
                      _buildKPICard('إجمالي طلبات السداد', totalRequests.toString(), Icons.receipt_long, AppTheme.cobalt),
                      const SizedBox(width: 12),
                      _buildKPICard('بانتظار السويفت', pendingSwift.toString(), Icons.hourglass_top, Colors.orange),
                      const SizedBox(width: 12),
                      _buildKPICard('سويفت مطابق 100%', matchedSwift.toString(), Icons.check_circle_outline, AppTheme.emerald),
                      const SizedBox(width: 12),
                      _buildKPICard('فروقات (عجز / زيادة)', discrepancySwift.toString(), Icons.compare_arrows, AppTheme.crimson),
                      const SizedBox(width: 12),
                      _buildKPICard('متوسط مدة التنفيذ', '$avgDays يوم', Icons.speed, Colors.teal),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Smart AI SWIFT MT103 Extractor & Auto-Reconciler Tool
                  _buildSmartSwiftSection(paymentsList),
                  const SizedBox(height: 16),

                  // Filter & Search Toolbar
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'بحث بكود الطلب، ملف الشحنة، المورد، رقم السويفت...',
                              prefixIcon: Icon(Icons.search, color: AppTheme.cobalt),
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (v) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Filter Chips
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildFilterChip('الكل ($totalRequests)', 'ALL'),
                            _buildFilterChip('بانتظار السويفت ($pendingSwift)', 'PENDING'),
                            _buildFilterChip('مطابق ($matchedSwift)', 'MATCHED'),
                            _buildFilterChip('فروقات ($discrepancySwift)', 'DEFICIT'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Table of Payment Requests & SWIFTs
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.table_chart, color: AppTheme.charcoal, size: 20),
                                  const SizedBox(width: 8),
                                  Text('سجل طلبات السداد ومطابقة السويفت (${filtered.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                              const Row(
                                children: [
                                  Icon(Icons.bolt, color: Colors.orange, size: 16),
                                  SizedBox(width: 4),
                                  Text('التحديث التلقائي لملفات الشحنة مفعل ⚡', style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),

                        if (filtered.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(child: Text('لا توجد طلبات سداد تطابق معايير البحث الحالية.', style: TextStyle(color: Colors.grey))),
                          )
                        else
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                              columns: const [
                                DataColumn(label: Text('كود الطلب / الملف', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('المورد المستفيد والبنك', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('تاريخ تقديم الطلب', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('تاريخ استلام السويفت', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('مدة التنفيذ', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('المبلغ المطلوب', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('المبلغ المنفذ بالسويفت', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('حالة المطابقة والفارق', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('رقم السويفت (MT103)', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('⚡ العمليات', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: filtered.map((pay) {
                                final isReconciled = pay.swiftReferenceNo != null && pay.swiftReferenceNo!.isNotEmpty;
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(pay.paymentCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                                          if (pay.importFileCode != null)
                                            Text(pay.importFileCode!, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(pay.beneficiaryName ?? pay.supplierName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                          Text(pay.bankName ?? 'بنك غير محدد', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                        ],
                                      ),
                                    ),
                                    DataCell(Text(pay.requestDate.isNotEmpty ? pay.requestDate : '-')),
                                    DataCell(
                                      Text(
                                        pay.swiftReceiptDate ?? 'بانتظار السويفت',
                                        style: TextStyle(
                                          fontWeight: isReconciled ? FontWeight.bold : FontWeight.normal,
                                          color: isReconciled ? AppTheme.charcoal : Colors.grey,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      pay.swiftProcessingDays != null
                                          ? Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: pay.swiftProcessingDays! <= 3 ? Colors.green.shade50 : (pay.swiftProcessingDays! <= 7 ? Colors.orange.shade50 : Colors.red.shade50),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: pay.swiftProcessingDays! <= 3 ? Colors.green.shade300 : (pay.swiftProcessingDays! <= 7 ? Colors.orange.shade300 : Colors.red.shade300),
                                                ),
                                              ),
                                              child: Text(
                                                '⚡ ${pay.swiftProcessingDays} يوم',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: pay.swiftProcessingDays! <= 3 ? Colors.green.shade800 : (pay.swiftProcessingDays! <= 7 ? Colors.orange.shade900 : Colors.red.shade900),
                                                ),
                                              ),
                                            )
                                          : const Text('⏳ معلق', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                    ),
                                    DataCell(Text('${pay.requestedAmount.toStringAsFixed(2)} ${pay.currencyCode}', style: const TextStyle(fontWeight: FontWeight.w600))),
                                    DataCell(
                                      pay.swiftTransferredAmount != null
                                          ? Text(
                                              '${pay.swiftTransferredAmount!.toStringAsFixed(2)} ${pay.swiftTransferredCurrency ?? pay.currencyCode}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald),
                                            )
                                          : const Text('-', style: TextStyle(color: Colors.grey)),
                                    ),
                                    DataCell(_buildVarianceBadge(pay.swiftVarianceStatus, pay.swiftVarianceAmount, pay.currencyCode)),
                                    DataCell(
                                      pay.swiftReferenceNo != null && pay.swiftReferenceNo!.isNotEmpty
                                          ? Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.blue.shade200)),
                                              child: Text(pay.swiftReferenceNo!, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt, fontSize: 11)),
                                            )
                                          : const Text('غير مسجل', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isReconciled ? AppTheme.cobalt : AppTheme.emerald,
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            ),
                                            icon: Icon(isReconciled ? Icons.edit : Icons.account_balance, color: Colors.white, size: 14),
                                            label: Text(
                                              isReconciled ? 'تعديل السويفت' : 'تسجيل السويفت',
                                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                            onPressed: () => _showSwiftReconciliationDialog(pay),
                                          ),
                                          const SizedBox(width: 6),
                                          IconButton(
                                            icon: const Icon(Icons.visibility, color: AppTheme.charcoal, size: 18),
                                            tooltip: 'عرض التفاصيل',
                                            onPressed: () => _showSwiftDetailsDialog(pay),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );

    if (widget.isEmbedded) {
      return Container(
        color: Colors.grey.shade100,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppTheme.charcoal,
        title: const Row(
          children: [
            Icon(Icons.account_balance, color: AppTheme.cobalt),
            SizedBox(width: 10),
            Text('مركز مطابقة وتأكيد السويفت البنكي (Bank SWIFT Tracking & Reconciliation Engine)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث البيانات',
            onPressed: () {
              ref.read(paymentRequestsProvider.notifier).fetchPaymentRequests();
              ref.read(importFilesProvider.notifier).fetchImportFiles();
            },
          ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                  const SizedBox(height: 2),
                  Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedStatusFilter == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : AppTheme.charcoal)),
      selected: isSelected,
      selectedColor: AppTheme.cobalt,
      backgroundColor: Colors.grey.shade100,
      onSelected: (selected) {
        if (selected) setState(() => _selectedStatusFilter = value);
      },
    );
  }
}
