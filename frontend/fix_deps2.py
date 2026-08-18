with open('lib/features/customs_tariff/widgets/nafeza_details_dialog.dart', 'r', encoding='utf-8') as nf:
    n_text = nf.read()

# Add imports
imports = """import 'package:file_picker/file_picker.dart';
"""
if 'file_picker.dart' not in n_text:
    n_text = imports + n_text

# _numToDouble is missing in nafeza_details_dialog
if '_numToDouble(' not in n_text:
    n_text += """
double _numToDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is double) return val;
  if (val is int) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? 0.0;
  return 0.0;
}
"""

with open('lib/features/customs_tariff/widgets/nafeza_details_dialog.dart', 'w', encoding='utf-8') as nf:
    nf.write(n_text)

# Also check for the syntax error on line 424.
# It might be an extra closing brace at the very end.
