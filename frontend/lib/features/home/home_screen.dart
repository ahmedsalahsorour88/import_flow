import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../auth/providers/auth_provider.dart';
import '../audit_logs/screens/audit_logs_screen.dart';
import '../external_service_providers/screens/partners_screen.dart';
import '../import_companies/screens/import_companies_screen.dart';
import '../incoterms/screens/incoterms_screen.dart';
import '../customs_tariff/screens/customs_tariff_screen.dart';
import '../customs_tariff/screens/hs_code_search_screen.dart';
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
import '../financial_approval/screens/swift_reconciliation_screen.dart';
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
import '../import_requirements/screens/import_requirements_screen.dart';
import '../demurrage_detention/screens/demurrage_detention_screen.dart';
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

        // Index 30..37: Smart Engines, Demurrage, SWIFT Tracker & Comprehensive Report
        SmartTasksScreen(),
        DynamicReportBuilderScreen(),
        ShipmentUpdateEngineScreen(),
        ImportRequirementsScreen(),
        DemurrageDetentionScreen(),
        HsCodeSearchScreen(),
        SwiftReconciliationScreen(),
        ImportFileComprehensiveReportScreen(),
      ];

  String _searchQuery = '';

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
                // Logo & Header
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.cobalt,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.sync_alt, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ImportFlow ERP',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
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
                // Quick Search Bar in Sidebar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Container(
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: TextField(
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                      decoration: InputDecoration(
                        hintText: 'بحث سريع في الشاشات والمهام...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                        prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.5), size: 16),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.white54, size: 14),
                                onPressed: () => setState(() => _searchQuery = ''),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    children: [
                      // =========================================================
                      // HUB 1: المرحلة 1: الإعداد والبيانات الأساسية وملف الشحنة
                      // =========================================================
                      _buildHubTile(
                        icon: Icons.domain_outlined,
                        title: '1. الإعداد والبيانات الأساسية وملف الشحنة',
                        color: Colors.teal,
                        initiallyExpanded: true,
                        children: [
                          _buildMenuItem(Icons.domain_outlined, '🏢 الشركات المستوردة (Import Companies)', 22, selectedIndex),
                          _buildMenuItem(Icons.business_outlined, '🌍 الموردون الخارجيون والمحليون (Suppliers)', 23, selectedIndex),
                          _buildMenuItem(Icons.account_balance_outlined, '🏦 مقدمو الخدمات والشركاء والبنوك (Partners)', 24, selectedIndex),
                          _buildMenuItem(Icons.assignment_outlined, '📁 المشاريع ومراكز التكلفة (Projects)', 21, selectedIndex),
                          _buildMenuItem(Icons.folder_special_outlined, '📦 ملف الشحنة الاستيرادية (Import Files)', 1, selectedIndex),
                          _buildMenuItem(Icons.shopping_cart_outlined, '🛒 أوامر الشراء وبلد المنشأ (Purchase Orders)', 2, selectedIndex),
                        ],
                      ),

                      // =========================================================
                      // HUB 2: المرحلة 2: دراسات الشحن والجمارك (بالتوازي)
                      // =========================================================
                      _buildHubTile(
                        icon: Icons.alt_route_outlined,
                        title: '2. ⚡ دراسات الشحن والجمارك (بالتوازي)',
                        color: AppTheme.cobalt,
                        initiallyExpanded: true,
                        children: [
                          _buildSubSectionLabel('🚢 دراسات الشحن وسيناريوهات النولون:'),
                          _buildMenuItem(Icons.analytics_outlined, 'دراسة وسيناريوهات الشحن (Evaluator)', 4, selectedIndex),
                          _buildMenuItem(Icons.history_toggle_off_outlined, 'سجل دراسات الشحن المحفوظة (Saved Log)', 5, selectedIndex),

                          _buildSubSectionLabel('⚖️ استشارة المخلص وفحص الرسوم الجمركية:'),
                          _buildMenuItem(Icons.gavel_outlined, 'مركز الاستشارة والفحص الجمركي (Workspace)', 6, selectedIndex),
                          _buildMenuItem(Icons.history_outlined, 'سجل الاستشارات المحفوظة (Consultations Log)', 7, selectedIndex),
                        ],
                      ),

                      // =========================================================
                      // HUB 3: المرحلة 3: السداد + ACID + الإعفاءات (بالتوازي)
                      // =========================================================
                      _buildHubTile(
                        icon: Icons.sync_alt_outlined,
                        title: '3. ⚡ السداد + ACID + الإعفاءات (بالتوازي)',
                        color: AppTheme.orange,
                        initiallyExpanded: true,
                        children: [
                          _buildSubSectionLabel('💳 1. المسار المالي والميزانية والسويفت:'),
                          _buildMenuItem(Icons.payment_outlined, 'طلبات السداد المالي للمورد (Payment Requests)', 8, selectedIndex),
                          _buildMenuItem(Icons.account_balance, 'متابعة ومطابقة السويفت البنكي (SWIFT Tracker)', 36, selectedIndex),
                          _buildMenuItem(Icons.account_balance_wallet_outlined, 'اعتماد الميزانية الاستيرادية (Budget Approval)', 9, selectedIndex),
                          _buildMenuItem(Icons.receipt_long_outlined, 'سجل العمليات المالي والتسويات (Financial Registry)', 10, selectedIndex),

                          _buildSubSectionLabel('🏛️ 2. المسار الحكومي والتسجيل المسبق:'),
                          _buildMenuItem(Icons.qr_code_scanner_outlined, 'تسجيل نافذة وإصدار ACID (Nafeza Engine)', 11, selectedIndex),

                          _buildSubSectionLabel('📜 3. مراجعة المتطلبات وشهادات الإعفاء:'),
                          _buildMenuItem(Icons.rule_folder_outlined, 'مراجعة الاشتراطات وطلب الإعفاءات (Requirements)', 33, selectedIndex),
                        ],
                      ),

                      // =========================================================
                      // HUB 4: المرحلة 4: الحجز ومراجعة المسودات والدرافت والاعتماد
                      // =========================================================
                      _buildHubTile(
                        icon: Icons.directions_boat_outlined,
                        title: '4. 🔍 الحجز ومراجعة المسودات والدرافت',
                        color: AppTheme.emerald,
                        initiallyExpanded: true,
                        children: [
                          _buildMenuItem(Icons.directions_boat_outlined, 'حجز الشحنة وتحديد الناقل (Freight Booking)', 15, selectedIndex),
                          _buildMenuItem(Icons.local_shipping_outlined, 'تجهيز البضاعة ومتابعة التحميل في الميناء', 16, selectedIndex),
                          _buildMenuItem(Icons.folder_shared_outlined, 'مراجعة واعتماد درافت الأوراق (BL / Invoice / COO)', 13, selectedIndex),
                          _buildMenuItem(Icons.gavel_outlined, 'إعادة العرض على المخلص واعتماد الرسوم النهائية', 6, selectedIndex),
                        ],
                      ),

                      // =========================================================
                      // HUB 5: المرحلة 5: الإبحار ونموذج 4 والتخليص الجمركي
                      // =========================================================
                      _buildHubTile(
                        icon: Icons.gavel,
                        title: '5. 🚢 الإبحار ونموذج 4 والتخليص الجمركي',
                        color: Colors.indigo,
                        initiallyExpanded: true,
                        children: [
                          _buildMenuItem(Icons.account_balance_outlined, 'طلب إصدار وتوثيق نموذج 4 البنكي (Form 4)', 12, selectedIndex),
                          _buildMenuItem(Icons.schedule_outlined, 'تسجيل مواعيد السفر (ATD) والوصول (ETA) وتتبع CargoX', 16, selectedIndex),
                          _buildMenuItem(Icons.markunread_mailbox_outlined, 'استلام الأوراق والمستندات النهائية الأصلية', 13, selectedIndex),
                          _buildMenuItem(Icons.description_outlined, 'إجراءات الإقرار وإصدار الشهادة (Declaration 46)', 14, selectedIndex),
                          _buildMenuItem(Icons.find_in_page_outlined, 'متابعة التخليص اليومية والعروض الرقابية والمعملية', 17, selectedIndex),
                          _buildMenuItem(Icons.timer_outlined, 'غرامات وفترات السماح (Demurrage & Detention)', 34, selectedIndex),
                          _buildMenuItem(Icons.inventory_outlined, 'الإفراج النهائي واستلام المخزن وتوليد إذن (GRN)', 18, selectedIndex),
                        ],
                      ),

                      // =========================================================
                      // HUB 6: المرحلة 6: تسوية التكلفة وكشوف الحسابات والإغلاق
                      // =========================================================
                      _buildHubTile(
                        icon: Icons.calculate,
                        title: '6. 💵 تسوية التكلفة وكشوف الحسابات والإغلاق',
                        color: AppTheme.crimson,
                        initiallyExpanded: true,
                        children: [
                          _buildMenuItem(Icons.calculate, 'تسوية تكلفة الوصول حسب Incoterm (Landed Cost)', 19, selectedIndex),
                          _buildMenuItem(Icons.account_balance_wallet_outlined, 'كشوف حسابات مقدمي الخدمات بكل عملة (Partner SOA)', 24, selectedIndex),
                          _buildMenuItem(Icons.archive_outlined, 'المراجعة الختامية وإغلاق الملف الاستيرادي', 20, selectedIndex),
                        ],
                      ),

                      // =========================================================
                      // HUB 7: مركز القيادة والتحكم والأدوات والتقارير
                      // =========================================================
                      _buildHubTile(
                        icon: Icons.analytics_outlined,
                        title: '7. 📊 لوحة القيادة والتقارير والأدوات',
                        color: Colors.blueGrey,
                        initiallyExpanded: false,
                        children: [
                          _buildMenuItem(Icons.dashboard_customize_outlined, 'Dashboard (لوحة التحليلات والتحكم)', 0, selectedIndex),
                          _buildMenuItem(Icons.published_with_changes_outlined, 'Update Engine (محرك تحديث الشحنات)', 32, selectedIndex),
                          _buildMenuItem(Icons.summarize_outlined, 'تقرير الملف الشامل والمدمج (Master Report)', 37, selectedIndex),
                          _buildMenuItem(Icons.task_alt_outlined, 'Smart Tasks (المهام والتذكيرات الذكية)', 30, selectedIndex),
                          _buildMenuItem(Icons.assessment_outlined, 'Dynamic Reports (مُنشئ التقارير المخصصة)', 31, selectedIndex),
                          _buildMenuItem(Icons.calculate_outlined, 'حاسبة CBM والأوزان وتوزيع الحاويات', 3, selectedIndex),
                          _buildMenuItem(Icons.saved_search, 'مستكشف التعريفة الجمركية (HS Explorer)', 35, selectedIndex),
                          _buildMenuItem(Icons.description_outlined, 'Customs Tariff (جدول التعريفة MD-008)', 26, selectedIndex),
                          _buildMenuItem(Icons.handshake_outlined, 'Incoterms Rules (الشروط التجارية MD-006)', 25, selectedIndex),
                          _buildMenuItem(Icons.location_on_outlined, 'Ports & Locations (الموانئ والمواقع MD-009)', 27, selectedIndex),
                          _buildMenuItem(Icons.currency_exchange_outlined, 'Currencies & Rates (العملات MD-004)', 28, selectedIndex),
                          _buildMenuItem(Icons.history_edu_outlined, 'System Audit Logs (سجل الأنشطة والتدقيق)', 29, selectedIndex),
                        ],
                      ),
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

  Widget _buildHubTile({
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
    bool initiallyExpanded = false,
  }) {
    // If search query is active, auto expand all hubs
    final isSearching = _searchQuery.isNotEmpty;

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        hoverColor: Colors.white.withOpacity(0.04),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: ExpansionTile(
          key: isSearching ? UniqueKey() : null,
          initiallyExpanded: isSearching ? true : initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          childrenPadding: const EdgeInsets.only(bottom: 6),
          leading: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconColor: color,
          collapsedIconColor: Colors.white54,
          children: children,
        ),
      ),
    );
  }

  Widget _buildSubSectionLabel(String label) {
    if (_searchQuery.isNotEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 2),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.amber.shade300,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, int index, int selectedIndex) {
    // Search Filter Logic
    if (_searchQuery.isNotEmpty && !title.toLowerCase().contains(_searchQuery)) {
      return const SizedBox.shrink();
    }

    final isSelected = selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.cobalt.withOpacity(0.25) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: isSelected
            ? const Border(left: BorderSide(color: AppTheme.cobalt, width: 3.5))
            : null,
      ),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(horizontal: 0, vertical: -3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        leading: Icon(
          icon,
          size: 17,
          color: isSelected ? AppTheme.cobalt : AppTheme.cloudWhite.withOpacity(0.8),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.cloudWhite,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 11.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
