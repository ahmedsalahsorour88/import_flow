import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/services/file_save_helper.dart';

void main() {
  group('Task I — Unified File Naming & Sanitization Tests', () {
    test('sanitizeFileName removes illegal filesystem characters', () {
      const dirty = 'Phase 4: CargoX / Nafeza * <Test> | File?';
      final clean = FileSaveHelper.sanitizeFileName(dirty);
      expect(clean, isNot(contains(':')));
      expect(clean, isNot(contains('/')));
      expect(clean, isNot(contains('*')));
      expect(clean, isNot(contains('<')));
      expect(clean, isNot(contains('>')));
      expect(clean, isNot(contains('|')));
      expect(clean, isNot(contains('?')));
      expect(clean, equals('Phase 4- CargoX - Nafeza - -Test- - File-'));
    });

    test('buildExportFileName creates standardized naming [Stage] - [ImportFile].[ext]', () {
      final fileName = FileSaveHelper.buildExportFileName(
        stageName: 'CargoX Blockchain & ACI Hub',
        importFileNameOrCode: 'PET Stock (IMP-2026-0004)',
        extension: 'xlsx',
      );
      expect(
        fileName,
        equals('CargoX Blockchain & ACI Hub - PET Stock (IMP-2026-0004).xlsx'),
      );
    });

    test('buildExportFileName handles leading dots in extension and dirty characters', () {
      final fileName = FileSaveHelper.buildExportFileName(
        stageName: 'Container Load Planner: Side View',
        importFileNameOrCode: 'IMP/2026/0099',
        extension: '.png',
      );
      expect(
        fileName,
        equals('Container Load Planner- Side View - IMP-2026-0099.png'),
      );
    });

    test('sanitizeFileName handles empty or blank inputs gracefully', () {
      expect(FileSaveHelper.sanitizeFileName(''), equals('Export'));
      expect(FileSaveHelper.sanitizeFileName('   '), equals('Export'));
    });

    test('buildExportFileName normalizes uppercase extension and removes leading dots', () {
      final fileName = FileSaveHelper.buildExportFileName(
        stageName: 'Customs Valuation',
        importFileNameOrCode: 'Invoice-2026-X',
        extension: '.PDF',
      );
      expect(fileName, equals('Customs Valuation - Invoice-2026-X.pdf'));
    });

    test('buildExportFileName handles multiple extensions and spaces cleanly', () {
      final fileName = FileSaveHelper.buildExportFileName(
        stageName: 'Container Load Planner',
        importFileNameOrCode: 'PET Stock (IMP-2026-0004) - Stacking Sim',
        extension: '..xlsx',
      );
      expect(
        fileName,
        equals('Container Load Planner - PET Stock (IMP-2026-0004) - Stacking Sim.xlsx'),
      );
    });
  });
}
