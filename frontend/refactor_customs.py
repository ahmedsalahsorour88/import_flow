import re

with open('lib/features/customs_consultation/screens/customs_consultation_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Manual literal replaces for metric badges
text = text.replace("""                    _buildMetricBadge(
                        '✅ معتمدة', '${approved.length} مستند', Colors.green),""",
"""                    ConsultationMetricBadge(title: '✅ معتمدة', value: '${approved.length} مستند', color: Colors.green),""")

text = text.replace("""                    _buildMetricBadge(
                        '⏳ قيد الانتظار',
                        '${pending.length} مستند',
                        Colors.orange),""",
"""                    ConsultationMetricBadge(title: '⏳ قيد الانتظار', value: '${pending.length} مستند', color: Colors.orange),""")

text = text.replace("""                    _buildMetricBadge(
                        '🚫 عوائق التخليص',
                        '${blocking.length} بند',
                        blocking.isNotEmpty ? Colors.red : Colors.green),""",
"""                    ConsultationMetricBadge(title: '🚫 عوائق التخليص', value: '${blocking.length} بند', color: blocking.isNotEmpty ? Colors.red : Colors.green),""")

text = text.replace("""                    _buildMetricBadge(
                        '📊 نسبة الجاهزية',
                        '${saved.readinessPercentage.toStringAsFixed(0)}%',
                        Colors.blue),""",
"""                    ConsultationMetricBadge(title: '📊 نسبة الجاهزية', value: '${saved.readinessPercentage.toStringAsFixed(0)}%', color: Colors.blue),""")

text = text.replace("""                      _buildMetricBadge(
                        'عوائق التخليص (Blocking)',
                        '$blockingCount',
                        blockingCount > 0 ? Colors.red : Colors.green,
                        onTap: _showBlockingIssuesDialog,
                      ),""",
"""                      ConsultationMetricBadge(
                        title: 'عوائق التخليص (Blocking)',
                        value: '$blockingCount',
                        color: blockingCount > 0 ? Colors.red : Colors.green,
                        onTap: _showBlockingIssuesDialog,
                      ),""")

text = text.replace("""                        _buildMetricBadge(
                            'إجمالي الدراسات', '$totalCount دراسة', AppTheme.charcoal),""",
"""                        ConsultationMetricBadge(title: 'إجمالي الدراسات', value: '$totalCount دراسة', color: AppTheme.charcoal),""")

text = text.replace("""                        _buildMetricBadge(
                            'جاهزة للتخليص', '$readyCount', AppTheme.emerald),""",
"""                        ConsultationMetricBadge(title: 'جاهزة للتخليص', value: '$readyCount', color: AppTheme.emerald),""")

text = text.replace("""                        _buildMetricBadge(
                            'عوائق مفتوحة',
                            '$blockedCount',
                            blockedCount > 0
                                ? AppTheme.crimson
                                : Colors.grey),""",
"""                        ConsultationMetricBadge(
                            title: 'عوائق مفتوحة',
                            value: '$blockedCount',
                            color: blockedCount > 0 ? AppTheme.crimson : Colors.grey),""")

text = text.replace("""                        _buildMetricBadge(
                            'متوسط الجاهزية',
                            '${avgReadiness.toStringAsFixed(0)}%',
                            AppTheme.cobalt)""",
"""                        ConsultationMetricBadge(
                            title: 'متوسط الجاهزية',
                            value: '${avgReadiness.toStringAsFixed(0)}%',
                            color: AppTheme.cobalt)""")

# 2. Replace _buildStatusBadge calls
text = re.sub(r'_buildStatusBadge\((.*?)\)', r'ConsultationStatusBadge(status: \1)', text)

# 3. Replace _buildDocItemStatusBadge calls
text = re.sub(r'_buildDocItemStatusBadge\((.*?)\)', r'ConsultationDocStatusBadge(status: \1)', text)

# 4. Remove widget definitions from bottom of file
# They are near the very end of the file.
text = re.sub(r'  Widget _buildMetricBadge.*?Widget _buildDocItemStatusBadge.*?\n  }\n}\n', '}\n', text, flags=re.DOTALL)

# 5. Add imports
import_str = """
import '../widgets/add_checklist_item_dialog.dart';
import '../widgets/add_custom_broker_expense_row_dialog.dart';
import '../widgets/consultation_metric_badge.dart';
import '../widgets/consultation_status_badges.dart';
import '../widgets/post_save_status_dialog.dart';
"""
text = text.replace("import '../providers/customs_consultation_provider.dart';", "import '../providers/customs_consultation_provider.dart';" + import_str)

# 6. Replace _addChecklistItem
old_add_checklist = r"""  void _addChecklistItem\(\) \{[\s\S]*?            \);\n          \},\n        \);\n      \},\n    \);\n  \}"""
new_add_checklist = """  void _addChecklistItem() async {
    final newItem = await showDialog<CustomsChecklistItemModel>(
      context: context,
      builder: (context) => const AddChecklistItemDialog(),
    );
    if (newItem != null) {
      setState(() {
        _checklist.add(newItem);
      });
    }
  }"""
text = re.sub(old_add_checklist, new_add_checklist, text)

# 7. Replace _addCustomBrokerExpenseRow
old_add_expense = r"""  void _addCustomBrokerExpenseRow\(\) \{[\s\S]*?            \);\n          \},\n        \);\n      \},\n    \);\n  \}"""
new_add_expense = """  void _addCustomBrokerExpenseRow() async {
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
  }"""
text = re.sub(old_add_expense, new_add_expense, text)

# 8. Replace _showPostSaveStatusDialog
old_post_save = r"""  /// Shows a post-save status dialog summarising each checklist item's state.\n  void _showPostSaveStatusDialog.*?إغلاق والعودة لسجل الدراسات'\),\n          \),\n        \],\n      \),\n    \);\n  \}"""
new_post_save = """  void _showPostSaveStatusDialog(CustomsConsultationModel saved) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => PostSaveStatusDialog(saved: saved),
    );
  }"""
text = re.sub(old_post_save, new_post_save, text, flags=re.DOTALL)

with open('lib/features/customs_consultation/screens/customs_consultation_screen.dart', 'w', encoding='utf-8') as f:
    f.write(text)
