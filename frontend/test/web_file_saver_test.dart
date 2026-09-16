import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/services/file_save_helper.dart';
import 'package:frontend/core/services/web_file_saver.dart';

void main() {
  group('WebFileSaver & Native Save As Dialog Tests', () {
    test('WebFileSaver stub operates safely in VM / non-web test environment', () async {
      expect(WebFileSaver.isSupported, isFalse);

      final result = await WebFileSaver.saveFileWithPicker(
        bytes: [1, 2, 3],
        fileName: 'test.xlsx',
        allowedExtensions: ['xlsx'],
      );
      expect(result, isNull);

      // Verify triggerFallbackDownload does not crash
      expect(
        () => WebFileSaver.triggerFallbackDownload(
          bytes: [1, 2, 3],
          fileName: 'test.xlsx',
        ),
        returnsNormally,
      );
    });

    test('FileSaveHelper generates correct standard file names for PDF and Excel', () {
      final pdfName = FileSaveHelper.buildExportFileName(
        stageName: 'Customs Valuation Report',
        importFileNameOrCode: 'IMP-2026-0045',
        extension: 'pdf',
      );
      expect(pdfName, equals('Customs Valuation Report - IMP-2026-0045.pdf'));

      final excelName = FileSaveHelper.buildExportFileName(
        stageName: 'CargoX Blockchain & ACI Hub',
        importFileNameOrCode: 'PET Stock',
        extension: 'xlsx',
      );
      expect(excelName, equals('CargoX Blockchain & ACI Hub - PET Stock.xlsx'));

      final csvName = FileSaveHelper.buildExportFileName(
        stageName: 'Container Load Planner',
        importFileNameOrCode: 'IMP/2026/0012',
        extension: '.csv',
      );
      expect(csvName, equals('Container Load Planner - IMP-2026-0012.csv'));
    });

    test('FileSaveHelper sanitizes special characters in both stage and file names', () {
      final sanitized = FileSaveHelper.buildExportFileName(
        stageName: 'Stage <4>: Inspection / Drawing * Samples',
        importFileNameOrCode: 'BATCH? #12:34 | PO',
        extension: '.XLSX',
      );
      expect(sanitized, isNot(contains('<')));
      expect(sanitized, isNot(contains('>')));
      expect(sanitized, isNot(contains(':')));
      expect(sanitized, isNot(contains('/')));
      expect(sanitized, isNot(contains('*')));
      expect(sanitized, isNot(contains('?')));
      expect(sanitized, isNot(contains('|')));
      expect(sanitized.endsWith('.xlsx'), isTrue);
    });
  });
}
