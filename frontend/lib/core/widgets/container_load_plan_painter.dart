import 'package:flutter/material.dart';
import '../utils/container_requirement_engine.dart';

class ContainerLoadPlanPainter extends CustomPainter {
  final ContainerPackingResult plan;
  final bool isTopView;

  ContainerLoadPlanPainter({
    required this.plan,
    required this.isTopView,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final spec = plan.spec;
    final double contL = spec.internalLength;
    final double contH = isTopView ? spec.internalWidth : spec.internalHeight;

    const double margin = 10.0;
    final double drawW = size.width - (2 * margin);
    final double drawH = size.height - (2 * margin);

    final double scaleX = drawW / contL;
    final double scaleY = drawH / contH;
    final double scale = scaleX < scaleY ? scaleX : scaleY;

    final double offsetX = margin + (drawW - (contL * scale)) / 2;
    final double offsetY = margin + (drawH - (contH * scale)) / 2;

    final Rect containerRect = Rect.fromLTWH(offsetX, offsetY, contL * scale, contH * scale);
    final Paint borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(containerRect, borderPaint);

    final List<Color> colors = [
      Colors.red.shade400,
      Colors.blue.shade400,
      Colors.purple.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.teal.shade400,
      Colors.pink.shade400,
      Colors.indigo.shade400,
      Colors.amber.shade700,
    ];

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (final p in plan.placedItems) {
      int itemIdx = 0;
      try {
        itemIdx = (int.parse(p.item.itemId) - 1) % colors.length;
      } catch (_) {
        itemIdx = p.item.itemId.hashCode % colors.length;
      }
      final Color color = colors[itemIdx.abs()];

      double itemX = offsetX + (p.x * scale);
      double itemY = 0.0;
      double itemW = p.length * scale;
      double itemH = 0.0;

      if (isTopView) {
        itemY = offsetY + (contH - p.y - p.width) * scale;
        itemH = p.width * scale;
      } else {
        itemY = offsetY + (contH - p.item.height) * scale;
        itemH = p.item.height * scale;
      }

      final Rect itemRect = Rect.fromLTWH(itemX, itemY, itemW, itemH);
      final Paint itemPaint = Paint()
        ..color = color.withOpacity(0.8)
        ..style = PaintingStyle.fill;
      canvas.drawRect(itemRect, itemPaint);

      final Paint itemBorderPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRect(itemRect, itemBorderPaint);

      textPainter.text = TextSpan(
        text: p.item.itemId,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      );
      textPainter.layout();
      final double textX = itemX + (itemW - textPainter.width) / 2;
      final double textY = itemY + (itemH - textPainter.height) / 2;
      textPainter.paint(canvas, Offset(textX, textY));
    }
  }

  @override
  bool shouldRepaint(covariant ContainerLoadPlanPainter oldDelegate) {
    return oldDelegate.plan != plan || oldDelegate.isTopView != isTopView;
  }
}
