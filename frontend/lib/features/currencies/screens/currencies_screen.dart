import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';
import '../../../core/widgets/master_data_toolbar.dart';
import '../../../core/widgets/row_actions_pill.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/network/api_client.dart';
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
  int _currentPage = 1;
  int _pageSize = 25;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currenciesProvider.notifier).fetchCurrencies();
    });
  }

  Future<void> _syncOfficialCustomsExchangeRates(BuildContext context) async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post('/integrations/nafeza/exchange-rates/sync');
      ref.read(currenciesProvider.notifier).fetchCurrencies();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.emerald,
            content: Text(res.data['message_ar'] ?? 'تم تحديث أسعار الصرف الجمركية الرسمية بنجاح ✅'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.crimson,
            content: Text('فشل مزامنة أسعار الصرف الجمركية: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    final l10n = context.l10n;
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.currenciesScreenTitle,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.charcoal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.currenciesScreenSubtitle,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    const BackToDashboardButton(),
                    ElevatedButton.icon(
                      onPressed: () => _showCurrencyConverterDialog(context),
                      icon: const Icon(Icons.currency_exchange, size: 18),
                      label: Text(l10n.liveCurrencyConverterBtn),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cobalt,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showGainLossCalculatorDialog(context),
                      icon: const Icon(Icons.trending_up, size: 18),
                      label: Text(l10n.currencyGainLossBtn),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _syncOfficialCustomsExchangeRates(context),
                      icon: const Icon(Icons.sync, size: 18),
                      label: const Text('مزامنة أسعار الصرف الجمركية'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.charcoal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddRateDialog(context),
                      icon: const Icon(Icons.rate_review, size: 18),
                      label: Text(l10n.updateExchangeRatesBtn),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),

                    ElevatedButton.icon(
                      onPressed: () => _showCurrencyDialog(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l10n.addCurrencyBtn),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.charcoal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Data Actions Toolbar
            MasterDataToolbarWidget(
              moduleEndpoint: 'currencies',
              title: 'Currencies',
              onRefreshNeeded: () => ref.read(currenciesProvider.notifier).fetchCurrencies(),
            ),

            const SizedBox(height: 16),

            // Search input
            Row(
              children: [
                SizedBox(
                  width: 320,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: l10n.searchCurrenciesHint,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _currentPage = 1;
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
                        _currentPage = 1;
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
                  child: Text(l10n.currenciesFetchError(err.toString()), style: const TextStyle(color: AppTheme.crimson)),
                ),
                data: (currencies) {
                  if (currencies.isEmpty) {
                    return Center(
                      child: Text(l10n.noCurrenciesFound, style: const TextStyle(color: Colors.grey, fontSize: 15)),
                    );
                  }

                  final totalItems = currencies.length;
                  final totalPages = (totalItems / _pageSize).ceil();
                  final safeCurrentPage = _currentPage > totalPages && totalPages > 0 ? totalPages : _currentPage;
                  final startIndex = (safeCurrentPage - 1) * _pageSize;
                  final endIndex = (startIndex + _pageSize < totalItems) ? startIndex + _pageSize : totalItems;
                  final pagedCurrencies = totalItems > 0 && startIndex < totalItems
                      ? currencies.sublist(startIndex, endIndex)
                      : <CurrencyModel>[];

                  return Column(
                    children: [
                      Expanded(
                        child: Container(
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
                                6: FixedColumnWidth(150),
                              },
                              children: [
                                // Header
                                TableRow(
                                  decoration: const BoxDecoration(color: AppTheme.charcoal),
                                  children: [
                                    l10n.isoCodeCol,
                                    l10n.currencyNameCol,
                                    l10n.currencySymbolCol,
                                    l10n.commercialRateBankCol,
                                    l10n.customsRateOfficialCol,
                                    l10n.statusCol,
                                    l10n.actionsCol,
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
                                ...pagedCurrencies.asMap().entries.map((entry) {
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
                                              Padding(
                                                padding: const EdgeInsets.only(left: 4),
                                                child: Tooltip(
                                                  message: l10n.baseCurrencyTooltip,
                                                  child: const Icon(Icons.star, size: 14, color: AppTheme.emerald),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),

                                      // Currency Name
                                      _cell(
                                        child: InkWell(
                                          onTap: () => _showCurrencyRateHistoryDialog(context, ref, c),
                                          borderRadius: BorderRadius.circular(6),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    c.currencyName,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                      color: isActive ? AppTheme.cobalt : Colors.grey.shade700,
                                                      decoration: isActive ? TextDecoration.none : TextDecoration.lineThrough,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Tooltip(
                                                  message: l10n.viewRateHistoryTooltip,
                                                  child: Icon(
                                                    Icons.history_edu,
                                                    size: 16,
                                                    color: AppTheme.cobalt.withOpacity(0.7),
                                                  ),
                                                ),
                                              ],
                                            ),
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
                                            ? Text(l10n.baseCurrencyRateLabel, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald))
                                            : Text(
                                                c.latestCommercialRate != null
                                                    ? l10n.rateToEgpFormatted(c.currencyCode, c.latestCommercialRate!.toStringAsFixed(4))
                                                    : l10n.rateNotSet,
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt),
                                              ),
                                      ),

                                      // Customs Rate
                                      _cell(
                                        child: c.isBaseCurrency
                                            ? Text(l10n.baseCurrencyRateLabel, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald))
                                            : Text(
                                                c.latestCustomsRate != null
                                                    ? l10n.rateToEgpFormatted(c.currencyCode, c.latestCustomsRate!.toStringAsFixed(4))
                                                    : l10n.rateNotSet,
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
                                            isActive ? l10n.statusActive : l10n.statusInactive,
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
                                        child: RowActionsPill(
                                          onView: () => _showCurrencyRateHistoryDialog(context, ref, c),
                                          onEdit: () => _showCurrencyDialog(context, currency: c),
                                          onPrint: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(l10n.printCurrencyDetailsSnack(c.currencyCode, c.currencyName)),
                                                backgroundColor: AppTheme.charcoal,
                                                duration: const Duration(seconds: 2),
                                              ),
                                            );
                                          },
                                          onDelete: c.isBaseCurrency
                                              ? null
                                              : () async {
                                                  final confirm = await showDialog<bool>(
                                                    context: context,
                                                    builder: (ctx) => AlertDialog(
                                                      title: Text(l10n.confirmActionTitle),
                                                      content: Text(isActive
                                                          ? l10n.confirmDeactivateCurrency(c.currencyCode, c.currencyName)
                                                          : l10n.confirmActivateCurrency(c.currencyCode, c.currencyName)),
                                                      actions: [
                                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
                                                        ElevatedButton(
                                                          onPressed: () => Navigator.pop(ctx, true),
                                                          style: ElevatedButton.styleFrom(backgroundColor: isActive ? AppTheme.crimson : AppTheme.emerald),
                                                          child: Text(isActive ? l10n.deactivateBtn : l10n.activateBtn, style: const TextStyle(color: Colors.white)),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                  if (confirm == true && c.currencyId != null) {
                                                    ref.read(currenciesProvider.notifier).toggleActive(c.currencyId!, isActive);
                                                  }
                                                },
                                          deleteTooltip: c.isBaseCurrency
                                              ? l10n.cannotDeactivateBaseCurrencyTooltip
                                              : (isActive ? l10n.deactivateCurrencyTooltip : l10n.activateCurrencyTooltip),
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
                  ),
                ),
                const SizedBox(height: 10),
                // Pagination Footer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.showingCurrenciesCount(totalItems == 0 ? 0 : startIndex + 1, endIndex, totalItems),
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                      ),
                      Row(
                        children: [
                          Text(l10n.rowsPerPageLabel, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          DropdownButton<int>(
                            value: _pageSize,
                            underline: const SizedBox(),
                            isDense: true,
                            items: [15, 25, 50, 100]
                                .map((s) => DropdownMenuItem(value: s, child: Text('$s', style: const TextStyle(fontSize: 12))))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _pageSize = val;
                                  _currentPage = 1;
                                });
                              }
                            },
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.first_page, size: 20),
                            onPressed: safeCurrentPage > 1 ? () => setState(() => _currentPage = 1) : null,
                            tooltip: l10n.firstPageTooltip,
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_left, size: 20),
                            onPressed: safeCurrentPage > 1 ? () => setState(() => _currentPage = safeCurrentPage - 1) : null,
                            tooltip: l10n.previousPageTooltip,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              l10n.pageOfTotal(safeCurrentPage, totalPages == 0 ? 1 : totalPages),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, size: 20),
                            onPressed: safeCurrentPage < totalPages ? () => setState(() => _currentPage = safeCurrentPage + 1) : null,
                            tooltip: l10n.nextPageTooltip,
                          ),
                          IconButton(
                            icon: const Icon(Icons.last_page, size: 20),
                            onPressed: safeCurrentPage < totalPages ? () => setState(() => _currentPage = totalPages) : null,
                            tooltip: l10n.lastPageTooltip,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
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
    final l10n = context.l10n;
    final formKey = GlobalKey<FormState>();
    final codeCtrl = TextEditingController(text: currency?.currencyCode ?? '');
    final nameCtrl = TextEditingController(text: currency?.currencyName ?? '');
    final symbolCtrl = TextEditingController(text: currency?.currencySymbol ?? '');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(currency == null ? l10n.addCurrencyDialogTitle : l10n.editCurrencyDialogTitle(currency.currencyCode)),
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
                  decoration: InputDecoration(
                    labelText: l10n.isoCodeLabel,
                    hintText: l10n.isoCodeHint,
                  ),
                  validator: (v) => v == null || v.trim().length != 3 ? l10n.isoCodeLengthError : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.currencyNameLabel,
                    hintText: l10n.currencyNameHint,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? l10n.requiredField : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: symbolCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.currencySymbolLabel,
                    hintText: l10n.currencySymbolHint,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? l10n.requiredField : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(l10n.cancel),
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
            child: Text(currency == null ? l10n.createCurrencySubmitBtn : l10n.saveChangesSubmitBtn),
          ),
        ],
      ),
    );
  }

  Widget _historyStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCurrencyRateHistoryDialog(BuildContext context, WidgetRef ref, CurrencyModel initialCurrency) {
    if (initialCurrency.currencyId == null) return;
    final l10n = context.l10n;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 850,
          constraints: const BoxConstraints(maxHeight: 720),
          padding: const EdgeInsets.all(24),
          child: FutureBuilder<CurrencyModel?>(
            future: ref.read(currenciesProvider.notifier).fetchCurrencyHistory(initialCurrency.currencyId!),
            builder: (context, snapshot) {
              final currency = snapshot.data ?? initialCurrency;
              final isLoading = snapshot.connectionState == ConnectionState.waiting;
              final rates = currency.exchangeRates ?? [];

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dialog Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: (currency.isBaseCurrency ? AppTheme.emerald : AppTheme.cobalt),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${currency.currencyCode} (${currency.currencySymbol})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.exchangeRateHistoryTitle(currency.currencyName),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.charcoal,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currency.isBaseCurrency
                                    ? l10n.baseCurrencySystemDesc
                                    : l10n.rateHistorySubtitle,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 24, thickness: 1),

                  // Top Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _historyStatCard(
                          title: l10n.currentCommercialRateStat,
                          value: currency.isBaseCurrency
                              ? '1.0000 EGP'
                              : (currency.latestCommercialRate != null
                                  ? '${currency.latestCommercialRate!.toStringAsFixed(4)} EGP'
                                  : l10n.notSetLabel),
                          icon: Icons.account_balance,
                          color: AppTheme.cobalt,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _historyStatCard(
                          title: l10n.currentCustomsRateStat,
                          value: currency.isBaseCurrency
                              ? '1.0000 EGP'
                              : (currency.latestCustomsRate != null
                                  ? '${currency.latestCustomsRate!.toStringAsFixed(4)} EGP'
                                  : l10n.notSetLabel),
                          icon: Icons.gavel,
                          color: AppTheme.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _historyStatCard(
                          title: l10n.rateSpreadStat,
                          value: (currency.latestCommercialRate != null && currency.latestCustomsRate != null)
                              ? '${(currency.latestCommercialRate! - currency.latestCustomsRate!).toStringAsFixed(4)} EGP'
                              : '0.0000 EGP',
                          icon: Icons.compare_arrows,
                          color: AppTheme.emerald,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _historyStatCard(
                          title: l10n.historicalUpdatesCountStat,
                          value: l10n.recordsCountBadge(rates.length),
                          icon: Icons.history,
                          color: AppTheme.charcoal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Action Button
                  if (!currency.isBaseCurrency)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.exchangeRateTimelineHeader,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showAddRateDialog(context, preSelectedCurrencyId: currency.currencyId);
                          },
                          icon: const Icon(Icons.add_chart, size: 16, color: Colors.white),
                          label: Text(l10n.recordNewExchangeRateBtn,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.emerald,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),

                  // History Table
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator(color: AppTheme.cobalt))
                        : (currency.isBaseCurrency
                            ? Center(
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.green.shade200),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check_circle_outline, color: AppTheme.emerald, size: 48),
                                      const SizedBox(height: 12),
                                      Text(
                                        l10n.baseCurrencyNoticeTitle,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        l10n.baseCurrencyNoticeSubtitle,
                                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : (rates.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.history_toggle_off, size: 48, color: Colors.grey.shade400),
                                        const SizedBox(height: 12),
                                        Text(
                                          l10n.noRateHistoryForCurrency(currency.currencyCode),
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            _showAddRateDialog(context, preSelectedCurrencyId: currency.currencyId);
                                          },
                                          icon: const Icon(Icons.add, size: 16, color: Colors.white),
                                          label: Text(l10n.recordFirstExchangeRateBtn,
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.cobalt,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: ListView.separated(
                                        itemCount: rates.length,
                                        separatorBuilder: (_, __) => const Divider(height: 1),
                                        itemBuilder: (context, idx) {
                                          final rate = rates[idx];
                                          final diff = rate.commercialRate - rate.customsRate;
                                          final diffPct = rate.customsRate > 0 ? (diff / rate.customsRate) * 100 : 0.0;
                                          final isLatest = idx == 0;

                                          return Container(
                                            color: isLatest ? AppTheme.cobalt.withOpacity(0.04) : Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            child: Row(
                                              children: [
                                                // Date Badge
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: isLatest ? AppTheme.cobalt : Colors.grey.shade100,
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: isLatest ? AppTheme.cobalt : Colors.grey.shade300),
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      Text(
                                                        rate.effectiveDate,
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 12,
                                                          color: isLatest ? Colors.white : AppTheme.charcoal,
                                                        ),
                                                      ),
                                                      if (isLatest)
                                                        Text(
                                                          l10n.currentActiveRateBadge,
                                                          style: const TextStyle(fontSize: 9, color: Colors.white70, fontWeight: FontWeight.bold),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 16),

                                                // Commercial Rate
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(l10n.commercialBankRateLabel,
                                                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        '${rate.commercialRate.toStringAsFixed(4)} EGP',
                                                        style: const TextStyle(
                                                            fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.cobalt),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                // Customs Rate
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(l10n.customsExchangeRateLabel,
                                                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        '${rate.customsRate.toStringAsFixed(4)} EGP',
                                                        style: const TextStyle(
                                                            fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.orange),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                // Variance / Spread
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(l10n.spreadVarianceLabel,
                                                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        '${diff >= 0 ? "+" : ""}${diff.toStringAsFixed(4)} (${diffPct >= 0 ? "+" : ""}${diffPct.toStringAsFixed(2)}%)',
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 12,
                                                          color: diff.abs() > 0.5 ? AppTheme.crimson : AppTheme.emerald,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                // Source / Created By
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade100,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    l10n.rateSourcePrefix(rate.createdBy ?? "System"),
                                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ))),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showAddRateDialog(BuildContext context, {int? preSelectedCurrencyId}) {
    final l10n = context.l10n;
    final formKey = GlobalKey<FormState>();
    final currencies = ref.read(currenciesProvider).value?.where((c) => !c.isBaseCurrency).toList() ?? [];
    if (currencies.isEmpty) return;

    int selectedCurrencyId = preSelectedCurrencyId ?? currencies.first.currencyId!;
    final commCtrl = TextEditingController();
    final custCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.updateExchangeRatesDialogTitle),
          content: SizedBox(
            width: 450,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SearchableDropdownField<int?>(
                    value: selectedCurrencyId,
                    labelText: l10n.selectForeignCurrencyLabel,
                    searchHintText: l10n.searchCurrenciesHint,
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
                    decoration: InputDecoration(
                      labelText: l10n.commercialRateInputLabel,
                      hintText: l10n.rateInputHint,
                    ),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n <= 0) return l10n.enterValidRateError;
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: custCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: l10n.customsRateInputLabel,
                      hintText: l10n.rateInputHint,
                    ),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n <= 0) return l10n.enterValidRateError;
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: Text(l10n.effectiveDateLabel(selectedDate.toIso8601String().split('T').first)),
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
              child: Text(l10n.cancel),
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
              child: Text(l10n.saveRateSubmitBtn),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Multi-Currency Conversion Dialog ─────────────────────────────────────

  void _showCurrencyConverterDialog(BuildContext context) {
    final l10n = context.l10n;
    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController(text: '10000');
    String fromCurr = 'USD';
    String toCurr = 'EGP';
    String rateType = 'commercial';
    Map<String, dynamic>? resultData;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setSheetState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              const Icon(Icons.currency_exchange, color: AppTheme.cobalt),
              const SizedBox(width: 8),
              Text(l10n.liveCurrencyConverterDialogTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.liveCurrencyConverterDialogSubtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: l10n.amountToConvertLabel,
                        hintText: l10n.amountToConvertHint,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final val = double.tryParse(v ?? '');
                        if (val == null || val <= 0) return l10n.enterValidAmountError;
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: fromCurr,
                            decoration: InputDecoration(labelText: l10n.fromCurrencyLabel, border: const OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'USD', child: Text('USD')),
                              DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                              DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                              DropdownMenuItem(value: 'CNY', child: Text('CNY')),
                              DropdownMenuItem(value: 'SAR', child: Text('SAR')),
                              DropdownMenuItem(value: 'AED', child: Text('AED')),
                              DropdownMenuItem(value: 'EGP', child: Text('EGP')),
                            ],
                            onChanged: (v) => setSheetState(() => fromCurr = v!),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: toCurr,
                            decoration: InputDecoration(labelText: l10n.toCurrencyLabel, border: const OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'EGP', child: Text('EGP')),
                              DropdownMenuItem(value: 'USD', child: Text('USD')),
                              DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                              DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                              DropdownMenuItem(value: 'CNY', child: Text('CNY')),
                            ],
                            onChanged: (v) => setSheetState(() => toCurr = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: rateType,
                      decoration: InputDecoration(labelText: l10n.appliedRateTypeLabel, border: const OutlineInputBorder()),
                      items: [
                        DropdownMenuItem(value: 'commercial', child: Text(l10n.rateTypeCommercialOption)),
                        DropdownMenuItem(value: 'customs', child: Text(l10n.rateTypeCustomsOption)),
                      ],
                      onChanged: (v) => setSheetState(() => rateType = v!),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cobalt,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(45),
                      ),
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (formKey.currentState!.validate()) {
                                setSheetState(() => isLoading = true);
                                final res = await ref.read(currenciesProvider.notifier).convertCurrency(
                                      amount: double.parse(amountCtrl.text.trim()),
                                      fromCurrency: fromCurr,
                                      toCurrency: toCurr,
                                      rateType: rateType,
                                    );
                                setSheetState(() {
                                  resultData = res;
                                  isLoading = false;
                                });
                              }
                            },
                      icon: isLoading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.calculate, color: Colors.white),
                      label: Text(l10n.convertCurrencyNowBtn, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    if (resultData != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.cobalt.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.cobalt.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(l10n.convertedAmountLabel, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(
                                  '${resultData!['converted_amount']} ${resultData!['to_currency_code']}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.cobalt),
                                ),
                              ],
                            ),
                            const Divider(height: 14),
                            Text(l10n.appliedRatePrefix(resultData!['applied_rate']), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(l10n.baseEgpEquivalentPrefix(resultData!['base_currency_equivalent_egp']), style: const TextStyle(fontSize: 12)),
                            if (resultData!['summary_ar'] != null && Localizations.localeOf(context).languageCode == 'ar') ...[
                              const SizedBox(height: 6),
                              Text(resultData!['summary_ar'] ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.charcoal)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(l10n.closeBtn),
            ),
          ],
        ),
      ),
    );
  }

  // ─── FX Gain / Loss Engine Dialog ─────────────────────────────────────────

  void _showGainLossCalculatorDialog(BuildContext context) {
    final l10n = context.l10n;
    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController(text: '50000');
    final initialRateCtrl = TextEditingController(text: '49.00');
    final settlementRateCtrl = TextEditingController(text: '47.50');
    String currencyCode = 'USD';
    Map<String, dynamic>? resultData;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setSheetState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              const Icon(Icons.trending_up, color: AppTheme.orange),
              const SizedBox(width: 8),
              Text(l10n.fxGainLossDialogTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.fxGainLossDialogSubtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: amountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(labelText: l10n.foreignAmountLabel, border: const OutlineInputBorder()),
                            validator: (v) {
                              final val = double.tryParse(v ?? '');
                              if (val == null || val <= 0) return l10n.enterValidAmountError;
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: currencyCode,
                            decoration: InputDecoration(labelText: l10n.currencyLabel, border: const OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'USD', child: Text('USD')),
                              DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                              DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                              DropdownMenuItem(value: 'CNY', child: Text('CNY')),
                            ],
                            onChanged: (v) => setSheetState(() => currencyCode = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: initialRateCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(labelText: l10n.initialRateLabel, hintText: l10n.initialRateHint, border: const OutlineInputBorder()),
                            validator: (v) {
                              final val = double.tryParse(v ?? '');
                              if (val == null || val <= 0) return l10n.enterValidRateError;
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: settlementRateCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(labelText: l10n.settlementRateLabel, hintText: l10n.settlementRateHint, border: const OutlineInputBorder()),
                            validator: (v) {
                              final val = double.tryParse(v ?? '');
                              if (val == null || val <= 0) return l10n.enterValidRateError;
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.orange,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(45),
                      ),
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (formKey.currentState!.validate()) {
                                setSheetState(() => isLoading = true);
                                final res = await ref.read(currenciesProvider.notifier).calculateGainLoss(
                                      foreignAmount: double.parse(amountCtrl.text.trim()),
                                      currencyCode: currencyCode,
                                      initialRate: double.parse(initialRateCtrl.text.trim()),
                                      settlementRate: double.parse(settlementRateCtrl.text.trim()),
                                    );
                                setSheetState(() {
                                  resultData = res;
                                  isLoading = false;
                                });
                              }
                            },
                      icon: isLoading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.analytics, color: Colors.white),
                      label: Text(l10n.calculateGainLossBtn, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    if (resultData != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: (resultData!['is_gain'] as bool) ? AppTheme.emerald.withOpacity(0.08) : AppTheme.crimson.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (resultData!['is_gain'] as bool) ? AppTheme.emerald.withOpacity(0.4) : AppTheme.crimson.withOpacity(0.4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (resultData!['is_gain'] as bool) ? AppTheme.emerald : AppTheme.crimson,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    resultData!['status_label'] ?? '',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                                Text(
                                  '${resultData!['variance_egp']} EGP (${resultData!['percentage_change']}%)',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: (resultData!['is_gain'] as bool) ? AppTheme.emerald : AppTheme.crimson,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 14),
                            Text(l10n.initialCostAtBooking(resultData!['initial_amount_egp'], resultData!['initial_rate'])),
                            const SizedBox(height: 4),
                            Text(l10n.actualCostAtSettlement(resultData!['settlement_amount_egp'], resultData!['settlement_rate'])),
                            if (resultData!['summary_ar'] != null && Localizations.localeOf(context).languageCode == 'ar') ...[
                              const SizedBox(height: 8),
                              Text(
                                resultData!['summary_ar'] ?? '',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.charcoal),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(l10n.closeBtn),
            ),
          ],
        ),
      ),
    );
  }
}


