import re
with open('lib/features/customs_consultation/screens/customs_consultation_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

import_str = '''
import '../widgets/add_checklist_item_dialog.dart';
import '../widgets/add_custom_broker_expense_row_dialog.dart';
import '../widgets/consultation_metric_badge.dart';
import '../widgets/consultation_status_badges.dart';
import '../widgets/post_save_status_dialog.dart';
'''
if 'add_checklist_item_dialog.dart' not in text:
    text = text.replace("import '../providers/customs_consultation_provider.dart';", "import '../providers/customs_consultation_provider.dart';" + import_str)

def replace_method(text, method_name, new_method_str):
    idx = text.find('  void ' + method_name + '() {')
    if idx == -1:
        idx = text.find('  void ' + method_name + '(CustomsConsultationModel saved) {')
    if idx == -1: return text
    
    end_idx = -1
    brace_count = 0
    in_method = False
    for i in range(idx, len(text)):
        if text[i] == '{':
            brace_count += 1
            in_method = True
        elif text[i] == '}':
            brace_count -= 1
        
        if in_method and brace_count == 0:
            end_idx = i
            break
            
    if end_idx != -1:
        return text[:idx] + new_method_str + text[end_idx+1:]
    return text

new_add_checklist = '''  void _addChecklistItem() async {
    final newItem = await showDialog<CustomsChecklistItemModel>(
      context: context,
      builder: (context) => const AddChecklistItemDialog(),
    );
    if (newItem != null) {
      setState(() {
        _checklist.add(newItem);
      });
    }
  }'''

new_add_expense = '''  void _addCustomBrokerExpenseRow() async {
    final newItem = await showDialog<CustomsBrokerQuoteItemModel>(
      context: context,
      builder: (context) => const AddCustomBrokerExpenseRowDialog(),
    );
    if (newItem != null) {
      setState(() {
        _brokerQuoteItems.add(newItem);
        _calculateBrokerQuote();
      });
    }
  }'''

new_post_save = '''  void _showPostSaveStatusDialog(CustomsConsultationModel saved) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => PostSaveStatusDialog(saved: saved),
    );
  }'''

text = replace_method(text, '_addChecklistItem', new_add_checklist)
text = replace_method(text, '_addCustomBrokerExpenseRow', new_add_expense)
text = replace_method(text, '_showPostSaveStatusDialog', new_post_save)

text = re.sub(r'_buildMetricBadge\(\s*(.*?),\s*(.*?),\s*(.*?)\s*\)', r'ConsultationMetricBadge(title: \1, value: \2, color: \3)', text, flags=re.DOTALL)
text = re.sub(r'_buildMetricBadge\(\s*(.*?),\s*(.*?),\s*(.*?),\s*onTap:\s*(.*?)\s*\)', r'ConsultationMetricBadge(title: \1, value: \2, color: \3, onTap: \4)', text, flags=re.DOTALL)
text = re.sub(r'_buildStatusBadge\((.*?)\)', r'ConsultationStatusBadge(status: \1)', text)
text = re.sub(r'_buildDocItemStatusBadge\((.*?)\)', r'ConsultationDocStatusBadge(status: \1)', text)

text = text.replace('Widget _buildMetricBadge(String title, String value, Color color, {VoidCallback? onTap}) {', 'void _buildMetricBadge() {')
text = replace_method(text, '_buildMetricBadge', '')
text = text.replace('Widget _buildStatusBadge(String status) {', 'void _buildStatusBadge() {')
text = replace_method(text, '_buildStatusBadge', '')
text = text.replace('Widget _buildDocItemStatusBadge(String status) {', 'void _buildDocItemStatusBadge() {')
text = replace_method(text, '_buildDocItemStatusBadge', '')

with open('lib/features/customs_consultation/screens/customs_consultation_screen.dart', 'w', encoding='utf-8') as f:
    f.write(text)
