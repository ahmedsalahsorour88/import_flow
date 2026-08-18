import os
import re

path = 'lib/features/import_files/screens/import_files_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

def get_class_bounds(class_name):
    start = -1
    for i, line in enumerate(lines):
        if line.startswith(f'class {class_name}'):
            start = i
            break
    if start == -1: return -1, -1
    
    brace_count = 0
    end = -1
    for i in range(start, len(lines)):
        brace_count += lines[i].count('{') - lines[i].count('}')
        if brace_count == 0 and '{' in ''.join(lines[start:i+1]):
            end = i
            break
    return start, end

# Find _ImportFileDetailsDialogWidget and its state
c1_s, c1_e = get_class_bounds('_ImportFileDetailsDialogWidget')
c2_s, c2_e = get_class_bounds('_ImportFileDetailsDialogWidgetState')

if c1_s != -1 and c2_s != -1:
    # combine them
    details_body = lines[c1_s:c1_e+1] + ['\n'] + lines[c2_s:c2_e+1]
    # rename _ImportFileDetailsDialogWidget to ImportFileDetailsDialogWidget
    details_body = [line.replace('_ImportFileDetailsDialogWidget', 'ImportFileDetailsDialog') for line in details_body]
    
    # replace in main file usages
    for i in range(len(lines)):
        lines[i] = lines[i].replace('_ImportFileDetailsDialogWidget', 'ImportFileDetailsDialog')
        
    # delete from main file
    # remember we have to delete the larger index first
    del lines[c2_s:c2_e+1]
    del lines[c1_s:c1_e+1]
    
    # save to file
    imports = """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../models/import_file_model.dart';
import '../providers/import_files_provider.dart';
import '../../purchase_orders/models/purchase_order_model.dart' hide PackingListItemModel;
import '../../purchase_orders/providers/purchase_orders_provider.dart';
import '../../external_service_providers/providers/partners_provider.dart';
import '../../projects/models/project_model.dart';
import '../../projects/providers/projects_provider.dart';
import '../../../core/utils/container_requirement_engine.dart';
import '../../../core/widgets/container_load_plan_painter.dart';
import 'package:flutter/services.dart';

"""
    os.makedirs('lib/features/import_files/widgets', exist_ok=True)
    with open('lib/features/import_files/widgets/import_file_details_dialog.dart', 'w', encoding='utf-8') as f:
        f.write(imports + ''.join(details_body))

# Find _ImportFileFormDialog and its state
c3_s, c3_e = get_class_bounds('_ImportFileFormDialog')
c4_s, c4_e = get_class_bounds('_ImportFileFormDialogState')

if c3_s != -1 and c4_s != -1:
    form_body = lines[c3_s:c3_e+1] + ['\n'] + lines[c4_s:c4_e+1]
    form_body = [line.replace('_ImportFileFormDialog', 'ImportFileFormDialog') for line in form_body]
    
    for i in range(len(lines)):
        lines[i] = lines[i].replace('_ImportFileFormDialog', 'ImportFileFormDialog')
        
    del lines[c4_s:c4_e+1]
    del lines[c3_s:c3_e+1]
    
    imports = """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../models/import_file_model.dart';
import '../providers/import_files_provider.dart';
import '../../purchase_orders/providers/purchase_orders_provider.dart';
import '../../purchase_orders/models/purchase_order_model.dart' hide PackingListItemModel;
import '../../external_service_providers/providers/partners_provider.dart';
import '../../projects/models/project_model.dart';
import '../../projects/providers/projects_provider.dart';
import '../../import_companies/providers/import_companies_provider.dart';
import '../../incoterms/providers/incoterms_provider.dart';
import '../../suppliers/providers/suppliers_provider.dart';
import '../../financial_approval/providers/financial_approval_provider.dart';
import '../../financial_approval/models/financial_approval_model.dart';
import '../../import_documentation/providers/import_documentation_provider.dart';
import '../../import_documentation/models/import_documentation_model.dart';
import '../../customs_consultation/providers/customs_consultation_provider.dart';
import '../../customs_consultation/models/customs_consultation_model.dart';
import '../../currencies/providers/currencies_provider.dart';
import '../../shipping_scenarios/providers/shipping_scenarios_provider.dart';
"""
    with open('lib/features/import_files/widgets/import_file_form_dialog.dart', 'w', encoding='utf-8') as f:
        f.write(imports + ''.join(form_body))

import_str = """import '../widgets/import_file_details_dialog.dart';
import '../widgets/import_file_form_dialog.dart';
"""
for i in range(len(lines)):
    if lines[i].startswith('import'):
        lines.insert(i, import_str)
        break

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(lines)
