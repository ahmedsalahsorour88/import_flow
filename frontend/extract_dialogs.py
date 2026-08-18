import os
import re

path = 'lib/features/customs_consultation/screens/customs_consultation_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

def get_method(start_sig):
    start = -1
    for i, l in enumerate(lines):
        if start_sig in l:
            start = i
            break
    if start == -1: return None, -1, -1
    brace_count = 0
    end = -1
    for i in range(start, len(lines)):
        brace_count += lines[i].count('{') - lines[i].count('}')
        if brace_count == 0 and '{' in ''.join(lines[start:i+1]):
            end = i
            break
    return lines[start:end+1], start, end

# Extract PriceListFormDialog
body, s, e = get_method('void _showPriceListFormDialog')
imports = """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../models/customs_consultation_model.dart';
import '../providers/customs_consultation_provider.dart';

"""
body[0] = body[0].replace('void _showPriceListFormDialog', 'void showPriceListFormDialog')
os.makedirs('lib/features/customs_consultation/widgets', exist_ok=True)
with open('lib/features/customs_consultation/widgets/price_list_form_dialog.dart', 'w', encoding='utf-8') as f:
    f.write(imports + ''.join(body))

del lines[s:e+1]
for i in range(len(lines)):
    lines[i] = lines[i].replace('_showPriceListFormDialog', 'showPriceListFormDialog')

# Extract NafezaFeeBreakdownCard
body, s, e = get_method('Widget _buildNafezaFeeBreakdownCard')
imports = """import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/customs_consultation_model.dart';
import '../../customs_tariff/services/customs_export_service.dart';

"""
body[0] = body[0].replace('Widget _buildNafezaFeeBreakdownCard', 'Widget buildNafezaFeeBreakdownCard')
with open('lib/features/customs_consultation/widgets/nafeza_fee_breakdown_card.dart', 'w', encoding='utf-8') as f:
    f.write(imports + ''.join(body))
del lines[s:e+1]
for i in range(len(lines)):
    lines[i] = lines[i].replace('_buildNafezaFeeBreakdownCard', 'buildNafezaFeeBreakdownCard')

# Insert imports
import_str = """import '../widgets/price_list_form_dialog.dart';
import '../widgets/nafeza_fee_breakdown_card.dart';
import '../widgets/post_save_status_dialog.dart';
"""
for i in range(len(lines)):
    if lines[i].startswith('import'):
        lines.insert(i, import_str)
        break

# Fix PostSaveStatusDialog inline usage
for i in range(len(lines)):
    lines[i] = re.sub(r'_showPostSaveStatusDialog\((.*?)\)', r'showDialog(context: context, builder: (ctx) => PostSaveStatusDialog(saved: \1))', lines[i])

# Delete PostSaveStatusDialog from main file
body, s, e = get_method('void _showPostSaveStatusDialog')
if s != -1: del lines[s:e+1]

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(lines)
