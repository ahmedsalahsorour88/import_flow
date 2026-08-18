import os
import re
import sys

def process_file(filepath, import_path):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    if 'Dio(' not in content and 'dioProvider' in content:
        print(f"Skipping {filepath}, already processed")
        return

    # Add import
    if "api_client.dart" not in content:
        import_stmt = f"import '{import_path}';\n"
        # insert after last import
        imports = re.findall(r'^import .*;$', content, re.MULTILINE)
        if imports:
            last_import = imports[-1]
            content = content.replace(last_import, last_import + "\n" + import_stmt)
        else:
            content = import_stmt + content

    # Replace Dio() instantiations
    # Usually it's `final Dio _dio = Dio(...);` inside a StateNotifier class.
    # We want to change it to `final Dio _dio;` and update constructor.

    # Find the class and its constructor
    class_match = re.search(r'class\s+(\w+)\s+extends\s+(StateNotifier|AsyncNotifier)[\w<, >]*\s*\{', content)
    if class_match:
        class_name = class_match.group(1)
        
        # Replace `final Dio _dio = Dio(...);` with `final Dio _dio;`
        content = re.sub(r'final\s+Dio\s+_dio\s*=\s*Dio\([^)]*\)\s*;', 'final Dio _dio;', content, flags=re.DOTALL)
        content = re.sub(r'final\s+Dio\s+_dio\s*=\s*Dio\([^)]*\)\s*\)\s*;', 'final Dio _dio;', content, flags=re.DOTALL)
        # generic catch for multiline Dio(BaseOptions(...));
        content = re.sub(r'final\s+Dio\s+_dio\s*=\s*Dio\([\s\S]*?\)\s*\)\s*;', 'final Dio _dio;', content)
        content = re.sub(r'final\s+Dio\s+_dio\s*=\s*Dio\([^;]*\);', 'final Dio _dio;', content)
        
        # Now update the constructor to accept _dio
        # e.g., CargoShippingNotifier() : super(...) -> CargoShippingNotifier(this._dio) : super(...)
        # e.g., CurrenciesNotifier() { -> CurrenciesNotifier(this._dio) {
        
        if f"{class_name}()" in content:
            content = content.replace(f"{class_name}()", f"{class_name}(this._dio)")
        else:
            # Maybe there are other parameters, not modifying for now, will do manually if needed
            print(f"Manual intervention might be needed for constructor in {filepath}")
        
        # Now update the provider definition
        provider_match = re.search(f'return\s+{class_name}\(\);', content)
        if provider_match:
            content = content.replace(f'return {class_name}();', f'return {class_name}(ref.read(dioProvider));')
        
        # if using AsyncNotifier, there is no provider wrapper in the same way (usually annotated or build method)
        # We'll see if we need to handle AsyncNotifier differently
        
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Processed {filepath}")

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
    "features/warehouse_receiving/providers/warehouse_receiving_provider.dart"
]

for file in batch1:
    path = os.path.join("lib", file)
    if os.path.exists(path):
        process_file(path, "../../../core/network/api_client.dart")
    else:
        print(f"File not found: {path}")

