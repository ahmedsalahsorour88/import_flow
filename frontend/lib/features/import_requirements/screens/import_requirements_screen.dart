import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../models/import_requirement_model.dart';
import '../providers/import_requirements_provider.dart';

class ImportRequirementsScreen extends ConsumerStatefulWidget {
  const ImportRequirementsScreen({super.key});

  @override
  ConsumerState<ImportRequirementsScreen> createState() => _ImportRequirementsScreenState();
}

class _ImportRequirementsScreenState extends ConsumerState<ImportRequirementsScreen> {
  final TextEditingController _searchController = TextEditingController();

  void _showCreateEditDialog([ImportRequirementModel? requirement]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ImportRequirementFormDialog(requirement: requirement),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Obtained':
      case 'Completed':
      case 'Approved':
        return AppTheme.emerald;
      case 'Pending':
        return AppTheme.orange;
      case 'Rejected':
        return AppTheme.crimson;
      default:
        return Colors.grey;
    }
  }

  Color _getOverallStatusColor(String status) {
    switch (status) {
      case 'In Progress':
        return AppTheme.cobalt;
      case 'Complete':
        return AppTheme.emerald;
      case 'Cleared':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getRiskLevelColor(String risk) {
    switch (risk) {
      case 'Low':
        return AppTheme.emerald;
      case 'Medium':
        return AppTheme.orange;
      case 'High':
        return AppTheme.crimson;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncRequirements = ref.watch(importRequirementsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'التقييم المتطلبات عند الاستيراد (BP-011)',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppTheme.charcoal,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ref.read(importRequirementsProvider.notifier).refreshData();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateEditDialog(),
        backgroundColor: AppTheme.cobalt,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'بحث برقم التقييم، HS Code، أو الوصف...',
                      prefixIcon: const Icon(Icons.search, color: AppTheme.cobalt),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (val) {
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _showCreateEditDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة تقييم جديد'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: asyncRequirements.when(
                data: (requirements) {
                  final filtered = requirements.where((r) {
                    final query = _searchController.text.toLowerCase();
                    return r.assessmentCode.toLowerCase().contains(query) ||
                        (r.hsCode?.toLowerCase().contains(query) ?? false) ||
                        (r.commodityDescription?.toLowerCase().contains(query) ?? false);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('لا توجد تقييمات.'));
                  }

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.95,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final req = filtered[index];
                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.charcoal.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      req.assessmentCode,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: AppTheme.cobalt, size: 20),
                                    onPressed: () => _showCreateEditDialog(req),
                                  ),
                                ],
                              ),
                              if (req.importFileCode != null) ...[
                                const SizedBox(height: 8),
                                Text('ملف: ${req.importFileCode}', style: const TextStyle(color: AppTheme.cobalt, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                              const SizedBox(height: 12),
                              Text(req.hsCode ?? 'No HS Code', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(
                                req.commodityDescription ?? 'بدون وصف',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                              const Divider(height: 24),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildStatusChip('COO', req.cooRequired ? req.cooStatus : 'Not Required', _getStatusColor(req.cooRequired ? req.cooStatus : 'Not Required')),
                                  _buildStatusChip('Inspection', req.inspectionRequired ? req.inspectionStatus : 'Not Required', _getStatusColor(req.inspectionRequired ? req.inspectionStatus : 'Not Required')),
                                  _buildStatusChip('MSDS', req.msdsRequired ? req.msdsStatus : 'Not Required', _getStatusColor(req.msdsRequired ? req.msdsStatus : 'Not Required')),
                                  _buildStatusChip('Halal', req.halalCertRequired ? req.halalCertStatus : 'Not Required', _getStatusColor(req.halalCertRequired ? req.halalCertStatus : 'Not Required')),
                                  _buildStatusChip('Permit', req.importPermitRequired ? req.permitStatus : 'Not Required', _getStatusColor(req.importPermitRequired ? req.permitStatus : 'Not Required')),
                                ],
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildStatusChip('حالة التقييم', req.overallStatus, _getOverallStatusColor(req.overallStatus)),
                                  _buildStatusChip('الخطر', req.riskLevel, _getRiskLevelColor(req.riskLevel)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('خطأ: $err', style: const TextStyle(color: Colors.red))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        '$label: $status',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

class _ImportRequirementFormDialog extends ConsumerStatefulWidget {
  final ImportRequirementModel? requirement;
  const _ImportRequirementFormDialog({this.requirement});

  @override
  ConsumerState<_ImportRequirementFormDialog> createState() => _ImportRequirementFormDialogState();
}

class _ImportRequirementFormDialogState extends ConsumerState<_ImportRequirementFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _hsCodeCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _cooCtrl;
  late TextEditingController _valCtrl;
  late TextEditingController _inspBodyCtrl;
  late TextEditingController _permitAuthCtrl;
  late TextEditingController _notesCtrl;

  bool _cooRequired = false;
  String _cooType = 'EUR.1';
  String _cooStatus = 'Pending';

  bool _inspRequired = false;
  String _inspStatus = 'Pending';

  bool _msdsRequired = false;
  String _msdsStatus = 'Pending';

  bool _halalRequired = false;
  String _halalStatus = 'Pending';

  bool _permitRequired = false;
  String _permitStatus = 'Pending';

  bool _decree43 = false;
  bool _whiteList = false;

  String _overallStatus = 'Draft';
  String _riskLevel = 'Low';

  @override
  void initState() {
    super.initState();
    final req = widget.requirement;
    _hsCodeCtrl = TextEditingController(text: req?.hsCode);
    _descCtrl = TextEditingController(text: req?.commodityDescription);
    _cooCtrl = TextEditingController(text: req?.countryOfOrigin);
    _valCtrl = TextEditingController(text: req?.shipmentValueUsd.toString() ?? '0');
    _inspBodyCtrl = TextEditingController(text: req?.inspectionBody);
    _permitAuthCtrl = TextEditingController(text: req?.permitIssuingAuthority);
    _notesCtrl = TextEditingController(text: req?.assessmentNotes);

    if (req != null) {
      _cooRequired = req.cooRequired;
      _cooType = req.cooType ?? 'EUR.1';
      _cooStatus = req.cooStatus;
      
      _inspRequired = req.inspectionRequired;
      _inspStatus = req.inspectionStatus;

      _msdsRequired = req.msdsRequired;
      _msdsStatus = req.msdsStatus;

      _halalRequired = req.halalCertRequired;
      _halalStatus = req.halalCertStatus;

      _permitRequired = req.importPermitRequired;
      _permitStatus = req.permitStatus;

      _decree43 = req.decree43Applicable;
      _whiteList = req.whiteListRequired;

      _overallStatus = req.overallStatus;
      _riskLevel = req.riskLevel;
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    final data = {
      'hs_code': _hsCodeCtrl.text,
      'commodity_description': _descCtrl.text,
      'country_of_origin': _cooCtrl.text,
      'shipment_value_usd': double.tryParse(_valCtrl.text) ?? 0,
      'coo_required': _cooRequired,
      'coo_type': _cooType,
      'coo_status': _cooStatus,
      'inspection_required': _inspRequired,
      'inspection_body': _inspBodyCtrl.text,
      'inspection_status': _inspStatus,
      'msds_required': _msdsRequired,
      'msds_status': _msdsStatus,
      'halal_cert_required': _halalRequired,
      'halal_cert_status': _halalStatus,
      'import_permit_required': _permitRequired,
      'permit_issuing_authority': _permitAuthCtrl.text,
      'permit_status': _permitStatus,
      'decree_43_applicable': _decree43,
      'white_list_required': _whiteList,
      'overall_status': _overallStatus,
      'risk_level': _riskLevel,
      'assessment_notes': _notesCtrl.text,
    };

    try {
      if (widget.requirement == null) {
        await ref.read(importRequirementsProvider.notifier).addRequirement(data);
      } else {
        await ref.read(importRequirementsProvider.notifier).updateRequirement(widget.requirement!.assessmentId!, data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 800,
        height: 700,
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.requirement == null ? 'إضافة تقييم متطلبات جديد' : 'تعديل التقييم',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: TextFormField(controller: _hsCodeCtrl, decoration: const InputDecoration(labelText: 'HS Code *'), validator: (v) => v!.isEmpty ? 'مطلوب' : null)),
                          const SizedBox(width: 16),
                          Expanded(child: TextFormField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Commodity Description *'), validator: (v) => v!.isEmpty ? 'مطلوب' : null)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: TextFormField(controller: _cooCtrl, decoration: const InputDecoration(labelText: 'Country of Origin *'), validator: (v) => v!.isEmpty ? 'مطلوب' : null)),
                          const SizedBox(width: 16),
                          Expanded(child: TextFormField(controller: _valCtrl, decoration: const InputDecoration(labelText: 'Shipment Value (USD) *'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'مطلوب' : null)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('Certificate of Origin (COO)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                      SwitchListTile(title: const Text('Required?'), value: _cooRequired, onChanged: (v) => setState(() => _cooRequired = v)),
                      if (_cooRequired) ...[
                        Row(
                          children: [
                            Expanded(child: DropdownButtonFormField<String>(value: _cooType, decoration: const InputDecoration(labelText: 'Type'), items: ['EUR.1', 'Form A', 'GSTP', 'Arab League COO'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _cooType = v!))),
                            const SizedBox(width: 16),
                            Expanded(child: DropdownButtonFormField<String>(value: _cooStatus, decoration: const InputDecoration(labelText: 'Status'), items: ['Pending', 'Obtained', 'Rejected'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _cooStatus = v!))),
                          ],
                        ),
                      ],
                      const Divider(),
                      const Text('Inspection', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                      SwitchListTile(title: const Text('Required?'), value: _inspRequired, onChanged: (v) => setState(() => _inspRequired = v)),
                      if (_inspRequired) ...[
                        Row(
                          children: [
                            Expanded(child: TextFormField(controller: _inspBodyCtrl, decoration: const InputDecoration(labelText: 'Inspection Body'))),
                            const SizedBox(width: 16),
                            Expanded(child: DropdownButtonFormField<String>(value: _inspStatus, decoration: const InputDecoration(labelText: 'Status'), items: ['Pending', 'Completed', 'Rejected'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _inspStatus = v!))),
                          ],
                        ),
                      ],
                      const Divider(),
                      Row(
                        children: [
                          Expanded(child: SwitchListTile(title: const Text('MSDS Required?'), value: _msdsRequired, onChanged: (v) => setState(() => _msdsRequired = v))),
                          if (_msdsRequired) Expanded(child: DropdownButtonFormField<String>(value: _msdsStatus, decoration: const InputDecoration(labelText: 'MSDS Status'), items: ['Pending', 'Obtained', 'Rejected'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _msdsStatus = v!))),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(child: SwitchListTile(title: const Text('Halal Cert Required?'), value: _halalRequired, onChanged: (v) => setState(() => _halalRequired = v))),
                          if (_halalRequired) Expanded(child: DropdownButtonFormField<String>(value: _halalStatus, decoration: const InputDecoration(labelText: 'Halal Status'), items: ['Pending', 'Obtained', 'Rejected'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _halalStatus = v!))),
                        ],
                      ),
                      const Divider(),
                      const Text('Import Permit', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                      SwitchListTile(title: const Text('Required?'), value: _permitRequired, onChanged: (v) => setState(() => _permitRequired = v)),
                      if (_permitRequired) ...[
                        Row(
                          children: [
                            Expanded(child: TextFormField(controller: _permitAuthCtrl, decoration: const InputDecoration(labelText: 'Authority'))),
                            const SizedBox(width: 16),
                            Expanded(child: DropdownButtonFormField<String>(value: _permitStatus, decoration: const InputDecoration(labelText: 'Status'), items: ['Pending', 'Approved', 'Rejected'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _permitStatus = v!))),
                          ],
                        ),
                      ],
                      const Divider(),
                      Row(
                        children: [
                          Expanded(child: SwitchListTile(title: const Text('Decree 43 Applicable?'), value: _decree43, onChanged: (v) => setState(() => _decree43 = v))),
                          Expanded(child: SwitchListTile(title: const Text('White List Required?'), value: _whiteList, onChanged: (v) => setState(() => _whiteList = v))),
                        ],
                      ),
                      const Divider(),
                      Row(
                        children: [
                          Expanded(child: DropdownButtonFormField<String>(value: _overallStatus, decoration: const InputDecoration(labelText: 'Overall Status'), items: ['Draft', 'In Progress', 'Complete', 'Cleared'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _overallStatus = v!))),
                          const SizedBox(width: 16),
                          Expanded(child: DropdownButtonFormField<String>(value: _riskLevel, decoration: const InputDecoration(labelText: 'Risk Level'), items: ['Low', 'Medium', 'High'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _riskLevel = v!))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(controller: _notesCtrl, decoration: const InputDecoration(labelText: 'Assessment Notes'), maxLines: 3),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
                  const SizedBox(width: 12),
                  ElevatedButton(onPressed: _save, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, foregroundColor: Colors.white), child: const Text('حفظ')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
