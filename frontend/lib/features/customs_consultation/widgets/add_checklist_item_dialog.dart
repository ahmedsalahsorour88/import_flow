import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../models/customs_consultation_model.dart';

class AddChecklistItemDialog extends StatefulWidget {
  const AddChecklistItemDialog({super.key});

  @override
  State<AddChecklistItemDialog> createState() => _AddChecklistItemDialogState();
}

class _AddChecklistItemDialogState extends State<AddChecklistItemDialog> {
  final docController = TextEditingController();
  final hsController = TextEditingController();
  final agencyController = TextEditingController();
  final remarksController = TextEditingController();
  bool isReq = true;
  bool isBlock = true;
  String party = 'Customs Broker';
  String itemStatus = 'Pending';

  @override
  void dispose() {
    docController.dispose();
    hsController.dispose();
    agencyController.dispose();
    remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة بند جديد في قائمة الفحص الجمركي (Customs Checklist)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: docController,
                decoration: const InputDecoration(labelText: 'نوع المستند / الموافقة الجمركية *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hsController,
                decoration: const InputDecoration(labelText: 'بند التعريفة الجمركية المرتبط (HS Code)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              SearchableDropdownField<String>(
                value: party,
                labelText: 'الجهة المسؤولة عن المستند',
                items: const [
                  SearchableDropdownItem(value: 'Customs Broker', label: 'Customs Broker (المستخلص الجمركي)'),
                  SearchableDropdownItem(value: 'Supplier / Exporter', label: 'Supplier / Exporter (المورد الخارجي)'),
                  SearchableDropdownItem(value: 'Importer Team', label: 'Importer Team (فريق الاستيراد)'),
                  SearchableDropdownItem(value: 'Freight Forwarder', label: 'Freight Forwarder (شركة الشحن)'),
                ],
                onChanged: (v) => setState(() => party = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: agencyController,
                decoration: const InputDecoration(labelText: 'الجهة الرقابية / العرض الجمركي (GOEIC, NTRA, Food Safety...)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              SearchableDropdownField<String>(
                value: itemStatus,
                labelText: 'حالة المستند المبدئية',
                items: const [
                  SearchableDropdownItem(value: 'Pending', label: 'Pending (قيد الانتظار)'),
                  SearchableDropdownItem(value: 'Received', label: 'Received (تم الاستلام)'),
                  SearchableDropdownItem(value: 'Verified', label: 'Verified (تم التدقيق)'),
                  SearchableDropdownItem(value: 'Approved', label: 'Approved (معتمد جمركياً)'),
                  SearchableDropdownItem(value: 'Rejected', label: 'Rejected (مرفوض / يتطلب إجراء)'),
                ],
                onChanged: (v) => setState(() => itemStatus = v!),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: isReq,
                    onChanged: (v) => setState(() => isReq = v!),
                  ),
                  const Text('مستند إجباري (Required)'),
                  const Spacer(),
                  Checkbox(
                    value: isBlock,
                    onChanged: (v) => setState(() => isBlock = v!),
                  ),
                  const Text('يعطل الشحنة (Blocking Shipment)'),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: remarksController,
                decoration: const InputDecoration(labelText: 'ملاحظات المستخلص / المتطلبات', border: OutlineInputBorder()),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
          onPressed: () {
            if (docController.text.trim().isEmpty) return;
            final newItem = CustomsChecklistItemModel(
              documentType: docController.text.trim(),
              hsCode: hsController.text.trim().isNotEmpty ? hsController.text.trim() : null,
              isRequired: isReq,
              isBlockingShipment: isBlock,
              responsibleParty: party,
              status: itemStatus,
              regulatoryAgency: agencyController.text.trim().isNotEmpty ? agencyController.text.trim() : null,
              remarks: remarksController.text.trim().isNotEmpty ? remarksController.text.trim() : null,
            );
            Navigator.pop(context, newItem);
          },
          child: const Text('إضافة البند', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
