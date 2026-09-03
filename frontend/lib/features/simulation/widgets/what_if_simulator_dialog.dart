import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../import_files/providers/import_files_provider.dart';

class WhatIfSimulatorDialog extends ConsumerStatefulWidget {
  final int? initialImportFileId;

  const WhatIfSimulatorDialog({
    super.key,
    this.initialImportFileId,
  });

  @override
  ConsumerState<WhatIfSimulatorDialog> createState() => _WhatIfSimulatorDialogState();
}

class _WhatIfSimulatorDialogState extends ConsumerState<WhatIfSimulatorDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  // Controls state
  int? _selectedImportFileId;
  final TextEditingController _invoiceAmountCtrl = TextEditingController(text: '25000');
  final TextEditingController _freightCtrl = TextEditingController(text: '2000');
  String _selectedCurrency = 'USD';
  double _fxRateChangePct = 0.0;
  double _baseRate = 49.50;
  String _shippingRoute = 'RED_SEA'; // RED_SEA or CAPE_OF_GOOD_HOPE
  int _portDelayDays = 0;
  int _containerCount = 1;
  double _dutyRatePct = 5.0;

  bool _isSimulating = false;
  Map<String, dynamic>? _simulationResult;

  // FX Exposure state
  bool _isLoadingExposure = false;
  Map<String, dynamic>? _exposureData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedImportFileId = widget.initialImportFileId;
    _fetchExposure();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _invoiceAmountCtrl.dispose();
    _freightCtrl.dispose();
    super.dispose();
  }

  void _onImportFileSelected(int? fileId) {
    setState(() => _selectedImportFileId = fileId);
    if (fileId == null) return;

    final filesAsync = ref.read(importFilesProvider);
    filesAsync.whenData((files) {
      final match = files.firstWhere(
        (f) => f.importFileId == fileId,
        orElse: () => files.first,
      );
      if (match.importFileId == fileId) {
        setState(() {
          if (match.estimatedCost > 0) {
            _invoiceAmountCtrl.text = match.estimatedCost.toStringAsFixed(0);
          }
          if (match.estimatedCostCurrency.isNotEmpty) {
            _selectedCurrency = match.estimatedCostCurrency.toUpperCase();
            if (_selectedCurrency == 'EUR') _baseRate = 53.80;
            if (_selectedCurrency == 'CNY') _baseRate = 6.90;
            if (_selectedCurrency == 'USD') _baseRate = 49.50;
          }
        });
      }
    });
  }

  Future<void> _runSimulation() async {
    setState(() => _isSimulating = true);
    try {
      final invAmount = double.tryParse(_invoiceAmountCtrl.text.trim()) ?? 0.0;
      final freight = double.tryParse(_freightCtrl.text.trim()) ?? 0.0;

      final payload = {
        'import_file_id': _selectedImportFileId,
        'invoice_amount': invAmount,
        'currency': _selectedCurrency,
        'base_exchange_rate': _baseRate,
        'exchange_rate_change_pct': _fxRateChangePct,
        'freight_fcy': freight,
        'insurance_fcy': 150.0,
        'shipping_route': _shippingRoute,
        'port_storage_delay_days': _portDelayDays,
        'container_count': _containerCount,
        'duty_rate_pct': _dutyRatePct,
        'vat_rate_pct': 14.0,
        'acid_issuance_date': DateTime.now().subtract(const Duration(days: 90)).toIso8601String().substring(0, 10),
        'current_eta': DateTime.now().add(const Duration(days: 20)).toIso8601String().substring(0, 10),
      };

      final res = await _dio.post(
        '${ApiConstants.simulation}/what-if',
        data: payload,
      );

      if (res.statusCode == 200) {
        setState(() => _simulationResult = res.data as Map<String, dynamic>);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تشغيل المحاكاة: $e'),
            backgroundColor: AppTheme.crimson,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSimulating = false);
    }
  }

  Future<void> _fetchExposure() async {
    setState(() => _isLoadingExposure = true);
    try {
      final res = await _dio.get('${ApiConstants.simulation}/fx-exposure');
      if (res.statusCode == 200) {
        setState(() => _exposureData = res.data as Map<String, dynamic>);
      }
    } catch (_) {
      // Graceful fallback
    } finally {
      if (mounted) setState(() => _isLoadingExposure = false);
    }
  }

  Future<void> _saveCurrentScenario() async {
    if (_simulationResult == null) return;
    try {
      final invAmount = double.tryParse(_invoiceAmountCtrl.text.trim()) ?? 0.0;
      final payload = {
        'scenario_name': 'سيناريو محاكاة ${_selectedCurrency} (+${_fxRateChangePct.toStringAsFixed(0)}%) - ${_shippingRoute == "CAPE_OF_GOOD_HOPE" ? "رأس الرجاء الصالح" : "البحر الأحمر"}',
        'import_file_id': _selectedImportFileId,
        'simulation_request': {
          'invoice_amount': invAmount,
          'currency': _selectedCurrency,
          'base_exchange_rate': _baseRate,
          'exchange_rate_change_pct': _fxRateChangePct,
          'shipping_route': _shippingRoute,
          'port_storage_delay_days': _portDelayDays,
          'container_count': _containerCount,
        },
        'simulation_result': _simulationResult,
      };

      final res = await _dio.post(
        '${ApiConstants.simulation}/saved-scenarios',
        data: payload,
      );

      if (res.statusCode == 201 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم حفظ سيناريو المحاكاة بنجاح في سجل القرارات الاستراتيجية.'),
            backgroundColor: AppTheme.emerald,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حفظ السيناريو: $e'),
            backgroundColor: AppTheme.crimson,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 1160,
        height: 780,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildTabBar(),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSimulatorTab(),
                  _buildExposureRadarTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.cobaltLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.analytics_outlined, color: AppTheme.cobalt, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'محاكي مخاطر الشحن وتغيرات أسعار الصرف والأزمات (SIM-WHATIF-013)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'دراسة السيناريوهات الطارئة لتغيرات سعر الدولار الجمركي، التفاف السفن حول إفريقيا، وتراكم غرامات الميناء',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'إغلاق',
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.charcoal,
        indicator: BoxDecoration(
          color: AppTheme.cobalt,
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [
          Tab(
            icon: Icon(Icons.tune),
            text: 'محاكي السيناريوهات الحية (Live What-If Simulator)',
          ),
          Tab(
            icon: Icon(Icons.radar),
            text: 'رادار الانكشاف المالي بالعملات الأجنبية (FX Exposure)',
          ),
        ],
      ),
    );
  }

  Widget _buildSimulatorTab() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Parameters
        SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('1. تحديد مدخلات الشحنة والعملة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    _buildImportFileSelector(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _invoiceAmountCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'قيمة الفاتورة (FOB)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            value: _selectedCurrency,
                            decoration: const InputDecoration(
                              labelText: 'العملة',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'USD', child: Text('USD')),
                              DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                              DropdownMenuItem(value: 'CNY', child: Text('CNY')),
                              DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedCurrency = val;
                                  if (val == 'USD') _baseRate = 49.50;
                                  if (val == 'EUR') _baseRate = 53.80;
                                  if (val == 'CNY') _baseRate = 6.90;
                                  if (val == 'GBP') _baseRate = 64.20;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _freightCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'تكلفة النولون البحري/الجوي ($_selectedCurrency)',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text('2. محاكاة صدمة سعر الصرف (FX Shock):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('السعر الأساسي: ${_baseRate.toStringAsFixed(2)} ج.م', style: const TextStyle(fontSize: 12)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _fxRateChangePct > 0 ? Colors.red.shade50 : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _fxRateChangePct > 0 ? AppTheme.crimson : AppTheme.emerald),
                          ),
                          child: Text(
                            'المحاكى: ${(_baseRate * (1 + _fxRateChangePct / 100)).toStringAsFixed(2)} ج.م (${_fxRateChangePct > 0 ? "+" : ""}${_fxRateChangePct.toStringAsFixed(0)}%)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: _fxRateChangePct > 0 ? AppTheme.crimson : AppTheme.emerald,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _fxRateChangePct,
                      min: -10.0,
                      max: 60.0,
                      divisions: 14,
                      activeColor: _fxRateChangePct > 0 ? AppTheme.crimson : AppTheme.cobalt,
                      label: '${_fxRateChangePct.toStringAsFixed(0)}%',
                      onChanged: (val) => setState(() => _fxRateChangePct = val),
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text('3. مسار الشحن ومخاطر البحر الأحمر:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _shippingRoute,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'RED_SEA',
                          child: Text('مسار البحر الأحمر وقناة السويس (طبيعي)', overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: 'CAPE_OF_GOOD_HOPE',
                          child: Text('التفاف رأس الرجاء الصالح (+18 يوم / +25% نولون)', overflow: TextOverflow.ellipsis),
                        ),
                      ],
                      onChanged: (val) => setState(() => _shippingRoute = val ?? 'RED_SEA'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('تأخير الميناء: $_portDelayDays يوم', style: const TextStyle(fontSize: 12)),
                              Slider(
                                value: _portDelayDays.toDouble(),
                                min: 0.0,
                                max: 30.0,
                                divisions: 30,
                                label: '$_portDelayDays يوم',
                                onChanged: (val) => setState(() => _portDelayDays = val.toInt()),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _containerCount,
                            decoration: const InputDecoration(
                              labelText: 'الحاويات',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: [1, 2, 3, 4, 5, 10].map((c) => DropdownMenuItem(value: c, child: Text('$c حاوية'))).toList(),
                            onChanged: (val) => setState(() => _containerCount = val ?? 1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSimulating ? null : _runSimulation,
                        icon: _isSimulating
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.play_arrow),
                        label: const Text('تشغيل المحاكاة الآن', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.cobalt,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Right Column: Output Matrix
        Expanded(
          child: _simulationResult == null
              ? _buildPlaceholderGuide()
              : _buildSimulationOutput(),
        ),
      ],
    );
  }

  Widget _buildImportFileSelector() {
    final filesAsync = ref.watch(importFilesProvider);
    return filesAsync.when(
      data: (files) {
        return SearchableDropdownField<int>(
          labelText: 'اختر الشحنة للمحاكاة (اختياري)',
          hintText: 'ابحث برقم الملف أو الشركة...',
          items: files
              .map((f) => SearchableDropdownItem<int>(
                    value: f.importFileId,
                    label: '${f.importFileCode} - ${f.companyName} (${f.estimatedCost} ${f.estimatedCostCurrency})',
                  ))
              .toList(),
          value: _selectedImportFileId,
          onChanged: _onImportFileSelected,
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildPlaceholderGuide() {
    return Center(
      child: Card(
        elevation: 0,
        color: Colors.grey.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.query_stats, size: 56, color: AppTheme.cobalt.withOpacity(0.6)),
              const SizedBox(height: 16),
              const Text(
                'جاهز لمحاكاة صدمات أسعار الصرف والأزمات اللوجستية',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.charcoal),
              ),
              const SizedBox(height: 8),
              const SizedBox(
                width: 480,
                child: Text(
                  'اضبط المتغيرات على الجانب الأيسر واضغط "تشغيل المحاكاة" لرؤية الأثر الفوري على الوعاء الضريبي، تكلفة الوصول (Landed Cost)، غرامات الأرضيات، ومخاطر انتهاء صلاحية الـ ACID.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimulationOutput() {
    final res = _simulationResult!;
    final base = res['baseline_summary'] as Map<String, dynamic>;
    final sim = res['simulated_summary'] as Map<String, dynamic>;
    final varMap = res['variances'] as Map<String, dynamic>;
    final acid = res['acid_risk_analysis'] as Map<String, dynamic>;
    final dem = res['demurrage_and_storage'] as Map<String, dynamic>;
    final recommendations = (res['hedging_recommendations'] as List<dynamic>?) ?? [];
    final riskLevel = res['risk_level'] as String? ?? 'LOW';

    Color riskColor = AppTheme.emerald;
    if (riskLevel == 'CRITICAL') riskColor = AppTheme.crimson;
    if (riskLevel == 'HIGH') riskColor = AppTheme.orange;
    if (riskLevel == 'MEDIUM') riskColor = Colors.amber.shade700;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar: Risk Level & Save
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: riskColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: riskColor, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'مستوى المخاطر المالي والتشغيلي: $riskLevel',
                      style: TextStyle(color: riskColor, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _saveCurrentScenario,
                icon: const Icon(Icons.bookmark_add_outlined),
                label: const Text('حفظ السيناريو في سجل القرارات'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Primary Metric: Landed Cost Variance
          Card(
            elevation: 0,
            color: AppTheme.cobaltLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppTheme.cobaltBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('تكلفة الوصول الشاملة الأصلية (Baseline):', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('${(base['total_landed_cost_egp'] as num).toStringAsFixed(2)} ج.م',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward, color: Colors.grey),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('التكلفة بعد تطبيق المحاكاة (Simulated):', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('${(sim['total_landed_cost_egp'] as num).toStringAsFixed(2)} ج.م',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: riskColor)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: riskColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '+${(varMap['landed_cost_variance_pct'] as num).toStringAsFixed(1)}%',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '+${(varMap['landed_cost_variance_egp'] as num).toStringAsFixed(0)} ج.م',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Secondary Metrics: Taxes & Demurrage
          Row(
            children: [
              Expanded(
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('فارق الجمارك والضرائب (EGP):', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          '+${((varMap['customs_duty_variance_egp'] as num) + (varMap['vat_variance_egp'] as num)).toStringAsFixed(2)} ج.م',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('غرامات التوكيل (USD):', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          '\$${(dem['demurrage_cost_usd'] as num).toStringAsFixed(0)} (${(dem['extra_demurrage_days'] as num)} يوم إضافي)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.crimson),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('أرضيات الميناء (EGP):', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          '${(dem['port_storage_cost_egp'] as num).toStringAsFixed(0)} ج.م',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.orange),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ACID Regulatory Expiry Card
          if (acid['status'] != 'NOT_APPLICABLE') ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: acid['status'] == 'EXPIRED_RISK' ? AppTheme.crimsonLight : (acid['status'] == 'CRITICAL_WINDOW' ? AppTheme.orangeLight : Colors.green.shade50),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: acid['status'] == 'EXPIRED_RISK' ? AppTheme.crimson : (acid['status'] == 'CRITICAL_WINDOW' ? AppTheme.orange : AppTheme.emerald),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    acid['status'] == 'EXPIRED_RISK' ? Icons.dangerous : (acid['status'] == 'CRITICAL_WINDOW' ? Icons.alarm : Icons.verified),
                    color: acid['status'] == 'EXPIRED_RISK' ? AppTheme.crimson : (acid['status'] == 'CRITICAL_WINDOW' ? AppTheme.orange : AppTheme.emerald),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'فحص صلاحية القيد الجمركي المسبق ACID (180 يوماً):',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: acid['status'] == 'EXPIRED_RISK' ? AppTheme.crimson : AppTheme.charcoal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          acid['message_ar'] as String? ?? '',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Strategic Advice & Hedging Actions
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.shield_outlined, color: AppTheme.cobalt),
                      SizedBox(width: 8),
                      Text('التوصيات الاستراتيجية والتحوط المالي:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...recommendations.map(
                    (rec) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt, fontSize: 16)),
                          Expanded(child: Text(rec.toString(), style: const TextStyle(fontSize: 12, height: 1.4))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExposureRadarTab() {
    if (_isLoadingExposure) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_exposureData == null) {
      return Center(
        child: ElevatedButton.icon(
          onPressed: _fetchExposure,
          icon: const Icon(Icons.refresh),
          label: const Text('تحديث بيانات الانكشاف المالي'),
        ),
      );
    }

    final data = _exposureData!;
    final items = (data['items'] as List<dynamic>?) ?? [];
    final advice = (data['strategic_advice'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exposure Metric Cards
          Row(
            children: [
              _buildMetricCard(
                title: 'إجمالي الالتزامات بالدولار',
                value: '\$${(data['total_open_usd'] as num).toStringAsFixed(2)}',
                color: AppTheme.cobalt,
                icon: Icons.attach_money,
              ),
              const SizedBox(width: 12),
              _buildMetricCard(
                title: 'إجمالي الالتزامات باليورو',
                value: '€${(data['total_open_eur'] as num).toStringAsFixed(2)}',
                color: AppTheme.orange,
                icon: Icons.euro,
              ),
              const SizedBox(width: 12),
              _buildMetricCard(
                title: 'القيمة الحالية بالجنيه',
                value: '${(data['total_open_egp_baseline'] as num).toStringAsFixed(0)} ج.م',
                color: AppTheme.charcoal,
                icon: Icons.account_balance,
              ),
              const SizedBox(width: 12),
              _buildMetricCard(
                title: 'خطر انخفاض 10% (VaR)',
                value: '+${(data['var_at_risk_10_pct'] as num).toStringAsFixed(0)} ج.م',
                color: AppTheme.crimson,
                icon: Icons.trending_up,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Strategic advice
          Card(
            elevation: 0,
            color: Colors.amber.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.amber.shade300),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ملاحظات وإرشادات إدارة الخزانة والتحوط:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  ...advice.map((adv) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• $adv', style: const TextStyle(fontSize: 12)),
                      )),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Table of open files
          const Text('تفاصيل الشحنات المفتوحة المعرضة لتقلبات الصرف:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
              columns: const [
                DataColumn(label: Text('رقم الشحنة')),
                DataColumn(label: Text('المورد الأجنبي')),
                DataColumn(label: Text('العملة')),
                DataColumn(label: Text('المبلغ المعلق')),
                DataColumn(label: Text('المعادل الحالي (EGP)')),
                DataColumn(label: Text('في سيناريو +10%')),
                DataColumn(label: Text('في سيناريو +25%')),
              ],
              rows: items.map((item) {
                return DataRow(cells: [
                  DataCell(Text(item['import_file_code'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(item['supplier_name'] ?? '')),
                  DataCell(Text(item['currency'] ?? '')),
                  DataCell(Text((item['open_exposure_fcy'] as num).toStringAsFixed(2))),
                  DataCell(Text((item['open_exposure_egp'] as num).toStringAsFixed(0))),
                  DataCell(Text(
                    (item['simulated_exposure_egp_at_plus_10_pct'] as num).toStringAsFixed(0),
                    style: const TextStyle(color: AppTheme.orange, fontWeight: FontWeight.w500),
                  )),
                  DataCell(Text(
                    (item['simulated_exposure_egp_at_plus_25_pct'] as num).toStringAsFixed(0),
                    style: const TextStyle(color: AppTheme.crimson, fontWeight: FontWeight.bold),
                  )),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  Icon(icon, size: 20, color: color),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
