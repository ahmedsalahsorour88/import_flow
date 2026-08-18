with open('frontend/lib/features/purchase_orders/widgets/po_form_dialog.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
for i, line in enumerate(lines):
    new_lines.append(line)
    if 'padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),' in line and i > 1000 and i < 1150:
        # We find the end of this Container and Row, and inject the warning
        pass

# Let's search for line containing "Text('Line Total" and insert the warning after the Row ends
for i, line in enumerate(lines):
    if 'Line Total' in line and i > 1050 and i < 1120:
        # Find the end of the Row (which contains the Qty, Unit Price, Line Total)
        # Search forward for the closing parenthesis of Row
        row_end = i
        while row_end < len(lines) and '                                       ),' not in lines[row_end]:
            row_end += 1
        
        warning_block = """
                                       // Unregistered HS Code Warning Banner per Item
                                       if (item.tariffId == null || !tariffs.any((t) => t.tariffId == item.tariffId))
                                         Container(
                                           margin: const EdgeInsets.only(top: 8),
                                           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                           decoration: BoxDecoration(
                                             color: Colors.amber.shade50,
                                             borderRadius: BorderRadius.circular(6),
                                             border: Border.all(color: Colors.amber.shade400),
                                           ),
                                           child: Row(
                                             children: [
                                               Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 16),
                                               const SizedBox(width: 6),
                                               Expanded(
                                                 child: Text(
                                                   '⚠️ بند التعريفة الجمركية (HS Code) غير مسجل في جدول التعريفة المعتمد — يرجى اختياره لتطبيق الرسوم الجمركية وضريبة الوارد بدقة.',
                                                   style: TextStyle(
                                                     color: Colors.amber.shade900,
                                                     fontSize: 11,
                                                     fontWeight: FontWeight.w600,
                                                   ),
                                                 ),
                                               ),
                                             ],
                                           ),
                                         ),
"""
        lines.insert(row_end + 1, warning_block)
        break

with open('frontend/lib/features/purchase_orders/widgets/po_form_dialog.dart', 'w', encoding='utf-8') as f:
    f.writelines(lines)
print('DONE')
