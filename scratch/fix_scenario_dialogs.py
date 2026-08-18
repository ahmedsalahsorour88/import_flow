with open('frontend/lib/features/shipping_scenarios/widgets/saved_scenarios_registry_tab.dart', 'r', encoding='utf-8') as f:
    tab_code = f.read()

# Extract _showContainerComparisonDialog and _showVisualLoadPlanDialog and _buildLoadMetricPill
start_dialog = tab_code.find('  void _showContainerComparisonDialog(')
dialog_code = tab_code[start_dialog:]

with open('frontend/lib/features/shipping_scenarios/screens/shipping_scenarios_screen.dart', 'r', encoding='utf-8') as f:
    screen_code = f.read()

idx = screen_code.find('  Widget _buildHistoryRegistryTab(')
screen_code = screen_code[:idx] + dialog_code + "\n" + screen_code[idx:]

with open('frontend/lib/features/shipping_scenarios/screens/shipping_scenarios_screen.dart', 'w', encoding='utf-8') as f:
    f.write(screen_code)

print("Added dialogs to shipping_scenarios_screen.dart!")
