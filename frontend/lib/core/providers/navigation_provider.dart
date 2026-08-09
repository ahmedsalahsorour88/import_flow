import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/audit_logs/providers/audit_logs_provider.dart';
import '../../features/cbm_calculator/providers/cbm_calculator_provider.dart';
import '../../features/currencies/providers/currencies_provider.dart';
import '../../features/customs_clearance/providers/customs_clearance_provider.dart';
import '../../features/customs_tariff/providers/customs_tariff_provider.dart';
import '../../features/external_service_providers/providers/partners_provider.dart';
import '../../features/file_closure/providers/file_closure_provider.dart';
import '../../features/financial_settlement/providers/financial_settlement_provider.dart';
import '../../features/freight_booking/providers/freight_booking_provider.dart';
import '../../features/freight_quotations/providers/freight_quotations_provider.dart';
import '../../features/import_companies/providers/import_companies_provider.dart';
import '../../features/incoterms/providers/incoterms_provider.dart';
import '../../features/projects/providers/projects_provider.dart';
import '../../features/purchase_orders/providers/purchase_orders_provider.dart';
import '../../features/shipping_scenarios/providers/shipping_scenarios_provider.dart';
import '../../features/suppliers/providers/suppliers_provider.dart';
import '../../features/transport_locations/providers/transport_locations_provider.dart';
import '../../features/warehouse_receiving/providers/warehouse_receiving_provider.dart';

// ============================================================
// Navigation Index Provider
// ============================================================
// Screen indices (must match home_screen.dart _screens list):
//  0  = Dashboard (OperationalDashboardScreen)
//  1  = ImportFilesScreen
//  2  = PurchaseOrdersScreen
//  3  = CBMCalculatorScreen
//  4  = ShippingScenariosScreen
//  5  = FreightQuotationsScreen
//  6  = CustomsConsultationScreen
//  7  = FinancialApprovalScreen
//  8  = ImportDocumentationScreen
//  9  = FreightBookingScreen
//  10 = CargoShippingScreen
//  11 = ProjectsScreen
//  12 = ImportCompaniesScreen
//  13 = SuppliersScreen
//  14 = PartnersScreen (external_service_providers)
//  15 = AuditLogsScreen
//  16 = IncotermsScreen
//  17 = CustomsTariffScreen
//  18 = TransportLocationsScreen
//  19 = CurrenciesScreen
//  20 = CustomsClearanceScreen
//  21 = WarehouseReceivingScreen
//  22 = FinancialSettlementScreen
//  23 = FileClosureScreen
// ============================================================

const int _totalScreens = 24;

final navigationIndexProvider = StateProvider<int>((ref) => 13);

void selectNavigationIndex(WidgetRef ref, int index) {
  if (index < 0 || index >= _totalScreens) return;

  // 1. Update navigation state
  ref.read(navigationIndexProvider.notifier).state = index;

  // 2. Live-refresh the target screen's data from the server
  _liveRefreshScreenData(ref, index);
}

void _liveRefreshScreenData(WidgetRef ref, int index) {
  switch (index) {
    // --- Core Operations ---
    case 2:
      ref.read(purchaseOrdersProvider.notifier).fetchPurchaseOrders();
      break;
    case 3:
      ref.read(cbmCalculatorProvider.notifier).fetchCalculations();
      break;
    case 4:
      ref.read(shippingScenariosProvider.notifier).fetchSessions();
      break;
    case 5:
      ref.read(freightQuotationsProvider.notifier).fetchRFQs();
      break;

    // --- Operational Phases ---
    case 9:
      ref.read(freightBookingProvider.notifier).fetchBookings();
      break;
    case 11:
      ref.read(projectsProvider.notifier).fetchProjects();
      break;

    // --- Customs & Clearance ---
    case 20:
      ref.read(customsClearanceProvider.notifier).fetchRecords();
      break;
    case 21:
      ref.read(warehouseReceivingProvider.notifier).fetchRecords();
      break;
    case 22:
      ref.read(financialSettlementProvider.notifier).fetchSettlements();
      break;
    case 23:
      ref.read(fileClosureProvider.notifier).fetchClosures();
      break;

    // --- Master Data ---
    case 12:
      ref.read(importCompaniesProvider.notifier).fetchCompanies();
      break;
    case 13:
      ref.read(suppliersProvider.notifier).fetchSuppliers();
      break;
    case 14:
      ref.read(partnersProvider.notifier).fetchPartners();
      break;
    case 15:
      ref.invalidate(systemAuditLogsProvider);
      break;

    // --- Reference Data ---
    case 16:
      ref.read(incotermsProvider.notifier).fetchIncoterms();
      break;
    case 17:
      ref.read(customsTariffProvider.notifier).fetchTariffs();
      break;
    case 18:
      ref.read(transportLocationsProvider.notifier).fetchLocations();
      break;
    case 19:
      ref.read(currenciesProvider.notifier).fetchCurrencies();
      break;

    default:
      break;
  }
}
