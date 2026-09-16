import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/cargox/models/export_configs.dart';

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // InvoiceExportConfig
  // ──────────────────────────────────────────────────────────────────────────
  group('InvoiceExportConfig — toApiInvoiceMode()', () {
    test('singleFile + consolidated → all_consolidated', () {
      const cfg = InvoiceExportConfig(
        packaging: FilePackagingMode.singleFile,
        detail: ContentDetailMode.consolidated,
      );
      expect(cfg.toApiInvoiceMode(), 'all_consolidated');
    });

    test('singleFile + detailed → all_detailed', () {
      const cfg = InvoiceExportConfig(
        packaging: FilePackagingMode.singleFile,
        detail: ContentDetailMode.detailed,
      );
      expect(cfg.toApiInvoiceMode(), 'all_detailed');
    });

    test('zipPerInvoice + consolidated → per_invoice_consolidated', () {
      const cfg = InvoiceExportConfig(
        packaging: FilePackagingMode.zipPerInvoice,
        detail: ContentDetailMode.consolidated,
      );
      expect(cfg.toApiInvoiceMode(), 'per_invoice_consolidated');
    });

    test('zipPerInvoice + detailed → per_invoice_detailed', () {
      const cfg = InvoiceExportConfig(
        packaging: FilePackagingMode.zipPerInvoice,
        detail: ContentDetailMode.detailed,
      );
      expect(cfg.toApiInvoiceMode(), 'per_invoice_detailed');
    });
  });

  group('InvoiceExportConfig — toApiInvoiceGrouping()', () {
    test('byHsCode → by_hs_code', () {
      const cfg = InvoiceExportConfig(grouping: InvoiceGroupingMode.byHsCode);
      expect(cfg.toApiInvoiceGrouping(), 'by_hs_code');
    });

    test('byPriceGroup → by_price_group', () {
      const cfg = InvoiceExportConfig(grouping: InvoiceGroupingMode.byPriceGroup);
      expect(cfg.toApiInvoiceGrouping(), 'by_price_group');
    });

    test('flat → flat', () {
      const cfg = InvoiceExportConfig(grouping: InvoiceGroupingMode.flat);
      expect(cfg.toApiInvoiceGrouping(), 'flat');
    });
  });

  group('InvoiceExportConfig — copyWith()', () {
    test('copyWith preserves unchanged fields', () {
      const original = InvoiceExportConfig(
        packaging: FilePackagingMode.zipPerInvoice,
        detail: ContentDetailMode.detailed,
        grouping: InvoiceGroupingMode.byPriceGroup,
      );
      final copy = original.copyWith(grouping: InvoiceGroupingMode.flat);
      expect(copy.packaging, FilePackagingMode.zipPerInvoice);
      expect(copy.detail, ContentDetailMode.detailed);
      expect(copy.grouping, InvoiceGroupingMode.flat);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // PackingListExportConfig — toApiPackingListMode()
  // ──────────────────────────────────────────────────────────────────────────
  group('PackingListExportConfig — toApiPackingListMode()', () {
    test('singleFile + consolidated → all_consolidated', () {
      const cfg = PackingListExportConfig(
        packaging: FilePackagingMode.singleFile,
        detail: ContentDetailMode.consolidated,
      );
      expect(cfg.toApiPackingListMode(), 'all_consolidated');
    });

    test('zipPerInvoice + detailed → per_invoice_detailed', () {
      const cfg = PackingListExportConfig(
        packaging: FilePackagingMode.zipPerInvoice,
        detail: ContentDetailMode.detailed,
      );
      expect(cfg.toApiPackingListMode(), 'per_invoice_detailed');
    });
  });

  group('PackingListExportConfig — toApiPackingListStructure()', () {
    test('byHsCode → by_hs_code', () {
      const cfg = PackingListExportConfig(structure: PackingListStructure.byHsCode);
      expect(cfg.toApiPackingListStructure(), 'by_hs_code');
    });

    test('flat → flat', () {
      const cfg = PackingListExportConfig(structure: PackingListStructure.flat);
      expect(cfg.toApiPackingListStructure(), 'flat');
    });

    test('byPallet → by_pallet', () {
      const cfg = PackingListExportConfig(structure: PackingListStructure.byPallet);
      expect(cfg.toApiPackingListStructure(), 'by_pallet');
    });

    test('byCarton → by_carton', () {
      const cfg = PackingListExportConfig(structure: PackingListStructure.byCarton);
      expect(cfg.toApiPackingListStructure(), 'by_carton');
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // isPalletToggleAllowed invariant
  // ──────────────────────────────────────────────────────────────────────────
  group('PackingListExportConfig — isPalletToggleAllowed', () {
    test('byHsCode → false', () {
      const cfg = PackingListExportConfig(structure: PackingListStructure.byHsCode);
      expect(cfg.isPalletToggleAllowed, isFalse);
    });

    test('flat → false', () {
      const cfg = PackingListExportConfig(structure: PackingListStructure.flat);
      expect(cfg.isPalletToggleAllowed, isFalse);
    });

    test('byPallet → true', () {
      const cfg = PackingListExportConfig(structure: PackingListStructure.byPallet);
      expect(cfg.isPalletToggleAllowed, isTrue);
    });

    test('byCarton → true', () {
      const cfg = PackingListExportConfig(structure: PackingListStructure.byCarton);
      expect(cfg.isPalletToggleAllowed, isTrue);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // effectiveIncludePalletDetails invariant
  // ──────────────────────────────────────────────────────────────────────────
  group('PackingListExportConfig — effectiveIncludePalletDetails', () {
    test('byHsCode with includePalletDetails=true → effective is false', () {
      const cfg = PackingListExportConfig(
        structure: PackingListStructure.byHsCode,
        includePalletDetails: true,
      );
      expect(cfg.effectiveIncludePalletDetails, isFalse);
    });

    test('flat with includePalletDetails=true → effective is false', () {
      const cfg = PackingListExportConfig(
        structure: PackingListStructure.flat,
        includePalletDetails: true,
      );
      expect(cfg.effectiveIncludePalletDetails, isFalse);
    });

    test('byPallet with includePalletDetails=false → effective is false', () {
      const cfg = PackingListExportConfig(
        structure: PackingListStructure.byPallet,
        includePalletDetails: false,
      );
      expect(cfg.effectiveIncludePalletDetails, isFalse);
    });

    test('byPallet with includePalletDetails=true → effective is true', () {
      const cfg = PackingListExportConfig(
        structure: PackingListStructure.byPallet,
        includePalletDetails: true,
      );
      expect(cfg.effectiveIncludePalletDetails, isTrue);
    });

    test('byCarton with includePalletDetails=true → effective is true', () {
      const cfg = PackingListExportConfig(
        structure: PackingListStructure.byCarton,
        includePalletDetails: true,
      );
      expect(cfg.effectiveIncludePalletDetails, isTrue);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // copyWith() reset behavior when structure changes
  // ──────────────────────────────────────────────────────────────────────────
  group('PackingListExportConfig — copyWith() invariant enforcement', () {
    test('switching from byPallet to byHsCode resets includePalletDetails to false', () {
      const original = PackingListExportConfig(
        structure: PackingListStructure.byPallet,
        includePalletDetails: true,
      );
      final updated = original.copyWith(structure: PackingListStructure.byHsCode);
      expect(updated.effectiveIncludePalletDetails, isFalse);
      expect(updated.includePalletDetails, isFalse);
    });

    test('switching from byHsCode to byCarton with includePalletDetails=true works', () {
      const original = PackingListExportConfig(
        structure: PackingListStructure.byHsCode,
        includePalletDetails: false,
      );
      final updated = original.copyWith(structure: PackingListStructure.byCarton, includePalletDetails: true);
      expect(updated.effectiveIncludePalletDetails, isTrue);
    });

    test('copyWith preserves unchanged structure and packaging', () {
      const original = PackingListExportConfig(
        packaging: FilePackagingMode.zipPerInvoice,
        detail: ContentDetailMode.detailed,
        structure: PackingListStructure.byCarton,
        includePalletDetails: true,
      );
      final copy = original.copyWith(detail: ContentDetailMode.consolidated);
      expect(copy.packaging, FilePackagingMode.zipPerInvoice);
      expect(copy.structure, PackingListStructure.byCarton);
      expect(copy.includePalletDetails, isTrue);
      expect(copy.detail, ContentDetailMode.consolidated);
    });
  });
}
