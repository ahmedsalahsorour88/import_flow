# Fix cbm_calculator_screen.dart
with open('frontend/lib/features/cbm_calculator/screens/cbm_calculator_screen.dart', 'r', encoding='utf-8') as f:
    cbm = f.read()

if "import '../../projects/models/project_model.dart';" not in cbm:
    import_idx = cbm.find('import ')
    cbm = cbm[:import_idx] + "import '../../projects/models/project_model.dart';\n" + cbm[import_idx:]

cbm = cbm.replace("import '../../../core/widgets/row_actions_pill.dart';\n", "")

with open('frontend/lib/features/cbm_calculator/screens/cbm_calculator_screen.dart', 'w', encoding='utf-8') as f:
    f.write(cbm)

# Fix shipping_scenarios_screen.dart
with open('frontend/lib/features/shipping_scenarios/screens/shipping_scenarios_screen.dart', 'r', encoding='utf-8') as f:
    scen = f.read()

scen = scen.replace("import '../../../core/widgets/master_data_toolbar.dart';\n", "")
scen = scen.replace("import '../../../core/widgets/row_actions_pill.dart';\n", "")

with open('frontend/lib/features/shipping_scenarios/screens/shipping_scenarios_screen.dart', 'w', encoding='utf-8') as f:
    f.write(scen)

# Fix saved_cbm_registry_tab.dart
with open('frontend/lib/features/cbm_calculator/widgets/saved_cbm_registry_tab.dart', 'r', encoding='utf-8') as f:
    cbm_tab = f.read()

cbm_tab = cbm_tab.replace("import '../../../core/widgets/master_data_toolbar.dart';\n", "")
cbm_tab = cbm_tab.replace("import '../../../core/widgets/error_details_dialog.dart';\n", "")
cbm_tab = cbm_tab.replace("import '../../../core/widgets/change_diff_dialog.dart';\n", "")
cbm_tab = cbm_tab.replace("import '../../import_files/models/import_file_model.dart';\n", "")
cbm_tab = cbm_tab.replace("import '../../purchase_orders/models/purchase_order_model.dart';\n", "")

with open('frontend/lib/features/cbm_calculator/widgets/saved_cbm_registry_tab.dart', 'w', encoding='utf-8') as f:
    f.write(cbm_tab)

# Fix saved_scenarios_registry_tab.dart
with open('frontend/lib/features/shipping_scenarios/widgets/saved_scenarios_registry_tab.dart', 'r', encoding='utf-8') as f:
    scen_tab = f.read()

scen_tab = scen_tab.replace("import '../../../core/widgets/change_diff_dialog.dart';\n", "")
scen_tab = scen_tab.replace("import '../../../core/widgets/searchable_dropdown_field.dart';\n", "")
scen_tab = scen_tab.replace("import '../../../core/widgets/error_details_dialog.dart';\n", "")
scen_tab = scen_tab.replace("import '../../currencies/models/currency_model.dart';\n", "")
scen_tab = scen_tab.replace("import '../../currencies/providers/currencies_provider.dart';\n", "")

with open('frontend/lib/features/shipping_scenarios/widgets/saved_scenarios_registry_tab.dart', 'w', encoding='utf-8') as f:
    f.write(scen_tab)

print("Cleaned up unused imports across all files!")
