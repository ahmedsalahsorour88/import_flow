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

path = 'lib/features/customs_tariff/screens/customs_tariff_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

def move_method_to_file(method_name, target_file, rename_to):
    global lines
    body, start, end = extract_method(lines, [f'void {method_name}'])
    if not body: return
    
    # create the file
    os.makedirs(os.path.dirname(target_file), exist_ok=True)
    imports = """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../models/customs_tariff_model.dart';
import '../providers/customs_tariff_provider.dart';
import '../../import_requirements/models/import_requirement_model.dart';
import '../../import_requirements/providers/import_requirements_provider.dart';

"""
    # Fix the method signature (remove _)
    body[0] = body[0].replace(f'void {method_name}', f'void {rename_to}')
    
    with open(target_file, 'w', encoding='utf-8') as f:
        f.write(imports + ''.join(body))
        
    # Replace the body in lines with just a call to the new method, if needed.
    # Actually, we can just delete it from `lines`, and change calls in `lines` to `rename_to`
    del lines[start:end+1]
    
    for i in range(len(lines)):
        lines[i] = lines[i].replace(method_name, rename_to)

move_method_to_file('_showDutyCalculatorDialog', 'lib/features/customs_tariff/widgets/duty_calculator_dialog.dart', 'showDutyCalculatorDialog')
move_method_to_file('_showTariffDialog', 'lib/features/customs_tariff/widgets/tariff_form_dialog.dart', 'showTariffDialog')
move_method_to_file('_showVerifyTariffDialog', 'lib/features/customs_tariff/widgets/verify_tariff_dialog.dart', 'showVerifyTariffDialog')
move_method_to_file('_showNafezaDetailsDialog', 'lib/features/customs_tariff/widgets/nafeza_details_dialog.dart', 'showNafezaDetailsDialog')
move_method_to_file('_showAddAgreementDialog', 'lib/features/customs_tariff/widgets/add_agreement_dialog.dart', 'showAddAgreementDialog')

# Add imports to the top of customs_tariff_screen.dart
import_str = """import '../widgets/duty_calculator_dialog.dart';
import '../widgets/tariff_form_dialog.dart';
import '../widgets/verify_tariff_dialog.dart';
import '../widgets/nafeza_details_dialog.dart';
import '../widgets/add_agreement_dialog.dart';
"""
for i in range(len(lines)):
    if lines[i].startswith('import'):
        lines.insert(i, import_str)
        break

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(lines)
