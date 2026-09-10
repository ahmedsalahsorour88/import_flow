import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/widgets/extraction_progress_dialog.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../models/customs_consultation_model.dart';
import '../providers/customs_consultation_provider.dart';

void showPriceListFormDialog(
  BuildContext context,
  WidgetRef ref, {
  BrokerPriceListModel? existingPriceList,
  required List<dynamic> brokersList,
  Map<String, dynamic>? initialExtractedData,
}) {
  final l = context.l10n;
  if (brokersList.isEmpty && existingPriceList == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.noBrokersRegistered), backgroundColor: Colors.orange),
    );
    return;
  }

  final isEditing = existingPriceList != null;
  int? selectedBroker = existingPriceList?.brokerId ?? (brokersList.isNotEmpty ? brokersList.first.providerId : null);
  final titleCtrl = TextEditingController(text: existingPriceList?.title ?? (initialExtractedData?['title'] ?? 'بيان أسعار التخليص والنقل لميناء الإسكندرية لعام 2026'));
  final portCtrl = TextEditingController(text: existingPriceList?.portName ?? (initialExtractedData?['port_name'] ?? 'ميناء الإسكندرية والدخيلة'));
  final notesCtrl = TextEditingController(text: existingPriceList?.notes ?? (initialExtractedData?['notes'] ?? ''));
  final dateCtrl = TextEditingController(text: existingPriceList?.effectiveFrom ?? (initialExtractedData?['effective_from'] ?? DateTime.now().toIso8601String().split('T').first));
  int version = existingPriceList?.version ?? 1;

  // Standard benchmark mapping
  final standardRatesMap = <String, double>{
    'أتعاب تخليص LCL': 1250.0,
    'واحد طن LCL مصاريف تخليص': 4750.0,
    'لكل طن زيادة LCL': 1000.0,
    'أتعاب تخليص حاوية 20 قدم': 2500.0,
    'مصاريف تخليص أول حاوية 20 قدم': 7500.0,
    'مصاريف تخليص كل حاوية 20 قدم زيادة': 1500.0,
    'أتعاب تخليص حاوية 40 قدم': 2500.0,
    'مصاريف تخليص أول حاوية 40 قدم': 7500.0,
    'مصاريف تخليص كل حاوية 40 قدم زيادة': 2000.0,
    'بريد - دمغات': 250.0,
    'عرض الواردات + اعتماد الإيباك': 3500.0,
    'عرض الواردات + اعتماد الإيلاك': 3000.0,
    'ACID رسوم استخراج وإصدار': 1000.0,
    'زراعة ومهمل وسيل': 1150.0,
    'أمن عام + مندوب الأمن العام + سحب العينات': 1500.0,
    'عرض أمن عام للقاهرة': 5000.0,
    'وثيقة تأمين': 500.0,
    '(X-Ray) عرض إكس راي': 250.0,
    'تطبيق الاتفاقيات التفضيلية': 1000.0,
    'الإفراج تحت التحفظ': 350.0,
    'غسيل جمركي': 250.0,
    'مطافئ': 1000.0,
    'دمغة وموازين': 1000.0,
    'مفرقعات': 1000.0,
    'إفراج نهائي': 500.0,
    'إشعاع': 1000.0,
    'عرض زراعة مشمول': 1500.0,
    'عرض مصلحة الكيمياء': 1500.0,
    'سحب إذن / تصوير / تعديل منافستو': 750.0,
    'مصاريف وزن قماش': 1500.0,
    'إنهاء إجراءات زيادة الوزن': 750.0,
    'سيارة 1 طن (دبابة) إسكندرية - قاهرة': 6150.0,
    'سيارة جامبو حتى 4 طن إسكندرية - قاهرة': 8200.0,
    'سيارة فرداني حتى 7 طن إسكندرية - قاهرة': 14150.0,
    'حاوية 20 قدم حتى 10 طن إسكندرية - قاهرة': 14800.0,
    'حاوية 20 قدم أكثر من 10 طن إسكندرية - قاهرة': 18400.0,
    'حاويتين 20*2 قدم إسكندرية - قاهرة': 23300.0,
    'حاوية 40 قدم إسكندرية - قاهرة': 18400.0,
    'بياتة شاحنة 20*2': 4200.0,
    'بياتة شاحنة 40*1': 3600.0,
    'بياتة شاحنة 20*1': 3000.0,
    'تعتيق ميناء أبوقير': 4250.0,
    'نقل الحاوية للوزن داخل الميناء': 3500.0,
    'كشف عمال وكلارك': 1250.0,
  };

  // Load items either from existing price list or from master expense catalog
  if (!ref.read(expenseCatalogProvider).isLoading && ref.read(expenseCatalogProvider).valueOrNull == null) {
    Future.microtask(() => ref.read(expenseCatalogProvider.notifier).fetchCatalog());
  }
  final catalog = ref.read(clearanceExpenseTypesProvider).valueOrNull ?? [];
  final List<Map<String, dynamic>> itemsState = [];

  String normalizeArabic(String s) {
    var str = s.toLowerCase().trim();
    str = str.replaceAll(RegExp(r'[أإآ]'), 'ا');
    str = str.replaceAll('ة', 'ه');
    str = str.replaceAll('ى', 'ي');
    str = str.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), ' ');
    return str.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  int calculateMatchScore(String name, String extName) {
    final n1 = normalizeArabic(name);
    final n2 = normalizeArabic(extName);
    if (n1 == n2) return 100;
    if (n1.isEmpty || n2.isEmpty) return 0;
    if (n1.contains(n2) || n2.contains(n1)) return 80;

    // LCL items
    if (n1.contains('lcl') && n2.contains('lcl')) {
      if ((n1.contains('فاتوره') && n2.contains('فاتوره')) || (n1.contains('اتعاب') && n2.contains('اتعاب'))) {
        return 95;
      }
      if (n1.contains('واحد طن') && n2.contains('واحد طن')) return 95;
      if ((n1.contains('زياده') || n1.contains('اضافي')) && (n2.contains('زياده') || n2.contains('اضافي'))) {
        return 95;
      }
    }

    // 20FT vs 40FT
    final has20_1 = n1.contains('20');
    final has20_2 = n2.contains('20');
    final has40_1 = n1.contains('40');
    final has40_2 = n2.contains('40');

    // Prevent 20ft matching 40ft
    if ((has20_1 && has40_2 && !has20_2) || (has40_1 && has20_2 && !has40_2)) {
      return 0;
    }

    // 20ft 2x20 dual
    final isDual_1 = n1.contains('20 2') || n1.contains('20*2') || n1.contains('حاويتين');
    final isDual_2 = n2.contains('20 2') || n2.contains('20*2') || n2.contains('حاويتين');
    if (isDual_1 && isDual_2) {
      if (n1.contains('بياته') && n2.contains('بياته')) return 95;
      if (n1.contains('نقل') && n2.contains('نقل')) return 95;
    }
    if (isDual_1 != isDual_2 && (isDual_1 || isDual_2)) {
      return 0; // Don't confuse dual 20ft with single 20ft
    }

    // 20ft single
    if (has20_1 && has20_2) {
      if (n1.contains('بياته') && n2.contains('بياته')) return 90;
      if (n1.contains('اول حاويه') && (n2.contains('اول حاويه') || n2.contains('1 حاويه'))) return 95;
      if (n1.contains('زياده') && n2.contains('زياده')) return 95;
      if ((n1.contains('فاتوره') && n2.contains('فاتوره')) || (n1.contains('اتعاب') && n2.contains('اتعاب'))) return 95;
      if (n2.contains('اكبر') || n1.contains('اكثر')) {
        if ((n2.contains('اكبر') || n2.contains('اكثر')) && (n1.contains('اكبر') || n1.contains('اكثر'))) return 95;
      } else if ((n2.contains('اقل') || n1.contains('حتي') || n1.contains('اقل')) && (!n2.contains('اكبر') && !n2.contains('اكثر'))) {
        return 95;
      }
    }

    // 40ft
    if (has40_1 && has40_2) {
      if (n1.contains('بياته') && n2.contains('بياته')) return 95;
      if (n1.contains('اول حاويه') && (n2.contains('اول حاويه') || n2.contains('1 حاويه'))) return 95;
      if (n1.contains('زياده') && n2.contains('زياده')) return 95;
      if ((n1.contains('فاتوره') && n2.contains('فاتوره')) || (n1.contains('اتعاب') && n2.contains('اتعاب'))) return 95;
      if (n1.contains('نقل') && n2.contains('نقل')) return 90;
    }

    // Inland transport trucks
    if (n1.contains('دبابه') && n2.contains('دبابه')) return 95;
    if (n1.contains('جامبو') && n2.contains('جامبو')) return 95;
    if (n1.contains('فرداني') && n2.contains('فرداني')) return 95;

    // Procedures & approvals
    if (n1.contains('acid') && n2.contains('acid')) return 95;
    if (n1.contains('بريد') && n2.contains('بريد')) return 95;
    if ((n1.contains('واردات') || n1.contains('ايلاك') || n1.contains('ايباك')) &&
        (n2.contains('واردات') || n2.contains('ايلاك') || n2.contains('ايباك'))) {
      return 90;
    }
    if (n1.contains('امن عام') && n2.contains('امن عام')) {
      if (n1.contains('قاهره') && n2.contains('قاهره')) return 95;
      if (!n1.contains('قاهره') && !n2.contains('قاهره')) return 90;
    }
    if (n1.contains('تامين') && n2.contains('تامين')) return 95;
    if (n1.contains('اكس راي') && n2.contains('اكس راي')) return 95;
    if (n1.contains('اتفاقيات') && n2.contains('اتفاقيات')) return 95;
    if (n1.contains('تحفظ') && n2.contains('تحفظ')) return 95;
    if (!n1.contains('غسيل') && !n2.contains('غسيل')) {
      if ((n1.contains('سيل') || n1.contains('ترصيص')) && (n2.contains('سيل') || n2.contains('ترصيص'))) return 95;
    }
    if (n1.contains('غسيل') && n2.contains('غسيل')) return 95;
    if (n1.contains('ابوقير') && n2.contains('ابوقير')) return 95;
    if (n1.contains('وزن') && n2.contains('وزن') && n1.contains('ميناء') && n2.contains('ميناء')) return 95;
    if ((n1.contains('سحب') || n1.contains('اذن')) && (n2.contains('سحب') || n2.contains('اذن'))) return 90;

    return 0;
  }

  void applyExtractedExpenses(Map<String, dynamic> extracted, {required bool isInitial}) {
    final expensesCatalog = (extracted['expenses_catalog'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
    final cFee = (extracted['clearance_fee'] as num?)?.toDouble();
    final inlandFee = (extracted['inland_transport_fee'] as num?)?.toDouble();
    final inspFee = (extracted['inspection_fee'] as num?)?.toDouble();
    final portFee = (extracted['port_expenses'] as num?)?.toDouble();
    final miscFee = (extracted['miscellaneous_fee'] as num?)?.toDouble();

    final matchedExtractedIndices = <int>{};

    for (var itm in itemsState) {
      final name = (itm['expense_name'] as String? ?? '').trim();
      double? foundPrice;
      double? minP;
      double? maxP;
      String? notes;

      // 1. Match against expenses_catalog from AI extractor with score >= 80
      int bestScore = 0;
      int bestExtIdx = -1;
      Map<String, dynamic>? bestExtItem;

      for (int i = 0; i < expensesCatalog.length; i++) {
        final extItem = expensesCatalog[i];
        final extName = ((extItem['item_name'] ?? extItem['expense_name']) as String? ?? '').trim();
        final extPrice = ((extItem['price'] ?? extItem['amount']) as num?)?.toDouble() ?? 0.0;
        if (extPrice > 0) {
          final score = calculateMatchScore(name, extName);
          if (score > bestScore) {
            bestScore = score;
            bestExtIdx = i;
            bestExtItem = extItem;
          }
        }
      }

      if (bestScore >= 80 && bestExtItem != null) {
        foundPrice = ((bestExtItem['price'] ?? bestExtItem['amount']) as num?)?.toDouble();
        minP = (bestExtItem['min_price'] as num?)?.toDouble();
        maxP = (bestExtItem['max_price'] as num?)?.toDouble();
        notes = bestExtItem['notes']?.toString();
        if (bestExtItem['code'] != null) {
          itm['code'] = bestExtItem['code'];
          itm['is_uncoded'] = bestExtItem['is_uncoded'] == true;
        }
        matchedExtractedIndices.add(bestExtIdx);
      }

      // 2. Match against high-level extracted fee buckets ONLY if not matched above
      if (foundPrice == null || foundPrice == 0.0) {
        // IMPORTANT: NEVER overwrite LCL with cFee (2500)!
        if (cFee != null && cFee > 0 && name.contains('تخليص') && (name.contains('40') || name.contains('20')) && !name.contains('LCL')) {
          foundPrice = cFee;
        } else if (inlandFee != null && inlandFee > 0 && (name.contains('نقل') || name.contains('شاحنة')) && name.contains('40')) {
          foundPrice = inlandFee;
        } else if (inlandFee != null && inlandFee > 0 && (name.contains('نقل') || name.contains('شاحنة')) && name.contains('20') && !name.contains('20*2')) {
          foundPrice = inlandFee * 0.8;
        } else if (inspFee != null && inspFee > 0 && (name.contains('فحص') || name.contains('واردات') || name.contains('إيباك'))) {
          foundPrice = inspFee;
        } else if (portFee != null && portFee > 0 && name.contains('أول حاوية')) {
          foundPrice = portFee;
        } else if (miscFee != null && miscFee > 0 && (name.contains('بريد') || name.contains('دمغات') || name.contains('نثريات'))) {
          foundPrice = miscFee;
        }
      }

      // 3. Fallback to standard benchmark rates map if still 0.0
      if ((foundPrice == null || foundPrice == 0.0) && isInitial) {
        for (var entry in standardRatesMap.entries) {
          if (calculateMatchScore(name, entry.key) >= 80) {
            foundPrice = entry.value;
            break;
          }
        }
      }

      if (foundPrice != null && foundPrice > 0) {
        itm['standard_price'] = foundPrice;
        if (minP != null) itm['min_price'] = minP;
        if (maxP != null) itm['max_price'] = maxP;
        if (notes != null && notes.isNotEmpty) itm['notes'] = notes;
      }
    }

    // 4. Any custom line items from expenses_catalog that were NOT matched to standard catalog:
    for (int i = expensesCatalog.length - 1; i >= 0; i--) {
      if (matchedExtractedIndices.contains(i)) continue;
      final extItem = expensesCatalog[i];
      final extName = ((extItem['item_name'] ?? extItem['expense_name']) as String? ?? '').trim();
      final extPrice = ((extItem['price'] ?? extItem['amount']) as num?)?.toDouble() ?? 0.0;
      if (extPrice > 0) {
        final alreadyInItems = itemsState.any((itm) {
          final existingName = (itm['expense_name'] as String? ?? '').trim();
          return calculateMatchScore(existingName, extName) >= 80;
        });
        if (!alreadyInItems) {
          itemsState.insert(0, {
            'expense_type_id': null,
            'code': extItem['code'],
            'is_uncoded': extItem['is_uncoded'] == true,
            'expense_name': extName,
            'category': extItem['category']?.toString() ?? 'Other Fees (مصاريف أخرى)',
            'unit_type': ((extItem['pricing_unit'] ?? extItem['unit_type'])?.toString()) ?? 'Per Shipment (لكل شحنة)',
            'standard_price': extPrice,
            'currency': extItem['currency']?.toString() ?? 'EGP',
            'min_price': (extItem['min_price'] as num?)?.toDouble(),
            'max_price': (extItem['max_price'] as num?)?.toDouble(),
            'notes': extItem['notes']?.toString() ?? 'مستخرج آلياً من مقايسة التخليص',
            'is_active': true,
          });
        }
      }
    }
  }

  if (isEditing) {
    for (final itm in existingPriceList.items) {
      itemsState.add({
        'item_id': itm.itemId,
        'expense_type_id': itm.expenseTypeId,
        'expense_name': itm.expenseName,
        'category': itm.category,
        'unit_type': itm.unitType,
        'standard_price': itm.standardPrice,
        'currency': itm.currency,
        'min_price': itm.minPrice,
        'max_price': itm.maxPrice,
        'notes': itm.notes ?? '',
        'is_active': itm.isActive,
      });
    }
  } else {
    for (final exp in catalog) {
      itemsState.add({
        'expense_type_id': exp.expenseId,
        'expense_name': exp.nameAr,
        'category': exp.category,
        'unit_type': exp.defaultUnit,
        'standard_price': 0.0,
        'currency': exp.defaultCurrency,
        'min_price': null,
        'max_price': null,
        'notes': '',
        'is_active': true,
      });
    }

    if (initialExtractedData != null) {
      applyExtractedExpenses(initialExtractedData, isInitial: true);
    } else {
      for (var itm in itemsState) {
        final name = itm['expense_name'] as String;
        for (var entry in standardRatesMap.entries) {
          if (name.contains(entry.key) || entry.key.contains(name)) {
            itm['standard_price'] = entry.value;
            break;
          }
        }
      }
    }
  }

  // Pre-fill broker from initialExtractedData if provided
  if (initialExtractedData != null && !isEditing) {
    final bName = (initialExtractedData['broker_name'] as String?)?.toLowerCase() ?? '';
    if (bName.isNotEmpty) {
      for (final b in brokersList) {
        final pName = (b.partnerName as String).toLowerCase();
        if (bName.contains(pName) || pName.contains(bName) || (bName.contains('acc') && pName.contains('acc')) || (bName.contains('اسكندرية') && pName.contains('اسكندرية')) || (bName.contains('أهرام') && pName.contains('أهرام')) || (bName.contains('اهرام') && pName.contains('اهرام'))) {
          selectedBroker = b.providerId;
          break;
        }
      }
    }
  }

  String itemSearchQuery = '';
  String selectedCategoryFilter = 'All';
  bool isSaving = false;
  int? activeRowIndex;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDlgState) {
        // AI Extractor Function
        Future<void> extractFromDocument() async {
          try {
            final result = await FilePicker.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['pdf', 'docx', 'doc', 'png', 'jpg', 'jpeg', 'webp', 'xlsx', 'xls', 'txt'],
              withData: true,
            );

            if (result == null || result.files.isEmpty || result.files.first.bytes == null) return;
            final file = result.files.first;

            final fileSizeFormatted = file.size > 1024 * 1024
                ? '${(file.size / (1024 * 1024)).toStringAsFixed(2)} MB'
                : '${(file.size / 1024).toStringAsFixed(1)} KB';

            final progressCtrl = ExtractionProgressController();
            progressCtrl.update(
              percent: 0.20,
              status: 'جاري قراءة وتصنيف مقايسة التخليص بالذكاء الاصطناعي...',
              stepLabel: 'المرحلة 1 من 3: فحص المستند',
              currentStep: 1,
            );

            if (!ctx.mounted) return;
            ExtractionProgressDialog.show(
              context: ctx,
              title: 'استخراج وتصنيف مقايسة التخليص الجمركي',
              fileName: file.name,
              fileSize: fileSizeFormatted,
              controller: progressCtrl,
            );

            final dio = Dio();
            final multipartFile = MultipartFile.fromBytes(file.bytes!, filename: file.name);
            final formData = FormData.fromMap({
              'file': multipartFile,
              'module_name': 'clearance-quotation',
              'save_session': false,
            });

            final response = await dio.post(
              '${ApiConstants.baseUrl}/smart-upload/upload',
              data: formData,
              options: Options(receiveTimeout: const Duration(seconds: 120)),
              onSendProgress: (sent, total) {
                if (total > 0) {
                  final ratio = sent / total;
                  progressCtrl.update(
                    percent: 0.20 + (ratio * 0.40),
                    status: 'جاري رفع الملف (${(ratio * 100).round()}%)...',
                    stepLabel: 'المرحلة 2 من 4: معالجة البيانات',
                    currentStep: 2,
                  );
                  if (ratio >= 0.99) {
                    progressCtrl.startAutoAdvance(
                      targetPercent: 0.92,
                      duration: const Duration(seconds: 4),
                      step4Status: 'جاري استخراج أتعاب ومصروفات مقايسة التخليص والنقل وتنسيق البيانات...',
                    );
                  }
                }
              },
            );

            progressCtrl.complete();
            await Future.delayed(const Duration(milliseconds: 300));
            if (ctx.mounted) Navigator.of(ctx, rootNavigator: true).pop();

            if (response.data != null) {
              final extracted = (response.data['extracted_fields'] as Map<String, dynamic>?) ?? {};
              setDlgState(() {
                if (extracted['title'] != null && (extracted['title'] as String).isNotEmpty) {
                  titleCtrl.text = extracted['title'] as String;
                }
                if (extracted['port_name'] != null && (extracted['port_name'] as String).isNotEmpty) {
                  portCtrl.text = extracted['port_name'] as String;
                }
                if (extracted['effective_from'] != null && (extracted['effective_from'] as String).isNotEmpty) {
                  dateCtrl.text = extracted['effective_from'] as String;
                }
                if (extracted['notes'] != null && (extracted['notes'] as String).isNotEmpty) {
                  notesCtrl.text = extracted['notes'] as String;
                }

                // Match Broker
                final bName = (extracted['broker_name'] as String?)?.toLowerCase() ?? '';
                if (bName.isNotEmpty) {
                  for (final b in brokersList) {
                    final pName = (b.partnerName as String).toLowerCase();
                    if (bName.contains(pName) || pName.contains(bName) || (bName.contains('acc') && pName.contains('acc')) || (bName.contains('اسكندرية') && pName.contains('اسكندرية')) || (bName.contains('أهرام') && pName.contains('أهرام')) || (bName.contains('اهرام') && pName.contains('اهرام'))) {
                      selectedBroker = b.providerId;
                      break;
                    }
                  }
                }

                // Apply extracted items and dynamic fees
                applyExtractedExpenses(extracted, isInitial: false);
              });

              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('✨ تم استخراج وتصنيف بنود المقايسة وتعبئة النموذج بنجاح!'),
                    backgroundColor: AppTheme.emerald,
                  ),
                );
              }
            }
          } catch (e) {
            if (ctx.mounted) {
              try { Navigator.of(ctx, rootNavigator: true).pop(); } catch (_) {}
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text('خطأ أثناء الاستخراج: $e'), backgroundColor: AppTheme.crimson),
              );
            }
          }
        }

        // Coded Item Registration / Alias Mapping Dialog (AI-EXPENSE-CATALOG-002)
        Future<void> showAddCustomItemDialog({String? initialName, String? initialCategory, double? initialPrice, Map<String, dynamic>? targetItem}) async {
          final formKey = GlobalKey<FormState>();
          int activeMode = 0; // 0 = Map as alias to existing code, 1 = Create new permanent code

          final catalogItems = ref.read(expenseCatalogProvider).valueOrNull ?? [];
          String? selectedCanonicalCode = catalogItems.isNotEmpty ? catalogItems.first.code : null;

          final aliasPatternCtrl = TextEditingController(text: initialName ?? '');
          final customPriceCtrl = TextEditingController(text: initialPrice != null && initialPrice > 0 ? initialPrice.toStringAsFixed(0) : '1000');
          final customNotesCtrl = TextEditingController();

          // For mode 1 (new permanent code)
          final newCodeCtrl = TextEditingController();
          final newNameArCtrl = TextEditingController(text: initialName ?? '');
          final newNameEnCtrl = TextEditingController();
          String newCategory = initialCategory ?? 'Other Fees';
          String newUnit = 'fixed';
          String customCurrency = 'EGP';
          bool isSubmitting = false;

          await showDialog(
            context: ctx,
            builder: (c) => StatefulBuilder(
              builder: (c, setInnerState) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: const Row(
                  children: [
                    Icon(Icons.qr_code_2, color: AppTheme.cobalt, size: 24),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('تكويد المصروفات الجمركية المرجعية', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: 520,
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Mode selector tabs
                          Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => setInnerState(() => activeMode = 0),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: activeMode == 0 ? AppTheme.cobalt : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '🔗 ربط كمرادف لبند معتمد',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: activeMode == 0 ? Colors.white : AppTheme.charcoal,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => setInnerState(() => activeMode = 1),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: activeMode == 1 ? AppTheme.cobalt : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '➕ تسجيل كود جديد بالكتالوج',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: activeMode == 1 ? Colors.white : AppTheme.charcoal,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (activeMode == 0) ...[
                            // Mode 0: Alias mapping
                            SearchableDropdownField<String?>(
                              value: selectedCanonicalCode,
                              labelText: 'البند المعتمد في الكتالوج *',
                              searchHintText: 'ابحث في بنود الكتالوج المعتمدة...',
                              items: catalogItems.map((ci) => SearchableDropdownItem<String?>(
                                value: ci.code,
                                label: '${ci.code} — ${ci.canonicalNameAr}',
                              )).toList(),
                              onChanged: (v) => setInnerState(() => selectedCanonicalCode = v),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: aliasPatternCtrl,
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى كتابة الاسم أو المرادف كما ورد في المقايسة' : null,
                              decoration: const InputDecoration(
                                labelText: 'الاسم أو المرادف في المستند *',
                                hintText: 'مثال: عوائد تفريغ ميناء / كارتة / أتعاب استثنائية',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ] else ...[
                            // Mode 1: New code
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: newCodeCtrl,
                                    textCapitalization: TextCapitalization.characters,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) return 'يرجى إدخال كود فريد';
                                      if (!RegExp(r'^[A-Z0-9]+(-[A-Z0-9]+)+$').hasMatch(v.trim().toUpperCase())) {
                                        return 'الصيغة غير صالحة (مثال: OTHER-CLARK-01)';
                                      }
                                      return null;
                                    },
                                    decoration: const InputDecoration(
                                      labelText: 'كود البند المرجعي *',
                                      hintText: 'OTHER-SPECIAL-01',
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: SearchableDropdownField<String>(
                                    value: newCategory,
                                    labelText: 'الفئة الرسمية *',
                                    items: const [
                                      SearchableDropdownItem(value: 'Clearance Fees', label: 'Clearance Fees (أتعاب تخليص)'),
                                      SearchableDropdownItem(value: 'Procedures & Approvals', label: 'Procedures & Approvals (إجراءات وموافقات)'),
                                      SearchableDropdownItem(value: 'Inland Transport', label: 'Inland Transport (نقل داخلي)'),
                                      SearchableDropdownItem(value: 'Port & Handling', label: 'Port & Handling (موانئ ومناولة)'),
                                      SearchableDropdownItem(value: 'Other Fees', label: 'Other Fees (مصاريف أخرى)'),
                                    ],
                                    onChanged: (v) => setInnerState(() => newCategory = v ?? newCategory),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: newNameArCtrl,
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال الاسم العربي المعتمد للبند' : null,
                              decoration: const InputDecoration(
                                labelText: 'الاسم العربي المعتمد للبند *',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: newNameEnCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'الاسم بالإنجليزية (اختياري)',
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: SearchableDropdownField<String>(
                                    value: newUnit,
                                    labelText: 'نوع الوحدة *',
                                    items: const [
                                      SearchableDropdownItem(value: 'fixed', label: 'مبلغ مقطوع (fixed)'),
                                      SearchableDropdownItem(value: 'per_container', label: 'لكل حاوية (per_container)'),
                                      SearchableDropdownItem(value: 'per_invoice', label: 'لكل فاتورة (per_invoice)'),
                                      SearchableDropdownItem(value: 'per_ton', label: 'لكل طن (per_ton)'),
                                      SearchableDropdownItem(value: 'per_truck', label: 'لكل شاحنة (per_truck)'),
                                      SearchableDropdownItem(value: 'per_day', label: 'لكل يوم (per_day)'),
                                      SearchableDropdownItem(value: 'per_shipment', label: 'لكل شحنة (per_shipment)'),
                                      SearchableDropdownItem(value: 'per_declaration', label: 'لكل شهادة (per_declaration)'),
                                      SearchableDropdownItem(value: 'per_bl', label: 'لكل بوليصة (per_bl)'),
                                    ],
                                    onChanged: (v) => setInnerState(() => newUnit = v ?? newUnit),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: customPriceCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'يرجى تحديد السعر';
                                    if (double.tryParse(v.trim()) == null) return 'السعر غير صالح';
                                    return null;
                                  },
                                  decoration: const InputDecoration(
                                    labelText: 'السعر المعتمد *',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 100,
                                child: SearchableDropdownField<String>(
                                  value: customCurrency,
                                  items: const [
                                    SearchableDropdownItem(value: 'EGP', label: 'EGP'),
                                    SearchableDropdownItem(value: 'USD', label: 'USD'),
                                    SearchableDropdownItem(value: 'EUR', label: 'EUR'),
                                  ],
                                  onChanged: (v) => setInnerState(() => customCurrency = v ?? 'EGP'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: customNotesCtrl,
                            decoration: const InputDecoration(
                              labelText: 'ملاحظات وشروط البند',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(c), child: const Text('إلغاء')),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white),
                    icon: isSubmitting
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check, size: 16),
                    label: Text(activeMode == 0 ? 'حفظ وتكويد المرادف' : 'تسجيل الكود بالكتالوج'),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setInnerState(() => isSubmitting = true);
                            final price = double.tryParse(customPriceCtrl.text.trim()) ?? 0.0;

                            if (activeMode == 0) {
                              // Mode 0: Alias pattern mapping
                              final code = selectedCanonicalCode;
                              final alias = aliasPatternCtrl.text.trim();
                              if (code != null && alias.isNotEmpty) {
                                await ref.read(expenseCatalogProvider.notifier).addPattern(code, alias);
                                final matchedCatItem = catalogItems.firstWhere((it) => it.code == code, orElse: () => catalogItems.first);

                                setDlgState(() {
                                  selectedCategoryFilter = 'All';
                                  itemSearchQuery = '';
                                  if (targetItem != null) {
                                    targetItem['code'] = code;
                                    targetItem['is_uncoded'] = false;
                                    targetItem['canonical_name_ar'] = matchedCatItem.canonicalNameAr;
                                    if (price > 0) targetItem['standard_price'] = price;
                                  } else {
                                    itemsState.insert(0, {
                                      'expense_type_id': null,
                                      'code': code,
                                      'expense_name': alias,
                                      'canonical_name_ar': matchedCatItem.canonicalNameAr,
                                      'category': matchedCatItem.category,
                                      'unit_type': matchedCatItem.unitType,
                                      'standard_price': price,
                                      'currency': customCurrency,
                                      'min_price': null,
                                      'max_price': null,
                                      'notes': customNotesCtrl.text.trim(),
                                      'is_uncoded': false,
                                      'is_active': true,
                                    });
                                  }
                                });

                                if (c.mounted) Navigator.pop(c);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text('✨ تم تكويد "$alias" وربطه بنجاح بالكود المرجعي $code'),
                                    backgroundColor: AppTheme.emerald,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                                }
                              }
                            } else {
                              // Mode 1: New code
                              final newCode = newCodeCtrl.text.trim().toUpperCase();
                              final nameAr = newNameArCtrl.text.trim();
                              final nameEn = newNameEnCtrl.text.trim();

                              await ref.read(expenseCatalogProvider.notifier).createItem({
                                'code': newCode,
                                'canonical_name_ar': nameAr,
                                if (nameEn.isNotEmpty) 'canonical_name_en': nameEn,
                                'category': newCategory,
                                'unit_type': newUnit,
                                'allow_composite': false,
                                'recognition_patterns': [nameAr],
                              });

                              setDlgState(() {
                                selectedCategoryFilter = 'All';
                                itemSearchQuery = '';
                                if (targetItem != null) {
                                  targetItem['code'] = newCode;
                                  targetItem['is_uncoded'] = false;
                                  targetItem['canonical_name_ar'] = nameAr;
                                  if (price > 0) targetItem['standard_price'] = price;
                                } else {
                                  itemsState.insert(0, {
                                    'expense_type_id': null,
                                    'code': newCode,
                                    'expense_name': nameAr,
                                    'canonical_name_ar': nameAr,
                                    'category': newCategory,
                                    'unit_type': newUnit,
                                    'standard_price': price,
                                    'currency': customCurrency,
                                    'min_price': null,
                                    'max_price': null,
                                    'notes': customNotesCtrl.text.trim(),
                                    'is_uncoded': false,
                                    'is_active': true,
                                  });
                                }
                              });

                              if (c.mounted) Navigator.pop(c);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text('✨ تم تسجيل الكود المرجعي الجديد $newCode بالكتالوج بنجاح'),
                                  backgroundColor: AppTheme.emerald,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                              }
                            }
                          },
                  ),
                ],
              ),
            ),
          );
        }
        final filteredItems = itemsState.where((itm) {
          final name = (itm['expense_name'] as String).toLowerCase();
          final cat = (itm['category'] as String);
          final matchSearch = itemSearchQuery.isEmpty || name.contains(itemSearchQuery.toLowerCase());
          final matchCat = selectedCategoryFilter == 'All' ||
              cat == selectedCategoryFilter ||
              cat.toLowerCase().contains(selectedCategoryFilter.toLowerCase()) ||
              selectedCategoryFilter.toLowerCase().contains(cat.toLowerCase());
          return matchSearch && matchCat;
        }).toList();

        void cloneRowAt(int realIdx) {
          if (realIdx < 0 || realIdx >= itemsState.length) return;
          final orig = itemsState[realIdx];
          final cloned = Map<String, dynamic>.from(orig);
          cloned['item_id'] = null;
          cloned['expense_type_id'] = null;
          final isAr = Localizations.localeOf(ctx).languageCode == 'ar';
          final suffix = isAr ? ' (نسخة)' : ' (Copy)';
          cloned['expense_name'] = '${orig['expense_name']}$suffix';
          cloned['notes'] = orig['notes'] != null && orig['notes'].toString().isNotEmpty
              ? '${orig['notes']} | مستنسخ'
              : (isAr ? 'مستنسخ' : 'Cloned');
          setDlgState(() {
            itemsState.insert(realIdx + 1, cloned);
            activeRowIndex = realIdx + 1;
          });
          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(isAr ? '✨ تم استنساخ السطر بنجاح (كنترول + د)' : '✨ Row cloned successfully (Ctrl+D)'),
                backgroundColor: AppTheme.cobalt,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }

        final mediaQuery = MediaQuery.of(ctx);
        final dialogWidth = (mediaQuery.size.width * 0.92).clamp(750.0, 1050.0);
        final dialogHeight = (mediaQuery.size.height * 0.88).clamp(420.0, 750.0);

        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.keyD, control: true): () {
              if (activeRowIndex != null) {
                cloneRowAt(activeRowIndex!);
              } else if (filteredItems.isNotEmpty) {
                final firstIdx = itemsState.indexOf(filteredItems.first);
                cloneRowAt(firstIdx);
              }
            },
          },
          child: Focus(
            autofocus: true,
            child: Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Container(
            width: dialogWidth,
            height: dialogHeight,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Header & AI Extract Button
                Row(
                  children: [
                    Icon(isEditing ? Icons.edit_note : Icons.add_circle, color: AppTheme.cobalt, size: 26),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isEditing ? l.editPriceListTitle(existingPriceList.title) : l.createPriceListTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.charcoal),
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C5CE7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.auto_awesome, color: Colors.amber, size: 16),
                      label: const Text('✨ استخراج ذكي من ملف (Word/PDF/Text)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      onPressed: extractFromDocument,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),
                const Divider(height: 16),

                // Header Form Inputs (Broker, Title, Port, Effective Date, Notes)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.charcoal.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          if (!isEditing)
                            Expanded(
                              flex: 2,
                              child: SearchableDropdownField<int?>(
                                value: selectedBroker,
                                labelText: '${l.responsibleCustomsBroker} *',
                                searchHintText: l.searchBrokerHint,
                                items: brokersList.map((b) => SearchableDropdownItem<int?>(value: b.providerId, label: b.partnerName)).toList(),
                                onChanged: (v) => setDlgState(() => selectedBroker = v),
                              ),
                            )
                          else
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade300)),
                                child: Text('${l.responsibleCustomsBroker}: ${existingPriceList.brokerName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: titleCtrl,
                              decoration: InputDecoration(labelText: l.priceListTitleField, isDense: true, border: const OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: portCtrl,
                              decoration: InputDecoration(labelText: l.targetPortField, isDense: true, border: const OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: dateCtrl,
                              decoration: InputDecoration(labelText: '${l.effectiveDateField} 📅', isDense: true, border: const OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: notesCtrl,
                        decoration: InputDecoration(labelText: l.generalTermsAndNotesField, isDense: true, border: const OutlineInputBorder()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Table Toolbar: Search, Category Filter & Quick Actions
                Row(
                  children: [
                    // Search Box
                    SizedBox(
                      width: 200,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: l.searchExpenseCatalogHint,
                          prefixIcon: const Icon(Icons.search, size: 16),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        onChanged: (v) => setDlgState(() => itemSearchQuery = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Category Filter
                    SizedBox(
                      width: 220,
                      child: SearchableDropdownField<String>(
                        value: selectedCategoryFilter,
                        labelText: l.filterCategoryLabel,
                        items: [
                          SearchableDropdownItem(value: 'All', label: l.allCategoriesItem),
                          const SearchableDropdownItem(value: 'Clearance Fees', label: 'Clearance Fees (أتعاب تخليص)'),
                          const SearchableDropdownItem(value: 'Procedures & Approvals', label: 'Procedures & Approvals (إجراءات وموافقات)'),
                          const SearchableDropdownItem(value: 'Inland Transport', label: 'Inland Transport (نقل داخلي)'),
                          const SearchableDropdownItem(value: 'Port & Handling', label: 'Port & Handling (موانئ ومناولة)'),
                          const SearchableDropdownItem(value: 'Other Fees', label: 'Other Fees (مصاريف أخرى)'),
                        ],
                        onChanged: (v) => setDlgState(() => selectedCategoryFilter = v ?? 'All'),
                      ),
                    ),
                    const Spacer(),
                    // Add Custom Item Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                      onPressed: () => showAddCustomItemDialog(),
                      icon: const Icon(Icons.qr_code_2, size: 15),
                      label: const Text('➕ تكويد بند جديد أو ربط مرادف', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 6),
                    // Quick Fill Button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: AppTheme.cobalt),
                      onPressed: () {
                        setDlgState(() {
                          for (var itm in itemsState) {
                            final name = itm['expense_name'] as String;
                            for (var entry in standardRatesMap.entries) {
                              if (name.contains(entry.key) || entry.key.contains(name)) {
                                itm['standard_price'] = entry.value;
                                break;
                              }
                            }
                          }
                        });
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('⚡ ${l.standardRatesFilledToast}'), backgroundColor: AppTheme.cobalt),
                        );
                      },
                      icon: const Icon(Icons.flash_on, size: 14),
                      label: Text(l.fillStandardRatesBtn, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 6),
                    // Zero Out Button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade800),
                      onPressed: () {
                        setDlgState(() {
                          for (var itm in itemsState) {
                            itm['standard_price'] = 0.0;
                          }
                        });
                      },
                      icon: const Icon(Icons.clear_all, size: 14),
                      label: Text(l.zeroOutRatesBtn, style: const TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Interactive Items Table
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ListView.separated(
                        itemCount: filteredItems.length,
                        separatorBuilder: (ctx, idx) => Divider(height: 1, color: Colors.grey.shade200),
                        itemBuilder: (ctx, idx) {
                          final itm = filteredItems[idx];
                          final realIdx = itemsState.indexOf(itm);
                          final standardPrice = (itm['standard_price'] as num?)?.toDouble() ?? 0.0;
                          final isCustomItem = itm['expense_type_id'] == null;

                          return Container(
                            color: isCustomItem ? Colors.amber.shade50 : (idx.isEven ? Colors.white : Colors.grey.shade50),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Row(
                              children: [
                                // Item Name & Category
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          if (itm['code'] != null)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              margin: const EdgeInsets.only(left: 6),
                                              decoration: BoxDecoration(color: AppTheme.cobalt, borderRadius: BorderRadius.circular(4)),
                                              child: Text(itm['code'].toString(), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                            )
                                          else if (itm['is_uncoded'] == true)
                                            InkWell(
                                              onTap: () => showAddCustomItemDialog(initialName: itm['expense_name'], initialPrice: standardPrice, targetItem: itm),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                margin: const EdgeInsets.only(left: 6),
                                                decoration: BoxDecoration(color: AppTheme.crimson, borderRadius: BorderRadius.circular(4)),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.warning_amber_rounded, color: Colors.white, size: 10),
                                                    SizedBox(width: 2),
                                                    Text('بحاجة لتكويد', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                                  ],
                                                ),
                                              ),
                                            )
                                          else if (isCustomItem)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              margin: const EdgeInsets.only(left: 6),
                                              decoration: BoxDecoration(color: Colors.amber.shade700, borderRadius: BorderRadius.circular(4)),
                                              child: const Text('بند مخصص', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                            ),
                                          Expanded(
                                            child: Text(
                                              itm['expense_name'],
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '${(itm['category'] as String).split('(').first.trim()} | ${itm['unit_type']}',
                                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Standard Price Input
                                SizedBox(
                                  width: 130,
                                  child: TextFormField(
                                    key: ValueKey('dlg_price_${itm["expense_type_id"] ?? itm["expense_name"]}_$standardPrice'),
                                    initialValue: standardPrice == 0.0 ? '' : (standardPrice % 1 == 0 ? standardPrice.toInt().toString() : standardPrice.toString()),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      labelText: l.approvedPriceField,
                                      isDense: true,
                                      border: const OutlineInputBorder(),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    ),
                                    onChanged: (v) {
                                      final p = double.tryParse(v) ?? 0.0;
                                      itemsState[realIdx]['standard_price'] = p;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Currency Dropdown
                                SizedBox(
                                  width: 110,
                                  child: SearchableDropdownField<String>(
                                    value: itm['currency'] ?? 'EGP',
                                    items: const [
                                      SearchableDropdownItem(value: 'EGP', label: 'EGP'),
                                      SearchableDropdownItem(value: 'USD', label: 'USD'),
                                      SearchableDropdownItem(value: 'EUR', label: 'EUR'),
                                    ],
                                    onChanged: (v) => setDlgState(() => itemsState[realIdx]['currency'] = v ?? 'EGP'),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Notes / Min-Max Input
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    key: ValueKey('dlg_notes_${itm['expense_type_id'] ?? itm['expense_name']}_${itm['notes']}'),
                                    initialValue: itm['notes'] ?? '',
                                    decoration: InputDecoration(
                                      labelText: l.notesPriceRangeField,
                                      isDense: true,
                                      border: const OutlineInputBorder(),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    ),
                                    onChanged: (v) => itemsState[realIdx]['notes'] = v,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.control_point_duplicate_rounded, color: AppTheme.cobalt, size: 18),
                                  tooltip: l.cloneRowTooltip,
                                  onPressed: () => cloneRowAt(realIdx),
                                ),
                                if (isCustomItem)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                    tooltip: 'حذف البند المخصص',
                                    onPressed: () => setDlgState(() => itemsState.removeAt(realIdx)),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Actions Footer
                Container(
                  padding: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                    Text(
                      l.totalExpensesCountSummary(
                        itemsState.length,
                        itemsState.where((i) => (i['standard_price'] as num) > 0).length,
                      ),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(l.cancel),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.emerald,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          onPressed: isSaving ? null : () async {
                            final title = titleCtrl.text.trim();
                            if (title.isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text(l.priceListTitleRequired), backgroundColor: Colors.red),
                              );
                              return;
                            }

                            if (selectedBroker == null) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text(l.selectBrokerRequired), backgroundColor: Colors.orange),
                              );
                              return;
                            }

                            final broker = brokersList.firstWhere(
                              (element) => element.providerId == selectedBroker,
                              orElse: () => null,
                            );
                            final brokerName = broker?.partnerName ?? (existingPriceList?.brokerName ?? 'مستخلص');

                            final itemsPayload = itemsState.map((itm) => {
                              if (itm['item_id'] != null) 'item_id': itm['item_id'],
                              'expense_type_id': itm['expense_type_id'],
                              'expense_name': itm['expense_name'],
                              'category': itm['category'],
                              'unit_type': itm['unit_type'] ?? 'Per Shipment',
                              'standard_price': itm['standard_price'] ?? 0.0,
                              'currency': itm['currency'] ?? 'EGP',
                              'min_price': itm['min_price'],
                              'max_price': itm['max_price'],
                              'notes': itm['notes'] ?? '',
                              'is_active': itm['is_active'] ?? true,
                            }).toList();

                            setDlgState(() => isSaving = true);

                            try {
                              if (isEditing) {
                                await ref.read(brokerPriceListsProvider.notifier).updatePriceList(
                                  existingPriceList.priceListId,
                                  {
                                    'title': title,
                                    'broker_id': selectedBroker,
                                    'broker_name': brokerName,
                                    'port_name': portCtrl.text.trim(),
                                    'effective_from': dateCtrl.text.trim().isNotEmpty ? dateCtrl.text.trim() : DateTime.now().toIso8601String().split('T').first,
                                    'version': version,
                                    'is_active': existingPriceList.isActive,
                                    'notes': notesCtrl.text.trim(),
                                    'items': itemsPayload,
                                  },
                                );
                                ref.invalidate(brokerPriceListsProvider);
                                await ref.read(brokerPriceListsProvider.notifier).fetchPriceLists();
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('✅ ${l.priceListUpdatedSuccess}'), backgroundColor: AppTheme.emerald),
                                  );
                                }
                              } else {
                                await ref.read(brokerPriceListsProvider.notifier).createPriceList({
                                  'title': title,
                                  'broker_id': selectedBroker,
                                  'broker_name': brokerName,
                                  'port_name': portCtrl.text.trim(),
                                  'effective_from': dateCtrl.text.trim().isNotEmpty ? dateCtrl.text.trim() : DateTime.now().toIso8601String().split('T').first,
                                  'version': 1,
                                  'is_active': true,
                                  'notes': notesCtrl.text.trim(),
                                  'items': itemsPayload,
                                });
                                ref.invalidate(brokerPriceListsProvider);
                                await ref.read(brokerPriceListsProvider.notifier).fetchPriceLists();
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('✅ ${l.priceListCreatedSuccess}'), backgroundColor: AppTheme.emerald),
                                  );
                                }
                              }
                              if (ctx.mounted) Navigator.pop(ctx);
                            } catch (e) {
                              String errorMsg = e.toString();
                              if (e is DioException) {
                                final resData = e.response?.data;
                                if (resData is Map && resData.containsKey('detail')) {
                                  errorMsg = resData['detail'].toString();
                                } else if (resData != null) {
                                  errorMsg = resData.toString();
                                } else {
                                  errorMsg = e.message ?? 'فشل الاتصال بالخادم';
                                }
                              }
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text('❌ تعذر الحفظ: $errorMsg'),
                                    backgroundColor: AppTheme.crimson,
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              }
                            } finally {
                              if (ctx.mounted) {
                                setDlgState(() => isSaving = false);
                              }
                            }
                          },
                          icon: isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.save, color: Colors.white, size: 18),
                          label: Text(
                            isSaving
                                ? 'جاري الحفظ...'
                                : (isEditing ? l.savePriceListEditsBtn : l.createAndSavePriceListBtn),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
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
  );
},
),
);
}
