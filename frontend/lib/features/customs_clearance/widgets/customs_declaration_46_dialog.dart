import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../import_files/models/import_file_model.dart';
import '../providers/customs_clearance_provider.dart';

/// Modal dialog for CS-03: Customs Declaration 46 Registration
/// قيد الإقرار الجمركي ونموذج 46 ك.م
class CustomsDeclaration46Dialog extends ConsumerStatefulWidget {
  final ImportFileModel file;

  const CustomsDeclaration46Dialog({
    super.key,
    required this.file,
  });

  static Future<bool?> show(BuildContext context, ImportFileModel file) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomsDeclaration46Dialog(file: file),
    );
  }

  @override
  ConsumerState<CustomsDeclaration46Dialog> createState() =>
      _CustomsDeclaration46DialogState();
}

class _CustomsDeclaration46DialogState
    extends ConsumerState<CustomsDeclaration46Dialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _declaration46Controller;
  late TextEditingController _mtsCertController;
  late TextEditingController _tariffCountController;
  late TextEditingController _inspectionNotesController;

  DateTime _declarationDate = DateTime.now();
  String _selectedOffice = 'Alexandria Port Customs';
  String _selectedChannel = 'Red Channel';
  final Set<String> _selectedRegulatoryBodies = {
    'الهيئة العامة للرقابة على الصادرات والواردات (GOEIC)',
  };

  bool _isSubmitting = false;

  final List<String> _customsOffices = [
    'Alexandria Port Customs',
    'El Dekheila Port Customs',
    'Port Said Customs',
    'Damietta Port Customs',
    'Sokhna Port Customs',
    'Cairo Airport Cargo Customs',
    '6th of October Dry Port Customs',
    '10th of Ramadan Dry Port Customs',
    'Adabiya Port Customs',
  ];

  final Map<String, String> _officeLabels = {
    'Alexandria Port Customs': 'جمارك ميناء الإسكندرية البحري',
    'El Dekheila Port Customs': 'جمارك ميناء الدخيلة البحري',
    'Port Said Customs': 'جمارك ميناء غرب / شرق بورسعيد',
    'Damietta Port Customs': 'جمارك ميناء دمياط البحري',
    'Sokhna Port Customs': 'جمارك ميناء العين السخنة',
    'Cairo Airport Cargo Customs': 'جمارك قرية البضائع - مطار القاهرة الدولي',
    '6th of October Dry Port Customs': 'جمارك الميناء الجاف بمدينة 6 أكتوبر',
    '10th of Ramadan Dry Port Customs': 'جمارك الميناء الجاف بمدينة العاشر من رمضان',
    'Adabiya Port Customs': 'جمارك ميناء الأدبية بالسويس',
  };

  final List<Map<String, dynamic>> _channels = [
    {
      'code': 'Red Channel',
      'label': 'المسار الأحمر',
      'desc': 'كشف ومعاينة فعلية كاملة وسحب عينات',
      'color': const Color(0xFFDC2626),
      'icon': Icons.security_rounded,
    },
    {
      'code': 'Yellow Channel',
      'label': 'المسار الأصفر',
      'desc': 'مراجعة وتدقيق مستندي وفحص ورقي',
      'color': const Color(0xFFD97706),
      'icon': Icons.rule_folder_rounded,
    },
    {
      'code': 'Green Channel',
      'label': 'المسار الأخضر',
      'desc': 'إفراج فوري ومراجعة لاحقة (مشغل اقتصادي)',
      'color': const Color(0xFF16A34A),
      'icon': Icons.verified_user_rounded,
    },
  ];

  final List<String> _regulatoryAgencyOptions = [
    'الهيئة العامة للرقابة على الصادرات والواردات (GOEIC)',
    'الهيئة القومية لسلامة الغذاء (NFSA)',
    'الجهاز القومي لتنظيم الاتصالات (NTRA)',
    'مصلحة الكيمياء (Chemistry Dept)',
    'الحجر الزراعي / البيطري (Quarantine)',
    'هيئة الدواء المصرية (EDA)',
    'مصلحة الرقابة الصناعية',
  ];

  @override
  void initState() {
    super.initState();
    _declaration46Controller = TextEditingController(
      text: widget.file.form46No ?? '',
    );
    _mtsCertController = TextEditingController();
    _tariffCountController = TextEditingController(text: '1');
    _inspectionNotesController = TextEditingController();

    if (_declaration46Controller.text.trim().isEmpty) {
      _generateDeclaration46Number();
    }

    if (widget.file.portOfDischarge != null &&
        widget.file.portOfDischarge!.isNotEmpty) {
      final pod = widget.file.portOfDischarge!.toLowerCase();
      if (pod.contains('dekheila') || pod.contains('دخيلة')) {
        _selectedOffice = 'El Dekheila Port Customs';
      } else if (pod.contains('alex') || pod.contains('إسكندرية')) {
        _selectedOffice = 'Alexandria Port Customs';
      } else if (pod.contains('said') || pod.contains('بورسعيد')) {
        _selectedOffice = 'Port Said Customs';
      } else if (pod.contains('damietta') || pod.contains('دمياط')) {
        _selectedOffice = 'Damietta Port Customs';
      } else if (pod.contains('sokhna') || pod.contains('سخنة')) {
        _selectedOffice = 'Sokhna Port Customs';
      }
    }
  }

  @override
  void dispose() {
    _declaration46Controller.dispose();
    _mtsCertController.dispose();
    _tariffCountController.dispose();
    _inspectionNotesController.dispose();
    super.dispose();
  }

  void _generateDeclaration46Number() {
    final year = DateTime.now().year;
    final rand = 10000 + Random().nextInt(90000);
    String portPrefix = 'ALX';
    if (_selectedOffice.contains('Dekheila')) {
      portPrefix = 'DKH';
    } else if (_selectedOffice.contains('Port Said')) {
      portPrefix = 'PSD';
    } else if (_selectedOffice.contains('Damietta')) {
      portPrefix = 'DMT';
    } else if (_selectedOffice.contains('Sokhna')) {
      portPrefix = 'SKH';
    } else if (_selectedOffice.contains('Airport')) {
      portPrefix = 'CAI';
    }

    setState(() {
      _declaration46Controller.text = '46-$year-$portPrefix-$rand';
      if (_mtsCertController.text.trim().isEmpty) {
        _mtsCertController.text = 'MTS-$year-$portPrefix-${rand + 100}';
      }
    });
  }

  Future<void> _selectDeclarationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _declarationDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() {
        _declarationDate = picked;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final itemsCount = int.tryParse(_tariffCountController.text.trim()) ?? 1;

      final payload = {
        'import_file_id': widget.file.importFileId,
        'declaration_46_no': _declaration46Controller.text.trim(),
        'declaration_46_date': _declarationDate.toIso8601String(),
        'customs_office_name': _selectedOffice,
        'channel_type': _selectedChannel,
        'regulatory_bodies': _selectedRegulatoryBodies.toList(),
        'mts_certificate_number': _mtsCertController.text.trim().isNotEmpty
            ? _mtsCertController.text.trim()
            : null,
        'customs_tariff_items_count': itemsCount,
        'inspection_notes': _inspectionNotesController.text.trim().isNotEmpty
            ? _inspectionNotesController.text.trim()
            : null,
      };

      await ref
          .read(customsClearanceProvider.notifier)
          .registerDeclaration46(payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'تم قيد الإقرار الجمركي ونموذج 46 ك.م بنجاح! رقم الإقرار (${_declaration46Controller.text.trim()}) على المسار ($_selectedChannel). المرحلة التالية: تسجيل الكشف والمعاينة وسحب العينات (CL-01).',
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.emerald,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء قيد الإقرار 46: $e'),
            backgroundColor: AppTheme.crimson,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860, maxHeight: 780),
        child: Column(
          children: [
            // Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFD97706), // Amber / Customs Gold
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.description_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'قيد الإقرار الجمركي ونموذج 46 ك.م (CS-03)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'المرحلة السادسة: الإعداد الجمركي 46 — ربط الإقرار وتحديد المسار وجهات العرض الرقابية',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('cancelDeclaration46Btn'),
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // File Info Banner
                      _buildShipmentSummaryBanner(isDark),
                      const SizedBox(height: 20),

                      // Section 1: Declaration 46 Number & Date
                      _buildSectionHeader('بيانات الإقرار الجمركي ونموذج 46 ك.م', Icons.receipt_long_rounded),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              key: const Key('declaration46NoField'),
                              controller: _declaration46Controller,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                labelText: 'رقم الإقرار الجمركي 46 ك.م *',
                                hintText: 'مثال: 46-2026-ALX-98124',
                                prefixIcon: const Icon(Icons.confirmation_number_rounded),
                                suffixIcon: IconButton(
                                  key: const Key('generateDeclaration46Btn'),
                                  tooltip: 'توليد رقم إقرار جديد',
                                  icon: const Icon(Icons.auto_awesome_rounded, color: AppTheme.cobalt),
                                  onPressed: _generateDeclaration46Number,
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'رقم الإقرار الجمركي 46 ك.م مطلوب';
                                }
                                if (value.trim().length < 3) {
                                  return 'رقم الإقرار يجب ألا يقل عن 3 أحرف/أرقام';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 2,
                            child: InkWell(
                              onTap: _selectDeclarationDate,
                              borderRadius: BorderRadius.circular(8),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'تاريخ القيد الجمركي *',
                                  prefixIcon: const Icon(Icons.calendar_today_rounded),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: Text(
                                  _declarationDate.toIso8601String().substring(0, 10),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Section 2: Customs Office & MTS Certificate
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: SearchableDropdownField<String>(
                              key: const Key('customsOfficeDropdown'),
                              labelText: 'الميناء / المركز الجمركي المختص *',
                              hintText: 'اختر المركز الجمركي...',
                              items: _customsOffices
                                  .map(
                                    (office) => SearchableDropdownItem<String>(
                                      value: office,
                                      label: '${_officeLabels[office] ?? office} ($office)',
                                    ),
                                  )
                                  .toList(),
                              value: _selectedOffice,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.account_balance_rounded),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedOffice = val;
                                    _generateDeclaration46Number();
                                  });
                                }
                              },
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'يرجى تحديد المركز الجمركي';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _mtsCertController,
                              decoration: InputDecoration(
                                labelText: 'رقم الشهادة / منصة MTS',
                                hintText: 'مثال: MTS-2026-EG-44910',
                                prefixIcon: const Icon(Icons.tag_rounded),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Section 3: Channel Selection (Red / Yellow / Green)
                      _buildSectionHeader('المسار الجمركي المحدد (Customs Channel)', Icons.alt_route_rounded),
                      const SizedBox(height: 10),
                      _buildChannelSelector(isDark),
                      const SizedBox(height: 20),

                      // Section 4: Regulatory Bodies & Tariff Items Count
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader('جهات العرض والرقابة المختصة', Icons.policy_rounded),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: _regulatoryAgencyOptions.map((agency) {
                                    final isSelected = _selectedRegulatoryBodies.contains(agency);
                                    return FilterChip(
                                      selected: isSelected,
                                      showCheckmark: true,
                                      selectedColor: const Color(0xFFD97706).withOpacity(0.18),
                                      checkmarkColor: const Color(0xFFD97706),
                                      label: Text(
                                        agency,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected
                                              ? const Color(0xFFD97706)
                                              : (isDark ? Colors.white70 : AppTheme.charcoal),
                                        ),
                                      ),
                                      onSelected: (checked) {
                                        setState(() {
                                          if (checked) {
                                            _selectedRegulatoryBodies.add(agency);
                                          } else {
                                            _selectedRegulatoryBodies.remove(agency);
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader('بنود التعريفة', Icons.list_alt_rounded),
                                const SizedBox(height: 8),
                                TextFormField(
                                  key: const Key('tariffCountField'),
                                  controller: _tariffCountController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  decoration: InputDecoration(
                                    labelText: 'عدد بنود التعريفة *',
                                    prefixIcon: const Icon(Icons.format_list_numbered_rounded),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  validator: (v) {
                                    final n = int.tryParse(v ?? '');
                                    if (n == null || n < 1) {
                                      return 'بند 1 على الأقل';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Section 5: Inspection Notes
                      _buildSectionHeader('ملاحظات وتوجيهات الكشف والتثمين', Icons.edit_note_rounded),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _inspectionNotesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'أية تعليمات خاصة بمعاينة الحاويات، لجان الفحص المشترك، ساحات الكشف...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkElevatedSurface : Colors.grey.shade50,
                border: Border(top: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200)),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'تسجيل الإقرار يرفع نسبة إنجاز الشحنة إلى 86% وينقلها للمرحلة السابعة (التخليص الجمركي والكشف CL-01).',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.grey.shade700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    child: const Text('إلغاء'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    key: const Key('submitDeclaration46Btn'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706), // Amber / Customs Gold
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_rounded, size: 18),
                    label: Text(
                      _isSubmitting ? 'جاري القيد والتسجيل...' : 'تأكيد وقيد نموذج 46 ك.م',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: _isSubmitting ? null : _handleSubmit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShipmentSummaryBanner(bool isDark) {
    final file = widget.file;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.blueGrey.shade900.withOpacity(0.35) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.blueGrey.shade700 : const Color(0xFFBBF7D0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildBannerItem('الملف الاستيرادي', file.primaryNameWithCode),
                _buildBannerItem('الشركة المستوردة', file.companyName),
                _buildBannerItem('المورد الأجنبي', file.supplierName),
                _buildBannerItem('ميناء الوصول', file.portOfDischarge ?? '—'),
                _buildBannerItem('رقم ACID', file.acidNumber ?? '—'),
                _buildBannerItem('إذن التسليم D/O', file.deliveryOrderNo ?? '—'),
                _buildBannerItem('المخلص الجمركي', file.brokerName ?? '—'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFD97706)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildChannelSelector(bool isDark) {
    return Row(
      children: _channels.map((ch) {
        final code = ch['code'] as String;
        final label = ch['label'] as String;
        final desc = ch['desc'] as String;
        final color = ch['color'] as Color;
        final icon = ch['icon'] as IconData;
        final isSelected = _selectedChannel == code;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () {
                setState(() => _selectedChannel = code);
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(isDark ? 0.25 : 0.1)
                      : (isDark ? AppTheme.darkElevatedSurface : Colors.grey.shade50),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? color : (isDark ? Colors.white12 : Colors.grey.shade300),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: color, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          Icon(Icons.check_circle_rounded, color: color, size: 18),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
