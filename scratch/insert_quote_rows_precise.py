path = r"c:\Users\Hp\Desktop\ImportFlow\frontend\lib\features\shipping_scenarios\screens\shipping_scenarios_screen.dart"
with open(path, "r", encoding="utf-8") as f:
    lines = f.readlines()

target_idx = -1
for i, line in enumerate(lines):
    if "rowKey: 'othersFee_" in line:
        target_idx = i
        break

print(f"Found othersFee at line {target_idx}")

# Find the closing of _buildCostRow (the closing parenthesis followed by comma)
end_idx = -1
for i in range(target_idx, target_idx + 20):
    if lines[i].strip() == "),":
        end_idx = i
        break

print(f"Ending at line {end_idx}: {repr(lines[end_idx])}")

new_rows = """                                     _buildCostRow(
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
                                     ),
"""

lines.insert(end_idx + 1, new_rows)

with open(path, "w", encoding="utf-8") as f:
    f.writelines(lines)

print("Successfully inserted 3 new cost rows!")
