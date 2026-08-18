import os

path = 'lib/features/customs_consultation/screens/customs_consultation_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

start = -1
for i, l in enumerate(lines):
    if 'void showDialog(context: context, builder: (ctx) => PostSaveStatusDialog(saved: CustomsConsultationM' in l:
        start = i
        break

if start != -1:
    brace_count = 0
    end = -1
    for i in range(start, len(lines)):
        brace_count += lines[i].count('{') - lines[i].count('}')
        if brace_count == 0 and '{' in ''.join(lines[start:i+1]):
            end = i
            break
    
    del lines[start:end+1]

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(lines)
