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
    body, start, end = extract_method(lines, [f'void {method_name}'])
    if not body: return
    
    os.makedirs(os.path.dirname(target_file), exist_ok=True)
    imports = """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../models/customs_consultation_model.dart';
import '../providers/customs_consultation_provider.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import 'consultation_metric_badge.dart';
import 'consultation_status_badges.dart';

"""
    # Fix the method signature (remove _)
    body[0] = body[0].replace(f'void {method_name}', f'void {rename_to}')
    
    with open(target_file, 'w', encoding='utf-8') as f:
        f.write(imports + ''.join(body))
        
    del lines[start:end+1]
    
    for i in range(len(lines)):
        lines[i] = lines[i].replace(method_name, rename_to)

move_method_to_file('_showPriceListFormDialog', 'lib/features/customs_consultation/widgets/price_list_form_dialog.dart', 'showPriceListFormDialog')
move_method_to_file('_showConsultationDetailsDialog', 'lib/features/customs_consultation/widgets/consultation_details_dialog.dart', 'showConsultationDetailsDialog')
move_method_to_file('_showAddExpenseTypeDialog', 'lib/features/customs_consultation/widgets/add_expense_type_dialog.dart', 'showAddExpenseTypeDialog')

# _showBlockingIssuesDialog takes _checklist from state. Let's make it a param
blocking_body, bs, be = extract_method(lines, ['void _showBlockingIssuesDialog'])
if blocking_body:
    blocking_body[0] = blocking_body[0].replace('void _showBlockingIssuesDialog() {', 'void showBlockingIssuesDialog(BuildContext context, List<CustomsChecklistItemModel> checklist) {')
    for i in range(len(blocking_body)):
        blocking_body[i] = blocking_body[i].replace('_checklist', 'checklist')
    imports = """import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/customs_consultation_model.dart';

"""
    with open('lib/features/customs_consultation/widgets/blocking_issues_dialog.dart', 'w', encoding='utf-8') as f:
        f.write(imports + ''.join(blocking_body))
    del lines[bs:be+1]
    for i in range(len(lines)):
        lines[i] = lines[i].replace('_showBlockingIssuesDialog()', 'showBlockingIssuesDialog(context, _checklist)')
        lines[i] = lines[i].replace('onTap: _showBlockingIssuesDialog', 'onTap: () => showBlockingIssuesDialog(context, _checklist)')

# Now, let's extract the inline methods that have existing widgets in widgets/
def replace_widget(old_sig, replace_with, target_str=None):
    global lines
    body, start, end = extract_method(lines, [old_sig])
    if body:
        del lines[start:end+1]
        
# For widgets that are already classes, just delete the void/Widget helpers inside the class
replace_widget('void _addChecklistItem', None)
replace_widget('void _addCustomBrokerExpenseRow', None)
replace_widget('void _showPostSaveStatusDialog', None)
replace_widget('Widget _buildMetricBadge', None)
replace_widget('Widget _buildStatusBadge', None)
replace_widget('Widget _buildDocItemStatusBadge', None)

# Add imports for existing widgets
import_str = """import '../widgets/price_list_form_dialog.dart';
import '../widgets/consultation_details_dialog.dart';
import '../widgets/add_expense_type_dialog.dart';
import '../widgets/blocking_issues_dialog.dart';
import '../widgets/add_checklist_item_dialog.dart';
import '../widgets/add_custom_broker_expense_row_dialog.dart';
import '../widgets/consultation_metric_badge.dart';
import '../widgets/consultation_status_badges.dart';
import '../widgets/post_save_status_dialog.dart';
"""
for i in range(len(lines)):
    if lines[i].startswith('import'):
        lines.insert(i, import_str)
        break

# Now, we must replace the calls to the inline methods with the actual widgets!
for i in range(len(lines)):
    lines[i] = lines[i].replace('_showPostSaveStatusDialog(saved)', 'showDialog(context: context, builder: (ctx) => PostSaveStatusDialog(saved: saved))')
    # addChecklistItem is used as `onPressed: _addChecklistItem`. We replace with a closure
    # wait, addChecklistItem had setState _checklist.add. We must do that inline.
    if '_addChecklistItem' in lines[i]:
        lines[i] = lines[i].replace('_addChecklistItem', "() async { final res = await showDialog<CustomsChecklistItemModel>(context: context, builder: (_) => const AddChecklistItemDialog()); if (res != null) setState(() => _checklist.add(res)); }")
    if '_addCustomBrokerExpenseRow' in lines[i]:
        lines[i] = lines[i].replace('_addCustomBrokerExpenseRow', "() async { final res = await showDialog<CustomsBrokerQuoteItemModel>(context: context, builder: (_) => const AddCustomBrokerExpenseRowDialog()); if (res != null) setState(() { _brokerQuoteItems.add(res); _calculateBrokerQuote(); }); }")
    
    # buildMetricBadge -> ConsultationMetricBadge
    # The regex for this might be tricky, let's use python regex.
    import re
    lines[i] = re.sub(r'_buildMetricBadge\(\s*([^,]+),\s*([^,]+),\s*([^,\)]+)\s*\)', r'ConsultationMetricBadge(title: \1, value: \2, color: \3)', lines[i])
    lines[i] = re.sub(r'_buildMetricBadge\(\s*([^,]+),\s*([^,]+),\s*([^,]+),\s*onTap:\s*([^\)]+)\s*\)', r'ConsultationMetricBadge(title: \1, value: \2, color: \3, onTap: \4)', lines[i])
    lines[i] = re.sub(r'_buildStatusBadge\((.*?)\)', r'ConsultationStatusBadge(status: \1)', lines[i])
    lines[i] = re.sub(r'_buildDocItemStatusBadge\((.*?)\)', r'ConsultationDocStatusBadge(status: \1)', lines[i])

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(lines)
