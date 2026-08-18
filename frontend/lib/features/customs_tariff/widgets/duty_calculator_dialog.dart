import '../services/customs_pdf_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../models/customs_tariff_model.dart';
import '../providers/customs_tariff_provider.dart';

  void showDutyCalculatorDialog(BuildContext context, WidgetRef ref,
      {String? initialHsCode}) {
    String selectedCurrency = 'USD';
    String selectedFreightCurrency = 'USD';

    final Map<String, double> defaultExchangeRates = {
      'USD': 50.7917,
      'EUR': 55.2000,
      'GBP': 64.5000,
      'CNY': 7.1000,
      'SAR': 13.5400,
      'AED': 13.8200,
      'EGP': 1.0000,
    };

    final exchangeRateCtrl = TextEditingController(text: '50.7917');
    final totalInvoiceFcCtrl = TextEditingController(text: '11736.40');
    final insuranceCtrl = TextEditingController(text: '14902.793');
    final deemedInsuranceCtrl = TextEditingController(text: '0.00');
    final freightForeignCtrl = TextEditingController(text: '234.72');
    final freightExchangeRateCtrl = TextEditingController(text: '50.7917');
    final multiFreightCtrl = TextEditingController(text: '11922.234');
    final deemedFreightCtrl = TextEditingController(text: '0.00');
    final additionalFeesCtrl = TextEditingController(text: '1329.50');
    final declaredCifCtrl = TextEditingController(text: '623000.00');

    String insuranceType = 'actual';
    String freightType = 'actual';

    double computeTotalInvoiceFc(List<Map<String, dynamic>> lines) {
      double total = 0;
      for (final m in lines) {
        final val = double.tryParse(
                (m['value'] as TextEditingController).text.trim()) ??
            0;
        total += val;
      }
      return total;
    }

    double computeTotalFobEgp(List<Map<String, dynamic>> lines) {
      final rate = double.tryParse(exchangeRateCtrl.text.trim()) ?? 50.7917;
      return computeTotalInvoiceFc(lines) * rate;
    }

    void recalcDeemedInsurance(
        StateSetter setState, List<Map<String, dynamic>> lines) {
      if (insuranceType != 'deemed') return;
      final deemed = computeTotalFobEgp(lines) * 0.025;
      setState(() {
        deemedInsuranceCtrl.text = deemed.toStringAsFixed(3);
        insuranceCtrl.text = '0.00';
      });
    }

    void recalcDeemedFreight(
        StateSetter setState, List<Map<String, dynamic>> lines) {
      if (freightType != 'deemed') return;
      final deemed = computeTotalFobEgp(lines) * 0.020;
      setState(() {
        deemedFreightCtrl.text = deemed.toStringAsFixed(3);
        multiFreightCtrl.text = '0.00';
      });
    }

    void syncCalculatedFields(
        StateSetter setState, List<Map<String, dynamic>> lines) {
      final totalFc = computeTotalInvoiceFc(lines);
      final rate = double.tryParse(exchangeRateCtrl.text.trim()) ?? 50.7917;
      final fobEgp = totalFc * rate;

      if (insuranceType == 'deemed') {
        final deemedIns = fobEgp * 0.025;
        deemedInsuranceCtrl.text = deemedIns.toStringAsFixed(3);
        insuranceCtrl.text = '0.00';
      }

      if (freightType == 'deemed') {
        final deemedFrt = fobEgp * 0.020;
        deemedFreightCtrl.text = deemedFrt.toStringAsFixed(3);
        multiFreightCtrl.text = '0.00';
      } else {
        final fAmt = double.tryParse(freightForeignCtrl.text.trim()) ?? 0;
        final fRate = selectedFreightCurrency == 'EGP'
            ? 1.0
            : (double.tryParse(freightExchangeRateCtrl.text.trim()) ?? rate);
        final calcFrtEgp = fAmt * fRate;
        multiFreightCtrl.text = calcFrtEgp.toStringAsFixed(3);
      }

      final actualIns = double.tryParse(insuranceCtrl.text.trim()) ?? 0;
      final deemedIns = double.tryParse(deemedInsuranceCtrl.text.trim()) ?? 0;
      final effectiveIns = insuranceType == 'deemed' ? deemedIns : actualIns;

      final actualFrt = double.tryParse(multiFreightCtrl.text.trim()) ?? 0;
      final deemedFrt = double.tryParse(deemedFreightCtrl.text.trim()) ?? 0;
      final effectiveFrt = freightType == 'deemed' ? deemedFrt : actualFrt;

      final calculatedCifEgp = fobEgp + effectiveIns + effectiveFrt;

      setState(() {
        totalInvoiceFcCtrl.text = totalFc.toStringAsFixed(2);
        declaredCifCtrl.text = calculatedCifEgp.toStringAsFixed(2);
      });
    }

    List<Map<String, dynamic>> multiLines = [
      {
        'hs': TextEditingController(text: initialHsCode ?? '8536.41.00'),
        'value': TextEditingController(text: '607.6'),
        'inspection': TextEditingController(text: '0.00'),
        'origin': 'CN',
        'exemption': null,
      },
      {
        'hs': TextEditingController(text: '8537.10.90'),
        'value': TextEditingController(text: '4371.2'),
        'inspection': TextEditingController(text: '8514.81'),
        'origin': 'TR',
        'exemption': null,
      },
      {
        'hs': TextEditingController(text: '8537.10.90'),
        'value': TextEditingController(text: '6757.6'),
        'inspection': TextEditingController(text: '69772.09'),
        'origin': 'DE',
        'exemption': null,
      },
    ];

    Map<String, dynamic>? multiResult;
    String? multiError;
    bool isMultiCalculating = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setCalcState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.calculate, color: AppTheme.emerald),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Egyptian Customs Duty Calculator (حاسبة الجمارك المصرية — منصة نافذة)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 860,
            height: 620,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'حساب الجمارك لشحنة متعددة الأصناف وفق نموذج منصة نافذة (Nafeza Statement)',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.orange,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                        ),
                        icon: const Icon(Icons.downloading, size: 14),
                        label: const Text(
                            'تحميل مثال نافذة الفعلي (2026-612-1-94731)',
                            style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          setCalcState(() {
                            selectedCurrency = 'USD';
                            selectedFreightCurrency = 'USD';
                            exchangeRateCtrl.text = '50.7917';
                            insuranceCtrl.text = '14902.793';
                            deemedInsuranceCtrl.text = '0.00';
                            insuranceType = 'actual';
                            freightForeignCtrl.text = '234.72';
                            multiFreightCtrl.text = '11922.234';
                            deemedFreightCtrl.text = '0.00';
                            freightType = 'actual';
                            additionalFeesCtrl.text = '1329.50';
                            multiLines = [
                              {
                                'hs': TextEditingController(text: '8536.41.00'),
                                'value': TextEditingController(text: '607.6'),
                                'inspection':
                                    TextEditingController(text: '0.00'),
                                'origin': 'CN',
                                'exemption': null,
                              },
                              {
                                'hs': TextEditingController(text: '8537.10.90'),
                                'value': TextEditingController(text: '4371.2'),
                                'inspection':
                                    TextEditingController(text: '8514.81'),
                                'origin': 'TR',
                                'exemption': null,
                              },
                              {
                                'hs': TextEditingController(text: '8537.10.90'),
                                'value': TextEditingController(text: '6757.6'),
                                'inspection':
                                    TextEditingController(text: '69772.09'),
                                'origin': 'DE',
                                'exemption': null,
                              },
                            ];
                            syncCalculatedFields(setCalcState, multiLines);
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Header Inputs Grid - Row 1: Invoice Currency + Exchange Rate + Total FC Auto-Calc
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: SearchableDropdownField<String>(
                          value: selectedCurrency,
                          labelText: 'عملة الفاتورة *',
                          searchHintText: 'ابحث عن عملة الفاتورة...',
                          items: const [
                            SearchableDropdownItem(
                                value: 'USD', label: 'USD - دولار (\$)'),
                            SearchableDropdownItem(
                                value: 'EUR', label: 'EUR - يورو (€)'),
                            SearchableDropdownItem(
                                value: 'GBP', label: 'GBP - إسترليني (£)'),
                            SearchableDropdownItem(
                                value: 'CNY', label: 'CNY - يوان (¥)'),
                            SearchableDropdownItem(
                                value: 'SAR', label: 'SAR - ريال (ر.س)'),
                            SearchableDropdownItem(
                                value: 'AED', label: 'AED - درهم (د.إ)'),
                            SearchableDropdownItem(
                                value: 'EGP', label: 'EGP - جنيه (ج.م)'),
                          ],
                          onChanged: (val) {
                            if (val == null) return;
                            setCalcState(() {
                              selectedCurrency = val;
                              if (freightType == 'actual' &&
                                  selectedFreightCurrency == 'USD') {
                                selectedFreightCurrency = val;
                              }
                              exchangeRateCtrl.text =
                                  (defaultExchangeRates[val] ?? 50.7917)
                                      .toStringAsFixed(4);
                              syncCalculatedFields(setCalcState, multiLines);
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: exchangeRateCtrl,
                          keyboardType: TextInputType.number,
                          onChanged: (_) =>
                              syncCalculatedFields(setCalcState, multiLines),
                          decoration: InputDecoration(
                            labelText: 'سعر التحويل (EGP/$selectedCurrency) *',
                            hintText: '50.7917',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: totalInvoiceFcCtrl,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText:
                                'إجمالي قيمة الفاتورة المقر عنها ($selectedCurrency)',
                            helperText: 'حاصل جمع قيم جميع السطور بالعملة',
                            helperStyle: const TextStyle(fontSize: 9),
                            isDense: true,
                            filled: true,
                            fillColor: AppTheme.cobalt.withOpacity(0.08),
                            suffixIcon: const Icon(Icons.calculate_outlined,
                                size: 16, color: AppTheme.cobalt),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Header Inputs Grid - Row 2: Declared CIF EGP + Additional Fees EGP
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: declaredCifCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'إجمالي القيمة المقرة CIF (EGP)',
                            helperText:
                                'محسوبة تلقائياً: (FOB + تأمين + نولون)',
                            helperStyle: TextStyle(fontSize: 9),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: additionalFeesCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'رسوم أساسية/إضافية (EGP)',
                            hintText: '1329.50',
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ── Insurance Interactive Row ──
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: (insuranceType == 'deemed'
                              ? AppTheme.orange
                              : AppTheme.cobalt)
                          .withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (insuranceType == 'deemed'
                                ? AppTheme.orange
                                : AppTheme.cobalt)
                            .withOpacity(0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              insuranceType == 'actual'
                                  ? Icons.verified_outlined
                                  : Icons.auto_fix_high,
                              size: 14,
                              color: insuranceType == 'actual'
                                  ? AppTheme.cobalt
                                  : AppTheme.orange,
                            ),
                            const SizedBox(width: 6),
                            const Text('التأمين:',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.charcoal)),
                            const SizedBox(width: 12),
                            ChoiceChip(
                              label: const Text('فعلي ✔',
                                  style: TextStyle(fontSize: 11)),
                              selected: insuranceType == 'actual',
                              selectedColor: AppTheme.cobalt.withOpacity(0.2),
                              onSelected: (_) {
                                setCalcState(() {
                                  insuranceType = 'actual';
                                  deemedInsuranceCtrl.text = '0.00';
                                  syncCalculatedFields(
                                      setCalcState, multiLines);
                                });
                              },
                            ),
                            const SizedBox(width: 6),
                            ChoiceChip(
                              label: const Text('حكمي 2.5% ⚡',
                                  style: TextStyle(fontSize: 11)),
                              selected: insuranceType == 'deemed',
                              selectedColor: AppTheme.orange.withOpacity(0.2),
                              onSelected: (_) {
                                setCalcState(() {
                                  insuranceType = 'deemed';
                                  insuranceCtrl.text = '0.00';
                                  recalcDeemedInsurance(
                                      setCalcState, multiLines);
                                  syncCalculatedFields(
                                      setCalcState, multiLines);
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (insuranceType == 'actual') ...[
                              Expanded(
                                child: TextField(
                                  controller: insuranceCtrl,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => syncCalculatedFields(
                                      setCalcState, multiLines),
                                  decoration: const InputDecoration(
                                    labelText: 'مبلغ التأمين الفعلي (EGP)',
                                    hintText: '14902.793',
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ] else ...[
                              Expanded(
                                child: TextField(
                                  controller: deemedInsuranceCtrl,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText:
                                        'التأمين الحكمي المحتسب (EGP) — 2.5% من إجمالي FOB',
                                    isDense: true,
                                    filled: true,
                                    fillColor:
                                        AppTheme.orange.withOpacity(0.08),
                                    suffixIcon: const Icon(
                                        Icons.calculate_outlined,
                                        size: 16,
                                        color: AppTheme.orange),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: insuranceCtrl,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText:
                                        'التأمين الفعلي (EGP) — يُضبط صفراً',
                                    isDense: true,
                                    filled: true,
                                    fillColor: Colors.grey.withOpacity(0.08),
                                    helperText: 'صفر لتجنب الاحتساب المزدوج',
                                    helperStyle: const TextStyle(
                                        fontSize: 9, color: Colors.grey),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Freight Interactive Row (Foreign Currency & Amount) ──
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: (freightType == 'deemed'
                              ? AppTheme.orange
                              : AppTheme.cobalt)
                          .withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (freightType == 'deemed'
                                ? AppTheme.orange
                                : AppTheme.cobalt)
                            .withOpacity(0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              freightType == 'actual'
                                  ? Icons.local_shipping_outlined
                                  : Icons.auto_fix_high,
                              size: 14,
                              color: freightType == 'actual'
                                  ? AppTheme.cobalt
                                  : AppTheme.orange,
                            ),
                            const SizedBox(width: 6),
                            const Text('النولون:',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.charcoal)),
                            const SizedBox(width: 12),
                            ChoiceChip(
                              label: const Text('فعلي ✔',
                                  style: TextStyle(fontSize: 11)),
                              selected: freightType == 'actual',
                              selectedColor: AppTheme.cobalt.withOpacity(0.2),
                              onSelected: (_) {
                                setCalcState(() {
                                  freightType = 'actual';
                                  deemedFreightCtrl.text = '0.00';
                                  syncCalculatedFields(
                                      setCalcState, multiLines);
                                });
                              },
                            ),
                            const SizedBox(width: 6),
                            ChoiceChip(
                              label: const Text('حكمي 2.0% ⚡',
                                  style: TextStyle(fontSize: 11)),
                              selected: freightType == 'deemed',
                              selectedColor: AppTheme.orange.withOpacity(0.2),
                              onSelected: (_) {
                                setCalcState(() {
                                  freightType = 'deemed';
                                  multiFreightCtrl.text = '0.00';
                                  recalcDeemedFreight(setCalcState, multiLines);
                                  syncCalculatedFields(
                                      setCalcState, multiLines);
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (freightType == 'actual') ...[
                              Expanded(
                                flex: 2,
                                child: SearchableDropdownField<String>(
                                  value: selectedFreightCurrency,
                                  labelText: 'عملة النولون الفعلي *',
                                  searchHintText: 'ابحث عن عملة النولون...',
                                  items: const [
                                    SearchableDropdownItem(
                                        value: 'USD',
                                        label: 'USD - دولار (\$)'),
                                    SearchableDropdownItem(
                                        value: 'EUR', label: 'EUR - يورو (€)'),
                                    SearchableDropdownItem(
                                        value: 'GBP',
                                        label: 'GBP - إسترليني (£)'),
                                    SearchableDropdownItem(
                                        value: 'CNY', label: 'CNY - يوان (¥)'),
                                    SearchableDropdownItem(
                                        value: 'SAR',
                                        label: 'SAR - ريال (ر.س)'),
                                    SearchableDropdownItem(
                                        value: 'AED',
                                        label: 'AED - درهم (د.إ)'),
                                    SearchableDropdownItem(
                                        value: 'EGP',
                                        label: 'EGP - جنيه (ج.م)'),
                                  ],
                                  onChanged: (val) {
                                    if (val == null) return;
                                    setCalcState(() {
                                      selectedFreightCurrency = val;
                                      freightExchangeRateCtrl.text =
                                          (defaultExchangeRates[val] ?? 50.7917)
                                              .toStringAsFixed(4);
                                      syncCalculatedFields(
                                          setCalcState, multiLines);
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: freightForeignCtrl,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => syncCalculatedFields(
                                      setCalcState, multiLines),
                                  decoration: InputDecoration(
                                    labelText:
                                        'مبلغ النولون ($selectedFreightCurrency) *',
                                    hintText: '234.72',
                                    isDense: true,
                                  ),
                                ),
                              ),
                              if (selectedFreightCurrency != 'EGP') ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: freightExchangeRateCtrl,
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => syncCalculatedFields(
                                        setCalcState, multiLines),
                                    decoration: const InputDecoration(
                                      labelText: 'معامل تحويل عملة النولون *',
                                      hintText: '50.7917',
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: multiFreightCtrl,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'إجمالي النولون الفعلي (EGP)',
                                    helperText: selectedFreightCurrency == 'EGP'
                                        ? 'نولون بالجنيه'
                                        : '= النولون ($selectedFreightCurrency) × معامل التحويل',
                                    helperStyle: const TextStyle(fontSize: 9),
                                    isDense: true,
                                    filled: true,
                                    fillColor:
                                        AppTheme.cobalt.withOpacity(0.08),
                                    suffixIcon: const Icon(
                                        Icons.calculate_outlined,
                                        size: 16,
                                        color: AppTheme.cobalt),
                                  ),
                                ),
                              ),
                            ] else ...[
                              Expanded(
                                child: TextField(
                                  controller: deemedFreightCtrl,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText:
                                        'النولون الحكمي المحتسب (EGP) — 2.0% من إجمالي FOB',
                                    isDense: true,
                                    filled: true,
                                    fillColor:
                                        AppTheme.orange.withOpacity(0.08),
                                    suffixIcon: const Icon(
                                        Icons.calculate_outlined,
                                        size: 16,
                                        color: AppTheme.orange),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: multiFreightCtrl,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText:
                                        'النولون الفعلي (EGP) — يُضبط صفراً',
                                    isDense: true,
                                    filled: true,
                                    fillColor: Colors.grey.withOpacity(0.08),
                                    helperText: 'صفر لتجنب الاحتساب المزدوج',
                                    helperStyle: const TextStyle(
                                        fontSize: 9, color: Colors.grey),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Lines Table Title & Add Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'سطور الفاتورة (Invoice Line Items):',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.charcoal,
                            fontSize: 13),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.cobalt,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('إضافة صنف +',
                            style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          setCalcState(() {
                            multiLines.add({
                              'hs': TextEditingController(text: '8471.30.00'),
                              'value': TextEditingController(text: '1000.00'),
                              'inspection': TextEditingController(text: '0.00'),
                              'origin': 'CN',
                              'exemption': null,
                            });
                            syncCalculatedFields(setCalcState, multiLines);
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Multi-Lines Input List
                  ...multiLines.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final m = entry.value;
                    final registeredTariffs =
                        ref.watch(customsTariffProvider).value ?? [];
                    final hsDropdownItems = registeredTariffs
                        .map((t) => SearchableDropdownItem<String>(
                              value: t.hsCode,
                              label: '[${t.hsCode}] ${t.hsDescription}',
                              subtitle:
                                  'الوارد: ${t.customsDutyRate}% | ض.م: ${t.vatRate}%',
                            ))
                        .toList();

                    final currentHs =
                        (m['hs'] as TextEditingController).text.trim();
                    final matchedTariff = registeredTariffs
                        .cast<CustomsTariffModel?>()
                        .firstWhere(
                          (t) =>
                              t != null &&
                              (t.hsCode == currentHs ||
                                  t.hsCode.replaceAll('.', '') ==
                                      currentHs.replaceAll('.', '')),
                          orElse: () => null,
                        );

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: AppTheme.cobalt,
                                child: Text('${idx + 1}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: SearchableDropdownField<String>(
                                  value: currentHs.isEmpty ? null : currentHs,
                                  labelText:
                                      'HS Code (بند التعريفة الجمركية) *',
                                  searchHintText:
                                      'ابحث برقم البند أو الوصف الجمركي...',
                                  items: [
                                    if (currentHs.isNotEmpty &&
                                        !registeredTariffs
                                            .any((t) => t.hsCode == currentHs))
                                      SearchableDropdownItem<String>(
                                        value: currentHs,
                                        label: currentHs,
                                        subtitle: 'بند غير مسجل / حرة',
                                      ),
                                    ...hsDropdownItems,
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setCalcState(() {
                                        (m['hs'] as TextEditingController)
                                            .text = val;
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller:
                                      m['value'] as TextEditingController,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => syncCalculatedFields(
                                      setCalcState, multiLines),
                                  decoration: InputDecoration(
                                    labelText: 'القيمة ($selectedCurrency)',
                                    hintText: '1000',
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 2,
                                child: SearchableDropdownField<String>(
                                  value: m['origin'] as String?,
                                  labelText: 'المنشأ',
                                  searchHintText: 'ابحث عن بلد المنشأ...',
                                  items: const [
                                    SearchableDropdownItem(
                                        value: 'CN', label: 'الصين - CN'),
                                    SearchableDropdownItem(
                                        value: 'TR',
                                        label: 'تركيا (اتفاقية) - TR'),
                                    SearchableDropdownItem(
                                        value: 'DE',
                                        label: 'ألمانيا (شراكة) - DE'),
                                    SearchableDropdownItem(
                                        value: 'IT',
                                        label: 'إيطاليا (شراكة) - IT'),
                                    SearchableDropdownItem(
                                        value: 'EG', label: 'مصر - EG'),
                                    SearchableDropdownItem(
                                        value: 'GB',
                                        label: 'المملكة المتحدة - GB'),
                                    SearchableDropdownItem(
                                        value: 'US', label: 'أمريكا - US'),
                                    SearchableDropdownItem(
                                        value: 'IN', label: 'الهند - IN'),
                                    SearchableDropdownItem(
                                        value: 'BR',
                                        label: 'البرازيل (ميركوسور) - BR'),
                                    SearchableDropdownItem(
                                        value: 'RS',
                                        label: 'صربيا (اتفاقية) - RS'),
                                    SearchableDropdownItem(
                                        value: 'CH',
                                        label: 'سويسرا (إفتا) - CH'),
                                  ],
                                  onChanged: (val) {
                                    setCalcState(() {
                                      m['origin'] = val;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 2,
                                child: SearchableDropdownField<String?>(
                                  value: m['exemption'] as String?,
                                  labelText: 'الإعفاء',
                                  searchHintText: 'ابحث عن كود الإعفاء...',
                                  items: const [
                                    SearchableDropdownItem(
                                        value: null, label: 'لا يوجد إعفاء'),
                                    SearchableDropdownItem(
                                        value: 'INV-LAW-EXEMPT-01',
                                        label: 'قانون الاستثمار (100%)'),
                                    SearchableDropdownItem(
                                        value: 'FREEZONE-EXEMPT-02',
                                        label: 'منطقة حرة (100%)'),
                                    SearchableDropdownItem(
                                        value: 'DIPLO-EXEMPT-03',
                                        label: 'إعفاء دبلوماسي (100%)'),
                                    SearchableDropdownItem(
                                        value: 'PARTIAL-50-EXEMPT',
                                        label: 'إعفاء جزئي (50%)'),
                                  ],
                                  onChanged: (val) {
                                    setCalcState(() {
                                      m['exemption'] = val;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller:
                                      m['inspection'] as TextEditingController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'خدمات جمركية (EGP)',
                                    hintText: '0.00',
                                    isDense: true,
                                  ),
                                ),
                              ),
                              if (multiLines.length > 1) ...[
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red, size: 18),
                                  onPressed: () {
                                    setCalcState(() {
                                      multiLines.removeAt(idx);
                                      syncCalculatedFields(
                                          setCalcState, multiLines);
                                    });
                                  },
                                ),
                              ],
                            ],
                          ),
                          if (matchedTariff != null &&
                              (matchedTariff.priorApprovalNote ?? '')
                                  .isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                                border:
                                    Border.all(color: Colors.amber.shade700),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded,
                                          color: Colors.amber.shade900,
                                          size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        '⚠️ تنبيه إعفاء وشروط مستندية مطلوبة للمورد الخارجي (HS Code: ${matchedTariff.hsCode}):',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          color: Colors.amber.shade900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '• توجد اتفاقيات وشروط مستندية يجب طلب استيفائها من المورد الخارجي (مثل شهادة EUR.1 الأصلي أو منشأ الميركسور) قبل تطبيق الإعفاء الجمركي:',
                                    style: TextStyle(
                                        fontSize: 10.5,
                                        color: Colors.amber.shade900),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    matchedTariff.priorApprovalNote!,
                                    style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.charcoal,
                                        height: 1.3),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),

                  // Submit Calculation Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emerald,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: isMultiCalculating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.bolt, size: 20),
                      label: const Text(
                        'حساب إجمالي الجمارك والإقرار الرسمي (Calculate Nafeza Duties)',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      onPressed: isMultiCalculating
                          ? null
                          : () async {
                              final rate = double.tryParse(
                                      exchangeRateCtrl.text.trim()) ??
                                  50.7917;

                              final bool isDeemedInsurance =
                                  insuranceType == 'deemed';
                              final double actualIns = isDeemedInsurance
                                  ? 0.0
                                  : (double.tryParse(
                                          insuranceCtrl.text.trim()) ??
                                      0);

                              final bool isDeemedFreight =
                                  freightType == 'deemed';
                              final double actualFrt = isDeemedFreight
                                  ? 0.0
                                  : (double.tryParse(
                                          multiFreightCtrl.text.trim()) ??
                                      0);

                              final add = double.tryParse(
                                      additionalFeesCtrl.text.trim()) ??
                                  0;
                              final decCif =
                                  double.tryParse(declaredCifCtrl.text.trim());

                              final linesData = <Map<String, dynamic>>[];
                              for (int i = 0; i < multiLines.length; i++) {
                                final m = multiLines[i];
                                linesData.add({
                                  'line_no': i + 1,
                                  'hs_code': (m['hs'] as TextEditingController)
                                      .text
                                      .trim(),
                                  'value_fc': double.tryParse(
                                          (m['value'] as TextEditingController)
                                              .text
                                              .trim()) ??
                                      0,
                                  'inspection_fee_egp': double.tryParse(
                                          (m['inspection']
                                                  as TextEditingController)
                                              .text
                                              .trim()) ??
                                      0,
                                  'origin_country': m['origin'],
                                  'exemption_code': m['exemption'],
                                });
                              }

                              setCalcState(() {
                                isMultiCalculating = true;
                                multiError = null;
                              });

                              try {
                                final payload = {
                                  'currency': selectedCurrency,
                                  'exchange_rate': rate,
                                  'insurance_egp': actualIns,
                                  'freight_egp': actualFrt,
                                  'freight_currency': selectedFreightCurrency,
                                  'freight_foreign_amount': double.tryParse(
                                          freightForeignCtrl.text.trim()) ??
                                      0,
                                  'freight_exchange_rate': double.tryParse(
                                          freightExchangeRateCtrl.text
                                              .trim()) ??
                                      rate,
                                  'has_insurance_document': !isDeemedInsurance,
                                  'has_freight_document': !isDeemedFreight,
                                  'additional_fees_egp': add,
                                  if (decCif != null && decCif > 0)
                                    'cif_declared_total_egp': decCif,
                                  'lines': linesData,
                                };

                                final res = await ref
                                    .read(customsTariffProvider.notifier)
                                    .estimateMultiItemDuty(payload);

                                setCalcState(() {
                                  multiResult = res;
                                  isMultiCalculating = false;
                                });
                              } catch (e) {
                                setCalcState(() {
                                  multiError = e
                                      .toString()
                                      .replaceAll('Exception: ', '');
                                  isMultiCalculating = false;
                                  multiResult = null;
                                });
                              }
                            },
                    ),
                  ),

                  if (multiError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(multiError!,
                                  style: TextStyle(
                                      color: Colors.red.shade900,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (multiResult != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const Text('نتيجة حساب الشحنة (Nafeza Statement Result):',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.charcoal,
                            fontSize: 13)),
                    const SizedBox(height: 8),

                    // Multi-Item Line Items Results Table
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 12,
                        headingRowHeight: 32,
                        dataRowMinHeight: 32,
                        dataRowMaxHeight: 32,
                        headingRowColor: WidgetStateProperty.all(
                            AppTheme.charcoal.withOpacity(0.05)),
                        columns: const [
                          DataColumn(label: Text('سطر')),
                          DataColumn(label: Text('HS Code')),
                          DataColumn(label: Text('المنشأ / الاتفاقية')),
                          DataColumn(label: Text('CIF (EGP)')),
                          DataColumn(label: Text('جمرك')),
                          DataColumn(label: Text('ض.جدول')),
                          DataColumn(label: Text('أ.ن.ص (1%)')),
                          DataColumn(label: Text('VAT (14%)')),
                          DataColumn(
                              label: Text('ملاحظات الإعفاء والاتفاقيات')),
                        ],
                        rows: (multiResult!['lines'] as List).map((l) {
                          return DataRow(cells: [
                            DataCell(Text('#${l['line_no']}')),
                            DataCell(Text(l['hs_code'].toString())),
                            DataCell(Text(
                                l['preferential_agreement_applied'] != null
                                    ? '${l['origin_country']} (تفضيل 0%)'
                                    : '${l['origin_country'] ?? "-"}')),
                            DataCell(Text('${l['cif_value_egp']} EGP')),
                            DataCell(Text(
                                '${l['duty_egp']} EGP (${l['customs_duty_rate']}%)')),
                            DataCell(Text('${l['schedule_tax_egp']} EGP')),
                            DataCell(Text(
                                '${l['customs_service_fee_egp']} EGP (1%)')),
                            DataCell(Text('${l['vat_egp']} EGP')),
                            DataCell(Text(
                                l['exemption_applied_details'] ??
                                    l['preferential_agreement_applied'] ??
                                    'خاضع بالكامل',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: (l['exemption_applied_details'] !=
                                                null ||
                                            l['preferential_agreement_applied'] !=
                                                null)
                                        ? AppTheme.emerald
                                        : Colors.black87))),
                          ]);
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 16),

                    // ── Nafeza Statement Fee Codes Breakdown Table (Matching Image #3 Layout) ──
                    if (multiResult!['fee_codes_breakdown'] != null) ...[
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppTheme.cobalt.withOpacity(0.4)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Card Header Bar
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.cobalt.withOpacity(0.12),
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(9)),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.receipt_long,
                                          color: AppTheme.cobalt, size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'تفاصيل بنود التحصيل والإقرارات الرسمية (Nafeza Statement Fee Breakdown)',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.cobalt,
                                            fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'إجمالي البيان: ${_numToDouble(multiResult!['fee_codes_breakdown']['grand_total']).toStringAsFixed(2)} EGP',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.cobalt,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),

                            // Grouped Fee Items (Matching Nafeza Official PDF layout in Image #3)
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                children: [
                                  ...((multiResult!['fee_codes_breakdown']
                                                  ['group_items']
                                              as Map<String, dynamic>? ??
                                          {})
                                      .entries
                                      .map((groupEntry) {
                                    final groupName = groupEntry.key;
                                    final itemsList =
                                        groupEntry.value as List<dynamic>? ??
                                            [];
                                    final groupSum =
                                        (multiResult!['fee_codes_breakdown']
                                                        ['by_group']
                                                    as Map<String, dynamic>? ??
                                                {})[groupName] ??
                                            0.0;

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                            color: Colors.grey.shade300),
                                      ),
                                      child: Column(
                                        children: [
                                          // Group Subheader Bar
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            color: Colors.blueGrey.shade100
                                                .withOpacity(0.4),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text('تحصيل $groupName',
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12,
                                                        color:
                                                            AppTheme.charcoal)),
                                                Text(
                                                    '${_numToDouble(groupSum).toStringAsFixed(2)} ج.م',
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12,
                                                        color:
                                                            AppTheme.charcoal)),
                                              ],
                                            ),
                                          ),
                                          // Group Items List
                                          ...itemsList.map((item) {
                                            final itemMap =
                                                item as Map<String, dynamic>;
                                            final code =
                                                itemMap['code']?.toString() ??
                                                    '';
                                            final name = itemMap['name_ar']
                                                    ?.toString() ??
                                                '';
                                            final calcType =
                                                itemMap['calculation_type']
                                                        ?.toString() ??
                                                    'flat';
                                            final amt = _numToDouble(
                                                itemMap['calculated_amount']);
                                            final typeLabel = calcType == 'flat'
                                                ? 'قطعي'
                                                : (calcType == 'reference'
                                                    ? 'مرجعي'
                                                    : 'مشتق');

                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 5),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.grey.shade200,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: Text('[$code]',
                                                        style: const TextStyle(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontFamily:
                                                                'monospace')),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(name,
                                                        style: const TextStyle(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500)),
                                                  ),
                                                  Text(typeLabel,
                                                      style: TextStyle(
                                                          fontSize: 10,
                                                          color: Colors
                                                              .grey.shade600)),
                                                  const SizedBox(width: 14),
                                                  SizedBox(
                                                    width: 95,
                                                    child: Text(
                                                        '${amt.toStringAsFixed(2)} ج.م',
                                                        textAlign:
                                                            TextAlign.end,
                                                        style: const TextStyle(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    );
                                  })),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Action Buttons: Print Statement & Download PDF
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.charcoal,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.print, size: 16),
                            label: const Text('طباعة التقرير 🖨️',
                                style: TextStyle(fontSize: 12)),
                            onPressed: () async {
                              final rate = double.tryParse(
                                      exchangeRateCtrl.text.trim()) ??
                                  50.7917;
                              final totalFc = computeTotalInvoiceFc(multiLines);
                              final fobEgp = totalFc * rate;
                              final insEgp = (insuranceType == 'deemed')
                                  ? (double.tryParse(
                                          deemedInsuranceCtrl.text.trim()) ??
                                      0)
                                  : (double.tryParse(
                                          insuranceCtrl.text.trim()) ??
                                      0);
                              final frtEgp = (freightType == 'deemed')
                                  ? (double.tryParse(
                                          deemedFreightCtrl.text.trim()) ??
                                      0)
                                  : (double.tryParse(
                                          multiFreightCtrl.text.trim()) ??
                                      0);
                              final addEgp = double.tryParse(
                                      additionalFeesCtrl.text.trim()) ??
                                  0;
                              final cifEgp = double.tryParse(
                                      declaredCifCtrl.text.trim()) ??
                                  (fobEgp + insEgp + frtEgp);

                              await CustomsPdfService.printStatement(
                                currency: selectedCurrency,
                                exchangeRate: rate,
                                totalFobFc: totalFc,
                                totalFobEgp: fobEgp,
                                insuranceEgp: insEgp,
                                freightEgp: frtEgp,
                                additionalFeesEgp: addEgp,
                                totalCifEgp: cifEgp,
                                insuranceMode: insuranceType == 'deemed'
                                    ? 'حكمي 2.5%'
                                    : 'فعلي',
                                freightMode: freightType == 'deemed'
                                    ? 'حكمي 2.0%'
                                    : 'فعلي',
                                result: multiResult!,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.cobalt,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.picture_as_pdf, size: 16),
                            label: const Text('تنزيل PDF 📄',
                                style: TextStyle(fontSize: 12)),
                            onPressed: () async {
                              final rate = double.tryParse(
                                      exchangeRateCtrl.text.trim()) ??
                                  50.7917;
                              final totalFc = computeTotalInvoiceFc(multiLines);
                              final fobEgp = totalFc * rate;
                              final insEgp = (insuranceType == 'deemed')
                                  ? (double.tryParse(
                                          deemedInsuranceCtrl.text.trim()) ??
                                      0)
                                  : (double.tryParse(
                                          insuranceCtrl.text.trim()) ??
                                      0);
                              final frtEgp = (freightType == 'deemed')
                                  ? (double.tryParse(
                                          deemedFreightCtrl.text.trim()) ??
                                      0)
                                  : (double.tryParse(
                                          multiFreightCtrl.text.trim()) ??
                                      0);
                              final addEgp = double.tryParse(
                                      additionalFeesCtrl.text.trim()) ??
                                  0;
                              final cifEgp = double.tryParse(
                                      declaredCifCtrl.text.trim()) ??
                                  (fobEgp + insEgp + frtEgp);

                              final savedPath =
                                  await CustomsPdfService.downloadPdf(
                                currency: selectedCurrency,
                                exchangeRate: rate,
                                totalFobFc: totalFc,
                                totalFobEgp: fobEgp,
                                insuranceEgp: insEgp,
                                freightEgp: frtEgp,
                                additionalFeesEgp: addEgp,
                                totalCifEgp: cifEgp,
                                insuranceMode: insuranceType == 'deemed'
                                    ? 'حكمي 2.5%'
                                    : 'فعلي',
                                freightMode: freightType == 'deemed'
                                    ? 'حكمي 2.0%'
                                    : 'فعلي',
                                result: multiResult!,
                              );

                              if (savedPath != null && ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'تم حفظ البيان بصيغة PDF بنجاح:\n$savedPath'),
                                    backgroundColor: AppTheme.emerald,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

double _numToDouble(dynamic val, [double fallback = 0.0]) {
  if (val == null) return fallback;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? fallback;
  return fallback;
}
