with open('frontend/lib/features/shipping_scenarios/screens/shipping_scenarios_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if line.startswith('  Widget ') or line.startswith('  void ') or line.startswith('  Future<') or line.startswith('  static Widget '):
        print(f"Line {i+1}: {line.strip()}")
