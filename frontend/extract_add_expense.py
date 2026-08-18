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

body, s, e = get_method('void _showAddExpenseTypeDialog')
if s != -1:
    imports = """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/customs_consultation_provider.dart';

"""
    body[0] = body[0].replace('void _showAddExpenseTypeDialog()', 'void showAddExpenseTypeDialog(BuildContext context, WidgetRef ref)')
    
    body_str = ''.join(body)
    body_str = body_str.replace('if (!mounted) return;', 'if (!context.mounted) return;')
    
    with open('lib/features/customs_consultation/widgets/add_expense_type_dialog.dart', 'w', encoding='utf-8') as f:
        f.write(imports + body_str)
    
    del lines[s:e+1]
    for i in range(len(lines)):
        lines[i] = lines[i].replace('onTap: _showAddExpenseTypeDialog,', 'onTap: () => showAddExpenseTypeDialog(context, ref),')
        lines[i] = lines[i].replace('_showAddExpenseTypeDialog();', 'showAddExpenseTypeDialog(context, ref);')

import_str = "import '../widgets/add_expense_type_dialog.dart';\n"
for i in range(len(lines)):
    if lines[i].startswith('import'):
        lines.insert(i, import_str)
        break

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(lines)
