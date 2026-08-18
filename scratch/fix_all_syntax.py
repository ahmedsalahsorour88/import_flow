import re

# Fix saved_cbm_registry_tab.dart
with open('frontend/lib/features/cbm_calculator/widgets/saved_cbm_registry_tab.dart', 'r', encoding='utf-8') as f:
    cbm = f.read()

cbm = cbm.replace("import '../models/cbm_calculation_model.dart';", "import '../models/cbm_calculator_model.dart';")
cbm = re.sub(r'\bCBMCalculationSessionModel\b', 'CBMCalculationModel', cbm)

with open('frontend/lib/features/cbm_calculator/widgets/saved_cbm_registry_tab.dart', 'w', encoding='utf-8') as f:
    f.write(cbm)

print("Fixed cbm tab!")

# Fix shipping_scenarios_screen.dart
with open('frontend/lib/features/shipping_scenarios/screens/shipping_scenarios_screen.dart', 'r', encoding='utf-8') as f:
    scen = f.read()

# Fix the end of shipping_scenarios_screen.dart where extra braces or methods were appended
# Let's see how _buildHistoryRegistryTab is defined at the end of shipping_scenarios_screen.dart
idx = scen.rfind('  Widget _buildHistoryRegistryTab(')
if idx != -1:
    scen = scen[:idx] + """  Widget _buildHistoryRegistryTab(ShippingScenariosState state, List poList, List projectsList) {
    return SavedScenariosRegistryTab(
      onEditSession: _loadSessionForEditing,
      onSwitchToEvaluator: () => _tabController.animateTo(0),
    );
  }
}
"""

with open('frontend/lib/features/shipping_scenarios/screens/shipping_scenarios_screen.dart', 'w', encoding='utf-8') as f:
    f.write(scen)

print("Fixed shipping screen!")
