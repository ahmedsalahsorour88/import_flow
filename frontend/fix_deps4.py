def fix(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        text = f.read()
    
    import re
    good_func = """double _numToDouble(dynamic val, [double fallback = 0.0]) {
  if (val == null) return fallback;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? fallback;
  return fallback;
}"""
    text = re.sub(r'double _numToDouble\(dynamic val\)\s*\{[\s\S]*?return 0\.0;\s*\}', good_func, text)
    text = re.sub(r'double _numToDouble\(dynamic val, \[double fallback = 0\.0\]\)\s*\{[\s\S]*?return fallback;\s*\}', good_func, text)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(text)

fix('lib/features/customs_tariff/widgets/duty_calculator_dialog.dart')
fix('lib/features/customs_tariff/widgets/nafeza_details_dialog.dart')
