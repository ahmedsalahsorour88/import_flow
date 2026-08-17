import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';
import '../models/lifecycle_board_model.dart';
import '../providers/lifecycle_board_provider.dart';
import '../widgets/step_action_dialog.dart';

class LifecycleBoardScreen extends ConsumerStatefulWidget {
  const LifecycleBoardScreen({super.key});

  @override
  ConsumerState<LifecycleBoardScreen> createState() => _LifecycleBoardScreenState();
}

class _LifecycleBoardScreenState extends ConsumerState<LifecycleBoardScreen> {
  String _searchQuery = '';
  String? _selectedFilterFileCode;

  @override
  Widget build(BuildContext context) {
    final boardAsync = ref.watch(lifecycleBoardSummaryProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppTheme.charcoal,
        elevation: 2,
        title: const Row(
          children: [
            Icon(Icons.view_kanban_outlined, color: AppTheme.cobalt, size: 24),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shipment Lifecycle Operations Board (6 Phases / 21 Steps)',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'لوحة تتبع ومتابعة مراحل الشحنات التفاعلية المباشرة (المستويات الـ 6 — 21 خطوة تشغيلية)',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'تحديث البيانات المباشرة',
            onPressed: () => ref.invalidate(lifecycleBoardSummaryProvider),
          ),
          const SizedBox(width: 8),
          const BackToDashboardButton(),
          const SizedBox(width: 12),
        ],
      ),
      body: boardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.crimson, size: 40),
              const SizedBox(height: 12),
              Text('حدث خطأ أثناء تحميل بيانات اللوحة: $err', style: const TextStyle(color: AppTheme.crimson)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(lifecycleBoardSummaryProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
        data: (boardData) {
          final allShipments = boardData.allShipments;
          final availableFileCodes = allShipments.map((s) => s.importFileCode).toSet().toList()..sort();

          // Filter shipments
          final filteredShipments = allShipments.where((s) {
            final matchesSearch = _searchQuery.isEmpty ||
                s.importFileCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                s.companyName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                s.supplierName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (s.poNumber != null && s.poNumber!.toLowerCase().contains(_searchQuery.toLowerCase()));

            final matchesFileCode = _selectedFilterFileCode == null ||
                _selectedFilterFileCode == 'All' ||
                s.importFileCode == _selectedFilterFileCode;

            return matchesSearch && matchesFileCode;
          }).toList();

          return Column(
            children: [
              // Top Filters & Live Statistics Bar
              _buildTopControlBar(boardData, availableFileCodes),

              // 6 Phase Pipeline Columns Board
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: constraints.maxWidth),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: boardData.phases.map((phase) {
                              final phaseShipments = filteredShipments
                                  .where((s) => phase.stepCodes.contains(s.stepCode))
                                  .toList();

                              return _buildPhaseColumn(
                                phase: phase,
                                shipments: phaseShipments,
                                allPhases: boardData.phases,
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopControlBar(LifecycleBoardSummaryModel boardData, List<String> availableFileCodes) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Live Counts Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.cobalt.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.cobalt.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stream, color: AppTheme.cobalt, size: 16),
                const SizedBox(width: 6),
                Text(
                  'إجمالي الشحنات النشطة: ${boardData.totalActiveFiles} ملف',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.cobalt),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${boardData.allShipments.length} مرحلة متزامنة)',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),

          // File Code Filter Dropdown
          const Text('تصفية بملف الشحنة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(width: 8),
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFilterFileCode ?? 'All',
                items: [
                  const DropdownMenuItem(value: 'All', child: Text('كافة ملفات الشحن', style: TextStyle(fontSize: 12))),
                  ...availableFileCodes.map((code) => DropdownMenuItem(value: code, child: Text(code, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))),
                ],
                onChanged: (val) {
                  setState(() => _selectedFilterFileCode = val);
                },
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Search Box
          Expanded(
            child: SizedBox(
              height: 36,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'بحث بالكود، اسم المورد، الشركة أو أمر الشراء PO...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: (val) {
                  setState(() => _searchQuery = val.trim());
                },
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Clear Filters Button
          if (_searchQuery.isNotEmpty || (_selectedFilterFileCode != null && _selectedFilterFileCode != 'All'))
            IconButton(
              icon: const Icon(Icons.clear, size: 20, color: AppTheme.crimson),
              tooltip: 'إلغاء التصفية',
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedFilterFileCode = 'All';
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPhaseColumn({
    required PhaseSummaryModel phase,
    required List<ShipmentStageCardModel> shipments,
    required List<PhaseSummaryModel> allPhases,
  }) {
    final headerColor = _parseColor(phase.colorHex);

    return Container(
      width: 290,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: headerColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Column Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(9),
                topRight: Radius.circular(9),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        phase.titleEn,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        phase.titleAr,
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${shipments.length}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Steps Pill List
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: Colors.grey.shade50,
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: phase.stepCodes.map((code) {
                final count = phase.stepCounts[code] ?? 0;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: count > 0 ? headerColor.withOpacity(0.15) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: count > 0 ? headerColor : Colors.grey.shade300),
                  ),
                  child: Text(
                    '$code: $count',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: count > 0 ? FontWeight.bold : FontWeight.normal,
                      color: count > 0 ? headerColor : Colors.grey.shade600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),

          // Shipments Cards Scroll Area
          Expanded(
            child: shipments.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_outlined, size: 36, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Text(
                            'لا توجد شحنات نشطة في هذه المرحلة حالياً',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: shipments.length,
                    itemBuilder: (context, index) {
                      final s = shipments[index];
                      return _buildShipmentCard(s, headerColor, allPhases);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildShipmentCard(
    ShipmentStageCardModel s,
    Color phaseColor,
    List<PhaseSummaryModel> allPhases,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: phaseColor.withOpacity(0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Code & Mode Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  s.importFileCode,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.cobalt),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.cobalt.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${s.shipmentMode} | ${s.incotermCode}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.cobalt),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Step Name Badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: phaseColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: phaseColor.withOpacity(0.3)),
              ),
              child: Text(
                '📍 ${s.stepNameEn} (${s.stepCode})',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: phaseColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 6),

            // Company & Supplier
            Text(
              '🏢 ${s.companyName}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '🌍 ${s.supplierName} ${s.poNumber != null ? '| PO: ${s.poNumber}' : ''}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Cost Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '💰 ${s.estimatedCost.toStringAsFixed(0)} ${s.estimatedCostCurrency}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: AppTheme.emerald),
                ),
                if (s.startedAt != null)
                  Text(
                    s.startedAt!.split(' ')[0],
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
              ],
            ),

            if (s.notes != null && s.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  '📝 ${s.notes}',
                  style: TextStyle(fontSize: 10.5, color: Colors.grey.shade800),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            const SizedBox(height: 8),

            // Action Workstation Button
            SizedBox(
              width: double.infinity,
              height: 32,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: phaseColor,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) => StepActionDialog(
                      shipment: s,
                      allPhases: allPhases,
                    ),
                  );
                },
                icon: const Icon(Icons.play_circle_outline, size: 15, color: Colors.white),
                label: const Text(
                  'تنفيذ الخطوة وترحيل الشحنة',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
