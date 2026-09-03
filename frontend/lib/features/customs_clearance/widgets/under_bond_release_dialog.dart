import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

void showUnderBondReleaseDialog(BuildContext context, WidgetRef ref, {
  required int clearanceId,
  required String declarationNo,
  bool isAlreadyUnderBond = false,
  VoidCallback? onDone,
}) {
  showDialog(
    context: context,
    builder: (ctx) => UnderBondReleaseDialog(
      clearanceId: clearanceId,
      declarationNo: declarationNo,
      isAlreadyUnderBond: isAlreadyUnderBond,
      onDone: onDone,
    ),
  );
}

class UnderBondReleaseDialog extends ConsumerStatefulWidget {
  final int clearanceId;
  final String declarationNo;
  final bool isAlreadyUnderBond;
  final VoidCallback? onDone;

  const UnderBondReleaseDialog({
    super.key,
    required this.clearanceId,
    required this.declarationNo,
    this.isAlreadyUnderBond = false,
    this.onDone,
  });

  @override
  ConsumerState<UnderBondReleaseDialog> createState() => _UnderBondReleaseDialogState();
}

class _UnderBondReleaseDialogState extends ConsumerState<UnderBondReleaseDialog> {
  late bool _modeRecordLab;

  // Release Controllers
  final _bondRefController = TextEditingController(text: 'BOND-EG-2026-');
  final _quarantineLocController = TextEditingController(text: 'مخزن الشركة الرئيسي - السادس من أكتوبر');

  // Lab Controllers
  final _labCertController = TextEditingController(text: 'LAB-GOEIC-2026-');
  String _labVerdict = 'PASSED';
  final _remarksController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _modeRecordLab = widget.isAlreadyUnderBond;
  }

  @override
  void dispose() {
    _bondRefController.dispose();
    _quarantineLocController.dispose();
    _labCertController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _submitUnderBondRelease() async {
    if (_bondRefController.text.trim().isEmpty || _quarantineLocController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء رقم خطاب الضمان وموقع التحفظ')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final dio = ref.read(dioProvider);
      final payload = {
        'bond_guarantee_ref': _bondRefController.text.trim(),
        'quarantine_location': _quarantineLocController.text.trim(),
      };

      await dio.post('/customs-clearance/${widget.clearanceId}/under-bond-release', data: payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.orange,
            content: Text('تم السحب على عهدة تحت التحفظ بنجاح، وتفعيل قفل الحظر المخزني'),
          ),
        );
        widget.onDone?.call();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppTheme.crimson, content: Text('فشل الإجراء: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitLabResult() async {
    if (_labCertController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال رقم شهادة الفحص المعملي')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final dio = ref.read(dioProvider);
      final payload = {
        'lab_certificate_number': _labCertController.text.trim(),
        'is_lab_passed': _labVerdict == 'PASSED',
        'remarks': _remarksController.text.trim().isNotEmpty ? _remarksController.text.trim() : null,
      };

      await dio.post('/customs-clearance/${widget.clearanceId}/lab-inspection-result', data: payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _labVerdict == 'PASSED' ? AppTheme.emerald : AppTheme.crimson,
            content: Text(
              _labVerdict == 'PASSED'
                  ? 'تم فك التحفظ واعتماد المطابقة المعملية بنجاح ✅'
                  : 'تم تسجيل رفض العينة المعملية وإلزام إعادة التصدير ⛔',
            ),
          ),
        );
        widget.onDone?.call();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppTheme.crimson, content: Text('فشل تسجيل النتيجة: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 680,
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
                      color: AppTheme.orange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.lock_clock_outlined, color: AppTheme.orange, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'مسار الإفراج تحت التحفظ وقفل الفحص المعملي (Under-Bond Release)',
                          style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                        ),
                        Text(
                          'إقرار جمركي رقم 46: ${widget.declarationNo}',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
                ],
              ),
              const SizedBox(height: 18),

              // Mode Selector
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('سحب على عهدة (تحت التحفظ)'),
                    icon: Icon(Icons.assignment_returned_outlined),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('تسجيل نتيجة المعامل وفك الحظر'),
                    icon: Icon(Icons.science_outlined),
                  ),
                ],
                selected: {_modeRecordLab},
                onSelectionChanged: (val) => setState(() => _modeRecordLab = val.first),
              ),
              const SizedBox(height: 20),

              // Mode 1: Under-Bond Release Form
              if (!_modeRecordLab) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.orange.withOpacity(0.5)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.orange, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'يسمح هذا المسار بنقل البضاعة لمخزن المصنع تحت التحفظ الجمركي لحين صدور نتائج معامل الفحص والرقابة، مع إغلاق أذون الصرف بالمخازن آلياً.',
                          style: TextStyle(fontSize: 12.5, color: AppTheme.charcoal, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bondRefController,
                  decoration: const InputDecoration(
                    labelText: 'رقم خطاب الضمان البنكي / التعهد الجمركي',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _quarantineLocController,
                  decoration: const InputDecoration(
                    labelText: 'موقع مخزن التحفظ المعملي (مخازن المصنع)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitUnderBondRelease,
                  icon: _isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_circle_outline, color: Colors.white),
                  label: const Text('تأكيد السحب على عهدة وتفعيل القفل المخزني', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.orange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],

              // Mode 2: Lab Results & Lifting Form
              if (_modeRecordLab) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.cobalt.withOpacity(0.5)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.science_outlined, color: AppTheme.cobalt, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'تسجيل تقرير الفحص الصادر من المعامل المركزية (GOEIC / سلامة الغذاء / الطاقة الذرية). النتيجة الإيجابية تفك قفل الصرف وتتيح تشغيل البضاعة فوراً.',
                          style: TextStyle(fontSize: 12.5, color: AppTheme.charcoal, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _labCertController,
                  decoration: const InputDecoration(
                    labelText: 'رقم شهادة الفحص المعملي الصادرة',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _labVerdict,
                  decoration: const InputDecoration(
                    labelText: 'نتيجة الفحص المعملي',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'PASSED', child: Text('مطابق للمواصفات القياسية (PASSED) ✅')),
                    DropdownMenuItem(value: 'REJECTED', child: Text('غير مطابق ومرفوض نهائياً (REJECTED) ⛔')),
                  ],
                  onChanged: (v) => setState(() => _labVerdict = v ?? 'PASSED'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _remarksController,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات المعمل أو رقم قرار الإفراج النهائي',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitLabResult,
                  icon: _isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.verified, color: Colors.white),
                  label: Text(
                    _labVerdict == 'PASSED' ? 'اعتماد المطابقة وفك قفل الصرف المخزني' : 'تثبيت الرفض وحظر التشغيل',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _labVerdict == 'PASSED' ? AppTheme.emerald : AppTheme.crimson,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
