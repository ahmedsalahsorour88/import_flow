import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// Animated skeleton shimmer placeholder for [EnterpriseDataTable] while loading.
class EnterpriseTableShimmerSkeleton extends StatefulWidget {
  final int rowCount;
  final int columnCount;

  const EnterpriseTableShimmerSkeleton({
    super.key,
    this.rowCount = 6,
    this.columnCount = 6,
  });

  @override
  State<EnterpriseTableShimmerSkeleton> createState() =>
      _EnterpriseTableShimmerSkeletonState();
}

class _EnterpriseTableShimmerSkeletonState
    extends State<EnterpriseTableShimmerSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              // Header Skeleton
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.charcoal.withOpacity(0.04),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Row(
                  children: List.generate(widget.columnCount, (index) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: _buildShimmerBox(
                          height: 16,
                          width: double.infinity,
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100,
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Rows Skeleton
              ...List.generate(widget.rowCount, (rowIndex) {
                final isEven = rowIndex.isEven;
                return Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isEven ? Colors.grey.shade50 : Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade100),
                    ),
                  ),
                  child: Row(
                    children: List.generate(widget.columnCount, (colIndex) {
                      // Vary box widths slightly to look natural
                      final factor = 0.6 + ((rowIndex + colIndex) % 4) * 0.1;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _buildShimmerBox(
                              height: 13,
                              width: 120 * factor,
                              baseColor: Colors.grey.shade200,
                              highlightColor: Colors.grey.shade50,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerBox({
    required double height,
    required double width,
    required Color baseColor,
    required Color highlightColor,
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [
            (_animation.value - 0.3).clamp(0.0, 1.0),
            _animation.value.clamp(0.0, 1.0),
            (_animation.value + 0.3).clamp(0.0, 1.0),
          ],
          colors: [
            baseColor,
            highlightColor,
            baseColor,
          ],
        ),
      ),
    );
  }
}
