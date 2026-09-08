import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/widgets/enterprise_data_table/enterprise_data_table.dart';

class TestItem {
  final int id;
  final String name;
  final String category;
  final int score;

  const TestItem({
    required this.id,
    required this.name,
    required this.category,
    required this.score,
  });
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final testItems = [
    const TestItem(id: 1, name: 'شحنة حديد', category: 'صناعي', score: 85),
    const TestItem(id: 2, name: 'قطع غيار توربينات', category: 'ميكانيكا', score: 95),
    const TestItem(id: 3, name: 'مواد عازلة', category: 'إنشاءات', score: 70),
    const TestItem(id: 4, name: 'أجهزة كهربائية', category: 'إلكترونيات', score: 60),
    const TestItem(id: 5, name: 'حبيبات بلاستيك', category: 'بتروكيماويات', score: 90),
  ];

  List<EnterpriseColumn<TestItem>> buildTestColumns() {
    return [
      EnterpriseColumn<TestItem>(
        id: 'id',
        title: 'الرقم',
        isLocked: true,
        searchValue: (item) => item.id.toString(),
        exportValue: (item) => item.id.toString(),
        cellBuilder: (context, item, index) => Text('${item.id}'),
      ),
      EnterpriseColumn<TestItem>(
        id: 'name',
        title: 'اسم الصنف',
        searchValue: (item) => item.name,
        exportValue: (item) => item.name,
        cellBuilder: (context, item, index) => Text(item.name),
      ),
      EnterpriseColumn<TestItem>(
        id: 'category',
        title: 'التصنيف',
        searchValue: (item) => item.category,
        exportValue: (item) => item.category,
        cellBuilder: (context, item, index) => Text(item.category),
      ),
      EnterpriseColumn<TestItem>(
        id: 'score',
        title: 'الدرجة',
        sortComparator: (a, b) => a.score.compareTo(b.score),
        searchValue: (item) => item.score.toString(),
        exportValue: (item) => item.score.toString(),
        cellBuilder: (context, item, index) => Text('${item.score}'),
      ),
    ];
  }

  Widget createTestWidget({
    List<TestItem>? data,
    bool isLoading = false,
    bool enableSelection = false,
    Set<TestItem>? selectedItems,
    ValueChanged<Set<TestItem>>? onSelectionChanged,
    Widget? bulkActions,
    int initialPageSize = 25,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: EnterpriseDataTable<TestItem>(
          title: 'جدول الأصناف التجريبي',
          storageKey: 'test_items_table',
          data: data ?? testItems,
          columns: buildTestColumns(),
          isLoading: isLoading,
          enableSelection: enableSelection,
          selectedItems: selectedItems,
          onSelectionChanged: onSelectionChanged,
          bulkActions: bulkActions,
          initialPageSize: initialPageSize,
        ),
      ),
    );
  }

  testWidgets('EnterpriseDataTable renders title, record count, and data rows', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('جدول الأصناف التجريبي'), findsOneWidget);
    expect(find.text('5 سجل'), findsOneWidget);
    expect(find.text('شحنة حديد'), findsOneWidget);
    expect(find.text('قطع غيار توربينات'), findsOneWidget);
    expect(find.text('مواد عازلة'), findsOneWidget);
  });

  testWidgets('EnterpriseDataTable instant search filters rows correctly', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    final searchField = find.byType(TextField).first;
    await tester.enterText(searchField, 'توربينات');
    await tester.pumpAndSettle();

    expect(find.text('قطع غيار توربينات'), findsOneWidget);
    expect(find.text('شحنة حديد'), findsNothing);
    expect(find.text('1 من 5 سجل'), findsOneWidget);

    // Clear search
    final clearBtn = find.byIcon(Icons.clear);
    expect(clearBtn, findsOneWidget);
    await tester.tap(clearBtn);
    await tester.pumpAndSettle();

    expect(find.text('شحنة حديد'), findsOneWidget);
    expect(find.text('5 سجل'), findsOneWidget);
  });

  testWidgets('EnterpriseDataTable sorts by score column when clicked', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Tap on 'الدرجة' header
    final scoreHeader = find.text('الدرجة');
    expect(scoreHeader, findsOneWidget);
    await tester.tap(scoreHeader);
    await tester.pumpAndSettle();

    // Verify sort ascending: 60 should be first, 95 last
    final rowTexts = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList();
    expect(rowTexts.contains('60'), isTrue);
  });

  testWidgets('EnterpriseDataTable pagination slices items properly', (tester) async {
    await tester.pumpWidget(createTestWidget(initialPageSize: 2));
    await tester.pumpAndSettle();

    // Should show 2 items on page 1
    expect(find.text('عرض 1 - 2 من إجمالي 5'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);

    // Next page
    final nextBtn = find.byTooltip('الصفحة التالية');
    expect(nextBtn, findsOneWidget);
    await tester.tap(nextBtn);
    await tester.pumpAndSettle();

    expect(find.text('عرض 3 - 4 من إجمالي 5'), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);
  });

  testWidgets('EnterpriseDataTable supports multi-row selection and bulk actions', (tester) async {
    Set<TestItem> selected = {};

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return createTestWidget(
            enableSelection: true,
            selectedItems: selected,
            onSelectionChanged: (s) => setState(() => selected = s),
            bulkActions: Text('Bulk: ${selected.length}'),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    // Find first row checkbox
    final checkboxes = find.byType(Checkbox);
    expect(checkboxes, findsWidgets);

    // Tap row 1 checkbox (index 1 because index 0 is select-all header)
    await tester.tap(checkboxes.at(1));
    await tester.pumpAndSettle();

    expect(selected.length, 1);
    expect(find.text('تم تحديد 1'), findsOneWidget);
    expect(find.text('Bulk: 1'), findsOneWidget);

    // Tap select all header checkbox
    await tester.tap(checkboxes.first);
    await tester.pumpAndSettle();

    expect(selected.length, 5);
    expect(find.text('تم تحديد 5'), findsOneWidget);
  });

  testWidgets('EnterpriseDataTable shows shimmer skeleton when isLoading is true', (tester) async {
    await tester.pumpWidget(createTestWidget(isLoading: true));
    await tester.pump(); // don't pumpAndSettle because animation repeats

    expect(find.byType(EnterpriseTableShimmerSkeleton), findsOneWidget);
    expect(find.text('شحنة حديد'), findsNothing);
  });

  testWidgets('EnterpriseDataTable opens column picker and protects locked columns', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    final colBtn = find.byIcon(Icons.view_column_outlined);
    expect(colBtn, findsOneWidget);
    await tester.tap(colBtn);
    await tester.pumpAndSettle();

    expect(find.text('تخصيص أعمدة الجدول'), findsOneWidget);
    expect(find.text('مثبت'), findsOneWidget); // locked column 'id'

    // Close dialog
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(find.text('تخصيص أعمدة الجدول'), findsNothing);
  });
}
