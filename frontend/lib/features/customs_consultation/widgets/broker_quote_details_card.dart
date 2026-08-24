import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../models/customs_consultation_model.dart';
import '../../currencies/models/currency_model.dart';
import 'broker_cost_row.dart';

class BrokerQuoteDetailsCard extends StatelessWidget {
  final int? selectedBrokerId;
  final bool isLoadingPriceList;
  final List<CustomsBrokerQuoteItemModel> brokerQuoteItems;
  final String? brokerPriceListTitle;
  final String categoryFilter;
  final bool isExpanded;
  final List<CurrencyModel> currenciesList;
  final VoidCallback onToggleExpanded;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onAddCustomExpense;
  final VoidCallback onApplyAll;
  final VoidCallback onDisableAll;
  final Function(int, CustomsBrokerQuoteItemModel) onUpdateItem;

  const BrokerQuoteDetailsCard({
    super.key,
    required this.selectedBrokerId,
    required this.isLoadingPriceList,
    required this.brokerQuoteItems,
    required this.brokerPriceListTitle,
    required this.categoryFilter,
    required this.isExpanded,
    required this.currenciesList,
    required this.onToggleExpanded,
    required this.onCategoryChanged,
    required this.onAddCustomExpense,
    required this.onApplyAll,
    required this.onDisableAll,
    required this.onUpdateItem,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (selectedBrokerId == null) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l.selectBrokerFirstMsg,
                  style: const TextStyle(fontSize: 13, color: AppTheme.charcoal),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isLoadingPriceList) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: const Padding(
          padding: EdgeInsets.all(30),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(strokeWidth: 2.5),
                SizedBox(width: 14),
                Text('...', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      );
    }

    final totalBrokerFees = brokerQuoteItems.fold(0.0, (sum, itm) => sum + (itm.isApplicable ? itm.totalAmount : 0.0));
    final appliedCount = brokerQuoteItems.where((i) => i.isApplicable).length;

    final categories = [
      'All',
      'Clearance Fees',
      'Procedures & Approvals',
      'Inland Transport',
      'Port & Handling',
      'Other Fees',
    ];

    final filteredItems = categoryFilter == 'All'
        ? brokerQuoteItems
        : brokerQuoteItems.where((i) => i.category.contains(categoryFilter)).toList();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.request_quote, color: AppTheme.cobalt, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.clearanceQuotesTab,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal),
                      ),
                      if (brokerPriceListTitle != null)
                        Text(
                          brokerPriceListTitle!,
                          style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade700),
                        ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: AppTheme.cobalt),
                  onPressed: onAddCustomExpense,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(l.addCustomExpenseRow, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: AppTheme.charcoal),
                  tooltip: l.clearanceQuotesTab,
                  onPressed: onToggleExpanded,
                ),
              ],
            ),
            if (isExpanded) ...[
              const Divider(height: 20),

              // Category Filter Bar & Bulk Actions
              Row(
                children: [
                  Text('${l.filterCategoryLabel}: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: categories.map((cat) {
                          final isSelected = categoryFilter == cat;
                          final label = cat == 'All' ? l.allCategoriesItem : cat;
                          return Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: ChoiceChip(
                              label: Text(label, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                              selected: isSelected,
                              selectedColor: AppTheme.cobalt.withOpacity(0.15),
                              onSelected: (_) => onCategoryChanged(cat),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onApplyAll,
                    icon: const Icon(Icons.check_box_outlined, size: 14, color: AppTheme.emerald),
                    label: Text(l.applyAllQuoteItems, style: const TextStyle(fontSize: 11, color: AppTheme.emerald)),
                  ),
                  TextButton.icon(
                    onPressed: onDisableAll,
                    icon: const Icon(Icons.disabled_by_default_outlined, size: 14, color: Colors.red),
                    label: Text(l.disableAllQuoteItems, style: const TextStyle(fontSize: 11, color: Colors.red)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Items List
              if (filteredItems.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                  child: Text(l.noResultsFound),
                )
              else
                ...filteredItems.map((item) {
                  final idx = brokerQuoteItems.indexOf(item);
                  return buildBrokerCostRow(
                    context: context,
                    onUpdate: onUpdateItem,
                    index: idx,
                    item: item,
                    currenciesList: currenciesList,
                  );
                }),

              const Divider(height: 24),

              // Summary Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.cobalt.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.cobalt.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_balance_wallet, color: AppTheme.cobalt, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${l.totalExpenses} ($appliedCount):',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                        ),
                      ],
                    ),
                    Text(
                      '${totalBrokerFees.toStringAsFixed(2)} EGP',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.cobalt),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

