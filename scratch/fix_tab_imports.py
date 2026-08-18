import re

# Fix saved_scenarios_registry_tab.dart
with open('frontend/lib/features/shipping_scenarios/widgets/saved_scenarios_registry_tab.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Add missing imports
imports = """import 'package:flutter/services.dart';
import '../../../core/utils/container_requirement_engine.dart';
"""
text = imports + text

with open('frontend/lib/features/shipping_scenarios/widgets/saved_scenarios_registry_tab.dart', 'w', encoding='utf-8') as f:
    f.write(text)

# Fix saved_cbm_registry_tab.dart
with open('frontend/lib/features/cbm_calculator/widgets/saved_cbm_registry_tab.dart', 'r', encoding='utf-8') as f:
    cbm_text = f.read()

cbm_imports = """import 'package:flutter/services.dart';
import '../../../core/utils/container_requirement_engine.dart';
"""
cbm_text = cbm_imports + cbm_text

with open('frontend/lib/features/cbm_calculator/widgets/saved_cbm_registry_tab.dart', 'w', encoding='utf-8') as f:
    f.write(cbm_text)

print("Added missing imports to both extracted widgets!")
