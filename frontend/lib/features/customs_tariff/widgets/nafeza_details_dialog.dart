import '../widgets/add_agreement_dialog.dart';
import '../widgets/tariff_form_dialog.dart';
import '../widgets/verify_tariff_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../models/customs_tariff_model.dart';
import '../providers/customs_tariff_provider.dart';

  void showNafezaDetailsDialog(
      BuildContext context, WidgetRef ref, CustomsTariffModel tariff) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 680, maxHeight: 750),
          padding: const EdgeInsets.all(24),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: ref
                .read(customsTariffProvider.notifier)
                .fetchAgreements(tariff.hsCode),
            builder: (context, snapshot) {
              final agreements = snapshot.data ?? [];
              final isLoadingAgreements =
                  snapshot.connectionState == ConnectionState.waiting;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Modal Header matching Screenshot
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.article_outlined,
                              color: AppTheme.charcoal, size: 26),
                          SizedBox(width: 8),
                          Text(
                            'تفاصيل البند',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.charcoal,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 20, thickness: 1),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Item Code & Description Section
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                  color: AppTheme.charcoal, fontSize: 14),
                              children: [
                                const TextSpan(
                                  text: 'رقم البند : ',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                                TextSpan(
                                  text: tariff.hsCode,
                                  style: const TextStyle(
                                    color: AppTheme.cobalt,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                  color: AppTheme.charcoal, fontSize: 14),
                              children: [
                                const TextSpan(
                                  text: 'نص البند : ',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                                TextSpan(
                                  text: tariff.hsDescription,
                                  style: const TextStyle(
                                      fontSize: 14, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 20, thickness: 1),

                          // Taxes Breakdown Section matching Screenshot
                          const Text(
                            'الضرائب :',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.charcoal,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _taxDetailRow('ضريبة الوارد',
                                    '${tariff.customsDutyRate.toStringAsFixed(3)} %'),
                                _taxDetailRow('ضريبة الجدول',
                                    '${tariff.scheduleTaxRate.toStringAsFixed(3)} %'),
                                _taxDetailRow('ضريبة قيمة مضافة',
                                    '${tariff.vatRate.toStringAsFixed(3)} %'),
                                if (tariff.developmentFeeRate > 0)
                                  _taxDetailRow('رسم التنمية',
                                      '${tariff.developmentFeeRate.toStringAsFixed(3)} %'),
                                if (tariff.importFeeRate > 0)
                                  _taxDetailRow('رسم الوارد',
                                      '${tariff.importFeeRate.toStringAsFixed(3)} %'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 20, thickness: 1),

                          // Rules, Trade Agreements & Regulatory Notes matching Screenshot
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'المستندات والأعمال :',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.charcoal,
                                ),
                              ),
                              if (isLoadingAgreements)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: AppTheme.cobalt),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Items List with Blue Left/Right Vertical Border matching Nafeza UI in screenshot
                          _buildNafezaRulesList(tariff, agreements),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  // Modal Footer Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.emerald,
                            side: const BorderSide(color: AppTheme.emerald),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.verified, size: 18),
                          label: const Text('توثيق وتدقيق البند'),
                          onPressed: () {
                            Navigator.pop(ctx);
                            showVerifyTariffDialog(context, ref, tariff);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.cobalt,
                            side: const BorderSide(color: AppTheme.cobalt),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.handshake_outlined, size: 18),
                          label: const Text('إضافة اتفاقية تفضيلية'),
                          onPressed: () {
                            Navigator.pop(ctx);
                            showAddAgreementDialog(
                                context, ref, tariff.hsCode);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.cobalt,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('تعديل البند'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          showTariffDialog(context, ref, tariff: tariff);
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

Widget _taxDetailRow(String label, String rateStr) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label :',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.charcoal,
              ),
            ),
          ),
          Text(
            rateStr,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.cobalt,
            ),
          ),
        ],
      ),
    );
  }

Widget _buildNafezaRulesList(
      CustomsTariffModel tariff, List<Map<String, dynamic>> agreements) {
    final List<String> rules = [];

    // Preferential Agreements from Database
    for (final ag in agreements) {
      final name = ag['agreement_name'] ?? 'اتفاقية تجارية';
      final red = _numToDouble(ag['reduction_percentage'], 1.0);
      final pctStr = (red * 100).toStringAsFixed(0);
      final cond = ag['conditions_note'] != null &&
              ag['conditions_note'].toString().isNotEmpty
          ? ' - ${ag['conditions_note']}'
          : '';
      rules.add('ر ${ag['agreement_id'] ?? 6722} - $name تخفيض $pctStr%$cond');
    }

    // Prior Approval Note & Regulatory Conditions matching screenshot
    if (tariff.priorApprovalNote != null &&
        tariff.priorApprovalNote!.isNotEmpty) {
      rules.add('ق 4518 - ${tariff.priorApprovalNote}');
    } else if (tariff.regulatoryAuthority != null &&
        tariff.regulatoryAuthority!.isNotEmpty) {
      rules.add(
          'ق 4518 - لا يصرح باستيراد صنف إلا بموافقة مختومة بخاتم شعار الجمهورية من ${tariff.regulatoryAuthority}');
    }

    // Standard Nafeza Inspection Rule if required
    if (tariff.requiresInspection) {
      rules.add(
          'ق 4547 - يشترط للإفراج عن الصنف وارد تجار أن يكون إنتاج مصانع مسجلة من شركات مالكة للعلامة أو مطبقاً للائحة الفحص المعتمدة');
    }

    // General VAT Rule matching screenshot (ر 7042 - يحصل ضريبة قيمة مضافة بمقدار14% [عام])
    rules.add(
        'ر 7042 - يحصل ضريبة قيمة مضافة بمقدار ${tariff.vatRate.toStringAsFixed(0)}% [عام]');

    // Additional Notes
    if (tariff.notes != null && tariff.notes!.isNotEmpty) {
      rules.add('ق 9994 - ${tariff.notes}');
    }

    return Column(
      children: rules.map((ruleText) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9FA),
            border: Border(
              right: BorderSide(color: Color(0xFF1B65A8), width: 3.5),
            ),
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              ruleText,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.charcoal,
                height: 1.4,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      }).toList(),
    );
  }
double _numToDouble(dynamic val, [double fallback = 0.0]) {
  if (val == null) return fallback;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? fallback;
  return fallback;
}
