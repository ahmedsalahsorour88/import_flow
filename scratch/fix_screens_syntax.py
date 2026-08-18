# Fix shipping_scenarios_screen.dart
with open('frontend/lib/features/shipping_scenarios/screens/shipping_scenarios_screen.dart', 'r', encoding='utf-8') as f:
    scen = f.read()

# Replace the incorrect end
bad_end = """  }
}

  Widget _buildHistoryRegistryTab(ShippingScenariosState state, List poList, List projectsList) {
    return SavedScenariosRegistryTab(
      onEditSession: _loadSessionForEditing,
      onSwitchToEvaluator: () => _tabController.animateTo(0),
    );
  }
}
"""

good_end = """  }

  Widget _buildHistoryRegistryTab(ShippingScenariosState state, List poList, List projectsList) {
    return SavedScenariosRegistryTab(
      onEditSession: _loadSessionForEditing,
      onSwitchToEvaluator: () => _tabController.animateTo(0),
    );
  }
}
"""

if bad_end in scen:
    scen = scen.replace(bad_end, good_end)
else:
    # Alternative fix
    idx = scen.rfind('  Widget _buildHistoryRegistryTab(')
    # Find the closing brace right before it
    brace_idx = scen.rfind('}', 0, idx)
    scen = scen[:brace_idx] + scen[brace_idx+1:]

with open('frontend/lib/features/shipping_scenarios/screens/shipping_scenarios_screen.dart', 'w', encoding='utf-8') as f:
    f.write(scen)

print("Fixed shipping_scenarios_screen.dart!")

# Fix cbm_calculator_screen.dart
with open('frontend/lib/features/cbm_calculator/screens/cbm_calculator_screen.dart', 'r', encoding='utf-8') as f:
    cbm = f.read()

# Add missing imports if not present
imports_to_add = """import '../../import_files/models/import_file_model.dart';
import '../../purchase_orders/models/purchase_order_model.dart';
"""
if "import '../../import_files/models/import_file_model.dart';" not in cbm:
    import_idx = cbm.find('import ')
    cbm = cbm[:import_idx] + imports_to_add + cbm[import_idx:]

cbm = cbm.replace('_loadSessionIntoEditor', '_loadSessionForEditing')

with open('frontend/lib/features/cbm_calculator/screens/cbm_calculator_screen.dart', 'w', encoding='utf-8') as f:
    f.write(cbm)

print("Fixed cbm_calculator_screen.dart!")
