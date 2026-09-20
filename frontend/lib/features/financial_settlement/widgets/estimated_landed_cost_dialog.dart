import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/file_save_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/unsaved_changes_guard.dart';
import '../models/estimated_landed_cost_model.dart';
import '../providers/financial_settlement_provider.dart';

/// Shows the Estimated Landed Cost Simulation Dialog (PL-08).
Future<void> showEstimatedLandedCostDialog(
  BuildContext context,
  WidgetRef ref, {
  required int importFileId,
  EstimatedLandedCostSimulationRequestModel? initialRequest,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => EstimatedLandedCostDialog(
      importFileId: importFileId,
      initialRequest: initialRequest,
    ),
  );
}

class EstimatedLandedCostDialog extends ConsumerStatefulWidget {
  final int importFileId;
  final EstimatedLandedCostSimulationRequestModel? initialRequest;

  const EstimatedLandedCostDialog({
    super.key,
    required this.importFileId,
    this.initialRequest,
  });

  @override
  ConsumerState<EstimatedLandedCostDialog> createState() =>
      _EstimatedLandedCostDialogState();
}

class _EstimatedLandedCostDialogState
    extends ConsumerState<EstimatedLandedCostDialog>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;
  EstimatedLandedCostSimulationModel? _data;

  // Controllers for overrides
  late final TextEditingController _fxRateController;
  late final TextEditingController _freightController;
  late final TextEditingController _insuranceController;
  late final TextEditingController _clearanceController;
  late final TextEditingController _portController;
  late final TextEditingController _transportController;
  late final TextEditingController _bankFeesController;
  late final TextEditingController _otherFeesController;
  String _selectedAllocation = 'Value-Based';

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _fxRateController = TextEditingController();
    _freightController = TextEditingController();
    _insuranceController = TextEditingController();
    _clearanceController = TextEditingController();
    _portController = TextEditingController();
    _transportController = TextEditingController();
    _bankFeesController = TextEditingController();
    _otherFeesController = TextEditingController();

    if (widget.initialRequest != null) {
      _applyRequestToControllers(widget.initialRequest!);
    }

    _loadSimulation();
  }

  void _applyRequestToControllers(
      EstimatedLandedCostSimulationRequestModel req) {
    if (req.exchangeRateOverride != null) {
      _fxRateController.text = req.exchangeRateOverride!.toString();
    }
    if (req.freightAmountEgpOverride != null) {
      _freightController.text = req.freightAmountEgpOverride!.toString();
    }
    if (req.insuranceAmountEgpOverride != null) {
      _insuranceController.text = req.insuranceAmountEgpOverride!.toString();
    }
    if (req.clearanceFeesEgpOverride != null) {
      _clearanceController.text = req.clearanceFeesEgpOverride!.toString();
    }
    if (req.portHandlingEgpOverride != null) {
      _portController.text = req.portHandlingEgpOverride!.toString();
    }
    if (req.inlandTransportEgpOverride != null) {
      _transportController.text = req.inlandTransportEgpOverride!.toString();
    }
    if (req.bankFeesEgpOverride != null) {
      _bankFeesController.text = req.bankFeesEgpOverride!.toString();
    }
    if (req.otherExpensesEgpOverride != null) {
      _otherFeesController.text = req.otherExpensesEgpOverride!.toString();
    }
    _selectedAllocation = req.allocationPreference;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fxRateController.dispose();
    _freightController.dispose();
    _insuranceController.dispose();
    _clearanceController.dispose();
    _portController.dispose();
    _transportController.dispose();
    _bankFeesController.dispose();
    _otherFeesController.dispose();
    super.dispose();
  }

  Future<void> _loadSimulation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final req = _buildRequestFromControllers();
      final result = await ref
          .read(financialSettlementProvider.notifier)
          .simulateEstimatedLandedCost(widget.importFileId, req.toJson());

      if (mounted) {
        setState(() {
          _data = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  EstimatedLandedCostSimulationRequestModel _buildRequestFromControllers() {
    return EstimatedLandedCostSimulationRequestModel(
      exchangeRateOverride: double.tryParse(_fxRateController.text.trim()),
      freightAmountEgpOverride: double.tryParse(_freightController.text.trim()),
      insuranceAmountEgpOverride:
          double.tryParse(_insuranceController.text.trim()),
      clearanceFeesEgpOverride:
          double.tryParse(_clearanceController.text.trim()),
      portHandlingEgpOverride: double.tryParse(_portController.text.trim()),
      inlandTransportEgpOverride:
          double.tryParse(_transportController.text.trim()),
      bankFeesEgpOverride: double.tryParse(_bankFeesController.text.trim()),
      otherExpensesEgpOverride: double.tryParse(_otherFeesController.text.trim()),
      allocationPreference: _selectedAllocation,
    );
  }

  void _copyTsvToClipboard() {
    if (_data == null) return;
    final buffer = StringBuffer();
    buffer.writeln(
        "Line\tItem Code\tItem Name\tHS Code\tQty\tFOB Unit FC\tFOB Unit EGP\tFOB Total EGP\tCustoms Duty EGP\tVAT & Taxes EGP\tFreight EGP\tClearance & Port EGP\tInland Transport EGP\tTotal Landed EGP\tUnit Landed EGP\tUnit Landed FC\tMarkup Factor\tMarkup %");
    for (final itm in _data!.itemsBreakdown) {
      buffer.writeln(
          "${itm.lineNo}\t${itm.itemCode}\t${itm.itemName}\t${itm.hsCode}\t${itm.qty}\t${itm.unitPriceFc}\t${itm.fobUnitEgp}\t${itm.fobTotalEgp}\t${itm.allocatedCustomsDutyEgp}\t${itm.allocatedVatEgp}\t${itm.allocatedFreightEgp}\t${itm.allocatedClearanceAndPortEgp}\t${itm.allocatedInlandTransportEgp}\t${itm.totalLandedCostEgp}\t${itm.unitLandedCostEgp}\t${itm.unitLandedCostFc}\t${itm.markupFactor}\t${itm.markupPercent}%");
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ بيانات التكلفة التقديرية (TSV) للحافظة بنجاح'),
        backgroundColor: AppTheme.emerald,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _exportCsv() async {
    if (_data == null) return;
    final buffer = StringBuffer();
    // UTF-8 BOM for Arabic support in Excel
    buffer.write('\uFEFF');
    buffer.writeln(
        "م,كود الصنف,اسم الصنف,البند الجمركي,الكمية,سعر الوحدة أجنبي,سعر الوحدة ج.م,إجمالي FOB ج.م,ضريبة الوارد ج.م,الضرائب والقيمة المضافة ج.م,النولون ج.م,الموانئ والتخليص ج.م,النقل الداخلي ج.م,إجمالي تكلفة الوصول ج.م,تكلفة الوحدة ج.م,تكلفة الوحدة أجنبي,معامل الزيادة,نسبة الزيادة %");
    for (final itm in _data!.itemsBreakdown) {
      buffer.writeln(
          '${itm.lineNo},"${itm.itemCode}","${itm.itemName}","${itm.hsCode}",${itm.qty},${itm.unitPriceFc},${itm.fobUnitEgp},${itm.fobTotalEgp},${itm.allocatedCustomsDutyEgp},${itm.allocatedVatEgp},${itm.allocatedFreightEgp},${itm.allocatedClearanceAndPortEgp},${itm.allocatedInlandTransportEgp},${itm.totalLandedCostEgp},${itm.unitLandedCostEgp},${itm.unitLandedCostFc},${itm.markupFactor},${itm.markupPercent}%');
    }

    await FileSaveHelper.exportAndSaveFile(
      context: context,
      bytes: utf8.encode(buffer.toString()),
      stageName: 'Landed Cost Simulation',
      importFileNameOrCode: _data!.importFileCode,
      extension: 'csv',
    );
  }

  bool get _isDirty {
    final req = widget.initialRequest;
    if (_fxRateController.text.trim() != (req?.exchangeRateOverride?.toString() ?? '')) return true;
    if (_freightController.text.trim() != (req?.freightAmountEgpOverride?.toString() ?? '')) return true;
    if (_insuranceController.text.trim() != (req?.insuranceAmountEgpOverride?.toString() ?? '')) return true;
    if (_clearanceController.text.trim() != (req?.clearanceFeesEgpOverride?.toString() ?? '')) return true;
    if (_portController.text.trim() != (req?.portHandlingEgpOverride?.toString() ?? '')) return true;
    if (_transportController.text.trim() != (req?.inlandTransportEgpOverride?.toString() ?? '')) return true;
    if (_bankFeesController.text.trim() != (req?.bankFeesEgpOverride?.toString() ?? '')) return true;
    if (_otherFeesController.text.trim() != (req?.otherExpensesEgpOverride?.toString() ?? '')) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = (screenSize.width - 32).clamp(360.0, 1150.0);
    final dialogHeight = (screenSize.height - 48).clamp(500.0, 850.0);
    final isDark = AppTheme.isDark(context);

    return UnsavedChangesGuard(
      isDirty: _isDirty,
      child: Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'جاري حساب وتوزيع تكلفة الوصول التقديرية بالربط مع محرك الجمارك...',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.red, size: 48),
                                const SizedBox(height: 12),
                                Text(
                                  'خطأ في عملية المحاكاة:\n$_errorMessage',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.red),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _loadSimulation,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('إعادة المحاولة'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _buildContent(isDark),
            ),
            _buildBottomBar(isDark),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkElevatedSurface : const Color(0xFF1E293B),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.shade700,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.calculate, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'محاكاة تكلفة الوصول التقديرية للوحدة قبل الشحن (Estimated Landed Cost)',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _data != null
                      ? 'الملف: ${_data!.importFileCode} | العملة: ${_data!.currency} | الصرف: ${_data!.exchangeRate} ج.م | شرط الشحن: ${_data!.incoterm}'
                      : 'جاري تحميل المعطيات اللوجستية والجمركية...',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => UnsavedChangesGuard.maybePop(context, isDirty: _isDirty),
            tooltip: 'إغلاق',
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_data == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Executive Summary Banner
          _buildExecutiveSummaryBanner(isDark),
          const SizedBox(height: 12),

          // 2. KPI Cards Strip
          _buildKpiCards(isDark),
          const SizedBox(height: 12),

          // 3. Overrides & Recalculate Panel (Collapsible)
          _buildOverridesPanel(isDark),
          const SizedBox(height: 16),

          // 4. Tabs Section
          TabBar(
            controller: _tabController,
            labelColor: isDark ? Colors.tealAccent : Colors.teal.shade800,
            unselectedLabelColor: Colors.grey,
            indicatorColor: isDark ? Colors.tealAccent : Colors.teal.shade700,
            tabs: const [
              Tab(
                icon: Icon(Icons.table_chart_outlined),
                text: 'تحليل بنود البضاعة وتكلفة الوحدة (Items Landed Cost)',
              ),
              Tab(
                icon: Icon(Icons.receipt_long_outlined),
                text: 'قائمة المصاريف والنفقات التقديرية (Expenses Breakdown)',
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 380,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildItemsTable(isDark),
                _buildExpensesTable(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveSummaryBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.teal.shade900.withOpacity(0.25)
            : const Color(0xFFF0FDFA),
        border: Border.all(
          color: isDark ? Colors.teal.shade700 : Colors.teal.shade300,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: isDark ? Colors.tealAccent : Colors.teal.shade700,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _data!.executiveSummaryAr,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.tealAccent.shade100 : Colors.teal.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCards(bool isDark) {
    return LayoutBuilder(builder: (context, constraints) {
      final bool isCompact = constraints.maxWidth < 850;

      final cards = [
        _buildKpiItem(
          label: 'إجمالي البضاعة FOB',
          valueEgp: '${_data!.totalFobEgp.toStringAsFixed(0)} ج.م',
          valueFc: '${_data!.totalFobFc.toStringAsFixed(0)} ${_data!.currency}',
          icon: Icons.inventory_2,
          color: const Color(0xFF2563EB),
          isDark: isDark,
        ),
        _buildKpiItem(
          label: 'النولون والتأمين',
          valueEgp:
              '${(_data!.totalFreightEgp + _data!.totalInsuranceEgp).toStringAsFixed(0)} ج.م',
          valueFc: 'نولون: ${_data!.totalFreightEgp.toStringAsFixed(0)}',
          icon: Icons.sailing,
          color: const Color(0xFF0D9488),
          isDark: isDark,
        ),
        _buildKpiItem(
          label: 'الجمارك والضرائب',
          valueEgp: '${_data!.totalCustomsAndTaxesEgp.toStringAsFixed(0)} ج.م',
          valueFc: 'بند التعريفة MD-008',
          icon: Icons.account_balance,
          color: const Color(0xFFD97706),
          isDark: isDark,
        ),
        _buildKpiItem(
          label: 'الموانئ والتخليص والنقل',
          valueEgp:
              '${(_data!.totalClearanceAndPortEgp + _data!.totalInlandTransportEgp).toStringAsFixed(0)} ج.م',
          valueFc: 'لوجستيات وموانئ',
          icon: Icons.local_shipping,
          color: const Color(0xFF7C3AED),
          isDark: isDark,
        ),
        _buildKpiItem(
          label: 'تكلفة الوصول الشاملة',
          valueEgp: '${_data!.totalLandedCostEgp.toStringAsFixed(0)} ج.م',
          valueFc:
              '${_data!.totalLandedCostFc.toStringAsFixed(0)} ${_data!.currency}',
          icon: Icons.monetization_on,
          color: const Color(0xFF059669),
          isDark: isDark,
          highlight: true,
        ),
        _buildKpiItem(
          label: 'معامل الزيادة الإجمالي',
          valueEgp: '×${_data!.averageMarkupFactor.toStringAsFixed(3)}',
          valueFc: '+${_data!.averageMarkupPercent.toStringAsFixed(1)}%',
          icon: Icons.trending_up,
          color: const Color(0xFFE11D48),
          isDark: isDark,
          highlight: true,
        ),
      ];

      if (isCompact) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: cards
              .map((c) => SizedBox(
                    width: (constraints.maxWidth - 16) / 2,
                    child: c,
                  ))
              .toList(),
        );
      }

      return Row(
        children: cards
            .map((c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: c,
                  ),
                ))
            .toList(),
      );
    });
  }

  Widget _buildKpiItem({
    required String label,
    required String valueEgp,
    required String valueFc,
    required IconData icon,
    required Color color,
    required bool isDark,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: highlight
            ? (isDark ? color.withOpacity(0.2) : color.withOpacity(0.08))
            : (isDark ? AppTheme.darkElevatedSurface : Colors.white),
        border: Border.all(
          color: highlight ? color : color.withOpacity(isDark ? 0.4 : 0.25),
          width: highlight ? 1.5 : 1.0,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkTextSecondary : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            valueEgp,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: highlight
                  ? color
                  : (isDark ? Colors.white : AppTheme.charcoal),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            valueFc,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildOverridesPanel(bool isDark) {
    return ExpansionTile(
      initiallyExpanded: false,
      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
      childrenPadding: const EdgeInsets.all(12),
      backgroundColor:
          isDark ? AppTheme.darkElevatedSurface : const Color(0xFFF8FAFC),
      collapsedBackgroundColor:
          isDark ? AppTheme.darkElevatedSurface : const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
      ),
      leading: const Icon(Icons.tune, color: AppTheme.cobalt, size: 20),
      title: const Text(
        'تعديل معايير ومصاريف المحاكاة (Parameters & Cost Overrides)',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      ),
      subtitle: const Text(
        'يمكنك تعديل أسعار الصرف، نولون الشحن، التأمين، التخليص، وتفضيل التوزيع وإعادة الحساب فورياً',
        style: TextStyle(fontSize: 11, color: Colors.grey),
      ),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildOverrideField('سعر الصرف ج.م', _fxRateController, 'مثال: 50.5'),
            _buildOverrideField(
                'نولون الشحن (EGP)', _freightController, 'تعديل النولون'),
            _buildOverrideField(
                'التأمين البحري (EGP)', _insuranceController, 'تعديل التأمين'),
            _buildOverrideField(
                'أتعاب التخليص (EGP)', _clearanceController, '4500'),
            _buildOverrideField(
                'مصاريف الموانئ (EGP)', _portController, '5000'),
            _buildOverrideField(
                'النقل الداخلي (EGP)', _transportController, '7500'),
            _buildOverrideField('مصاريف بنكية (EGP)', _bankFeesController, '2500'),
            _buildOverrideField(
                'مصاريف أخرى (EGP)', _otherFeesController, '2000'),
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<String>(
                value: _selectedAllocation,
                decoration: const InputDecoration(
                  labelText: 'أساس توزيع المصاريف',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  isDense: true,
                ),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'Value-Based', child: Text('حسب القيمة (Value)')),
                  DropdownMenuItem(
                      value: 'Weight-Based', child: Text('حسب الوزن (Weight)')),
                  DropdownMenuItem(
                      value: 'Volume-Based', child: Text('حسب الحجم (Volume)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedAllocation = val;
                    });
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: () {
                _fxRateController.clear();
                _freightController.clear();
                _insuranceController.clear();
                _clearanceController.clear();
                _portController.clear();
                _transportController.clear();
                _bankFeesController.clear();
                _otherFeesController.clear();
                _selectedAllocation = 'Value-Based';
                _loadSimulation();
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('استعادة القيم الافتراضية'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.cobalt,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: _loadSimulation,
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text(
                'إعادة الحساب والتوزيع',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverrideField(
      String label, TextEditingController ctrl, String hint) {
    return SizedBox(
      width: 150,
      child: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildItemsTable(bool isDark) {
    if (_data!.itemsBreakdown.isEmpty) {
      return const Center(child: Text('لا توجد بنود متاحة للمحاكاة'));
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                isDark ? AppTheme.darkElevatedSurface : const Color(0xFFF1F5F9),
              ),
              columnSpacing: 16,
              horizontalMargin: 12,
              dataRowMinHeight: 40,
              dataRowMaxHeight: 44,
              columns: const [
                DataColumn(label: Text('م', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('كود الصنف', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('اسم الصنف والوصف', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('البند الجمركي', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('الكمية', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('سعر FOB للوحدة', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('إجمالي FOB ج.م', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('ضريبة الوارد ج.م', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('الضرائب والقيمة المضافة', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('نولون ولوجستيات', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('إجمالي التكلفة ج.م', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('تكلفة الوحدة ج.م', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('تكلفة الوحدة أجنبي', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('معامل الزيادة', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('نسبة الزيادة', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: _data!.itemsBreakdown.map((itm) {
                return DataRow(cells: [
                  DataCell(Text('${itm.lineNo}')),
                  DataCell(Text(itm.itemCode, style: const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(Text(itm.itemName)),
                  DataCell(Text(itm.hsCode, style: const TextStyle(fontFamily: 'monospace'))),
                  DataCell(Text('${itm.qty}')),
                  DataCell(Text('${itm.unitPriceFc.toStringAsFixed(2)} ${_data!.currency}')),
                  DataCell(Text(itm.fobTotalEgp.toStringAsFixed(2))),
                  DataCell(Text(itm.allocatedCustomsDutyEgp.toStringAsFixed(2))),
                  DataCell(Text(itm.allocatedVatEgp.toStringAsFixed(2))),
                  DataCell(Text(
                      (itm.allocatedFreightEgp + itm.allocatedClearanceAndPortEgp + itm.allocatedInlandTransportEgp)
                          .toStringAsFixed(2))),
                  DataCell(Text(
                    itm.totalLandedCostEgp.toStringAsFixed(2),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald),
                  )),
                  DataCell(Text(
                    itm.unitLandedCostEgp.toStringAsFixed(2),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt),
                  )),
                  DataCell(Text(
                    '${itm.unitLandedCostFc.toStringAsFixed(2)} ${_data!.currency}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )),
                  DataCell(Text(
                    '×${itm.markupFactor.toStringAsFixed(3)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
                  )),
                  DataCell(Text(
                    '+${itm.markupPercent.toStringAsFixed(1)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
                  )),
                ]);
              }).toList(),
            ),
          ),
        ),
    );
  }

  Widget _buildExpensesTable(bool isDark) {
    if (_data!.expensesBreakdown.isEmpty) {
      return const Center(child: Text('لا توجد مصاريف مفصلة'));
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                isDark ? AppTheme.darkElevatedSurface : const Color(0xFFF1F5F9),
              ),
              columns: const [
                DataColumn(label: Text('فئة المصروف', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('البيان والوصف', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('القيمة بالجنيه (EGP)', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('القيمة بالعملة الأجنبية', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('مصدر الاحتساب', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('طريقة التوزيع على البنود', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: _data!.expensesBreakdown.map((exp) {
                return DataRow(cells: [
                  DataCell(Text(exp.category, style: const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(Text(exp.description)),
                  DataCell(Text(
                    exp.amountEgp.toStringAsFixed(2),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                  )),
                  DataCell(Text(
                    '${exp.amountFc.toStringAsFixed(2)} ${exp.currency}',
                  )),
                  DataCell(Text(exp.source)),
                  DataCell(Text(exp.allocationRule)),
                ]);
              }).toList(),
            ),
          ),
        ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkElevatedSurface : Colors.grey.shade100,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emerald,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onPressed: _data == null ? null : _exportCsv,
                icon: const Icon(Icons.file_download, size: 18),
                label: const Text('تصدير تقرير Excel/CSV'),
              ),
              OutlinedButton.icon(
                onPressed: _data == null ? null : _copyTsvToClipboard,
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('نسخ جدول النتائج (TSV)'),
              ),
            ],
          ),
          TextButton(
            onPressed: () => UnsavedChangesGuard.maybePop(context, isDirty: _isDirty),
            child: const Text('إغلاق', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
