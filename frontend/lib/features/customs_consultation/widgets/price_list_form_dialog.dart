import 'dart:typed_data';
import 'package:flutter/material.dart';
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
  final catalog = ref.read(clearanceExpenseTypesProvider).value ?? [];
  final List<Map<String, dynamic>> itemsState = [];

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
      double initialPrice = 0.0;
      if (initialExtractedData != null) {
        for (final entry in standardRatesMap.entries) {
          if (exp.nameAr.contains(entry.key) || entry.key.contains(exp.nameAr)) {
            initialPrice = entry.value;
            break;
          }
        }
      }
      itemsState.add({
        'expense_type_id': exp.expenseId,
        'expense_name': exp.nameAr,
        'category': exp.category,
        'unit_type': exp.defaultUnit,
        'standard_price': initialPrice,
        'currency': exp.defaultCurrency,
        'min_price': null,
        'max_price': null,
        'notes': '',
        'is_active': true,
      });
    }
  }

  // Pre-fill broker from initialExtractedData if provided
  if (initialExtractedData != null && !isEditing) {
    final bName = (initialExtractedData['broker_name'] as String?)?.toLowerCase() ?? '';
    if (bName.isNotEmpty) {
      for (final b in brokersList) {
        final pName = (b.partnerName as String).toLowerCase();
        if (bName.contains(pName) || pName.contains(bName) || (bName.contains('acc') && pName.contains('acc')) || (bName.contains('اسكندرية') && pName.contains('اسكندرية'))) {
          selectedBroker = b.providerId;
          break;
        }
      }
    }
  }

  String itemSearchQuery = '';
  String selectedCategoryFilter = 'All';

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
              options: Options(receiveTimeout: const Duration(seconds: 60)),
              onSendProgress: (sent, total) {
                if (total > 0) {
                  final ratio = sent / total;
                  progressCtrl.update(
                    percent: 0.20 + (ratio * 0.40),
                    status: 'جاري رفع الملف (${(ratio * 100).round()}%)...',
                    stepLabel: 'المرحلة 2 من 3: معالجة البيانات',
                    currentStep: 2,
                  );
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
                    if (bName.contains(pName) || pName.contains(bName) || (bName.contains('acc') && pName.contains('acc')) || (bName.contains('اسكندرية') && pName.contains('اسكندرية'))) {
                      selectedBroker = b.providerId;
                      break;
                    }
                  }
                }

                // Apply standard benchmark rates
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

        // Add Custom Surcharge / Ad-hoc Item Dialog
        Future<void> showAddCustomItemDialog() async {
          final customNameCtrl = TextEditingController();
          final customPriceCtrl = TextEditingController(text: '1000');
          final customNotesCtrl = TextEditingController();
          String customCategory = 'Other Fees (مصاريف أخرى)';
          String customUnit = 'Per Shipment (لكل شحنة)';
          String customCurrency = 'EGP';

          await showDialog(
            context: ctx,
            builder: (c) => StatefulBuilder(
              builder: (c, setInnerState) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: const Row(
                  children: [
                    Icon(Icons.add_circle, color: AppTheme.cobalt),
                    SizedBox(width: 8),
                    Text('إضافة بند مخصص / استثنائي خارج الليستة', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                content: SizedBox(
                  width: 480,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: customNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'اسم البند / المصروف المخصص *',
                          hintText: 'مثال: كشف عمال وتجميع وكلارك / حراسة أمنية',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SearchableDropdownField<String>(
                        value: customCategory,
                        labelText: 'فئة المصروف',
                        items: const [
                          SearchableDropdownItem(value: 'Clearance Fees (أتعاب ومصاريف تخليص)', label: 'Clearance Fees (أتعاب ومصاريف تخليص)'),
                          SearchableDropdownItem(value: 'Procedures & Approvals (إجراءات وموافقات وفحص)', label: 'Procedures & Approvals (إجراءات وموافقات وفحص)'),
                          SearchableDropdownItem(value: 'Inland Transport (نقل بري وشاحنات)', label: 'Inland Transport (نقل بري وشاحنات)'),
                          SearchableDropdownItem(value: 'Port & Handling (موانئ وتعتيق وتفريغ)', label: 'Port & Handling (موانئ وتعتيق وتفريغ)'),
                          SearchableDropdownItem(value: 'Other Fees (مصاريف أخرى)', label: 'Other Fees (مصاريف أخرى)'),
                        ],
                        onChanged: (v) => setInnerState(() => customCategory = v ?? customCategory),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: customPriceCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                          labelText: 'ملاحظات وشروط البند المخصص',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(c), child: const Text('إلغاء')),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('إضافة البند'),
                    onPressed: () {
                      final name = customNameCtrl.text.trim();
                      if (name.isEmpty) return;
                      final price = double.tryParse(customPriceCtrl.text.trim()) ?? 0.0;

                      setDlgState(() {
                        itemsState.insert(0, {
                          'expense_type_id': null,
                          'expense_name': name,
                          'category': customCategory,
                          'unit_type': customUnit,
                          'standard_price': price,
                          'currency': customCurrency,
                          'min_price': null,
                          'max_price': null,
                          'notes': customNotesCtrl.text.trim(),
                          'is_active': true,
                        });
                      });
                      Navigator.pop(c);
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
          final matchCat = selectedCategoryFilter == 'All' || cat == selectedCategoryFilter;
          return matchSearch && matchCat;
        }).toList();

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: 1000,
            height: 780,
            padding: const EdgeInsets.all(20),
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
                          const SearchableDropdownItem(value: 'Clearance Fees (أتعاب ومصاريف تخليص)', label: 'Clearance Fees'),
                          const SearchableDropdownItem(value: 'Procedures & Approvals (إجراءات وموافقات وفحص)', label: 'Procedures & Approvals'),
                          const SearchableDropdownItem(value: 'Inland Transport (نقل بري وشاحنات)', label: 'Inland Transport'),
                          const SearchableDropdownItem(value: 'Port & Handling (موانئ وتعتيق وتفريغ)', label: 'Port & Handling'),
                          const SearchableDropdownItem(value: 'Other Fees (مصاريف أخرى)', label: 'Other Fees'),
                        ],
                        onChanged: (v) => setDlgState(() => selectedCategoryFilter = v ?? 'All'),
                      ),
                    ),
                    const Spacer(),
                    // Add Custom Item Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                      onPressed: showAddCustomItemDialog,
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text('➕ إضافة بند مخصص خارج الليستة', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
                                          if (isCustomItem)
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
                                    key: ValueKey('dlg_price_${itm["expense_type_id"] ?? itm["expense_name"]}'),
                                    initialValue: standardPrice == 0.0 ? '' : standardPrice.toString(),
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
                                    key: ValueKey('dlg_notes_${itm['expense_type_id'] ?? itm['expense_name']}'),
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
                const SizedBox(height: 14),

                // Actions Footer
                Row(
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
                          onPressed: () async {
                            final title = titleCtrl.text.trim();
                            if (title.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l.priceListTitleRequired), backgroundColor: Colors.red),
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
                              'unit_type': itm['unit_type'],
                              'standard_price': itm['standard_price'],
                              'currency': itm['currency'],
                              'min_price': itm['min_price'],
                              'max_price': itm['max_price'],
                              'notes': itm['notes'],
                              'is_active': itm['is_active'] ?? true,
                            }).toList();

                            try {
                              if (isEditing) {
                                await ref.read(brokerPriceListsProvider.notifier).updatePriceList(
                                  existingPriceList.priceListId,
                                  {
                                    'title': title,
                                    'port_name': portCtrl.text.trim(),
                                    'effective_from': dateCtrl.text.trim(),
                                    'version': version,
                                    'is_active': existingPriceList.isActive,
                                    'notes': notesCtrl.text.trim(),
                                    'items': itemsPayload,
                                  },
                                );
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('✅ ${l.priceListUpdatedSuccess}'), backgroundColor: AppTheme.emerald),
                                  );
                                }
                              } else {
                                if (selectedBroker == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(l.selectBrokerRequired), backgroundColor: Colors.orange),
                                  );
                                  return;
                                }
                                await ref.read(brokerPriceListsProvider.notifier).createPriceList({
                                  'title': title,
                                  'broker_id': selectedBroker,
                                  'broker_name': brokerName,
                                  'port_name': portCtrl.text.trim(),
                                  'effective_from': dateCtrl.text.trim(),
                                  'version': 1,
                                  'is_active': true,
                                  'notes': notesCtrl.text.trim(),
                                  'items': itemsPayload,
                                });
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('✅ ${l.priceListCreatedSuccess}'), backgroundColor: AppTheme.emerald),
                                  );
                                }
                              }
                              if (ctx.mounted) Navigator.pop(ctx);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.save, color: Colors.white, size: 18),
                          label: Text(
                            isEditing ? l.savePriceListEditsBtn : l.createAndSavePriceListBtn,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
