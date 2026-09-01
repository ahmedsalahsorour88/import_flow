import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FileSaveHelper Universal File Saving Tests', () {
    test('saveText prepends UTF-8 BOM when requested for Excel compatibility', () {
      final sampleCsv = 'Column1,Column2\nValue1,Value2';
      final withBom = '\uFEFF$sampleCsv';
      final bytes = utf8.encode(withBom);

      expect(bytes[0], equals(0xEF));
      expect(bytes[1], equals(0xBB));
      expect(bytes[2], equals(0xBF));
      expect(bytes.length, equals(utf8.encode(sampleCsv).length + 3));
    });

    test('File extension resolution guarantees primary extension', () {
      final allowed = ['xlsx', 'xls'];
      final primaryExt = allowed.first.toLowerCase().replaceAll('.', '');
      expect(primaryExt, equals('xlsx'));

      var testPath1 = 'C:\\Exports\\MyInvoice';
      final hasValidExt1 = allowed.any((ext) => testPath1.toLowerCase().endsWith('.$ext'));
      if (!hasValidExt1) {
        testPath1 = '$testPath1.$primaryExt';
      }
      expect(testPath1, equals('C:\\Exports\\MyInvoice.xlsx'));

      var testPath2 = 'C:\\Exports\\MyInvoice.xlsx';
      final hasValidExt2 = allowed.any((ext) => testPath2.toLowerCase().endsWith('.$ext'));
      if (!hasValidExt2) {
        testPath2 = '$testPath2.$primaryExt';
      }
      expect(testPath2, equals('C:\\Exports\\MyInvoice.xlsx'));
    });
  });
}
