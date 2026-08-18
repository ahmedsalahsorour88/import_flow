import os

with open('frontend/lib/features/shipping_scenarios/widgets/saved_scenarios_registry_tab.dart', 'r', encoding='utf-8') as f:
    tab_lines = f.readlines()

# Locate _saveEvaluationSession start and _showSessionDetailsDialog start
save_start = -1
save_end = -1
for i, l in enumerate(tab_lines):
    if 'Future<void> _saveEvaluationSession(' in l:
        save_start = i
    if 'void _showSessionDetailsDialog(' in l:
        save_end = i
        break

print(f"save_start: {save_start}, save_end: {save_end}")

evaluator_methods = "".join(tab_lines[save_start:save_end])
clean_tab_lines = tab_lines[:save_start] + tab_lines[save_end:]

with open('frontend/lib/features/shipping_scenarios/widgets/saved_scenarios_registry_tab.dart', 'w', encoding='utf-8') as f:
    f.writelines(clean_tab_lines)

print("Cleaned saved_scenarios_registry_tab.dart!")

with open('frontend/lib/features/shipping_scenarios/screens/shipping_scenarios_screen.dart', 'r', encoding='utf-8') as f:
    screen_code = f.read()

# Insert evaluator_methods before _buildHistoryRegistryTab
idx = screen_code.find('  Widget _buildHistoryRegistryTab(')
screen_code = screen_code[:idx] + evaluator_methods + "\n" + screen_code[idx:]

with open('frontend/lib/features/shipping_scenarios/screens/shipping_scenarios_screen.dart', 'w', encoding='utf-8') as f:
    f.write(screen_code)

print("Updated shipping_scenarios_screen.dart with evaluator methods!")
