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

# 1. BrokerCostRow
body, s, e = get_method('Widget _buildBrokerCostRow')
if s != -1:
    imports = """import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/customs_consultation_model.dart';
import '../../currencies/models/currency_model.dart';

"""
    body[0] = body[0].replace('Widget _buildBrokerCostRow({', 'Widget buildBrokerCostRow({\n    required Function(int, CustomsBrokerQuoteItemModel) onUpdate,')
    body_str = ''.join(body)
    body_str = body_str.replace('_updateBrokerQuoteItem(index, ', 'onUpdate(index, ')
    
    with open('lib/features/customs_consultation/widgets/broker_cost_row.dart', 'w', encoding='utf-8') as f:
        f.write(imports + body_str)
    
    del lines[s:e+1]
    for i in range(len(lines)):
        lines[i] = lines[i].replace('_buildBrokerCostRow(', 'buildBrokerCostRow(onUpdate: _updateBrokerQuoteItem, ')

import_str = "import '../widgets/broker_cost_row.dart';\n"
for i in range(len(lines)):
    if lines[i].startswith('import'):
        lines.insert(i, import_str)
        break

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(lines)
