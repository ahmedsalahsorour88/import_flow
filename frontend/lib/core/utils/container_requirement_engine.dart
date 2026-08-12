class CargoItem {
  final String itemId;
  final double length; // cm
  final double width;  // cm
  final double height; // cm
  final double weight; // kg
  final bool rotate;

  CargoItem({
    required this.itemId,
    required this.length,
    required this.width,
    required this.height,
    required this.weight,
    this.rotate = true,
  });

  double get volumeM3 => (length * width * height) / 1000000;
}

class PlacedItem {
  final CargoItem item;
  final double x;
  final double y;
  final double length; // placed length (cm) after possible rotation
  final double width;  // placed width (cm) after possible rotation

  PlacedItem({
    required this.item,
    required this.x,
    required this.y,
    required this.length,
    required this.width,
  });
}

class ContainerPackingResult {
  final String containerCode;
  final ContainerSpec spec;
  final List<PlacedItem> placedItems;
  final List<CargoItem> unplacedItems;
  final double totalWeight;
  final double totalVolume;
  final bool fits;

  ContainerPackingResult({
    required this.containerCode,
    required this.spec,
    required this.placedItems,
    required this.unplacedItems,
    required this.totalWeight,
    required this.totalVolume,
    required this.fits,
  });
}

class ContainerSpec {
  final String code;
  final String name;
  final double internalVolumeCbm;
  final double maxPayloadKg;
  final double internalLength;
  final double internalWidth;
  final double internalHeight;

  const ContainerSpec({
    required this.code,
    required this.name,
    required this.internalVolumeCbm,
    required this.maxPayloadKg,
    required this.internalLength,
    required this.internalWidth,
    required this.internalHeight,
  });
}


class ShipmentModeRecommendation {
  final String recommendedMode; // 'Air', 'Sea LCL', 'Sea FCL'
  final String recommendedModeAr;
  final String reasonAr;
  final bool isAirSuggested;
  final bool isLclSuggested;

  ShipmentModeRecommendation({
    required this.recommendedMode,
    required this.recommendedModeAr,
    required this.reasonAr,
    required this.isAirSuggested,
    required this.isLclSuggested,
  });
}

class ContainerRecommendationResult {
  final bool isStackable;
  final String stackingLabel;
  final String recommendedContainerCode;
  final int requiredContainersCount;
  final double spaceUtilizationPercent;
  final double payloadUtilizationPercent;
  final String recommendationSummary;
  final List<Map<String, dynamic>> comparisonDetails;
  final ShipmentModeRecommendation modeRecommendation;

  ContainerRecommendationResult({
    required this.isStackable,
    required this.stackingLabel,
    required this.recommendedContainerCode,
    required this.requiredContainersCount,
    required this.spaceUtilizationPercent,
    required this.payloadUtilizationPercent,
    required this.recommendationSummary,
    required this.comparisonDetails,
    required this.modeRecommendation,
  });
}

class ContainerDualRecommendationResult {
  final ContainerRecommendationResult stackableResult;
  final ContainerRecommendationResult nonStackableResult;
  final ShipmentModeRecommendation modeRecommendation;

  ContainerDualRecommendationResult({
    required this.stackableResult,
    required this.nonStackableResult,
    required this.modeRecommendation,
  });
}

/// MD-019.1 Container Requirement & Utilization Calculation Engine + Cargo Stacking Skill
class ContainerRequirementEngine {
  static const List<ContainerSpec> specs = [
    ContainerSpec(code: '20GP', name: "20' General Purpose Container", internalVolumeCbm: 33.2, maxPayloadKg: 21700.0, internalLength: 589.0, internalWidth: 235.0, internalHeight: 239.0),
    ContainerSpec(code: '40GP', name: "40' General Purpose Container", internalVolumeCbm: 67.7, maxPayloadKg: 26500.0, internalLength: 1203.0, internalWidth: 235.0, internalHeight: 239.0),
    ContainerSpec(code: '40HC', name: "40' High Cube Container", internalVolumeCbm: 76.4, maxPayloadKg: 26500.0, internalLength: 1203.0, internalWidth: 235.0, internalHeight: 269.0),
    ContainerSpec(code: '45HC', name: "45' High Cube Container", internalVolumeCbm: 86.0, maxPayloadKg: 27700.0, internalLength: 1355.6, internalWidth: 235.2, internalHeight: 269.8),
  ];


  /// Smart Shipment Mode Recommendation Rules:
  /// 1. Air Freight Rule (MUST SATISFY BOTH CONDITIONS):
  ///    - Condition 1: Actual Gross Weight (kg) >= Volumetric Air Chargeable Weight (totalCbm * 166.67 kg).
  ///    - Condition 2: Actual Total Volume (CBM) < 5.0 m³.
  /// 2. Sea LCL Rule:
  ///    - If totalCbm < 15.0 m³ (and not qualifying for Air Freight).
  /// 3. Sea FCL Rule:
  ///    - If totalCbm >= 15.0 m³.
  static ShipmentModeRecommendation recommendShipmentMode({
    required double totalCbm,
    required double totalWeightKg,
  }) {
    final double airVolumetricWeightKg = totalCbm * 166.67;
    final bool condition1AirHeavy = totalWeightKg > 0 && totalWeightKg >= airVolumetricWeightKg;
    final bool condition2AirSmallVol = totalCbm > 0 && totalCbm < 5.0;

    if (condition1AirHeavy && condition2AirSmallVol) {
      return ShipmentModeRecommendation(
        recommendedMode: 'Air',
        recommendedModeAr: 'Air (شحن جوي ✈️)',
        reasonAr: 'التوصية الذكية: اقتراح شحن جوي (AIR) لاكتمال الشرطين الحاسمين:\n1. الوزن الفعلي القائم (${totalWeightKg.toStringAsFixed(1)} kg) أكبر من/يغطي الوزن المحاسب عليه بالطيران (${airVolumetricWeightKg.toStringAsFixed(1)} kg).\n2. الحجم الفعلي (${totalCbm.toStringAsFixed(2)} m³) أقل من 5 m³.',
        isAirSuggested: true,
        isLclSuggested: false,
      );
    } else if (totalCbm > 0 && totalCbm < 15.0) {
      return ShipmentModeRecommendation(
        recommendedMode: 'Sea LCL',
        recommendedModeAr: 'Sea LCL (شحن بحري طرد/جزئي 📦)',
        reasonAr: 'التوصية الذكية: اقتراح شحن بحري جزئي (Sea LCL) لأن إجمالي الحجم (${totalCbm.toStringAsFixed(2)} m³) أقل من 15 m³ ولا يستدعي شحن حاوية كاملة (FCL).',
        isAirSuggested: false,
        isLclSuggested: true,
      );
    } else {
      return ShipmentModeRecommendation(
        recommendedMode: 'Sea FCL',
        recommendedModeAr: 'Sea FCL (شحن بحري حاوية كاملة 🚢)',
        reasonAr: 'التوصية الذكية: اقتراح شحن بحري حاوية كاملة (Sea FCL) لأن الحجم (${totalCbm.toStringAsFixed(2)} m³) يبلغ 15 m³ أو أكثر.',
        isAirSuggested: false,
        isLclSuggested: false,
      );
    }
  }

  static ContainerRecommendationResult calculate({
    required double totalCbm,
    required double totalWeightKg,
    bool isStackable = true,
  }) {
    final modeTag = isStackable ? '📦 قابل للرص (Stackable)' : '🚫 غير قابل للرص (Non-Stackable)';
    final modeRec = recommendShipmentMode(totalCbm: totalCbm, totalWeightKg: totalWeightKg);

    if (totalCbm <= 0 && totalWeightKg <= 0) {
      return ContainerRecommendationResult(
        isStackable: isStackable,
        stackingLabel: modeTag,
        recommendedContainerCode: '40HC',
        requiredContainersCount: 1,
        spaceUtilizationPercent: 0,
        payloadUtilizationPercent: 0,
        recommendationSummary: 'لم يتم تحديد حمولة لحساب الحاوية المقترحة [$modeTag]',
        comparisonDetails: [],
        modeRecommendation: modeRec,
      );
    }

    final List<Map<String, dynamic>> comparisons = [];

    for (final spec in specs) {
      // For Non-Stackable cargo, calculate effective volume and floor footprint constraints:
      // 40HC (76.4 CBM, 28.27 m² floor) fits up to 70 CBM / 28 m² floor footprint safely.
      final double volumeUsabilityFactor = isStackable ? 1.0 : (spec.code == '40HC' || spec.code == '45HC' ? 0.85 : 0.65);
      final double effectiveVolumeCbm = spec.internalVolumeCbm * volumeUsabilityFactor;
      final int countByVol = effectiveVolumeCbm > 0 ? (totalCbm / effectiveVolumeCbm).ceil() : 1;
      final int countByWeight = spec.maxPayloadKg > 0 ? (totalWeightKg / spec.maxPayloadKg).ceil() : 1;
      final int rawReq = countByVol > countByWeight ? countByVol : countByWeight;
      final int reqCount = rawReq < 1 ? 1 : rawReq;

      final double spaceUtil = (totalCbm / (reqCount * spec.internalVolumeCbm)) * 100;
      final double payloadUtil = (totalWeightKg / (reqCount * spec.maxPayloadKg)) * 100;

      // Penalize oversized 45HC when 40HC fits 100% of cargo (e.g. 40 CBM)
      double score = (reqCount * 100) - ((spaceUtil + payloadUtil) / 2);
      if (!isStackable && totalCbm > 30.0 && totalCbm <= 65.0 && spec.code == '40HC' && reqCount == 1) {
        score -= 50.0; // Boost 40HC as ideal non-stackable choice
      }
      if (!isStackable && totalCbm <= 65.0 && spec.code == '45HC') {
        score += 30.0; // Discourage unnecessary 45HC when 40HC is sufficient
      }

      comparisons.add({
        'spec': spec,
        'reqCount': reqCount,
        'effectiveVolumeCbm': effectiveVolumeCbm,
        'spaceUtil': spaceUtil > 100 ? 100.0 : spaceUtil,
        'payloadUtil': payloadUtil > 100 ? 100.0 : payloadUtil,
        'score': score,
      });
    }

    comparisons.sort((a, b) => (a['score'] as double).compareTo(b['score'] as double));

    final best = comparisons.first;
    final bestSpec = best['spec'] as ContainerSpec;
    final int bestCount = best['reqCount'] as int;
    final double bestVol = best['spaceUtil'] as double;
    final double bestWeight = best['payloadUtil'] as double;

    final summary = '$bestCount x ${bestSpec.code} Container(s) [$modeTag] — (استغلال المساحة: ${bestVol.toStringAsFixed(1)}% | استغلال الوزن: ${bestWeight.toStringAsFixed(1)}%)';

    return ContainerRecommendationResult(
      isStackable: isStackable,
      stackingLabel: modeTag,
      recommendedContainerCode: bestSpec.code,
      requiredContainersCount: bestCount,
      spaceUtilizationPercent: bestVol,
      payloadUtilizationPercent: bestWeight,
      recommendationSummary: summary,
      comparisonDetails: comparisons,
      modeRecommendation: modeRec,
    );
  }

  static ContainerDualRecommendationResult calculateBoth({
    required double totalCbm,
    required double totalWeightKg,
  }) {
    final modeRec = recommendShipmentMode(totalCbm: totalCbm, totalWeightKg: totalWeightKg);
    return ContainerDualRecommendationResult(
      stackableResult: calculate(totalCbm: totalCbm, totalWeightKg: totalWeightKg, isStackable: true),
      nonStackableResult: calculate(totalCbm: totalCbm, totalWeightKg: totalWeightKg, isStackable: false),
      modeRecommendation: modeRec,
    );
  }

  static ContainerPackingResult packCargo({
    required List<CargoItem> items,
    required ContainerSpec spec,
  }) {
    // Sort by max footprint dimension descending
    final sortedItems = List<CargoItem>.from(items)
      ..sort((a, b) {
        final maxA = a.length > a.width ? a.length : a.width;
        final maxB = b.length > b.width ? b.length : b.width;
        return maxB.compareTo(maxA);
      });

    final List<PlacedItem> placed = [];
    final List<CargoItem> unplaced = [];

    // Shelves: list of [y_start, shelf_depth, x_cursor]
    final List<List<double>> shelves = [];

    for (final item in sortedItems) {
      if (item.height > spec.internalHeight) {
        unplaced.add(item);
        continue;
      }

      int? bestShelfIdx;
      List<double>? bestOrientation; // [placedLength, placedWidth]

      final orientations = [[item.length, item.width]];
      if (item.rotate) {
        orientations.add([item.width, item.length]);
      }

      // Try existing shelves
      for (int i = 0; i < shelves.length; i++) {
        final shelf = shelves[i];
        final shelfDepth = shelf[1];
        final xCursor = shelf[2];


        for (final orient in orientations) {
          final L = orient[0];
          final W = orient[1];
          if (W <= shelfDepth && (xCursor + L) <= spec.internalLength) {
            bestShelfIdx = i;
            bestOrientation = orient;
            break;
          }
        }
        if (bestShelfIdx != null) break;
      }

      if (bestShelfIdx != null) {
        final L = bestOrientation![0];
        final W = bestOrientation[1];
        final shelf = shelves[bestShelfIdx];
        placed.add(PlacedItem(
          item: item,
          x: shelf[2],
          y: shelf[0],
          length: L,
          width: W,
        ));
        shelf[2] = shelf[2] + L; // increment cursor
        continue;
      }

      // Open new shelf
      double currentWidthUsed = 0.0;
      for (final s in shelves) {
        currentWidthUsed += s[1];
      }

      bool placedOnNewShelf = false;
      for (final orient in orientations) {
        final L = orient[0];
        final W = orient[1];
        if ((currentWidthUsed + W) <= spec.internalWidth && L <= spec.internalLength) {
          shelves.add([currentWidthUsed, W, L]);
          placed.add(PlacedItem(
            item: item,
            x: 0.0,
            y: currentWidthUsed,
            length: L,
            width: W,
          ));
          placedOnNewShelf = true;
          break;
        }
      }

      if (!placedOnNewShelf) {
        unplaced.add(item);
      }
    }

    final totalWeight = placed.fold(0.0, (sum, p) => sum + p.item.weight);
    final totalVolume = placed.fold(0.0, (sum, p) => sum + p.item.volumeM3);
    final fits = unplaced.isEmpty && totalWeight <= spec.maxPayloadKg;

    return ContainerPackingResult(
      containerCode: spec.code,
      spec: spec,
      placedItems: placed,
      unplacedItems: unplaced,
      totalWeight: totalWeight,
      totalVolume: totalVolume,
      fits: fits,
    );
  }

  static List<ContainerPackingResult> planShipment(List<CargoItem> items) {
    List<CargoItem> remaining = List<CargoItem>.from(items);
    final List<ContainerPackingResult> plan = [];
    int guard = 0;

    while (remaining.isNotEmpty && guard < items.length + 5) {
      guard++;

      ContainerPackingResult? bestResult;
      
      // Try containers from smallest to largest: 20GP, 40GP, 40HC, 45HC
      for (final spec in specs) {
        final res = packCargo(items: remaining, spec: spec);
        if (res.fits) {
          bestResult = res;
          break;
        }
      }

      // If nothing fits all remaining, pick the container type that packs the most items.
      if (bestResult == null) {
        ContainerPackingResult? mostPlacedResult;
        int maxPlacedCount = -1;
        for (final spec in specs) {
          final res = packCargo(items: remaining, spec: spec);
          if (res.placedItems.length > maxPlacedCount) {
            maxPlacedCount = res.placedItems.length;
            mostPlacedResult = res;
          }
        }
        bestResult = mostPlacedResult;
      }

      if (bestResult == null || bestResult.placedItems.isEmpty) {
        // Unplaced item that can't fit anywhere
        plan.add(ContainerPackingResult(
          containerCode: 'FAILED',
          spec: specs.last,
          placedItems: [],
          unplacedItems: remaining,
          totalWeight: 0,
          totalVolume: 0,
          fits: false,
        ));
        break;
      }

      plan.add(bestResult);
      final placedIds = bestResult.placedItems.map((p) => p.item.itemId).toSet();
      remaining = remaining.where((i) => !placedIds.contains(i.itemId)).toList();
    }

    return plan;
  }
}

