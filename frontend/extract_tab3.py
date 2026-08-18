import os

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

# Extract BrokerPriceListsTab
body1, s1, e1 = get_method('Widget _buildPriceListsAndCatalogTab')
body2, s2, e2 = get_method('Widget _buildBrokerPriceListsView')
body3, s3, e3 = get_method('Widget _buildExpenseCatalogView')
body4, s4, e4 = get_method('void _showAddExpenseTypeDialog')

imports = """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../models/customs_consultation_model.dart';
import '../providers/customs_consultation_provider.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import 'price_list_form_dialog.dart';

class BrokerPriceListsTab extends ConsumerStatefulWidget {
  const BrokerPriceListsTab({super.key});

  @override
  ConsumerState<BrokerPriceListsTab> createState() => _BrokerPriceListsTabState();
}

class _BrokerPriceListsTabState extends ConsumerState<BrokerPriceListsTab> {
  String? _selectedMgmtBrokerId;
  String _mgmtExpenseSearch = '';
  String _mgmtExpenseCategory = 'All';

  @override
  Widget build(BuildContext context) {
    return _buildPriceListsAndCatalogTab();
  }
"""

closing = """
}
"""

with open('lib/features/customs_consultation/widgets/broker_price_lists_tab.dart', 'w', encoding='utf-8') as f:
    f.write(imports + ''.join(body1) + ''.join(body2) + ''.join(body3) + ''.join(body4) + closing)

# remove state variables from main file
lines = [l for l in lines if not l.strip().startswith("String? _selectedMgmtBrokerId;")]
lines = [l for l in lines if not l.strip().startswith("String _mgmtExpenseSearch = '';")]
lines = [l for l in lines if not l.strip().startswith("String _mgmtExpenseCategory = 'All';")]

# delete methods from bottom up
if s4 != -1: del lines[s4:e4+1]
if s3 != -1: del lines[s3:e3+1]
if s2 != -1: del lines[s2:e2+1]
if s1 != -1: del lines[s1:e1+1]

# replace in build method
for i in range(len(lines)):
    lines[i] = lines[i].replace('_buildPriceListsAndCatalogTab()', 'const BrokerPriceListsTab()')

import_str = "import '../widgets/broker_price_lists_tab.dart';\n"
for i in range(len(lines)):
    if lines[i].startswith('import'):
        lines.insert(i, import_str)
        break

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(lines)
