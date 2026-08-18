import re

# Fix saved_cbm_registry_tab.dart
with open('frontend/lib/features/cbm_calculator/widgets/saved_cbm_registry_tab.dart', 'r', encoding='utf-8') as f:
    cbm = f.read()

# Add math and projects imports if missing
if "import 'dart:math' as math;" not in cbm:
    cbm = "import 'dart:math' as math;\nimport '../../projects/providers/projects_provider.dart';\n" + cbm

# Replace CBMCalculationModel -> CBMCalculationSessionModel
cbm = re.sub(r'\bCBMCalculationModel\b', 'CBMCalculationSessionModel', cbm)
cbm = cbm.replace('_loadSessionForEditing', 'widget.onLoadSession')

with open('frontend/lib/features/cbm_calculator/widgets/saved_cbm_registry_tab.dart', 'w', encoding='utf-8') as f:
    f.write(cbm)

print("Fixed saved_cbm_registry_tab.dart!")

# Fix saved_scenarios_registry_tab.dart
with open('frontend/lib/features/shipping_scenarios/widgets/saved_scenarios_registry_tab.dart', 'r', encoding='utf-8') as f:
    scen = f.read()

scen = scen.replace('ref.watch(projectsProvider).projects', 'ref.watch(projectsProvider).value ?? []')
scen = scen.replace('_loadSessionForEditing(sess)', 'widget.onEditSession(sess)')

with open('frontend/lib/features/shipping_scenarios/widgets/saved_scenarios_registry_tab.dart', 'w', encoding='utf-8') as f:
    f.write(scen)

print("Fixed saved_scenarios_registry_tab.dart!")
