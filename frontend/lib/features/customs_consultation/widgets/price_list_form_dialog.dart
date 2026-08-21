import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../models/customs_consultation_model.dart';
import '../providers/customs_consultation_provider.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';

void showPriceListFormDialog(
  BuildContext context,
  WidgetRef ref, {
  BrokerPriceListModel? existingPriceList,
  required List<dynamic> brokersList,
}) {
    if (brokersList.isEmpty && existingPriceList == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد مخلصين جمركيين مسجلين في الشركاء.'), backgroundColor: Colors.orange),
      );
      return;
    }

    final isEditing = existingPriceList != null;
    int? selectedBroker = existingPriceList?.brokerId ?? (brokersList.isNotEmpty ? brokersList.first.providerId : null);
    final titleCtrl = TextEditingController(text: existingPriceList?.title ?? 'بيان أسعار التخليص والنقل لميناء الإسكندرية لعام 2026');
    final portCtrl = TextEditingController(text: existingPriceList?.portName ?? 'ميناء الإسكندرية والدخيلة');
    final notesCtrl = TextEditingController(text: existingPriceList?.notes ?? '');
    final dateCtrl = TextEditingController(text: existingPriceList?.effectiveFrom ?? DateTime.now().toIso8601String().split('T').first);
    int version = existingPriceList?.version ?? 1;

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
    }

    String itemSearchQuery = '';
    String selectedCategoryFilter = 'All';

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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
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
              width: 950,
              height: 750,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Header
                  Row(
                    children: [
                      Icon(isEditing ? Icons.edit_note : Icons.add_circle, color: AppTheme.cobalt, size: 26),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isEditing ? 'تعديل وتحديث أسعار قائمة المستخلص: ${existingPriceList.title}' : 'إنشاء وتحديد أسعار قائمة جديدة للمستخلص الجمركي',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.charcoal),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, color: Colors.grey),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Header Form Inputs
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
                                  labelText: 'المستخلص الجمركي *',
                                  searchHintText: 'ابحث عن المستخلص...',
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
                                  child: Text('المستخلص: ${existingPriceList.brokerName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: titleCtrl,
                                decoration: const InputDecoration(labelText: 'عنوان قائمة الأسعار *', isDense: true, border: OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: portCtrl,
                                decoration: const InputDecoration(labelText: 'الميناء المعني', isDense: true, border: OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: dateCtrl,
                                decoration: const InputDecoration(labelText: 'تاريخ السريان', isDense: true, border: OutlineInputBorder()),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: notesCtrl,
                          decoration: const InputDecoration(labelText: 'ملاحظات وشروط عامة', isDense: true, border: OutlineInputBorder()),
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
                        width: 220,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'بحث في بنود المصروفات...',
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
                        width: 250,
                        child: SearchableDropdownField<String>(
                          value: selectedCategoryFilter,
                          labelText: 'تصفية التصنيف',
                          searchHintText: 'ابحث عن التصنيف...',
                          items: const [
                            SearchableDropdownItem(value: 'All', label: 'جميع التصنيفات'),
                            SearchableDropdownItem(value: 'Clearance Fees (أتعاب ومصاريف تخليص)', label: 'أتعاب ومصاريف تخليص'),
                            SearchableDropdownItem(value: 'Procedures & Approvals (إجراءات وموافقات وفحص)', label: 'إجراءات وموافقات وفحص'),
                            SearchableDropdownItem(value: 'Inland Transport (نقل بري وشاحنات)', label: 'نقل بري وشاحنات'),
                            SearchableDropdownItem(value: 'Port & Handling (موانئ وتعتيق وتفريغ)', label: 'موانئ وتعتيق وتفريغ'),
                            SearchableDropdownItem(value: 'Other Fees (مصاريف أخرى)', label: 'مصاريف أخرى'),
                          ],
                          onChanged: (v) => setDlgState(() => selectedCategoryFilter = v ?? 'All'),
                        ),
                      ),
                      const Spacer(),
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
                            const SnackBar(content: Text('⚡ تم استدعاء وتعبئة الأسعار الاسترشادية القياسية المصرية بنجاح!'), backgroundColor: AppTheme.cobalt),
                          );
                        },
                        icon: const Icon(Icons.flash_on, size: 14),
                        label: const Text('تعبئة بالأسعار الاسترشادية', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
                        label: const Text('تصفير الكل', style: TextStyle(fontSize: 11)),
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

                            return Container(
                              color: idx.isEven ? Colors.white : Colors.grey.shade50,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: Row(
                                children: [
                                  // Item Name & Category
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          itm['expense_name'],
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal),
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
                                      key: ValueKey('dlg_price_${itm['expense_type_id']}_$standardPrice'),
                                      initialValue: standardPrice == 0.0 ? '' : standardPrice.toString(),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(
                                        labelText: 'السعر المعتمد *',
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                                    width: 85,
                                    child: DropdownButtonFormField<String>(
                                      value: itm['currency'] ?? 'EGP',
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: 'EGP', child: Text('EGP', style: TextStyle(fontSize: 11))),
                                        DropdownMenuItem(value: 'USD', child: Text('USD', style: TextStyle(fontSize: 11))),
                                        DropdownMenuItem(value: 'EUR', child: Text('EUR', style: TextStyle(fontSize: 11))),
                                      ],
                                      onChanged: (v) => setDlgState(() => itemsState[realIdx]['currency'] = v ?? 'EGP'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Notes / Min-Max Input
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      key: ValueKey('dlg_notes_${itm['expense_type_id']}'),
                                      initialValue: itm['notes'] ?? '',
                                      decoration: const InputDecoration(
                                        labelText: 'ملاحظات / نطاق السعر',
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      ),
                                      onChanged: (v) => itemsState[realIdx]['notes'] = v,
                                    ),
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
                        'إجمالي بنود المصروفات بالقائمة: ${itemsState.length} بند (${itemsState.where((i) => (i['standard_price'] as num) > 0).length} بند مسعر بقيمة)',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('إلغاء'),
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
                                  const SnackBar(content: Text('يرجى كتابة عنوان قائمة الأسعار.'), backgroundColor: Colors.red),
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
                                      const SnackBar(content: Text('✅ تم تحديث وتعديل أسعار القائمة بنجاح!'), backgroundColor: AppTheme.emerald),
                                    );
                                  }
                                } else {
                                  if (selectedBroker == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('الرجاء اختيار المستخلص الجمركي'), backgroundColor: Colors.orange),
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
                                      const SnackBar(content: Text('✅ تم إنشاء قائمة أسعار المخلص وحفظ الأسعار بنجاح!'), backgroundColor: AppTheme.emerald),
                                    );
                                  }
                                }
                                if (ctx.mounted) Navigator.pop(ctx);
                              } catch (e) {
                                if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('خطأ أثناء الحفظ: $e'), backgroundColor: Colors.red),
                                );
                                }
                              }
                            },
                            icon: const Icon(Icons.save, color: Colors.white, size: 18),
                            label: Text(
                              isEditing ? 'حفظ تعديلات القائمة' : 'إنشاء وحفظ قائمة الأسعار',
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
