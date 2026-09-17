import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
              horizontal: 16,
              vertical: density.isUltraCompact ? 5 : (density.isCompact ? 7 : 9),
            ),
            decoration: BoxDecoration(
              color: AppTheme.charcoal,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, headerConstraints) {
                final isNarrow = headerConstraints.maxWidth < 1000;

                final iconAndTitle = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(density.isUltraCompact ? 5 : (density.isCompact ? 6.5 : 8)),
                      decoration: BoxDecoration(
                        color: headerColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: headerColor.withOpacity(0.5)),
                      ),
                      child: Icon(headerIcon, color: headerColor, size: density.headerIconSize),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            Directionality.of(context) == TextDirection.rtl ? titleAr : titleEn,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: density.headerTitleFontSize,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (stageCode.isNotEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: density.isUltraCompact ? 6 : 8,
                                vertical: density.isUltraCompact ? 1 : 2,
                              ),
                              decoration: BoxDecoration(
                                color: headerColor.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: headerColor.withOpacity(0.6)),
                              ),
                              child: Text(
                                stageCode,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: DisplayDensityMode.clampFontSize(density.headerSubtitleFontSize),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          iconAndTitle,
                          const BackToDashboardButton(),
                        ],
                      ),
                      if (showStageLifecycleControls) ...[
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ShipmentStageLifecycleControl(
                            importFileId: selectedImportFileId,
                            stageName: Directionality.of(context) == TextDirection.rtl ? titleAr : titleEn,
                            stageCode: stageCode,
                            onStatusChanged: onShipmentStatusChanged,
                          ),
                        ),
                      ],
                      if (headerActions != null && headerActions!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: headerActions!,
                        ),
                      ],
                    ],
                  );
                }

                // Desktop Full Width Header
                return Row(
                  children: [
                    Expanded(child: iconAndTitle),
                    if (showStageLifecycleControls) ...[
                      const SizedBox(width: 16),
                      ShipmentStageLifecycleControl(
                        importFileId: selectedImportFileId,
                        stageName: Directionality.of(context) == TextDirection.rtl ? titleAr : titleEn,
                        stageCode: stageCode,
                        onStatusChanged: onShipmentStatusChanged,
                      ),
                    ],
                    if (headerActions != null && headerActions!.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Flexible(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          alignment: WrapAlignment.end,
                          children: headerActions!,
                        ),
                      ),
                    ],
                    const SizedBox(width: 12),
                    const BackToDashboardButton(),
                  ],
                );
              },
            ),
          ),

          // Optional Top Banner
          if (topBanner != null) topBanner!,

          // 100% Full-Width Body Workspace with Anti-Occlusion Clearance Buffer (+72px)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 72.0),
              child: body,
            ),
          ),
        ],
      ),
    );
  }
}
