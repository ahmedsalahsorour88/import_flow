import os
import re

path = 'lib/features/customs_consultation/screens/customs_consultation_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

start = -1
end = -1
for i, line in enumerate(lines):
    if '// TAB 2: SAVED CONSULTATIONS HISTORY REGISTRY' in line:
        start = i
    if '// TAB 3: BROKER PRICE LISTS & CATALOG MANAGEMENT' in line:
        end = i
        break

tab2_body = lines[start:end]

imports = """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../models/customs_consultation_model.dart';
import '../providers/customs_consultation_provider.dart';
import 'consultation_metric_badge.dart';
import 'consultation_status_badges.dart';

class SavedConsultationsTab extends ConsumerStatefulWidget {
  final Function(CustomsConsultationModel) onEdit;
  const SavedConsultationsTab({super.key, required this.onEdit});

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

closing = """
  }
}
"""

for i in range(len(tab2_body)):
    tab2_body[i] = tab2_body[i].replace('_loadConsultationForEdit', 'widget.onEdit')
    tab2_body[i] = tab2_body[i].replace('consultationsState.when(', 'consultationsState.when(\n')

# replace `_buildMetricBadge` and `_buildStatusBadge` with standard widgets if any
for i in range(len(tab2_body)):
    tab2_body[i] = re.sub(r'_buildMetricBadge\(\s*([^,]+),\s*([^,]+),\s*([^,\)]+)\s*\)', r'ConsultationMetricBadge(title: \1, value: \2, color: \3)', tab2_body[i])
    tab2_body[i] = re.sub(r'_buildMetricBadge\(\s*([^,]+),\s*([^,]+),\s*([^,]+),\s*onTap:\s*([^\)]+)\s*\)', r'ConsultationMetricBadge(title: \1, value: \2, color: \3, onTap: \4)', tab2_body[i])
    tab2_body[i] = re.sub(r'_buildStatusBadge\((.*?)\)', r'ConsultationStatusBadge(status: \1)', tab2_body[i])
    tab2_body[i] = re.sub(r'_buildDocItemStatusBadge\((.*?)\)', r'ConsultationDocStatusBadge(status: \1)', tab2_body[i])


os.makedirs('lib/features/customs_consultation/widgets', exist_ok=True)
with open('lib/features/customs_consultation/widgets/saved_consultations_tab.dart', 'w', encoding='utf-8') as f:
    f.write(imports + ''.join(tab2_body) + ';\n' + closing)

del lines[start:end]
lines.insert(start, '          SavedConsultationsTab(onEdit: _loadConsultationForEdit),\n')

# remove state variables from main file
lines = [l for l in lines if not l.strip().startswith("String _searchQuery = '';")]
lines = [l for l in lines if not l.strip().startswith("String _statusFilter = 'All';")]
lines = [l for l in lines if not l.strip().startswith("bool _showInactive = false;")]

import_str = "import '../widgets/saved_consultations_tab.dart';\n"
for i in range(len(lines)):
    if lines[i].startswith('import'):
        lines.insert(i, import_str)
        break

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(lines)
