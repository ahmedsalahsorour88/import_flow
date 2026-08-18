import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/customs_consultation_model.dart';
import '../../currencies/models/currency_model.dart';

  Widget buildBrokerCostRow({
    required Function(int, CustomsBrokerQuoteItemModel) onUpdate,
    required int index,
    required CustomsBrokerQuoteItemModel item,
    required List<CurrencyModel> currenciesList,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: item.isApplicable ? AppTheme.emerald.withOpacity(0.04) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: item.isApplicable ? AppTheme.emerald.withOpacity(0.3) : Colors.grey.shade300),
      ),
      child: Row(
        children: [
          // Title & Category
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.expenseName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.category.split('(').first.trim()} | ${item.unitType}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Price field
          Expanded(
            flex: 2,
            child: TextFormField(
              key: ValueKey('price_${item.expenseTypeId ?? item.expenseName}_${item.unitPrice}'),
              initialValue: item.unitPrice == 0.0 ? '' : item.unitPrice.toString(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'سعر البند',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              onChanged: (v) {
                final p = double.tryParse(v) ?? 0.0;
                onUpdate(index, item.copyWith(unitPrice: p));
              },
            ),
          ),
          const SizedBox(width: 8),
          // Currency dropdown
          Expanded(
            flex: 2,
            child: SearchableDropdownField<String>(
              value: currenciesList.any((c) => c.currencyCode == item.currency)
                  ? item.currency
                  : (currenciesList.isNotEmpty ? currenciesList.first.currencyCode : 'EGP'),
              labelText: 'العملة',
              items: currenciesList
                  .map((c) => SearchableDropdownItem(
                        value: c.currencyCode,
                        label: '${c.currencyCode} (${c.currencySymbol})',
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  onUpdate(index, item.copyWith(currency: v));
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          // Qty field
          Expanded(
            flex: 1,
            child: TextFormField(
              key: ValueKey('qty_${item.expenseTypeId ?? item.expenseName}_${item.qty}'),
              initialValue: item.qty == 0.0 ? '1' : (item.qty == item.qty.roundToDouble() ? item.qty.toInt().toString() : item.qty.toString()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'الكمية',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              onChanged: (v) {
                final q = double.tryParse(v) ?? 1.0;
                onUpdate(index, item.copyWith(qty: q));
              },
            ),
          ),
          const SizedBox(width: 10),
          // Applicable switch
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: item.isApplicable,
                activeColor: AppTheme.emerald,
                onChanged: (v) => onUpdate(index, item.copyWith(isApplicable: v)),
              ),
              Text(
                item.isApplicable ? 'مطبق' : 'غير مطبق',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: item.isApplicable ? AppTheme.emerald : Colors.red.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          // Line total display
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: item.isApplicable ? AppTheme.emerald.withOpacity(0.12) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.isApplicable
                    ? '${(item.unitPrice * item.qty).toStringAsFixed(2)} ${item.currency}'
                    : '0.00 ${item.currency}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: item.isApplicable ? AppTheme.emerald : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
