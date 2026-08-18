import os
import re

path = 'lib/features/customs_consultation/widgets/blocking_issues_dialog.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Remove the /* and */
text = text.replace('/*\n', '')
text = text.replace('*/\n', '')

# add onUpdate(checklist) inside the onPressed block properly:
# Find:
#                                         checklist[realIndex] = checklist[realIndex].copyWith(
#                                           status: 'Approved',
#                                           verifiedDate: DateTime.now().toString().split(' ')[0],
#                                         );
# And add onUpdate(checklist); after it.
# Actually, the original code was:
#                                       onPressed: () {
#                                         onUpdate(checklist);
#                                           final realIndex = ...
# It's better to just leave it as is but remove the /* and */.
# Wait! I also need to replace the other `onUpdate(checklist);\n/*` if there are any.
text = text.replace('onUpdate(checklist);\n                                          final realIndex', '                                          final realIndex')
text = text.replace('verifiedDate: DateTime.now().toString().split(\' \')[0],\n                                            );\n                                          }', 'verifiedDate: DateTime.now().toString().split(\' \')[0],\n                                            );\n                                            onUpdate(checklist);\n                                          }')

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
