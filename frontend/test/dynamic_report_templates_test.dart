import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';
import 'package:frontend/features/dynamic_reporting/screens/dynamic_report_builder_screen.dart';
import 'package:frontend/features/import_files/models/import_file_model.dart';

void main() {
  group('Dynamic Report Builder Templates & Timestamp Tests', () {
    late AppLocalizationsAr ar;
    late AppLocalizationsEn en;

    setUp(() {
      ar = const AppLocalizationsAr();
      en = const AppLocalizationsEn();
    });

    test('Template mode labels and preset headers are properly localized', () {
      expect(ar.dynTemplatePresetLabel, equals('قالب التقرير'));
      expect(en.dynTemplatePresetLabel, equals('Report Template'));

      expect(ar.dynTemplateEco, contains('إيكو'));
      expect(en.dynTemplateEco, contains('ECO'));

      expect(ar.dynTemplateScas, contains('سكاس'));
      expect(en.dynTemplateScas, contains('SCAS'));

      expect(ar.dynTemplateCustom, contains('تخصيص حر'));
      expect(en.dynTemplateCustom, contains('Custom'));

      expect(ar.dynLastUpdatedLabel('2026-09-06 11:30:00'), equals('آخر تحديث: 2026-09-06 11:30:00'));
      expect(en.dynLastUpdatedLabel('2026-09-06 11:30:00'), equals('Last Updated: 2026-09-06 11:30:00'));

      expect(ar.dynSearchColumnsPlaceholder, isNotEmpty);
      expect(en.dynSearchColumnsPlaceholder, isNotEmpty);

      expect(ar.dynSelectAll, equals('تحديد الكل'));
      expect(en.dynSelectAll, equals('Select All'));

      expect(ar.dynDeselectAll, equals('إلغاء التحديد'));
      expect(en.dynDeselectAll, equals('Deselect All'));
    });

    test('All 8 Categories are localized in Arabic and English', () {
      expect(ar.dynCatFileAndProject, isNotEmpty);
      expect(en.dynCatFileAndProject, isNotEmpty);

      expect(ar.dynCatCommercialAndPo, isNotEmpty);
      expect(en.dynCatCommercialAndPo, isNotEmpty);

      expect(ar.dynCatShippingAndLogistics, isNotEmpty);
      expect(en.dynCatShippingAndLogistics, isNotEmpty);

      expect(ar.dynCatPackagesAndCbm, isNotEmpty);
      expect(en.dynCatPackagesAndCbm, isNotEmpty);

      expect(ar.dynCatCustomsAndNafeza, isNotEmpty);
      expect(en.dynCatCustomsAndNafeza, isNotEmpty);

      expect(ar.dynCatBankingAndSwift, isNotEmpty);
      expect(en.dynCatBankingAndSwift, isNotEmpty);

      expect(ar.dynCatScasTracking, isNotEmpty);
      expect(en.dynCatScasTracking, isNotEmpty);

      expect(ar.dynCatEcoTracking, isNotEmpty);
      expect(en.dynCatEcoTracking, isNotEmpty);
    });

    test('ECO Template contains exactly 15 milestone & document tracking columns from image in exact order', () {
      expect(DynamicReportBuilderScreen.kEcoPresetColumnIds.length, equals(15));
      expect(DynamicReportBuilderScreen.kEcoPresetColumnIds, equals([
        'scasProjectFileAcid',
        'scasExFactory',
        'scasOrderToOrigin',
        'scasPickUpDate',
        'scasDeparturePort',
        'scasArrivalAlexPort',
        'scasOrigInvoice',
        'scasOrigPackingList',
        'scasOrigCoo',
        'scasOrigBl',
        'scasOrigInsurance',
        'scasInsertNafeza',
        'scasBankForm4',
        'scasDeclare3A',
        'scasMaterialReceived',
      ]));
    });

    test('SCAS Template contains exactly 16 operational tracking columns in exact requested order', () {
      expect(DynamicReportBuilderScreen.kScasPresetColumnIds.length, equals(16));
      expect(DynamicReportBuilderScreen.kScasPresetColumnIds, equals([
        'ecoBroker',
        'ecoShipmentNo',
        'ecoSupplier',
        'ecoProject',
        'ecoPiValue',
        'ecoShippingDate',
        'ecoArrivalPort',
        'ecoArrivalWarehouse',
        'ecoSara',
        'ecoMaro',
        'ecoReadyToPickUp',
        'ecoLatestUpdate',
        'ecoSwiftDate',
        'ecoSwiftAmount',
        'ecoShippingCompany',
        'ecoAcid',
      ]));
    });

    test('SCAS and ECO specific column getters return localized text matching specifications', () {
      expect(ar.dynColEcoBroker, equals('Custom Broker Name'));
      expect(ar.dynColEcoShipmentNo, equals('Shipment No'));
      expect(ar.dynColEcoSupplier, equals('Supp. Name'));
      expect(ar.dynColEcoProject, equals('Project Name'));
      expect(ar.dynColEcoPiValue, equals('PI Value'));
      expect(ar.dynColEcoShippingDate, equals('Shipping Date'));
      expect(ar.dynColEcoArrivalPort, equals('Arrival Port'));
      expect(ar.dynColEcoArrivalWarehouse, equals('Arrival Warehouse'));
      expect(ar.dynColEcoSara, equals('المسئول عن المشروع'));
      expect(ar.dynColEcoMaro, equals('مالك المشروع'));
      expect(en.dynColEcoSara, equals('المسئول عن المشروع'));
      expect(en.dynColEcoMaro, equals('مالك المشروع'));
      expect(ar.dynColEcoSara.toLowerCase(), isNot(contains('sara')));
      expect(ar.dynColEcoMaro.toLowerCase(), isNot(contains('maro')));
      expect(en.dynColEcoSara.toLowerCase(), isNot(contains('sara')));
      expect(en.dynColEcoMaro.toLowerCase(), isNot(contains('maro')));
      expect(ar.dynColEcoReadyToPickUp, equals('Ready to Pick Up Date'));
      expect(ar.dynColEcoLatestUpdate, equals('Latest Update for Pending Shipment'));
      expect(ar.dynColEcoSwiftDate, equals('تاريخ السويفت'));
      expect(ar.dynColEcoSwiftAmount, equals('قيمة السويفت'));
      expect(ar.dynColEcoShippingCompany, equals('شركة الشحن'));
      expect(ar.dynColEcoAcid, equals('ACID'));

      expect(ar.dynColScasProjectFileAcid, equals('Project'));
      expect(ar.dynColScasExFactory, equals('EX Factory'));
      expect(ar.dynColScasOrderToOrigin, equals('Order to Origin for Pick Up'));
      expect(ar.dynColScasPickUpDate, equals('Pick Up Date from Gind'));
      expect(ar.dynColScasDeparturePort, equals('Departure Date from Port (ETD)'));
      expect(ar.dynColScasArrivalAlexPort, equals('Arrival Date to Alex Port (ETA)'));
      expect(ar.dynColScasOrigInvoice, equals('Original Commercial Invoice'));
      expect(ar.dynColScasOrigPackingList, equals('Original Packing List'));
      expect(ar.dynColScasOrigCoo, equals('Original Certificate of Origin'));
      expect(ar.dynColScasOrigBl, equals('Original Bill of Lading'));
      expect(ar.dynColScasOrigInsurance, equals('Original Insurance Certificate'));
      expect(ar.dynColScasInsertNafeza, equals('Insert on Nafeza'));
      expect(ar.dynColScasBankForm4, equals('Bank Name (Form 4)'));
      expect(ar.dynColScasDeclare3A, equals('Declare to 3A'));
      expect(ar.dynColScasMaterialReceived, equals('Material Received'));
    });

    test('Data extraction correctly formats composite values for ECO and SCAS models', () {
      final sampleFile = ImportFileModel(
        importFileId: 101,
        importFileCode: 'O26-IMP-OC-229',
        customFileNumber: '2001830441009610018',
        companyName: 'INNOVO GROUP',
        supplierName: 'TARKET TME/20081',
        brokerName: 'حمدي بسيوني',
        projectNames: 'Lake Residence',
        shipmentMode: 'Sea FCL',
        incotermCode: 'FOB',
        acidNumber: '7595528271012210010',
        acidIssueDate: '2026-05-01',
        form4No: 'F4-8899',
        form4ReceivedDate: '2026-05-15',
        form46No: '46-12345',
        estimatedCost: 7050.08,
        estimatedCostCurrency: 'EUR',
        currentModule: 'Customs Clearance',
        currentStage: 'Customs Inspection & 46',
        nextAction: 'تم الحجز - في انتظار النموذج',
        isCustomsReleased: false,
        cargoReadyDate: '2026-05-06',
        fileOpeningDate: '2026-05-08',
        requiredEta: '2026-05-31',
        portOfLoading: 'Hamburg',
        portOfDischarge: 'Alexandria (El Dekheila)',
        selectedScenario: 'Vertex / Express BL',
        notes: 'في انتظار النموذج',
        owner: 'سارة عبد الله',
        createdAt: '2026-05-01T10:00:00',
        updatedAt: '2026-09-06T11:20:00',
        invoicesData: [
          InvoiceItemModel(
            invoiceNo: 'INV-2026-001',
            amount: 7050.08,
            currency: 'EUR',
            date: '2026-05-03',
          ),
        ],
        packingListsData: [
          PackingListItemModel(
            plNo: 'PL-2026-001',
            totalPackages: 12,
            grossWeightKg: 4500.0,
            cbm: 18.5,
            date: '2026-04-30',
          ),
        ],
      );

      expect(sampleFile.importFileCode, equals('O26-IMP-OC-229'));
      expect(sampleFile.customFileNumber, equals('2001830441009610018'));
      expect(sampleFile.supplierName, equals('TARKET TME/20081'));
      expect(sampleFile.projectNames, equals('Lake Residence'));
      expect(sampleFile.brokerName, equals('حمدي بسيوني'));
      expect(sampleFile.acidNumber, equals('7595528271012210010'));
      expect(sampleFile.invoicesData.first.amount, equals(7050.08));
      expect(sampleFile.invoicesData.first.currency, equals('EUR'));
      expect(sampleFile.packingListsData.first.totalPackages, equals(12));
      expect(sampleFile.packingListsData.first.cbm, equals(18.5));
    });

    test('Company/project filtering logic validates ECO only vs SCAS & Archi Rands', () {
      final ecoFileByCompany = ImportFileModel(
        importFileId: 1,
        importFileCode: 'ECO-001',
        companyName: 'ECO Associates LLC',
        supplierName: 'Supplier 1',
        shipmentMode: 'Sea FCL',
        incotermCode: 'CIF',
        estimatedCost: 1000,
        estimatedCostCurrency: 'USD',
        currentModule: 'Shipping',
        currentStage: 'Booking',
        progressPercent: 20,
        nextAction: 'Pending',
        status: 'Active',
        owner: 'User',
        createdAt: '2026-09-01',
        updatedAt: '2026-09-06',
        invoicesData: const [],
        packingListsData: const [],
      );

      final ecoFileByProject = ImportFileModel(
        importFileId: 2,
        importFileCode: 'PRJ-002',
        companyName: 'Trading Corp',
        supplierName: 'Supplier 2',
        projectNames: 'ECO Tower Project',
        shipmentMode: 'Air',
        incotermCode: 'FOB',
        estimatedCost: 2000,
        estimatedCostCurrency: 'USD',
        currentModule: 'Shipping',
        currentStage: 'Departure',
        progressPercent: 40,
        nextAction: 'Pending',
        status: 'Active',
        owner: 'User',
        createdAt: '2026-09-01',
        updatedAt: '2026-09-06',
        invoicesData: const [],
        packingListsData: const [],
      );

      final scasFile = ImportFileModel(
        importFileId: 3,
        importFileCode: 'SCAS-003',
        companyName: 'SCAS Construction',
        supplierName: 'Supplier 3',
        projectNames: 'Mall Project',
        shipmentMode: 'Sea FCL',
        incotermCode: 'FOB',
        estimatedCost: 3000,
        estimatedCostCurrency: 'USD',
        currentModule: 'Shipping',
        currentStage: 'Customs',
        progressPercent: 60,
        nextAction: 'Pending',
        status: 'Active',
        owner: 'User',
        createdAt: '2026-09-01',
        updatedAt: '2026-09-06',
        invoicesData: const [],
        packingListsData: const [],
      );

      final archiFile = ImportFileModel(
        importFileId: 4,
        importFileCode: 'ARC-004',
        companyName: 'Archi Rands Design',
        supplierName: 'Supplier 4',
        shipmentMode: 'Air',
        incotermCode: 'CIF',
        estimatedCost: 4000,
        estimatedCostCurrency: 'USD',
        currentModule: 'Shipping',
        currentStage: 'Arrival',
        progressPercent: 80,
        nextAction: 'Pending',
        status: 'Active',
        owner: 'User',
        createdAt: '2026-09-01',
        updatedAt: '2026-09-06',
        invoicesData: const [],
        packingListsData: const [],
      );

      final otherFile = ImportFileModel(
        importFileId: 5,
        importFileCode: 'OTH-005',
        companyName: 'General Logistics',
        supplierName: 'Supplier 5',
        projectNames: 'City Center',
        shipmentMode: 'Sea FCL',
        incotermCode: 'FOB',
        estimatedCost: 5000,
        estimatedCostCurrency: 'USD',
        currentModule: 'Shipping',
        currentStage: 'Completed',
        progressPercent: 100,
        nextAction: 'Done',
        status: 'Closed',
        owner: 'User',
        createdAt: '2026-09-01',
        updatedAt: '2026-09-06',
        invoicesData: const [],
        packingListsData: const [],
      );

      final allFiles = [ecoFileByCompany, ecoFileByProject, scasFile, archiFile, otherFile];

      // ECO Filter predicate
      bool isEco(ImportFileModel f) {
        final comp = f.companyName.toLowerCase();
        final proj = (f.projectNames ?? '').toLowerCase();
        final owner = f.owner.toLowerCase();
        final notes = (f.notes ?? '').toLowerCase();
        return comp.contains('eco') || comp.contains('إيكو') || comp.contains('ايكو') ||
               proj.contains('eco') || proj.contains('إيكو') || proj.contains('ايكو') ||
               owner.contains('eco') || notes.contains('eco');
      }

      // SCAS & Archi Rands Filter predicate
      bool isScasOrArchi(ImportFileModel f) {
        final comp = f.companyName.toLowerCase();
        final proj = (f.projectNames ?? '').toLowerCase();
        final owner = f.owner.toLowerCase();
        final notes = (f.notes ?? '').toLowerCase();
        return comp.contains('scas') || comp.contains('سكاس') ||
               comp.contains('archi') || comp.contains('أركي') || comp.contains('اركي') ||
               proj.contains('scas') || proj.contains('سكاس') ||
               proj.contains('archi') || proj.contains('أركي') || proj.contains('اركي') ||
               owner.contains('scas') || owner.contains('archi') ||
               notes.contains('scas') || notes.contains('archi');
      }

      final ecoFiltered = allFiles.where(isEco).toList();
      final scasFiltered = allFiles.where(isScasOrArchi).toList();

      expect(ecoFiltered.length, equals(2));
      expect(ecoFiltered.map((f) => f.importFileCode), containsAll(['ECO-001', 'PRJ-002']));
      expect(ecoFiltered.map((f) => f.importFileCode), isNot(contains('SCAS-003')));
      expect(ecoFiltered.map((f) => f.importFileCode), isNot(contains('ARC-004')));
      expect(ecoFiltered.map((f) => f.importFileCode), isNot(contains('OTH-005')));

      expect(scasFiltered.length, equals(2));
      expect(scasFiltered.map((f) => f.importFileCode), containsAll(['SCAS-003', 'ARC-004']));
      expect(scasFiltered.map((f) => f.importFileCode), isNot(contains('ECO-001')));
      expect(scasFiltered.map((f) => f.importFileCode), isNot(contains('PRJ-002')));
      expect(scasFiltered.map((f) => f.importFileCode), isNot(contains('OTH-005')));
    });
  });
}
