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

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final List<Widget> _screens = const [
    DashboardTab(),
    PurchaseOrdersScreen(),
    CBMCalculatorScreen(),
    ShippingScenariosScreen(),
    CustomsConsultationScreen(),
    ProjectsScreen(),
    ImportCompaniesScreen(),
    SuppliersScreen(),
    PartnersScreen(),
    AuditLogsScreen(),
    IncotermsScreen(),
    CustomsTariffScreen(),
    TransportLocationsScreen(),
    CurrenciesScreen(),
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
            width: 260,
            color: AppTheme.charcoal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'ImportFlow ERP',
                    style: TextStyle(
                      color: AppTheme.cloudWhite,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildMenuItem(Icons.dashboard, 'Dashboard', 0, selectedIndex),
                      _buildMenuItem(Icons.shopping_cart_outlined, 'Purchase Orders (أوامر الشراء)', 1, selectedIndex),
                      _buildMenuItem(Icons.calculate_outlined, 'CBM Calculator (حاسبة الأحجام)', 2, selectedIndex),
                      _buildMenuItem(Icons.alt_route, 'Shipping Scenarios (BP-007)', 3, selectedIndex),
                      _buildMenuItem(Icons.gavel, 'Customs Broker (BP-009)', 4, selectedIndex),
                      _buildMenuItem(Icons.assignment, 'Projects (المشاريع)', 5, selectedIndex),
                      _buildMenuItem(Icons.domain, 'Import Companies', 6, selectedIndex),
                      _buildMenuItem(Icons.business, 'Suppliers', 7, selectedIndex),
                      _buildMenuItem(Icons.account_balance, 'Partners & Banks', 8, selectedIndex),
                      _buildMenuItem(Icons.history_edu, 'System Audit Trail', 9, selectedIndex),
                      _buildMenuItem(Icons.handshake_outlined, 'Incoterms (MD-006)', 10, selectedIndex),
                      _buildMenuItem(Icons.calculate, 'Customs Tariff (MD-008)', 11, selectedIndex),
                      _buildMenuItem(Icons.directions_boat, 'Ports & Locations (MD-009)', 12, selectedIndex),
                      _buildMenuItem(Icons.currency_exchange, 'Currencies & Rates (MD-004)', 13, selectedIndex),
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
            child: IndexedStack(
              index: selectedIndex,
              children: _screens,
            ),
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

  Widget _buildMenuItem(IconData icon, String title, int index, int selectedIndex) {
    final isSelected = selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.cobalt : AppTheme.cloudWhite,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppTheme.cobalt : AppTheme.cloudWhite,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onTap: () {
        selectNavigationIndex(ref, index);
      },
    );
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Executive Overview',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.charcoal,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard('Active Shipments', '12', Icons.local_shipping, AppTheme.cobalt),
              const SizedBox(width: 16),
              _buildStatCard('Customs Clearance', '5 Pending', Icons.assignment, AppTheme.orange),
              const SizedBox(width: 16),
              _buildStatCard('Est. Landed Cost', '\$45,200', Icons.attach_money, AppTheme.emerald),
              const SizedBox(width: 16),
              _buildStatCard('Pending Documents', '3 Action Req.', Icons.description, AppTheme.crimson),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: AppTheme.cloudWhite,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.charcoal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(icon, color: color),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
