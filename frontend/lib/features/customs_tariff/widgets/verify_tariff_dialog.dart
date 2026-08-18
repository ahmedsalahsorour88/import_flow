import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../models/customs_tariff_model.dart';
import '../providers/customs_tariff_provider.dart';
import '../../import_requirements/models/import_requirement_model.dart';
import '../../import_requirements/providers/import_requirements_provider.dart';

  void showVerifyTariffDialog(
      BuildContext context, WidgetRef ref, CustomsTariffModel tariff) {
    final formKey = GlobalKey<FormState>();
    final verifiedByController =
        TextEditingController(text: tariff.verifiedBy ?? 'System Admin');
    final sourceUrlController = TextEditingController(
        text: tariff.sourceUrl ??
            'https://www.nafeza.gov.eg/ar/tarrif?code=${tariff.hsCode}');
    final priorApprovalNoteController =
        TextEditingController(text: tariff.priorApprovalNote ?? '');
    final dutyRateController =
        TextEditingController(text: tariff.customsDutyRate.toString());
    final vatRateController =
        TextEditingController(text: tariff.vatRate.toString());
    final scheduleTaxRateController =
        TextEditingController(text: tariff.scheduleTaxRate.toString());

    String confidence = tariff.confidence ?? 'verified_manual';
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.verified, color: AppTheme.cobalt),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Verify HS Code & Audit Metadata (${tariff.hsCode})',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 550,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.cobalt.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: AppTheme.cobalt.withOpacity(0.2)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Addendum 3 Manual Verification Protocol:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppTheme.charcoal),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '• Live web queries forbidden. All data stored internally.\n'
                            '• Modifying tax rates archives the current version today and creates a new active version.\n'
                            '• Historical estimates keep their exact snapshot rate.',
                            style:
                                TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: verifiedByController,
                      decoration: const InputDecoration(
                        labelText: 'Verified By (Auditor Name) *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Auditor name is required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: sourceUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Nafeza Source URL Reference',
                        prefixIcon: Icon(Icons.link),
                        hintText:
                            'https://www.nafeza.gov.eg/ar/tarrif?code=...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SearchableDropdownField<String>(
                      value: confidence,
                      labelText: 'Confidence Level',
                      searchHintText: 'ابحث عن حالة التوثيق...',
                      items: const [
                        SearchableDropdownItem(
                            value: 'verified_manual',
                            label: 'Manual Audit (Verified)'),
                        SearchableDropdownItem(
                            value: 'verified_official_gazette',
                            label: 'Official Gazette Decree'),
                        SearchableDropdownItem(
                            value: 'draft', label: 'Draft / Unverified'),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => confidence = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: priorApprovalNoteController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Prior Approval / Special Conditions Note',
                        prefixIcon: Icon(Icons.notes),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Tax Rates Verification:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: dutyRateController,
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: 'Duty Rate %'),
                            validator: (val) =>
                                val == null || double.tryParse(val) == null
                                    ? 'Invalid'
                                    : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: vatRateController,
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: 'VAT Rate %'),
                            validator: (val) =>
                                val == null || double.tryParse(val) == null
                                    ? 'Invalid'
                                    : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: scheduleTaxRateController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'Schedule Tax %'),
                            validator: (val) =>
                                val == null || double.tryParse(val) == null
                                    ? 'Invalid'
                                    : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check, size: 18),
              label: const Text('Confirm Verification'),
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => isLoading = true);

                      final error = await ref
                          .read(customsTariffProvider.notifier)
                          .verifyTariff(
                        tariff.hsCode,
                        {
                          'verified_by': verifiedByController.text.trim(),
                          'source_url': sourceUrlController.text.trim(),
                          'confidence': confidence,
                          'prior_approval_note':
                              priorApprovalNoteController.text.trim().isEmpty
                                  ? null
                                  : priorApprovalNoteController.text.trim(),
                          'customs_duty_rate':
                              double.parse(dutyRateController.text),
                          'vat_rate': double.parse(vatRateController.text),
                          'schedule_tax_rate':
                              double.parse(scheduleTaxRateController.text),
                        },
                      );

                      setState(() => isLoading = false);
                      if (context.mounted) {
                        if (error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(error),
                                backgroundColor: AppTheme.crimson),
                          );
                        } else {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'HS Code ${tariff.hsCode} successfully verified!'),
                              backgroundColor: AppTheme.emerald,
                            ),
                          );
                        }
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
