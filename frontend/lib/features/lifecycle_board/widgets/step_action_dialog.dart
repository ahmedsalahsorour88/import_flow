import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../models/lifecycle_board_model.dart';
import '../providers/lifecycle_board_provider.dart';

class StepActionDialog extends ConsumerStatefulWidget {
  final ShipmentStageCardModel shipment;
  final List<PhaseSummaryModel> allPhases;

  const StepActionDialog({
    super.key,
    required this.shipment,
    required this.allPhases,
  });

  @override
  ConsumerState<StepActionDialog> createState() => _StepActionDialogState();
}

class _StepActionDialogState extends ConsumerState<StepActionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _param1Controller = TextEditingController();
  final _param2Controller = TextEditingController();
  final _param3Controller = TextEditingController();

  final List<String> _selectedNextSteps = [];
  bool _isSaving = false;

  final Map<String, String> _allStepsMap = {
    'STEP_01': 'STEP_01: Freight Studies (دراسات النولون)',
    'STEP_02': 'STEP_02: Customs Studies (الدراسات الجمركية)',
    'STEP_03': 'STEP_03: Regulatory Reqs (اشتراطات الاستيراد)',
    'STEP_04': 'STEP_04: Finance Approvals (اعتماد الميزانية)',
    'STEP_05': 'STEP_05: ACID Operations (إصدار ACID)',
    'STEP_06': 'STEP_06: Freight Booking (حجز النولون)',
    'STEP_07': 'STEP_07: Freight Allocations (تخصيص الحاويات)',
    'STEP_08': 'STEP_08: Draft Docs Review (مراجعة المسودات)',
    'STEP_09': 'STEP_09: Docs Customs Approval (الاعتماد النهائي)',
    'STEP_10': 'STEP_10: CargoX Follow-up (رفع CargoX)',
    'STEP_11': 'STEP_11: Originals Collection (أصول المستندات)',
    'STEP_12': 'STEP_12: Bank Form 4 (نموذج 4 البنكي)',
    'STEP_13': 'STEP_13: Declaration 46 (إقرار 46 ك.م)',
    'STEP_14': 'STEP_14: Clearance Follow-up (الكشف والتثمين)',
    'STEP_15': 'STEP_15: Drawing Samples (سحب العينات)',
    'STEP_16': 'STEP_16: Cargo Discrepancy (محضر المعاينة)',
    'STEP_17': 'STEP_17: Final Calculation (سداد الرسوم)',
    'STEP_18': 'STEP_18: Demurrage & Detention (الأرضيات)',
    'STEP_19': 'STEP_19: Warehouse GRN (إذن الإضافة)',
    'STEP_20': 'STEP_20: Landed Cost (تسوية التكلفة)',
    'STEP_21': 'STEP_21: Final Closure (إغلاق الملف)',
  };

  @override
  void initState() {
    super.initState();
    _notesController.text = widget.shipment.notes ?? '';
    _initDefaultParams();
    _suggestNextSteps();
  }

  void _initDefaultParams() {
    switch (widget.shipment.stepCode) {
      case 'STEP_01':
        _param1Controller.text = 'MSC Mediterranean Shipping';
        _param2Controller.text = '2450.00';
        _param3Controller.text = '24 Days';
        break;
      case 'STEP_02':
        _param1Controller.text = '8471.30.00.00';
        _param2Controller.text = '5.0%';
        _param3Controller.text = '14.0%';
        break;
      case 'STEP_04':
        _param1Controller.text = '${widget.shipment.estimatedCost.toStringAsFixed(0)} ${widget.shipment.estimatedCostCurrency}';
        _param2Controller.text = 'National Bank of Egypt (NBE)';
        _param3Controller.text = 'SWIFT-NBE-2026-9811';
        break;
      case 'STEP_05':
        _param1Controller.text = '2026081700981234567';
        _param2Controller.text = '180 Days';
        _param3Controller.text = 'MFG-REG-IT-88412';
        break;
      case 'STEP_06':
        _param1Controller.text = 'BKG-MSC-9981204';
        _param2Controller.text = 'MSC Oscar';
        _param3Controller.text = '2x 40ft High Cube';
        break;
      case 'STEP_12':
        _param1Controller.text = 'F4-2026-88192';
        _param2Controller.text = 'CIB Egypt';
        _param3Controller.text = '${widget.shipment.estimatedCost.toStringAsFixed(0)} USD';
        break;
      case 'STEP_13':
        _param1Controller.text = '46-ALX-2026-7781';
        _param2Controller.text = 'Alexandria Port';
        _param3Controller.text = 'Al-Ahram Clearance Group';
        break;
      case 'STEP_19':
        _param1Controller.text = 'GRN-WH-2026-0045';
        _param2Controller.text = 'Main Cairo Warehouse';
        _param3Controller.text = 'Fully Received / Sound Condition';
        break;
      default:
        _param1Controller.text = 'REF-${widget.shipment.importFileCode}';
        _param2Controller.text = 'Standard Approval';
        _param3Controller.text = 'Completed in good order';
    }
  }

  void _suggestNextSteps() {
    final cur = widget.shipment.stepCode;
    final index = int.tryParse(cur.replaceAll('STEP_', '')) ?? 1;
    if (index < 21) {
      final nextCode = 'STEP_${(index + 1).toString().padLeft(2, '0')}';
      _selectedNextSteps.add(nextCode);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _param1Controller.dispose();
    _param2Controller.dispose();
    _param3Controller.dispose();
    super.dispose();
  }

  Future<void> _handleSaveAndAdvance() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final actionData = {
      'param1': _param1Controller.text.trim(),
      'param2': _param2Controller.text.trim(),
      'param3': _param3Controller.text.trim(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    final notifier = ref.read(lifecycleBoardActionProvider.notifier);
    final success = await notifier.advanceStep(
      importFileCode: widget.shipment.importFileCode,
      currentStepCode: widget.shipment.stepCode,
      nextStepCodes: _selectedNextSteps,
      notes: _notesController.text.trim(),
      actionData: actionData,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.emerald,
            content: Text(
              'تم حفظ الخطوة وتفعيل المراحل التالية (${_selectedNextSteps.join(', ')}) بنجاح للشحنة ${widget.shipment.importFileCode}.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.crimson,
            content: Text('حدث خطأ أثناء حفظ الخطوة. يرجى مراجعة الخادم.'),
          ),
        );
      }
    }
  }

  Future<void> _handleSkipStep() async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.fast_forward_rounded, color: AppTheme.orange),
            SizedBox(width: 8),
            Text('تخطي هذه المرحلة (Skip Step)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'هل أنت متأكد من تخطي الخطوة (${widget.shipment.stepNameAr}) للشحنة ${widget.shipment.importFileCode}؟',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'سبب التخطي (Skip Reason) *',
                    hintText: 'مثال: شحنة CIF - نولون مسدد، أو إعفاء من الـ ACID...',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'يلزم إدخال سبب التخطي' : null,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.orange),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            icon: const Icon(Icons.fast_forward_rounded, color: Colors.white, size: 18),
            label: const Text('تأكيد التخطي والترحيل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isSaving = true);
      final notifier = ref.read(lifecycleBoardActionProvider.notifier);
      final success = await notifier.skipStep(
        importFileCode: widget.shipment.importFileCode,
        currentStepCode: widget.shipment.stepCode,
        skipReason: reasonController.text.trim(),
        nextStepCodes: _selectedNextSteps,
      );
      if (mounted) {
        setState(() => _isSaving = false);
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.orange,
              content: Text(
                '⏭️ تم تخطي الخطوة بنجاح وتفعيل المراحل التالية (${_selectedNextSteps.join(', ')}) للشحنة ${widget.shipment.importFileCode}.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _handleHoldOrResume() async {
    final isOnHold = widget.shipment.status == 'On-Hold';
    if (isOnHold) {
      setState(() => _isSaving = true);
      final notifier = ref.read(lifecycleBoardActionProvider.notifier);
      final success = await notifier.setMultiActiveStages(
        importFileCode: widget.shipment.importFileCode,
        activeStepCodes: [widget.shipment.stepCode],
        notes: 'تم استئناف العمل على الشحنة من نفس المرحلة',
      );
      if (mounted) {
        setState(() => _isSaving = false);
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppTheme.emerald,
              content: Text('▶️ تم استئناف الشحنة ومواصلة دورة العمل بنجاح.'),
            ),
          );
        }
      }
    } else {
      final reasonController = TextEditingController();
      final formKey = GlobalKey<FormState>();

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.pause_circle_outline_rounded, color: AppTheme.crimson),
              SizedBox(width: 8),
              Text('إيقاف مؤقت / تعليق الشحنة (Put on Hold)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'سيتم تعليق الشحنة ${widget.shipment.importFileCode} مؤقتاً عند هذه الخطوة (${widget.shipment.stepNameAr}).',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: 'سبب الإيقاف المؤقت (Hold Reason) *',
                      hintText: 'مثال: في انتظار موافقة البنك، أو مراجعة مع المورد...',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'يلزم إدخال سبب الإيقاف' : null,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(ctx, true);
                }
              },
              icon: const Icon(Icons.pause_circle_filled_rounded, color: Colors.white, size: 18),
              label: const Text('تأكيد الإيقاف المؤقت', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        setState(() => _isSaving = true);
        final notifier = ref.read(lifecycleBoardActionProvider.notifier);
        final success = await notifier.advanceStep(
          importFileCode: widget.shipment.importFileCode,
          currentStepCode: widget.shipment.stepCode,
          nextStepCodes: [widget.shipment.stepCode],
          notes: 'On-Hold: ${reasonController.text.trim()}',
        );
        if (mounted) {
          setState(() => _isSaving = false);
          if (success) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: AppTheme.crimson,
                content: Text('⏸️ تم تعليق الشحنة مؤقتاً بنجاح.'),
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnHold = widget.shipment.status == 'On-Hold';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 780,
        constraints: const BoxConstraints(maxHeight: 720),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.cobalt.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.tune_outlined, color: AppTheme.cobalt, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'بطاقة تنفيذ الخطوة: ${widget.shipment.stepNameEn}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isOnHold ? AppTheme.crimson : AppTheme.cobalt,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isOnHold ? '${widget.shipment.stepCode} (On-Hold)' : widget.shipment.stepCode,
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          widget.shipment.stepNameAr,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
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
              const Divider(height: 24),

              // Body Form
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Shipment Info Pill
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            _buildInfoCol('ملف الشحنة', widget.shipment.importFileCode, isBold: true, color: AppTheme.cobalt),
                            _buildInfoCol('الشركة المستوردة', widget.shipment.companyName),
                            _buildInfoCol('المورد الأجنبي', widget.shipment.supplierName),
                            _buildInfoCol('أمر الشراء', widget.shipment.poNumber ?? 'N/A'),
                            _buildInfoCol('القيمة التقديرية', '${widget.shipment.estimatedCost.toStringAsFixed(0)} ${widget.shipment.estimatedCostCurrency}', isBold: true, color: AppTheme.emerald),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Step-Specific Parameters Form
                      const Text(
                        'بيانات ومتطلبات الخطوة التشغيلية الحالية:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _param1Controller,
                              decoration: InputDecoration(
                                labelText: _getParam1Label(widget.shipment.stepCode),
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'هذا الحقل إلزامي' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _param2Controller,
                              decoration: InputDecoration(
                                labelText: _getParam2Label(widget.shipment.stepCode),
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _param3Controller,
                        decoration: InputDecoration(
                          labelText: _getParam3Label(widget.shipment.stepCode),
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Next Step Multi-Target Picker (Supports Concurrent Multi-Stage)
                      const Text(
                        'المراحل التالية المستهدفة بعد الإنجاز (يمكن اختيار أكثر من مرحلة بالتوازي):',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                      ),
                      const SizedBox(height: 8),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _allStepsMap.entries.map((entry) {
                          final isSelected = _selectedNextSteps.contains(entry.key);
                          return FilterChip(
                            label: Text(
                              entry.value,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.white : AppTheme.charcoal,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppTheme.cobalt,
                            checkmarkColor: Colors.white,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedNextSteps.add(entry.key);
                                } else {
                                  _selectedNextSteps.remove(entry.key);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),

                      // Notes & Live Updates
                      const Text(
                        'ملاحظات وسجل التحديثات لهذه الخطوة:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'اكتب الملاحظات الفنية، التوجيهات أو المرجع التشغيلي...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 24),

              // Action Buttons with Skip and Hold/Resume
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.cancel_outlined, size: 16),
                        label: const Text('إغلاق'),
                      ),
                      const SizedBox(width: 8),
                      // Skip Step Button
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.orange,
                          side: const BorderSide(color: AppTheme.orange),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        onPressed: _isSaving ? null : _handleSkipStep,
                        icon: const Icon(Icons.fast_forward_rounded, size: 16),
                        label: const Text('تخطي المرحلة (Skip Step)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      // Hold / Resume Button
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isOnHold ? AppTheme.emerald : AppTheme.crimson,
                          side: BorderSide(color: isOnHold ? AppTheme.emerald : AppTheme.crimson),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        onPressed: _isSaving ? null : _handleHoldOrResume,
                        icon: Icon(isOnHold ? Icons.play_arrow_rounded : Icons.pause_circle_outline_rounded, size: 16),
                        label: Text(isOnHold ? 'استئناف الشحنة (Resume)' : 'إيقاف مؤقت (Hold)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emerald,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: _isSaving ? null : _handleSaveAndAdvance,
                    icon: _isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_outline, size: 18, color: Colors.white),
                    label: Text(
                      _isSaving ? 'جاري الحفظ والترحيل...' : 'اكتمال الخطوة وترحيل الشحنة',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCol(String label, String value, {bool isBold = false, Color? color}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? AppTheme.charcoal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getParam1Label(String stepCode) {
    switch (stepCode) {
      case 'STEP_01':
        return 'اسم الخط الملاحي / شركة الشحن المعتمدة';
      case 'STEP_02':
        return 'بند التعريفة الجمركية (HS Code)';
      case 'STEP_03':
        return 'جهة العرض والرقابة المطلوبة';
      case 'STEP_04':
        return 'مبلغ الدفعة المعتمدة للمورد';
      case 'STEP_05':
        return 'الرقم التعريفي المبدئي (ACID Number)';
      case 'STEP_06':
        return 'رقم تأكيد الحجز (Booking Ref)';
      case 'STEP_12':
        return 'رقم نموذج 4 المعتمد';
      case 'STEP_13':
        return 'رقم شهادة الإجراءات (إقرار 46)';
      case 'STEP_19':
        return 'رقم إذن الإضافة المخزني (GRN)';
      default:
        return 'المرجع التشغيلي الرئيسي للخطوة';
    }
  }

  String _getParam2Label(String stepCode) {
    switch (stepCode) {
      case 'STEP_01':
        return 'سعر النولون البحري للحاوية (\$)';
      case 'STEP_02':
        return 'نسبة ضريبة الوارد / الجمارك %';
      case 'STEP_04':
        return 'البنك المعتمد للتحويل';
      case 'STEP_05':
        return 'فترة صلاحية الـ ACID (أيام)';
      case 'STEP_06':
        return 'اسم السفينة الناقلة';
      case 'STEP_12':
        return 'البنك المصدر للنموذج';
      case 'STEP_13':
        return 'جمرك الإفراج المعتمد';
      case 'STEP_19':
        return 'المستودع المستلم';
      default:
        return 'الملاحظة الإجرائية الفرعية';
    }
  }

  String _getParam3Label(String stepCode) {
    switch (stepCode) {
      case 'STEP_01':
        return 'مدة الإبحار المتوقعة (Transit Days)';
      case 'STEP_02':
        return 'نسبة ضريبة القيمة المضافة VAT %';
      case 'STEP_04':
        return 'رقم مرجع السويفت SWIFT Ref';
      case 'STEP_05':
        return 'رقم تسجيل المصنع الأجنبي';
      case 'STEP_06':
        return 'توزيع الحاويات وعدد الطرود';
      case 'STEP_12':
        return 'القيمة المعتمدة بالنموذج (\$)';
      case 'STEP_13':
        return 'اسم المخلص الجمركي المعتمد';
      case 'STEP_19':
        return 'حالة الفحص والاستلام الفعلي';
      default:
        return 'بيانات إضافية';
    }
  }
}
