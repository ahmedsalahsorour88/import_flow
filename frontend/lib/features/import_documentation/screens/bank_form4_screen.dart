import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/clone_entity_review_dialog.dart';
import '../../../core/widgets/copyable_data_helper.dart';
import '../../../core/widgets/error_details_dialog.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/vertical_stage_scaffold.dart';
import '../../currencies/providers/currencies_provider.dart';
import '../../external_service_providers/providers/partners_provider.dart';
import '../../import_files/models/import_file_model.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../models/import_documentation_model.dart';
import '../providers/import_documentation_provider.dart';
import '../widgets/search_and_clone_bank_form4_dialog.dart';
import '../../../core/services/display_name_resolver.dart';
import '../../../core/helpers/table_copy_helper.dart';
import '../../../core/services/table_export_service.dart';

class BankForm4Screen extends ConsumerStatefulWidget {
  final int initialSubTab;
  final int? initialImportFileId;

  const BankForm4Screen({
    super.key,
    this.initialSubTab = 0,
    this.initialImportFileId,
  });

  @override
  ConsumerState<BankForm4Screen> createState() => _BankForm4ScreenState();
}

class _BankForm4ScreenState extends ConsumerState<BankForm4Screen> {
  // Active Vertical Sub-Tab:
  // 0: 📝 طلب وتوثيق نموذج 4 (Form 4 Request & Checklist)
  // 1: 📋 سجل النماذج البنكية والتوثيق (Bank Form 4 Registry)
  int _selectedSubTab = 0;

  // Form 4 State (BP-015)
  final _bankFormKey = GlobalKey<FormState>();
  int? _editingBankDocId;
  String? _editingBankDocCode;
  int? _form4ImportFileId;
  final TextEditingController _bankAmountController = TextEditingController(text: '62300.0');
  String _bankDocType = 'Form 4';
  String _form4Currency = 'USD';
  int? _selectedBankId;
  String _bankName = 'National Bank of Egypt (NBE)';
  final TextEditingController _form4RequestDateCtrl = TextEditingController(text: DateTime.now().toString().substring(0, 10));
  final TextEditingController _form4NotesCtrl = TextEditingController();

  String _form4SearchQuery = '';
  bool _isSavingForm4 = false;

  final Map<String, bool> _form4DocsChecklist = {
    'proforma_invoice': true,
    'packing_list': true,
    'certificate_of_origin': true,
    'bill_of_lading': true,
    'acid_notice': true,
    'marine_insurance': false,
    'bank_application': true,
    'admin_fee_receipt': false,
  };

  @override
  void initState() {
    super.initState();
    _selectedSubTab = widget.initialSubTab;
    _form4ImportFileId = widget.initialImportFileId;
    Future.microtask(() {
      _refreshData();
    });
  }

  @override
  void didUpdateWidget(BankForm4Screen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSubTab != widget.initialSubTab) {
      setState(() => _selectedSubTab = widget.initialSubTab);
    }
    if (oldWidget.initialImportFileId != widget.initialImportFileId) {
      setState(() => _form4ImportFileId = widget.initialImportFileId);
    }
  }

  void _refreshData() {
    if (!ref.read(partnersProvider).isLoading) {
      ref.read(partnersProvider.notifier).fetchPartners();
    }
    if (!ref.read(importFilesProvider).isLoading) {
      ref.read(importFilesProvider.notifier).fetchImportFiles();
    }
    if (!ref.read(bankingDocumentsProvider).isLoading) {
      ref.read(bankingDocumentsProvider.notifier).fetchBankingDocuments();
    }
    if (!ref.read(currenciesProvider).isLoading) {
      ref.read(currenciesProvider.notifier).fetchCurrencies();
    }
  }

  @override
  void dispose() {
    _bankAmountController.dispose();
    _form4RequestDateCtrl.dispose();
    _form4NotesCtrl.dispose();
    super.dispose();
  }

  void _loadForm4ForEdit(BankingDocumentModel doc) {
    setState(() {
      _editingBankDocId = doc.bankDocId;
      _editingBankDocCode = doc.bankDocCode;
      _form4ImportFileId = doc.importFileId;
      _bankDocType = doc.docType;
      _selectedBankId = doc.bankId;
      _bankName = doc.bankName;
      _bankAmountController.text = doc.amount.toStringAsFixed(2);
      _form4Currency = doc.currencyCode.toUpperCase();
      _form4RequestDateCtrl.text = doc.requestDate ?? doc.issueDate;
      _form4NotesCtrl.text = doc.notes ?? '';
      _selectedSubTab = 0; // Switch to Request Tab
    });
  }

  void _resetForm4Form() {
    setState(() {
      _editingBankDocId = null;
      _editingBankDocCode = null;
      _form4ImportFileId = null;
      _bankDocType = 'Form 4';
      _selectedBankId = null;
      _bankName = 'National Bank of Egypt (NBE)';
      _bankAmountController.clear();
      _form4Currency = 'USD';
      _form4RequestDateCtrl.text = DateTime.now().toIso8601String().substring(0, 10);
      _form4NotesCtrl.clear();
    });
  }

  void _openSearchAndCloneBankForm4Dialog() {
    final bankingDocs = ref.read(bankingDocumentsProvider).valueOrNull ?? [];
    showDialog(
      context: context,
      builder: (ctx) => SearchAndCloneBankForm4Dialog(
        bankingDocs: bankingDocs,
        onSelectDoc: _onCloneBankDocSelected,
      ),
    );
  }

  void _onCloneBankDocSelected(BankingDocumentModel doc) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AppLocalizationsProvider(
        locale: Localizations.localeOf(context),
        child: Directionality(
          textDirection: Directionality.of(context),
          child: CloneEntityReviewDialog(
            entityType: 'طلب وتوثيق نموذج 4 البنكي (Bank Form 4)',
            sourceCode: doc.bankDocCode,
            sourceTitle: doc.bankName,
            suggestedNewCode: 'FORM4-2026-DRAFT',
            copiedFieldsSummary: {
              'البنك المعتمد': doc.bankName,
              'قيمة الاعتماد': '${doc.amount.toStringAsFixed(2)} ${doc.currencyCode}',
              'ملف الشحنة': doc.importFileCode ?? (doc.importFileId != null ? 'IMP-${doc.importFileId}' : '-'),
              'ملاحظات وتوجيهات': doc.notes ?? '-',
            },
            mandatorilyResetFields: const [
              'كود المستند البنكي: يتم تصفيره إلى مسودة جديدة (Draft)',
              'تاريخ طلب النموذج: يعاد ضبطه إلى تاريخ اليوم',
              'حالة التوثيق والاعتماد: تعاد إلى قيد المعالجة (Processing)',
              'معرف السجل السابق: تم فك الارتباط',
            ],
            allowCopyLineItems: false,
            allowCopyAttachments: false,
            onConfirm: ({
              required String newCode,
              required String newTitle,
              required bool copyLineItems,
              required bool copyAttachments,
              String? notes,
            }) async {
              setState(() {
                _editingBankDocId = null;
                _editingBankDocCode = null;
                _selectedSubTab = 0;
                _form4ImportFileId = doc.importFileId;
                _bankDocType = doc.docType;
                _selectedBankId = doc.bankId;
                _bankName = doc.bankName;
                _bankAmountController.text = doc.amount.toStringAsFixed(2);
                _form4Currency = doc.currencyCode;
                _form4RequestDateCtrl.text = DateTime.now().toIso8601String().substring(0, 10);
                _form4NotesCtrl.text = (doc.notes != null && doc.notes!.isNotEmpty)
                    ? '${doc.notes} (نسخة)'
                    : '(نسخة نموذج سابق)';
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.cloneBankForm4Success),
                    backgroundColor: AppTheme.wcagEmerald,
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  void _onCloneBankDocRow(BankingDocumentModel doc) {
    _onCloneBankDocSelected(doc);
  }

  @override
  Widget build(BuildContext context) {
    final bankingDocs = ref.watch(bankingDocumentsProvider).valueOrNull ?? [];

    final tabs = [
      const VerticalNavTabItem(
        icon: Icons.note_add_outlined,
        titleEn: 'Form 4 Request & Checklist',
        titleAr: 'طلب وتوثيق نموذج 4',
      ),
      VerticalNavTabItem(
        icon: Icons.history_edu_outlined,
        titleEn: 'Bank Form 4 Registry',
        titleAr: 'سجل النماذج البنكية',
        badge: bankingDocs.isNotEmpty
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.wcagCobalt.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${bankingDocs.length}',
                  style: const TextStyle(color: AppTheme.wcagCobalt, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              )
            : null,
      ),
    ];

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyD, control: true): _openSearchAndCloneBankForm4Dialog,
      },
      child: Focus(
        autofocus: true,
        child: VerticalStageScaffold(
          stageCode: '',
          titleEn: 'Bank Form 4 & Financial Endorsement',
          titleAr: 'المستندات والتوثيق البنكي ونموذج 4',
          headerIcon: Icons.account_balance_outlined,
          headerColor: AppTheme.wcagCobalt,
          tabs: tabs,
          selectedIndex: _selectedSubTab,
          onTabSelected: (index) {
            setState(() => _selectedSubTab = index);
            if (index == 1) {
              ref.read(bankingDocumentsProvider.notifier).fetchBankingDocuments();
            }
          },
          headerActions: [
            IconButton(
              key: const Key('searchAndCloneBankForm4Btn'),
              icon: const Icon(Icons.copy_all, color: Colors.white70),
              tooltip: context.l10n.searchAndCloneBankForm4Btn,
              onPressed: _openSearchAndCloneBankForm4Dialog,
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white70),
              tooltip: context.l10n.refresh,
              onPressed: _refreshData,
            ),
          ],
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _selectedSubTab == 0 ? _buildForm4RequestTab() : _buildForm4HistoryRegistryTab(),
          ),
        ),
      ),
    );
  }

  // --- SUB-VIEW 0: REQUEST TAB ---
  Widget _buildForm4RequestTab() {
    final partnersState = ref.watch(partnersProvider);
    final banksList = (partnersState.valueOrNull ?? []).where((p) => p.partnerType.contains('Bank') || p.partnerType.contains('بنك')).toList();
    final importFiles = ref.watch(importFilesProvider).valueOrNull ?? [];
    final currencies = ref.watch(currenciesProvider).valueOrNull ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;

        return Form(
          key: _bankFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Action / Header Bar with Search & Clone
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.form4RequestTab,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.charcoal,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    key: const Key('subtab0SearchAndCloneBtn'),
                    icon: const Icon(Icons.copy_all, size: 16),
                    label: Text(context.l10n.searchAndCloneBankForm4Btn),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.wcagCobalt,
                      side: const BorderSide(color: AppTheme.wcagCobalt),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onPressed: _openSearchAndCloneBankForm4Dialog,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Edit Banner
              if (_editingBankDocId != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2D1F0A) : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? const Color(0xFFD97706) : Colors.amber.shade400),
                  ),
                  child: isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.edit_note, color: Colors.amber, size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: CopyableText(
                                    context.l10n.bankForm4EditingBanner(_editingBankDocCode ?? ''),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? const Color(0xFFFDE68A) : Colors.amber.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                key: const Key('cancelForm4EditModeBtn'),
                                onPressed: _resetForm4Form,
                                icon: const Icon(Icons.cancel, size: 16),
                                label: Text(context.l10n.cancelEditNewForm4),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            const Icon(Icons.edit_note, color: Colors.amber, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: CopyableText(
                                context.l10n.bankForm4EditingBanner(_editingBankDocCode ?? ''),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFFFDE68A) : Colors.amber.shade900,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              key: const Key('cancelForm4EditModeBtn'),
                              onPressed: _resetForm4Form,
                              icon: const Icon(Icons.cancel, size: 16),
                              label: Text(context.l10n.cancelEditNewForm4),
                            ),
                          ],
                        ),
                ),

              // File Selector
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCardBackground : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppTheme.darkBorder : Colors.grey.shade300),
                ),
                child: SearchableDropdownField<int>(
                  labelText: context.l10n.selectImportFileForm4Label,
                  hintText: context.l10n.searchFileOrSupplierHint,
                  value: _form4ImportFileId,
                  isRequired: true,
                  items: importFiles.map((f) => SearchableDropdownItem<int>(
                    value: f.importFileId,
                    label: '${f.primaryNameWithCode} — ${f.supplierName} (${f.companyName})',
                  )).toList(),
                  onChanged: (val) {
                    setState(() => _form4ImportFileId = val);
                    if (val != null) {
                      final file = importFiles.where((f) => f.importFileId == val).firstOrNull;
                      if (file != null && file.estimatedCost > 0) {
                        _bankAmountController.text = file.estimatedCost.toStringAsFixed(2);
                        _form4Currency = file.estimatedCostCurrency.isNotEmpty ? file.estimatedCostCurrency : 'USD';
                      }
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Main Form Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCardBackground : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppTheme.darkBorder : Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.bankApplicationDetailsSection,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.charcoal,
                      ),
                    ),
                    Divider(height: 24, color: isDark ? AppTheme.darkBorder : Colors.grey.shade300),

                    // Inputs Row 1: Bank, Amount, Currency
                    if (isMobile) ...[
                      SearchableDropdownField<int>(
                        labelText: context.l10n.issuingBankLabel,
                        hintText: context.l10n.selectBankHint,
                        value: _selectedBankId,
                        isRequired: true,
                        items: banksList.map((b) => SearchableDropdownItem<int>(
                          value: b.providerId ?? 0,
                          label: '${b.partnerName} (${b.partnerCode})',
                        )).toList(),
                        onChanged: (val) {
                          setState(() => _selectedBankId = val);
                          final b = banksList.where((p) => p.providerId == val).firstOrNull;
                          if (b != null) _bankName = b.partnerName;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _bankAmountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : Colors.black87),
                        decoration: InputDecoration(
                          labelText: context.l10n.bankAmountLabel,
                          prefixIcon: const Icon(Icons.attach_money),
                          suffixText: _form4Currency,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? context.l10n.requiredField : null,
                      ),
                      const SizedBox(height: 14),
                      SearchableDropdownField<String>(
                        labelText: context.l10n.transferCurrencyLabel,
                        hintText: context.l10n.selectCurrencyHint,
                        value: _form4Currency,
                        isRequired: true,
                        items: (currencies.isNotEmpty ? currencies.map((c) => c.currencyCode).toSet() : ['USD', 'EUR', 'GBP', 'CNY', 'SAR', 'AED', 'EGP'])
                            .map((code) => SearchableDropdownItem<String>(
                                  value: code,
                                  label: code,
                                ))
                            .toList(),
                        onChanged: (val) => setState(() => _form4Currency = val ?? 'USD'),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: SearchableDropdownField<int>(
                              labelText: context.l10n.issuingBankLabel,
                              hintText: context.l10n.selectBankHint,
                              value: _selectedBankId,
                              isRequired: true,
                              items: banksList.map((b) => SearchableDropdownItem<int>(
                                value: b.providerId ?? 0,
                                label: '${b.partnerName} (${b.partnerCode})',
                              )).toList(),
                              onChanged: (val) {
                                setState(() => _selectedBankId = val);
                                final b = banksList.where((p) => p.providerId == val).firstOrNull;
                                if (b != null) _bankName = b.partnerName;
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _bankAmountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : Colors.black87),
                              decoration: InputDecoration(
                                labelText: context.l10n.bankAmountLabel,
                                prefixIcon: const Icon(Icons.attach_money),
                                suffixText: _form4Currency,
                                border: const OutlineInputBorder(),
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? context.l10n.requiredField : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: SearchableDropdownField<String>(
                              labelText: context.l10n.transferCurrencyLabel,
                              hintText: context.l10n.selectCurrencyHint,
                              value: _form4Currency,
                              isRequired: true,
                              items: (currencies.isNotEmpty ? currencies.map((c) => c.currencyCode).toSet() : ['USD', 'EUR', 'GBP', 'CNY', 'SAR', 'AED', 'EGP'])
                                  .map((code) => SearchableDropdownItem<String>(
                                        value: code,
                                        label: code,
                                      ))
                                  .toList(),
                              onChanged: (val) => setState(() => _form4Currency = val ?? 'USD'),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Inputs Row 2: Date, Notes
                    if (isMobile) ...[
                      TextFormField(
                        controller: _form4RequestDateCtrl,
                        style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : Colors.black87),
                        decoration: InputDecoration(
                          labelText: context.l10n.bankRequestDateLabel,
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _form4NotesCtrl,
                        style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : Colors.black87),
                        decoration: InputDecoration(
                          labelText: context.l10n.bankNotesLabel,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _form4RequestDateCtrl,
                              style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : Colors.black87),
                              decoration: InputDecoration(
                                labelText: context.l10n.bankRequestDateLabel,
                                prefixIcon: const Icon(Icons.calendar_today),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _form4NotesCtrl,
                              style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : Colors.black87),
                              decoration: InputDecoration(
                                labelText: context.l10n.bankNotesLabel,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Documents Checklist
                    Text(
                      context.l10n.form4ChecklistSectionTitle,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.wcagCobalt),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        _buildChecklistItem('proforma_invoice', context.l10n.form4ItemProformaInvoice, true, isDark),
                        _buildChecklistItem('packing_list', context.l10n.form4ItemPackingList, true, isDark),
                        _buildChecklistItem('certificate_of_origin', context.l10n.form4ItemCertificateOfOrigin, true, isDark),
                        _buildChecklistItem('bill_of_lading', context.l10n.form4ItemBillOfLading, true, isDark),
                        _buildChecklistItem('acid_notice', context.l10n.form4ItemAcidNotice, true, isDark),
                        _buildChecklistItem('marine_insurance', context.l10n.form4ItemMarineInsurance, false, isDark),
                        _buildChecklistItem('bank_application', context.l10n.form4ItemBankApplication, true, isDark),
                        _buildChecklistItem('admin_fee_receipt', context.l10n.form4ItemAdminFeeReceipt, false, isDark),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        ElevatedButton.icon(
                          key: const Key('saveForm4SubmitBtn'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.wcagCobalt,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _isSavingForm4 ? null : _saveBankingDoc,
                          icon: _isSavingForm4
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.save),
                          label: Text(
                            _isSavingForm4
                                ? context.l10n.loading
                                : _editingBankDocId != null
                                    ? context.l10n.updateForm4Button
                                    : context.l10n.saveForm4Button,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
                          onPressed: () => setState(() => _selectedSubTab = 1),
                          icon: const Icon(Icons.history_edu),
                          label: Text(context.l10n.goToBankRegistryButton),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChecklistItem(String key, String title, bool isRequired, bool isDark) {
    final isChecked = _form4DocsChecklist[key] ?? false;
    return InkWell(
      onTap: () => setState(() => _form4DocsChecklist[key] = !isChecked),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isChecked
              ? (isDark ? AppTheme.wcagCobalt.withOpacity(0.2) : Colors.blue.shade50)
              : (isDark ? AppTheme.darkSurface : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isChecked
                ? AppTheme.wcagCobalt
                : (isDark ? AppTheme.darkBorder : Colors.grey.shade300),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isChecked ? Icons.check_box : Icons.check_box_outline_blank,
              size: 18,
              color: isChecked
                  ? AppTheme.wcagCobalt
                  : (isDark ? AppTheme.darkTextSecondary : Colors.grey),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.charcoal,
                ),
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              const Text('*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
      ),
    );
  }

  // --- SUB-VIEW 1: REGISTRY TAB ---
  Widget _buildForm4HistoryRegistryTab() {
    final bankingDocs = ref.watch(bankingDocumentsProvider).valueOrNull ?? [];
    final importFiles = ref.watch(importFilesProvider).valueOrNull ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = bankingDocs.where((d) {
      final matchesSearch = _form4SearchQuery.isEmpty ||
          d.bankDocCode.toLowerCase().contains(_form4SearchQuery.toLowerCase()) ||
          d.bankName.toLowerCase().contains(_form4SearchQuery.toLowerCase()) ||
          (d.importFileCode != null && d.importFileCode!.toLowerCase().contains(_form4SearchQuery.toLowerCase()));
      return matchesSearch;
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Toolbar
            if (isMobile) ...[
              TextField(
                key: const Key('bankRegistrySearchInput'),
                decoration: InputDecoration(
                  hintText: context.l10n.searchBankRegistryHint,
                  hintStyle: TextStyle(color: isDark ? AppTheme.darkTextSecondary : Colors.grey.shade500),
                  prefixIcon: Icon(Icons.search, color: isDark ? AppTheme.darkTextSecondary : Colors.grey.shade600),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : Colors.grey.shade300),
                  ),
                  filled: true,
                  fillColor: isDark ? AppTheme.darkSurface : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : Colors.black87),
                onChanged: (val) => setState(() => _form4SearchQuery = val),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    key: const Key('subtab1NewForm4Btn'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.wcagCobalt,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: () {
                      _resetForm4Form();
                      setState(() => _selectedSubTab = 0);
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(context.l10n.newForm4RequestButton),
                  ),
                  OutlinedButton.icon(
                    key: const Key('subtab1SearchAndCloneBtn'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? AppTheme.darkTextPrimary : AppTheme.charcoal,
                      side: BorderSide(color: isDark ? AppTheme.darkBorder : Colors.grey.shade400),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onPressed: _openSearchAndCloneBankForm4Dialog,
                    icon: const Icon(Icons.copy_all, size: 18, color: AppTheme.wcagCobalt),
                    label: Text(context.l10n.searchAndCloneBankForm4Btn),
                  ),
                  OutlinedButton.icon(
                    key: const Key('bankRegistryCopyBtn'),
                    icon: const Icon(Icons.copy, size: 16),
                    label: Text(Localizations.localeOf(context).languageCode == 'ar' ? 'نسخ الجدول' : 'Copy Table'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? AppTheme.wcagCobalt : AppTheme.charcoal,
                      side: BorderSide(color: isDark ? AppTheme.wcagCobalt : AppTheme.charcoal),
                    ),
                    onPressed: () => _copyBankForm4AsTsv(filtered, importFiles),
                  ),
                  OutlinedButton.icon(
                    key: const Key('bankRegistryExcelBtn'),
                    icon: const Icon(Icons.table_chart, size: 16, color: Colors.green),
                    label: Text(Localizations.localeOf(context).languageCode == 'ar' ? 'تصدير Excel' : 'Export Excel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green.shade700,
                      side: const BorderSide(color: Colors.green),
                    ),
                    onPressed: () => _exportBankForm4ToExcel(filtered, importFiles),
                  ),
                  OutlinedButton.icon(
                    key: const Key('bankRegistryPdfBtn'),
                    icon: const Icon(Icons.picture_as_pdf, size: 16, color: Colors.red),
                    label: Text(Localizations.localeOf(context).languageCode == 'ar' ? 'تصدير PDF' : 'Export PDF'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: const BorderSide(color: Colors.red),
                    ),
                    onPressed: () => _exportBankForm4ToPdf(filtered, importFiles),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('bankRegistrySearchInput'),
                      decoration: InputDecoration(
                        hintText: context.l10n.searchBankRegistryHint,
                        hintStyle: TextStyle(color: isDark ? AppTheme.darkTextSecondary : Colors.grey.shade500),
                        prefixIcon: Icon(Icons.search, color: isDark ? AppTheme.darkTextSecondary : Colors.grey.shade600),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : Colors.grey.shade300),
                        ),
                        filled: true,
                        fillColor: isDark ? AppTheme.darkSurface : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : Colors.black87),
                      onChanged: (val) => setState(() => _form4SearchQuery = val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    key: const Key('bankRegistryCopyBtn'),
                    icon: const Icon(Icons.copy, size: 16),
                    label: Text(Localizations.localeOf(context).languageCode == 'ar' ? 'نسخ الجدول' : 'Copy Table'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? AppTheme.wcagCobalt : AppTheme.charcoal,
                      side: BorderSide(color: isDark ? AppTheme.wcagCobalt : AppTheme.charcoal),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    onPressed: () => _copyBankForm4AsTsv(filtered, importFiles),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    key: const Key('bankRegistryExcelBtn'),
                    icon: const Icon(Icons.table_chart, size: 16, color: Colors.green),
                    label: Text(Localizations.localeOf(context).languageCode == 'ar' ? 'تصدير Excel' : 'Export Excel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green.shade700,
                      side: const BorderSide(color: Colors.green),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    onPressed: () => _exportBankForm4ToExcel(filtered, importFiles),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    key: const Key('bankRegistryPdfBtn'),
                    icon: const Icon(Icons.picture_as_pdf, size: 16, color: Colors.red),
                    label: Text(Localizations.localeOf(context).languageCode == 'ar' ? 'تصدير PDF' : 'Export PDF'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    onPressed: () => _exportBankForm4ToPdf(filtered, importFiles),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    key: const Key('subtab1SearchAndCloneBtn'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? AppTheme.darkTextPrimary : AppTheme.charcoal,
                      side: BorderSide(color: isDark ? AppTheme.darkBorder : Colors.grey.shade400),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onPressed: _openSearchAndCloneBankForm4Dialog,
                    icon: const Icon(Icons.copy_all, color: AppTheme.wcagCobalt),
                    label: Text(context.l10n.searchAndCloneBankForm4Btn),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    key: const Key('subtab1NewForm4Btn'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.wcagCobalt,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    ),
                    onPressed: () {
                      _resetForm4Form();
                      setState(() => _selectedSubTab = 0);
                    },
                    icon: const Icon(Icons.add),
                    label: Text(context.l10n.newForm4RequestButton),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),

            // Registry Table or Empty State
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCardBackground : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppTheme.darkBorder : Colors.grey.shade300),
              ),
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 48, color: isDark ? AppTheme.darkTextSecondary : Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            context.l10n.noBankForm4Found,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppTheme.darkTextSecondary : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SelectionArea(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 750),
                        child: DataTable(
                    headingRowColor: WidgetStateProperty.all(isDark ? AppTheme.darkSurface : Colors.grey.shade100),
                    columns: [
                      DataColumn(label: Text(context.l10n.actionCol, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextPrimary : null))),
                      DataColumn(label: Text(context.l10n.documentCodeCol, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextPrimary : null))),
                      DataColumn(label: Text(context.l10n.importFile, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextPrimary : null))),
                      DataColumn(label: Text(context.l10n.certifiedBankCol, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextPrimary : null))),
                      DataColumn(label: Text(context.l10n.amountAndCurrencyCol, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextPrimary : null))),
                      DataColumn(label: Text(context.l10n.requestDateCol, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextPrimary : null))),
                      DataColumn(label: Text(context.l10n.endorsementStatusCol, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextPrimary : null))),
                    ],
                    rows: filtered.map((d) {
                      final isAr = Localizations.localeOf(context).languageCode == 'ar';
                      final rawCode = d.importFileCode ?? (d.importFileId != null ? 'IMP-${d.importFileId}' : '');
                      final shipName = DisplayNameResolver.resolveShipmentNameByCode(rawCode, shipments: importFiles, isArabic: isAr);
                      final shipTitle = DisplayNameResolver.resolveShipmentTitleByCode(rawCode, shipments: importFiles, isArabic: isAr);
                      final statusLabel = d.status == 'Received' ? context.l10n.endorsedStatusBadge : context.l10n.bankProcessingStatusBadge;
                      final formattedDate = d.requestDate ?? d.issueDate.substring(0, min(10, d.issueDate.length));
                      final formattedAmount = '${d.amount.toStringAsFixed(2)} ${d.currencyCode}';
                      final rowSummary = '${d.bankDocCode}\t$shipTitle\t${d.bankName}\t$formattedAmount\t$formattedDate\t$statusLabel';

                      return DataRow(
                        cells: [
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: AppTheme.wcagCobalt, size: 18),
                                  tooltip: context.l10n.edit,
                                  onPressed: () => _loadForm4ForEdit(d),
                                ),
                                IconButton(
                                  key: Key('cloneBankForm4RowBtn_${d.bankDocId}'),
                                  icon: const Icon(Icons.copy_all, color: AppTheme.wcagCobalt, size: 18),
                                  tooltip: context.l10n.cloneBankForm4RecordTooltip,
                                  onPressed: () => _onCloneBankDocRow(d),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            CopyableTableCell(
                              value: d.bankDocCode,
                              rowSummary: rowSummary,
                              child: Text(d.bankDocCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.wcagCobalt)),
                            ),
                          ),
                          DataCell(
                            CopyableTableCell(
                              value: shipTitle,
                              rowSummary: rowSummary,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    shipName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.charcoal,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (rawCode.isNotEmpty)
                                    Container(
                                      margin: const EdgeInsets.only(top: 2),
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppTheme.wcagCobalt.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        rawCode,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isDark ? AppTheme.darkTextSecondary : Colors.grey.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          DataCell(
                            CopyableTableCell(
                              value: d.bankName,
                              rowSummary: rowSummary,
                              child: Text(d.bankName, style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : null)),
                            ),
                          ),
                          DataCell(
                            CopyableTableCell(
                              value: formattedAmount,
                              rowSummary: rowSummary,
                              child: Text(formattedAmount, style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : null)),
                            ),
                          ),
                          DataCell(
                            CopyableTableCell(
                              value: formattedDate,
                              rowSummary: rowSummary,
                              child: Text(formattedDate, style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : null)),
                            ),
                          ),
                          DataCell(
                            CopyableTableCell(
                              value: statusLabel,
                              rowSummary: rowSummary,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: d.status == 'Received'
                                      ? (isDark ? const Color(0xFF064E3B) : Colors.green.shade50)
                                      : (isDark ? const Color(0xFF78350F) : Colors.amber.shade50),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: d.status == 'Received'
                                        ? (isDark ? const Color(0xFF059669) : Colors.green.shade300)
                                        : (isDark ? const Color(0xFFD97706) : Colors.amber.shade300),
                                  ),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: d.status == 'Received'
                                        ? (isDark ? const Color(0xFF6EE7B7) : Colors.green.shade800)
                                        : (isDark ? const Color(0xFFFDE68A) : Colors.amber.shade900),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
          ],
        );
      },
    );
  }

  Future<void> _saveBankingDoc() async {
    if (!_bankFormKey.currentState!.validate()) return;
    if (_form4ImportFileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.selectImportFileFirst), backgroundColor: AppTheme.crimson),
      );
      return;
    }

    setState(() => _isSavingForm4 = true);
    try {
      final payload = {
        'import_file_id': _form4ImportFileId,
        'doc_type': _bankDocType,
        'bank_id': _selectedBankId,
        'bank_name': _bankName,
        'amount': double.tryParse(_bankAmountController.text) ?? 0.0,
        'currency_code': _form4Currency,
        'request_date': _form4RequestDateCtrl.text.trim(),
        'notes': _form4NotesCtrl.text.trim(),
      };

      if (_editingBankDocId != null) {
        await ref.read(bankingDocumentsProvider.notifier).updateBankingDocument(_editingBankDocId!, payload);
      } else {
        await ref.read(bankingDocumentsProvider.notifier).createBankingDocument(payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.form4SavedSuccess), backgroundColor: AppTheme.emerald),
        );
        _resetForm4Form();
        setState(() => _selectedSubTab = 1);
      }
    } catch (e) {
      if (mounted) {
        showErrorDetailsDialog(context, title: context.l10n.form4SaveError, error: e);
      }
    } finally {
      if (mounted) setState(() => _isSavingForm4 = false);
    }
  }

  Future<void> _exportBankForm4ToExcel(List<dynamic> list, List<ImportFileModel> importFiles) async {
    final headers = [
      context.l10n.documentCodeCol,
      context.l10n.importFile,
      context.l10n.certifiedBankCol,
      context.l10n.amountAndCurrencyCol,
      context.l10n.requestDateCol,
      context.l10n.endorsementStatusCol,
    ];
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final rows = list.map((d) {
      final rawCode = d.importFileCode ?? (d.importFileId != null ? 'IMP-${d.importFileId}' : '');
      final shipTitle = DisplayNameResolver.resolveShipmentTitleByCode(rawCode, shipments: importFiles, isArabic: isAr);
      final statusLabel = d.status == 'Received' ? context.l10n.endorsedStatusBadge : context.l10n.bankProcessingStatusBadge;
      final formattedDate = d.requestDate ?? (d.issueDate.length >= 10 ? d.issueDate.substring(0, 10) : d.issueDate);
      final formattedAmount = '${d.amount.toStringAsFixed(2)} ${d.currencyCode}';

      return [
        d.bankDocCode,
        shipTitle,
        d.bankName,
        formattedAmount,
        formattedDate,
        statusLabel,
      ];
    }).toList();

    await TableExportService.exportTableToExcel(
      context: context,
      headers: headers,
      rows: rows,
      stageName: isAr ? 'سجل النماذج البنكية' : 'Bank Form 4 Registry',
      importFileNameOrCode: 'Bank_Form4_Registry',
    );
  }

  Future<void> _exportBankForm4ToPdf(List<dynamic> list, List<ImportFileModel> importFiles) async {
    final headers = [
      context.l10n.documentCodeCol,
      context.l10n.importFile,
      context.l10n.certifiedBankCol,
      context.l10n.amountAndCurrencyCol,
      context.l10n.requestDateCol,
      context.l10n.endorsementStatusCol,
    ];
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final rows = list.map((d) {
      final rawCode = d.importFileCode ?? (d.importFileId != null ? 'IMP-${d.importFileId}' : '');
      final shipTitle = DisplayNameResolver.resolveShipmentTitleByCode(rawCode, shipments: importFiles, isArabic: isAr);
      final statusLabel = d.status == 'Received' ? context.l10n.endorsedStatusBadge : context.l10n.bankProcessingStatusBadge;
      final formattedDate = d.requestDate ?? (d.issueDate.length >= 10 ? d.issueDate.substring(0, 10) : d.issueDate);
      final formattedAmount = '${d.amount.toStringAsFixed(2)} ${d.currencyCode}';

      return [
        d.bankDocCode,
        shipTitle,
        d.bankName,
        formattedAmount,
        formattedDate,
        statusLabel,
      ];
    }).toList();

    await TableExportService.exportTableToPdf(
      context: context,
      headers: headers,
      rows: rows,
      stageName: isAr ? 'سجل النماذج البنكية' : 'Bank Form 4 Registry',
      importFileNameOrCode: 'Bank_Form4_Registry',
    );
  }

  void _copyBankForm4AsTsv(List<dynamic> list, List<ImportFileModel> importFiles) {
    final headers = [
      context.l10n.documentCodeCol,
      context.l10n.importFile,
      context.l10n.certifiedBankCol,
      context.l10n.amountAndCurrencyCol,
      context.l10n.requestDateCol,
      context.l10n.endorsementStatusCol,
    ];
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final rows = list.map((d) {
      final rawCode = d.importFileCode ?? (d.importFileId != null ? 'IMP-${d.importFileId}' : '');
      final shipTitle = DisplayNameResolver.resolveShipmentTitleByCode(rawCode, shipments: importFiles, isArabic: isAr);
      final statusLabel = d.status == 'Received' ? context.l10n.endorsedStatusBadge : context.l10n.bankProcessingStatusBadge;
      final formattedDate = d.requestDate ?? (d.issueDate.length >= 10 ? d.issueDate.substring(0, 10) : d.issueDate);
      final formattedAmount = '${d.amount.toStringAsFixed(2)} ${d.currencyCode}';

      return [
        d.bankDocCode,
        shipTitle,
        d.bankName,
        formattedAmount,
        formattedDate,
        statusLabel,
      ];
    }).toList();

    TableCopyHelper.copyTable(context, headers, rows);
  }
}
