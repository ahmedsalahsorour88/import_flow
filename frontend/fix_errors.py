import os

path = 'lib/features/customs_consultation/widgets/broker_price_lists_tab.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Add partners_provider
text = text.replace("import '../providers/customs_consultation_provider.dart';", "import '../providers/customs_consultation_provider.dart';\nimport '../../external_service_providers/providers/partners_provider.dart';")

# 2. Add _managementSubTabIndex
text = text.replace("String _mgmtExpenseCategory = 'All';", "String _mgmtExpenseCategory = 'All';\n  int _managementSubTabIndex = 0;")

# 3. Replace _showPriceListFormDialog
text = text.replace('_showPriceListFormDialog', 'showPriceListFormDialog')

# 4. _selectedMgmtBrokerId type issue
text = text.replace("String? _selectedMgmtBrokerId;", "int? _selectedMgmtBrokerId;")
text = text.replace("String _selectedMgmtBrokerId =", "int? _selectedMgmtBrokerId =")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)

# Also fix `customs_consultation_screen.dart` errors
path2 = 'lib/features/customs_consultation/screens/customs_consultation_screen.dart'
with open(path2, 'r', encoding='utf-8') as f:
    text2 = f.read()

# fix `void Function(CustomsConsultationModel)` error on onViewDetails
# because it takes BuildContext too
text2 = text2.replace('SavedConsultationsTab(onEdit: _loadConsultationForEdit, onViewDetails: _showConsultationDetailsDialog)', 'SavedConsultationsTab(onEdit: _loadConsultationForEdit, onViewDetails: (context, saved) => showConsultationDetailsDialog(context, saved))')

text2 = text2.replace('void showDialog(context: context, builder: (ctx) => PostSaveStatusDialog(saved: CustomsConsultationM', '/* void showDialog(context: context, builder: (ctx) => PostSaveStatusDialog(saved: CustomsConsultationM')

with open(path2, 'w', encoding='utf-8') as f:
    f.write(text2)
