path = r"c:\Users\Hp\Desktop\ImportFlow\frontend\lib\features\shipping_scenarios\screens\shipping_scenarios_screen.dart"
with open(path, "r", encoding="utf-8") as f:
    content = f.read()

target = """                                     _buildCostRow(
                                       rowKey: 'othersFee_$idx',
                                       title: '14. مصاريف ومصاريف أخرى (Others)',
                                       applicable: item.othersFeeApplicable,
                                       price: item.othersFeePrice,
                                       currency: item.othersFeeCurrency,
                                       onApplicableChanged: (v) => _updateItem(idx, item.copyWith(othersFeeApplicable: v), currenciesList),
                                       onPriceChanged: (v) => _updateItem(idx, item.copyWith(othersFeePrice: v), currenciesList),
                                       onCurrencyChanged: (v) => _updateItem(idx, item.copyWith(othersFeeCurrency: v), currenciesList),
                                       currenciesList: currenciesList,
                                     ),"""

replacement = """                                     _buildCostRow(
                                       rowKey: 'othersFee_$idx',
                                       title: '14. مصاريف ومصاريف أخرى (Others)',
                                       applicable: item.othersFeeApplicable,
                                       price: item.othersFeePrice,
                                       currency: item.othersFeeCurrency,
                                       onApplicableChanged: (v) => _updateItem(idx, item.copyWith(othersFeeApplicable: v), currenciesList),
                                       onPriceChanged: (v) => _updateItem(idx, item.copyWith(othersFeePrice: v), currenciesList),
                                       onCurrencyChanged: (v) => _updateItem(idx, item.copyWith(othersFeeCurrency: v), currenciesList),
                                       currenciesList: currenciesList,
                                     ),
                                     _buildCostRow(
                                       rowKey: 'dthc_$idx',
                                       title: '15. تفريغ ومناولة ميناء الوصول (DTHC)',
                                       applicable: item.dthcApplicable,
                                       price: item.dthcPrice,
                                       currency: item.dthcCurrency,
                                       onApplicableChanged: (v) => _updateItem(idx, item.copyWith(dthcApplicable: v), currenciesList),
                                       onPriceChanged: (v) => _updateItem(idx, item.copyWith(dthcPrice: v), currenciesList),
                                       onCurrencyChanged: (v) => _updateItem(idx, item.copyWith(dthcCurrency: v), currenciesList),
                                       currenciesList: currenciesList,
                                     ),
                                     _buildCostRow(
                                       rowKey: 'storagePerWeek_$idx',
                                       title: '16. أرضيات / تخزين لأول أسبوع (Storage per one week)',
                                       applicable: item.storagePerWeekApplicable,
                                       price: item.storagePerWeekPrice,
                                       currency: item.storagePerWeekCurrency,
                                       onApplicableChanged: (v) => _updateItem(idx, item.copyWith(storagePerWeekApplicable: v), currenciesList),
                                       onPriceChanged: (v) => _updateItem(idx, item.copyWith(storagePerWeekPrice: v), currenciesList),
                                       onCurrencyChanged: (v) => _updateItem(idx, item.copyWith(storagePerWeekCurrency: v), currenciesList),
                                       currenciesList: currenciesList,
                                     ),
                                     _buildCostRow(
                                       rowKey: 'extraDayStorage_$idx',
                                       title: '17. أرضيات / تخزين لليوم الإضافي (Extra day storage)',
                                       applicable: item.extraDayStorageApplicable,
                                       price: item.extraDayStoragePrice,
                                       currency: item.extraDayStorageCurrency,
                                       onApplicableChanged: (v) => _updateItem(idx, item.copyWith(extraDayStorageApplicable: v), currenciesList),
                                       onPriceChanged: (v) => _updateItem(idx, item.copyWith(extraDayStoragePrice: v), currenciesList),
                                       onCurrencyChanged: (v) => _updateItem(idx, item.copyWith(extraDayStorageCurrency: v), currenciesList),
                                       currenciesList: currenciesList,
                                     ),"""

if target in content:
    content = content.replace(target, replacement, 1)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print("Successfully replaced!")
else:
    print("Target not found!")
