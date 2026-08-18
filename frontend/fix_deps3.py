with open('lib/features/customs_tariff/widgets/nafeza_details_dialog.dart', 'r', encoding='utf-8') as f:
    text = f.read()

idx = text.rfind('Widget _buildNafezaRulesList')
func = text[idx:]
# find the proper end by counting braces
brace_count = 0
end_idx = -1
for i, char in enumerate(func):
    if char == '{':
        brace_count += 1
    elif char == '}':
        brace_count -= 1
        if brace_count == 0:
            end_idx = i
            break

text = text[:idx + end_idx + 1]

text += """
double _numToDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is double) return val;
  if (val is int) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? 0.0;
  return 0.0;
}
"""
with open('lib/features/customs_tariff/widgets/nafeza_details_dialog.dart', 'w', encoding='utf-8') as f:
    f.write(text)
