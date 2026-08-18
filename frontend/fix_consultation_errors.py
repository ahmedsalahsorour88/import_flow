import os

# 1. Revert broker_price_lists_view.dart back into customs_consultation_screen.dart
path = 'lib/features/customs_consultation/screens/customs_consultation_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

with open('lib/features/customs_consultation/widgets/broker_price_lists_view.dart', 'r', encoding='utf-8') as f:
    broker_text = f.read()

# find body
start = broker_text.find('Widget buildBrokerPriceListsView')
body = broker_text[start:]
body = body.replace('Widget buildBrokerPriceListsView', 'Widget _buildBrokerPriceListsView')

# append to end of _CustomsConsultationScreenState
for i in range(len(lines)-1, -1, -1):
    if lines[i].strip() == '}':
        lines.insert(i, body + '\n')
        break

# fix usages back
for i in range(len(lines)):
    lines[i] = lines[i].replace('buildBrokerPriceListsView(', '_buildBrokerPriceListsView(')

# remove import
lines = [l for l in lines if 'broker_price_lists_view.dart' not in l]

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(lines)


# 2. Fix _showPostSaveStatusDialog and _buildMetricBadge in customs_consultation_screen.dart
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace('_showPostSaveStatusDialog(', 'showDialog(context: context, builder: (ctx) => PostSaveStatusDialog(saved: ')
import re
text = re.sub(r'_buildMetricBadge\(\s*([^,]+),\s*([^,]+),\s*([^,\)]+)\s*\)', r'ConsultationMetricBadge(title: \1, value: \2, color: \3)', text)

# fix _addCustomBrokerExpenseRow replacing issue (it deleted _calculateBrokerQuote() definition?)
# Wait, why is _calculateBrokerQuote undefined?
# Did my script extract it? Let's check if `_calculateBrokerQuote` is in the file.
