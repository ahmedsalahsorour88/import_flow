import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';
import 'package:frontend/features/lifecycle_board/models/step_config_model.dart';
import 'package:frontend/features/lifecycle_board/services/step_config_export_service.dart';

void main() {
  group('StepConfigExportService Unit Tests', () {
    const ar = AppLocalizationsAr();
    const en = AppLocalizationsEn();

    final testConfigs = [
      const StepConfigModel(
        id: 1,
        stepCode: 'ST-01',
        stepNameAr: 'طلب الشراء وتأكيد التوريد',
        stepNameEn: 'PO & Supply Confirmation',
        phaseId: 1,
        skipPolicy: 'blocked',
        approverRoles: ['Manager'],
        supportsPendingReference: false,
        reasonCategories: ['Technical delay', 'Supplier notice'],
        lastModifiedBy: 'admin',
      ),
      const StepConfigModel(
        id: 2,
        stepCode: 'ST-02',
        stepNameAr: 'إصدار نموذج 4 البنكي',
        stepNameEn: 'Bank Form 4 Issuance',
        phaseId: 2,
        skipPolicy: 'single_approval',
        approverRoles: ['Manager', 'FinanceHead'],
        supportsPendingReference: true,
        reasonCategories: ['Bank processing'],
        lastModifiedBy: 'supervisor',
      ),
    ];

    test('exportToTsv generates valid TSV with UTF-8 BOM in Arabic and English',
        () {
      // Arabic
      final tsvAr = StepConfigExportService.exportToTsv(testConfigs, ar,
          isArabic: true);
      expect(tsvAr.startsWith('\uFEFF'), isTrue);
      expect(tsvAr.contains('\t'), isTrue);
      expect(tsvAr.contains(ar.stepConfigColPhaseCode), isTrue);
      expect(tsvAr.contains('P1-ST-01'), isTrue);
      expect(tsvAr.contains('طلب الشراء وتأكيد التوريد'), isTrue);
      expect(tsvAr.contains(ar.stepConfigPolicyBlocked), isTrue);

      // English
      final tsvEn = StepConfigExportService.exportToTsv(testConfigs, en,
          isArabic: false);
      expect(tsvEn.startsWith('\uFEFF'), isTrue);
      expect(tsvEn.contains(en.stepConfigColPhaseCode), isTrue);
      expect(tsvEn.contains('PO & Supply Confirmation'), isTrue);
      expect(tsvEn.contains(en.stepConfigPolicyBlocked), isTrue);
    });

    test('exportToCsv generates valid RFC 4180 CSV with UTF-8 BOM', () {
      final csv = StepConfigExportService.exportToCsv(testConfigs, ar,
          isArabic: true);
      expect(csv.startsWith('\uFEFF'), isTrue);
      expect(csv.contains(','), isTrue);
      expect(csv.contains(ar.stepConfigColStepName), isTrue);
      expect(csv.contains('طلب الشراء وتأكيد التوريد'), isTrue);
    });

    test('buildDossier generates complete structured plain-text summary', () {
      final dossierAr = StepConfigExportService.buildDossier(testConfigs, ar,
          isArabic: true);
      expect(dossierAr.contains(ar.stepConfigDossierHeader), isTrue);
      expect(dossierAr.contains(ar.stepConfigDossierKpiSummary), isTrue);
      expect(dossierAr.contains(ar.stepConfigDossierRecordsDetails), isTrue);
      expect(dossierAr.contains('ST-01'), isTrue);
      expect(dossierAr.contains('ST-02'), isTrue);
      expect(dossierAr.contains(ar.stepConfigDossierFooter), isTrue);
    });

    test('toRowSummary produces formatted single-line string', () {
      final summary = StepConfigExportService.toRowSummary(testConfigs.first, ar,
          isArabic: true);
      expect(summary.contains('P1-ST-01'), isTrue);
      expect(summary.contains('طلب الشراء وتأكيد التوريد'), isTrue);
      expect(summary.contains(' | '), isTrue);
    });

    test('Handles empty list gracefully across all export formats', () {
      final tsv = StepConfigExportService.exportToTsv([], ar, isArabic: true);
      expect(tsv.startsWith('\uFEFF'), isTrue);

      final csv = StepConfigExportService.exportToCsv([], ar, isArabic: true);
      expect(csv.startsWith('\uFEFF'), isTrue);

      final dossier =
          StepConfigExportService.buildDossier([], ar, isArabic: true);
      expect(dossier.contains(ar.stepConfigDossierHeader), isTrue);
    });
  });
}
