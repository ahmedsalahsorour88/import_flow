import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/audit_logs/providers/audit_logs_provider.dart';
import '../../features/cargo_shipping/providers/cargo_shipping_provider.dart';
import '../../features/cbm_calculator/providers/cbm_calculator_provider.dart';
import '../../features/currencies/providers/currencies_provider.dart';
import '../../features/customs_clearance/providers/customs_clearance_provider.dart';
import '../../features/customs_consultation/providers/customs_consultation_provider.dart';
import '../../features/customs_tariff/providers/customs_tariff_provider.dart';
import '../../features/demurrage_detention/providers/demurrage_provider.dart';
import '../../features/external_service_providers/providers/partners_provider.dart';
import '../../features/file_closure/providers/file_closure_provider.dart';
import '../../features/financial_approval/providers/financial_approval_provider.dart';
import '../../features/financial_settlement/providers/financial_settlement_provider.dart';
import '../../features/freight_booking/providers/freight_booking_provider.dart';
import '../../features/freight_quotations/providers/freight_quotations_provider.dart';
import '../../features/import_companies/providers/import_companies_provider.dart';
import '../../features/import_documentation/providers/import_documentation_provider.dart';
import '../../features/import_files/providers/import_files_provider.dart';
import '../../features/import_requirements/providers/import_requirements_provider.dart';
import '../../features/incoterms/providers/incoterms_provider.dart';
import '../../features/projects/providers/projects_provider.dart';
import '../../features/purchase_orders/providers/purchase_orders_provider.dart';
import '../../features/shipping_scenarios/providers/shipping_scenarios_provider.dart';
import '../../features/smart_tasks/providers/smart_tasks_provider.dart';
import '../../features/suppliers/providers/suppliers_provider.dart';
import '../../features/transport_locations/providers/transport_locations_provider.dart';
import '../../features/warehouse_receiving/providers/warehouse_receiving_provider.dart';

// ============================================================
// Navigation Index Provider
// ============================================================

// Screen indices (strictly matching home_screen.dart _screens list):
//  0  = OperationalDashboardScreen
//  1  = ImportFilesScreen
//  2  = PurchaseOrdersScreen
//  3  = CBMCalculatorScreen
//  4  = ShippingScenariosScreen (initialIndex: 0)
//  5  = ShippingScenariosScreen (initialIndex: 1)
//  6  = CustomsConsultationScreen (initialIndex: 0)
//  7  = CustomsConsultationScreen (initialIndex: 1)
//  8  = FinancialApprovalScreen (initialIndex: 0)
//  9  = FinancialApprovalScreen (initialIndex: 1)
//  10 = FinancialApprovalScreen (initialIndex: 2)
//  11..15 = NafezaAcidScreen (0..4)
//  16..17 = BankForm4Screen (0..1)
//  18..22 = ShipmentDraftDocsScreen (0..4)
//  23..24 = CustomsDeclaration46Screen (0..1)
//  25 = FreightBookingScreen
//  26 = CargoShippingScreen
//  27 = CustomsClearanceScreen
//  28 = WarehouseReceivingScreen
//  29 = FinancialSettlementScreen
//  30 = FileClosureScreen
//  31 = ProjectsScreen
//  32 = ImportCompaniesScreen
//  33 = SuppliersScreen
//  34 = PartnersScreen (external_service_providers)
//  35 = IncotermsScreen
//  36 = CustomsTariffScreen
//  37 = TransportLocationsScreen
//  38 = CurrenciesScreen
//  39 = AuditLogsScreen
//  40 = SmartTasksScreen
//  41 = DynamicReportBuilderScreen
//  42 = ShipmentUpdateEngineScreen
//  43 = ImportRequirementsScreen
//  44 = DemurrageDetentionScreen
//  45 = HsCodeSearchScreen
//  46 = SwiftReconciliationScreen
//  47 = ImportFileComprehensiveReportScreen
//  48 = LifecycleBoardScreen
//  49 = FreightQuotationsComparisonScreen
//  50 = LandedCostComparisonScreen
// ============================================================

const int _totalScreens = 60;

final navigationIndexProvider = StateProvider<int>((ref) => 0);

void selectNavigationIndex(WidgetRef ref, int index) {
  if (index < 0 || index >= _totalScreens) return;

  // 1. Update navigation state
  ref.read(navigationIndexProvider.notifier).state = index;

  // 2. Live-refresh the target screen's data from the server
  _liveRefreshScreenData(ref, index);
}

void _liveRefreshScreenData(WidgetRef ref, int index) {
  switch (index) {
    // --- Core Operations & Sourcing ---
    case 1:
      ref.read(importFilesProvider.notifier).fetchImportFiles();
      break;
    case 2:
      ref.read(purchaseOrdersProvider.notifier).fetchPurchaseOrders();
      break;
    case 3:
      ref.read(cbmCalculatorProvider.notifier).fetchCalculations();
      break;
    case 4:
    case 5:
      ref.read(shippingScenariosProvider.notifier).fetchSessions();
      break;
    case 6:
    case 7:
      ref.read(customsConsultationsProvider.notifier).fetchConsultations();
      break;

    // --- Financial Approvals ---
    case 8:
    case 9:
    case 10:
    case 46:
      ref.read(importBudgetsProvider.notifier).fetchImportBudgets();
      ref.read(paymentRequestsProvider.notifier).fetchPaymentRequests();
      break;

    // --- Import Documentation, ACID & Banking ---
    case 11:
    case 12:
    case 13:
    case 14:
    case 15:
    case 16:
    case 17:
    case 18:
    case 19:
    case 20:
    case 21:
    case 22:
    case 23:
    case 24:
      ref.read(acidSessionsProvider.notifier).fetchAcidSessions();
      break;

    // --- Operational Phases ---
    case 25:
      ref.read(freightBookingProvider.notifier).fetchBookings();
      break;
    case 26:
      ref.read(cargoShippingProvider.notifier).fetchRecords();
      break;
    case 27:
      ref.read(customsClearanceProvider.notifier).fetchRecords();
      break;
    case 28:
      ref.read(warehouseReceivingProvider.notifier).fetchRecords();
      break;
    case 29:
    case 50:
      ref.read(financialSettlementProvider.notifier).fetchSettlements();
      break;
    case 30:
      ref.read(fileClosureProvider.notifier).fetchClosures();
      break;

    // --- Master Data ---
    case 31:
      ref.read(projectsProvider.notifier).fetchProjects();
      break;
    case 32:
      ref.read(importCompaniesProvider.notifier).fetchCompanies();
      break;
    case 33:
      ref.read(suppliersProvider.notifier).fetchSuppliers();
      break;
    case 34:
      ref.read(partnersProvider.notifier).fetchPartners();
      break;
    case 35:
      ref.read(incotermsProvider.notifier).fetchIncoterms();
      break;
    case 36:
    case 45:
      ref.read(customsTariffProvider.notifier).fetchTariffs();
      break;
    case 37:
      ref.read(transportLocationsProvider.notifier).fetchLocations();
      break;
    case 38:
      ref.read(currenciesProvider.notifier).fetchCurrencies();
      break;
    case 39:
      ref.invalidate(systemAuditLogsProvider);
      break;

    // --- Smart Engines & Reporting ---
    case 40:
      ref.read(smartTasksProvider.notifier).fetchTasks();
      break;
    case 43:
      ref.read(importRequirementsProvider.notifier).refreshData();
      break;
    case 44:
      ref.read(demurrageProvider.notifier).loadInitialData();
      break;
    case 49:
      ref.read(freightQuotationsProvider.notifier).fetchRFQs();
      break;

    default:
      break;
  }
}

