import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../localization/app_localizations.dart';
import '../theme/app_theme.dart';

/// Central clipboard helper utility and reusable widgets for copying data
/// across all screens in ImportFlow ERP.
class CopyHelper {
  /// Copies the specified [text] to the system clipboard and displays a
  /// styled, floating confirmation SnackBar.
  static Future<void> copy(
    BuildContext context,
    String text, {
    String? customMessage,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: trimmed));
    if (!context.mounted) return;

    final l10n = context.l10n;
    final message = customMessage ?? l10n.copiedToClipboardGeneric;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        width: 320,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: AppTheme.flatCharcoal,
        duration: const Duration(milliseconds: 1500),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, color: AppTheme.flatEmerald, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A text widget that can be selected, copied via tap, double-tap, right-click,
/// or via an optional hover/static icon button.
class CopyableText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool showIcon;
  final bool isSelectable;
  final String? tooltip;
  final String? copyMessage;

  const CopyableText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.showIcon = false,
    this.isSelectable = true,
    this.tooltip,
    this.copyMessage,
  });

  @override
  State<CopyableText> createState() => _CopyableTextState();
}

class _CopyableTextState extends State<CopyableText> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tooltipText = widget.tooltip ?? l10n.copyTooltip;

    Widget textWidget;
    if (widget.isSelectable) {
      textWidget = SelectableText(
        widget.text,
        style: widget.style,
        textAlign: widget.textAlign,
        maxLines: widget.maxLines,
      );
    } else {
      textWidget = Text(
        widget.text,
        style: widget.style,
        textAlign: widget.textAlign,
        overflow: widget.overflow ?? TextOverflow.ellipsis,
        maxLines: widget.maxLines,
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: tooltipText,
        waitDuration: const Duration(milliseconds: 600),
        child: GestureDetector(
          onSecondaryTap: () => CopyHelper.copy(
            context,
            widget.text,
            customMessage: widget.copyMessage,
          ),
          onDoubleTap: () => CopyHelper.copy(
            context,
            widget.text,
            customMessage: widget.copyMessage,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(child: textWidget),
              if (widget.showIcon || _isHovered) ...[
                const SizedBox(width: 4),
                InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () => CopyHelper.copy(
                    context,
                    widget.text,
                    customMessage: widget.copyMessage,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Icon(
                      Icons.copy_rounded,
                      size: (widget.style?.fontSize ?? 14) * 0.95,
                      color: AppTheme.flatCobalt.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A cell wrapper for data tables or key-value summary rows that enables
/// copying either the cell value or the full row summary.
class CopyableTableCell extends StatelessWidget {
  final Widget child;
  final String value;
  final String? rowSummary;
  final String? customMessage;

  const CopyableTableCell({
    super.key,
    required this.child,
    required this.value,
    this.rowSummary,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return GestureDetector(
      onSecondaryTapUp: (details) async {
        final selected = await showMenu<String>(
          context: context,
          position: RelativeRect.fromLTRB(
            details.globalPosition.dx,
            details.globalPosition.dy,
            details.globalPosition.dx + 1,
            details.globalPosition.dy + 1,
          ),
          items: [
            PopupMenuItem<String>(
              value: 'cell',
              child: Row(
                children: [
                  const Icon(Icons.copy_rounded, size: 16, color: AppTheme.flatCobalt),
                  const SizedBox(width: 8),
                  Text(l10n.copyValue, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
            if (rowSummary != null && rowSummary!.isNotEmpty)
              PopupMenuItem<String>(
                value: 'row',
                child: Row(
                  children: [
                    const Icon(Icons.table_rows_rounded, size: 16, color: AppTheme.flatEmerald),
                    const SizedBox(width: 8),
                    Text(l10n.copyRow, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
          ],
        );

        if (!context.mounted) return;
        if (selected == 'cell') {
          CopyHelper.copy(context, value, customMessage: customMessage);
        } else if (selected == 'row' && rowSummary != null) {
          CopyHelper.copy(context, rowSummary!, customMessage: l10n.copiedToClipboardGeneric);
        }
      },
      child: Tooltip(
        message: l10n.copyTooltip,
        waitDuration: const Duration(milliseconds: 700),
        child: child,
      ),
    );
  }
}
