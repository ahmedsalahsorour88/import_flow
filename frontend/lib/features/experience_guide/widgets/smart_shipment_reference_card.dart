import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../models/smart_reference_card_model.dart';
import '../providers/experience_guide_provider.dart';
import 'add_guide_entry_dialog.dart';
import 'experience_guide_management_dialog.dart';

class SmartShipmentReferenceCard extends ConsumerWidget {
  final int importFileId;
  final String? initialHsCode;
  final String? initialCategory;
  final String? initialPod;
  final String? initialSupplier;
  final String? initialCarrier;
  final VoidCallback? onGuidelineAdded;

  const SmartShipmentReferenceCard({
    super.key,
    required this.importFileId,
    this.initialHsCode,
    this.initialCategory,
    this.initialPod,
    this.initialSupplier,
    this.initialCarrier,
    this.onGuidelineAdded,
  });

  void _copyCardData(BuildContext context, SmartReferenceCardModel card) {
    final l10n = context.l10n;
    final buffer = StringBuffer();
    buffer.writeln('=== ${l10n.smartReferenceCardTitle} ===');
    buffer.writeln('كود الملف: ${card.importFileCode}');
    if (card.customFileNumber != null && card.customFileNumber!.isNotEmpty) {
      buffer.writeln('الرقم المخصص: ${card.customFileNumber}');
    }
    buffer.writeln('\n[${l10n.refCardProductSection}]');
    buffer.writeln('بند التعريفة: ${card.hsCode}');
    buffer.writeln('تصنيف الصنف: ${card.productCategory}');
    buffer.writeln('إجمالي الحجم: ${card.totalCbm} متر مكعب');
    buffer.writeln('الوزن الإجمالي: ${card.totalGrossWeightKg} كجم');
    buffer.writeln('عدد الطرود: ${card.packagesCount}');

    buffer.writeln('\n[${l10n.refCardRouteSection}]');
    buffer.writeln('ميناء الشحن: ${card.originPort}');
    buffer.writeln('ميناء الوصول: ${card.destinationPort}');
    buffer.writeln('الناقل والخط الملاحي: ${card.carrier}');

    buffer.writeln('\n[${l10n.refCardDatesSection}]');
    buffer.writeln('فترة سماح الحاويات: ${card.freeDays} يوم');
    buffer.writeln('حالة السماح: ${card.freeTimeStatus}');

    buffer.writeln('\n[${l10n.refCardDocsSection}]');
    buffer.writeln('حالة الجاهزية: ${card.isDocsComplete ? "مكتملة" : "غير مكتملة"}');
    buffer.writeln('شهادة المنشأ: ${card.hasCooAttached ? "مرفقة ومصدقة" : "غير مرفقة"}');
    if (card.pendingDocuments.isNotEmpty) {
      buffer.writeln('المستندات المعلقة: ${card.pendingDocuments.join("، ")}');
    }

    buffer.writeln('\n[${l10n.refCardCostSection}]');
    buffer.writeln('المقدر: ${card.estimatedCost} ${card.currency}');
    buffer.writeln('الفعلي: ${card.actualCost} ${card.currency}');
    buffer.writeln('الفارق: ${card.varianceAmount} (${card.variancePercentage}%)');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.referenceCardCopiedSuccess),
        backgroundColor: AppTheme.flatEmerald,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openAddGuidelineDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AddGuideEntryDialog(
        initialHsCode: initialHsCode,
        initialCategory: initialCategory,
        initialDestinationPort: initialPod,
        initialSupplier: initialSupplier,
        initialShippingLine: initialCarrier,
        onSuccess: () {
          ref.invalidate(smartReferenceCardProvider(importFileId));
          ref.invalidate(experienceGuideProvider);
          if (onGuidelineAdded != null) onGuidelineAdded!();
        },
      ),
    );
  }

  void _openManageGuideDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const ExperienceGuideManagementDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final cardAsync = ref.watch(smartReferenceCardProvider(importFileId));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: cardAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.flatOrange, size: 36),
                  const SizedBox(height: 8),
                  Text('تعذر تحميل المرجع الذكي للشحنة: $err',
                      style: const TextStyle(fontSize: 13, color: AppTheme.flatCharcoal)),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('إعادة المحاولة'),
                    onPressed: () => ref.invalidate(smartReferenceCardProvider(importFileId)),
                  )
                ],
              ),
            ),
          ),
          data: (card) => _buildCardContent(context, ref, l10n, card),
        ),
      ),
    );
  }

  Widget _buildCardContent(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    SmartReferenceCardModel card,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Card Header ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.flatCobalt.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_awesome, color: AppTheme.flatCobalt, size: 20),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.smartReferenceCardTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.flatCharcoal,
                      ),
                    ),
                    Text(
                      '${card.importFileCode} ${card.customFileNumber != null ? "• ${card.customFileNumber}" : ""}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.copy_all, size: 20, color: AppTheme.flatCharcoal),
                  tooltip: l10n.copyReferenceCardTooltip,
                  onPressed: () => _copyCardData(context, card),
                ),
                IconButton(
                  icon: const Icon(Icons.library_books_outlined, size: 20, color: AppTheme.flatCobalt),
                  tooltip: l10n.manageGuideEntriesBtn,
                  onPressed: () => _openManageGuideDialog(context),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(l10n.addGuideEntryBtn, style: const TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.flatCharcoal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onPressed: () => _openAddGuidelineDialog(context, ref),
                ),
              ],
            ),
          ],
        ),
        const Divider(height: 24),

        // ── Matched Guidelines Alerts (If any) ──
        if (card.matchedGuideEntries.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: card.matchedGuideEntries.any((e) => e.severity == 'critical')
                  ? AppTheme.flatCrimson.withOpacity(0.08)
                  : AppTheme.flatOrange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: card.matchedGuideEntries.any((e) => e.severity == 'critical')
                    ? AppTheme.flatCrimson.withOpacity(0.4)
                    : AppTheme.flatOrange.withOpacity(0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      card.matchedGuideEntries.any((e) => e.severity == 'critical')
                          ? Icons.warning_amber_rounded
                          : Icons.info_outline,
                      color: card.matchedGuideEntries.any((e) => e.severity == 'critical')
                          ? AppTheme.flatCrimson
                          : AppTheme.flatOrange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      card.matchedGuideEntries.any((e) => e.severity == 'critical')
                          ? l10n.guideCriticalAlertTitle
                          : l10n.guideWarningAlertTitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: card.matchedGuideEntries.any((e) => e.severity == 'critical')
                            ? AppTheme.flatCrimson
                            : AppTheme.flatOrange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...card.matchedGuideEntries.map((e) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Text(
                              '${e.title}: ${e.content}',
                              style: const TextStyle(fontSize: 12, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── Grid of Information Cards ──
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            // 1. Product Summary Box
            _buildSectionBox(
              title: l10n.refCardProductSection,
              icon: Icons.inventory_2_outlined,
              accentColor: AppTheme.flatCobalt,
              children: [
                _buildInfoRow(l10n.refCardHsCodeLabel, card.hsCode.isNotEmpty ? card.hsCode : 'غير محدد', isBadge: true),
                _buildInfoRow(l10n.refCardCategoryLabel, card.productCategory.isNotEmpty ? card.productCategory : 'غير محدد'),
                _buildInfoRow(l10n.refCardTotalCbmLabel, '${card.totalCbm} متر مكعب'),
                _buildInfoRow(l10n.refCardGrossWeightLabel, '${card.totalGrossWeightKg} كجم'),
                _buildInfoRow(l10n.refCardPackagesCountLabel, '${card.packagesCount} طرد'),
              ],
            ),

            // 2. Route & Carrier Box
            _buildSectionBox(
              title: l10n.refCardRouteSection,
              icon: Icons.directions_boat_outlined,
              accentColor: AppTheme.flatCharcoal,
              children: [
                _buildInfoRow(l10n.refCardPolLabel, card.originPort),
                _buildInfoRow(l10n.refCardPodLabel, card.destinationPort, isHighlighted: true),
                _buildInfoRow(l10n.refCardCarrierLabel, card.carrier.isNotEmpty ? card.carrier : 'معتمد'),
                _buildInfoRow('الشروط التجارية:', (card.routeSummary['incoterm_code'] as String?) ?? 'FOB'),
                _buildInfoRow('نوع الشحن:', (card.routeSummary['shipment_mode'] as String?) ?? 'Sea FCL'),
              ],
            ),

            // 3. Critical Dates & Free Time Box
            _buildSectionBox(
              title: l10n.refCardDatesSection,
              icon: Icons.access_time_rounded,
              accentColor: AppTheme.flatOrange,
              children: [
                _buildInfoRow(l10n.refCardFreeDaysLabel, '${card.freeDays} يوماً'),
                _buildInfoRow('تاريخ الوصول:', (card.criticalDates['required_eta'] as String?) ?? 'قيد التحديد'),
                _buildInfoRow('جاهزية البضاعة:', (card.criticalDates['cargo_ready_date'] as String?) ?? 'جاهزة'),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.flatEmerald.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    card.freeTimeStatus,
                    style: const TextStyle(fontSize: 11, color: AppTheme.flatEmerald, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            // 4. Customs Documents Readiness Box
            _buildSectionBox(
              title: l10n.refCardDocsSection,
              icon: Icons.verified_user_outlined,
              accentColor: card.isDocsComplete ? AppTheme.flatEmerald : AppTheme.flatCrimson,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: card.isDocsComplete
                        ? AppTheme.flatEmerald.withOpacity(0.12)
                        : AppTheme.flatCrimson.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        card.isDocsComplete ? Icons.check_circle : Icons.error_outline,
                        size: 14,
                        color: card.isDocsComplete ? AppTheme.flatEmerald : AppTheme.flatCrimson,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        card.isDocsComplete ? l10n.refCardDocsCompleteBadge : l10n.refCardDocsPendingBadge,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: card.isDocsComplete ? AppTheme.flatEmerald : AppTheme.flatCrimson,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                _buildInfoRow(
                  'شهادة المنشأ الأصلية:',
                  card.hasCooAttached ? l10n.refCardCooAttachedBadge : l10n.refCardCooMissingBadge,
                  isAlert: !card.hasCooAttached && card.isCooRequired,
                ),
                if (card.pendingDocuments.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'مستندات مطلوبة: ${card.pendingDocuments.take(2).join("، ")}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ],
              ],
            ),

            // 5. Cost Comparison Box
            _buildSectionBox(
              title: l10n.refCardCostSection,
              icon: Icons.monetization_on_outlined,
              accentColor: card.varianceAmount <= 0 ? AppTheme.flatEmerald : AppTheme.flatCrimson,
              children: [
                _buildInfoRow(l10n.refCardEstCostLabel, '${card.estimatedCost} ${card.currency}'),
                _buildInfoRow(l10n.refCardActualCostLabel, '${card.actualCost} ${card.currency}'),
                _buildInfoRow(
                  l10n.refCardVarianceLabel,
                  '${card.varianceAmount} (${card.variancePercentage}%)',
                  isAlert: card.varianceAmount > 0,
                  isHighlighted: card.varianceAmount <= 0,
                ),
                const SizedBox(height: 4),
                Text(
                  card.costSummary['status'] as String? ?? '',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: card.varianceAmount <= 0 ? AppTheme.flatEmerald : AppTheme.flatCrimson,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionBox({
    required String title,
    required IconData icon,
    required Color accentColor,
    required List<Widget> children,
  }) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accentColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const Divider(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isBadge = false,
    bool isHighlighted = false,
    bool isAlert = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: isBadge
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.flatCobalt.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      value,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.flatCobalt),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                : Text(
                    value,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: (isHighlighted || isAlert) ? FontWeight.bold : FontWeight.normal,
                      color: isAlert
                          ? AppTheme.flatCrimson
                          : (isHighlighted ? AppTheme.flatEmerald : AppTheme.flatCharcoal),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ],
      ),
    );
  }
}
