import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../auth/providers/auth_provider.dart';
import '../audit_logs/screens/audit_logs_screen.dart';
import '../external_service_providers/screens/partners_screen.dart';
import '../import_companies/screens/import_companies_screen.dart';
import '../incoterms/screens/incoterms_screen.dart';
import '../customs_tariff/screens/customs_tariff_screen.dart';
import '../transport_locations/screens/transport_locations_screen.dart';
import '../currencies/screens/currencies_screen.dart';
import '../suppliers/screens/suppliers_screen.dart';
import '../../core/providers/navigation_provider.dart';
import '../projects/screens/projects_screen.dart';
import '../purchase_orders/screens/purchase_orders_screen.dart';
import '../cbm_calculator/screens/cbm_calculator_screen.dart';
import '../shipping_scenarios/screens/shipping_scenarios_screen.dart';
import '../customs_consultation/screens/customs_consultation_screen.dart';
import '../freight_quotations/screens/freight_quotations_screen.dart';
import '../financial_approval/screens/financial_approval_screen.dart';
import '../import_documentation/screens/import_documentation_screen.dart';
import '../import_files/screens/import_files_screen.dart';
import '../freight_booking/screens/freight_booking_screen.dart';
import '../cargo_shipping/screens/cargo_shipping_screen.dart';
import '../customs_clearance/screens/customs_clearance_screen.dart';
import '../operational_dashboard/screens/operational_dashboard_screen.dart';
import '../warehouse_receiving/screens/warehouse_receiving_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<Widget> get _screens => const [
        DashboardTab(),
        ImportFilesScreen(),
        PurchaseOrdersScreen(),
        CBMCalculatorScreen(),
        ShippingScenariosScreen(),
        FreightQuotationsScreen(),
        CustomsConsultationScreen(),
        FinancialApprovalScreen(),
        ImportDocumentationScreen(),
        FreightBookingScreen(),
        CargoShippingScreen(),
        ProjectsScreen(),
        ImportCompaniesScreen(),
        SuppliersScreen(),
        PartnersScreen(),
        AuditLogsScreen(),
        IncotermsScreen(),
        CustomsTariffScreen(),
        TransportLocationsScreen(),
        CurrenciesScreen(),
        CustomsClearanceScreen(),
        WarehouseReceivingScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(navigationIndexProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 275,
            color: AppTheme.charcoal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.cobalt,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.swap_calls_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ImportFlow ERP',
                                style: TextStyle(
                                  color: AppTheme.cloudWhite,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'إدارة الاستيراد والجمارك',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      // Section 1: Core Operations
                      _buildSectionHeader('📊 الرئيسية وأوامر الشراء'),
                      _buildMenuItem(Icons.dashboard_outlined, 'Dashboard (لوحة التحليلات)', 0, selectedIndex),
                      _buildMenuItem(Icons.folder_special_outlined, 'Import Files (ملفات الشحنات)', 1, selectedIndex),
                      _buildMenuItem(Icons.shopping_cart_outlined, 'Purchase Orders (أوامر الشراء)', 2, selectedIndex),
                      _buildMenuItem(Icons.calculate_outlined, 'CBM Calculator (حاسبة الأحجام)', 3, selectedIndex),

                      // Section 2: Phase 1 Shipping & Logistics Planning
                      _buildSectionHeader('🚀 مراحل التخطيط وشغور النولون'),
                      _buildMenuItem(Icons.alt_route, 'Shipping Scenarios (BP-007)', 4, selectedIndex),
                      _buildMenuItem(Icons.request_quote_outlined, 'Freight RFQ (BP-008)', 5, selectedIndex),
                      _buildMenuItem(Icons.gavel_outlined, 'Customs Broker (BP-009)', 6, selectedIndex),

                      // Section 3: Phases 2 - 5 Operations & Execution
                      _buildSectionHeader('⚡ المراحل الإجرائية والتخليص'),
                      _buildMenuItem(Icons.account_balance_wallet_outlined, 'Financial Approval (Phase 2)', 7, selectedIndex),
                      _buildMenuItem(Icons.verified_user_outlined, 'Import Docs & ACID (Phase 3)', 8, selectedIndex),
                      _buildMenuItem(Icons.directions_boat_outlined, 'Freight Booking (Phase 4)', 9, selectedIndex),
                      _buildMenuItem(Icons.local_shipping_outlined, 'Cargo & CargoX (Phase 5)', 10, selectedIndex),
                      _buildMenuItem(Icons.gavel_outlined, 'Customs Clearance (Phase 7)', 20, selectedIndex),
                      _buildMenuItem(Icons.inventory_outlined, 'Warehouse Receiving (Phase 8)', 21, selectedIndex),

                      // Section 4: Master Data
                      _buildSectionHeader('🏢 البيانات الأساسية للمؤسسة'),
                      _buildMenuItem(Icons.domain_outlined, 'Import Companies (شركات الاستيراد)', 12, selectedIndex),
                      _buildMenuItem(Icons.business_outlined, 'Suppliers (الموردون الخارجيون)', 13, selectedIndex),
                      _buildMenuItem(Icons.account_balance_outlined, 'Partners & Banks (البنوك والشركاء)', 14, selectedIndex),
                      _buildMenuItem(Icons.assignment_outlined, 'Projects (المشاريع والمراكز)', 11, selectedIndex),

                      // Section 5: Reference Data & Tariff Rules
                      _buildSectionHeader('⚙️ الجداول المرجعية والتعريفات'),
                      _buildMenuItem(Icons.handshake_outlined, 'Incoterms Rules (MD-006)', 16, selectedIndex),
                      _buildMenuItem(Icons.description_outlined, 'Customs Tariff (MD-008)', 17, selectedIndex),
                      _buildMenuItem(Icons.location_on_outlined, 'Ports & Locations (MD-009)', 18, selectedIndex),
                      _buildMenuItem(Icons.currency_exchange_outlined, 'Currencies & Rates (MD-004)', 19, selectedIndex),
                      _buildMenuItem(Icons.history_edu_outlined, 'System Audit Logs (سجل الأنشطة)', 15, selectedIndex),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),

                // User Profile & Role Switcher Footer (RBAC Demo)
                if (user != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.black.withOpacity(0.15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: _getRoleColor(user.role).withOpacity(0.2),
                              radius: 18,
                              child: Icon(Icons.person, color: _getRoleColor(user.role), size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.fullName,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: _getRoleColor(user.role).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      user.role,
                                      style: TextStyle(color: _getRoleColor(user.role), fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('Quick Role Switcher (RBAC):', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _buildRoleChip('MANAGER', 'Manager'),
                            const SizedBox(width: 4),
                            _buildRoleChip('OPERATOR', 'Operator'),
                            const SizedBox(width: 4),
                            _buildRoleChip('ADMIN', 'Admin'),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Main Content Area
          Expanded(
            child: _screens[selectedIndex < _screens.length ? selectedIndex : 0],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(String roleKey, String label) {
    final activeUser = ref.watch(authProvider).user;
    final isSelected = activeUser?.role == roleKey;

    return Expanded(
      child: InkWell(
        onTap: () {
          ref.read(authProvider.notifier).switchDemoRole(roleKey);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? _getRoleColor(roleKey) : Colors.white10,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return AppTheme.crimson;
      case 'MANAGER':
        return AppTheme.cobalt;
      case 'OPERATOR':
        return AppTheme.emerald;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Divider(color: Colors.white12, height: 1),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, int index, int selectedIndex) {
    final isSelected = selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.cobalt.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: isSelected
            ? const Border(left: BorderSide(color: AppTheme.cobalt, width: 4))
            : null,
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: Icon(
          icon,
          size: 20,
          color: isSelected ? AppTheme.cobalt : AppTheme.cloudWhite,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.cloudWhite,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12.5,
          ),
        ),
        selected: isSelected,
        onTap: () {
          selectNavigationIndex(ref, index);
        },
      ),
    );
  }
}
class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const OperationalDashboardScreen();
  }
}
