import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/helpers/table_copy_helper.dart';
import 'package:frontend/core/services/table_export_service.dart';

void main() {
  group('TableCopyHelper Unit Tests (Task J)', () {
    test('cleanCell handles null, numbers, tabs, and newlines', () {
      expect(TableCopyHelper.cleanCell(null), '');
      expect(TableCopyHelper.cleanCell(123), '123');
      expect(TableCopyHelper.cleanCell(45.678), '45.678');
      expect(TableCopyHelper.cleanCell('Hello\tWorld\nTest\r\n'), 'Hello World Test');
      expect(TableCopyHelper.cleanCell('  بند التعريفة   '), 'بند التعريفة');
    });

    test('formatRowAsTsv formats row as tab-separated values', () {
      final row = ['PO-2026-001', 'Description with\ttab', 1500, 25.5];
      final tsv = TableCopyHelper.formatRowAsTsv(row);
      expect(tsv, 'PO-2026-001\tDescription with tab\t1500\t25.5');
    });

    test('formatRowWithHeadersAsTsv formats header and data lines', () {
      final headers = ['PO Code', 'Item', 'Qty'];
      final row = ['PO-001', 'Iron Bars', 50];
      final tsv = TableCopyHelper.formatRowWithHeadersAsTsv(headers, row);
      expect(tsv, 'PO Code\tItem\tQty\nPO-001\tIron Bars\t50');
    });

    test('formatTableAsTsv formats full multi-row table as TSV', () {
      final headers = ['Code', 'Price', 'Currency'];
      final rows = [
        ['ITEM-1', 100.0, 'USD'],
        ['ITEM-2', 250.5, 'EUR'],
      ];
      final tsv = TableCopyHelper.formatTableAsTsv(headers, rows);
      expect(tsv, 'Code\tPrice\tCurrency\nITEM-1\t100.0\tUSD\nITEM-2\t250.5\tEUR');
    });
  });

  group('TableExportService Content Generation Tests (Task J)', () {
    test('buildCsvContent prefixes UTF-8 BOM and properly quotes commas and quotes', () {
      final headers = ['كود الصنف', 'الوصف', 'السعر'];
      final rows = [
        ['ITM-01', 'Iron, Steel & "Coils"', 1500.50],
        ['ITM-02', 'Copper Wire', 3200.00],
      ];

      final csv = TableExportService.buildCsvContent(headers, rows);

      // Must start with UTF-8 BOM for Microsoft Excel Arabic support
      expect(csv.startsWith('\uFEFF'), isTrue);

      // Contains Arabic headers
      expect(csv.contains('كود الصنف,الوصف,السعر'), isTrue);

      // Escapes quotes and commas
      expect(csv.contains('"Iron, Steel & ""Coils"""'), isTrue);
      expect(csv.contains('Copper Wire'), isTrue);
    });

    test('buildTsvContent prefixes UTF-8 BOM and separates by tabs', () {
      final headers = ['HS Code', 'Description', 'Total CBM'];
      final rows = [
        ['8471.30', 'Laptops & Devices', 1.450],
        ['8504.40', 'Static Converters', 0.820],
      ];

      final tsv = TableExportService.buildTsvContent(headers, rows);

      expect(tsv.startsWith('\uFEFF'), isTrue);
      expect(tsv.contains('HS Code\tDescription\tTotal CBM'), isTrue);
      expect(tsv.contains('8471.30\tLaptops & Devices\t1.45'), isTrue);
      expect(tsv.contains('8504.40\tStatic Converters\t0.82'), isTrue);
    });
  });
}
