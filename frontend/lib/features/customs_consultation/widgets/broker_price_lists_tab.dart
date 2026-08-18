import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../models/customs_consultation_model.dart';
import '../providers/customs_consultation_provider.dart';
import '../../external_service_providers/providers/partners_provider.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import 'price_list_form_dialog.dart';

class BrokerPriceListsTab extends ConsumerStatefulWidget {
  const BrokerPriceListsTab({super.key});

  @override
  ConsumerState<BrokerPriceListsTab> createState() => _BrokerPriceListsTabState();
}

class _BrokerPriceListsTabState extends ConsumerState<BrokerPriceListsTab> {
  int? _selectedMgmtBrokerId;
  String _mgmtExpenseSearch = '';
  String _mgmtExpenseCategory = 'All';
  int _managementSubTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return _buildPriceListsAndCatalogTab();
  }
  Widget _buildPriceListsAndCatalogTab() {
    final priceListsAsync = ref.watch(brokerPriceListsProvider);
    final expenseTypesAsync = ref.watch(clearanceExpenseTypesProvider);
    final brokersList = (ref.watch(partnersProvider).value ?? [])
        .where((p) => p.partnerType.toLowerCase().contains('customs broker') || p.partnerType.toLowerCase().contains('مخلص'))
        .toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sub-Tab Switcher (Segmented Control)
          Row(
            children: [
              ChoiceChip(
                label: const Text('📋 قوائم أسعار المخلصين (Broker Price Lists)', style: TextStyle(fontWeight: FontWeight.bold)),
                selected: _managementSubTabIndex == 0,
                selectedColor: AppTheme.cobalt.withOpacity(0.18),
                onSelected: (_) => setState(() => _managementSubTabIndex = 0),
              ),
              const SizedBox(width: 12),
              ChoiceChip(
                label: const Text('🏷️ دليل وتكويد بنود المصروفات (Clearance Expense Catalog)', style: TextStyle(fontWeight: FontWeight.bold)),
                selected: _managementSubTabIndex == 1,
                selectedColor: AppTheme.cobalt.withOpacity(0.18),
                onSelected: (_) => setState(() => _managementSubTabIndex = 1),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Sub-Tab Content
          Expanded(
            child: _managementSubTabIndex == 0
                ? _buildBrokerPriceListsView(priceListsAsync, brokersList)
                : _buildExpenseCatalogView(expenseTypesAsync),
          ),
        ],
      ),
    );
  }
  Widget _buildBrokerPriceListsView(AsyncValue<List<BrokerPriceListModel>> priceListsAsync, List<dynamic> brokersList) {
    return priceListsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('❌ Error: $e')),
      data: (priceLists) {
        final filteredLists = priceLists.where((pl) {
          if (_selectedMgmtBrokerId != null && pl.brokerId != _selectedMgmtBrokerId) return false;
          return true;
        }).toList();

        return Column(
          children: [
            // Filter Bar
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 300,
                      child: SearchableDropdownField<int?>(
                        value: _selectedMgmtBrokerId,
                        labelText: 'تصفية حسب المخلص الجمركي',
                        searchHintText: 'ابحث عن مخلص...',
                        items: [
                          const SearchableDropdownItem(value: null, label: 'جميع المخلصين'),
                          ...brokersList.map((b) => SearchableDropdownItem<int?>(
                                value: b.providerId,
                                label: b.partnerName,
                              )),
                        ],
                        onChanged: (v) => setState(() => _selectedMgmtBrokerId = v),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                      onPressed: () => showPriceListFormDialog(brokersList: brokersList),
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('إنشاء قائمة أسعار جديدة لمخلص', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Price Lists Table / Grid
            Expanded(
              child: filteredLists.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('لا توجد قوائم أسعار مسجلة للمخلصين المحددين.', style: TextStyle(color: Colors.grey, fontSize: 14)),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => showPriceListFormDialog(brokersList: brokersList),
                            icon: const Icon(Icons.add),
                            label: const Text('إضافة قائمة أسعار الآن'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredLists.length,
                      itemBuilder: (ctx, idx) {
                        final pl = filteredLists[idx];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: ExpansionTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: AppTheme.cobalt.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                              child: const Icon(Icons.price_change, color: AppTheme.cobalt),
                            ),
                            title: Row(
                              children: [
                                Text(pl.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: pl.isActive ? Colors.green.shade100 : Colors.red.shade100, borderRadius: BorderRadius.circular(4)),
                                  child: Text(pl.isActive ? 'سارية' : 'مؤرشفة', style: TextStyle(color: pl.isActive ? Colors.green.shade900 : Colors.red.shade900, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                const Spacer(),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.cobalt,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                  onPressed: () => showPriceListFormDialog(existingPriceList: pl, brokersList: brokersList),
                                  icon: const Icon(Icons.edit, color: Colors.white, size: 14),
                                  label: const Text('تعديل الأسعار والبنود', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                  tooltip: 'أرشفة قائمة الأسعار',
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('تأكيد أرشفة قائمة الأسعار'),
                                        content: Text('هل أنت متأكد من رغبتك في أرشفة قائمة الأسعار "${pl.title}"؟'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text('أرشفة', style: TextStyle(color: Colors.white)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await ref.read(brokerPriceListsProvider.notifier).softDeletePriceList(pl.priceListId);
                                    }
                                  },
                                ),
                              ],
                            ),
                            subtitle: Text('المخلص: ${pl.brokerName} | الميناء: ${pl.portName ?? "عام"} | السريان: من ${pl.effectiveFrom} ${pl.effectiveTo != null ? "إلى ${pl.effectiveTo}" : "(مفتوح)"} | عدد البنود: ${pl.items.length}'),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (pl.notes != null && pl.notes!.isNotEmpty) ...[
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.amber.shade200)),
                                        child: Text('📝 ملاحظات وشروط: ${pl.notes}', style: const TextStyle(fontSize: 12)),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    Table(
                                      border: TableBorder.all(color: Colors.grey.shade300),
                                      columnWidths: const {
                                        0: FlexColumnWidth(3.0),
                                        1: FlexColumnWidth(2.0),
                                        2: FlexColumnWidth(1.2),
                                        3: FlexColumnWidth(1.5),
                                        4: FlexColumnWidth(2.0),
                                      },
                                      children: [
                                        TableRow(
                                          decoration: BoxDecoration(color: AppTheme.charcoal.withOpacity(0.08)),
                                          children: const [
                                            Padding(padding: EdgeInsets.all(6), child: Text('اسم المصروف / البند', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                            Padding(padding: EdgeInsets.all(6), child: Text('التصنيف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                            Padding(padding: EdgeInsets.all(6), child: Text('الوحدة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                            Padding(padding: EdgeInsets.all(6), child: Text('السعر المعتمد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                            Padding(padding: EdgeInsets.all(6), child: Text('نطاق السعر / ملاحظات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                          ],
                                        ),
                                        ...pl.items.map((itm) => TableRow(
                                              children: [
                                                Padding(padding: const EdgeInsets.all(6), child: Text(itm.expenseName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                                Padding(padding: const EdgeInsets.all(6), child: Text(itm.category.split('(').first.trim(), style: const TextStyle(fontSize: 10))),
                                                Padding(padding: const EdgeInsets.all(6), child: Text(itm.unitType, style: const TextStyle(fontSize: 10))),
                                                Padding(padding: const EdgeInsets.all(6), child: Text('${itm.standardPrice.toStringAsFixed(2)} ${itm.currency}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald, fontSize: 11))),
                                                Padding(
                                                  padding: const EdgeInsets.all(6),
                                                  child: Text(
                                                    itm.minPrice != null && itm.maxPrice != null
                                                        ? '${itm.minPrice!.toStringAsFixed(0)} - ${itm.maxPrice!.toStringAsFixed(0)} ${itm.currency}'
                                                        : (itm.notes ?? '-'),
                                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                                  ),
                                                ),
                                              ],
                                            )),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
  Widget _buildExpenseCatalogView(AsyncValue<List<ClearanceExpenseTypeModel>> expenseTypesAsync) {
    return expenseTypesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('❌ Error: $e')),
      data: (expenses) {
        final filtered = expenses.where((exp) {
          if (_mgmtExpenseCategory != 'All' && exp.category != _mgmtExpenseCategory) return false;
          if (_mgmtExpenseSearch.isNotEmpty) {
            final q = _mgmtExpenseSearch.toLowerCase();
            return exp.expenseCode.toLowerCase().contains(q) || exp.nameAr.toLowerCase().contains(q) || (exp.nameEn?.toLowerCase().contains(q) ?? false);
          }
          return true;
        }).toList();

        return Column(
          children: [
            // Toolbar
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 250,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'بحث في دليل المصروفات...',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                        onChanged: (v) => setState(() => _mgmtExpenseSearch = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 250,
                      child: SearchableDropdownField<String>(
                        value: _mgmtExpenseCategory,
                        labelText: 'تصفية التصنيف',
                        searchHintText: 'ابحث...',
                        items: const [
                          SearchableDropdownItem(value: 'All', label: 'جميع التصنيفات'),
                          SearchableDropdownItem(value: 'Clearance Fees (أتعاب ومصاريف تخليص)', label: 'أتعاب ومصاريف تخليص'),
                          SearchableDropdownItem(value: 'Procedures & Approvals (إجراءات وموافقات وفحص)', label: 'إجراءات وموافقات وفحص'),
                          SearchableDropdownItem(value: 'Inland Transport (نقل بري وشاحنات)', label: 'نقل بري وشاحنات'),
                          SearchableDropdownItem(value: 'Port & Handling (موانئ وتعتيق وتفريغ)', label: 'موانئ وتعتيق وتفريغ'),
                          SearchableDropdownItem(value: 'Other Fees (مصاريف أخرى)', label: 'مصاريف أخرى'),
                        ],
                        onChanged: (v) => setState(() => _mgmtExpenseCategory = v ?? 'All'),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                      onPressed: _showAddExpenseTypeDialog,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('تكويد نوع مصروف جديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Table of Expenses
            Expanded(
              child: Card(
                elevation: 2,
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppTheme.charcoal),
                    headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    columns: const [
                      DataColumn(label: Text('الكود')),
                      DataColumn(label: Text('اسم المصروف (عربي)')),
                      DataColumn(label: Text('اسم المصروف (إنجليزي)')),
                      DataColumn(label: Text('التصنيف')),
                      DataColumn(label: Text('وحدة الحساب')),
                      DataColumn(label: Text('العملة الافتراضية')),
                    ],
                    rows: filtered.map((exp) {
                      return DataRow(
                        cells: [
                          DataCell(Text(exp.expenseCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                          DataCell(Text(exp.nameAr, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(exp.nameEn ?? '-')),
                          DataCell(Text(exp.category.split('(').first.trim())),
                          DataCell(Text(exp.defaultUnit)),
                          DataCell(Text(exp.defaultCurrency)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  void _showAddExpenseTypeDialog() {
    final codeCtrl = TextEditingController();
    final nameArCtrl = TextEditingController();
    final nameEnCtrl = TextEditingController();
    String category = 'Clearance Fees (أتعاب ومصاريف تخليص)';
    String defaultUnit = 'Per Invoice (لكل فاتورة)';
    String currency = 'EGP';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('تكويد نوع مصروف جديد في الدليل', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(labelText: 'كود المصروف (مثال: EXP-CLR-050)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameArCtrl,
                  decoration: const InputDecoration(labelText: 'اسم المصروف بالعربية *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameEnCtrl,
                  decoration: const InputDecoration(labelText: 'اسم المصروف بالإنجليزية (اختياري)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                SearchableDropdownField<String>(
                  value: category,
                  labelText: 'التصنيف',
                  searchHintText: 'ابحث عن التصنيف...',
                  items: const [
                    SearchableDropdownItem(value: 'Clearance Fees (أتعاب ومصاريف تخليص)', label: 'Clearance Fees (أتعاب ومصاريف تخليص)'),
                    SearchableDropdownItem(value: 'Procedures & Approvals (إجراءات وموافقات وفحص)', label: 'Procedures & Approvals (إجراءات وموافقات وفحص)'),
                    SearchableDropdownItem(value: 'Inland Transport (نقل بري وشاحنات)', label: 'Inland Transport (نقل بري وشاحنات)'),
                    SearchableDropdownItem(value: 'Port & Handling (موانئ وتعتيق وتفريغ)', label: 'Port & Handling (موانئ وتعتيق وتفريغ)'),
                    SearchableDropdownItem(value: 'Other Fees (مصاريف أخرى)', label: 'Other Fees (مصاريف أخرى)'),
                  ],
                  onChanged: (v) => setDlgState(() => category = v ?? category),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: defaultUnit,
                        decoration: const InputDecoration(labelText: 'وحدة الحساب الافتراضية', border: OutlineInputBorder()),
                        onChanged: (v) => defaultUnit = v,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SearchableDropdownField<String>(
                        value: currency,
                        labelText: 'العملة الافتراضية',
                        searchHintText: 'ابحث عن العملة...',
                        items: const [
                          SearchableDropdownItem(value: 'EGP', label: 'EGP'),
                          SearchableDropdownItem(value: 'USD', label: 'USD'),
                          SearchableDropdownItem(value: 'EUR', label: 'EUR'),
                        ],
                        onChanged: (v) => setDlgState(() => currency = v ?? 'EGP'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald),
              onPressed: () async {
                final nameAr = nameArCtrl.text.trim();
                if (nameAr.isEmpty) return;
                try {
                  await ref.read(clearanceExpenseTypesProvider.notifier).createExpenseType({
                    'expense_code': codeCtrl.text.trim().isNotEmpty ? codeCtrl.text.trim() : 'EXP-${DateTime.now().millisecondsSinceEpoch % 1000}',
                    'name_ar': nameAr,
                    'name_en': nameEnCtrl.text.trim().isNotEmpty ? nameEnCtrl.text.trim() : null,
                    'category': category,
                    'default_unit': defaultUnit,
                    'default_currency': currency,
                    'display_order': 99,
                    'is_active': true,
                  });
                  if (mounted) Navigator.pop(ctx);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
                }
              },
              child: const Text('حفظ المصروف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

}
