import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/audit_logs/providers/audit_logs_provider.dart';
import '../../features/cbm_calculator/providers/cbm_calculator_provider.dart';
import '../../features/currencies/providers/currencies_provider.dart';
import '../../features/customs_tariff/providers/customs_tariff_provider.dart';
import '../../features/external_service_providers/providers/partners_provider.dart';
import '../../features/import_companies/providers/import_companies_provider.dart';
import '../../features/incoterms/providers/incoterms_provider.dart';
import '../../features/projects/providers/projects_provider.dart';
import '../../features/purchase_orders/providers/purchase_orders_provider.dart';
import '../../features/suppliers/providers/suppliers_provider.dart';
import '../../features/transport_locations/providers/transport_locations_provider.dart';

// Navigation slugs matching screen indices
final List<String> navSlugs = [
  'dashboard',
  'purchase-orders',
  'cbm-calculator',
  'projects',
  'companies',
  'suppliers',
  'partners',
  'audit',
  'incoterms',
  'customs-tariff',
  'locations',
  'currencies',
];

int _getInitialIndexFromHash() {
  try {
    final fragment = Uri.base.fragment
        .replaceAll('/', '')
        .replaceAll('#', '')
        .trim()
        .toLowerCase();
    if (fragment.isNotEmpty) {
      final index = navSlugs.indexOf(fragment);
      if (index != -1) return index;
    }
  } catch (_) {}
  return 0; // Default to Dashboard
}

final navigationIndexProvider = StateProvider<int>((ref) => _getInitialIndexFromHash());

void selectNavigationIndex(WidgetRef ref, int index) {
  if (index < 0 || index >= navSlugs.length) return;

  // 1. Update State
  ref.read(navigationIndexProvider.notifier).state = index;

  // 2. Live Auto-Refresh / Mount Live Data Fetch for target screen
  _liveRefreshScreenData(ref, index);
}

void _liveRefreshScreenData(WidgetRef ref, int index) {
  switch (index) {
    case 1:
      ref.read(purchaseOrdersProvider.notifier).fetchPurchaseOrders();
      break;
    case 2:
      ref.read(cbmCalculatorProvider.notifier).fetchCalculations();
      break;
    case 3:
      ref.read(projectsProvider.notifier).fetchProjects();
      break;
    case 4:
      ref.read(importCompaniesProvider.notifier).fetchCompanies();
      break;
    case 5:
      ref.read(suppliersProvider.notifier).fetchSuppliers();
      break;
    case 6:
      ref.read(partnersProvider.notifier).fetchPartners();
      break;
    case 7:
      ref.invalidate(systemAuditLogsProvider);
      break;
    case 8:
      ref.read(incotermsProvider.notifier).fetchIncoterms();
      break;
    case 9:
      ref.read(customsTariffProvider.notifier).fetchTariffs();
      break;
    case 10:
      ref.read(transportLocationsProvider.notifier).fetchLocations();
      break;
    case 11:
      ref.read(currenciesProvider.notifier).fetchCurrencies();
      break;
    default:
      break;
  }
}
