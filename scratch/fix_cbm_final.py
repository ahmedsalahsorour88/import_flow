with open('frontend/lib/features/cbm_calculator/screens/cbm_calculator_screen.dart', 'r', encoding='utf-8') as f:
    cbm = f.read()

# Fix line where _buildSavedRegistryTab is called in build()
# Let's inspect how _buildSavedRegistryTab is called in cbm_calculator_screen.dart
idx = cbm.find('_buildSavedRegistryTab(')
print(cbm[idx:idx+150])

# Also get _showContainerComparisonDialog and _showVisualLoadPlanDialog from saved_cbm_registry_tab.dart
with open('frontend/lib/features/cbm_calculator/widgets/saved_cbm_registry_tab.dart', 'r', encoding='utf-8') as f:
    tab_code = f.read()

start_dialog = tab_code.find('  void _showContainerComparisonDialog(')
cbm_dialogs = tab_code[start_dialog:]

# Add cbm_dialogs before _buildSavedRegistryTab in cbm_calculator_screen.dart
idx_tab = cbm.rfind('  Widget _buildSavedRegistryTab(')
cbm = cbm[:idx_tab] + cbm_dialogs + "\n" + cbm[idx_tab:]

# Fix the parameters passed to _buildSavedRegistryTab
cbm = cbm.replace(
    'return _buildSavedRegistryTab(context, state, projects, poList);',
    'return _buildSavedRegistryTab(context, state, importFiles, poList);'
)

with open('frontend/lib/features/cbm_calculator/screens/cbm_calculator_screen.dart', 'w', encoding='utf-8') as f:
    f.write(cbm)

print("Updated cbm_calculator_screen.dart successfully!")
