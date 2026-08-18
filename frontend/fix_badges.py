import re

with open('lib/features/customs_consultation/screens/customs_consultation_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Replace _buildMetricBadge(title, value, color)
def repl_metric(m):
    # Match the content inside parentheses
    content = m.group(1)
    
    # Simple split by comma but outside quotes would be ideal, but here we can just use a simpler regex
    # The multiline ones are mostly formatted as:
    # _buildMetricBadge(
    #    'title',
    #    'value',
    #    Colors.green
    # )
    #
    # We can split by comma. But values might have commas? Not in this file.
    parts = content.split(',')
    
    title = parts[0].strip()
    value = parts[1].strip()
    color = parts[2].strip()
    
    onTap = ""
    for part in parts[3:]:
        if 'onTap:' in part:
            onTap = ', ' + part.strip()
            
    return f"ConsultationMetricBadge(title: {title}, value: {value}, color: {color}{onTap})"

text = re.sub(r'_buildMetricBadge\(\s*(.*?)\s*\)', repl_metric, text, flags=re.DOTALL)

with open('lib/features/customs_consultation/screens/customs_consultation_screen.dart', 'w', encoding='utf-8') as f:
    f.write(text)
