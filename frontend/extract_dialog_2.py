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

# 1. showConsultationDetailsDialog (211)
body, s, e = get_method('void _showConsultationDetailsDialog')
if s != -1:
    imports = """import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/customs_consultation_model.dart';
import 'consultation_metric_badge.dart';
import 'consultation_status_badges.dart';

"""
    body[0] = body[0].replace('void _showConsultationDetailsDialog', 'void showConsultationDetailsDialog')
    # replace internal widget usages
    for i in range(len(body)):
        body[i] = re.sub(r'_buildMetricBadge\(\s*([^,]+),\s*([^,]+),\s*([^,\)]+)\s*\)', r'ConsultationMetricBadge(title: \1, value: \2, color: \3)', body[i])
        body[i] = re.sub(r'_buildStatusBadge\((.*?)\)', r'ConsultationStatusBadge(status: \1)', body[i])
        body[i] = re.sub(r'_buildDocItemStatusBadge\((.*?)\)', r'ConsultationDocStatusBadge(status: \1)', body[i])
    
    with open('lib/features/customs_consultation/widgets/consultation_details_dialog.dart', 'w', encoding='utf-8') as f:
        f.write(imports + ''.join(body))
    del lines[s:e+1]
    for i in range(len(lines)):
        lines[i] = lines[i].replace('_showConsultationDetailsDialog', 'showConsultationDetailsDialog')

# 2. _buildMetricBadge, _buildStatusBadge, _buildDocItemStatusBadge are ALREADY extracted as widgets!
# We just need to delete them from main file and replace their usages.
body, s, e = get_method('Widget _buildMetricBadge')
if s != -1: del lines[s:e+1]
body, s, e = get_method('Widget _buildStatusBadge')
if s != -1: del lines[s:e+1]
body, s, e = get_method('Widget _buildDocItemStatusBadge')
if s != -1: del lines[s:e+1]

for i in range(len(lines)):
    lines[i] = re.sub(r'_buildMetricBadge\(\s*([^,]+),\s*([^,]+),\s*([^,\)]+)\s*\)', r'ConsultationMetricBadge(title: \1, value: \2, color: \3)', lines[i])
    lines[i] = re.sub(r'_buildMetricBadge\(\s*([^,]+),\s*([^,]+),\s*([^,]+),\s*onTap:\s*([^\)]+)\s*\)', r'ConsultationMetricBadge(title: \1, value: \2, color: \3, onTap: \4)', lines[i])
    lines[i] = re.sub(r'_buildStatusBadge\((.*?)\)', r'ConsultationStatusBadge(status: \1)', lines[i])
    lines[i] = re.sub(r'_buildDocItemStatusBadge\((.*?)\)', r'ConsultationDocStatusBadge(status: \1)', lines[i])

# 3. Add imports
import_str = """import '../widgets/consultation_details_dialog.dart';
import '../widgets/consultation_metric_badge.dart';
import '../widgets/consultation_status_badges.dart';
"""
for i in range(len(lines)):
    if lines[i].startswith('import'):
        lines.insert(i, import_str)
        break

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(lines)
