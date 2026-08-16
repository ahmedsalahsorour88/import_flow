file_path = r'c:\Users\Hp\Desktop\ImportFlow\frontend\lib\features\import_documentation\screens\import_documentation_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Ensure state variables are declared
if 'int _matrixViewMode' not in code:
    code = code.replace(
        'class _ImportDocumentationScreenState extends ConsumerState<ImportDocumentationScreen>\n    with SingleTickerProviderStateMixin {\n  late TabController _tabController;',
        '''class _ImportDocumentationScreenState extends ConsumerState<ImportDocumentationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _matrixViewMode = 0;
  String _comparisonAuditSearch = '';
  final Map<String, bool> _form4DocsChecklist = {
    'proforma_invoice': true,
    'packing_list': true,
    'certificate_of_origin': true,
    'bill_of_lading': true,
    'acid_notice': true,
    'marine_insurance': true,
    'bank_application': true,
    'admin_fee_receipt': true,
  };'''
    )

# 2. In _buildForm4RequestTab, invoke _buildForm4DocsChecklist()
# Search for _form4NotesCtrl field and the save button
old_notes_field = '''                        controller: _form4NotesCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'ملاحظات طلب نموذج 4 والتعليمات المصرفية',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.notes),
                        ),
                      ),
                    ),'''

new_notes_field = '''                        controller: _form4NotesCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'ملاحظات طلب نموذج 4 والتعليمات المصرفية',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.notes),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildForm4DocsChecklist(),'''

if old_notes_field in code:
    code = code.replace(old_notes_field, new_notes_field, 1)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(code)

print('State variables and checklist call applied!')
