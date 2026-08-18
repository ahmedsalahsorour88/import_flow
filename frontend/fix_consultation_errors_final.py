import os
import re

path = 'lib/features/customs_consultation/screens/customs_consultation_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Fix _showPostSaveStatusDialog
text = text.replace('_showPostSaveStatusDialog(saved)', 'showDialog(context: context, builder: (ctx) => PostSaveStatusDialog(saved: saved))')

# 2. Fix _buildMetricBadge
text = re.sub(r'_buildMetricBadge\(\s*([^,]+),\s*([^,]+),\s*([^,\)]+)\s*\)', r'ConsultationMetricBadge(title: \1, value: \2, color: \3)', text)

# 3. Remove _calculateBrokerQuote()
text = text.replace('_calculateBrokerQuote();', '')

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)

# 4. Fix widgets/add_expense_type_dialog.dart
exp_path = 'lib/features/customs_consultation/widgets/add_expense_type_dialog.dart'
with open(exp_path, 'r', encoding='utf-8') as f:
    exp_text = f.read()
exp_text = exp_text.replace('void showAddExpenseTypeDialog()', 'void showAddExpenseTypeDialog(BuildContext context, WidgetRef ref)')
exp_text = exp_text.replace('if (!mounted) return;', 'if (!context.mounted) return;')
with open(exp_path, 'w', encoding='utf-8') as f:
    f.write(exp_text)

# 5. Fix blocking_issues_dialog.dart
block_path = 'lib/features/customs_consultation/widgets/blocking_issues_dialog.dart'
with open(block_path, 'r', encoding='utf-8') as f:
    block_text = f.read()
block_text = block_text.replace('void showBlockingIssuesDialog(BuildContext context, List<CustomsChecklistItemModel> checklist)', 'void showBlockingIssuesDialog(BuildContext context, List<CustomsChecklistItemModel> checklist, Function(List<CustomsChecklistItemModel>) onUpdate)')
block_text = block_text.replace('setState(() {', 'onUpdate(checklist);\n/*')
block_text = block_text.replace('});\n          }', '*/\n          }')
# Wait, it's better to just regex replace the setState block.
# Actually, inside blocking_issues_dialog:
#   setState(() {
#     checklist[index] = item.copyWith(status: val ? 'Approved' : 'Pending');
#   });
# We can replace it with:
#   checklist[index] = item.copyWith(status: val ? 'Approved' : 'Pending');
#   onUpdate(checklist);
block_text = re.sub(r'setState\(\(\)\s*\{\s*(.*?)\s*\}\);', r'\1\n                                onUpdate(checklist);', block_text, flags=re.DOTALL)

with open(block_path, 'w', encoding='utf-8') as f:
    f.write(block_text)

# fix call in customs_consultation_screen.dart
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()
text = text.replace('showBlockingIssuesDialog(context, _checklist)', 'showBlockingIssuesDialog(context, _checklist, (val) => setState(() => _checklist = val))')
# fix call in _showAddExpenseTypeDialog
text = text.replace('showAddExpenseTypeDialog()', 'showAddExpenseTypeDialog(context, ref)')
with open(path, 'w', encoding='utf-8') as f:
    f.write(text)

