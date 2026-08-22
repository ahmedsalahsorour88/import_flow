import 'dart:math' as math;
import '../../features/import_files/models/import_file_model.dart';
import '../../features/purchase_orders/models/purchase_order_model.dart';
import 'container_requirement_engine.dart';

/// Helper for linking Purchase Orders to Import Files, aggregating shipping metrics,
/// and building accurate 3D cargo items for Bin Packing & Container Stacking.
class ImportFilePoLinker {
  /// Robustly matches linked Purchase Orders for a given Import File.
  static List<PurchaseOrderModel> getLinkedPOs({
    required ImportFileModel file,
    required List<PurchaseOrderModel> allPOs,
  }) {
    return allPOs.where((p) {
      // 1. Direct ID match
      if (p.importFileId == file.importFileId) return true;

      // 2. Import File Code match
      if (file.importFileCode.isNotEmpty && p.importFileCode != null && p.importFileCode == file.importFileCode) return true;
      if (file.customFileNumber != null && file.customFileNumber!.isNotEmpty && p.importFileCode != null && p.importFileCode == file.customFileNumber) return true;

      // 3. poIds array match on Import File
      if (file.poIds != null && p.poId != null && file.poIds!.contains(p.poId)) return true;

      // 4. PO Number match
      if (file.poNumber != null && file.poNumber!.isNotEmpty && p.poNumber.isNotEmpty) {
        final filePoClean = file.poNumber!.trim();
        final pPoClean = p.poNumber.trim();
        if (filePoClean == pPoClean || filePoClean.contains(pPoClean) || pPoClean.contains(filePoClean)) return true;
      }

      // 5. Proforma Invoice number match
      if (file.piNumber != null && file.piNumber!.isNotEmpty && p.proformaInvoiceNumber != null && p.proformaInvoiceNumber!.isNotEmpty) {
        final filePiClean = file.piNumber!.trim();
        final pPiClean = p.proformaInvoiceNumber!.trim();
        if (filePiClean == pPiClean || filePiClean.contains(pPiClean) || pPiClean.contains(filePiClean)) return true;
      }

      // 6. Importer + Supplier match fallback
      if (file.companyId != null && file.companyId == p.companyId && file.supplierId != null && file.supplierId == p.supplierId) {
        if (p.importFileId == null || p.importFileId == file.importFileId) return true;
      }

      return false;
    }).toList();
  }

  /// Aggregates total CBM, gross weight, packing lists count, and invoice numbers.
  static ({double cbm, double weightKg, int plCount, Set<String> invoices}) computeMetrics({
    required ImportFileModel file,
    required List<PurchaseOrderModel> linkedPOs,
  }) {
    double totalCbm = 0.0;
    double totalWeight = 0.0;
    int plCount = 0;
    final invoices = <String>{};

    if (file.piNumber != null && file.piNumber!.isNotEmpty) invoices.add(file.piNumber!);
    if (file.poNumber != null && file.poNumber!.isNotEmpty) invoices.add(file.poNumber!);

    for (final po in linkedPOs) {
      if (po.proformaInvoiceNumber != null && po.proformaInvoiceNumber!.isNotEmpty) {
        invoices.add(po.proformaInvoiceNumber!);
      }
      if (po.poNumber.isNotEmpty) {
        invoices.add(po.poNumber);
      }

      if (po.packingListItems.isNotEmpty) {
        plCount += po.packingListItems.length;
        for (final pl in po.packingListItems) {
          totalCbm += (pl.totalCbm > 0 ? pl.totalCbm : pl.calculatedCbm);
          totalWeight += (pl.totalGrossWeightKg > 0 ? pl.totalGrossWeightKg : (pl.grossWeightUnitKg * pl.qtyPkg));
        }
      } else if (po.items.isNotEmpty) {
        plCount += po.items.length;
        double poLineCbm = 0.0;
        double poLineWt = 0.0;
        for (final item in po.items) {
          poLineCbm += (item.totalCbm > 0 ? item.totalCbm : (item.cbmPerUnit * item.quantity));
          poLineWt += (item.grossWeightKg > 0 ? item.grossWeightKg : (item.netWeightKg > 0 ? item.netWeightKg : 0.0));
        }
        totalCbm += (poLineCbm > 0 ? poLineCbm : po.totalCbm);
        totalWeight += (poLineWt > 0 ? poLineWt : po.totalGrossWeightKg);
      } else {
        totalCbm += po.totalCbm;
        totalWeight += po.totalGrossWeightKg;
      }
    }

    if (totalCbm == 0 && file.packingListsData.isNotEmpty) {
      for (final pl in file.packingListsData) {
        totalCbm += pl.cbm;
        totalWeight += pl.grossWeightKg;
        plCount += 1;
      }
    }

    return (cbm: totalCbm, weightKg: totalWeight, plCount: plCount, invoices: invoices);
  }

  /// Builds accurate CargoItem list for 3D Bin Packing & Container Stacking.
  static List<CargoItem> buildCargoItems({
    required List<PurchaseOrderModel> pos,
    required ImportFileModel file,
    required double fallbackCbm,
    required double fallbackWeight,
  }) {
    final List<CargoItem> baseCargoItems = [];
    int itemCounter = 1;

    for (final po in pos) {
      if (po.packingListItems.isNotEmpty) {
        for (final pl in po.packingListItems) {
          for (int q = 0; q < pl.qtyPkg.toInt(); q++) {
            double lCm = pl.lengthCm;
            double wCm = pl.widthCm;
            double hCm = pl.heightCm;
            if (pl.unit == 'mm') {
              lCm /= 10;
              wCm /= 10;
              hCm /= 10;
            } else if (pl.unit == 'm') {
              lCm *= 100;
              wCm *= 100;
              hCm *= 100;
            }

            baseCargoItems.add(CargoItem(
              itemId: '$itemCounter',
              length: lCm > 0 ? lCm : 120,
              width: wCm > 0 ? wCm : 100,
              height: hCm > 0 ? hCm : 160,
              weight: pl.grossWeightUnitKg > 0
                  ? pl.grossWeightUnitKg
                  : (pl.totalGrossWeightKg / (pl.qtyPkg > 0 ? pl.qtyPkg : 1)),
              rotate: true,
              isStackable: pl.isStackable,
              packageType: pl.packageType,
            ));
            itemCounter++;
          }
        }
      } else if (po.items.isNotEmpty) {
        for (final item in po.items) {
          final itemCbm = item.totalCbm > 0 ? item.totalCbm : (item.cbmPerUnit * item.quantity);
          final itemWt = item.grossWeightKg > 0 ? item.grossWeightKg : (item.netWeightKg > 0 ? item.netWeightKg : 500.0);
          final int pkgs = item.quantity > 0 ? item.quantity.toInt().clamp(1, 100) : 1;
          final double perPkgCbm = (itemCbm > 0 ? itemCbm : 1.0) / pkgs;

          double sideCm = math.pow(perPkgCbm, 1.0 / 3.0).toDouble() * 100.0;
          if (sideCm <= 0) sideCm = 100.0;
          double lCm = sideCm;
          double wCm = sideCm;
          double hCm = sideCm;

          if (wCm > 220) {
            wCm = 220;
            if (hCm > 220) hCm = 220;
            lCm = (perPkgCbm * 1000000.0) / (wCm * hCm);
          }

          for (int q = 0; q < pkgs; q++) {
            baseCargoItems.add(CargoItem(
              itemId: '$itemCounter',
              length: lCm.clamp(30.0, 1100.0),
              width: wCm.clamp(30.0, 225.0),
              height: hCm.clamp(30.0, 260.0),
              weight: itemWt / pkgs,
              rotate: true,
              isStackable: true,
              packageType: 'Box',
            ));
            itemCounter++;
          }
        }
      }
    }

    if (baseCargoItems.isEmpty && file.packingListsData.isNotEmpty) {
      for (final pl in file.packingListsData) {
        final double cbm = pl.cbm > 0 ? pl.cbm : 1.0;
        final int pkgs = pl.totalPackages > 0 ? pl.totalPackages.clamp(1, 100) : 1;
        final double perPkgCbm = cbm / pkgs;
        final double perPkgWt = (pl.grossWeightKg > 0 ? pl.grossWeightKg : 500.0) / pkgs;

        double sideCm = math.pow(perPkgCbm, 1.0 / 3.0).toDouble() * 100.0;
        double lCm = sideCm.clamp(30.0, 1100.0);
        double wCm = sideCm.clamp(30.0, 225.0);
        double hCm = sideCm.clamp(30.0, 260.0);

        for (int q = 0; q < pkgs; q++) {
          baseCargoItems.add(CargoItem(
            itemId: '$itemCounter',
            length: lCm,
            width: wCm,
            height: hCm,
            weight: perPkgWt,
            rotate: true,
            isStackable: true,
            packageType: 'Package',
          ));
          itemCounter++;
        }
      }
    }

    if (baseCargoItems.isEmpty && fallbackCbm > 0) {
      final double targetCbm = fallbackCbm;
      final double targetWeight = fallbackWeight > 0 ? fallbackWeight : 1000.0;

      final int numPallets = (targetCbm / 2.0).ceil().clamp(1, 50);
      final double perPalletCbm = targetCbm / numPallets;
      final double perPalletWeight = targetWeight / numPallets;

      double palletHeightCm = (perPalletCbm * 1000000.0) / 12000.0;
      if (palletHeightCm > 260) palletHeightCm = 260;

      for (int i = 0; i < numPallets; i++) {
        baseCargoItems.add(CargoItem(
          itemId: '$itemCounter',
          length: 120,
          width: 100,
          height: palletHeightCm.clamp(30.0, 260.0),
          weight: perPalletWeight,
          rotate: true,
          isStackable: true,
          packageType: 'Pallet',
        ));
        itemCounter++;
      }
    }

    if (baseCargoItems.isEmpty) {
      baseCargoItems.add(CargoItem(
        itemId: '1',
        length: 120,
        width: 100,
        height: 100,
        weight: fallbackWeight > 0 ? fallbackWeight : 500.0,
        rotate: true,
        isStackable: true,
      ));
    }

    return baseCargoItems;
  }
}
