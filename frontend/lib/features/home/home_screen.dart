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
import '../financial_settlement/screens/landed_cost_comparison_screen.dart';
import '../freight_booking/screens/freight_booking_screen.dart';
import '../freight_quotations/screens/freight_quotations_comparison_screen.dart';
import '../import_companies/screens/import_companies_screen.dart';
import '../import_documentation/screens/bank_form4_screen.dart';
import '../import_documentation/screens/central_docs_archive_screen.dart';
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

        // 49: Freight Quotations Comparison
        FreightQuotationsComparisonScreen(),

        // 50: Landed Cost Comparison
        LandedCostComparisonScreen(importFileId: 1, importFileCode: 'IMP-DEMO'),

        // 51: Central Shipment Documents Archive & Discrepancies Summary Hub
        const CentralDocsArchiveScreen(),
      ];

  bool _isSidebarCollapsed = false;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(navigationIndexProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      body: Row(
        children: [
          // Animated Collapsible Professional Sidebar (52px <-> 235px)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: _isSidebarCollapsed ? 52 : 235,
            color: AppTheme.charcoal,
            child: _isSidebarCollapsed
                ? _buildCollapsedRail(selectedIndex, user)
                : _buildFullSidebar(selectedIndex, user),
          ),

          // Main Content View
          Expanded(
            child: _screens[selectedIndex < _screens.length ? selectedIndex : 0],
          ),
        ],
      ),
    );
  }

  // ─── Mini Icon Rail (52px width) ───────────────────────────────────────────

  Widget _buildCollapsedRail(int selectedIndex, dynamic user) {
    return Column(
      children: [
        const SizedBox(height: 8),
        IconButton(
          icon: const Icon(Icons.menu, color: Colors.white, size: 20),
          tooltip: 'إظهار القائمة الجانبية الكاملة (Expand Sidebar)',
          onPressed: () => setState(() => _isSidebarCollapsed = false),
        ),
        const Divider(color: Colors.white24, height: 10),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 4),
            children: [
              _buildRailIcon(Icons.view_kanban_outlined, 'لوحة مراحل وتتبع الشحنات (Operations Board)', 48, selectedIndex, AppTheme.cobalt),
              _buildRailIcon(Icons.dashboard_customize_outlined, 'لوحة التحكم ومؤشرات الأداء (Dashboard)', 0, selectedIndex, AppTheme.emerald),
              const Divider(color: Colors.white12, height: 8),
              _buildRailIcon(Icons.analytics_outlined, 'المرحلة 1: التخطيط والدراسات المسبقة', 4, selectedIndex, Colors.amber.shade700),
              _buildRailIcon(Icons.app_registration_outlined, 'المرحلة 2: بداية الشحنة وإصدار ACID', 8, selectedIndex, AppTheme.cobalt),
              _buildRailIcon(Icons.assignment_turned_in_outlined, 'المرحلة 3: حجز وتدقيق الشحن المستندي', 11, selectedIndex, Colors.teal),
              _buildRailIcon(Icons.verified_user_outlined, 'المرحلة 4: التوثيق الرقمي والاعتماد البنكي', 20, selectedIndex, AppTheme.crimson),
              _buildRailIcon(Icons.anchor_outlined, 'المرحلة 5: عمليات الميناء والتخليص الجمركي', 24, selectedIndex, Colors.purple),
              _buildRailIcon(Icons.inventory_outlined, 'المرحلة 6: الاستلام المخزني والتسوية المالية', 31, selectedIndex, AppTheme.emerald),
              const Divider(color: Colors.white12, height: 8),
              _buildRailIcon(Icons.folder_special_outlined, 'تخطيط الشحنة وأوامر الشراء', 1, selectedIndex, Colors.cyan),
              _buildRailIcon(Icons.storage_outlined, 'البيانات والجداول الأساسية', 34, selectedIndex, Colors.teal),
              _buildRailIcon(Icons.summarize_outlined, 'التقارير وسجلات التدقيق', 47, selectedIndex, Colors.indigo),
            ],
          ),
        ),
        const Divider(color: Colors.white24, height: 8),
        const NotificationBellWidget(),
        const SizedBox(height: 6),
        if (user != null)
          Tooltip(
            message: '${user.fullName} (${user.role})',
            child: CircleAvatar(
              backgroundColor: _getRoleColor(user.role).withOpacity(0.2),
              radius: 12,
              child: Icon(Icons.person, color: _getRoleColor(user.role), size: 14),
            ),
          ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildRailIcon(IconData icon, String tooltip, int index, int selectedIndex, Color color) {
    final isSelected = selectedIndex == index;
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: InkWell(
        onTap: () => selectNavigationIndex(ref, index),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.3) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: isSelected ? Border.all(color: color, width: 1.5) : null,
          ),
          child: Icon(
            icon,
            size: 17,
            color: isSelected ? color : Colors.white70,
          ),
        ),
      ),
    );
  }

  // ─── Full Sidebar (235px width) ────────────────────────────────────────────

  Widget _buildFullSidebar(int selectedIndex, dynamic user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo & Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppTheme.cobalt,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sorour Logistics',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                    ),
                    Text(
                      'سرور للخدمات اللوجستية',
                      style: TextStyle(color: Colors.white70, fontSize: 8.5),
                    ),
                  ],
                ),
              ),
              const NotificationBellWidget(),
              const SizedBox(width: 2),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.keyboard_double_arrow_left, color: Colors.white70, size: 18),
                tooltip: 'إخفاء القائمة لتوسيع الشاشة (Collapse Sidebar)',
                onPressed: () => setState(() => _isSidebarCollapsed = true),
              ),
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
                initiallyExpanded: false,
                children: [
                  _buildMenuItem(Icons.compare_arrows_outlined, 'Freight Studies', 'دراسات ومفاضلة نولون الشحن', 4, selectedIndex),
                  _buildMenuItem(Icons.price_change_outlined, 'Freight Quotations Comparison', 'مقارنة عروض أسعار الشحن', 49, selectedIndex),
                  _buildMenuItem(Icons.gavel_outlined, 'Customs Studies', 'الدراسات والاستشارات الجمركية', 6, selectedIndex),
                  _buildMenuItem(Icons.verified_outlined, 'Import Regulatory Requirements', 'متطلبات واشتراطات الاستيراد للشحنة', 43, selectedIndex),
                ],
              ),

              // =========================================================
              // PHASE 2: SHIPMENT INITIATION (بداية الشحنة والتسجيل المسبق)
              // =========================================================
              _buildHubTile(
                icon: Icons.app_registration_outlined,
                titleEn: '2. Shipment Initiation',
                titleAr: 'المرحلة 2: بداية الشحنة والتسجيل المسبق',
                color: AppTheme.cobalt,
                initiallyExpanded: false,
                children: [
                  _buildMenuItem(Icons.account_balance_wallet_outlined, 'Finance Approvals & Budget', 'اعتمادات الميزانية وسداد الموردين', 8, selectedIndex),
                  _buildMenuItem(Icons.qr_code_2_outlined, 'ACID Operations', 'الرقم التعريفي المبدئي للشحنة ACID', 11, selectedIndex),
                ],
              ),

              // =========================================================
              // PHASE 3: BOOKING & DOC PREPARATION (حجز الشحن والتدقيق المبدئي)
              // =========================================================
              _buildHubTile(
                icon: Icons.assignment_turned_in_outlined,
                titleEn: '3. Booking & Doc Prep',
                titleAr: 'المرحلة 3: حجز الشحن والتدقيق المستندي المبدئي',
                color: Colors.teal,
                initiallyExpanded: false,
                children: [
                  _buildMenuItem(Icons.bookmark_added_outlined, 'Freight Booking', 'حجز النولون وتأكيد الخط الملاحي', 25, selectedIndex),
                  _buildMenuItem(Icons.grid_view_outlined, 'Freight Allocations', 'تخصيص وتوزيع الحاويات والبضائع', 26, selectedIndex),
                  _buildMenuItem(Icons.directions_boat_outlined, 'Cargo Shipping Tracking', 'متابعة حركة الشحن البحري والجوي', 26, selectedIndex),
                  _buildMenuItem(Icons.rate_review_outlined, 'Draft Docs Review', 'مراجعة وتدقيق مسودات المستندات', 19, selectedIndex),
                  _buildMenuItem(Icons.verified_outlined, 'Docs Customs Approval', 'الاعتماد النهائي للمستندات جمركياً', 20, selectedIndex),
                  _buildMenuItem(Icons.inventory_2_outlined, 'Central Docs & Rectifications Hub', 'الأرشيف المركزي لمستندات وتعديلات الشحنة', 51, selectedIndex),
                  _buildMenuItem(Icons.calculate_outlined, 'Customs Duty Estimator', 'حساب الضرائب والرسوم الجمركية التقديرية', 6, selectedIndex),
                ],
              ),

              // =========================================================
              // PHASE 4: DIGITAL & BANKING (التوثيق الرقمي والاعتماد البنكي)
              // =========================================================
              _buildHubTile(
                icon: Icons.verified_user_outlined,
                titleEn: '4. Digital & Banking',
                titleAr: 'المرحلة 4: التوثيق الرقمي والاعتماد البنكي',
                color: AppTheme.crimson,
                initiallyExpanded: false,
                children: [
                  _buildMenuItem(Icons.cloud_upload_outlined, 'CargoX Follow-up / Upload', 'متابعة ورفع المستندات عبر نافذة و CargoX', 22, selectedIndex),
                  _buildMenuItem(Icons.mark_email_read_outlined, 'Originals Collection', 'تحصيل أصول مستندات الشحنة', 18, selectedIndex),
                  _buildMenuItem(Icons.account_balance_outlined, 'Bank Form 4', 'النموذج الإحصائي والتحويل البنكي نموذج 4', 16, selectedIndex),
                ],
              ),

              // =========================================================
              // PHASE 5: PORT & CLEARANCE (الميناء والتخليص الجمركي)
              // =========================================================
              _buildHubTile(
                icon: Icons.anchor_outlined,
                titleEn: '5. Port & Clearance',
                titleAr: 'المرحلة 5: الميناء والتخليص الجمركي',
                color: Colors.purple,
                initiallyExpanded: false,
                children: [
                  _buildMenuItem(Icons.description_outlined, 'Customs Declaration 46', 'شهادة الإجراءات الجمركية إقرار 46 ك.م', 23, selectedIndex),
                  _buildMenuItem(Icons.fact_check_outlined, 'Customs Clearance Follow-up', 'متابعة الكشف والتثمين والتفتيش الجمركي', 27, selectedIndex),
                  _buildMenuItem(Icons.science_outlined, 'Drawing Samples / Shortage', 'سحب العينات وتحديد عجز البضائع', 27, selectedIndex),
                  _buildMenuItem(Icons.report_problem_outlined, 'Discrepancy / Damage', 'إثبات الفاقد والتلف الجمركي', 27, selectedIndex),
                  _buildMenuItem(Icons.receipt_long_outlined, 'Final Customs Payment', 'سداد الرسوم والضرائب الجمركية النهائية', 27, selectedIndex),
                  _buildMenuItem(Icons.timer_outlined, 'Demurrage & Detention', 'تتبع غرامات الأرضيات وحراسات الحاويات', 44, selectedIndex),
                ],
              ),

              // =========================================================
              // PHASE 6: INBOUND & CLOSURE (الاستلام والتسوية المالية)
              // =========================================================
              _buildHubTile(
                icon: Icons.inventory_outlined,
                titleEn: '6. Inbound & Closure',
                titleAr: 'المرحلة 6: الاستلام المخزني والتسوية المالية',
                color: AppTheme.emerald,
                initiallyExpanded: false,
                children: [
                  _buildMenuItem(Icons.warehouse_outlined, 'Warehouse Receiving GRN', 'إذن إضافة المخزن واستلام الشحنة', 28, selectedIndex),
                  _buildMenuItem(Icons.price_check_outlined, 'Landed Cost Settlement', 'حساب تكلفة الوصول النهائية للوحدة', 29, selectedIndex),
                  _buildMenuItem(Icons.analytics_outlined, 'Landed Cost Comparison', 'مقارنة تكاليف الوصول', 50, selectedIndex),
                  _buildMenuItem(Icons.task_alt_outlined, 'Import File Final Closure', 'الإغلاق المالي والإداري لملف الاستيراد', 30, selectedIndex),
                ],
              ),

              // =========================================================
              // HUB 3: DASHBOARDS & AUDIT (لوحات القيادة والتقارير الرقابية)
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
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.white70, size: 16),
                  tooltip: 'خيارات المستخدم',
                  onSelected: (val) {
                    if (val == 'LOGOUT') {
                      ref.read(authProvider.notifier).logout();
                    } else {
                      ref.read(authProvider.notifier).switchDemoRole(val);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'ADMIN', child: Text('تبديل كـ: Admin 🔴')),
                    const PopupMenuItem(value: 'MANAGER', child: Text('تبديل كـ: Manager 🔵')),
                    const PopupMenuItem(value: 'OPERATOR', child: Text('تبديل كـ: Specialist 🟢')),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'LOGOUT',
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: AppTheme.crimson, size: 16),
                          SizedBox(width: 8),
                          Text('تسجيل الخروج (Logout)', style: TextStyle(color: AppTheme.crimson)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
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
