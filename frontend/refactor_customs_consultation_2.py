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

path = 'lib/features/customs_consultation/screens/customs_consultation_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

def move_method_to_file(method_name, target_file, rename_to):
    global lines
    body, start, end = extract_method(lines, [f'Widget {method_name}'])
    if not body: return
    
    os.makedirs(os.path.dirname(target_file), exist_ok=True)
    imports = """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../models/customs_consultation_model.dart';
import '../../customs_tariff/services/customs_export_service.dart';
import '../providers/customs_consultation_provider.dart';
import '../../currencies/models/currency_model.dart';

"""
    body[0] = body[0].replace(f'Widget {method_name}', f'Widget {rename_to}')
    
    with open(target_file, 'w', encoding='utf-8') as f:
        f.write(imports + ''.join(body))
        
    del lines[start:end+1]
    
    for i in range(len(lines)):
        lines[i] = lines[i].replace(method_name, rename_to)

move_method_to_file('_buildNafezaFeeBreakdownCard', 'lib/features/customs_consultation/widgets/nafeza_fee_breakdown_card.dart', 'buildNafezaFeeBreakdownCard')
move_method_to_file('_buildBrokerPriceListsView', 'lib/features/customs_consultation/widgets/broker_price_lists_view.dart', 'buildBrokerPriceListsView')

import_str = """import '../widgets/nafeza_fee_breakdown_card.dart';
import '../widgets/broker_price_lists_view.dart';
"""
for i in range(len(lines)):
    if lines[i].startswith('import'):
        lines.insert(i, import_str)
        break

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(lines)
