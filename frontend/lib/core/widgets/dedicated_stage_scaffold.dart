import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/display_name_resolver.dart';
import '../theme/app_theme.dart';
import '../theme/density_provider.dart';
import 'back_to_dashboard_button.dart';
import 'shipment_stage_lifecycle_control.dart';

/// A dedicated, full-width scaffold for independent operational stages in ImportFlow ERP.
/// Provides a unified enterprise header with stage code badge, lifecycle controls,
/// shipment selector, and header actions while dedicating 100% of the screen width
/// to the actual stage workspace without nested vertical sub-tab navigation.
class DedicatedStageScaffold extends ConsumerWidget {
  final String stageCode;
  final String titleAr;
  final String titleEn;
  final IconData headerIcon;
  final Color headerColor;
  final Widget body;
  final List<Widget>? headerActions;
  final Widget? topBanner;
  final int? selectedImportFileId;
  final bool showStageLifecycleControls;
  final VoidCallback? onShipmentStatusChanged;

  const DedicatedStageScaffold({
    super.key,
    required this.stageCode,
    required this.titleAr,
    required this.titleEn,
    required this.headerIcon,
    this.headerColor = AppTheme.cobalt,
    required this.body,
    this.headerActions,
    this.topBanner,
    this.selectedImportFileId,
    this.showStageLifecycleControls = true,
    this.onShipmentStatusChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final density = ref.watch(displayDensityProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          // Top Header Bar
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: density.isUltraCompact ? 10 : 14,
              vertical: density.isUltraCompact ? 3.0 : (density.isCompact ? 4.5 : 6.0),
            ),
            decoration: BoxDecoration(
              color: AppTheme.charcoal,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, headerConstraints) {
                final isArabic = Directionality.of(context) == TextDirection.rtl;
                final badgeText = DisplayNameResolver.resolveStageBadge(stageCode, isArabic: isArabic);

                final iconAndTitle = Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(density.isUltraCompact ? 4 : (density.isCompact ? 5.5 : 7)),
                      decoration: BoxDecoration(
                        color: headerColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: headerColor.withOpacity(0.5)),
                      ),
                      child: Icon(headerIcon, color: headerColor, size: density.headerIconSize * 0.9),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              isArabic ? titleAr : titleEn,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: DisplayDensityMode.clampFontSize(density.headerTitleFontSize * 0.9),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (badgeText.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: density.isUltraCompact ? 5 : 7,
                                vertical: density.isUltraCompact ? 1 : 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: headerColor.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: headerColor.withOpacity(0.6)),
                              ),
                              child: Text(
                                badgeText,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: DisplayDensityMode.clampFontSize(density.headerSubtitleFontSize * 0.9),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );

                final hasControls = showStageLifecycleControls;
                final hasActions = headerActions != null && headerActions!.isNotEmpty;

                if (headerConstraints.maxWidth < 650) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(child: iconAndTitle),
                          const SizedBox(width: 8),
                          const BackToDashboardButton(),
                        ],
                      ),
                      if (hasControls || hasActions) ...[
                        const SizedBox(height: 6),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasControls) ...[
                                ShipmentStageLifecycleControl(
                                  importFileId: selectedImportFileId,
                                  stageName: Directionality.of(context) == TextDirection.rtl ? titleAr : titleEn,
                                  stageCode: stageCode,
                                  onStatusChanged: onShipmentStatusChanged,
                                ),
                                if (hasActions) const SizedBox(width: 8),
                              ],
                              if (hasActions) ...headerActions!,
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                }

                // Desktop / Laptop Single Row Header (<40px height)
                return Row(
                  children: [
                    Expanded(child: iconAndTitle),
                    if (showStageLifecycleControls) ...[
                      const SizedBox(width: 10),
                      // Stop Shipment & Skip Step remain directly visible and prominent in AppTheme.crimson
                      ShipmentStageLifecycleControl(
                        importFileId: selectedImportFileId,
                        stageName: Directionality.of(context) == TextDirection.rtl ? titleAr : titleEn,
                        stageCode: stageCode,
                        onStatusChanged: onShipmentStatusChanged,
                      ),
                    ],
                    if (hasActions) ...[
                      const SizedBox(width: 8),
                      // Secondary actions menu or compact row
                      if (headerConstraints.maxWidth < 1100 && headerActions!.length > 2)
                        PopupMenuButton<int>(
                          tooltip: isArabic ? 'إجراءات إضافية' : 'More Actions',
                          position: PopupMenuPosition.under,
                          elevation: 6,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          color: const Color(0xFF1E2631),
                          itemBuilder: (ctx) => [
                            for (int i = 0; i < headerActions!.length; i++)
                              PopupMenuItem<int>(
                                value: i,
                                height: 36,
                                child: headerActions![i],
                              ),
                          ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.cobalt.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: AppTheme.cobalt.withOpacity(0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isArabic ? 'الإجراءات' : 'Actions',
                                  style: TextStyle(
                                    fontSize: density.buttonFontSize,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.arrow_drop_down, size: 14, color: Colors.white70),
                              ],
                            ),
                          ),
                        )
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (int i = 0; i < headerActions!.length; i++) ...[
                              headerActions![i],
                              if (i < headerActions!.length - 1) const SizedBox(width: 6),
                            ],
                          ],
                        ),
                    ],
                    const SizedBox(width: 8),
                    const BackToDashboardButton(),
                  ],
                );
              },
            ),
          ),

          // Optional Top Banner
          if (topBanner != null) topBanner!,

          // 100% Full-Width Body Workspace (Maximized Viewport)
          Expanded(
            child: body,
          ),
        ],
      ),
    );
  }
}
