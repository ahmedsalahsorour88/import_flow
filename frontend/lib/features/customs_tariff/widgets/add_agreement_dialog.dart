import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../models/customs_tariff_model.dart';
import '../providers/customs_tariff_provider.dart';
import '../../import_requirements/models/import_requirement_model.dart';
import '../../import_requirements/providers/import_requirements_provider.dart';

  void showAddAgreementDialog(
      BuildContext context, WidgetRef ref, String hsCode) {
    final nameCtrl = TextEditingController();
    final countriesCtrl = TextEditingController(text: 'EG,EU,TR,JO,TN,MA,GB');
    final pctCtrl = TextEditingController(text: '100');
    final notesCtrl = TextEditingController();

    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('إضافة اتفاقية تفضيلية للبند $hsCode'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'اسم الاتفاقية *',
                      hintText: 'مثال: اتفاقية الشراكة المصرية الأوروبية EU',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'مطلوب إدخال اسم الاتفاقية'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: countriesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'دول المنشأ المعنية *',
                      hintText: 'رموز الدول بالفواصل e.g. JO,TN,MA,EU',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'مطلوب إدخال دول المنشأ'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: pctCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'نسبة التخفيض الجمركي % *',
                      hintText: '100 للإعفاء الكامل، 10 للتخفيض 10%',
                    ),
                    validator: (v) => (v == null || double.tryParse(v) == null)
                        ? 'رقم غير صحيح'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'شروط وملاحظات الإفراج التفضيلية',
                      hintText: 'مثال: مصحوبة بفرام 1 أو شهادة EUR.1',
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isLoading = true);

                      final pctVal = double.parse(pctCtrl.text.trim()) / 100.0;
                      final data = {
                        'hs_code': hsCode,
                        'agreement_name': nameCtrl.text.trim(),
                        'reduction_type': pctVal >= 1.0
                            ? 'full_duty_exemption'
                            : 'percentage_of_duty',
                        'reduction_percentage': pctVal,
                        'origin_countries': countriesCtrl.text.trim(),
                        'conditions_note': notesCtrl.text.trim().isEmpty
                            ? null
                            : notesCtrl.text.trim(),
                      };

                      final error = await ref
                          .read(customsTariffProvider.notifier)
                          .createPreferentialAgreement(data);

                      setDialogState(() => isLoading = false);
                      if (ctx.mounted) {
                        if (error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(error),
                                backgroundColor: AppTheme.crimson),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('تمت إضافة الاتفاقية التفضيلية بنجاح!'),
                              backgroundColor: AppTheme.emerald,
                            ),
                          );
                          Navigator.pop(ctx);
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('حفظ الاتفاقية'),
            ),
          ],
        ),
      ),
    );
  }
