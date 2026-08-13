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
import '../financial_approval/screens/financial_approval_screen.dart';
import '../import_documentation/screens/import_documentation_screen.dart';
import '../import_files/screens/import_files_screen.dart';
import '../freight_booking/screens/freight_booking_screen.dart';
import '../cargo_shipping/screens/cargo_shipping_screen.dart';
import '../customs_clearance/screens/customs_clearance_screen.dart';
import '../warehouse_receiving/screens/warehouse_receiving_screen.dart';
import '../financial_settlement/screens/financial_settlement_screen.dart';
import '../file_closure/screens/file_closure_screen.dart';
import '../operational_dashboard/screens/operational_dashboard_screen.dart';
import '../smart_tasks/screens/smart_tasks_screen.dart';
import '../dynamic_reporting/screens/dynamic_report_builder_screen.dart';
import '../shipment_updates/screens/shipment_update_engine_screen.dart';
import '../comprehensive_report/screens/import_file_comprehensive_report_screen.dart';
import '../notifications/widgets/notification_bell_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<Widget> get _screens => const [
        // Index 0..3: Core Workspace
        OperationalDashboardScreen(),
        ImportFilesScreen(),
        PurchaseOrdersScreen(),
        CBMCalculatorScreen(),

        // Index 4..5: Phase 1 Shipping Scenarios (Separated Pages)
        ShippingScenariosScreen(initialIndex: 0),
        ShippingScenariosScreen(initialIndex: 1),

        // Index 6..7: Phase 1 Customs Broker Consultation (Separated Pages)
        CustomsConsultationScreen(initialIndex: 0),
        CustomsConsultationScreen(initialIndex: 1),

        // Index 8..10: Phase 2 Financial Approvals (Separated Pages)
        FinancialApprovalScreen(initialIndex: 0),
        FinancialApprovalScreen(initialIndex: 1),
        FinancialApprovalScreen(initialIndex: 2),

        // Index 11..14: Phase 3 Documentation & Nafeza (Separated Pages)
        ImportDocumentationScreen(initialIndex: 0),
        ImportDocumentationScreen(initialIndex: 1),
        ImportDocumentationScreen(initialIndex: 2),
        ImportDocumentationScreen(initialIndex: 3),

        // Index 15..20: Phases 4 -> 10 Execution
        FreightBookingScreen(),
        CargoShippingScreen(),
        CustomsClearanceScreen(),
        WarehouseReceivingScreen(),
        FinancialSettlementScreen(),
        FileClosureScreen(),

        // Index 21..24: Master Data
        ProjectsScreen(),
        ImportCompaniesScreen(),
        SuppliersScreen(),
        PartnersScreen(),

        // Index 25..29: References & Audit
        IncotermsScreen(),
        CustomsTariffScreen(),
        TransportLocationsScreen(),
        CurrenciesScreen(),
        AuditLogsScreen(),

        // Index 30..33: Smart Tasks, Dynamic Reporting, Update Engine & Comprehensive Report
        SmartTasksScreen(),
        DynamicReportBuilderScreen(),
        ShipmentUpdateEngineScreen(),
        ImportFileComprehensiveReportScreen(),
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
                // Logo & Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.cobalt,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.sync_alt, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ImportFlow ERP',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            'إدارة الاستيراد والجمارك',
                            style: TextStyle(color: Colors.white54, fontSize: 10),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const NotificationBellWidget(),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      // Section 1: Dashboard & Workspace
                      _buildSectionHeader('📊 لوحة التحكم ومتابعة الشحنات'),
                      _buildMenuItem(Icons.dashboard_customize_outlined, 'Dashboard (لوحة التحليلات والتحكم)', 0, selectedIndex),
                      _buildMenuItem(Icons.published_with_changes_outlined, 'Update Engine (محرك تحديث الشحنات)', 32, selectedIndex),
                      _buildMenuItem(Icons.summarize_outlined, 'تقرير الملف الشامل والمدمج', 33, selectedIndex),
                      _buildMenuItem(Icons.task_alt_outlined, 'Smart Tasks (المهام والتذكيرات 2.4/2.5)', 30, selectedIndex),
                      _buildMenuItem(Icons.assessment_outlined, 'Dynamic Reports (مُنشئ التقارير 2.7)', 31, selectedIndex),
                      _buildMenuItem(Icons.folder_special_outlined, 'Import Files (ملفات الشحنات النشطة)', 1, selectedIndex),
                      _buildMenuItem(Icons.shopping_cart_outlined, 'Purchase Orders (أوامر الشراء)', 2, selectedIndex),
                      _buildMenuItem(Icons.calculate_outlined, 'CBM Calculator (حاسبة الأوزان والأحجام)', 3, selectedIndex),

                      // Section 2: Phase 1 Shipping & Logistics Scenarios (منفصلة)
                      _buildSectionHeader('🚀 Phase 1: سيناريوهات الشحن وعروض الأسعار'),
                      _buildMenuItem(Icons.analytics_outlined, 'دراسة وسيناريوهات الشحن (Evaluator)', 4, selectedIndex),
                      _buildMenuItem(Icons.history_toggle_off_outlined, 'سجل الدراسات المحفوظة (Saved Log)', 5, selectedIndex),

                      // Section 3: Phase 1 Customs Broker Consultations (منفصلة)
                      _buildSectionHeader('⚖️ Phase 1: استشارة المخلص الجمركي'),
                      _buildMenuItem(Icons.gavel_outlined, 'مركز الاستشارة والفحص الجمركي (Workspace)', 6, selectedIndex),
                      _buildMenuItem(Icons.history_outlined, 'سجل الاستشارات المحفوظة (Consultations Log)', 7, selectedIndex),

                      // Section 4: Phase 2 Financial Approvals (منفصلة)
                      _buildSectionHeader('💳 Phase 2: الموافقة والاعتماد المالي'),
                      _buildMenuItem(Icons.payment_outlined, 'طلبات السداد المالي (Payment Requests BP-012)', 8, selectedIndex),
                      _buildMenuItem(Icons.account_balance_wallet_outlined, 'اعتماد الميزانية الاستيرادية (Budget BP-013)', 9, selectedIndex),
                      _buildMenuItem(Icons.receipt_long_outlined, 'سجل العمليات المالي والتسويات (Financial Registry)', 10, selectedIndex),

                      // Section 5: Phase 3 Import Documentation & Nafeza (منفصلة)
                      _buildSectionHeader('📝 Phase 3: المستندات والتسجيل الحكومي'),
                      _buildMenuItem(Icons.qr_code_scanner_outlined, 'تسجيل نافذة ACID & Nafeza (BP-014)', 11, selectedIndex),
                      _buildMenuItem(Icons.account_balance_outlined, 'المستندات البنكية نموذج 4 (Form 4 BP-015)', 12, selectedIndex),
                      _buildMenuItem(Icons.folder_shared_outlined, 'مستندات الشحن وتتبع CargoX (BP-016)', 13, selectedIndex),
                      _buildMenuItem(Icons.description_outlined, 'إقرار 46 جمارك والشهادة (Declaration 46 BP-019)', 14, selectedIndex),

                      // Section 6: Phases 4 -> 10 Execution
                      _buildSectionHeader('⚡ Phases 4 → 10: التنفيذ والإفراج الجمركي'),
                      _buildMenuItem(Icons.directions_boat_outlined, 'Phase 4: حجز الشحن وتحديد الناقل', 15, selectedIndex),
                      _buildMenuItem(Icons.local_shipping_outlined, 'Phase 5: تجهيز البضاعة وتتبع CargoX', 16, selectedIndex),
                      _buildMenuItem(Icons.gavel, 'Phase 6-7: الإقرار والمعاينة والتخليص', 17, selectedIndex),
                      _buildMenuItem(Icons.inventory_outlined, 'Phase 8: استلام المخازن وتوليد GRN', 18, selectedIndex),
                      _buildMenuItem(Icons.calculate, 'Phase 9: تسوية تكلفة الوصول Landed Cost', 19, selectedIndex),
                      _buildMenuItem(Icons.archive_outlined, 'Phase 10: إغلاق الملف والأرشفة التاريخية', 20, selectedIndex),

                      // Section 7: Master Data
                      _buildSectionHeader('🏢 البيانات الأساسية (Master Data)'),
                      _buildMenuItem(Icons.assignment_outlined, 'Projects (المشاريع ومراكز التكلفة)', 21, selectedIndex),
                      _buildMenuItem(Icons.domain_outlined, 'Import Companies (الشركات المستوردة)', 22, selectedIndex),
                      _buildMenuItem(Icons.business_outlined, 'Suppliers (الموردون الخارجيون)', 23, selectedIndex),
                      _buildMenuItem(Icons.account_balance_outlined, 'Partners & Banks (البنوك والشركاء)', 24, selectedIndex),

                      // Section 8: Reference Rules & Audit
                      _buildSectionHeader('⚙️ الجداول المرجعية وتدقيق النظام'),
                      _buildMenuItem(Icons.handshake_outlined, 'Incoterms Rules (الشروط التجارية MD-006)', 25, selectedIndex),
                      _buildMenuItem(Icons.description_outlined, 'Customs Tariff (جدول التعريفة MD-008)', 26, selectedIndex),
                      _buildMenuItem(Icons.location_on_outlined, 'Ports & Locations (الموانئ والمواقع MD-009)', 27, selectedIndex),
                      _buildMenuItem(Icons.currency_exchange_outlined, 'Currencies & Rates (العملات MD-004)', 28, selectedIndex),
                      _buildMenuItem(Icons.history_edu_outlined, 'System Audit Logs (سجل الأنشطة)', 29, selectedIndex),
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
class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 550),
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.dashboard_customize_outlined, size: 48, color: AppTheme.orange),
              ),
              const SizedBox(height: 20),
              const Text(
                'لوحة التحكم الإحصائية معطلة مؤقتاً',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
              ),
              const SizedBox(height: 10),
              const Text(
                'تم تعطيل الشاشة الرئيسية مؤقتاً بناءً على طلبك لحين الانتهاء من تصميم وتجهيز كافة موديولات وواجهات النظام بالكامل.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  selectNavigationIndex(ref, 13); // Go to Foreign Suppliers
                },
                icon: const Icon(Icons.people_alt_outlined, size: 18),
                label: const Text('الانتقال لدليل الموردين الخارجيين (MD-002)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cobalt,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
