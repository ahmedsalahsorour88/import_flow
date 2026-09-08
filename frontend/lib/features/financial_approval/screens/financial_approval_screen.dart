import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/copyable_data_helper.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/row_actions_pill.dart';
import '../../../core/widgets/master_data_toolbar.dart';
import '../../../core/widgets/error_details_dialog.dart';
import '../../../core/widgets/vertical_stage_scaffold.dart';
import '../../currencies/providers/currencies_provider.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../../purchase_orders/providers/purchase_orders_provider.dart';
import '../../suppliers/providers/suppliers_provider.dart';
import '../models/financial_approval_model.dart';
import '../providers/financial_approval_provider.dart';
import '../services/financial_export_service.dart';
import '../widgets/saved_budgets_registry_tab.dart';
import '../../simulation/widgets/what_if_simulator_dialog.dart';
import 'swift_reconciliation_screen.dart';

class FinancialApprovalScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  final int? initialImportFileId;
  const FinancialApprovalScreen({super.key, this.initialIndex = 0, this.initialImportFileId});

  @override
  ConsumerState<FinancialApprovalScreen> createState() => _FinancialApprovalScreenState();
}

class _FinancialApprovalScreenState extends ConsumerState<FinancialApprovalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Payment Request Form State (BP-012)
  final _paymentFormKey = GlobalKey<FormState>();
  final TextEditingController _payTitleController = TextEditingController();
  final TextEditingController _supplierNameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _exchangeRateController = TextEditingController(text: '50.0');
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _swiftCodeController = TextEditingController();
  final TextEditingController _ibanController = TextEditingController();
  final TextEditingController _payNotesController = TextEditingController();
  final TextEditingController _paySwiftRawTextController = TextEditingController();

  bool _isPaySwiftExpanded = true;
  bool _isPaySwiftExtracting = false;
  Map<String, dynamic>? _payExtractedSwiftSummary;

  String _paymentType = 'Advance Payment';
  String _currencyCode = 'USD';
  DateTime _requestDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 12));
  int? _selectedSupplierId;
  int? _paySelectedImportFileId;
  BudgetPrefillModel? _payPrefillData;
  bool _isSavingPayment = false;
  bool _isLoadingPayPrefill = false;

  // Import Budget Form State (BP-013)
  final _budgetFormKey = GlobalKey<FormState>();
  final TextEditingController _bgtTitleController = TextEditingController();
  final TextEditingController _invoiceEgpController = TextEditingController(text: '0.0');
  final TextEditingController _invoiceForeignController = TextEditingController(text: '0.0');
  final TextEditingController _freightEgpController = TextEditingController(text: '0.0');
  final TextEditingController _freightForeignController = TextEditingController(text: '0.0');
  final TextEditingController _customsEgpController = TextEditingController(text: '0.0');
  final TextEditingController _clearanceEgpController = TextEditingController(text: '0.0');
  final TextEditingController _bgtExchangeRateController = TextEditingController(text: '50.0');
  final TextEditingController _bgtNotesController = TextEditingController();
  
  String _bgtInvoiceCurrency = 'USD';
  String _bgtFreightCurrency = 'USD';
  int? _bgtSelectedImportFileId;
  BudgetPrefillModel? _bgtPrefillData;
  ImportBudgetModel? _lastSavedBudget;
  bool _isSavingBudget = false;
  bool _isLoadingBgtPrefill = false;

  // Search & Filter
  String _searchQuery = '';
  String _statusFilter = 'All';

  // Edit Mode for Tab 1 (Payment Requests)
  int? _editingPaymentId;
  String? _editingPaymentCode;

  // Edit Mode for Tab 2 (Import Budgets)
  int? _editingBudgetId;
  late final Set<int> _visitedTabs = {widget.initialIndex};

  double _getExchangeRateForCurrency(String currencyCode) {
    if (currencyCode.toUpperCase() == 'EGP') return 1.0;
    final currencies = ref.read(currenciesProvider).valueOrNull ?? [];
    final cur = currencies.where((c) => c.currencyCode.toUpperCase() == currencyCode.toUpperCase()).firstOrNull;
    if (cur != null) {
      if (cur.isBaseCurrency) return 1.0;
      if (cur.latestCommercialRate != null && cur.latestCommercialRate! > 0) {
        return cur.latestCommercialRate!;
      }
    }
    return 50.0;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: widget.initialIndex);
    _tabController.addListener(() {
      if (!_visitedTabs.contains(_tabController.index)) {
        setState(() => _visitedTabs.add(_tabController.index));
      }
    });
    Future.microtask(() {
      if (!ref.read(currenciesProvider).isLoading) {
        ref.read(currenciesProvider.notifier).fetchCurrencies();
      }
      if (!ref.read(importFilesProvider).isLoading) {
        ref.read(importFilesProvider.notifier).fetchImportFiles();
      }
      if (!ref.read(suppliersProvider).isLoading) {
        ref.read(suppliersProvider.notifier).fetchSuppliers();
      }
      if (!ref.read(paymentRequestsProvider).isLoading) {
        ref.read(paymentRequestsProvider.notifier).fetchPaymentRequests();
      }
      if (!ref.read(importBudgetsProvider).isLoading) {
        ref.read(importBudgetsProvider.notifier).fetchImportBudgets();
      }
      if (!ref.read(purchaseOrdersProvider).isLoading) {
        ref.read(purchaseOrdersProvider.notifier).fetchPurchaseOrders();
      }
      
      if (widget.initialImportFileId != null) {
        _onPayImportFileSelected(widget.initialImportFileId);
        _onBgtImportFileSelected(widget.initialImportFileId);
      }
    });
  }

  @override
  void didUpdateWidget(FinancialApprovalScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _visitedTabs.add(widget.initialIndex);
      _tabController.animateTo(widget.initialIndex);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _payTitleController.dispose();
    _supplierNameController.dispose();
    _amountController.dispose();
    _exchangeRateController.dispose();
    _bankNameController.dispose();
    _swiftCodeController.dispose();
    _ibanController.dispose();
    _payNotesController.dispose();
    _paySwiftRawTextController.dispose();

    _bgtTitleController.dispose();
    _invoiceEgpController.dispose();
    _invoiceForeignController.dispose();
    _freightEgpController.dispose();
    _freightForeignController.dispose();
    _customsEgpController.dispose();
    _clearanceEgpController.dispose();
    _bgtExchangeRateController.dispose();
    _bgtNotesController.dispose();
    super.dispose();
  }

  // ── Auto-Fetch & Duplicate Guard for Tab 1 (Payment Requests) ──────────────
  Future<void> _onPayImportFileSelected(int? fileId) async {
    if (fileId == null) {
      setState(() {
        _paySelectedImportFileId = null;
        _payPrefillData = null;
      });
      return;
    }

    // Check for existing Payment Request duplicate
    final existingList = ref.read(paymentRequestsProvider).valueOrNull ?? [];
    final existing = existingList.where((p) => p.importFileId == fileId && p.isActive && p.paymentId != _editingPaymentId).firstOrNull;
    if (existing != null) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                const SizedBox(width: 8),
                Text(context.l10n.duplicatePaymentRequestTitle),
              ],
            ),
            content: Text(
              context.l10n.duplicatePaymentRequestMessage(existing.paymentCode, existing.title),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _paySelectedImportFileId = null;
                    _payPrefillData = null;
                  });
                },
                child: Text(context.l10n.cancelSelection),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                icon: const Icon(Icons.visibility, color: Colors.white, size: 16),
                label: Text(context.l10n.viewAndEditPaymentRequest, style: const TextStyle(color: Colors.white)),
                onPressed: () {
                  Navigator.pop(ctx);
                  _showPaymentDetailsDialog(existing);
                },
              ),
            ],
          ),
        );
      }
      return;
    }

    setState(() {
      _paySelectedImportFileId = fileId;
      _isLoadingPayPrefill = true;
    });

    try {
      final prefill = await ref.read(importBudgetsProvider.notifier).fetchBudgetPrefill(fileId);
      final importFiles = ref.read(importFilesProvider).valueOrNull ?? [];
      final impFile = importFiles.where((f) => f.importFileId == fileId).firstOrNull;
      final poList = ref.read(purchaseOrdersProvider).purchaseOrders;
      final linkedPOs = poList.where((po) => po.importFileId == fileId || (impFile?.poIds?.contains(po.poId) ?? false)).toList();
      final currencies = ref.read(currenciesProvider).valueOrNull ?? [];

      // Calculate total invoices from linked POs or invoicesData or estimatedCost
      double calculatedInvoiceAmount = 0.0;
      String calculatedCurrency = 'USD';

      if (prefill != null && prefill.totalInvoiceAmount > 0) {
        calculatedInvoiceAmount = prefill.totalInvoiceAmount;
        calculatedCurrency = prefill.invoiceCurrency.isNotEmpty ? prefill.invoiceCurrency : 'USD';
      } else if (linkedPOs.isNotEmpty) {
        for (final po in linkedPOs) {
          final amt = po.totalAmountFob > 0
              ? po.totalAmountFob
              : po.items.fold(0.0, (s, it) => s + (it.quantity * it.unitPrice));
          calculatedInvoiceAmount += amt;
          final curr = currencies.where((c) => c.currencyId == po.currencyId).firstOrNull;
          if (curr != null) {
            calculatedCurrency = curr.currencyCode;
          }
        }
      } else if (impFile != null && impFile.invoicesData.isNotEmpty) {
        for (final inv in impFile.invoicesData) {
          calculatedInvoiceAmount += inv.amount;
          if (inv.currency.isNotEmpty) calculatedCurrency = inv.currency;
        }
      } else if (impFile != null && impFile.estimatedCost > 0) {
        calculatedInvoiceAmount = impFile.estimatedCost;
        if (impFile.estimatedCostCurrency.isNotEmpty) {
          calculatedCurrency = impFile.estimatedCostCurrency;
        }
      }

      final suppliersList = ref.read(suppliersProvider).valueOrNull ?? [];
      final targetSupId = impFile?.supplierId ?? prefill?.supplierId ?? (linkedPOs.isNotEmpty ? linkedPOs.first.supplierId : null);
      final supObj = suppliersList.where((s) => 
          (targetSupId != null && s.supplierId == targetSupId) || 
          (impFile != null && s.companyName.trim().toLowerCase() == impFile.supplierName.trim().toLowerCase()) || 
          (prefill != null && s.companyName.trim().toLowerCase() == prefill.supplierName.trim().toLowerCase())
      ).firstOrNull;

      final effectiveSupplierId = supObj?.supplierId ?? targetSupId;
      final effectiveSupplierName = supObj?.companyName ?? (impFile != null && impFile.supplierName.isNotEmpty ? impFile.supplierName : (prefill?.beneficiaryName ?? prefill?.supplierName ?? ''));
      final effectiveBankName = (supObj?.bankName != null && supObj!.bankName!.isNotEmpty) ? supObj.bankName! : (prefill?.bankName ?? '');
      final effectiveSwiftCode = (supObj?.swiftCode != null && supObj!.swiftCode!.isNotEmpty) ? supObj.swiftCode! : (prefill?.swiftCode ?? '');
      final effectiveIban = (supObj?.iban != null && supObj!.iban!.isNotEmpty)
          ? supObj.iban!
          : ((supObj?.accountNumber != null && supObj!.accountNumber!.isNotEmpty)
              ? supObj.accountNumber!
              : (prefill?.iban ?? prefill?.accountNumber ?? ''));

      if (mounted) {
        final dynamicRate = _getExchangeRateForCurrency(calculatedCurrency);
        final effRate = dynamicRate > 0 ? dynamicRate : (prefill != null && prefill.exchangeRate > 0 ? prefill.exchangeRate : 50.0);

        final fCode = impFile?.primaryNameWithCode ?? prefill?.importFileTitle ?? 'IMP-$fileId';
        final compName = impFile?.companyName ?? '';

        setState(() {
          _payPrefillData = prefill;
          _payTitleController.text = compName.isNotEmpty ? '$fCode - $compName' : fCode;
          _selectedSupplierId = effectiveSupplierId;
          _supplierNameController.text = effectiveSupplierName;
          _paymentType = (prefill != null && prefill.paymentTermsSummary.isNotEmpty) ? prefill.paymentTermsSummary : 'Advance Payment';
          
          if (calculatedInvoiceAmount > 0) {
            _amountController.text = calculatedInvoiceAmount.toStringAsFixed(2);
          } else {
            _amountController.text = '';
          }
          
          _currencyCode = calculatedCurrency;
          _exchangeRateController.text = effRate.toStringAsFixed(2);
          _bankNameController.text = effectiveBankName;
          _swiftCodeController.text = effectiveSwiftCode;
          _ibanController.text = effectiveIban;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingPayPrefill = false);
    }
  }

  // ── Auto-Fetch & Duplicate Guard for Tab 2 (Budget Approval) ───────────────
  Future<void> _onBgtImportFileSelected(int? fileId) async {
    if (fileId == null) {
      setState(() {
        _bgtSelectedImportFileId = null;
        _bgtPrefillData = null;
      });
      return;
    }

    // Check for existing Budget Approval duplicate
    final existingList = ref.read(importBudgetsProvider).valueOrNull ?? [];
    final existing = existingList.where((b) => b.importFileId == fileId && b.isActive && b.budgetId != _editingBudgetId).firstOrNull;
    if (existing != null) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                const SizedBox(width: 8),
                Text(context.l10n.duplicateBudgetTitle),
              ],
            ),
            content: Text(
              context.l10n.duplicateBudgetMessage(existing.budgetCode, existing.title),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _bgtSelectedImportFileId = null;
                    _bgtPrefillData = null;
                  });
                },
                child: Text(context.l10n.cancelSelection),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald),
                icon: const Icon(Icons.print, color: Colors.white, size: 16),
                label: Text(context.l10n.viewAndPrintBudget, style: const TextStyle(color: Colors.white)),
                onPressed: () {
                  Navigator.pop(ctx);
                  _showBudgetDetailsDialog(existing);
                },
              ),
            ],
          ),
        );
      }
      return;
    }

    setState(() {
      _bgtSelectedImportFileId = fileId;
      _isLoadingBgtPrefill = true;
    });

    try {
      final prefill = await ref.read(importBudgetsProvider.notifier).fetchBudgetPrefill(fileId);
      final importFiles = ref.read(importFilesProvider).valueOrNull ?? [];
      final impFile = importFiles.where((f) => f.importFileId == fileId).firstOrNull;
      final poList = ref.read(purchaseOrdersProvider).purchaseOrders;
      final linkedPOs = poList.where((po) => po.importFileId == fileId || (impFile?.poIds?.contains(po.poId) ?? false)).toList();
      final currencies = ref.read(currenciesProvider).valueOrNull ?? [];

      double calculatedInvoiceAmount = 0.0;
      String calculatedCurrency = 'USD';

      if (prefill != null && prefill.totalInvoiceAmount > 0) {
        calculatedInvoiceAmount = prefill.totalInvoiceAmount;
        calculatedCurrency = prefill.invoiceCurrency.isNotEmpty ? prefill.invoiceCurrency : 'USD';
      } else if (linkedPOs.isNotEmpty) {
        for (final po in linkedPOs) {
          final amt = po.totalAmountFob > 0
              ? po.totalAmountFob
              : po.items.fold(0.0, (s, it) => s + (it.quantity * it.unitPrice));
          calculatedInvoiceAmount += amt;
          final curr = currencies.where((c) => c.currencyId == po.currencyId).firstOrNull;
          if (curr != null) {
            calculatedCurrency = curr.currencyCode;
          }
        }
      } else if (impFile != null && impFile.invoicesData.isNotEmpty) {
        for (final inv in impFile.invoicesData) {
          calculatedInvoiceAmount += inv.amount;
          if (inv.currency.isNotEmpty) calculatedCurrency = inv.currency;
        }
      } else if (impFile != null && impFile.estimatedCost > 0) {
        calculatedInvoiceAmount = impFile.estimatedCost;
        if (impFile.estimatedCostCurrency.isNotEmpty) {
          calculatedCurrency = impFile.estimatedCostCurrency;
        }
      }

      if (mounted) {
        final dynamicRate = _getExchangeRateForCurrency(calculatedCurrency);
        final effRate = dynamicRate > 0 ? dynamicRate : (prefill != null && prefill.exchangeRate > 0 ? prefill.exchangeRate : 50.0);

        final freightCost = prefill?.estimatedFreightCost ?? 0.0;
        final freightCurr = (prefill != null && prefill.freightCurrency.isNotEmpty) ? prefill.freightCurrency : 'USD';
        final freightRate = _getExchangeRateForCurrency(freightCurr);
        final freightEgp = freightCost * (freightRate > 0 ? freightRate : effRate);

        final customsDutiesEgp = prefill?.estimatedCustomsDutiesEgp ?? 0.0;
        final clearanceFeesEgp = prefill?.estimatedClearanceFeesEgp ?? 0.0;

        final fCode = impFile?.primaryNameWithCode ?? prefill?.importFileTitle ?? 'IMP-$fileId';
        final compName = impFile?.companyName ?? '';

        setState(() {
          _bgtPrefillData = prefill;
          _bgtTitleController.text = compName.isNotEmpty ? '$fCode - $compName' : fCode;
          
          _invoiceForeignController.text = calculatedInvoiceAmount > 0 ? calculatedInvoiceAmount.toStringAsFixed(2) : '0.00';
          _bgtInvoiceCurrency = calculatedCurrency;
          _invoiceEgpController.text = (calculatedInvoiceAmount * effRate).toStringAsFixed(2);
          
          _freightForeignController.text = freightCost.toStringAsFixed(2);
          _bgtFreightCurrency = freightCurr;
          _freightEgpController.text = freightEgp.toStringAsFixed(2);
          
          _customsEgpController.text = customsDutiesEgp.toStringAsFixed(2);
          _clearanceEgpController.text = clearanceFeesEgp.toStringAsFixed(2);
          _bgtExchangeRateController.text = effRate.toStringAsFixed(2);
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingBgtPrefill = false);
    }
  }

  Future<void> _savePaymentRequest() async {
    if (!_paymentFormKey.currentState!.validate()) return;

    setState(() => _isSavingPayment = true);
    try {
      final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
      final rate = double.tryParse(_exchangeRateController.text.trim()) ?? 50.0;

      final payload = {
        'title': _payTitleController.text.trim(),
        'import_file_id': _paySelectedImportFileId,
        'supplier_id': _selectedSupplierId,
        'supplier_name': _supplierNameController.text.trim(),
        'beneficiary_name': _supplierNameController.text.trim(),
        'payment_type': _paymentType,
        'requested_amount': amount,
        'currency_code': _currencyCode,
        'exchange_rate': rate,
        'request_date': _requestDate.toString().substring(0, 10),
        'due_date': _dueDate.toString().substring(0, 10),
        'bank_name': _bankNameController.text.trim(),
        'swift_code': _swiftCodeController.text.trim(),
        'iban_account_no': _ibanController.text.trim(),
        'notes': _payNotesController.text.trim(),
      };

      if (_editingPaymentId != null) {
        final updated = await ref.read(paymentRequestsProvider.notifier).updatePaymentRequest(_editingPaymentId!, payload);
        if (mounted && updated != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.paymentRequestUpdatedSuccess(updated.paymentCode)), backgroundColor: AppTheme.emerald),
          );
          setState(() {
            _editingPaymentId = null;
            _editingPaymentCode = null;
          });
          _showPaymentDetailsDialog(updated);
        }
      } else {
        final created = await ref.read(paymentRequestsProvider.notifier).createPaymentRequest(payload);
        if (mounted && created != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.paymentRequestCreatedSuccess(created.paymentCode)), backgroundColor: AppTheme.emerald),
          );
          _showPaymentDetailsDialog(created);
        }
      }
    } catch (e) {
      if (mounted) {
        await showErrorDetailsDialog(
          context,
          title: context.l10n.savePaymentFailedTitle,
          error: e,
          onRetry: () async {
            await _savePaymentRequest();
          },
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingPayment = false);
    }
  }

  void _loadPaymentRequestForEdit(PaymentRequestModel p) {
    setState(() {
      _visitedTabs.add(0);
      _editingPaymentId = p.paymentId;
      _editingPaymentCode = p.paymentCode;
      _paySelectedImportFileId = p.importFileId;
      _payTitleController.text = p.title;
      _selectedSupplierId = p.supplierId;
      _supplierNameController.text = p.beneficiaryName ?? p.supplierName;
      _paymentType = p.paymentType;
      _amountController.text = p.requestedAmount.toStringAsFixed(2);
      _currencyCode = p.currencyCode;
      _exchangeRateController.text = p.exchangeRate.toStringAsFixed(2);
      _bankNameController.text = p.bankName ?? '';
      _swiftCodeController.text = p.swiftCode ?? '';
      _ibanController.text = p.ibanAccountNo ?? '';
      _payNotesController.text = p.notes ?? '';
      _dueDate = DateTime.tryParse(p.dueDate) ?? DateTime.now().add(const Duration(days: 12));
      _requestDate = p.requestDate.isNotEmpty ? (DateTime.tryParse(p.requestDate) ?? DateTime.now()) : DateTime.now();
    });
    _tabController.animateTo(0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.paymentLoadedForEditMsg(p.paymentCode)),
        backgroundColor: AppTheme.cobalt,
      ),
    );
  }

  void _loadBudgetForEdit(ImportBudgetModel b) {
    setState(() {
      _visitedTabs.add(1);
      _editingBudgetId = b.budgetId;
      _bgtTitleController.text = b.title;
      _bgtSelectedImportFileId = b.importFileId;
      _invoiceForeignController.text = b.invoiceAmountForeign.toStringAsFixed(2);
      _bgtInvoiceCurrency = b.invoiceCurrency;
      _invoiceEgpController.text = b.invoiceAmountEgp.toStringAsFixed(2);
      _freightForeignController.text = b.freightCostForeign.toStringAsFixed(2);
      _bgtFreightCurrency = b.freightCurrency;
      _freightEgpController.text = b.freightCostEgp.toStringAsFixed(2);
      _customsEgpController.text = b.customsDutiesEgp.toStringAsFixed(2);
      _clearanceEgpController.text = b.clearanceInlandEgp.toStringAsFixed(2);
      _bgtExchangeRateController.text = b.exchangeRate.toStringAsFixed(2);
      _bgtNotesController.text = b.notes ?? '';
      _lastSavedBudget = b;
    });
    _tabController.animateTo(1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.budgetLoadedForEditMsg(b.budgetCode)),
        backgroundColor: AppTheme.cobalt,
      ),
    );
  }

  Future<void> _confirmDeletePaymentRequest(PaymentRequestModel p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_rounded, color: Colors.orange, size: 22),
            const SizedBox(width: 8),
            Text(context.l10n.confirmDeletePaymentTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(context.l10n.confirmDeletePaymentMessage(p.paymentCode, p.title)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.l10n.cancel)),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson),
            icon: const Icon(Icons.delete, color: Colors.white, size: 16),
            label: Text(context.l10n.delete, style: const TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(paymentRequestsProvider.notifier).softDeletePaymentRequest(p.paymentId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.paymentDeletedSuccess(p.paymentCode)), backgroundColor: AppTheme.emerald),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.deleteErrorMsg(e.toString())), backgroundColor: AppTheme.crimson),
          );
        }
      }
    }
  }

  void _applySwiftParsedData(Map<String, dynamic> p, {String? fileName}) {
    setState(() {
      _payExtractedSwiftSummary = p;
      if (p['amount'] != null && (p['amount'] as num) > 0) {
        _amountController.text = (p['amount'] as num).toString();
      }
      if (p['currency'] != null && (p['currency'] as String).isNotEmpty) {
        _currencyCode = (p['currency'] as String).toUpperCase();
        _exchangeRateController.text = _getExchangeRateForCurrency(_currencyCode).toStringAsFixed(2);
      }
      if (p['beneficiary_name'] != null && (p['beneficiary_name'] as String).isNotEmpty) {
        _supplierNameController.text = p['beneficiary_name'];
        // Auto-match supplier from Master Data
        final suppliers = ref.read(suppliersProvider).valueOrNull ?? [];
        final bName = (p['beneficiary_name'] as String).toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        final matchedSup = suppliers.where((s) {
          final sName = s.companyName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
          return sName.isNotEmpty && (sName.contains(bName) || bName.contains(sName));
        }).firstOrNull;
        if (matchedSup != null) {
          _selectedSupplierId = matchedSup.supplierId;
          if (matchedSup.bankName != null && matchedSup.bankName!.isNotEmpty) {
            _bankNameController.text = matchedSup.bankName!;
          }
          if (matchedSup.swiftCode != null && matchedSup.swiftCode!.isNotEmpty && (p['beneficiary_bank_swift'] == null || (p['beneficiary_bank_swift'] as String).isEmpty)) {
            _swiftCodeController.text = matchedSup.swiftCode!;
          }
          final supIban = matchedSup.iban ?? matchedSup.accountNumber;
          if (supIban != null && supIban.isNotEmpty && (p['beneficiary_account_or_iban'] == null || (p['beneficiary_account_or_iban'] as String).isEmpty)) {
            _ibanController.text = supIban;
          }
        }
      }
      if (p['beneficiary_bank_swift'] != null && (p['beneficiary_bank_swift'] as String).isNotEmpty) {
        _swiftCodeController.text = p['beneficiary_bank_swift'];
      }
      if (p['beneficiary_account_or_iban'] != null && (p['beneficiary_account_or_iban'] as String).isNotEmpty) {
        _ibanController.text = p['beneficiary_account_or_iban'];
      }
      if (p['value_date'] != null && (p['value_date'] as String).isNotEmpty) {
        try {
          final d = DateTime.parse(p['value_date']);
          _dueDate = d;
        } catch (_) {}
      }

      // Auto-match Import File if available
      final importFiles = ref.read(importFilesProvider).valueOrNull ?? [];
      final piNum = p['pi_number']?.toString().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final poNum = p['po_number']?.toString().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final transRef = p['transaction_reference']?.toString().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

      if (_paySelectedImportFileId == null) {
        final matchedFile = importFiles.where((f) {
          final fCode = f.importFileCode.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
          final cNum = (f.customFileNumber ?? '').toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
          final pNum = (f.poNumber ?? '').toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
          if (piNum != null && piNum.isNotEmpty && (fCode.contains(piNum) || cNum.contains(piNum) || pNum.contains(piNum))) return true;
          if (poNum != null && poNum.isNotEmpty && (fCode.contains(poNum) || cNum.contains(poNum) || pNum.contains(poNum))) return true;
          if (transRef != null && transRef.isNotEmpty && (fCode.contains(transRef) || cNum.contains(transRef))) return true;
          return false;
        }).firstOrNull;
        if (matchedFile != null) {
          _paySelectedImportFileId = matchedFile.importFileId;
        }
      }

      final l = context.l10n;
      if (_payTitleController.text.trim().isEmpty && p['beneficiary_name'] != null) {
        final refNo = p['transaction_reference'] ?? '';
        final piText = p['pi_number'] != null ? ' - PI: ${p['pi_number']}' : '';
        _payTitleController.text = '${l.swiftPaymentPrefix}: ${p['beneficiary_name']}$piText ($refNo)';
      }
      final notesParts = <String>[];
      if (p['transaction_reference'] != null) notesParts.add('SWIFT Ref: ${p['transaction_reference']}');
      if (p['pi_number'] != null) notesParts.add('PI: ${p['pi_number']}');
      if (p['ordering_customer_name'] != null) notesParts.add('${l.orderingCustomerPrefix}: ${p['ordering_customer_name']}');
      if (p['payment_details'] != null) notesParts.add('${l.paymentDetailsPrefix}: ${p['payment_details']}');
      if (notesParts.isNotEmpty) {
        _payNotesController.text = notesParts.join(' | ');
      }
    });

    if (mounted) {
      final l = context.l10n;
      final msg = fileName != null
          ? l.swiftDataExtractedSuccess(fileName)
          : l.swiftMatchedSuccess;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppTheme.emerald),
      );
    }
  }

  Map<String, dynamic> _parseSwiftClientFallback(String rawText) {
    final text = rawText.trim();
    if (text.isEmpty) return {'success': false, 'error': context.l10n.emptyTextError};

    // 1. Transaction Ref (:20)
    String? transRef;
    final refMatch = RegExp(r'(?:^|[\r\n])\s*:?20(?:/TRANSACTION\s+REFERENCE(?:\s+NUMBER)?)?\s*[:/]?\s*([^\r\n]+)', caseSensitive: false).firstMatch(text);
    if (refMatch != null) {
      final rawVal = refMatch.group(1)?.trim() ?? '';
      final parts = rawVal.split('|').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
      transRef = parts.isNotEmpty ? parts.first : rawVal;
    } else {
      final fbRef = RegExp(r'(?:Reference(?:\s+No|\s+Number)?|TRN|Ref\s*#?|Transaction\s+(?:Ref|Reference|Id)|Bank\s+Ref|رقم\s+(?:المرجع|المعاملة|الحوالة|العملية)|الرقم\s+المرجعي)\s*[:=-]?\s*([A-Za-z0-9/\-_.]+)', caseSensitive: false).firstMatch(text);
      if (fbRef != null) {
        transRef = fbRef.group(1)?.trim();
      }
    }
    if (transRef != null) {
      transRef = transRef.replaceAll(RegExp(r'^[ |:/]+|[ |:/]+$'), '');
    }

    // 2. Value Date, Currency, Amount (:32A)
    String currency = 'USD';
    double amount = 0.0;
    String? valueDate;

    final valMatch = RegExp(r'(?:^|[\r\n])\s*:?32A(?:/Value\s+Date,?\s*CCY,?\s*Amount)?\s*[:/]?\s*(\d{6})\s*([A-Za-z0-9]{3})\s*([0-9.,]+)', caseSensitive: false).firstMatch(text);
    if (valMatch != null) {
      final rawDate = valMatch.group(1)!;
      var rawCurr = valMatch.group(2)!.toUpperCase();
      if (rawCurr == 'U5D' || rawCurr == 'U50' || rawCurr == 'US0') rawCurr = 'USD';
      if (rawCurr == 'E0R' || rawCurr == 'EVR' || rawCurr == 'FUR') rawCurr = 'EUR';
      if (rawCurr == 'E6P' || rawCurr == 'ECP') rawCurr = 'EGP';
      if (rawCurr == '6BP') rawCurr = 'GBP';
      currency = rawCurr;

      final rawAmtStr = valMatch.group(3)!.trim();
      if (!rawAmtStr.contains(',') && !rawAmtStr.contains('.') && rawAmtStr.length > 4 && rawAmtStr.endsWith('00')) {
        amount = (double.tryParse(rawAmtStr) ?? 0.0) / 100.0;
      } else {
        final rawAmt = rawAmtStr.replaceAll(',', '.');
        amount = double.tryParse(rawAmt) ?? 0.0;
      }
      try {
        final yy = int.parse(rawDate.substring(0, 2));
        final mm = int.parse(rawDate.substring(2, 4));
        final dd = int.parse(rawDate.substring(4, 6));
        final y = yy < 70 ? 2000 + yy : 1900 + yy;
        valueDate = '$y-${mm.toString().padLeft(2, '0')}-${dd.toString().padLeft(2, '0')}';
      } catch (_) {}
    } else {
      final labeledAmt = RegExp(r'(?:Amount|Value|Sum|Total(?:\s+Amount)?|المبلغ|القيمة|الصافي|إجمالي\s+المبلغ)\s*[:=]?\s*(?:([A-Za-z]{3}|\$|€|£|¥)\s*([0-9.,]+)|([0-9.,]+)\s*([A-Za-z]{3}|\$|€|£|¥))', caseSensitive: false).firstMatch(text);
      if (labeledAmt != null) {
        final c1 = labeledAmt.group(1);
        final a1 = labeledAmt.group(2);
        final a2 = labeledAmt.group(3);
        final c2 = labeledAmt.group(4);
        final rawC = c1 ?? c2 ?? 'USD';
        final rawA = a1 ?? a2 ?? '0';

        if (rawC == '\$') {
          currency = 'USD';
        } else if (rawC == '€') {
          currency = 'EUR';
        } else if (rawC == '£') {
          currency = 'GBP';
        } else if (rawC == '¥') {
          currency = 'CNY';
        } else if (rawC.length == 3) {
          currency = rawC.toUpperCase();
        }

        var cleanA = rawA.trim().replaceAll(RegExp(r'\.+$'), '');
        if (cleanA.contains(',') && cleanA.contains('.')) {
          if (cleanA.indexOf(',') < cleanA.indexOf('.')) {
            cleanA = cleanA.replaceAll(',', '');
          } else {
            cleanA = cleanA.replaceAll('.', '').replaceAll(',', '.');
          }
        } else if (cleanA.contains(',')) {
          if (cleanA.split(',').last.length == 2) {
            cleanA = cleanA.replaceAll(',', '.');
          } else {
            cleanA = cleanA.replaceAll(',', '');
          }
        }
        amount = double.tryParse(cleanA) ?? 0.0;
      }
    }

    // 3. Beneficiary Customer (:59)
    String? beneficiaryAccount;
    String? beneficiaryName;
    final benMatch = RegExp(r'(?:^|[\r\n])\s*:?59[A]?\s*(?:/Beneficiary\s+Customer)?\s*[:/]?\s*(?:/([A-Za-z0-9]+))?\s*\n?([^\n\r:]+)(?:\n([^\n\r:]+))?', caseSensitive: false).firstMatch(text);
    if (benMatch != null) {
      beneficiaryAccount = benMatch.group(1)?.trim();
      beneficiaryName = benMatch.group(2)?.trim();
    } else {
      final benGen = RegExp(r'(?:Beneficiary(?:\s+Customer|\s+Name)?|Payee|To\s+the\s+order\s+of|المستفيد|المورد|اسم\s+المستفيد|اسم\s+المورد)\s*[:=]\s*([^\r\n]+)', caseSensitive: false).firstMatch(text);
      if (benGen != null) beneficiaryName = benGen.group(1)?.trim();
      final ibanGen = RegExp(r'(?:IBAN|Account(?:\s+No|\s+Number)?|رقم\s+(?:الحساب|الآيبان)|الآيبان)\s*[:=]?\s*([A-Za-z0-9]{8,34})', caseSensitive: false).firstMatch(text);
      if (ibanGen != null) beneficiaryAccount = ibanGen.group(1)?.trim();
    }

    // 4. Beneficiary Bank / SWIFT (:57A)
    String? swiftCode;
    final swiftMatch = RegExp(r'(?:^|[\r\n])\s*:?57[AD]?(?:/Account\s+with\s+Bank)?\s*[:/]?\s*([A-Za-z0-9]{8,11})', caseSensitive: false).firstMatch(text);
    if (swiftMatch != null) {
      swiftCode = swiftMatch.group(1)?.trim().toUpperCase();
    } else {
      final swiftGen = RegExp(r'(?:SWIFT(?:\s+Code)?|BIC|Bank\s+SWIFT|كود\s+السويفت|سويفت)\s*[:=]?\s*([A-Za-z0-9]{8,11})', caseSensitive: false).firstMatch(text);
      if (swiftGen != null) swiftCode = swiftGen.group(1)?.trim().toUpperCase();
    }

    // 5. Details of Payment (:70)
    String? piNumber;
    String? details;
    final dtMatch = RegExp(r'(?:^|[\r\n])\s*:?70(?:/DETAILS\s+OF\s+PAYMENT)?\s*[:/]?\s*([^\r\n:]+(?:\n[^\r\n:]+)?)', caseSensitive: false).firstMatch(text);
    if (dtMatch != null) {
      details = dtMatch.group(1)?.trim();
      final piMatch = RegExp(r'(?:PI|Proforma\s+Invoice|فاتورة\s+مبدئية)\s*(?:NO\.?|#)?\s*([A-Za-z0-9\-_.]+)', caseSensitive: false).firstMatch(details ?? '');
      if (piMatch != null) piNumber = piMatch.group(1)?.trim();
    } else {
      final piMatch = RegExp(r'(?:PI|Proforma\s+Invoice|فاتورة\s+مبدئية)\s*(?:NO\.?|#)?\s*([A-Za-z0-9\-_.]+)', caseSensitive: false).firstMatch(text);
      if (piMatch != null) piNumber = piMatch.group(1)?.trim();
    }

    // 6. Ordering Customer (:50K)
    String? orderingCustomer;
    final ordMatch = RegExp(r'(?:^|[\r\n])\s*:?50[KA]?(?:/ORDERING\s+CUST(?:OMER)?)?\s*[:/]?\s*(?:/([A-Za-z0-9]+))?\s*\n?([^\n\r:]+)(?:\n([^\n\r:]+))?', caseSensitive: false).firstMatch(text);
    if (ordMatch != null) {
      orderingCustomer = ordMatch.group(2)?.trim();
    } else {
      final ordGen = RegExp(r'(?:Ordering\s+Customer|Applicant|Sender|Remitter|الآمر\s+بالتحويل|طالب\s+التحويل|الشركة\s+المستوردة|العميل)\s*[:=]\s*([^\r\n]+)', caseSensitive: false).firstMatch(text);
      if (ordGen != null) orderingCustomer = ordGen.group(1)?.trim();
    }

    return {
      'success': true,
      'transaction_reference': transRef,
      'amount': amount,
      'currency': currency,
      'value_date': valueDate,
      'beneficiary_name': beneficiaryName,
      'beneficiary_account_or_iban': beneficiaryAccount,
      'beneficiary_bank_swift': swiftCode,
      'payment_details': details,
      'pi_number': piNumber,
      'ordering_customer_name': orderingCustomer,
    };
  }

  Future<void> _autoFillFromSwiftText(String text) async {
    setState(() => _isPaySwiftExtracting = true);
    try {
      Map<String, dynamic>? parsed;
      try {
        final res = await ref.read(paymentRequestsProvider.notifier).smartExtractSwift(rawText: text);
        if (res['success'] == true && res['parsed_swift'] != null) {
          parsed = res['parsed_swift'] as Map<String, dynamic>;
        }
      } catch (_) {
        // Fallback to client parser
      }

      if (parsed == null || ((parsed['amount'] as num?) == 0 && parsed['beneficiary_name'] == null)) {
        final clientFallback = _parseSwiftClientFallback(text);
        if (clientFallback['success'] == true) {
          parsed = clientFallback;
        }
      }

      if (parsed != null) {
        _applySwiftParsedData(parsed);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.swiftTextParseError), backgroundColor: AppTheme.orange),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isPaySwiftExtracting = false);
    }
  }

  Future<void> _autoFillFromSwiftFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'doc', 'xlsx', 'xls', 'csv', 'jpg', 'jpeg', 'png', 'webp', 'bmp', 'txt'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.bytes == null) return;

      setState(() => _isPaySwiftExtracting = true);

      final res = await ref.read(paymentRequestsProvider.notifier).smartExtractSwiftFromFile(
        fileBytes: file.bytes!,
        filename: file.name,
      );
      if (res['success'] == true && res['parsed_swift'] != null) {
        if (res['raw_text'] != null && (res['raw_text'] as String).isNotEmpty) {
          _paySwiftRawTextController.text = res['raw_text'] as String;
        }
        _applySwiftParsedData(res['parsed_swift'] as Map<String, dynamic>, fileName: file.name);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.swiftFileExtractError(res['error'].toString())), backgroundColor: AppTheme.crimson),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.swiftFileExtractError(e.toString())), backgroundColor: AppTheme.crimson),
        );
      }
    } finally {
      if (mounted) setState(() => _isPaySwiftExtracting = false);
    }
  }

  Future<void> _saveImportBudget() async {
    if (!_budgetFormKey.currentState!.validate()) return;

    setState(() => _isSavingBudget = true);
    try {
      final invForeign = double.tryParse(_invoiceForeignController.text.trim()) ?? 0.0;
      final invEgp = double.tryParse(_invoiceEgpController.text.trim()) ?? 0.0;
      final frtForeign = double.tryParse(_freightForeignController.text.trim()) ?? 0.0;
      final frtEgp = double.tryParse(_freightEgpController.text.trim()) ?? 0.0;
      final custEgp = double.tryParse(_customsEgpController.text.trim()) ?? 0.0;
      final clrEgp = double.tryParse(_clearanceEgpController.text.trim()) ?? 0.0;
      final rate = double.tryParse(_bgtExchangeRateController.text.trim()) ?? 50.0;

      final payload = {
        'title': _bgtTitleController.text.trim(),
        'import_file_id': _bgtSelectedImportFileId,
        'invoice_amount_foreign': invForeign,
        'invoice_currency': _bgtInvoiceCurrency,
        'invoice_amount_egp': invEgp,
        'freight_cost_foreign': frtForeign,
        'freight_currency': _bgtFreightCurrency,
        'freight_cost_egp': frtEgp,
        'customs_duties_egp': custEgp,
        'clearance_inland_egp': clrEgp,
        'exchange_rate': rate,
        'notes': _bgtNotesController.text.trim(),
      };

      if (_editingBudgetId != null) {
        final updated = await ref.read(importBudgetsProvider.notifier).updateImportBudget(_editingBudgetId!, payload);
        if (mounted && updated != null) {
          setState(() {
            _lastSavedBudget = updated;
            _editingBudgetId = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.budgetUpdatedSuccess(updated.budgetCode)), backgroundColor: AppTheme.emerald),
          );
          _showBudgetDetailsDialog(updated);
        }
      } else {
        final created = await ref.read(importBudgetsProvider.notifier).createImportBudget(payload);
        if (mounted && created != null) {
          setState(() => _lastSavedBudget = created);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.budgetCreatedSuccess(created.budgetCode)), backgroundColor: AppTheme.emerald),
          );
          _showBudgetDetailsDialog(created);
        }
      }
    } catch (e) {
      if (mounted) {
        await showErrorDetailsDialog(
          context,
          title: context.l10n.saveBudgetFailedTitle,
          error: e,
          onRetry: () async {
            await _saveImportBudget();
          },
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingBudget = false);
    }
  }

  void _showPaymentDetailsDialog(PaymentRequestModel pay) {
    final swiftController = TextEditingController(text: pay.swiftReferenceNo ?? '');
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.l10n.paymentRequestDetailsTitle(pay.paymentCode), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              _buildStatusBadge(pay.status),
            ],
          ),
          content: SizedBox(
            width: 650,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pay.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
                  const SizedBox(height: 6),
                  Text(context.l10n.beneficiarySupplierDetails(pay.beneficiaryName ?? pay.supplierName), style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('${context.l10n.paymentTypeLabel}: ${pay.paymentType} | ${context.l10n.requestDateLabel}: ${pay.requestDate.isNotEmpty ? pay.requestDate : "-"} | ${context.l10n.dueDateLabel}: ${pay.dueDate}'),
                  const Divider(),
                  Row(
                    children: [
                      _buildMetricBadge(context.l10n.foreignAmountMetric, '${pay.requestedAmount} ${pay.currencyCode}', AppTheme.cobalt),
                      const SizedBox(width: 10),
                      _buildMetricBadge(context.l10n.exchangeRateCol, '${pay.exchangeRate} EGP', Colors.orange),
                      const SizedBox(width: 10),
                      _buildMetricBadge(context.l10n.equivalentEgpCol, '${pay.requestedAmountEgp.toStringAsFixed(2)} EGP', Colors.green),
                    ],
                  ),
                  const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.blue.shade50.withOpacity(0.5), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.shade200)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${context.l10n.beneficiaryBankDetails}:', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                          const SizedBox(height: 4),
                          Text('${context.l10n.bankNameLabel}: ${pay.bankName ?? "-"}'),
                          Text('${context.l10n.swiftCodeLabel}: ${pay.swiftCode ?? "-"}'),
                          Text('${context.l10n.ibanAccountLabel}: ${pay.ibanAccountNo ?? "-"}'),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // ── EXPORT & SHARING ACTION TOOLBAR ────────────────────────
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.share_outlined, size: 16, color: AppTheme.cobalt),
                            const SizedBox(width: 6),
                            Text(context.l10n.exportAndShareOptionsTitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            // 1. Print / Save PDF
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.cobalt,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              icon: const Icon(Icons.print, color: Colors.white, size: 16),
                              label: Text(context.l10n.printSavePdfBtn, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                FinancialExportService.printPaymentRequestPdf(payment: pay);
                              },
                            ),
                            // 2. Export Excel
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.green),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              icon: const Icon(Icons.table_chart, color: Colors.green, size: 16),
                              label: Text(context.l10n.downloadExcelBtn, style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                              onPressed: () async {
                                final path = await FinancialExportService.exportSinglePaymentRequestToExcel(
                                  context: context,
                                  payment: pay,
                                );
                                if (path != null && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(context.l10n.excelSavedSuccess(path)), backgroundColor: Colors.green),
                                  );
                                }
                              },
                            ),
                            // 3. WhatsApp Sharing
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              icon: const Icon(Icons.chat, color: Colors.white, size: 16),
                              label: Text(context.l10n.whatsappShareBtn, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                _showWhatsAppShareDialog(pay);
                              },
                            ),
                            // 4. Email Sharing
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.orange,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              icon: const Icon(Icons.email_outlined, color: Colors.white, size: 16),
                              label: Text(context.l10n.emailShareBtn, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                _showEmailShareDialog(pay);
                              },
                            ),
                            // 5. Copy Summary
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey.shade600),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              icon: const Icon(Icons.copy, color: AppTheme.charcoal, size: 16),
                              label: Text(context.l10n.copySummaryBtn, style: const TextStyle(color: AppTheme.charcoal, fontSize: 11, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                final text = FinancialExportService.generatePaymentWhatsAppText(pay);
                                CopyHelper.copy(context, text);
                              },
                            ),
                            // 6. SWIFT Smart Reconcile & Auto Match
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple.shade700,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                              label: Text(context.l10n.extractAndMatchSwiftBtn, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                Navigator.pop(ctx);
                                setState(() => _tabController.index = 3);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (pay.status == 'Approved') ...[
                    const Divider(),
                    TextField(
                      controller: swiftController,
                      decoration: InputDecoration(labelText: context.l10n.swiftReferenceInputLabel, border: const OutlineInputBorder()),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.close)),
            if (pay.status == 'Draft' || pay.status == 'Pending Approval') ...[
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                onPressed: () async {
                  final nav = Navigator.of(context);
                  await ref.read(paymentRequestsProvider.notifier).approvePaymentRequest(pay.paymentId);
                  nav.pop();
                },
                child: Text(context.l10n.approvePaymentAction, style: const TextStyle(color: Colors.white)),
              ),
            ],
            if (pay.status == 'Approved') ...[
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald),
                onPressed: () async {
                  final nav = Navigator.of(context);
                  await ref.read(paymentRequestsProvider.notifier).executePayment(pay.paymentId, swiftRef: swiftController.text.trim());
                  nav.pop();
                },
                child: Text(context.l10n.markAsPaidAction, style: const TextStyle(color: Colors.white)),
              ),
            ],
          ],
        );
      },
    );
  }

  void _showWhatsAppShareDialog(PaymentRequestModel pay) {
    final text = FinancialExportService.generatePaymentWhatsAppText(pay);
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.chat, color: Color(0xFF25D366)),
            const SizedBox(width: 8),
            Text(context.l10n.sendPaymentWhatsAppTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 550,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: context.l10n.whatsAppNumberLabel,
                    hintText: context.l10n.whatsAppNumberHint,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.phone_android),
                  ),
                ),
                const SizedBox(height: 12),
                Text(context.l10n.messagePreviewLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEAE2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFD1D7DB)),
                  ),
                  child: SelectableText(
                    text,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black87, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.l10n.cancel)),
          OutlinedButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: Text(context.l10n.copySummaryBtn),
            onPressed: () {
              CopyHelper.copy(ctx, text);
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
            icon: const Icon(Icons.open_in_new, color: Colors.white, size: 16),
            label: Text(context.l10n.openWhatsAppBtn, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () {
              final phone = phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
              final encoded = Uri.encodeComponent(text);
              final url = phone.isNotEmpty ? 'https://wa.me/$phone?text=$encoded' : 'https://wa.me/?text=$encoded';
              FinancialExportService.launchUrlNative(url);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _showEmailShareDialog(PaymentRequestModel pay) {
    final subject = FinancialExportService.generatePaymentEmailSubject(pay);
    final body = FinancialExportService.generatePaymentEmailBody(pay);
    final toController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.email, color: AppTheme.orange),
            const SizedBox(width: 8),
            Text(context.l10n.sendPaymentEmailTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: toController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: context.l10n.recipientEmailLabel,
                    hintText: 'accounting@company.com',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.alternate_email),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.l10n.emailSubjectLabel(subject), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const Divider(height: 12),
                      SelectableText(
                        body,
                        style: const TextStyle(fontSize: 11, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.l10n.cancel)),
          OutlinedButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: Text(context.l10n.copySummaryBtn),
            onPressed: () {
              CopyHelper.copy(ctx, 'Subject: $subject\n\n$body');
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
            icon: const Icon(Icons.send, color: Colors.white, size: 16),
            label: Text(context.l10n.openEmailClientBtn, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () {
              final to = toController.text.trim();
              final encodedSubject = Uri.encodeComponent(subject);
              final encodedBody = Uri.encodeComponent(body);
              final url = 'mailto:$to?subject=$encodedSubject&body=$encodedBody';
              FinancialExportService.launchUrlNative(url);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _showBudgetDetailsDialog(ImportBudgetModel bgt) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.l10n.budgetDetailsTitle(bgt.budgetCode), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              _buildStatusBadge(bgt.budgetStatus),
            ],
          ),
          content: SizedBox(
            width: 700,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bgt.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
                  const SizedBox(height: 12),
                  
                  // Multi-currency details in modal
                  _buildConsolidatedBudgetSummary(bgt: bgt, prefill: _bgtPrefillData),
                  
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.share_outlined, size: 16, color: AppTheme.cobalt),
                            const SizedBox(width: 6),
                            Text(context.l10n.exportAndShareOptionsTitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            // 1. Print / Save PDF
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.cobalt,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              icon: const Icon(Icons.print, color: Colors.white, size: 16),
                              label: Text(context.l10n.printSavePdfBtn, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                FinancialExportService.printOrSaveBudgetPdf(
                                  budget: bgt,
                                  prefill: _bgtPrefillData,
                                );
                              },
                            ),
                            // 2. Export Excel
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.green),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              icon: const Icon(Icons.table_chart, color: Colors.green, size: 16),
                              label: Text(context.l10n.downloadExcelBtn, style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                              onPressed: () async {
                                final path = await FinancialExportService.exportBudgetToExcel(
                                  context: context,
                                  budget: bgt,
                                  prefill: _bgtPrefillData,
                                );
                                if (path != null && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(context.l10n.excelSavedSuccess(path)), backgroundColor: Colors.green),
                                  );
                                }
                              },
                            ),
                            // 3. WhatsApp Sharing
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              icon: const Icon(Icons.chat, color: Colors.white, size: 16),
                              label: Text(context.l10n.whatsappShareBtn, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                _showBudgetWhatsAppShareDialog(bgt);
                              },
                            ),
                            // 4. Email Sharing
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.orange,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              icon: const Icon(Icons.email_outlined, color: Colors.white, size: 16),
                              label: Text(context.l10n.emailShareBtn, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                _showBudgetEmailShareDialog(bgt);
                              },
                            ),
                            // 5. Copy Summary
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey.shade600),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              icon: const Icon(Icons.copy, color: AppTheme.charcoal, size: 16),
                              label: Text(context.l10n.copySummaryBtn, style: const TextStyle(color: AppTheme.charcoal, fontSize: 11, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                final text = FinancialExportService.generateBudgetWhatsAppText(bgt, _bgtPrefillData);
                                CopyHelper.copy(context, text);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.close)),
            if (bgt.budgetStatus == 'Pending Review' || bgt.budgetStatus == 'Draft') ...[
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald),
                onPressed: () async {
                  final nav = Navigator.of(context);
                  await ref.read(importBudgetsProvider.notifier).approveImportBudget(bgt.budgetId);
                  nav.pop();
                },
                child: Text(context.l10n.approveAndCertifyBudget, style: const TextStyle(color: Colors.white)),
              ),
            ],
          ],
        );
      },
    );
  }

  void _showBudgetWhatsAppShareDialog(ImportBudgetModel bgt) {
    final text = FinancialExportService.generateBudgetWhatsAppText(bgt, _bgtPrefillData);
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.chat, color: Color(0xFF25D366)),
            const SizedBox(width: 8),
            Text(context.l10n.sendBudgetWhatsAppTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 550,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: context.l10n.whatsAppNumberLabel,
                    hintText: context.l10n.whatsAppNumberHint,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.phone_android),
                  ),
                ),
                const SizedBox(height: 12),
                Text(context.l10n.messagePreviewLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEAE2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFD1D7DB)),
                  ),
                  child: SelectableText(
                    text,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black87, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.l10n.cancel)),
          OutlinedButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: Text(context.l10n.copySummaryBtn),
            onPressed: () {
              CopyHelper.copy(ctx, text);
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
            icon: const Icon(Icons.open_in_new, color: Colors.white, size: 16),
            label: Text(context.l10n.openWhatsAppBtn, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () {
              final phone = phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
              final encoded = Uri.encodeComponent(text);
              final url = phone.isNotEmpty ? 'https://wa.me/$phone?text=$encoded' : 'https://wa.me/?text=$encoded';
              FinancialExportService.launchUrlNative(url);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _showBudgetEmailShareDialog(ImportBudgetModel bgt) {
    final subject = FinancialExportService.generateBudgetEmailSubject(bgt);
    final body = FinancialExportService.generateBudgetEmailBody(bgt, _bgtPrefillData);
    final toController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.email, color: AppTheme.orange),
            const SizedBox(width: 8),
            Text(context.l10n.sendBudgetEmailTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: toController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: context.l10n.recipientEmailLabel,
                    hintText: 'cfo@company.com',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.alternate_email),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.l10n.emailSubjectLabel(subject), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const Divider(height: 12),
                      SelectableText(
                        body,
                        style: const TextStyle(fontSize: 11, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.l10n.cancel)),
          OutlinedButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: Text(context.l10n.copySummaryBtn),
            onPressed: () {
              CopyHelper.copy(ctx, 'Subject: $subject\n\n$body');
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
            icon: const Icon(Icons.send, color: Colors.white, size: 16),
            label: Text(context.l10n.openEmailClientBtn, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () {
              final to = toController.text.trim();
              final encodedSubject = Uri.encodeComponent(subject);
              final encodedBody = Uri.encodeComponent(body);
              final url = 'mailto:$to?subject=$encodedSubject&body=$encodedBody';
              FinancialExportService.launchUrlNative(url);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final suppliersState = ref.watch(suppliersProvider);
    final paymentsState = ref.watch(paymentRequestsProvider);
    final budgetsState = ref.watch(importBudgetsProvider);

    final suppliersList = suppliersState.valueOrNull ?? [];

    final tabs = [
      const VerticalNavTabItem(
        icon: Icons.payment_outlined,
        titleEn: 'Payment Requests',
        titleAr: 'طلبات السداد المالي للمورد',
      ),
      const VerticalNavTabItem(
        icon: Icons.pie_chart_outline,
        titleEn: 'Import Budget Approval',
        titleAr: 'اعتماد الميزانية الاستيرادية',
      ),
      VerticalNavTabItem(
        icon: Icons.account_balance_wallet_outlined,
        titleEn: 'Saved Budgets Registry',
        titleAr: 'سجل الميزانيات المعتمدة',
        badge: (budgetsState.valueOrNull?.length ?? 0) > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.emerald.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${budgetsState.valueOrNull?.length ?? 0}',
                  style: const TextStyle(color: AppTheme.emerald, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              )
            : null,
      ),
      VerticalNavTabItem(
        icon: Icons.history_edu_outlined,
        titleEn: 'Payment Requests Registry',
        titleAr: 'سجل طلبات السداد والتحويلات',
        badge: (paymentsState.valueOrNull?.length ?? 0) > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${paymentsState.valueOrNull?.length ?? 0}',
                  style: const TextStyle(color: AppTheme.orange, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              )
            : null,
      ),
      const VerticalNavTabItem(
        icon: Icons.auto_awesome,
        titleEn: 'SWIFT MT103 Reconciliation',
        titleAr: 'استخراج ومطابقة السويفت (MT103)',
      ),
    ];

    return VerticalStageScaffold(
      stageCode: '',
      titleEn: 'Financial Approvals & Budget Management',
      titleAr: 'الموافقات المالية وإدارة الميزانية',
      headerIcon: Icons.account_balance_wallet_outlined,
      headerColor: AppTheme.orange,
      tabs: tabs,
      selectedIndex: _tabController.index,
      onTabSelected: (index) => setState(() {
        _visitedTabs.add(index);
        _tabController.index = index;
      }),
      headerActions: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.crimson,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => const WhatIfSimulatorDialog(),
            );
          },
          icon: const Icon(Icons.analytics_outlined, size: 16),
          label: Text(
            l.whatIfSimulatorButton,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70),
          tooltip: l.liveRefreshTooltip,
          onPressed: () {
            ref.read(paymentRequestsProvider.notifier).fetchPaymentRequests();
            ref.read(importBudgetsProvider.notifier).fetchImportBudgets();
            ref.read(importFilesProvider.notifier).fetchImportFiles();
            ref.read(purchaseOrdersProvider.notifier).fetchPurchaseOrders();
            ref.read(suppliersProvider.notifier).fetchSuppliers();
            ref.read(currenciesProvider.notifier).fetchCurrencies();
          },
        ),
      ],
      body: IndexedStack(
        index: _tabController.index,
        children: [
          // ── TAB 1: PAYMENT REQUEST FORM (BP-012) ───────────────────────────
          if (_visitedTabs.contains(0))
            SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _paymentFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_editingPaymentId != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.shade300),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.edit_note, color: Colors.orange),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${l.activeEditModeBanner}: $_editingPaymentCode',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown.shade900),
                                    ),
                                  ),
                                  TextButton.icon(
                                    icon: const Icon(Icons.close, size: 16, color: Colors.red),
                                    label: Text(l.cancelEdit, style: const TextStyle(color: Colors.red)),
                                    onPressed: () {
                                      setState(() {
                                        _editingPaymentId = null;
                                        _editingPaymentCode = null;
                                        _payTitleController.clear();
                                        _supplierNameController.clear();
                                        _amountController.clear();
                                        _payNotesController.clear();
                                        _paySelectedImportFileId = null;
                                        _payPrefillData = null;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _editingPaymentId != null
                                    ? '${l.editPaymentRequestTitle} ($_editingPaymentCode)'
                                    : l.createPaymentRequestTitle,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                              ),
                              if (_isLoadingPayPrefill) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 6),

                          // Smart AI SWIFT MT103 Interactive Extractor & Auto-Fill Box
                          _buildPaySwiftExtractorWidget(),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: SearchableDropdownField<int?>(
                                  value: _paySelectedImportFileId,
                                  labelText: '${l.importFile} *',
                                  searchHintText: l.search,
                                  items: [
                                    SearchableDropdownItem<int?>(
                                      value: null,
                                      label: '-- ${l.notLinked} --',
                                    ),
                                    ...(ref.watch(importFilesProvider).valueOrNull ?? []).map((f) => SearchableDropdownItem<int?>(
                                          value: f.importFileId,
                                          label: '${f.primaryNameWithCode} - ${f.companyName}',
                                          subtitle: f.companyName,
                                        )),
                                  ],
                                  onChanged: _onPayImportFileSelected,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _payTitleController,
                                  decoration: InputDecoration(labelText: '${l.paymentTitleLabel} *', border: const OutlineInputBorder()),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? l.requiredField : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: SearchableDropdownField<int?>(
                                  value: _selectedSupplierId,
                                  labelText: l.selectSupplierFromMasterData,
                                  searchHintText: l.search,
                                  items: suppliersList
                                      .map((s) => SearchableDropdownItem<int?>(
                                            value: s.supplierId,
                                            label: s.companyName,
                                            subtitle: s.foreignExporterCountry,
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      final sup = suppliersList.firstWhere((s) => s.supplierId == val);
                                      setState(() {
                                        _selectedSupplierId = val;
                                        _supplierNameController.text = sup.companyName;
                                        if (sup.bankName != null && sup.bankName!.isNotEmpty) _bankNameController.text = sup.bankName!;
                                        if (sup.swiftCode != null && sup.swiftCode!.isNotEmpty) _swiftCodeController.text = sup.swiftCode!;
                                        if (sup.iban != null && sup.iban!.isNotEmpty) {
                                          _ibanController.text = sup.iban!;
                                        } else if (sup.accountNumber != null && sup.accountNumber!.isNotEmpty) {
                                          _ibanController.text = sup.accountNumber!;
                                        }
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _supplierNameController,
                                  decoration: InputDecoration(labelText: '${l.beneficiarySupplierLabel} *', border: const OutlineInputBorder()),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? l.requiredField : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  initialValue: _paymentType,
                                  key: ValueKey('pay_type_$_paymentType'),
                                  decoration: InputDecoration(labelText: '${l.paymentTypeLabel} *', border: const OutlineInputBorder()),
                                  onChanged: (v) => _paymentType = v,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _amountController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(labelText: '${l.requestedAmountLabel} *', border: const OutlineInputBorder()),
                                  validator: (v) => (v == null || double.tryParse(v) == null || double.parse(v) <= 0) ? l.requiredField : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SearchableDropdownField<String>(
                                  value: _currencyCode,
                                  labelText: '${l.currencyCol} *',
                                  searchHintText: l.search,
                                  items: () {
                                    final curList = ref.watch(currenciesProvider).valueOrNull ?? [];
                                    final list = curList.isNotEmpty
                                        ? curList.map((c) => SearchableDropdownItem<String>(
                                              value: c.currencyCode,
                                              label: '${c.currencyCode} - ${c.currencyName}',
                                            )).toList()
                                        : [
                                            const SearchableDropdownItem(value: 'USD', label: 'USD'),
                                            const SearchableDropdownItem(value: 'EUR', label: 'EUR'),
                                            const SearchableDropdownItem(value: 'EGP', label: 'EGP'),
                                            const SearchableDropdownItem(value: 'GBP', label: 'GBP'),
                                            const SearchableDropdownItem(value: 'CNY', label: 'CNY'),
                                            const SearchableDropdownItem(value: 'SAR', label: 'SAR'),
                                            const SearchableDropdownItem(value: 'AED', label: 'AED'),
                                          ];
                                    if (!list.any((i) => i.value == _currencyCode)) {
                                      list.add(SearchableDropdownItem(value: _currencyCode, label: _currencyCode));
                                    }
                                    return list;
                                  }(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _currencyCode = val;
                                        final rate = _getExchangeRateForCurrency(val);
                                        _exchangeRateController.text = rate.toStringAsFixed(2);
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _exchangeRateController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(labelText: '${l.exchangeRateCol} (EGP) *', border: const OutlineInputBorder()),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final d = await showDatePicker(
                                      context: context,
                                      initialDate: _requestDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2030),
                                    );
                                    if (d != null) setState(() => _requestDate = d);
                                  },
                                  child: InputDecorator(
                                    decoration: InputDecoration(labelText: '${l.requestDateLabel} *', border: const OutlineInputBorder()),
                                    child: Text(_requestDate.toString().substring(0, 10)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final d = await showDatePicker(
                                      context: context,
                                      initialDate: _dueDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2030),
                                    );
                                    if (d != null) setState(() => _dueDate = d);
                                  },
                                  child: InputDecorator(
                                    decoration: InputDecoration(labelText: '${l.dueDateLabel} *', border: const OutlineInputBorder()),
                                    child: Text(_dueDate.toString().substring(0, 10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Supplier Banking Details Card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${l.beneficiaryBankDetails}:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.cobalt)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _bankNameController,
                                        decoration: InputDecoration(labelText: l.bankNameLabel, border: const OutlineInputBorder()),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _swiftCodeController,
                                        decoration: InputDecoration(labelText: l.swiftCodeLabel, border: const OutlineInputBorder()),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _ibanController,
                                        decoration: InputDecoration(labelText: l.ibanAccountLabel, border: const OutlineInputBorder()),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Linked Purchase Orders Table for Payment Request
                          if (_payPrefillData != null && _payPrefillData!.linkedPos.isNotEmpty) ...[
                            Text('${l.linkedPurchaseOrdersTitle}:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal)),
                            const SizedBox(height: 8),
                            Table(
                              border: TableBorder.all(color: Colors.grey.shade300),
                              columnWidths: const {
                                0: FlexColumnWidth(1.5),
                                1: FlexColumnWidth(1.5),
                                2: FlexColumnWidth(2.0),
                                3: FlexColumnWidth(1.5),
                                4: FlexColumnWidth(1.2),
                                5: FlexColumnWidth(1.2),
                              },
                              children: [
                                TableRow(
                                  decoration: const BoxDecoration(color: AppTheme.charcoal),
                                  children: [
                                    Padding(padding: const EdgeInsets.all(8), child: Text(l.poNumberCol, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                    Padding(padding: const EdgeInsets.all(8), child: Text(l.projectNameCol, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                    Padding(padding: const EdgeInsets.all(8), child: Text(l.paymentTypeLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                    Padding(padding: const EdgeInsets.all(8), child: Text(l.currencyCol, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                    Padding(padding: const EdgeInsets.all(8), child: Text(l.invoiceAmount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                    Padding(padding: const EdgeInsets.all(8), child: Text(l.statusCol, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                  ],
                                ),
                                ..._payPrefillData!.linkedPos.map((po) {
                                  return TableRow(
                                    children: [
                                      Padding(padding: const EdgeInsets.all(8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [CopyableText(po.displayName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt)), if (po.displayName != po.poNumber) CopyableText(po.poNumber, style: const TextStyle(fontSize: 10, color: Colors.grey))])),
                                      Padding(padding: const EdgeInsets.all(8), child: CopyableText(po.projectName ?? '-')),
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.amber.shade200)),
                                          child: CopyableText(po.paymentTerms, style: TextStyle(fontSize: 11, color: Colors.brown.shade800, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                      Padding(padding: const EdgeInsets.all(8), child: CopyableText(po.currency, style: const TextStyle(fontWeight: FontWeight.w600))),
                                      Padding(padding: const EdgeInsets.all(8), child: CopyableText('${po.totalAmount.toStringAsFixed(2)} ${po.currency}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                                      Padding(padding: const EdgeInsets.all(8), child: CopyableText(po.status, style: const TextStyle(fontSize: 11, color: AppTheme.cobalt))),
                                    ],
                                  );
                                }),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],

                          TextFormField(
                            controller: _payNotesController,
                            decoration: InputDecoration(labelText: l.paymentNotesLabel, border: const OutlineInputBorder()),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (_editingPaymentId != null)
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.grey.shade800,
                                    side: BorderSide(color: Colors.grey.shade400),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _editingPaymentId = null;
                                      _editingPaymentCode = null;
                                      _paySelectedImportFileId = null;
                                      _payPrefillData = null;
                                      _payTitleController.clear();
                                      _supplierNameController.clear();
                                      _amountController.clear();
                                      _bankNameController.clear();
                                      _swiftCodeController.clear();
                                      _ibanController.clear();
                                      _payNotesController.clear();
                                    });
                                  },
                                  icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                                  label: Text(l.cancelEdit, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                )
                              else
                                const SizedBox.shrink(),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _editingPaymentId != null ? AppTheme.emerald : AppTheme.cobalt,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                ),
                                onPressed: _isSavingPayment ? null : _savePaymentRequest,
                                icon: _isSavingPayment
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : Icon(_editingPaymentId != null ? Icons.save : Icons.send, color: Colors.white),
                                label: Text(
                                  _editingPaymentId != null ? l.savePaymentChangesButton : l.issuePaymentRequestButton,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          else
            const SizedBox.shrink(),

          // ── TAB 2: IMPORT BUDGET APPROVAL FORM (BP-013) ────────────────────
          if (_visitedTabs.contains(1))
            SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _budgetFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(l.importBudgetSetupTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
                              if (_isLoadingBgtPrefill) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: SearchableDropdownField<int?>(
                                  value: _bgtSelectedImportFileId,
                                  labelText: '${l.importFile} *',
                                  searchHintText: l.search,
                                  items: [
                                    SearchableDropdownItem<int?>(
                                      value: null,
                                      label: '-- ${l.notLinked} --',
                                    ),
                                    ...(ref.watch(importFilesProvider).valueOrNull ?? []).map((f) => SearchableDropdownItem<int?>(
                                          value: f.importFileId,
                                          label: '${f.primaryNameWithCode} - ${f.companyName}',
                                          subtitle: f.companyName,
                                        )),
                                  ],
                                  onChanged: _onBgtImportFileSelected,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _bgtTitleController,
                                  decoration: InputDecoration(labelText: '${l.budgetTitleLabel} *', border: const OutlineInputBorder()),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? l.requiredField : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Multi-Currency Live Consolidated Breakdown Tables
                          _buildConsolidatedBudgetSummary(prefill: _bgtPrefillData),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _invoiceForeignController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(labelText: '${l.estimatedInvoiceValue} ($_bgtInvoiceCurrency)', border: const OutlineInputBorder()),
                                  onChanged: (v) {
                                    final f = double.tryParse(v) ?? 0;
                                    final r = double.tryParse(_bgtExchangeRateController.text) ?? 50;
                                    _invoiceEgpController.text = (f * r).toStringAsFixed(2);
                                    setState(() {});
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _freightForeignController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(labelText: '${l.estimatedFreightCost} ($_bgtFreightCurrency)', border: const OutlineInputBorder()),
                                  onChanged: (v) {
                                    final f = double.tryParse(v) ?? 0;
                                    final r = double.tryParse(_bgtExchangeRateController.text) ?? 50;
                                    _freightEgpController.text = (f * r).toStringAsFixed(2);
                                    setState(() {});
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _customsEgpController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(labelText: '${l.customsAndVatEstimate} (EGP)', border: const OutlineInputBorder()),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _clearanceEgpController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(labelText: '${l.clearanceAndTransportEstimate} (EGP)', border: const OutlineInputBorder()),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _bgtNotesController,
                            decoration: InputDecoration(labelText: l.budgetApprovalNotes, border: const OutlineInputBorder()),
                          ),
                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  // 1. Live Refresh
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.charcoal,
                                      side: BorderSide(color: Colors.grey.shade400),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    ),
                                    onPressed: () {
                                      ref.read(importBudgetsProvider.notifier).fetchImportBudgets();
                                      ref.read(paymentRequestsProvider.notifier).fetchPaymentRequests();
                                      ref.read(importFilesProvider.notifier).fetchImportFiles();
                                    },
                                    icon: const Icon(Icons.refresh, size: 16, color: AppTheme.cobalt),
                                    label: Text(l.refresh, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),

                                  // 2. Clear Form & Start New
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.grey.shade800,
                                      side: BorderSide(color: Colors.grey.shade400),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _editingBudgetId = null;
                                        _bgtSelectedImportFileId = null;
                                        _bgtPrefillData = null;
                                        _bgtNotesController.clear();
                                      });
                                    },
                                    icon: const Icon(Icons.cleaning_services_outlined, size: 16, color: Colors.blueGrey),
                                    label: Text(l.reset, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),

                                  // 3. Save Draft & Continue Later
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFEFF6FF),
                                      foregroundColor: AppTheme.cobalt,
                                      elevation: 0,
                                      side: const BorderSide(color: AppTheme.cobalt),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    ),
                                    onPressed: _isSavingBudget ? null : _saveImportBudget,
                                    icon: const Icon(Icons.save_outlined, size: 16, color: AppTheme.cobalt),
                                    label: Text(
                                      _editingBudgetId != null ? l.saveBudgetChanges : l.saveDraft,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // 4. Final Approval
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13)),
                                    onPressed: _isSavingBudget ? null : _saveImportBudget,
                                    icon: _isSavingBudget ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.verified, color: Colors.white),
                                    label: Text(
                                      _editingBudgetId != null ? l.saveBudgetChanges : l.approveAndCertifyBudget,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.table_chart, color: Colors.green),
                                    label: Text(l.exportExcel),
                                    onPressed: () async {
                                      final bgt = _lastSavedBudget ?? _buildTempBudgetModel();
                                      final messenger = ScaffoldMessenger.of(context);
                                      final path = await FinancialExportService.exportBudgetToExcel(
                                        context: context,
                                        budget: bgt,
                                        prefill: _bgtPrefillData,
                                      );
                                      if (path != null && mounted) {
                                        messenger.showSnackBar(
                                          SnackBar(content: Text('✅ $path'), backgroundColor: Colors.green),
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                                    icon: const Icon(Icons.print, color: Colors.white),
                                    label: Text(l.print, style: const TextStyle(color: Colors.white)),
                                    onPressed: () {
                                      final bgt = _lastSavedBudget ?? _buildTempBudgetModel();
                                      FinancialExportService.printOrSaveBudgetPdf(
                                        budget: bgt,
                                        prefill: _bgtPrefillData,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          else
            const SizedBox.shrink(),

          // ── TAB 3: SAVED BUDGETS REGISTRY (سجل الميزانيات الاستيرادية المعتمدة) ───
          if (_visitedTabs.contains(2))
            SavedBudgetsRegistryTab(
              onEditBudget: _loadBudgetForEdit,
              onSwitchToForm: () => setState(() {
                _visitedTabs.add(1);
                _tabController.index = 1;
              }),
            )
          else
            const SizedBox.shrink(),

          // ── TAB 4: PAYMENT REQUESTS REGISTRY (سجل طلبات السداد والتحويلات) ─────────
          if (_visitedTabs.contains(3))
            Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Master Data Toolbar
                paymentsState.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (payments) {
                    final filtered = payments.where((p) {
                      final matchQ = _searchQuery.isEmpty ||
                          p.paymentCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          p.supplierName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          (p.importFileCode ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
                      final matchS = _statusFilter == 'All' || p.status == _statusFilter;
                      return matchQ && matchS;
                    }).toList();

                    return MasterDataToolbarWidget(
                      moduleEndpoint: 'financial-approval',
                      title: '${l.paymentRequestsLogTitle} (${filtered.length})',
                      onExportExcel: () => FinancialExportService.exportPaymentRequestsListToExcel(context: context, list: filtered),
                      onRefreshNeeded: () => ref.read(paymentRequestsProvider.notifier).fetchPaymentRequests(),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Search & Filters Row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: l.searchPaymentsHint,
                          prefixIcon: const Icon(Icons.search),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 220,
                      child: SearchableDropdownField<String>(
                        value: _statusFilter,
                        labelText: l.filterByStatus,
                        searchHintText: l.search,
                        items: [
                          SearchableDropdownItem(value: 'All', label: l.allStatuses),
                          SearchableDropdownItem(value: 'Draft', label: l.draftStatus),
                          SearchableDropdownItem(value: 'Approved', label: l.approvedBudgetsMetric),
                          SearchableDropdownItem(value: 'Paid', label: l.paidStatus),
                          SearchableDropdownItem(value: 'Reconciled', label: l.reconciledStatus),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _statusFilter = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Standardized Saved Registry Table Container
                Expanded(
                  child: paymentsState.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text('❌ Error: $err')),
                    data: (payments) {
                      final filtered = payments.where((p) {
                        final matchQ = _searchQuery.isEmpty ||
                            p.paymentCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            p.supplierName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            (p.importFileCode ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
                        final matchS = _statusFilter == 'All' || p.status == _statusFilter;
                        return matchQ && matchS;
                      }).toList();

                      if (filtered.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Center(
                            child: Text(
                              l.noMatchingPayments,
                              style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(AppTheme.charcoal),
                                    headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    columns: [
                                      DataColumn(
                                        label: Row(
                                          children: [
                                            const Icon(Icons.bolt, color: Colors.amber, size: 18),
                                            const SizedBox(width: 6),
                                            Text(l.actionsCol, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                      DataColumn(label: Text(l.paymentCodeCol, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text(l.importFile, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text(l.beneficiarySupplierLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text(l.bankSwiftCol, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text(l.paymentTypeLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text(l.requestedAmountLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text(l.equivalentEgpCol, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text(l.requestDueDateCol, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text(l.statusCol, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                    ],
                                    rows: filtered.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final p = entry.value;
                                      final isEven = index % 2 == 0;
                                      final rowSummary = [
                                        p.paymentCode,
                                        p.importFileCode ?? (p.importFileId != null ? 'IMP-${p.importFileId}' : '-'),
                                        p.beneficiaryName ?? p.supplierName,
                                        '${p.bankName ?? "-"} ${p.swiftCode ?? ""}'.trim(),
                                        p.paymentType,
                                        '${p.requestedAmount.toStringAsFixed(2)} ${p.currencyCode}',
                                        '${p.requestedAmountEgp.toStringAsFixed(2)} EGP',
                                        '${p.requestDate} / ${p.dueDate}',
                                        p.status,
                                      ].join('\t');

                                      return DataRow(
                                        color: WidgetStateProperty.all(isEven ? Colors.white : Colors.grey.shade50),
                                        cells: [
                                          DataCell(
                                            RowActionsPill(
                                              onView: () => _showPaymentDetailsDialog(p),
                                              onEdit: () => _loadPaymentRequestForEdit(p),
                                              onPrint: () => FinancialExportService.printPaymentRequestPdf(payment: p),
                                              onDelete: () => _confirmDeletePaymentRequest(p),
                                            ),
                                          ),
                                          DataCell(
                                            CopyableTableCell(
                                              value: p.paymentCode,
                                              rowSummary: rowSummary,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.cobalt.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: AppTheme.cobalt.withOpacity(0.3)),
                                                ),
                                                child: Text(
                                                  p.paymentCode,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt, fontSize: 12),
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            CopyableTableCell(
                                              value: p.importFileCode ?? (p.importFileId != null ? 'IMP-${p.importFileId}' : '-'),
                                              rowSummary: rowSummary,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.charcoal.withOpacity(0.08),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  p.importFileCode ?? (p.importFileId != null ? 'IMP-${p.importFileId}' : '-'),
                                                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.charcoal, fontSize: 12),
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            CopyableTableCell(
                                              value: '${p.beneficiaryName ?? p.supplierName} - ${p.title}',
                                              rowSummary: rowSummary,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(p.beneficiaryName ?? p.supplierName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                  Text(p.title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                                ],
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            CopyableTableCell(
                                              value: '${p.bankName ?? "-"} ${p.swiftCode ?? ""}'.trim(),
                                              rowSummary: rowSummary,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(p.bankName ?? '-', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                                  if (p.swiftCode != null && p.swiftCode!.isNotEmpty)
                                                    Text('SWIFT: ${p.swiftCode}', style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                                                ],
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            CopyableTableCell(
                                              value: p.paymentType,
                                              rowSummary: rowSummary,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber.shade50,
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: Colors.amber.shade200),
                                                ),
                                                child: Text(p.paymentType, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.brown.shade800)),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            CopyableTableCell(
                                              value: '${p.requestedAmount.toStringAsFixed(2)} ${p.currencyCode}',
                                              rowSummary: rowSummary,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade50,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  '${p.requestedAmount.toStringAsFixed(2)} ${p.currencyCode}',
                                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800, fontSize: 12),
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            CopyableTableCell(
                                              value: '${p.requestedAmountEgp.toStringAsFixed(2)} EGP',
                                              rowSummary: rowSummary,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.shade50,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  '${p.requestedAmountEgp.toStringAsFixed(2)} EGP',
                                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800, fontSize: 12),
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            CopyableTableCell(
                                              value: '${p.requestDate} - ${p.dueDate}',
                                              rowSummary: rowSummary,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text('${l.requestDateLabel}: ${p.requestDate.isNotEmpty ? p.requestDate : "-"}', style: const TextStyle(fontSize: 11)),
                                                  Text('${l.dueDateLabel}: ${p.dueDate}', style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                                                ],
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            CopyableTableCell(
                                              value: p.status,
                                              rowSummary: rowSummary,
                                              child: _buildStatusBadge(p.status),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          )
          else
            const SizedBox.shrink(),

          // ── TAB 4: SWIFT MT103 PARSER & RECONCILIATION ───────────────────────
          if (_visitedTabs.contains(4))
            const SwiftReconciliationScreen(isEmbedded: true)
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  ImportBudgetModel _buildTempBudgetModel() {
    final invForeign = double.tryParse(_invoiceForeignController.text.trim()) ?? 0.0;
    final invEgp = double.tryParse(_invoiceEgpController.text.trim()) ?? 0.0;
    final frtForeign = double.tryParse(_freightForeignController.text.trim()) ?? 0.0;
    final frtEgp = double.tryParse(_freightEgpController.text.trim()) ?? 0.0;
    final custEgp = double.tryParse(_customsEgpController.text.trim()) ?? 0.0;
    final clrEgp = double.tryParse(_clearanceEgpController.text.trim()) ?? 0.0;
    final rate = double.tryParse(_bgtExchangeRateController.text.trim()) ?? 50.0;

    return ImportBudgetModel(
      budgetId: 0,
      budgetCode: 'BGT-PREVIEW',
      title: _bgtTitleController.text.trim(),
      importFileId: _bgtSelectedImportFileId,
      invoiceAmountForeign: invForeign,
      invoiceCurrency: _bgtInvoiceCurrency,
      invoiceAmountEgp: invEgp,
      freightCostForeign: frtForeign,
      freightCurrency: _bgtFreightCurrency,
      freightCostEgp: frtEgp,
      customsDutiesEgp: custEgp,
      clearanceInlandEgp: clrEgp,
      exchangeRate: rate,
      totalBudgetEgp: invEgp + frtEgp + custEgp + clrEgp,
      budgetStatus: 'Pending Review',
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  Widget _buildConsolidatedBudgetSummary({ImportBudgetModel? bgt, BudgetPrefillModel? prefill}) {
    final invForeign = bgt != null && bgt.invoiceAmountForeign > 0
        ? bgt.invoiceAmountForeign
        : (double.tryParse(_invoiceForeignController.text) ?? (prefill?.totalInvoiceAmount ?? 0));
    final invCurr = bgt != null ? bgt.invoiceCurrency : _bgtInvoiceCurrency;
    final invEgp = bgt != null && bgt.invoiceAmountEgp > 0
        ? bgt.invoiceAmountEgp
        : (double.tryParse(_invoiceEgpController.text) ?? (prefill?.totalInvoiceAmountEgp ?? 0));

    final frtForeign = bgt != null && bgt.freightCostForeign > 0
        ? bgt.freightCostForeign
        : (double.tryParse(_freightForeignController.text) ?? (prefill?.estimatedFreightCost ?? 0));
    final frtCurr = bgt != null ? bgt.freightCurrency : _bgtFreightCurrency;
    final frtEgp = bgt != null && bgt.freightCostEgp > 0
        ? bgt.freightCostEgp
        : (double.tryParse(_freightEgpController.text) ?? (prefill?.estimatedFreightCostEgp ?? 0));

    final custEgp = bgt != null && bgt.customsDutiesEgp > 0
        ? bgt.customsDutiesEgp
        : (double.tryParse(_customsEgpController.text) ?? (prefill?.estimatedCustomsDutiesEgp ?? 0));

    final clrEgp = bgt != null && bgt.clearanceInlandEgp > 0
        ? bgt.clearanceInlandEgp
        : (double.tryParse(_clearanceEgpController.text) ?? (prefill?.estimatedClearanceFeesEgp ?? 0));

    final grandTotalEgp = invEgp + frtEgp + custEgp + clrEgp;

    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.currency_exchange, color: AppTheme.cobalt, size: 20),
              const SizedBox(width: 8),
              Text(
                l.consolidatedBudgetSummary,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Group 1: Foreign Currency Table
          Text('1. ${l.estimatedInvoiceValue} & ${l.estimatedFreightCost}:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.cobalt)),
          const SizedBox(height: 6),
          Table(
            border: TableBorder.all(color: Colors.grey.shade300),
            columnWidths: const {
              0: FlexColumnWidth(2.0),
              1: FlexColumnWidth(1.5),
              2: FlexColumnWidth(1.2),
              3: FlexColumnWidth(1.5),
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(color: AppTheme.cobalt),
                children: [
                  Padding(padding: const EdgeInsets.all(6), child: Text(l.categoryCol, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                  Padding(padding: const EdgeInsets.all(6), child: Text(l.requestedAmountLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                  Padding(padding: const EdgeInsets.all(6), child: Text(l.currencyCol, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                  Padding(padding: const EdgeInsets.all(6), child: Text(l.equivalentEgpCol, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: const EdgeInsets.all(6), child: Text(l.estimatedInvoiceValue, style: const TextStyle(fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(6), child: CopyableText(invForeign.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(6), child: CopyableText(invCurr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(6), child: CopyableText('${invEgp.toStringAsFixed(2)} EGP', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12))),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: const EdgeInsets.all(6), child: Text(l.estimatedFreightCost, style: const TextStyle(fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(6), child: CopyableText(frtForeign.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(6), child: CopyableText(frtCurr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(6), child: CopyableText('${frtEgp.toStringAsFixed(2)} EGP', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12))),
                ],
              ),
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade100),
                children: [
                  Padding(padding: const EdgeInsets.all(6), child: Text(l.totalExpenses, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: CopyableText(
                      invCurr.toUpperCase() == frtCurr.toUpperCase()
                          ? (invForeign + frtForeign).toStringAsFixed(2)
                          : '${invForeign.toStringAsFixed(2)} ($invCurr)\n+ ${frtForeign.toStringAsFixed(2)} ($frtCurr)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: CopyableText(
                      invCurr.toUpperCase() == frtCurr.toUpperCase() ? invCurr : '-',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: CopyableText(
                      '${(invEgp + frtEgp).toStringAsFixed(2)} EGP',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Group 2: Local EGP Table
          Text('2. ${l.clearanceAndTransportEstimate}:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.orange)),
          const SizedBox(height: 6),
          Table(
            border: TableBorder.all(color: Colors.grey.shade300),
            columnWidths: const {
              0: FlexColumnWidth(2.0),
              1: FlexColumnWidth(1.8),
              2: FlexColumnWidth(1.5),
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(color: AppTheme.orange),
                children: [
                  Padding(padding: const EdgeInsets.all(6), child: Text(l.categoryCol, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                  Padding(padding: const EdgeInsets.all(6), child: Text(l.responsiblePartyLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                  Padding(padding: const EdgeInsets.all(6), child: Text(l.equivalentEgpCol, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: const EdgeInsets.all(6), child: Text(l.customsAndVatEstimate, style: const TextStyle(fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(6), child: CopyableText(l.customsAuthority, style: const TextStyle(fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(6), child: CopyableText('${custEgp.toStringAsFixed(2)} EGP', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple, fontSize: 12))),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: const EdgeInsets.all(6), child: Text(l.clearanceAndTransportEstimate, style: const TextStyle(fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(6), child: CopyableText(l.customsBrokerLabel, style: const TextStyle(fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(6), child: CopyableText('${clrEgp.toStringAsFixed(2)} EGP', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 12))),
                ],
              ),
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade100),
                children: [
                  Padding(padding: const EdgeInsets.all(6), child: Text(l.totalExpenses, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  const Padding(padding: EdgeInsets.all(6), child: Text('-', style: TextStyle(fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(6), child: CopyableText('${(custEgp + clrEgp).toStringAsFixed(2)} EGP', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Total Approved Budget Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.emerald.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.emerald.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${l.totalBudgetEgp}:',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                ),
                CopyableText(
                  '${grandTotalEgp.toStringAsFixed(2)} EGP',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.emerald),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaySwiftExtractorWidget() {
    final l = context.l10n;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueGrey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.cobalt, Colors.blue.shade700],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                    const SizedBox(width: 6),
                    const Icon(Icons.bolt, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      l.swiftExtractorTitle,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(_isPaySwiftExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.white),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: _isPaySwiftExpanded ? l.collapseSidebar : l.actionsCol,
                      onPressed: () => setState(() => _isPaySwiftExpanded = !_isPaySwiftExpanded),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Collapsible Body
          if (_isPaySwiftExpanded)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 650;
                      final textArea = Stack(
                        children: [
                          TextField(
                            controller: _paySwiftRawTextController,
                            maxLines: 5,
                            minLines: 4,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.4),
                            decoration: InputDecoration(
                              hintText: l.swiftPasteText,
                              hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 40),
                            ),
                          ),
                          Positioned(
                            left: 8,
                            bottom: 8,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () async {
                                    final d = await Clipboard.getData(Clipboard.kTextPlain);
                                    if (d != null && d.text != null && d.text!.isNotEmpty) {
                                      _paySwiftRawTextController.text = d.text!;
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.paste, size: 12, color: Colors.black87),
                                        const SizedBox(width: 4),
                                        Text(l.swiftPasteText, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () {
                                    _paySwiftRawTextController.clear();
                                    setState(() => _payExtractedSwiftSummary = null);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.clear, size: 12, color: Colors.black54),
                                        const SizedBox(width: 4),
                                        Text(l.reset, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );

                      final actionButtons = Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.shade800,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.upload_file, size: 16, color: Colors.white),
                            label: Text(l.swiftUploadDocument, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: _isPaySwiftExtracting ? null : _autoFillFromSwiftFile,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.cobalt,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: _isPaySwiftExtracting
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.bolt, size: 16, color: Colors.amber),
                            label: Text(l.swiftExecuteReconciliation, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: _isPaySwiftExtracting
                                ? null
                                : () {
                                    final txt = _paySwiftRawTextController.text.trim();
                                    if (txt.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('⚠️ ${l.swiftPasteText}'), backgroundColor: AppTheme.orange),
                                      );
                                      return;
                                    }
                                    _autoFillFromSwiftText(txt);
                                  },
                          ),
                        ],
                      );

                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            textArea,
                            const SizedBox(height: 10),
                            actionButtons,
                          ],
                        );
                      } else {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: textArea),
                            const SizedBox(width: 14),
                            SizedBox(width: 200, child: actionButtons),
                          ],
                        );
                      }
                    },
                  ),

                  // Extracted Summary Badges (if extracted)
                  if (_payExtractedSwiftSummary != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppTheme.emerald, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 4,
                              children: [
                                Text('${l.requestedAmountLabel}: ${_payExtractedSwiftSummary!['amount']} ${_payExtractedSwiftSummary!['currency']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87)),
                                Text('${l.beneficiarySupplierLabel}: ${_payExtractedSwiftSummary!['beneficiary_name'] ?? "-"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87)),
                                Text('${l.paymentCodeCol}: ${_payExtractedSwiftSummary!['transaction_reference'] ?? "-"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87)),
                                Text('${l.swiftCodeLabel}: ${_payExtractedSwiftSummary!['beneficiary_bank_swift'] ?? "-"}', style: const TextStyle(fontSize: 11, color: Colors.black87)),
                                Text('${l.ibanAccountLabel}: ${_payExtractedSwiftSummary!['beneficiary_account_or_iban'] ?? "-"}', style: const TextStyle(fontSize: 11, color: Colors.black87)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricBadge(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          CopyableText(value, style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final l = context.l10n;
    Color bg = Colors.grey;
    String localizedStatus = status;

    if (status == 'Paid' || status == 'Budget Approved') {
      bg = Colors.green;
      localizedStatus = status == 'Paid' ? l.paidStatus : l.statusApproved;
    } else if (status == 'Approved') {
      bg = Colors.blue;
      localizedStatus = l.statusApproved;
    } else if (status == 'Pending Approval' || status == 'Pending Review') {
      bg = Colors.orange;
      localizedStatus = l.statusPendingReview;
    } else if (status == 'Draft') {
      bg = Colors.grey;
      localizedStatus = l.draftStatus;
    } else if (status == 'Reconciled') {
      bg = Colors.purple;
      localizedStatus = l.reconciledStatus;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(localizedStatus, style: TextStyle(color: bg, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }
}
