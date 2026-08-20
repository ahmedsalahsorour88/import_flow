import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/currencies/models/currency_model.dart';
import 'package:frontend/features/currencies/providers/currencies_provider.dart';
import 'package:frontend/features/financial_approval/models/financial_approval_model.dart';
import 'package:frontend/features/financial_approval/providers/financial_approval_provider.dart';
import 'package:frontend/features/financial_approval/screens/financial_approval_screen.dart';
import 'package:frontend/features/import_files/models/import_file_model.dart';
import 'package:frontend/features/import_files/providers/import_files_provider.dart';
import 'package:frontend/features/purchase_orders/models/purchase_order_model.dart';
import 'package:frontend/features/purchase_orders/providers/purchase_orders_provider.dart';
import 'package:frontend/features/suppliers/models/supplier_model.dart';
import 'package:frontend/features/suppliers/providers/suppliers_provider.dart';

class _MockPaymentRequestsNotifier extends PaymentRequestsNotifier {
  _MockPaymentRequestsNotifier() : super() {
    state = const AsyncValue.data([]);
  }
  @override
  Future<void> fetchPaymentRequests({
    bool includeInactive = false,
    String? search,
    int? poId,
    int? supplierId,
    String? status,
  }) async {
    state = const AsyncValue.data([]);
  }
}

class _MockImportBudgetsNotifier extends ImportBudgetsNotifier {
  _MockImportBudgetsNotifier() : super() {
    state = const AsyncValue.data([]);
  }
  @override
  Future<void> fetchImportBudgets({
    bool includeInactive = false,
    String? search,
    int? poId,
    int? importFileId,
    String? status,
    String? budgetStatus,
  }) async {
    state = const AsyncValue.data([]);
  }
}

class _MockImportFilesNotifier extends ImportFilesNotifier {
  _MockImportFilesNotifier() : super(Dio()) {
    state = const AsyncValue.data([]);
  }
  @override
  Future<void> fetchImportFiles({
    bool includeInactive = false,
    String? search,
    int? companyId,
    int? supplierId,
    String? status,
    String? owner,
  }) async {
    state = const AsyncValue.data([]);
  }
}

class _MockSuppliersNotifier extends SuppliersNotifier {
  _MockSuppliersNotifier() : super(showInactive: true, dio: Dio()) {
    state = const AsyncValue.data([]);
  }
  @override
  Future<void> fetchSuppliers() async {
    state = const AsyncValue.data([]);
  }
}

class _MockCurrenciesNotifier extends CurrenciesNotifier {
  _MockCurrenciesNotifier() : super(Dio()) {
    state = const AsyncValue.data([]);
  }
  @override
  Future<void> fetchCurrencies({bool includeInactive = true, String? search}) async {
    state = const AsyncValue.data([]);
  }
}

void main() {
  testWidgets('FinancialApprovalScreen renders Smart AI SWIFT Extractor and auto-fills Payment Request form', (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          paymentRequestsProvider.overrideWith((ref) => _MockPaymentRequestsNotifier()),
          importBudgetsProvider.overrideWith((ref) => _MockImportBudgetsNotifier()),
          importFilesProvider.overrideWith((ref) => _MockImportFilesNotifier()),
          suppliersProvider.overrideWith((ref) => _MockSuppliersNotifier()),
          currenciesProvider.overrideWith((ref) => _MockCurrenciesNotifier()),
        ],
        child: const MaterialApp(
          home: FinancialApprovalScreen(initialIndex: 0),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title & Header of SWIFT Extractor tool
    expect(find.textContaining('محرك الاستخراج الذكي والمطابقة الفورية لبيانات السويفت'), findsOneWidget);
    expect(find.text('تحميل نموذج سويفت تجريبي 📄'), findsOneWidget);
    expect(find.text('استخراج وتعبئة الحقول ⚡'), findsOneWidget);
    expect(find.textContaining('رفع واستخراج من ملف'), findsOneWidget);

    // Tap "تحميل نموذج سويفت تجريبي"
    await tester.tap(find.text('تحميل نموذج سويفت تجريبي 📄'));
    await tester.pumpAndSettle();

    // Verify Form Fields Auto-Populated
    expect(find.text('43704.0'), findsWidgets);
    expect(find.text('PCBCCNBJJSS'), findsWidgets);
    expect(find.text('32250198613609841015'), findsWidgets);
    expect(find.textContaining('SUZHOU YUHENG TEXTILE'), findsWidgets);
  });
}
