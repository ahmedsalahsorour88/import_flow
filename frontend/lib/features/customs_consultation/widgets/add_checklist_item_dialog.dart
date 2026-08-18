import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../models/customs_consultation_model.dart';

class AddChecklistItemDialog extends StatefulWidget {
  final Function(CustomsChecklistItemModel) onItemAdded;

  const AddChecklistItemDialog({
    super.key,
    required this.onItemAdded,
  });

  @override
  State<AddChecklistItemDialog> createState() => _AddChecklistItemDialogState();
}

class _AddChecklistItemDialogState extends State<AddChecklistItemDialog> {
  final _docController = TextEditingController();
  final _hsController = TextEditingController();
  final _agencyController = TextEditingController();
  final _remarksController = TextEditingController();
  bool _isRequired = true;
  bool _isBlocking = true;
  String _responsibleParty = 'Customs Broker';
  String _itemStatus = 'Pending';

  @override
  void dispose() {
    _docController.dispose();
    _hsController.dispose();
    _agencyController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'إضافة بند جديد في قائمة الفحص الجمركي (Customs Checklist)',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _docController,
                decoration: const InputDecoration(
                  labelText: 'نوع المستند / الموافقة الجمركية *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _hsController,
                decoration: const InputDecoration(
                  labelText: 'بند التعريفة الجمركية المرتبط (HS Code)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SearchableDropdownField<String>(
                value: _responsibleParty,
                labelText: 'الجهة المسؤولة عن المستند',
                items: const [
                  SearchableDropdownItem(
                    value: 'Customs Broker',
                    label: 'Customs Broker (المستخلص الجمركي)',
                  ),
                  SearchableDropdownItem(
                    value: 'Supplier / Exporter',
                    label: 'Supplier / Exporter (المورد الخارجي)',
                  ),
                  SearchableDropdownItem(
                    value: 'Importer Team',
                    label: 'Importer Team (فريق الاستيراد)',
                  ),
                  SearchableDropdownItem(
                    value: 'Freight Forwarder',
                    label: 'Freight Forwarder (شركة الشحن)',
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _responsibleParty = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _agencyController,
                decoration: const InputDecoration(
                  labelText: 'الجهة الرقابية / العرض الجمركي (GOEIC, NTRA, Food Safety...)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SearchableDropdownField<String>(
                value: _itemStatus,
                labelText: 'حالة المستند المبدئية',
                items: const [
                  SearchableDropdownItem(
                    value: 'Pending',
                    label: 'Pending (قيد الانتظار)',
                  ),
                  SearchableDropdownItem(
                    value: 'Received',
                    label: 'Received (تم الاستلام)',
                  ),
                  SearchableDropdownItem(
                    value: 'Verified',
                    label: 'Verified (تم التدقيق)',
                  ),
                  SearchableDropdownItem(
                    value: 'Approved',
                    label: 'Approved (معتمد جمركياً)',
                  ),
                  SearchableDropdownItem(
                    value: 'Rejected',
                    label: 'Rejected (مرفوض / يتطلب إجراء)',
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _itemStatus = v);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _isRequired,
                    onChanged: (v) => setState(() => _isRequired = v ?? true),
                  ),
                  const Text('مستند إجباري (Required)'),
                  const Spacer(),
                  Checkbox(
                    value: _isBlocking,
                    onChanged: (v) => setState(() => _isBlocking = v ?? true),
                  ),
                  const Text('يعطل الشحنة (Blocking Shipment)'),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _remarksController,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات المستخلص / المتطلبات',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
          onPressed: () {
            final doc = _docController.text.trim();
            if (doc.isEmpty) return;
            widget.onItemAdded(CustomsChecklistItemModel(
              documentType: doc,
              hsCode: _hsController.text.trim().isNotEmpty ? _hsController.text.trim() : null,
              isRequired: _isRequired,
              isBlockingShipment: _isBlocking,
              responsibleParty: _responsibleParty,
              status: _itemStatus,
              regulatoryAgency: _agencyController.text.trim().isNotEmpty ? _agencyController.text.trim() : null,
              remarks: _remarksController.text.trim().isNotEmpty ? _remarksController.text.trim() : null,
            ));
            Navigator.pop(context);
          },
          child: const Text('إضافة البند', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
