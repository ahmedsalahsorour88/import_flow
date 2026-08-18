import os

with open('frontend/lib/features/cbm_calculator/screens/cbm_calculator_screen.dart', 'r', encoding='utf-8') as f:
    code = f.read()

idx = code.find('  Widget _buildSavedRegistryTab(')
if idx == -1:
    print("Could not find _buildSavedRegistryTab")
    exit(1)

screen_code = code[:idx]
tab_methods_code = code[idx:]

widget_code = """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/master_data_toolbar.dart';
import '../../../core/widgets/row_actions_pill.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/container_load_plan_painter.dart';
import '../../../core/widgets/error_details_dialog.dart';
import '../../../core/widgets/change_diff_dialog.dart';
import '../../import_files/models/import_file_model.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../../purchase_orders/models/purchase_order_model.dart';
import '../../purchase_orders/providers/purchase_orders_provider.dart';
import '../models/cbm_calculation_model.dart';
import '../providers/cbm_calculator_provider.dart';

class SavedCbmRegistryTab extends ConsumerStatefulWidget {
  final void Function(CBMCalculationSessionModel session) onLoadSession;
  final VoidCallback onSwitchToCalculator;

  const SavedCbmRegistryTab({
    super.key,
    required this.onLoadSession,
    required this.onSwitchToCalculator,
  });

  @override
  ConsumerState<SavedCbmRegistryTab> createState() => _SavedCbmRegistryTabState();
}

class _SavedCbmRegistryTabState extends ConsumerState<SavedCbmRegistryTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cbmCalculatorProvider);
    final importFiles = ref.watch(importFilesProvider).value ?? [];
    final poList = ref.watch(purchaseOrdersProvider).purchaseOrders;

    return _buildSavedRegistryTab(context, state, importFiles, poList);
  }

""" + tab_methods_code

# Replace internal references in widget_code
widget_code = widget_code.replace('_loadSessionIntoEditor(session);', 'widget.onLoadSession(session);')
widget_code = widget_code.replace('_tabController.animateTo(0);', 'widget.onSwitchToCalculator();')

os.makedirs('frontend/lib/features/cbm_calculator/widgets', exist_ok=True)
with open('frontend/lib/features/cbm_calculator/widgets/saved_cbm_registry_tab.dart', 'w', encoding='utf-8') as f:
    f.write(widget_code)

print("Created saved_cbm_registry_tab.dart successfully!")

# Update cbm_calculator_screen.dart
screen_code = screen_code.rstrip() + """

  Widget _buildSavedRegistryTab(
    BuildContext context,
    CBMCalculatorState state,
    List<ImportFileModel> importFiles,
    List<PurchaseOrderModel> poList,
  ) {
    return SavedCbmRegistryTab(
      onLoadSession: _loadSessionIntoEditor,
      onSwitchToCalculator: () => _tabController.animateTo(0),
    );
  }
}
"""

top_import = "import '../widgets/saved_cbm_registry_tab.dart';\n"
import_idx = screen_code.find('import ')
screen_code = screen_code[:import_idx] + top_import + screen_code[import_idx:]

with open('frontend/lib/features/cbm_calculator/screens/cbm_calculator_screen.dart', 'w', encoding='utf-8') as f:
    f.write(screen_code)

print("Updated cbm_calculator_screen.dart successfully!")
