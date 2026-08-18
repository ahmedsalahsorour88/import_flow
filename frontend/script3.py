import re

def process(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Add import
    if "api_client.dart" not in content:
        import_stmt = "import '../../../core/network/api_client.dart';\n"
        imports = re.findall(r'^import .*;$', content, re.MULTILINE)
        if imports:
            last_import = imports[-1]
            content = content.replace(last_import, last_import + "\n" + import_stmt)

    # Find all Notifier classes
    class_matches = re.finditer(r'class\s+(\w+)\s+extends\s+StateNotifier<', content)
    
    for match in class_matches:
        class_name = match.group(1)
        
        # update provider returning it
        # return ClassName();
        # return ClassName(ref: ref);
        # return ClassName(ref: ref, ...);
        
        provider_calls = re.findall(fr'return\s+{class_name}\((.*?)\);', content)
        for args in provider_calls:
            new_args = args.strip()
            if new_args == '':
                new_args = "ref.read(dioProvider)"
            else:
                new_args += ", dio: ref.read(dioProvider)"
            content = content.replace(f"return {class_name}({args});", f"return {class_name}({new_args});")
            
        # replace final Dio _dio = ...;
        content = re.sub(r'final\s+Dio\s+_dio\s*=\s*Dio\([^)]*\)\s*;', 'final Dio _dio;', content)
        content = re.sub(r'final\s+Dio\s+_dio\s*=\s*Dio\([\s\S]*?\)\s*\)\s*;', 'final Dio _dio;', content)
        content = re.sub(r'final\s+Dio\s+_dio\s*=\s*Dio\([^;]*\);', 'final Dio _dio;', content)
        
        # update constructor
        # ClassName() : super(...)
        # ClassName({this.ref}) : super(...)
        # ClassName({this.ref, required this.showInactive}) : super(...)
        
        constr_matches = re.finditer(fr'{class_name}\((.*?)\)\s*:\s*super', content)
        for c_match in constr_matches:
            c_args = c_match.group(1)
            original_c = f"{class_name}({c_args}) :"
            if c_args.strip() == '':
                new_c = f"{class_name}(this._dio) :"
            else:
                if c_args.endswith('}'):
                    new_c_args = c_args[:-1] + ", required Dio dio}"
                else:
                    new_c_args = c_args + ", required Dio dio"
                new_c = f"{class_name}({new_c_args}) : _dio = dio,"
            
            content = content.replace(original_c, new_c)
            
    # Specially handle POReconciliationService which is a regular Provider
    if "POReconciliationService" in content:
        content = content.replace("final dio = Dio();", "final dio = ref.watch(dioProvider);")
        
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
        
process("lib/features/import_documentation/providers/import_documentation_provider.dart")
process("lib/features/operational_dashboard/providers/operational_dashboard_provider.dart")
process("lib/features/lifecycle_board/providers/lifecycle_board_provider.dart")
