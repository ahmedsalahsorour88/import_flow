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

# 1. BlockingIssuesDialog
body, s, e = get_method('void _showBlockingIssuesDialog')
if s != -1:
    imports = """import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/customs_consultation_model.dart';

"""
    body[0] = body[0].replace('void _showBlockingIssuesDialog()', 'void showBlockingIssuesDialog(BuildContext context, List<CustomsChecklistItemModel> checklist, Function(List<CustomsChecklistItemModel>) onUpdate)')
    
    body_str = ''.join(body)
    body_str = body_str.replace('_checklist', 'checklist')
    body_str = re.sub(r'setState\(\(\)\s*\{\s*(.*?)\s*\}\);', r'\1\n                                            onUpdate(checklist);', body_str, flags=re.DOTALL)
    
    with open('lib/features/customs_consultation/widgets/blocking_issues_dialog.dart', 'w', encoding='utf-8') as f:
        f.write(imports + body_str)
    
    del lines[s:e+1]
    for i in range(len(lines)):
        lines[i] = lines[i].replace('_showBlockingIssuesDialog()', 'showBlockingIssuesDialog(context, _checklist, (val) => setState(() { _checklist.clear(); _checklist.addAll(val); }))')
        lines[i] = lines[i].replace('onTap: _showBlockingIssuesDialog', 'onTap: () => showBlockingIssuesDialog(context, _checklist, (val) => setState(() { _checklist.clear(); _checklist.addAll(val); }))')

import_str = "import '../widgets/blocking_issues_dialog.dart';\n"
for i in range(len(lines)):
    if lines[i].startswith('import'):
        lines.insert(i, import_str)
        break

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(lines)
