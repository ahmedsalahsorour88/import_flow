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

os.makedirs('lib/features/customs_consultation/widgets', exist_ok=True)

# 1. TAB 2: SavedConsultationsTab
start_t2, end_t2 = -1, -1
for i, line in enumerate(lines):
    if '// TAB 2: SAVED CONSULTATIONS HISTORY REGISTRY' in line:
        start_t2 = i
    if '// TAB 3: BROKER PRICE LISTS & CATALOG MANAGEMENT' in line:
        end_t2 = i
        break
tab2_body = lines[start_t2:end_t2]
imports_t2 = """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../models/customs_consultation_model.dart';
import '../providers/customs_consultation_provider.dart';

class SavedConsultationsTab extends ConsumerStatefulWidget {
  final Function(CustomsConsultationModel) onEdit;
  final Function(BuildContext, CustomsConsultationModel) onViewDetails;
  
  const SavedConsultationsTab({super.key, required this.onEdit, required this.onViewDetails});

  @override
  ConsumerState<SavedConsultationsTab> createState() => _SavedConsultationsTabState();
}

class _SavedConsultationsTabState extends ConsumerState<SavedConsultationsTab> {
  String _searchQuery = '';
  String _statusFilter = 'All';
  bool _showInactive = false;

  @override
  Widget build(BuildContext context) {
    final consultationsState = ref.watch(customsConsultationsProvider);
    return """
closing_t2 = "  }\n}\n"
for i in range(len(tab2_body)):
    tab2_body[i] = tab2_body[i].replace('_loadConsultationForEdit', 'widget.onEdit')
    tab2_body[i] = tab2_body[i].replace('_showConsultationDetailsDialog', 'widget.onViewDetails')
    tab2_body[i] = tab2_body[i].replace('consultationsState.when(', 'consultationsState.when(\n')

with open('lib/features/customs_consultation/widgets/saved_consultations_tab.dart', 'w', encoding='utf-8') as f:
    f.write(imports_t2 + ''.join(tab2_body) + ';\n' + closing_t2)

del lines[start_t2:end_t2]
lines.insert(start_t2, '          SavedConsultationsTab(onEdit: _loadConsultationForEdit, onViewDetails: _showConsultationDetailsDialog),\n')


# 2. _showPostSaveStatusDialog -> replace inline and delete
body_ps, s_ps, e_ps = get_method('void _showPostSaveStatusDialog')
if s_ps != -1: del lines[s_ps:e_ps+1]
for i in range(len(lines)):
    lines[i] = re.sub(r'_showPostSaveStatusDialog\((.*?)\)', r'showDialog(context: context, builder: (ctx) => PostSaveStatusDialog(saved: \1))', lines[i])


# 3. _buildNafezaFeeBreakdownCard
body_naf, s_naf, e_naf = get_method('Widget _buildNafezaFeeBreakdownCard')
imports_naf = """import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/customs_consultation_model.dart';
import '../../customs_tariff/services/customs_export_service.dart';

"""
body_naf[0] = body_naf[0].replace('Widget _buildNafezaFeeBreakdownCard', 'Widget buildNafezaFeeBreakdownCard')
with open('lib/features/customs_consultation/widgets/nafeza_fee_breakdown_card.dart', 'w', encoding='utf-8') as f:
    f.write(imports_naf + ''.join(body_naf))
if s_naf != -1: del lines[s_naf:e_naf+1]
for i in range(len(lines)):
    lines[i] = lines[i].replace('_buildNafezaFeeBreakdownCard', 'buildNafezaFeeBreakdownCard')


# 4. _showConsultationDetailsDialog
body_det, s_det, e_det = get_method('void _showConsultationDetailsDialog')
imports_det = """import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/customs_consultation_model.dart';

"""
body_det[0] = body_det[0].replace('void _showConsultationDetailsDialog', 'void showConsultationDetailsDialog')
with open('lib/features/customs_consultation/widgets/consultation_details_dialog.dart', 'w', encoding='utf-8') as f:
    f.write(imports_det + ''.join(body_det))
if s_det != -1: del lines[s_det:e_det+1]
for i in range(len(lines)):
    lines[i] = lines[i].replace('_showConsultationDetailsDialog', 'showConsultationDetailsDialog')


# Delete state variables
lines = [l for l in lines if not l.strip().startswith("String _searchQuery = '';")]
lines = [l for l in lines if not l.strip().startswith("String _statusFilter = 'All';")]
lines = [l for l in lines if not l.strip().startswith("bool _showInactive = false;")]

import_str = """import '../widgets/saved_consultations_tab.dart';
import '../widgets/nafeza_fee_breakdown_card.dart';
import '../widgets/consultation_details_dialog.dart';
import '../widgets/post_save_status_dialog.dart';
"""
for i in range(len(lines)):
    if lines[i].startswith('import'):
        lines.insert(i, import_str)
        break

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(lines)
