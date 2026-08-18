def add_todo(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if "TODO: Refactor" not in content:
        content = "// TODO: Refactor to ConsumerWidget to use dioProvider/uploadDioProvider\n" + content
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)

add_todo("lib/core/widgets/master_data_toolbar.dart")
add_todo("lib/core/widgets/smart_upload_button.dart")
add_todo("lib/core/widgets/universal_entity_extractor_dialog.dart")
