with open('lib/features/customs_tariff/screens/customs_tariff_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# _numToDouble is a helper method
idx = text.find('double _numToDouble(')
if idx != -1:
    end = text.find('}', idx)
    func_text = text[idx:end+1]
    with open('lib/features/customs_tariff/widgets/duty_calculator_dialog.dart', 'r', encoding='utf-8') as df:
        d_text = df.read()
    d_text = d_text + '\n' + func_text + '\n'
    d_text = "import '../services/customs_pdf_service.dart';\n" + d_text
    with open('lib/features/customs_tariff/widgets/duty_calculator_dialog.dart', 'w', encoding='utf-8') as df:
        df.write(d_text)

# _taxDetailRow
idx2 = text.find('Widget _taxDetailRow(')
if idx2 != -1:
    end2 = text.find('}', idx2)
    func_text2 = text[idx2:end2+1]
    with open('lib/features/customs_tariff/widgets/nafeza_details_dialog.dart', 'r', encoding='utf-8') as nf:
        n_text = nf.read()
    n_text = n_text + '\n' + func_text2 + '\n'
    n_text = n_text.replace('_showAddAgreementDialog', 'showAddAgreementDialog')
    n_text = """import '../widgets/add_agreement_dialog.dart';
import '../widgets/tariff_form_dialog.dart';
import '../widgets/verify_tariff_dialog.dart';
""" + n_text
    with open('lib/features/customs_tariff/widgets/nafeza_details_dialog.dart', 'w', encoding='utf-8') as nf:
        nf.write(n_text)

# _buildNafezaRulesList
idx3 = text.find('Widget _buildNafezaRulesList(')
if idx3 != -1:
    # it ends when we see the next widget or void method
    end3 = text.find('void ', idx3)
    if end3 == -1: end3 = text.find('Widget ', idx3+10)
    func_text3 = text[idx3:end3]
    with open('lib/features/customs_tariff/widgets/nafeza_details_dialog.dart', 'a', encoding='utf-8') as nf:
        nf.write('\n' + func_text3)
