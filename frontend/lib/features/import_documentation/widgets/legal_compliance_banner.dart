import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/import_documentation_provider.dart';

class LegalComplianceBanner extends ConsumerWidget {
  final int? importFileId;

  const LegalComplianceBanner({super.key, required this.importFileId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (importFileId == null) {
      return const SizedBox.shrink();
    }

    final complianceAsync = ref.watch(legalComplianceFamilyProvider(importFileId!));

    return complianceAsync.when(
      loading: () => const LinearProgressIndicator(minHeight: 3),
      error: (err, _) => const SizedBox.shrink(),
      data: (data) {
        if (!data.hasCriticalAlerts && data.overallComplianceStatus == 'COMPLIANT') {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user, color: Colors.green, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'جميع المستندات القانونية (ACID، البطاقة الاستيرادية، السجل التجاري، البطاقة الضريبية) سارية وصالحة لما بعد موعد وصول الشحنة (${data.etaDate}) بـ 30 يوماً على الأقل (${data.safetyWindowDate}).',
                    style: TextStyle(color: Colors.green.shade900, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
        }

        // Critical Alert Banner (Persistent Red Alert)
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade400, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'تحذير قانوني وإجرائي حرج (ETA + 30 Days Safety Margin Violation)',
                      style: TextStyle(color: Colors.red.shade900, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'تاريخ الوصول: ${data.etaDate}',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (data.persistentBannerText != null)
                Text(
                  data.persistentBannerText!,
                  style: TextStyle(color: Colors.red.shade900, fontSize: 12.5, fontWeight: FontWeight.w500),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: data.alerts.where((a) => a.isCriticalBreach || a.isExpired).map((alert) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${alert.docType}: تنتهي في ${alert.expiryDate} (متبقي ${alert.daysUntilExpiry} يوم)',
                          style: TextStyle(color: Colors.red.shade800, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
