import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/navigation_provider.dart';
import '../../core/theme/app_theme.dart';
import '../audit_logs/screens/audit_logs_screen.dart';
import '../auth/providers/auth_provider.dart';
import '../cargo_shipping/screens/cargo_shipping_screen.dart';
import '../cbm_calculator/screens/cbm_calculator_screen.dart';
import '../comprehensive_report/screens/import_file_comprehensive_report_screen.dart';
import '../currencies/screens/currencies_screen.dart';
import '../customs_clearance/screens/customs_clearance_screen.dart';
import '../customs_consultation/screens/customs_consultation_screen.dart';
import '../customs_tariff/screens/customs_tariff_screen.dart';
import '../customs_tariff/screens/hs_code_search_screen.dart';
import '../demurrage_detention/screens/demurrage_detention_screen.dart';
import '../dynamic_reporting/screens/dynamic_report_builder_screen.dart';
import '../external_service_providers/screens/partners_screen.dart';
import '../file_closure/screens/file_closure_screen.dart';
import '../financial_approval/screens/financial_approval_screen.dart';
import '../financial_approval/screens/swift_reconciliation_screen.dart';
import '../financial_settlement/screens/financial_settlement_screen.dart';
import '../freight_booking/screens/freight_booking_screen.dart';
import '../import_companies/screens/import_companies_screen.dart';
import '../import_documentation/screens/bank_form4_screen.dart';
import '../import_documentation/screens/customs_declaration46_screen.dart';
import '../import_documentation/screens/nafeza_acid_screen.dart';
import '../import_documentation/screens/shipment_draft_docs_screen.dart';
import '../import_files/screens/import_files_screen.dart';
import '../import_requirements/screens/import_requirements_screen.dart';
import '../incoterms/screens/incoterms_screen.dart';
import '../notifications/widgets/notification_bell_widget.dart';
import '../operational_dashboard/screens/operational_dashboard_screen.dart';
import '../projects/screens/projects_screen.dart';
import '../lifecycle_board/screens/lifecycle_board_screen.dart';
import '../purchase_orders/screens/purchase_orders_screen.dart';
import '../shipment_updates/screens/shipment_update_engine_screen.dart';
import '../shipping_scenarios/screens/shipping_scenarios_screen.dart';
import '../smart_tasks/screens/smart_tasks_screen.dart';
import '../suppliers/screens/suppliers_screen.dart';
import '../transport_locations/screens/transport_locations_screen.dart';
import '../warehouse_receiving/screens/warehouse_receiving_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<Widget> get _screens => const [
        // 0..3: Core Workspace (Phase 1)
        OperationalDashboardScreen(),
        ImportFilesScreen(),
        PurchaseOrdersScreen(),
        CBMCalculatorScreen(),

        // 4..5: Phase 1 Shipping Scenarios
        ShippingScenariosScreen(initialIndex: 0),
        ShippingScenariosScreen(initialIndex: 1),

        // 6..7: Phase 1 Customs Broker Consultation
        CustomsConsultationScreen(initialIndex: 0),
        CustomsConsultationScreen(initialIndex: 1),

        // 8..10: Phase 2 Financial Approvals
        FinancialApprovalScreen(initialIndex: 0),
        FinancialApprovalScreen(initialIndex: 1),
        FinancialApprovalScreen(initialIndex: 2),

        // 11..15: Phase 3 Nafeza & ACID Engine (Dedicated Screen with Vertical Tabs)
        NafezaAcidScreen(initialSubTab: 0),
        NafezaAcidScreen(initialSubTab: 1),
        NafezaAcidScreen(initialSubTab: 2),
        NafezaAcidScreen(initialSubTab: 3),
        NafezaAcidScreen(initialSubTab: 4),

        // 16..17: Bank Form 4 & Endorsement (Dedicated Screen with Vertical Tabs)
        BankForm4Screen(initialSubTab: 0),
        BankForm4Screen(initialSubTab: 1),

        // 18..22: Phase 5 Shipment Draft Documents & CargoX Review (Dedicated Screen with Vertical Tabs)
        ShipmentDraftDocsScreen(initialSubTab: 0),
        ShipmentDraftDocsScreen(initialSubTab: 1),
        ShipmentDraftDocsScreen(initialSubTab: 2),
        ShipmentDraftDocsScreen(initialSubTab: 3),
        ShipmentDraftDocsScreen(initialSubTab: 4),

        // 23..24: Phase 6 Customs Declaration 46 (Dedicated Screen with Vertical Tabs)
        CustomsDeclaration46Screen(initialSubTab: 0),
        CustomsDeclaration46Screen(initialSubTab: 1),

        // 25..30: Execution Phases (Phases 4 -> 10)
        FreightBookingScreen(),
        CargoShippingScreen(),
        CustomsClearanceScreen(),
        WarehouseReceivingScreen(),
        FinancialSettlementScreen(),
        FileClosureScreen(),

        // 31..34: Master Data
        ProjectsScreen(),
        ImportCompaniesScreen(),
        SuppliersScreen(),
        PartnersScreen(),

        // 35..39: Reference Master Tables & Audit
        IncotermsScreen(),
        CustomsTariffScreen(),
        TransportLocationsScreen(),
        CurrenciesScreen(),
        AuditLogsScreen(),

        // 40..47: Smart Engines & Reporting
        SmartTasksScreen(),
        DynamicReportBuilderScreen(),
        ShipmentUpdateEngineScreen(),
        ImportRequirementsScreen(),
        DemurrageDetentionScreen(),
        HsCodeSearchScreen(),
        SwiftReconciliationScreen(),
        ImportFileComprehensiveReportScreen(),

        // 48: Native 6-Phase Lifecycle Operations Board
        LifecycleBoardScreen(),
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
          // Compact Professional Sidebar
          Container(
            width: 235,
            color: AppTheme.charcoal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo & Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppTheme.cobalt,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.sync_alt, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 8),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ImportFlow ERP',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            'إدارة الاستيراد والتخليص الجمركي',
                            style: TextStyle(color: Colors.white54, fontSize: 9),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Container(
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: TextField(
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                      onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                      decoration: InputDecoration(
                        hintText: 'بحث سريع / Search...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
                        prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.5), size: 14),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.white54, size: 12),
                                onPressed: () => setState(() => _searchQuery = ''),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 6),
                      ),
                    ),
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),

                // Navigation Hubs List (Organized strictly according to Shipment Workflow & Stages)
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    children: [
                      // =========================================================
                      // HUB 1: MASTER DATA & REGISTRIES (البيانات والجداول الأساسية)
                      // =========================================================
                      _buildHubTile(
                        icon: Icons.storage_outlined,
                        titleEn: 'Master Data & Tables',
                        titleAr: 'البيانات والجداول الأساسية',
                        color: Colors.teal,
                        initiallyExpanded: false,
                        children: [
                          _buildMenuItem(Icons.domain_outlined, 'Import Companies', 'الشركات المستوردة', 32, selectedIndex),
                          _buildMenuItem(Icons.business_outlined, 'Foreign Suppliers', 'دليل الموردين الأجانب', 33, selectedIndex),
                          _buildMenuItem(Icons.account_balance_outlined, 'Partners & Banks', 'الشركاء والبنوك ومقدمو الخدمات', 34, selectedIndex),
                          _buildMenuItem(Icons.assignment_outlined, 'Projects & Cost Centers', 'المشاريع ومراكز التكلفة', 31, selectedIndex),
                          _buildMenuItem(Icons.location_on_outlined, 'Ports & Locations', 'الموانئ والمنافذ الجمركية', 37, selectedIndex),
                          _buildMenuItem(Icons.handshake_outlined, 'Incoterms Rules', 'الشروط التجارية الدولية', 35, selectedIndex),
                          _buildMenuItem(Icons.description_outlined, 'Customs Tariff Schedule', 'جدول التعريفة الجمركية', 36, selectedIndex),
                          _buildMenuItem(Icons.currency_exchange_outlined, 'Currencies & Rates', 'العملات وأسعار الصرف', 38, selectedIndex),
                        ],
                      ),

                      // =========================================================
                      // HUB 2: SHIPMENT PLANNING & SOURCING (ملفات وأوامر الشراء)
                      // =========================================================
                      _buildHubTile(
                        icon: Icons.folder_special_outlined,
                        titleEn: 'Shipment Planning',
                        titleAr: 'تخطيط الشحنة وأوامر الشراء',
                        color: Colors.cyan,
                        initiallyExpanded: false,
                        children: [
                          _buildMenuItem(Icons.folder_special_outlined, 'Import Files', 'ملفات الشحنات الاستيرادية', 1, selectedIndex),
                          _buildMenuItem(Icons.shopping_cart_outlined, 'Purchase Orders & Origin', 'أوامر الشراء وإثبات المنشأ', 2, selectedIndex),
                          _buildMenuItem(Icons.calculate_outlined, 'CBM & Container Loading', 'حاسبة الأحجام وتوزيع الحاويات', 3, selectedIndex),
                        ],
                      ),

                      // =========================================================
                      // PHASE 1: PRE-PLANNING & STUDIES (التخطيط والدراسات المسبقة)
                      // =========================================================
                      _buildHubTile(
                        icon: Icons.analytics_outlined,
                        titleEn: '1. Pre-Planning & Studies',
                        titleAr: 'المرحلة 1: التخطيط والدراسات المسبقة',
                        color: Colors.amber.shade800,
                        initiallyExpanded: true,
                        children: [
                          _buildMenuItem(Icons.analytics_outlined, 'Freight Studies', 'دراسات ومفاضلة نولون الشحن', 4, selectedIndex),
                          _buildMenuItem(Icons.gavel_outlined, 'Customs Studies', 'الدراسات والاستشارات الجمركية', 6, selectedIndex),
                          _buildMenuItem(Icons.rule_folder_outlined, 'Regulatory Requirements', 'متطلبات واشتراطات الاستيراد للشحنة', 43, selectedIndex),
                        ],
                      ),

                      // =========================================================
                      // PHASE 2: SHIPMENT INITIATION & REGISTRATION (بداية الشحنة)
                      // =========================================================
                      _buildHubTile(
                        icon: Icons.qr_code_scanner_outlined,
                        titleEn: '2. Shipment Initiation',
                        titleAr: 'المرحلة 2: بداية الشحنة والتسجيل المسبق',
                        color: AppTheme.cobalt,
                        initiallyExpanded: false,
                        children: [
                          _buildMenuItem(Icons.payment_outlined, 'Finance Approvals & Budget', 'اعتمادات الميزانية وسداد الموردين', 8, selectedIndex),
                          _buildMenuItem(Icons.qr_code_scanner_outlined, 'ACID Operations', 'الرقم التعريفي المبدئي ACID', 11, selectedIndex),
                        ],
                      ),

                      // =========================================================
                      // PHASE 3: FREIGHT BOOKING & DOC PREPARATION (حجز الشحن والتدقيق المستندي)
                      // =========================================================
                      _buildHubTile(
                        icon: Icons.directions_boat_outlined,
                        titleEn: '3. Booking & Doc Prep',
                        titleAr: 'المرحلة 3: حجز الشحن والتدقيق المستندي',
                        color: AppTheme.emerald,
                        initiallyExpanded: false,
                        children: [
                          _buildMenuItem(Icons.directions_boat_outlined, 'Freight Booking', 'حجز النولون وتأكيد الخط الملاحي', 25, selectedIndex),
                          _buildMenuItem(Icons.local_shipping_outlined, 'Freight Allocations', 'تخصيص وتوزيع الحاويات والبضائع', 26, selectedIndex),
                          _buildMenuItem(Icons.assignment_turned_in_outlined, 'Draft Docs Review', 'مراجعة وتدقيق مسودات الشحن', 19, selectedIndex),
                          _buildMenuItem(Icons.verified_outlined, 'Docs Customs Approval', 'الاعتماد الجمركي النهائي للمستندات', 18, selectedIndex),
                        ],
                      ),

                      // =========================================================
                      // PHASE 4: DIGITAL PROCESSING & BANKING (التوثيق الرقمي والاعتماد البنكي)
                      // =========================================================
                      _buildHubTile(
                        icon: Icons.account_balance_outlined,
                        titleEn: '4. Digital & Banking',
                        titleAr: 'المرحلة 4: التوثيق الرقمي والاعتماد البنكي',
                        color: AppTheme.orange,
                        initiallyExpanded: false,
                        children: [
                          _buildMenuItem(Icons.cloud_upload_outlined, 'CargoX Follow-up / Upload', 'متابعة ورفع المستندات عبر CargoX', 22, selectedIndex),
                          _buildMenuItem(Icons.markunread_mailbox_outlined, 'Original Docs Collection', 'استلام وتدقيق أصول مستندات الشحن', 20, selectedIndex),
                          _buildMenuItem(Icons.account_balance_outlined, 'Bank Form 4', 'نموذج 4 والمطابقة والتوثيق البنكي', 16, selectedIndex),
                        ],
                      ),

                      // =========================================================
                      // PHASE 5: PORT OPERATIONS & CLEARANCE (التخليص الجمركي وإدارة الميناء)
                      // =========================================================
                      _buildHubTile(
                        icon: Icons.gavel,
                        titleEn: '5. Port Operations & Clearance',
                        titleAr: 'المرحلة 5: التخليص الجمركي وإدارة الميناء',
                        color: Colors.indigo,
                        initiallyExpanded: false,
                        children: [
                          _buildMenuItem(Icons.description_outlined, 'Customs Declaration 46', 'قيد شهادة الإجراءات إقرار 46', 23, selectedIndex),
                          _buildMenuItem(Icons.find_in_page_outlined, 'Customs Clearance Follow-up', 'متابعة الكشف والتثمين والتخليص', 27, selectedIndex),
                          _buildMenuItem(Icons.science_outlined, 'Drawing Samples / Shortage', 'سحب العينات وإثبات الفاقد الجمركي', 27, selectedIndex),
                          _buildMenuItem(Icons.warning_amber_outlined, 'Cargo Discrepancy / Damage', 'محضر إثبات العجز والتلف بالمعاينة', 28, selectedIndex),
                          _buildMenuItem(Icons.receipt_long_outlined, 'Final Customs Calculation', 'المطالبة وسداد الرسوم والضرائب', 27, selectedIndex),
                          _buildMenuItem(Icons.timer_outlined, 'Demurrage & Detention', 'فترات السماح وغرامات الأرضيات', 44, selectedIndex),
                        ],
                      ),

                      // =========================================================
                      // PHASE 6: INBOUND LOGISTICS & FINAL CLOSURE (الاستلام المخزني والتسوية المالية)
                      // =========================================================
                      _buildHubTile(
                        icon: Icons.archive_outlined,
                        titleEn: '6. Inbound & Final Closure',
                        titleAr: 'المرحلة 6: الاستلام والتسوية والإغلاق',
                        color: AppTheme.crimson,
                        initiallyExpanded: false,
                        children: [
                          _buildMenuItem(Icons.inventory_outlined, 'Warehouse Receiving (GRN)', 'إشعار المخازن وإذن الإضافة GRN', 28, selectedIndex),
                          _buildMenuItem(Icons.calculate_outlined, 'Landed Cost Settlement', 'تسوية التكلفة الاستيرادية الشاملة', 29, selectedIndex),
                          _buildMenuItem(Icons.archive_outlined, 'Import File Final Closure', 'المراجعة الختامية وإغلاق الملف', 30, selectedIndex),
                        ],
                      ),

                      // =========================================================
                      // HUB: DASHBOARD & INTELLIGENCE (لوحة القيادة والتقارير والرقابة)
                      // =========================================================
                      _buildHubTile(
                        icon: Icons.analytics_outlined,
                        titleEn: 'Dashboard & Reports',
                        titleAr: 'لوحة القيادة والتقارير والرقابة',
                        color: Colors.blueGrey,
                        initiallyExpanded: false,
                        children: [
                          _buildMenuItem(Icons.dashboard_customize_outlined, 'Operational Dashboard', 'لوحة التحكم ومؤشرات الأداء', 0, selectedIndex),
                          _buildMenuItem(Icons.view_kanban_outlined, 'Lifecycle Operations Board', 'لوحة تتبع ومراحل الشحنات التفاعلية', 48, selectedIndex),
                          _buildMenuItem(Icons.summarize_outlined, 'Master Shipment Report', 'تقرير الشحنة الشامل المدمج', 47, selectedIndex),
                          _buildMenuItem(Icons.assessment_outlined, 'Dynamic Report Builder', 'مُنشئ التقارير المخصصة', 41, selectedIndex),
                          _buildMenuItem(Icons.published_with_changes_outlined, 'Quick Update Engine', 'محرك التحديث السريع', 42, selectedIndex),
                          _buildMenuItem(Icons.task_alt_outlined, 'Smart Tasks & Alerts', 'المهام والتنبيهات الذكية', 40, selectedIndex),
                          _buildMenuItem(Icons.saved_search, 'HS Code Tariff Explorer', 'مستكشف بنود التعريفة الجمركية', 45, selectedIndex),
                          _buildMenuItem(Icons.history_edu_outlined, 'System Audit Logs', 'سجل التدقيق والرقابة', 39, selectedIndex),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),

                // User Profile & RBAC Footer
                if (user != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    color: Colors.black.withOpacity(0.15),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: _getRoleColor(user.role).withOpacity(0.2),
                          radius: 13,
                          child: Icon(Icons.person, color: _getRoleColor(user.role), size: 14),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.fullName,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                user.role,
                                style: TextStyle(color: _getRoleColor(user.role), fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Main Content View
          Expanded(
            child: _screens[selectedIndex < _screens.length ? selectedIndex : 0],
          ),
        ],
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
    required String titleEn,
    required String titleAr,
    required Color color,
    required List<Widget> children,
    bool initiallyExpanded = false,
  }) {
    final isSearching = _searchQuery.isNotEmpty;

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        hoverColor: Colors.white.withOpacity(0.04),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: ExpansionTile(
          key: isSearching ? UniqueKey() : null,
          initiallyExpanded: isSearching ? true : initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
          childrenPadding: const EdgeInsets.only(bottom: 2),
          leading: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                titleEn,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                titleAr,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 9,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          iconColor: color,
          collapsedIconColor: Colors.white54,
          children: children,
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String titleEn, String titleAr, int index, int selectedIndex) {
    if (_searchQuery.isNotEmpty &&
        !titleEn.toLowerCase().contains(_searchQuery) &&
        !titleAr.toLowerCase().contains(_searchQuery)) {
      return const SizedBox.shrink();
    }

    final isSelected = selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.cobalt.withOpacity(0.25) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: isSelected
            ? const Border(left: BorderSide(color: AppTheme.cobalt, width: 3))
            : null,
      ),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
        minLeadingWidth: 18,
        leading: Icon(
          icon,
          size: 13.5,
          color: isSelected ? AppTheme.cobalt : AppTheme.cloudWhite.withOpacity(0.8),
        ),
        title: Text(
          titleEn,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.cloudWhite,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 10.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          titleAr,
          style: TextStyle(
            color: isSelected ? Colors.white70 : Colors.white54,
            fontSize: 9,
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
