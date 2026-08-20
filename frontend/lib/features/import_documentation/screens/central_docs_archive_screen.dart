import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../providers/import_documentation_provider.dart';

class CentralDocsArchiveScreen extends ConsumerStatefulWidget {
  final int? initialImportFileId;
  final bool isEmbedded;
  const CentralDocsArchiveScreen({
    super.key,
    this.initialImportFileId,
    this.isEmbedded = false,
  });

  @override
  ConsumerState<CentralDocsArchiveScreen> createState() => _CentralDocsArchiveScreenState();
}

class _CentralDocsArchiveScreenState extends ConsumerState<CentralDocsArchiveScreen> {
  int? _selectedImportFileId;

  @override
  void initState() {
    super.initState();
    _selectedImportFileId = widget.initialImportFileId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(importFilesProvider.notifier).fetchImportFiles();
    });
  }

  void _copyToClipboard(String text, String successMessage) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(successMessage, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final importFiles = ref.watch(importFilesProvider).value ?? [];

    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Selection Bar
          _buildSelectionBar(importFiles),
          const SizedBox(height: 16),

          if (_selectedImportFileId == null)
            _buildEmptyPlaceholder()
          else
            _buildArchiveContent(_selectedImportFileId!),
        ],
      ),
    );

    if (widget.isEmbedded) {
      return Container(
        color: const Color(0xFFF4F6F9),
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, color: Colors.white),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                'الأرشيف المركزي لمستندات وتعديلات الشحنة (Central Archive & Rectifications)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.charcoal,
        elevation: 2,
        actions: [
          IconButton(
            tooltip: 'إغلاق والعودة',
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: content,
    );
  }

  Widget _buildSelectionBar(List<dynamic> importFiles) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: SearchableDropdownField<int>(
                value: _selectedImportFileId,
                labelText: 'اختر ملف الشحنة للاستعراض المركزي *',
                searchHintText: 'ابحث برقم الملف أو اسم المستورد أو المورد...',
                items: importFiles
                    .map((f) => SearchableDropdownItem<int>(
                          value: f.importFileId,
                          label: '${f.importFileCode} - ${f.companyName} (${f.supplierName})',
                        ))
                    .toList(),
                onChanged: (v) {
                  setState(() => _selectedImportFileId = v);
                },
              ),
            ),
            const SizedBox(width: 16),
            if (_selectedImportFileId != null)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cobalt,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('تحديث الأرشيف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: () {
                  ref.invalidate(centralArchiveProvider(_selectedImportFileId!));
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.folder_special_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'يرجى اختيار ملف شحنة من القائمة أعلاه',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            'سيتم استعراض الفاتورة النهائية، الباكينج ليست، درافت البوليصة، درافت المنشأ، درافت الفحص، وملخص التعديلات الصريحة فوراً.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveContent(int fileId) {
    final archiveAsync = ref.watch(centralArchiveProvider(fileId));

    return archiveAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(60.0),
          child: Column(
            children: [
              CircularProgressIndicator(color: AppTheme.cobalt),
              SizedBox(height: 16),
              Text('جارٍ جلب وتجميع الأرشيف المركزي ومطابقة المستندات...', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
      error: (err, stack) => Card(
        color: Colors.red.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(Icons.error, color: Colors.red, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Text('خطأ أثناء جلب بيانات الأرشيف: $err',
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
      data: (data) => _buildArchiveView(data),
    );
  }

  Widget _buildArchiveView(Map<String, dynamic> data) {
    final readiness = data['readiness_status']?.toString() ?? 'IN_REVIEW';
    final score = (data['readiness_score'] as num?)?.toDouble() ?? 0.0;
    final totalCritical = data['total_critical_discrepancies'] as int? ?? 0;
    final totalWarning = data['total_warning_discrepancies'] as int? ?? 0;
    final checklist = data['all_rectifications_checklist'] as List<dynamic>? ?? [];

    final finalInv = data['final_invoice'] as Map<String, dynamic>? ?? {};
    final finalPkg = data['final_packing_list'] as Map<String, dynamic>? ?? {};
    final draftBl = data['draft_bl'] as Map<String, dynamic>? ?? {};
    final draftCoo = data['certificate_of_origin'] as Map<String, dynamic>? ?? {};
    final draftInsp = data['inspection_certificate'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Overview & Readiness Header Card
        _buildOverviewHeaderCard(data, readiness, score, totalCritical, totalWarning),
        const SizedBox(height: 16),

        // 2. Master Discrepancies & Rectifications Summary
        _buildMasterRectificationsCard(data, checklist, totalCritical, totalWarning),
        const SizedBox(height: 20),

        // 3. Section Title
        const Row(
          children: [
            Icon(Icons.library_books, color: AppTheme.cobalt),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'أرشيف المستندات الـ 5 المعتمدة وتفاصيل التعديلات لكل وثيقة:',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 4. Five Core Document Cards
        _buildDocumentCard(
          doc: finalInv,
          icon: Icons.receipt_long,
          color: Colors.indigo,
          defaultTitle: '1. الفاتورة التجارية النهائية المعتمدة (Final Commercial Invoice)',
        ),
        const SizedBox(height: 12),
        _buildDocumentCard(
          doc: finalPkg,
          icon: Icons.inventory_2,
          color: Colors.teal,
          defaultTitle: '2. قائمة التعبئة النهائية المعتمدة (Final Packing List)',
        ),
        const SizedBox(height: 12),
        _buildDocumentCard(
          doc: draftBl,
          icon: Icons.directions_boat,
          color: Colors.blue.shade800,
          defaultTitle: '3. مسودة بوليصة الشحن البحرية (Draft Bill of Lading)',
        ),
        const SizedBox(height: 12),
        _buildDocumentCard(
          doc: draftCoo,
          icon: Icons.public,
          color: Colors.purple.shade700,
          defaultTitle: '4. درافت شهادة المنشأ / يورو 1 (Draft Certificate of Origin / EUR.1)',
        ),
        const SizedBox(height: 12),
        _buildDocumentCard(
          doc: draftInsp,
          icon: Icons.verified_user,
          color: Colors.orange.shade800,
          defaultTitle: '5. درافت شهادة الفحص والمطابقة النوعية (Draft Inspection / VoC / COC)',
        ),
        const SizedBox(height: 30),

        // Footer Actions
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.crimson,
                side: const BorderSide(color: AppTheme.crimson),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              icon: const Icon(Icons.close),
              label: const Text('إغلاق والعودة ✕', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewHeaderCard(Map<String, dynamic> data, String readiness, double score, int critical, int warning) {
    Color readinessColor;
    String readinessText;
    IconData readinessIcon;

    if (readiness == 'READY_FOR_RELEASE') {
      readinessColor = AppTheme.emerald;
      readinessText = 'جاهز تماماً للإفراج والرفع على كارجو إكس (100% Ready)';
      readinessIcon = Icons.check_circle;
    } else if (readiness == 'ACTION_REQUIRED') {
      readinessColor = AppTheme.crimson;
      readinessText = 'يتطلب تصحيحات وتعديلات حاسمة قبل إصدار الأصول';
      readinessIcon = Icons.warning_amber_rounded;
    } else {
      readinessColor = AppTheme.orange;
      readinessText = 'قيد استكمال ومراجعة مسودات المستندات';
      readinessIcon = Icons.pending_actions;
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.cobalt.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.cobalt.withOpacity(0.3)),
                      ),
                      child: Text(
                        'كود الملف: ${data['import_file_code']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt, fontSize: 14),
                      ),
                    ),
                    if (data['custom_file_number'] != null && data['custom_file_number'].toString().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: Text(
                          'رقم الملف الجمركي: ${data['custom_file_number']}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800, fontSize: 13),
                        ),
                      ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: readinessColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: readinessColor, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(readinessIcon, color: readinessColor, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '$readinessText (${score.toStringAsFixed(0)}%)',
                          style: TextStyle(fontWeight: FontWeight.bold, color: readinessColor, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 600;
                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderInfoRow('🏢 الشركة المستوردة:', data['importer_name'] ?? 'N/A'),
                      const SizedBox(height: 8),
                      _buildHeaderInfoRow('🏭 المصدر / المورد الأجنبي:', data['supplier_name'] ?? 'N/A'),
                      const SizedBox(height: 8),
                      _buildHeaderInfoRow('🔢 رقم القيد (ACID):', data['acid_number'] ?? 'N/A', isBold: true),
                      const SizedBox(height: 8),
                      _buildHeaderInfoRow('⚓ مسار الشحن:', '${data['port_of_loading'] ?? 'N/A'} ➔ ${data['port_of_discharge'] ?? 'Alexandria'}'),
                      const SizedBox(height: 8),
                      _buildHeaderInfoRow('📦 الطرود والوزن:', '${data['total_packages'] ?? 0} طرد | ${(data['total_gross_weight_kg'] as num?)?.toStringAsFixed(2) ?? '0.00'} KG'),
                      const SizedBox(height: 8),
                      _buildHeaderInfoRow('💰 القيمة الإجمالية:', '${(data['fob_or_cif_amount'] as num?)?.toStringAsFixed(2) ?? '0.00'} ${data['currency'] ?? 'EUR'}'),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderInfoRow('🏢 الشركة المستوردة:', data['importer_name'] ?? 'N/A'),
                          const SizedBox(height: 8),
                          _buildHeaderInfoRow('🏭 المصدر / المورد الأجنبي:', data['supplier_name'] ?? 'N/A'),
                          const SizedBox(height: 8),
                          _buildHeaderInfoRow('🔢 رقم القيد (ACID):', data['acid_number'] ?? 'N/A', isBold: true),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderInfoRow('⚓ مسار الشحن (POL ➔ POD):', '${data['port_of_loading'] ?? 'N/A'} ➔ ${data['port_of_discharge'] ?? 'Alexandria'}'),
                          const SizedBox(height: 8),
                          _buildHeaderInfoRow('📦 إجمالي الطرود والوزن:', '${data['total_packages'] ?? 0} طرد | ${(data['total_gross_weight_kg'] as num?)?.toStringAsFixed(2) ?? '0.00'} KG'),
                          const SizedBox(height: 8),
                          _buildHeaderInfoRow('💰 القيمة الإجمالية:', '${(data['fob_or_cif_amount'] as num?)?.toStringAsFixed(2) ?? '0.00'} ${data['currency'] ?? 'EUR'}'),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfoRow(String label, String value, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        SelectableText(
          value,
          style: TextStyle(
            fontSize: 13,
            color: isBold ? AppTheme.charcoal : Colors.grey.shade900,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMasterRectificationsCard(Map<String, dynamic> data, List<dynamic> checklist, int critical, int warning) {
    final emailText = data['supplier_email_rectification_text']?.toString() ?? '';
    final waText = data['supplier_whatsapp_rectification_text']?.toString() ?? '';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: critical > 0 ? AppTheme.crimson.withOpacity(0.5) : (warning > 0 ? AppTheme.orange.withOpacity(0.5) : AppTheme.emerald.withOpacity(0.5)), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      critical > 0 ? Icons.gavel : (warning > 0 ? Icons.warning_amber : Icons.verified),
                      color: critical > 0 ? AppTheme.crimson : (warning > 0 ? AppTheme.orange : AppTheme.emerald),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '⚡ ملخص التعديلات والفروق المطلوبة الصريحة:',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cobalt,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      icon: const Icon(Icons.email, color: Colors.white, size: 16),
                      label: const Text('📋 نسخ إيميل التعديلات للمورد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () => _copyToClipboard(emailText, 'تم نسخ إيميل التعديلات الإنجليزي للمورد بنجاح!'),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      icon: const Icon(Icons.chat, color: Colors.white, size: 16),
                      label: const Text('📱 نسخ رسالة واتساب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () => _copyToClipboard(waText, 'تم نسخ رسالة واتساب السريعة بنجاح!'),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            if (checklist.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.emerald),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '✔ مبروك! لا توجد أي فروق أو تعديلات مطلوبة. كافة المسودات مطابقة تماماً وجاهزة لرفعها على نافذة وكارجو إكس.',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: checklist.map((item) {
                  final sev = item['severity']?.toString() ?? 'WARNING';
                  final isCrit = sev == 'CRITICAL';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isCrit ? Colors.red.shade50 : Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isCrit ? Colors.red.shade300 : Colors.amber.shade400),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(isCrit ? Icons.error : Icons.warning_amber, color: isCrit ? AppTheme.crimson : AppTheme.orange, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${item['document']} - [${item['field']}]',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isCrit ? AppTheme.crimson : Colors.brown.shade900),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isCrit ? Colors.red.shade100 : Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isCrit ? 'حرج مانع للإفراج' : 'تنبيه تحذيري',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isCrit ? Colors.red.shade900 : Colors.brown.shade900),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('الملاحظة: ${item['issue']}', style: TextStyle(fontSize: 13, color: Colors.grey.shade800)),
                              const SizedBox(height: 4),
                              Text('📌 التعديل المطلوب: ${item['rectification']}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isCrit ? Colors.red.shade900 : Colors.brown.shade900)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard({
    required Map<String, dynamic> doc,
    required IconData icon,
    required Color color,
    required String defaultTitle,
  }) {
    final title = doc['title_ar']?.toString() ?? defaultTitle;
    final isAvail = doc['is_available'] as bool? ?? false;
    final status = doc['status']?.toString() ?? 'NOT_STARTED';
    final refNo = doc['document_reference']?.toString() ?? 'غير متوفر';
    final details = doc['details'] as Map<String, dynamic>? ?? {};
    final discrepancies = doc['discrepancies'] as List<dynamic>? ?? [];

    Color badgeColor;
    String badgeText;
    if (status == 'APPROVED') {
      badgeColor = AppTheme.emerald;
      badgeText = 'معتمد بنجاح ✔';
    } else if (status == 'MODIFICATIONS_REQUESTED') {
      badgeColor = AppTheme.crimson;
      badgeText = 'مطلوب تعديلات ✕';
    } else if (status == 'REVIEW_PENDING') {
      badgeColor = AppTheme.orange;
      badgeText = 'قيد التدقيق ⏳';
    } else {
      badgeColor = Colors.grey;
      badgeText = 'غير مدرج بعد ⚪';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        initiallyExpanded: discrepancies.isNotEmpty || isAvail,
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 6,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('المرجع: $refNo', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: badgeColor),
                  ),
                  child: Text(badgeText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor)),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Details Grid
                if (details.isNotEmpty) ...[
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: details.entries.map((e) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('${e.key}: ${e.value}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // Document Discrepancies
                if (discrepancies.isNotEmpty) ...[
                  const Text('التعديلات المطلوبة لهذا المستند:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.crimson)),
                  const SizedBox(height: 6),
                  ...discrepancies.map((d) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.arrow_left, color: AppTheme.crimson, size: 18),
                            Expanded(
                              child: Text(
                                '${d['field']}: ${d['issue']} ➔ المطلوب: ${d['rectification']}',
                                style: TextStyle(fontSize: 12, color: Colors.red.shade900, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      )),
                ] else if (isAvail) ...[
                  Row(
                    children: [
                      const Icon(Icons.check, color: AppTheme.emerald, size: 16),
                      const SizedBox(width: 6),
                      Text('هذا المستند لا يحتوي على أي ملاحظات أو فروق.', style: TextStyle(fontSize: 12, color: Colors.green.shade800)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
