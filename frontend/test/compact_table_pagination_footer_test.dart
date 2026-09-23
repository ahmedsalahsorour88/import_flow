import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/compact_table_pagination_footer.dart';
import 'package:frontend/core/widgets/enterprise_data_table/widgets/enterprise_table_pagination_bar.dart';

void main() {
  group('CompactTablePaginationFooter Widget Tests', () {
    testWidgets('renders pagination info and calculates bounds accurately', (tester) async {
      int? targetPage;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactTablePaginationFooter(
              currentPage: 2,
              totalPages: 5,
              totalCount: 120,
              pageSize: 25,
              onPageChanged: (page) => targetPage = page,
            ),
          ),
        ),
      );

      // Verify text showing items and pages
      expect(find.textContaining('26 - 50'), findsOneWidget);
      expect(find.textContaining('120'), findsOneWidget);
      expect(find.textContaining('2 / 5'), findsOneWidget);

      // Verify micro buttons exist
      final prevBtn = find.byTooltip('الصفحة السابقة');
      expect(prevBtn, findsOneWidget);
      await tester.tap(prevBtn);
      expect(targetPage, equals(1));

      final nextBtn = find.byTooltip('الصفحة التالية');
      expect(nextBtn, findsOneWidget);
      await tester.tap(nextBtn);
      expect(targetPage, equals(3));

      final firstBtn = find.byTooltip('الصفحة الأولى');
      expect(firstBtn, findsOneWidget);
      await tester.tap(firstBtn);
      expect(targetPage, equals(1));

      final lastBtn = find.byTooltip('الصفحة الأخيرة');
      expect(lastBtn, findsOneWidget);
      await tester.tap(lastBtn);
      expect(targetPage, equals(5));
    });

    testWidgets('disables previous/first buttons on first page', (tester) async {
      int? targetPage;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactTablePaginationFooter(
              currentPage: 1,
              totalPages: 3,
              totalCount: 60,
              pageSize: 20,
              onPageChanged: (page) => targetPage = page,
            ),
          ),
        ),
      );

      final prevBtn = find.byTooltip('الصفحة السابقة');
      await tester.tap(prevBtn);
      // Shouldn't fire because disabled on page 1
      expect(targetPage, isNull);
    });

    testWidgets('renders in compact mode under 36px height', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactTablePaginationFooter(
              currentPage: 1,
              totalPages: 1,
              totalCount: 10,
              pageSize: 25,
              onPageChanged: (_) {},
            ),
          ),
        ),
      );

      final footerFinder = find.byType(CompactTablePaginationFooter);
      expect(footerFinder, findsOneWidget);
      final size = tester.getSize(footerFinder);
      expect(size.height, lessThanOrEqualTo(36.0));
    });
  });

  group('EnterpriseTablePaginationBar Compact Tests', () {
    testWidgets('renders compact 34px bar with micro buttons and page size selector', (tester) async {
      int? changedPage;
      int? changedPageSize;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnterpriseTablePaginationBar(
              currentPage: 1,
              totalCount: 85,
              pageSize: 25,
              availablePageSizes: const [10, 25, 50],
              onPageChanged: (p) => changedPage = p,
              onPageSizeChanged: (s) => changedPageSize = s,
            ),
          ),
        ),
      );

      expect(find.textContaining('1 - 25'), findsOneWidget);
      expect(find.textContaining('85'), findsOneWidget);

      final nextBtn = find.byTooltip('الصفحة التالية');
      await tester.tap(nextBtn);
      expect(changedPage, equals(2));
      expect(changedPageSize, isNull);

      final barFinder = find.byType(EnterpriseTablePaginationBar);
      final barSize = tester.getSize(barFinder);
      expect(barSize.height, lessThanOrEqualTo(36.0));
    });
  });
}
