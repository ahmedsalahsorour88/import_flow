import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/file_save_helper.dart';
import '../models/cargox_model.dart';
import '../providers/cargox_provider.dart';

/// CGX-004: واجهة الاستخلاص المزدوج — فاتورة + باكينج ليست مستقلان
class DualExtractionModal extends ConsumerStatefulWidget {
  final int importFileId;
  final String importFileCode;
  final VoidCallback onTrackCreated;

  const DualExtractionModal({
    super.key,
    required this.importFileId,
    required this.importFileCode,
    required this.onTrackCreated,
  });

  @override
  ConsumerState<DualExtractionModal> createState() => _DualExtractionModalState();
}

class _DualExtractionModalState extends ConsumerState<DualExtractionModal> {
  // ── Invoice Settings ──────────────────────────────────────────────────────
  String _invoiceMode = 'all_consolidated';
  String _invoiceGrouping = 'by_hs_code';

  // ── Packing List Settings ─────────────────────────────────────────────────
  String _plMode = 'all_consolidated';
  String _plStructure = 'by_hs_code';

  // ── Pallets ───────────────────────────────────────────────────────────────
  bool _includePallets = false;
  final List<PalletInputModel> _pallets = [];

  // ── State ─────────────────────────────────────────────────────────────────
  bool _isLoading = false;
  String? _errorMessage;
  DualExtractionResponseModel? _previewResult;

  static const _invoiceModes = [
    ('all_consolidated', 'بيان مجمع واحد', 'جميع الفواتير في ملف Excel واحد — مجمع بـ HS Code'),
    ('all_detailed', 'بيان مفصل واحد', 'جميع الفواتير في ملف Excel واحد — كل بند منفصل'),
    ('per_invoice_consolidated', 'ZIP لكل فاتورة (مجمع)', 'ملف Excel مجمع لكل فاتورة — داخل ZIP'),
    ('per_invoice_detailed', 'ZIP لكل فاتورة (مفصل)', 'ملف Excel مفصل لكل فاتورة — داخل ZIP'),
  ];

  static const _plModes = [
    ('all_consolidated', 'بيان تعبئة مجمع واحد', 'جميع بنود التعبئة في ملف واحد — مجمع'),
    ('all_detailed', 'بيان تعبئة مفصل واحد', 'جميع بنود التعبئة في ملف واحد — مفصل'),
    ('per_invoice_consolidated', 'ZIP لكل فاتورة (مجمع)', 'ملف تعبئة مجمع لكل فاتورة — داخل ZIP'),
    ('per_invoice_detailed', 'ZIP لكل فاتورة (مفصل)', 'ملف تعبئة مفصل لكل فاتورة — داخل ZIP'),
  ];

  static const _plStructures = [
    ('by_hs_code', 'بـ HS Code', 'سطر واحد لكل بند تعريفة جمركية (الأكثر شيوعاً)'),
    ('flat', 'مفصل بالكامل', 'كل بند استيراد في سطر مستقل'),
    ('by_pallet', 'بالبالتات', 'تنظيم بالبالتات — يتطلب إدخال بيانات البالتات'),
    ('by_carton', 'بالكراتين', 'كل كرتونة/طرد في سطر مستقل'),
  ];

  static const _invoiceGroupings = [
    ('by_hs_code', 'بـ HS Code', 'متوسط سعر موزون لكل HS Code (الافتراضي جمركياً)'),
    ('by_price_group', 'بـ HS Code + سعر', 'أسعار مختلفة = سطور مختلفة'),
    ('flat', 'بدون تجميع', 'كل سطر مستقل كما هو'),
  ];

  Map<String, dynamic> _buildRequest() {
    final Map<String, dynamic> req = {
      'invoice_mode': _invoiceMode,
      'invoice_grouping': _invoiceGrouping,
      'packing_list_mode': _plMode,
      'packing_list_structure': _plStructure,
      'include_pallets': _includePallets,
    };
    if (_includePallets && _pallets.isNotEmpty) {
      req['pallet_details'] = _pallets.map((p) => p.toJson()).toList();
    }
    return req;
  }

  Future<void> _preview() async {
    setState(() { _isLoading = true; _errorMessage = null; _previewResult = null; });
    try {
      final notifier = ref.read(standardInvoiceSessionsProvider.notifier);
      final result = await notifier.extractDualMode(widget.importFileId, _buildRequest());
      setState(() { _previewResult = result; });
    } catch (e) {
      setState(() { _errorMessage = e.toString(); });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _saveAsTrack() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final notifier = ref.read(standardInvoiceSessionsProvider.notifier);
      final payload = {
        'import_file_id': widget.importFileId,
        ..._buildRequest(),
      };
      await notifier.createDualCustomsTrack(payload);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onTrackCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء المسار الجمركي المزدوج بنجاح ✅'),
            backgroundColor: AppTheme.emerald,
          ),
        );
      }
    } catch (e) {
      setState(() { _errorMessage = e.toString(); });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _downloadZip() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final notifier = ref.read(standardInvoiceSessionsProvider.notifier);
      final bytes = await notifier.generateDualZip(widget.importFileId, _buildRequest());
      if (mounted) {
        await FileSaveHelper.saveBytes(
          context: context,
          bytes: bytes,
          defaultFileName: 'CargoX_Dual_${widget.importFileCode}.zip',
          dialogTitle: 'حفظ ZIP الاستخلاص المزدوج',
          allowedExtensions: ['zip'],
        );
      }
    } catch (e) {
      setState(() { _errorMessage = e.toString(); });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920, maxHeight: 700),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                _buildDualEnginePanel(),
                if (_includePallets) ...[
                  const SizedBox(height: 16),
                  _buildPalletsPanel(),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  _buildErrorBanner(),
                ],
                if (_previewResult != null) ...[
                  const SizedBox(height: 12),
                  _buildPreviewSummary(),
                ],
              ]),
            )),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.charcoal,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(children: [
        const Icon(Icons.file_copy_outlined, color: Colors.white, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('محرك الاستخلاص المزدوج (CGX-004)',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            Text(widget.importFileCode,
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ]),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ]),
    );
  }

  Widget _buildDualEnginePanel() {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── Invoice Engine ────────────────────────────────────────────────────
      Expanded(child: _buildEngineCard(
        icon: Icons.receipt_long,
        color: AppTheme.cobalt,
        title: 'الفاتورة التجارية الجمركية',
        subtitle: 'Commercial Invoice',
        modeValue: _invoiceMode,
        modeItems: _invoiceModes,
        onModeChanged: (v) => setState(() => _invoiceMode = v),
        extraWidget: _buildGroupingSelector(),
      )),
      const SizedBox(width: 16),
      // ── PL Engine ─────────────────────────────────────────────────────────
      Expanded(child: _buildEngineCard(
        icon: Icons.inventory_2_outlined,
        color: AppTheme.emerald,
        title: 'قائمة التعبئة الجمركية',
        subtitle: 'Customs Packing List',
        modeValue: _plMode,
        modeItems: _plModes,
        onModeChanged: (v) => setState(() => _plMode = v),
        extraWidget: _buildStructureSelector(),
      )),
    ]);
  }

  Widget _buildEngineCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String modeValue,
    required List<(String, String, String)> modeItems,
    required ValueChanged<String> onModeChanged,
    required Widget extraWidget,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.03),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ])),
        ]),
        const Divider(height: 16),
        ...modeItems.map((item) => _buildModeRadioTile(
          value: item.$1,
          label: item.$2,
          desc: item.$3,
          groupValue: modeValue,
          color: color,
          onChanged: onModeChanged,
        )),
        const SizedBox(height: 10),
        extraWidget,
      ]),
    );
  }

  Widget _buildModeRadioTile({
    required String value,
    required String label,
    required String desc,
    required String groupValue,
    required Color color,
    required ValueChanged<String> onChanged,
  }) {
    final selected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.08) : Colors.transparent,
          border: Border.all(color: selected ? color : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? color : Colors.grey, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                    color: selected ? color : Colors.black87)),
            Text(desc, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ])),
        ]),
      ),
    );
  }

  Widget _buildGroupingSelector() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('التجميع:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
      const SizedBox(height: 6),
      ..._invoiceGroupings.map((g) => _buildModeRadioTile(
        value: g.$1, label: g.$2, desc: g.$3,
        groupValue: _invoiceGrouping,
        color: AppTheme.cobalt,
        onChanged: (v) => setState(() => _invoiceGrouping = v),
      )),
    ]);
  }

  Widget _buildStructureSelector() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('هيكل الطرود:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
      const SizedBox(height: 6),
      ..._plStructures.map((s) => _buildModeRadioTile(
        value: s.$1, label: s.$2, desc: s.$3,
        groupValue: _plStructure,
        color: AppTheme.emerald,
        onChanged: (v) {
          setState(() {
            _plStructure = v;
            if (v == 'by_pallet') _includePallets = true;
          });
        },
      )),
      const SizedBox(height: 8),
      SwitchListTile(
        value: _includePallets,
        onChanged: (v) => setState(() => _includePallets = v),
        title: const Text('إدراج بيانات البالتات', style: TextStyle(fontSize: 11)),
        activeColor: AppTheme.emerald,
        contentPadding: EdgeInsets.zero,
        dense: true,
      ),
    ]);
  }

  Widget _buildPalletsPanel() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.emerald.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFF1FBF5),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.view_module_outlined, color: AppTheme.emerald, size: 18),
          const SizedBox(width: 8),
          const Text('بيانات البالتات والطرود', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const Spacer(),
          FilledButton.icon(
            onPressed: _showAddPalletDialog,
            icon: const Icon(Icons.add, size: 14),
            label: const Text('إضافة بالتة', style: TextStyle(fontSize: 11)),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.emerald,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          ),
        ]),
        if (_pallets.isEmpty) ...[
          const SizedBox(height: 12),
          const Center(child: Text('لا توجد بالتات مُضافة بعد', style: TextStyle(color: Colors.grey, fontSize: 12))),
        ] else ...[
          const SizedBox(height: 10),
          ..._pallets.asMap().entries.map((e) => _buildPalletTile(e.key, e.value)),
        ],
      ]),
    );
  }

  Widget _buildPalletTile(int index, PalletInputModel pallet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(children: [
        const Icon(Icons.table_rows_outlined, size: 18, color: AppTheme.emerald),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(pallet.palletNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Text(
            '${pallet.palletType}  |  ${pallet.items.length} بند  |  '
            'الوزن القائم: ${pallet.grossWeightKg} كجم  |  الصافي: ${pallet.netWeightKg} كجم'
            '${pallet.dimensionsCm != null ? "  |  ${pallet.dimensionsCm} سم" : ""}',
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ])),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
          onPressed: () => setState(() => _pallets.removeAt(index)),
          tooltip: 'حذف البالتة',
        ),
      ]),
    );
  }

  void _showAddPalletDialog() {
    final palletNumCtrl = TextEditingController(text: 'PLT-${(_pallets.length + 1).toString().padLeft(3, "0")}');
    final dimsCtrl = TextEditingController();
    final grossCtrl = TextEditingController();
    final netCtrl = TextEditingController();
    String palletType = 'EURO';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setInnerState) => AlertDialog(
        title: const Text('إضافة بالتة', style: TextStyle(fontSize: 14)),
        content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: palletNumCtrl, decoration: const InputDecoration(labelText: 'رقم البالتة', isDense: true)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: palletType,
            items: ['EURO', 'CHEP', 'CUSTOM', 'WOODEN'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setInnerState(() => palletType = v ?? 'EURO'),
            decoration: const InputDecoration(labelText: 'نوع البالتة', isDense: true),
          ),
          const SizedBox(height: 8),
          TextField(controller: dimsCtrl, decoration: const InputDecoration(labelText: 'الأبعاد (سم) — مثال: 120x80x150', isDense: true)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(controller: grossCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الوزن القائم (كجم)', isDense: true))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: netCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الوزن الصافي (كجم)', isDense: true))),
          ]),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              final pallet = PalletInputModel(
                palletNumber: palletNumCtrl.text.trim(),
                palletType: palletType,
                dimensionsCm: dimsCtrl.text.trim().isEmpty ? null : dimsCtrl.text.trim(),
                grossWeightKg: double.tryParse(grossCtrl.text) ?? 0.0,
                netWeightKg: double.tryParse(netCtrl.text) ?? 0.0,
              );
              setState(() => _pallets.add(pallet));
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.emerald),
            child: const Text('إضافة'),
          ),
        ],
      )),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(children: [
        const Icon(Icons.warning_amber_outlined, color: Colors.orange, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(_errorMessage!, style: const TextStyle(fontSize: 11, color: Colors.orange))),
      ]),
    );
  }

  Widget _buildPreviewSummary() {
    final r = _previewResult!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.emerald.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('معاينة نتائج الاستخلاص المزدوج', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.emerald)),
        const SizedBox(height: 8),
        Row(children: [
          _previewChip(Icons.receipt_long, 'الفاتورة', '${r.invoiceInvoicesCount} فاتورة / ${r.invoiceTotalLineItems} بند', AppTheme.cobalt),
          const SizedBox(width: 12),
          _previewChip(Icons.inventory_2_outlined, 'الباكينج ليست', '${r.packingListCount} ملف / ${r.packingListTotalItems} بند', AppTheme.emerald),
        ]),
      ]),
    );
  }

  Widget _previewChip(IconData icon, String label, String value, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: color)),
          Text(value, style: const TextStyle(fontSize: 10)),
        ])),
      ]),
    ));
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(children: [
        OutlinedButton.icon(
          onPressed: _isLoading ? null : _preview,
          icon: const Icon(Icons.visibility_outlined, size: 16),
          label: const Text('معاينة النتائج', style: TextStyle(fontSize: 11)),
        ),
        const Spacer(),
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: _isLoading ? null : _downloadZip,
          icon: const Icon(Icons.download_outlined, size: 16),
          label: const Text('تحميل ZIP', style: TextStyle(fontSize: 11)),
          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.cobalt),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: _isLoading ? null : _saveAsTrack,
          icon: _isLoading
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save_outlined, size: 16),
          label: const Text('اعتماد كمسار جمركي', style: TextStyle(fontSize: 11)),
          style: FilledButton.styleFrom(backgroundColor: AppTheme.charcoal),
        ),
      ]),
    );
  }
}
