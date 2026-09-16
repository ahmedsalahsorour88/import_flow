import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'back_to_dashboard_button.dart';
import 'shipment_stage_lifecycle_control.dart';

/// A dedicated, full-width scaffold for independent operational stages in ImportFlow ERP.
/// Provides a unified enterprise header with stage code badge, lifecycle controls,
/// shipment selector, and header actions while dedicating 100% of the screen width
/// to the actual stage workspace without nested vertical sub-tab navigation.
class DedicatedStageScaffold extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          // Top Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: headerColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: headerColor.withOpacity(0.5)),
                      ),
                      child: Icon(headerIcon, color: headerColor, size: 20),
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (stageCode.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: headerColor.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: headerColor.withOpacity(0.6)),
                              ),
                              child: Text(
                                stageCode,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
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
                    if (headerActions != null) ...[
                      const SizedBox(width: 16),
                      ...headerActions!,
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

          // 100% Full-Width Body Workspace
          Expanded(
            child: body,
          ),
        ],
      ),
    );
  }
}
