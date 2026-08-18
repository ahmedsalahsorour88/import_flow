import os
import re

def extract_method(lines, method_starts):
    start_idx = -1
    for i, line in enumerate(lines):
        if any(line.strip().startswith(m) for m in method_starts):
            start_idx = i
            break
    if start_idx == -1: return None, -1, -1
    brace_count = 0
    end_idx = -1
    for i in range(start_idx, len(lines)):
        brace_count += lines[i].count('{') - lines[i].count('}')
        if brace_count == 0 and '{' in ''.join(lines[start_idx:i+1]):
            end_idx = i
            break
    return lines[start_idx:end_idx+1], start_idx, end_idx

path = 'lib/features/import_files/screens/import_files_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

def move_method_to_file(method_name, target_file, rename_to, replace_mounted=False):
    global lines
    body, start, end = extract_method(lines, [f'void {method_name}'])
    if not body: return
    
    os.makedirs(os.path.dirname(target_file), exist_ok=True)
    imports = """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../purchase_orders/models/purchase_order_model.dart';
import '../../purchase_orders/providers/purchase_orders_provider.dart';
import '../providers/import_files_provider.dart';
import '../models/import_file_model.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';

"""
    # Fix the method signature (remove _)
    body[0] = body[0].replace(f'void {method_name}', f'void {rename_to}')
    
    if replace_mounted:
        # if the original function doesn't take context/ref, let's add them
        if 'BuildContext context' not in body[0]:
            body[0] = body[0].replace('(', '(BuildContext context, WidgetRef ref, ', 1)
            body[0] = body[0].replace(', )', ')')
            # replace mounted with context.mounted
            for i in range(len(body)):
                body[i] = re.sub(r'\b(!?)mounted\b', r'\1context.mounted', body[i])
    
    with open(target_file, 'w', encoding='utf-8') as f:
        f.write(imports + ''.join(body))
        
    del lines[start:end+1]
    
    for i in range(len(lines)):
        # if replace_mounted is true, we must add context and ref to the call
        if replace_mounted and f'{method_name}(' in lines[i]:
            lines[i] = lines[i].replace(f'{method_name}(', f'{rename_to}(context, ref, ')
            lines[i] = lines[i].replace(', )', ')')
        else:
            lines[i] = lines[i].replace(method_name, rename_to)

move_method_to_file('_showMasterReportDialog', 'lib/features/import_files/widgets/master_report_dialog.dart', 'showMasterReportDialog', replace_mounted=True)
move_method_to_file('_showVisualLoadPlanDialogForReport', 'lib/features/import_files/widgets/visual_load_plan_dialog_for_report.dart', 'showVisualLoadPlanDialogForReport')
move_method_to_file('_showVisualLoadPlanDialog', 'lib/features/import_files/widgets/visual_load_plan_dialog.dart', 'showVisualLoadPlanDialog')

import_str = """import '../widgets/master_report_dialog.dart';
import '../widgets/visual_load_plan_dialog_for_report.dart';
import '../widgets/visual_load_plan_dialog.dart';
"""
for i in range(len(lines)):
    if lines[i].startswith('import'):
        lines.insert(i, import_str)
        break

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(lines)
