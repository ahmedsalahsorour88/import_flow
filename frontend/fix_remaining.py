import os
import re

path = 'lib/features/customs_consultation/screens/customs_consultation_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Fix _showPostSaveStatusDialog
text = re.sub(r'_showPostSaveStatusDialog\((.*?)\)', r'showDialog(context: context, builder: (ctx) => PostSaveStatusDialog(saved: \1))', text)

# 2. Fix _buildMetricBadge
text = re.sub(r'_buildMetricBadge\(\s*([^,]+),\s*([^,]+),\s*([^,\)]+)\s*\)', r'ConsultationMetricBadge(title: \1, value: \2, color: \3)', text)

# 3. Fix final _checklist assignment
text = text.replace('(val) => setState(() => _checklist = val)', '(val) => setState(() { _checklist.clear(); _checklist.addAll(val); })')

# 4. Fix showAddExpenseTypeDialog onTap
text = text.replace('onTap: showAddExpenseTypeDialog(context, ref)', 'onTap: () => showAddExpenseTypeDialog(context, ref)')

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)

# 5. Fix add_expense_type_dialog.dart mounted
exp_path = 'lib/features/customs_consultation/widgets/add_expense_type_dialog.dart'
with open(exp_path, 'r', encoding='utf-8') as f:
    exp_text = f.read()
exp_text = exp_text.replace('if (!mounted) return;', 'if (!context.mounted) return;')
with open(exp_path, 'w', encoding='utf-8') as f:
    f.write(exp_text)

# 6. Fix blocking_issues_dialog.dart regex mess
block_path = 'lib/features/customs_consultation/widgets/blocking_issues_dialog.dart'
with open(block_path, 'r', encoding='utf-8') as f:
    block_text = f.read()
# Let's just fix the broken syntax. The error was `174:60 - Expected to find ';'.` and `unterminated_multi_line_comment`.
# I will just write a clean replace for the file contents.
