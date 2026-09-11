import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';

void main() {
  group('Screen 0: Operational Workspace Dashboard Localization Strictness Tests', () {
    final latinRegex = RegExp(r'[a-zA-Z]');
    final bilingualSlashRegex = RegExp(r'[a-zA-Z]\s*/|/\s*[a-zA-Z]');

    test('Arabic localizations for Screen 0 must contain 0 Latin characters and 0 bilingual slashes', () {
      const lAr = AppLocalizationsAr();

      final screen0ArabicStrings = <String, String>{
        'operationalDashboardTitle': lAr.operationalDashboardTitle,
        'priority': lAr.priority,
        'customsBrokerLabel': lAr.customsBrokerLabel,
        'quickSearchLabel': lAr.quickSearchLabel,
        'resetFilters': lAr.resetFilters,
        'allBrokers': lAr.allBrokers,
        'priorityAll': lAr.priorityAll,
        'clearFilter': lAr.clearFilter,
        'matchingShipments': lAr.matchingShipments,
        'shipmentCountUnit': lAr.shipmentCountUnit,
        'currentPhase': lAr.currentPhase,
        'operationalStep': lAr.operationalStep,
        'purchaseOrder': lAr.purchaseOrder,
        'unassigned': lAr.unassigned,
        'copyTooltip': lAr.copyTooltip,
        'copiedToClipboard': lAr.copiedToClipboard('بيانات'),
        'operationalExportTsvBtn': lAr.operationalExportTsvBtn,
        'operationalExportExcelBtn': lAr.operationalExportExcelBtn,
        'operationalExportPdfBtn': lAr.operationalExportPdfBtn,
        'operationalCopyDossierBtn': lAr.operationalCopyDossierBtn,
        'operationalExportTsvDialogTitle': lAr.operationalExportTsvDialogTitle,
        'operationalExportExcelDialogTitle': lAr.operationalExportExcelDialogTitle,
        'operationalReportTitle': lAr.operationalReportTitle,
        'operationalPdfSystemBranding': lAr.operationalPdfSystemBranding,
        'operationalPdfOfficialBadge': lAr.operationalPdfOfficialBadge,
        'operationalPdfFilterCriteria': lAr.operationalPdfFilterCriteria,
        'operationalReportGeneratedAt': lAr.operationalReportGeneratedAt,
        'operationalReportGeneratedBy': lAr.operationalReportGeneratedBy,
        'operationalDossierCriteria': lAr.operationalDossierCriteria,
        'operationalCopiedTsvSuccess': lAr.operationalCopiedTsvSuccess,
        'operationalCopiedExcelSuccess': lAr.operationalCopiedExcelSuccess,
        'operationalCopiedDossierSuccess': lAr.operationalCopiedDossierSuccess,
        'operationalTsvHeaderShipmentName': lAr.operationalTsvHeaderShipmentName,
        'operationalTsvHeaderFileCode': lAr.operationalTsvHeaderFileCode,
        'operationalTsvHeaderCustomFileNo': lAr.operationalTsvHeaderCustomFileNo,
        'operationalTsvHeaderImporter': lAr.operationalTsvHeaderImporter,
        'operationalTsvHeaderSupplier': lAr.operationalTsvHeaderSupplier,
        'operationalTsvHeaderPriority': lAr.operationalTsvHeaderPriority,
        'operationalTsvHeaderCurrentPhase': lAr.operationalTsvHeaderCurrentPhase,
        'operationalTsvHeaderOperationalStep': lAr.operationalTsvHeaderOperationalStep,
        'operationalTsvHeaderBroker': lAr.operationalTsvHeaderBroker,
        'operationalTsvHeaderPoNumber': lAr.operationalTsvHeaderPoNumber,
        'operationalTsvHeaderProgress': lAr.operationalTsvHeaderProgress,
        'operationalTsvHeaderNextAction': lAr.operationalTsvHeaderNextAction,
        'operationalTsvHeaderStatus': lAr.operationalTsvHeaderStatus,
        'pathwayPrevFreightStudies': lAr.pathwayPrevFreightStudies,
        'pathwayPrevFilePlanning': lAr.pathwayPrevFilePlanning,
        'pathwayCurrent': lAr.pathwayCurrent,
        'pathwayNext': lAr.pathwayNext,
        'pathwayNextImportReqs': lAr.pathwayNextImportReqs,
        'nextStepDefaultTitle': lAr.nextStepDefaultTitle,
        'nextStepDefaultDesc': lAr.nextStepDefaultDesc,
        'responsibleImportTeam': lAr.responsibleImportTeam,
        'nextStepImportReqsTitle': lAr.nextStepImportReqsTitle,
        'nextStepImportReqsDesc': lAr.nextStepImportReqsDesc,
        'responsibleImportSpecialist': lAr.responsibleImportSpecialist,
        'nextStepCustomsConsultTitle': lAr.nextStepCustomsConsultTitle,
        'nextStepCustomsConsultDesc': lAr.nextStepCustomsConsultDesc,
        'responsibleCustomsBroker': lAr.responsibleCustomsBroker,
        'nextStepFinanceApprovalTitle': lAr.nextStepFinanceApprovalTitle,
        'nextStepFinanceApprovalDesc': lAr.nextStepFinanceApprovalDesc,
        'responsibleFinanceDept': lAr.responsibleFinanceDept,
        'nextStepNafezaAcidTitle': lAr.nextStepNafezaAcidTitle,
        'nextStepNafezaAcidDesc': lAr.nextStepNafezaAcidDesc,
        'responsibleNafezaSpecialist': lAr.responsibleNafezaSpecialist,
        'nextStepFreightBookingTitle': lAr.nextStepFreightBookingTitle,
        'nextStepFreightBookingDesc': lAr.nextStepFreightBookingDesc,
        'responsibleFreightForwarder': lAr.responsibleFreightForwarder,
        'nextStepTransitTrackingTitle': lAr.nextStepTransitTrackingTitle,
        'nextStepTransitTrackingDesc': lAr.nextStepTransitTrackingDesc,
        'responsibleShippingCarrier': lAr.responsibleShippingCarrier,
        'nextStepArrivalNoticeTitle': lAr.nextStepArrivalNoticeTitle,
        'nextStepArrivalNoticeDesc': lAr.nextStepArrivalNoticeDesc,
        'nextStepDutyPaymentTitle': lAr.nextStepDutyPaymentTitle,
        'nextStepDutyPaymentDesc': lAr.nextStepDutyPaymentDesc,
        'nextStepInlandTransportTitle': lAr.nextStepInlandTransportTitle,
        'nextStepInlandTransportDesc': lAr.nextStepInlandTransportDesc,
        'responsibleWarehouseCustodian': lAr.responsibleWarehouseCustodian,
        'nextStepLandedCostTitle': lAr.nextStepLandedCostTitle,
        'nextStepLandedCostDesc': lAr.nextStepLandedCostDesc,
        'responsibleFinanceAuditing': lAr.responsibleFinanceAuditing,
        'nextStepClosureTitle': lAr.nextStepClosureTitle,
        'nextStepClosureDesc': lAr.nextStepClosureDesc,
        'responsibleImportManager': lAr.responsibleImportManager,
      };

      for (final entry in screen0ArabicStrings.entries) {
        final key = entry.key;
        final val = entry.value;

        expect(
          latinRegex.hasMatch(val),
          isFalse,
          reason: 'Key "$key" in Arabic must NOT contain Latin characters: "$val"',
        );

        expect(
          bilingualSlashRegex.hasMatch(val),
          isFalse,
          reason: 'Key "$key" in Arabic must NOT contain bilingual slashes: "$val"',
        );
      }
    });

    test('English localizations for Screen 0 are populated and valid', () {
      const lEn = AppLocalizationsEn();

      expect(lEn.operationalDashboardTitle, 'Operational Workspace Dashboard');
      expect(lEn.priority, 'Priority:');
      expect(lEn.customsBrokerLabel, 'Customs Broker:');
      expect(lEn.quickSearchLabel, 'Quick Search:');
      expect(lEn.resetFilters, 'Reset Filters');
      expect(lEn.operationalExportTsvBtn, 'Export Operations (TSV)');
      expect(lEn.operationalExportExcelBtn, 'Export Excel (CSV)');
      expect(lEn.operationalExportPdfBtn, 'Print Operations (PDF)');
      expect(lEn.operationalCopyDossierBtn, 'Copy Dossier');
      expect(lEn.pathwayCurrent, 'Current');
      expect(lEn.pathwayNext, 'Next Step');
    });
  });
}
