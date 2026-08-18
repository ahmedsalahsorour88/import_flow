import os

with open('frontend/lib/features/shipping_scenarios/screens/shipping_scenarios_screen.dart', 'r', encoding='utf-8') as f:
    code = f.read()

idx = code.find('  Widget _buildHistoryRegistryTab(ShippingScenariosState state, List poList, List projectsList) {')
if idx == -1:
    print("Could not find _buildHistoryRegistryTab")
    exit(1)

screen_code = code[:idx]
tab_methods_code = code[idx:]

# Convert tab_methods_code into a standalone ConsumerStatefulWidget
widget_code = """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/change_diff_dialog.dart';
import '../../../core/widgets/container_load_plan_painter.dart';
import '../../../core/widgets/master_data_toolbar.dart';
import '../../../core/widgets/row_actions_pill.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/error_details_dialog.dart';
import '../../purchase_orders/models/purchase_order_model.dart';
import '../../purchase_orders/providers/purchase_orders_provider.dart';
import '../../projects/providers/projects_provider.dart';
import '../../currencies/models/currency_model.dart';
import '../../currencies/providers/currencies_provider.dart';
import '../models/shipping_scenario_model.dart';
import '../providers/shipping_scenarios_provider.dart';

class SavedScenariosRegistryTab extends ConsumerStatefulWidget {
  final void Function(ShippingEvaluationModel session) onEditSession;
  final VoidCallback onSwitchToEvaluator;

  const SavedScenariosRegistryTab({
    super.key,
    required this.onEditSession,
    required this.onSwitchToEvaluator,
  });

  @override
  ConsumerState<SavedScenariosRegistryTab> createState() => _SavedScenariosRegistryTabState();
}

class _SavedScenariosRegistryTabState extends ConsumerState<SavedScenariosRegistryTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shippingScenariosProvider);
    final poList = ref.watch(purchaseOrdersProvider).purchaseOrders;
    final projectsList = ref.watch(projectsProvider).projects;

    return _buildHistoryRegistryTab(state, poList, projectsList);
  }

""" + tab_methods_code

# In widget_code, replace widget context and editing callbacks
widget_code = widget_code.replace('_loadSessionForEditing(sess);', 'widget.onEditSession(sess);')
widget_code = widget_code.replace('_tabController.animateTo(0);', 'widget.onSwitchToEvaluator();')

os.makedirs('frontend/lib/features/shipping_scenarios/widgets', exist_ok=True)
with open('frontend/lib/features/shipping_scenarios/widgets/saved_scenarios_registry_tab.dart', 'w', encoding='utf-8') as f:
    f.write(widget_code)

print("Created saved_scenarios_registry_tab.dart successfully!")

# Now update shipping_scenarios_screen.dart
# In screen_code, add import and in _screens / tab view, render SavedScenariosRegistryTab
screen_code = screen_code.rstrip() + """

  Widget _buildHistoryRegistryTab(ShippingScenariosState state, List poList, List projectsList) {
    return SavedScenariosRegistryTab(
      onEditSession: _loadSessionForEditing,
      onSwitchToEvaluator: () => _tabController.animateTo(0),
    );
  }
}
"""

top_import = "import '../widgets/saved_scenarios_registry_tab.dart';\n"
import_idx = screen_code.find('import ')
screen_code = screen_code[:import_idx] + top_import + screen_code[import_idx:]

with open('frontend/lib/features/shipping_scenarios/screens/shipping_scenarios_screen.dart', 'w', encoding='utf-8') as f:
    f.write(screen_code)

print("Updated shipping_scenarios_screen.dart successfully!")
