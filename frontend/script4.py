import re

def process_screen(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Add import flutter_riverpod and api_client
    if "api_client.dart" not in content:
        import_stmt = "import 'package:flutter_riverpod/flutter_riverpod.dart';\nimport '../../../core/network/api_client.dart';\n"
        imports = re.findall(r'^import .*;$', content, re.MULTILINE)
        if imports:
            last_import = imports[-1]
            content = content.replace(last_import, last_import + "\n" + import_stmt)

    # Change StatefulWidget to ConsumerStatefulWidget
    content = content.replace("extends StatefulWidget", "extends ConsumerStatefulWidget")
    
    # Change State< to ConsumerState<
    content = content.replace("extends State<", "extends ConsumerState<")
    
    # Replace Dio instantiations
    content = re.sub(r"final\s+dio\s*=\s*Dio\([^)]*\);", "final dio = ref.read(dioProvider);", content)
    content = re.sub(r"await\s+Dio\([^)]*\)\.post", "await ref.read(dioProvider).post", content)

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
        
process_screen("lib/features/financial_settlement/screens/landed_cost_comparison_screen.dart")
process_screen("lib/features/freight_quotations/screens/freight_quotations_comparison_screen.dart")
