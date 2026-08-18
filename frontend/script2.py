import os
import re
import sys

batch1 = [
    "features/cargo_shipping/providers/cargo_shipping_provider.dart",
    "features/currencies/providers/currencies_provider.dart",
    "features/customs_clearance/providers/customs_clearance_provider.dart",
    "features/customs_tariff/providers/customs_tariff_provider.dart",
    "features/file_closure/providers/file_closure_provider.dart",
    "features/financial_settlement/providers/financial_settlement_provider.dart",
    "features/freight_booking/providers/freight_booking_provider.dart",
    "features/freight_quotations/providers/freight_quotations_provider.dart",
    "features/import_requirements/providers/import_requirements_provider.dart",
    "features/notifications/providers/notifications_provider.dart",
    "features/projects/providers/projects_provider.dart",
    "features/transport_locations/providers/transport_locations_provider.dart",
    "features/warehouse_receiving/providers/warehouse_receiving_provider.dart",
    "features/import_companies/providers/import_companies_provider.dart",
    "features/suppliers/providers/suppliers_provider.dart",
    "features/external_service_providers/providers/partners_provider.dart",
    "features/incoterms/providers/incoterms_provider.dart",
    "features/customs_consultation/providers/customs_consultation_provider.dart",
    "features/import_documentation/providers/import_documentation_provider.dart",
    "features/import_files/providers/import_files_provider.dart",
    "features/audit_logs/providers/audit_logs_provider.dart",
    "features/operational_dashboard/providers/operational_dashboard_provider.dart",
    "features/lifecycle_board/providers/lifecycle_board_provider.dart"
]

for file in batch1:
    path = os.path.join("lib", file)
    if not os.path.exists(path):
        continue
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find class name
    class_match = re.search(r'class\s+(\w+)\s+extends\s+(StateNotifier|AsyncNotifier)', content)
    if class_match:
        class_name = class_match.group(1)
        # Fix the provider return statement
        content = re.sub(fr'return\s+{class_name}\(this\._dio\);', f'return {class_name}(ref.read(dioProvider));', content)
        
        # for files that haven't been processed properly, replace `final Dio _dio = Dio(...);` 
        # and update provider definition
        if 'Dio(' in content and 'final Dio _dio = Dio(' in content:
            # We add import if not present
            if "api_client.dart" not in content:
                import_stmt = "import '../../../core/network/api_client.dart';\n"
                imports = re.findall(r'^import .*;$', content, re.MULTILINE)
                if imports:
                    last_import = imports[-1]
                    content = content.replace(last_import, last_import + "\n" + import_stmt)
            
            # replace Dio instantiation
            content = re.sub(r'final\s+Dio\s+_dio\s*=\s*Dio\([\s\S]*?\)\s*\)\s*;', 'final Dio _dio;', content)
            content = re.sub(r'final\s+Dio\s+_dio\s*=\s*Dio\([^;]*\);', 'final Dio _dio;', content)
            
            # update constructor
            if f"{class_name}()" in content:
                content = content.replace(f"{class_name}()", f"{class_name}(this._dio)")
            
            # update provider
            content = re.sub(fr'return\s+{class_name}\(\);', f'return {class_name}(ref.read(dioProvider));', content)

    # For audit_logs_provider, if it defines its own dioProvider, we should rename it to something else, or remove it and use the global one.
    if 'audit_logs_provider.dart' in path:
        # Check if it defines dioProvider
        if 'final dioProvider =' in content:
            content = content.replace('final dioProvider =', 'final auditDioProvider =')
            # But wait, audit_logs_provider might be imported by other files like customs_tariff_provider.
            # Let's just remove the local dioProvider if it's the same, or rename it.

    # Also resolve customs_tariff_provider import conflict
    if 'customs_tariff_provider.dart' in path:
        content = content.replace("import '../../audit_logs/providers/audit_logs_provider.dart';", "import '../../audit_logs/providers/audit_logs_provider.dart' hide dioProvider;")

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Processed {path}")
