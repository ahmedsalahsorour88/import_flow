import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

void showDualClockRadarDialog(BuildContext context, WidgetRef ref, {
  required int trackingId,
  required String billOfLadingNo,
  required String carrierName,
}) {
  showDialog(
    context: context,
    builder: (ctx) => DualClockRadarDialog(
      trackingId: trackingId,
      billOfLadingNo: billOfLadingNo,
      carrierName: carrierName,
    ),
  );
}

class DualClockRadarDialog extends ConsumerStatefulWidget {
  final int trackingId;
  final String billOfLadingNo;
  final String carrierName;

  const DualClockRadarDialog({
    super.key,
    required this.trackingId,
    required this.billOfLadingNo,
    required this.carrierName,
  });

  @override
  ConsumerState<DualClockRadarDialog> createState() => _DualClockRadarDialogState();
}

class _DualClockRadarDialogState extends ConsumerState<DualClockRadarDialog> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _data;

  // Gate-out controllers
  final _containerController = TextEditingController();
  final _eirController = TextEditingController();
  DateTime? _gateOutDate;
  DateTime? _emptyReturnDate;
  bool _isSubmittingGateOut = false;

  @override
  void initState() {
    super.initState();
    _fetchDualClockData();
  }

  @override
  void dispose() {
    _containerController.dispose();
    _eirController.dispose();
    super.dispose();
  }

  Future<void> _fetchDualClockData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/demurrage-detention/trackings/${widget.trackingId}/dual-clock');
      if (mounted) {
        setState(() {
          _data = res.data is Map<String, dynamic> ? res.data : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitContainerGateOut() async {
    if (_containerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال رقم الحاوية')),
      );
      return;
    }

    setState(() => _isSubmittingGateOut = true);
    try {
      final dio = ref.read(dioProvider);
      final containerNo = _containerController.text.trim();
      final payload = {
        'gate_out_date': _gateOutDate?.toIso8601String().split('T').first,
        'empty_return_date': _emptyReturnDate?.toIso8601String().split('T').first,
        'eir_number': _eirController.text.trim().isNotEmpty ? _eirController.text.trim() : null,
      };

      await dio.patch(
        '/demurrage-detention/trackings/${widget.trackingId}/containers/$containerNo',
        data: payload,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.emerald,
            content: Text('تم تثبيت بيانات خروج الحاوية $containerNo بنجاح'),
          ),
        );
        _containerController.clear();
        _eirController.clear();
        _gateOutDate = null;
        _emptyReturnDate = null;
        _fetchDualClockData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppTheme.crimson, content: Text('فشل حفظ البيانات: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingGateOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 820,
        padding: const EdgeInsets.all(24),
        child: _isLoading
            ? const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              )
            : _error != null
                ? SizedBox(
                    height: 250,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: AppTheme.crimson, size: 48),
                          const SizedBox(height: 12),
                          Text(_error!, style: const TextStyle(color: AppTheme.crimson)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _fetchDualClockData,
                            child: const Text('إعادة المحاولة'),
                          )
                        ],
                      ),
                    ),
                  )
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final carrierClock = _data?['carrier_clock'] as Map<String, dynamic>? ?? {};
    final portClock = _data?['port_storage_clock'] as Map<String, dynamic>? ?? {};
    final bool warning72h = portClock['warning_72h_active'] == true;
    final String portAdvice = portClock['urgent_advice_ar'] ?? '';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.cobalt.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.speed_rounded, color: AppTheme.cobalt, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'رادار المتابعة المزدوج: غرامات التأخير وأرضيات الميناء (Dual-Clock Radar)',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                    ),
                    Text(
                      'بوليصة الشحن: ${widget.billOfLadingNo}  •  الخط الملاحي: ${widget.carrierName}',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 72-Hour Warning Alert
          if (warning72h)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.orange, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppTheme.orange, size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '⚠️ تحذير حاسم: متبقي أقل من 72 ساعة على مضاعفة شريحة أرضيات ساحة الميناء!',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.orange, fontSize: 13.5),
                        ),
                        if (portAdvice.isNotEmpty)
                          Text(portAdvice, style: TextStyle(color: Colors.grey.shade800, fontSize: 12.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Dual Clocks (Side-by-Side)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Clock 1: Carrier Demurrage (USD)
              Expanded(
                child: _buildClockCard(
                  title: 'غرامات التوكيل الملاحي (Demurrage)',
                  currencySymbol: '\$',
                  currencyCode: 'USD',
                  totalAmount: (carrierClock['total_accrued_demurrage_usd'] as num?)?.toDouble() ?? 0.0,
                  freeDays: carrierClock['demurrage_free_days'] ?? 0,
                  overdueDays: carrierClock['demurrage_overdue_days'] ?? 0,
                  dailyRate: (carrierClock['daily_rate_usd'] as num?)?.toDouble() ?? 0.0,
                  statusNote: carrierClock['is_demurrage_overdue'] == true
                      ? 'تجاوزت فترة السماح (${carrierClock['demurrage_overdue_days']} يوم)'
                      : 'في نطاق السماح (متبقي ${carrierClock['free_days_remaining']} يوم)',
                  isDanger: carrierClock['is_demurrage_overdue'] == true,
                  icon: Icons.directions_boat_outlined,
                  accentColor: AppTheme.cobalt,
                ),
              ),
              const SizedBox(width: 16),

              // Clock 2: Port Storage (EGP)
              Expanded(
                child: _buildClockCard(
                  title: 'أرضيات هيئة الميناء (Port Storage)',
                  currencySymbol: 'ج.م',
                  currencyCode: 'EGP',
                  totalAmount: (portClock['total_accrued_storage_egp'] as num?)?.toDouble() ?? 0.0,
                  freeDays: portClock['port_storage_free_days'] ?? 0,
                  overdueDays: portClock['storage_overdue_days'] ?? 0,
                  dailyRate: (portClock['current_tier_rate_egp'] as num?)?.toDouble() ?? 0.0,
                  statusNote: 'الشريحة الحالية: ${portClock['current_tier_name'] ?? 'شريحة اعتيادية'}',
                  isDanger: portClock['is_storage_overdue'] == true,
                  icon: Icons.warehouse_outlined,
                  accentColor: AppTheme.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Partial Gate-Out Section (LOG-CONT-002)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_shipping_outlined, color: AppTheme.charcoal, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'التتبع المنفصل وخروج الحاويات الجزئي (Container Gate-Out & EIR)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _containerController,
                        decoration: const InputDecoration(
                          labelText: 'رقم الحاوية (مثلاً MSKU1234567)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _eirController,
                        decoration: const InputDecoration(
                          labelText: 'رقم إيصال الفحص EIR',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _isSubmittingGateOut ? null : _submitContainerGateOut,
                      icon: _isSubmittingGateOut
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('تثبيت الخروج'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClockCard({
    required String title,
    required String currencySymbol,
    required String currencyCode,
    required double totalAmount,
    required int freeDays,
    required int overdueDays,
    required double dailyRate,
    required String statusNote,
    required bool isDanger,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDanger ? AppTheme.crimson.withOpacity(0.5) : Colors.grey.shade200,
          width: isDanger ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.grey.shade800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '$currencySymbol ${totalAmount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: isDanger ? AppTheme.crimson : AppTheme.charcoal,
            ),
          ),
          Text(
            currencyCode,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text('أيام السماح: $freeDays يوم', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'أيام التجاوز: $overdueDays يوم',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDanger ? AppTheme.crimson : Colors.grey.shade700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),
          Text('المعدل اليومي: $currencySymbol ${dailyRate.toStringAsFixed(2)}', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDanger ? AppTheme.crimson.withOpacity(0.1) : AppTheme.emerald.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              statusNote,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: isDanger ? AppTheme.crimson : AppTheme.emerald,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
