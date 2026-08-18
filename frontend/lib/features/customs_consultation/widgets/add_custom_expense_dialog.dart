import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../models/customs_consultation_model.dart';

class AddCustomExpenseDialog extends StatefulWidget {
  final Function(CustomsBrokerQuoteItemModel) onExpenseAdded;

  const AddCustomExpenseDialog({
    super.key,
    required this.onExpenseAdded,
  });

  @override
  State<AddCustomExpenseDialog> createState() => _AddCustomExpenseDialogState();
}

class _AddCustomExpenseDialogState extends State<AddCustomExpenseDialog> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController(text: '0.0');
  final _qtyCtrl = TextEditingController(text: '1.0');
  String _selectedCategory = 'Other Fees (مصاريف أخرى)';
  String _selectedUnit = 'Fixed (مبلغ ثابت)';
  String _selectedCurrency = 'EGP';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
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
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'اسم المصروف / البند *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SearchableDropdownField<String>(
              value: _selectedCategory,
              labelText: 'التصنيف',
              items: const [
                SearchableDropdownItem(value: 'Clearance Fees (أتعاب التخليص)', label: 'Clearance Fees (أتعاب التخليص)'),
                SearchableDropdownItem(value: 'Port & Storage (رسوم الميناء والأرضيات)', label: 'Port & Storage (رسوم الميناء والأرضيات)'),
                SearchableDropdownItem(value: 'Inspection & Lab (الفحص والمعامل)', label: 'Inspection & Lab (الفحص والمعامل)'),
                SearchableDropdownItem(value: 'Inland Transport (النولون الداخلي والنقل)', label: 'Inland Transport (النولون الداخلي والنقل)'),
                SearchableDropdownItem(value: 'Other Fees (مصاريف أخرى)', label: 'Other Fees (مصاريف أخرى)'),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _selectedCategory = v);
              },
            ),
            const SizedBox(height: 12),
            SearchableDropdownField<String>(
              value: _selectedUnit,
              labelText: 'وحدة الاحتساب',
              items: const [
                SearchableDropdownItem(value: 'Fixed (مبلغ ثابت)', label: 'Fixed (مبلغ ثابت)'),
                SearchableDropdownItem(value: 'Per Container (لكل حاوية)', label: 'Per Container (لكل حاوية)'),
                SearchableDropdownItem(value: 'Per Ton (لكل طن)', label: 'Per Ton (لكل طن)'),
                SearchableDropdownItem(value: 'Per Shipment (لكل إقرار / بوليصة)', label: 'Per Shipment (لكل إقرار / بوليصة)'),
                SearchableDropdownItem(value: 'Per Truck (لكل سيارة نقل)', label: 'Per Truck (لكل سيارة نقل)'),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _selectedUnit = v);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'سعر الوحدة', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SearchableDropdownField<String>(
                    value: _selectedCurrency,
                    labelText: 'العملة',
                    items: const [
                      SearchableDropdownItem(value: 'EGP', label: 'EGP'),
                      SearchableDropdownItem(value: 'USD', label: 'USD'),
                      SearchableDropdownItem(value: 'EUR', label: 'EUR'),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedCurrency = v);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _qtyCtrl,
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
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;
            final price = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;
            final qty = double.tryParse(_qtyCtrl.text.trim()) ?? 1.0;
            widget.onExpenseAdded(CustomsBrokerQuoteItemModel(
              expenseName: name,
              category: _selectedCategory,
              unitType: _selectedUnit,
              unitPrice: price,
              currency: _selectedCurrency,
              qty: qty,
              isApplicable: true,
              totalAmount: price * qty,
            ));
            Navigator.pop(context);
          },
          child: const Text('إضافة البند للعرض', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
