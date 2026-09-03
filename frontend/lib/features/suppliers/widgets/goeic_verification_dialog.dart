import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

void showGOEICVerificationDialog(BuildContext context, WidgetRef ref, {
  required int supplierId,
  required String supplierName,
}) {
  showDialog(
    context: context,
    builder: (ctx) => GOEICVerificationDialog(
      supplierId: supplierId,
      supplierName: supplierName,
    ),
  );
}

class GOEICVerificationDialog extends ConsumerStatefulWidget {
  final int supplierId;
  final String supplierName;

  const GOEICVerificationDialog({
    super.key,
    required this.supplierId,
    required this.supplierName,
  });

  @override
  ConsumerState<GOEICVerificationDialog> createState() => _GOEICVerificationDialogState();
}

class _GOEICVerificationDialogState extends ConsumerState<GOEICVerificationDialog> {
  final _hsCodeController = TextEditingController(text: '8415820010');
  final _coiAgencyController = TextEditingController(text: 'SGS');
  final _coiNumberController = TextEditingController(text: 'SGS-CN-2026-9901');
  bool _hasCoi = true;
  bool _isChecking = false;
  String? _error;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _checkCompliance();
  }

  @override
  void dispose() {
    _hsCodeController.dispose();
    _coiAgencyController.dispose();
    _coiNumberController.dispose();
    super.dispose();
  }

  Future<void> _checkCompliance() async {
    setState(() {
      _isChecking = true;
      _error = null;
    });

    try {
      final dio = ref.read(dioProvider);
      final payload = {
        'supplier_id': widget.supplierId,
        'hs_code': _hsCodeController.text.trim(),
        'has_coi_certificate': _hasCoi,
        if (_hasCoi) 'coi_agency': _coiAgencyController.text.trim(),
        if (_hasCoi) 'coi_number': _coiNumberController.text.trim(),
      };

      final res = await dio.post('/integrations/goeic/verify-compliance', data: payload);
      if (mounted) {
        setState(() {
          _result = res.data is Map<String, dynamic> ? res.data : null;
          _isChecking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 780,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
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
                      color: AppTheme.emerald.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.verified_user_outlined, color: AppTheme.emerald, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'بوابة فحص الرقابة على الصادرات والواردات (GOEIC Compliance Hub)',
                          style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                        ),
                        Text(
                          'المصنع / المورد: ${widget.supplierName}',
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
              const SizedBox(height: 18),

              // Inputs Form
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _hsCodeController,
                            decoration: const InputDecoration(
                              labelText: 'بند التعريفة الجمركية (HS Code)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          children: [
                            Checkbox(
                              value: _hasCoi,
                              onChanged: (val) => setState(() => _hasCoi = val ?? false),
                            ),
                            const Text('شهادة فحص مسبق (COI)', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _isChecking ? null : _checkCompliance,
                          icon: _isChecking
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.search, size: 18),
                          label: const Text('فحص المطابقة'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.cobalt,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                    if (_hasCoi) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _coiAgencyController,
                              decoration: const InputDecoration(
                                labelText: 'شركة التفتيش (SGS, Bureau Veritas, TUV, Cotecna)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _coiNumberController,
                              decoration: const InputDecoration(
                                labelText: 'رقم شهادة الفحص (COI Number)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Results
              if (_isChecking)
                const SizedBox(height: 150, child: Center(child: CircularProgressIndicator()))
              else if (_error != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.crimson),
                  ),
                  child: Text('خطأ في الفحص: $_error', style: const TextStyle(color: AppTheme.crimson)),
                )
              else if (_result != null)
                _buildVerdictCard(_result!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerdictCard(Map<String, dynamic> res) {
    final verdict = res['overall_compliance_verdict'] ?? '';
    final isDecree43 = res['is_decree_43_mandated'] == true;
    final isRegistered = res['is_factory_registered'] == true;
    final regNo = res['factory_registration_number'] ?? 'غير متوفر';
    final warning = res['warning_message_ar'] as String?;
    final action = res['recommended_action_ar'] ?? '';

    Color verdictColor;
    IconData verdictIcon;
    String verdictTitle;

    if (verdict == 'BLOCKED_DECREE_43_VIOLATION') {
      verdictColor = AppTheme.crimson;
      verdictIcon = Icons.gpp_bad_outlined;
      verdictTitle = '⛔ محظور: انتهاك القرار 43 لسنة 2016 (المصنع غير مقيد بالقائمة البيضاء)';
    } else if (verdict == 'PENDING_COI_CERTIFICATE') {
      verdictColor = AppTheme.orange;
      verdictIcon = Icons.pending_actions_outlined;
      verdictTitle = '⚠️ معلق: المصنع مقيد ولكن يشترط إرفاق شهادة فحص ما قبل الشحن (COI)';
    } else {
      verdictColor = AppTheme.emerald;
      verdictIcon = Icons.verified_outlined;
      verdictTitle = '✅ مصرح بالشحن: الشحنة والمصنع مستوفيان لكافة اشتراطات الرقابة (GOEIC)';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: verdictColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: verdictColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(verdictIcon, color: verdictColor, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  verdictTitle,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: verdictColor),
                ),
              ),
            ],
          ),
          const Divider(height: 22),
          Row(
            children: [
              Expanded(
                child: Text('خضوع الصنف للقرار 43: ${isDecree43 ? 'نعم (إلزامي)' : 'لا'}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
              ),
              Expanded(
                child: Text('قيد المصنع بالهيئة: ${isRegistered ? 'مسجل ✅ ($regNo)' : 'غير مسجل ❌'}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
              ),
            ],
          ),
          if (warning != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: verdictColor.withOpacity(0.4)),
              ),
              child: Text(warning, style: TextStyle(color: verdictColor, fontSize: 13, height: 1.4)),
            ),
          ],
          const SizedBox(height: 12),
          Text('الإجراء الموصى به: $action',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade900)),
        ],
      ),
    );
  }
}
