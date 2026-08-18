import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../models/customs_consultation_model.dart';

class AddCustomBrokerExpenseRowDialog extends StatefulWidget {
  const AddCustomBrokerExpenseRowDialog({super.key});

  @override
  State<AddCustomBrokerExpenseRowDialog> createState() => _AddCustomBrokerExpenseRowDialogState();
}

class _AddCustomBrokerExpenseRowDialogState extends State<AddCustomBrokerExpenseRowDialog> {
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController(text: '0.0');
  final qtyCtrl = TextEditingController(text: '1.0');
  String selectedCategory = 'Other Fees (مصاريف أخرى)';
  String selectedUnit = 'Fixed (مبلغ ثابت)';
  String selectedCurrency = 'EGP';

  @override
  void dispose() {
    nameCtrl.dispose();
    priceCtrl.dispose();
    qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.add_circle, color: AppTheme.cobalt),
          SizedBox(width: 8),
          Text('إضافة بند مصروف تخليص / نقل مخصص', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'اسم البند / نوع المصروف *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            SearchableDropdownField<String>(
              value: selectedCategory,
              labelText: 'التصنيف',
              searchHintText: 'ابحث عن التصنيف...',
              items: const [
                SearchableDropdownItem(value: 'Clearance Fees (أتعاب ومصاريف تخليص)', label: 'أتعاب ومصاريف تخليص'),
                SearchableDropdownItem(value: 'Procedures & Approvals (إجراءات وموافقات وفحص)', label: 'إجراءات وموافقات وفحص'),
                SearchableDropdownItem(value: 'Inland Transport (نقل بري وشاحنات)', label: 'نقل بري وشاحنات'),
                SearchableDropdownItem(value: 'Port & Handling (موانئ وتعتيق وتفريغ)', label: 'موانئ وتعتيق وتفريغ'),
                SearchableDropdownItem(value: 'Other Fees (مصاريف أخرى)', label: 'مصاريف أخرى'),
              ],
              onChanged: (v) => setState(() => selectedCategory = v ?? selectedCategory),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'السعر', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SearchableDropdownField<String>(
                    value: selectedCurrency,
                    labelText: 'العملة',
                    searchHintText: 'ابحث عن العملة...',
                    items: const [
                      SearchableDropdownItem(value: 'EGP', label: 'EGP'),
                      SearchableDropdownItem(value: 'USD', label: 'USD'),
                      SearchableDropdownItem(value: 'EUR', label: 'EUR'),
                    ],
                    onChanged: (v) => setState(() => selectedCurrency = v ?? 'EGP'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: qtyCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'الكمية', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald),
          onPressed: () {
            final name = nameCtrl.text.trim();
            if (name.isEmpty) return;
            final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
            final qty = double.tryParse(qtyCtrl.text.trim()) ?? 1.0;
            final newItem = CustomsBrokerQuoteItemModel(
              expenseName: name,
              category: selectedCategory,
              unitType: selectedUnit,
              unitPrice: price,
              currency: selectedCurrency,
              qty: qty,
              isApplicable: true,
              totalAmount: price * qty,
            );
            Navigator.pop(context, newItem);
          },
          child: const Text('إضافة البند للعرض', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
