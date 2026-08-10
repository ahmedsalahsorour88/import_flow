import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../models/currency_model.dart';
import '../providers/currencies_provider.dart';

class CurrenciesScreen extends ConsumerStatefulWidget {
  const CurrenciesScreen({super.key});

  @override
  ConsumerState<CurrenciesScreen> createState() => _CurrenciesScreenState();
}

class _CurrenciesScreenState extends ConsumerState<CurrenciesScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currenciesProvider.notifier).fetchCurrencies();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currenciesAsync = ref.watch(currenciesProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Title & Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Currencies & Exchange Rates (MD-004)',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.charcoal,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Manage Currency ISO Codes, Commercial Bank Rates & Official Customs Exchange Rates',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _showAddRateDialog(context),
                      icon: const Icon(Icons.rate_review, size: 18),
                      label: const Text('Update Exchange Rates'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showCurrencyDialog(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Currency'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cobalt,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search input
            Row(
              children: [
                SizedBox(
                  width: 320,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by ISO code (USD, EUR...) or name...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                                ref.read(currenciesProvider.notifier).fetchCurrencies(search: '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                      ref.read(currenciesProvider.notifier).fetchCurrencies(search: val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Table Content
            Expanded(
              child: currenciesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.cobalt)),
                error: (err, stack) => Center(
                  child: Text('Error loading currencies: $err', style: const TextStyle(color: AppTheme.crimson)),
                ),
                data: (currencies) {
                  if (currencies.isEmpty) {
                    return const Center(
                      child: Text('No currencies found.', style: TextStyle(color: Colors.grey, fontSize: 15)),
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: MediaQuery.of(context).size.width > 1100
                                  ? MediaQuery.of(context).size.width - 300
                                  : 900,
                            ),
                            child: Table(
                              columnWidths: const {
                                0: FixedColumnWidth(100),
                                1: FlexColumnWidth(3),
                                2: FixedColumnWidth(90),
                                3: FlexColumnWidth(2.5),
                                4: FlexColumnWidth(2.5),
                                5: FixedColumnWidth(85),
                                6: FixedColumnWidth(110),
                              },
                              children: [
                                // Header
                                TableRow(
                                  decoration: const BoxDecoration(color: AppTheme.charcoal),
                                  children: [
                                    'ISO Code',
                                    'Currency Name',
                                    'Symbol',
                                    'Commercial Rate (Bank)',
                                    'Customs Rate (Official)',
                                    'Status',
                                    'Actions'
                                  ]
                                      .map((h) => Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                            child: Text(
                                              h,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                ),

                                // Data Rows
                                ...currencies.asMap().entries.map((entry) {
                                  final c = entry.value;
                                  final isEven = entry.key % 2 == 0;
                                  final isActive = c.isActive;

                                  return TableRow(
                                    decoration: BoxDecoration(
                                      color: isEven ? Colors.white : Colors.grey.shade50,
                                    ),
                                    children: [
                                      // ISO Code
                                      _cell(
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: (c.isBaseCurrency ? AppTheme.emerald : AppTheme.cobalt).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                c.currencyCode,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: c.isBaseCurrency ? AppTheme.emerald : AppTheme.cobalt,
                                                ),
                                              ),
                                            ),
                                            if (c.isBaseCurrency)
                                              const Padding(
                                                padding: EdgeInsets.only(left: 4),
                                                child: Tooltip(
                                                  message: 'Base Currency (EGP)',
                                                  child: Icon(Icons.star, size: 14, color: AppTheme.emerald),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),

                                      // Currency Name
                                      _cell(
                                        child: Text(
                                          c.currencyName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: isActive ? AppTheme.charcoal : Colors.grey.shade700,
                                            decoration: isActive ? TextDecoration.none : TextDecoration.lineThrough,
                                          ),
                                        ),
                                      ),

                                      // Symbol
                                      _cell(
                                        child: Text(
                                          c.currencySymbol,
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                        ),
                                      ),

                                      // Commercial Rate
                                      _cell(
                                        child: c.isBaseCurrency
                                            ? const Text('1.0000 (Base)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald))
                                            : Text(
                                                c.latestCommercialRate != null
                                                    ? '1 ${c.currencyCode} = ${c.latestCommercialRate!.toStringAsFixed(4)} EGP'
                                                    : 'Not Set',
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt),
                                              ),
                                      ),

                                      // Customs Rate
                                      _cell(
                                        child: c.isBaseCurrency
                                            ? const Text('1.0000 (Base)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald))
                                            : Text(
                                                c.latestCustomsRate != null
                                                    ? '1 ${c.currencyCode} = ${c.latestCustomsRate!.toStringAsFixed(4)} EGP'
                                                    : 'Not Set',
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.orange),
                                              ),
                                      ),

                                      // Status
                                      _cell(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: (isActive ? AppTheme.emerald : AppTheme.crimson).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            isActive ? 'Active' : 'Inactive',
                                            style: TextStyle(
                                              color: isActive ? AppTheme.emerald : AppTheme.crimson,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Actions
                                      _cell(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: AppTheme.cobalt, size: 18),
                                              tooltip: 'Edit Currency',
                                              onPressed: () => _showCurrencyDialog(context, currency: c),
                                            ),
                                            if (!c.isBaseCurrency)
                                              Tooltip(
                                                message: isActive ? 'Deactivate Currency' : 'Reactivate Currency',
                                                child: Switch(
                                                  value: isActive,
                                                  activeColor: AppTheme.emerald,
                                                  inactiveThumbColor: AppTheme.crimson,
                                                  onChanged: (_) {
                                                    if (c.currencyId != null) {
                                                      ref.read(currenciesProvider.notifier).toggleActive(c.currencyId!, isActive);
                                                    }
                                                  },
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell({required Widget child}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Align(alignment: Alignment.centerLeft, child: child),
      );

  void _showCurrencyDialog(BuildContext context, {CurrencyModel? currency}) {
    final formKey = GlobalKey<FormState>();
    final codeCtrl = TextEditingController(text: currency?.currencyCode ?? '');
    final nameCtrl = TextEditingController(text: currency?.currencyName ?? '');
    final symbolCtrl = TextEditingController(text: currency?.currencySymbol ?? '');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(currency == null ? 'Add Currency' : 'Edit Currency (${currency.currencyCode})'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: codeCtrl,
                  enabled: currency == null,
                  maxLength: 3,
                  decoration: const InputDecoration(
                    labelText: 'ISO Currency Code (3 Letters) *',
                    hintText: 'e.g. USD, EUR, GBP, CNY',
                  ),
                  validator: (v) => v == null || v.trim().length != 3 ? 'Must be 3 uppercase letters' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Currency Name *',
                    hintText: 'e.g. US Dollar, Euro',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: symbolCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Currency Symbol *',
                    hintText: r'e.g. $, €, £, ¥',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, foregroundColor: Colors.white),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                if (currency == null) {
                  final newModel = CurrencyModel(
                    currencyCode: codeCtrl.text.trim().toUpperCase(),
                    currencyName: nameCtrl.text.trim(),
                    currencySymbol: symbolCtrl.text.trim(),
                  );
                  final ok = await ref.read(currenciesProvider.notifier).createCurrency(newModel);
                  if (ok && context.mounted) Navigator.pop(dialogCtx);
                } else {
                  final updateData = {
                    'currency_name': nameCtrl.text.trim(),
                    'currency_symbol': symbolCtrl.text.trim(),
                  };
                  final ok = await ref
                      .read(currenciesProvider.notifier)
                      .updateCurrency(currency.currencyId!, updateData);
                  if (ok && context.mounted) Navigator.pop(dialogCtx);
                }
              }
            },
            child: Text(currency == null ? 'Create Currency' : 'Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showAddRateDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final currencies = ref.read(currenciesProvider).value?.where((c) => !c.isBaseCurrency).toList() ?? [];
    if (currencies.isEmpty) return;

    int selectedCurrencyId = currencies.first.currencyId!;
    final commCtrl = TextEditingController();
    final custCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Update Exchange Rates (Commercial & Customs)'),
          content: SizedBox(
            width: 450,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SearchableDropdownField<int?>(
                    value: selectedCurrencyId,
                    labelText: 'Select Foreign Currency *',
                    searchHintText: 'ابحث عن العملة...',
                    items: currencies
                        .map((c) => SearchableDropdownItem<int?>(
                              value: c.currencyId,
                              label: '${c.currencyCode} — ${c.currencyName} (${c.currencySymbol})',
                              searchValue: '${c.currencyCode} ${c.currencyName}',
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => selectedCurrencyId = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: commCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Commercial Bank Rate to EGP *',
                      hintText: 'e.g. 50.25',
                    ),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Enter valid rate > 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: custCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Official Customs Exchange Rate to EGP *',
                      hintText: 'e.g. 50.10',
                    ),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Enter valid rate > 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: Text('Effective Date: ${selectedDate.toIso8601String().split('T').first}'),
                    trailing: const Icon(Icons.calendar_today, color: AppTheme.cobalt),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final rateModel = ExchangeRateModel(
                    currencyId: selectedCurrencyId,
                    commercialRate: double.parse(commCtrl.text.trim()),
                    customsRate: double.parse(custCtrl.text.trim()),
                    effectiveDate: selectedDate.toIso8601String().split('T').first,
                  );
                  final ok = await ref.read(currenciesProvider.notifier).addExchangeRate(rateModel);
                  if (ok && context.mounted) Navigator.pop(dialogCtx);
                }
              },
              child: const Text('Save Rate'),
            ),
          ],
        ),
      ),
    );
  }
}
