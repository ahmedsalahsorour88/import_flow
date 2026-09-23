import '../../customs_tariff/models/customs_tariff_model.dart';
import '../models/purchase_order_model.dart';

/// Resolved shipping and packaging metrics for a single PO Line Item.
///
/// Ensures each PO item is linked strictly to its corresponding Packing List package,
/// preventing accidental data duplication or cross-item pollution across shared HS Codes.
class ResolvedPoItemMetrics {
  final POLineItemModel item;
  final String effectiveHsCode;
  final List<PackingListItemModel> matchedPackingItems;
  final double cbm;
  final double netWeightKg;
  final double grossWeightKg;
  final int qtyPkg;
  final String packageType;
  final bool hasMatchedPacking;

  const ResolvedPoItemMetrics({
    required this.item,
    required this.effectiveHsCode,
    required this.matchedPackingItems,
    required this.cbm,
    required this.netWeightKg,
    required this.grossWeightKg,
    required this.qtyPkg,
    this.packageType = '-',
    required this.hasMatchedPacking,
  });
}

/// Advanced matching engine between Purchase Order Line Items and Packing List Items.
///
/// Resolves discrepancies where multiple items share the same HS Code but represent
/// completely distinct physical packages, weights, and CBM volumes.
class PoPackingMatcher {
  /// Normalizes a string for robust alphanumeric matching (ignoring punctuation, spaces, case).
  static String normalizeKey(String? s) {
    if (s == null) return '';
    return s.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').trim().toUpperCase();
  }

  /// Formats a weight or dimension value for presentation and export.
  ///
  /// Restricts display to at most 3 decimal places without intermediate rounding,
  /// trims trailing zeros, and displays clean integers for whole numbers or epsilon values.
  static String formatWeight(double val) {
    if (val.isNaN || val.isInfinite) return '0';
    if (val == 0.0) return '0';
    final rounded = val.roundToDouble();
    if ((val - rounded).abs() < 0.0005) {
      return rounded.toInt().toString();
    }
    var s = val.toStringAsFixed(3);
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    return s;
  }

  /// Determines the effective HS Code for a PO Line Item using its direct HS Code
  /// or resolving through Customs Tariff ID.
  static String resolveItemHsCode(POLineItemModel item, [List<CustomsTariffModel>? tariffs]) {
    if (item.hsCode != null && item.hsCode!.trim().isNotEmpty) {
      return item.hsCode!.trim();
    }
    if (item.tariffId != null && tariffs != null && tariffs.isNotEmpty) {
      for (final t in tariffs) {
        if (t.tariffId == item.tariffId && t.hsCode.trim().isNotEmpty) {
          return t.hsCode.trim();
        }
      }
    }
    return 'UNSPECIFIED';
  }

  /// Resolves shipping metrics (CBM, Net Weight, Gross Weight, Qty PKG) for each PO Line Item
  /// using a multi-pass non-duplicating matching strategy.
  ///
  /// Pass 1: Exact Item Code / SKU match (normalized alphanumeric).
  /// Pass 2: Cross Match (itemCode vs description/model, or identical descriptions).
  /// Pass 3: Unambiguous/Sequential 1-to-1 matching for unassigned items under the same HS Code.
  /// Pass 4: Metric aggregation with fallback to PO item specifications when no packing item matches.
  static List<ResolvedPoItemMetrics> resolvePoItemMetrics({
    required List<POLineItemModel> items,
    required List<PackingListItemModel> packingListItems,
    bool isPalletized = false,
    List<CustomsTariffModel>? tariffs,
  }) {
    if (items.isEmpty) return const [];

    // Track assigned packing list item indices to guarantee that each package is claimed uniquely
    final Set<int> assignedPlIndices = {};
    // Map: PO item index -> list of matched PackingListItemModel indices
    final Map<int, List<int>> poToPlIndices = {
      for (int i = 0; i < items.length; i++) i: <int>[],
    };

    // Pre-calculate effective HS code for each PO item
    final List<String> poHsCodes = items
        .map((item) => resolveItemHsCode(item, tariffs))
        .toList();

    // -------------------------------------------------------------------------
    // PASS 1: Exact Item Code / SKU Match (Alphanumeric Normalized)
    // -------------------------------------------------------------------------
    for (int i = 0; i < items.length; i++) {
      final poCode = normalizeKey(items[i].itemCode);
      if (poCode.isEmpty) continue;

      for (int j = 0; j < packingListItems.length; j++) {
        if (assignedPlIndices.contains(j)) continue;
        final plCode = normalizeKey(packingListItems[j].itemCode);
        if (plCode.isNotEmpty && plCode == poCode) {
          poToPlIndices[i]!.add(j);
          assignedPlIndices.add(j);
        }
      }
    }

    // -------------------------------------------------------------------------
    // PASS 2: Cross-field Match (itemCode <-> description/model)
    // -------------------------------------------------------------------------
    for (int i = 0; i < items.length; i++) {
      if (poToPlIndices[i]!.isNotEmpty) continue; // Already matched in Pass 1

      final poCode = normalizeKey(items[i].itemCode);
      final poMainDesc = normalizeKey(items[i].mainDescription);
      final poDescAr = normalizeKey(items[i].descriptionAr);
      final poDescEn = normalizeKey(items[i].descriptionEn);

      for (int j = 0; j < packingListItems.length; j++) {
        if (assignedPlIndices.contains(j)) continue;

        final plCode = normalizeKey(packingListItems[j].itemCode);
        final plMainDesc = normalizeKey(packingListItems[j].mainDescription);
        final plDesc = normalizeKey(packingListItems[j].description);

        bool isCrossMatch = false;

        // PO code matches PL description or model
        if (poCode.length >= 3 && (poCode == plMainDesc || poCode == plDesc)) {
          isCrossMatch = true;
        }
        // PL code matches PO description or model
        else if (plCode.length >= 3 && (plCode == poMainDesc || plCode == poDescAr || plCode == poDescEn)) {
          isCrossMatch = true;
        }
        // Identical non-trivial descriptions
        else if (poMainDesc.length >= 5 && (poMainDesc == plMainDesc || poMainDesc == plDesc)) {
          isCrossMatch = true;
        }

        if (isCrossMatch) {
          poToPlIndices[i]!.add(j);
          assignedPlIndices.add(j);
        }
      }
    }

    // -------------------------------------------------------------------------
    // PASS 3: Sequential / 1-to-1 match for remaining unassigned items under SAME HS Code
    // -------------------------------------------------------------------------
    // Group remaining PO item indices by HS code
    final Map<String, List<int>> remainingPoByHs = {};
    for (int i = 0; i < items.length; i++) {
      if (poToPlIndices[i]!.isEmpty) {
        final hs = normalizeKey(poHsCodes[i]);
        if (hs.isNotEmpty && hs != 'UNSPECIFIED') {
          remainingPoByHs.putIfAbsent(hs, () => []).add(i);
        }
      }
    }

    // Group remaining unassigned PL item indices by HS code
    final Map<String, List<int>> remainingPlByHs = {};
    for (int j = 0; j < packingListItems.length; j++) {
      if (!assignedPlIndices.contains(j)) {
        final hs = normalizeKey(packingListItems[j].hsCode);
        if (hs.isNotEmpty && hs != 'UNSPECIFIED') {
          remainingPlByHs.putIfAbsent(hs, () => []).add(j);
        }
      }
    }

    // Link remaining items strictly without re-using or duplicating packages
    for (final entry in remainingPoByHs.entries) {
      final hs = entry.key;
      final poIndices = entry.value;
      final plIndices = remainingPlByHs[hs] ?? [];

      if (plIndices.isEmpty) continue;

      if (poIndices.length == 1) {
        // Single remaining PO item receives all remaining PL packages for this HS Code
        for (final plIdx in plIndices) {
          poToPlIndices[poIndices[0]]!.add(plIdx);
          assignedPlIndices.add(plIdx);
        }
      } else if (poIndices.length <= plIndices.length) {
        // 1-to-1 sequential match
        for (int k = 0; k < poIndices.length; k++) {
          final plIdx = plIndices[k];
          poToPlIndices[poIndices[k]]!.add(plIdx);
          assignedPlIndices.add(plIdx);
        }
        // If there are surplus PL packages, attach them to the last PO item in this HS group
        for (int k = poIndices.length; k < plIndices.length; k++) {
          final plIdx = plIndices[k];
          poToPlIndices[poIndices.last]!.add(plIdx);
          assignedPlIndices.add(plIdx);
        }
      } else {
        // More PO items than PL packages: match 1-to-1 for available PLs
        for (int k = 0; k < plIndices.length; k++) {
          final plIdx = plIndices[k];
          poToPlIndices[poIndices[k]]!.add(plIdx);
          assignedPlIndices.add(plIdx);
        }
        // Remaining PO items without PL will fall back to their own specs in Pass 4
      }
    }

    // -------------------------------------------------------------------------
    // PASS 4: Aggregate Metrics for Each PO Line Item
    // -------------------------------------------------------------------------
    final List<ResolvedPoItemMetrics> results = [];
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final matchedIndices = poToPlIndices[i]!;
      final List<PackingListItemModel> matchedPls = matchedIndices.map((idx) => packingListItems[idx]).toList();

      double itemCbm = 0.0;
      double itemNet = 0.0;
      double itemGross = 0.0;
      int itemPkg = 0;

      if (matchedPls.isNotEmpty) {
        for (final pl in matchedPls) {
          final double cbm = pl.calculatedCbm > 0 ? pl.calculatedCbm : pl.totalCbm;
          final double net = (pl.netWeightUnitKg > 0 && pl.qtyPkg > 0)
              ? (pl.qtyPkg * pl.netWeightUnitKg)
              : pl.totalNetWeightKg;
          final double gross = (pl.grossWeightUnitKg > 0 && pl.qtyPkg > 0)
              ? (pl.qtyPkg * pl.grossWeightUnitKg)
              : pl.totalGrossWeightKg;

          itemCbm += cbm;
          itemNet += net;
          itemGross += gross;
          if (!isPalletized) {
            itemPkg += pl.qtyPkg.toInt();
          }
        }
      } else {
        // Fallback to PO item's own specifications
        itemCbm = item.totalCbm > 0 ? item.totalCbm : (item.cbmPerUnit * item.quantity);
        itemNet = item.netWeightKg;
        itemGross = item.grossWeightKg;
        itemPkg = 0;
      }

      final packageTypes = matchedPls
          .map((pl) => pl.packageType.trim())
          .where((t) => t.isNotEmpty)
          .toSet()
          .toList();
      final String resolvedPackageType = packageTypes.isNotEmpty
          ? packageTypes.join(', ')
          : '-';

      results.add(ResolvedPoItemMetrics(
        item: item,
        effectiveHsCode: poHsCodes[i],
        matchedPackingItems: matchedPls,
        cbm: itemCbm,
        netWeightKg: itemNet,
        grossWeightKg: itemGross,
        qtyPkg: isPalletized ? 0 : itemPkg,
        packageType: resolvedPackageType,
        hasMatchedPacking: matchedPls.isNotEmpty,
      ));
    }

    return results;
  }

  /// Builds a synchronized PO Line Items Summary Map grouped by HS Code.
  ///
  /// Guarantees that totals (Qty, Qty PKG, Net Weight, Gross Weight, CBM, Total Price)
  /// in the UI, Excel, and PDF exports are 100% consistent and reflect actual physical items.
  static Map<String, Map<String, dynamic>> buildPoHsSummaryMap(List<ResolvedPoItemMetrics> resolvedItems) {
    final Map<String, Map<String, dynamic>> summaryMap = {};
    for (final resolved in resolvedItems) {
      final hs = resolved.effectiveHsCode.isNotEmpty ? resolved.effectiveHsCode : 'UNSPECIFIED';
      if (!summaryMap.containsKey(hs)) {
        summaryMap[hs] = {
          'hs_code': hs,
          'qty': 0.0,
          'qty_pkg': 0,
          'total_net': 0.0,
          'total_gross': 0.0,
          'total_cbm': 0.0,
          'total_price': 0.0,
          'duty_rate': resolved.item.dutyRate ?? 0.0,
          'vat_rate': resolved.item.vatRate ?? 0.0,
        };
      }

      summaryMap[hs]!['qty'] = (summaryMap[hs]!['qty'] as double) + resolved.item.quantity;
      summaryMap[hs]!['qty_pkg'] = (summaryMap[hs]!['qty_pkg'] as int) + resolved.qtyPkg;
      summaryMap[hs]!['total_net'] = (summaryMap[hs]!['total_net'] as double) + resolved.netWeightKg;
      summaryMap[hs]!['total_gross'] = (summaryMap[hs]!['total_gross'] as double) + resolved.grossWeightKg;
      summaryMap[hs]!['total_cbm'] = (summaryMap[hs]!['total_cbm'] as double) + resolved.cbm;
      summaryMap[hs]!['total_price'] = (summaryMap[hs]!['total_price'] as double) + resolved.item.totalPrice;
    }

    // Eliminate floating-point accumulator drift near integers
    for (final s in summaryMap.values) {
      final gross = s['total_gross'] as double;
      if ((gross - gross.roundToDouble()).abs() < 0.0005) {
        s['total_gross'] = gross.roundToDouble();
      }
      final net = s['total_net'] as double;
      if ((net - net.roundToDouble()).abs() < 0.0005) {
        s['total_net'] = net.roundToDouble();
      }
    }

    return summaryMap;
  }

  /// Formats an accurate, dynamic packaging summary for the top header and report metadata.
  ///
  /// Supports single packaging (e.g. "1 x PLT - Pallet (بالتة)") and mixed packaging
  /// (e.g. "1 x Pallet, 10 x CTN, 2 x Box (Total: 13 Pkgs)").
  static String formatPackagingSummary({
    required List<PackingListItemModel> packingListItems,
    int totalPalletCount = 0,
    bool isArabic = false,
  }) {
    if (packingListItems.isEmpty) {
      if (totalPalletCount > 0) {
        return '$totalPalletCount ${isArabic ? "بالتة" : "Pallets"}';
      }
      return isArabic ? '0 طرد' : '0 Pkgs';
    }

    final Map<String, int> countsByType = {};
    int totalPackages = 0;

    for (final pl in packingListItems) {
      final rawType = pl.packageType.trim();
      final type = rawType.isNotEmpty ? rawType : (isArabic ? 'كرتونة / طرد' : 'Carton / Pkg');
      final qty = pl.qtyPkg > 0 ? pl.qtyPkg.toInt() : 1;
      countsByType[type] = (countsByType[type] ?? 0) + qty;
      totalPackages += qty;
    }

    if (countsByType.isEmpty) {
      if (totalPalletCount > 0) {
        return '$totalPalletCount ${isArabic ? "بالتة" : "Pallets"}';
      }
      return isArabic ? '0 طرد' : '0 Pkgs';
    }

    if (countsByType.length == 1) {
      final entry = countsByType.entries.first;
      return '${entry.value} x ${entry.key}';
    }

    final parts = countsByType.entries.map((e) => '${e.value} x ${e.key}').toList();
    final totalLabel = isArabic ? 'الإجمالي: $totalPackages طرد' : 'Total: $totalPackages Pkgs';
    return '${parts.join(", ")} ($totalLabel)';
  }

  /// Builds a synchronized Packing List Summary Map grouped by Package Type.
  ///
  /// Aggregates: Total Packages (Qty PKG), Total Net Weight, Total Gross Weight, Total CBM.
  static Map<String, Map<String, dynamic>> buildPackingTypeSummaryMap(List<PackingListItemModel> packingListItems) {
    final Map<String, Map<String, dynamic>> summaryMap = {};
    for (final pl in packingListItems) {
      final rawType = pl.packageType.trim();
      final type = rawType.isNotEmpty ? rawType : 'Carton';
      if (!summaryMap.containsKey(type)) {
        summaryMap[type] = {
          'package_type': type,
          'qty_pkg': 0,
          'total_net': 0.0,
          'total_gross': 0.0,
          'total_cbm': 0.0,
        };
      }

      final double cbm = pl.calculatedCbm > 0 ? pl.calculatedCbm : pl.totalCbm;
      final double net = (pl.netWeightUnitKg > 0 && pl.qtyPkg > 0)
          ? (pl.qtyPkg * pl.netWeightUnitKg)
          : pl.totalNetWeightKg;
      final double gross = (pl.grossWeightUnitKg > 0 && pl.qtyPkg > 0)
          ? (pl.qtyPkg * pl.grossWeightUnitKg)
          : pl.totalGrossWeightKg;
      final int pkg = pl.qtyPkg > 0 ? pl.qtyPkg.toInt() : 1;

      summaryMap[type]!['qty_pkg'] = (summaryMap[type]!['qty_pkg'] as int) + pkg;
      summaryMap[type]!['total_net'] = (summaryMap[type]!['total_net'] as double) + net;
      summaryMap[type]!['total_gross'] = (summaryMap[type]!['total_gross'] as double) + gross;
      summaryMap[type]!['total_cbm'] = (summaryMap[type]!['total_cbm'] as double) + cbm;
    }

    // Eliminate floating-point accumulator drift near integers
    for (final s in summaryMap.values) {
      final gross = s['total_gross'] as double;
      if ((gross - gross.roundToDouble()).abs() < 0.0005) {
        s['total_gross'] = gross.roundToDouble();
      }
      final net = s['total_net'] as double;
      if ((net - net.roundToDouble()).abs() < 0.0005) {
        s['total_net'] = net.roundToDouble();
      }
    }

    return summaryMap;
  }
}

