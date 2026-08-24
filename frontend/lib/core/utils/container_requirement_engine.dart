import 'dart:math' as math;

class CargoItem {
  final String itemId;
  final double length; // cm
  final double width;  // cm
  final double height; // cm
  final double weight; // kg
  final bool rotate;
  final bool isStackable;
  final String? packageType;
  final String? description;

  CargoItem({
    required this.itemId,
    required this.length,
    required this.width,
    required this.height,
    required this.weight,
    this.rotate = true,
    this.isStackable = true,
    this.packageType,
    this.description,
  });

  double get volumeM3 => (length * width * height) / 1000000;
  double get floorAreaM2 => (length * width) / 10000;
}

class PlacedItem {
  final CargoItem item;
  final double x; // offset along length (cm)
  final double y; // offset along width (cm)
  final double z; // elevation from floor (cm)
  final double length; // placed length (cm) after possible rotation
  final double width;  // placed width (cm) after possible rotation
  final double height; // placed height (cm)

  PlacedItem({
    required this.item,
    required this.x,
    required this.y,
    this.z = 0.0,
    required this.length,
    required this.width,
    required this.height,
  });

  bool get isOnFloor => z <= 0.01;
}

class ContainerPackingResult {
  final String containerCode;
  final ContainerSpec spec;
  final List<PlacedItem> placedItems;
  final List<CargoItem> unplacedItems;
  final double totalWeight;
  final double totalVolume;
  final bool fits;
  final String? failureReason;

  ContainerPackingResult({
    required this.containerCode,
    required this.spec,
    required this.placedItems,
    required this.unplacedItems,
    required this.totalWeight,
    required this.totalVolume,
    required this.fits,
    this.failureReason,
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
  final String reasonEn;
  final bool isAirSuggested;
  final bool isLclSuggested;

  ShipmentModeRecommendation({
    required this.recommendedMode,
    required this.recommendedModeAr,
    required this.reasonAr,
    this.reasonEn = '',
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
  final String recommendationSummaryEn;
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
    this.recommendationSummaryEn = '',
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
    final modeTag = isStackable ? '📦 قابل للرص' : '🚫 غير قابل للرص';
    final modeTagEn = isStackable ? '📦 Stackable' : '🚫 Non-Stackable';
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
        recommendationSummaryEn: 'No cargo specified to calculate recommended container [$modeTagEn]',
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

    // Optimized Container Fleet Mix Calculation (e.g. 2x 40HC vs 2x 40HC + 1x 20GP)
    String fleetCombination = '';
    if (isStackable) {
      final int count40HC = (totalCbm / 76.4).ceil();
      fleetCombination = '$count40HC x 40HC Container(s)';
    } else {
      // Non-stackable floor usage:
      final int full40HC = (totalCbm / 50.0).floor();
      final double remCbm = totalCbm - (full40HC * 50.0);
      if (remCbm <= 0) {
        fleetCombination = '${full40HC < 1 ? 1 : full40HC} x 40HC';
      } else if (remCbm <= 25.0) {
        fleetCombination = full40HC > 0 ? '$full40HC x 40HC + 1 x 20GP' : '1 x 20GP';
      } else {
        fleetCombination = '${full40HC + 1} x 40HC';
      }
    }

    final modeDetail = isStackable ? 'رص متعدد الطبقات' : 'رص أرضي فقط Z=0';
    final modeDetailEn = isStackable ? 'Multi-Layer Stacking' : 'Floor-Only Placement (Z=0)';
    final summary = '$fleetCombination [$modeDetail] — (استغلال المساحة: ${bestVol.toStringAsFixed(1)}% | استغلال الوزن: ${bestWeight.toStringAsFixed(1)}%)';
    final summaryEn = '$fleetCombination [$modeDetailEn] — (Space Util: ${bestVol.toStringAsFixed(1)}% | Weight Util: ${bestWeight.toStringAsFixed(1)}%)';

    return ContainerRecommendationResult(
      isStackable: isStackable,
      stackingLabel: modeTag,
      recommendedContainerCode: bestSpec.code,
      requiredContainersCount: bestCount,
      spaceUtilizationPercent: bestVol,
      payloadUtilizationPercent: bestWeight,
      recommendationSummary: summary,
      recommendationSummaryEn: summaryEn,
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

  /// Advanced 3D/2.5D Cargo Packing Algorithm using Extreme-Point 3D Bin Packing:
  /// - Non-stackable cargo: Placed strictly on the container floor (z = 0) and blocks all vertical space above.
  /// - Stackable cargo: Can be placed on the floor (z = 0) or tiled on top of compatible stackable items below.
  static ContainerPackingResult packCargo({
    required List<CargoItem> items,
    required ContainerSpec spec,
  }) {
    // Universal 3D Bin Packing: Sort ALL items primarily by physical footprint/volume descending (Largest First!)
    final sortedItems = List<CargoItem>.from(items)
      ..sort((a, b) {
        final areaA = (a.length * a.width);
        final areaB = (b.length * b.width);
        if ((areaA - areaB).abs() > 1.0) {
          return areaB.compareTo(areaA);
        }
        final volA = a.volumeM3;
        final volB = b.volumeM3;
        if ((volA - volB).abs() > 0.01) {
          return volB.compareTo(volA);
        }
        if (a.isStackable != b.isStackable) {
          return a.isStackable ? 1 : -1;
        }
        return b.length.compareTo(a.length);
      });

    final List<PlacedItem> placed = [];
    final List<CargoItem> unplaced = [];

    // Helper: 3D bounding box collision check
    bool hasCollision(double x, double y, double z, double L, double W, double H) {
      for (final p in placed) {
        final bool overlapX = x < (p.x + p.length - 0.01) && (x + L - 0.01) > p.x;
        final bool overlapY = y < (p.y + p.width - 0.01) && (y + W - 0.01) > p.y;
        final bool overlapZ = z < (p.z + p.height - 0.01) && (z + H - 0.01) > p.z;
        if (overlapX && overlapY && overlapZ) return true;
        // Non-stackable items block all space above them
        if (!p.item.isStackable && overlapX && overlapY && z >= (p.z + p.height - 0.01)) return true;
      }
      return false;
    }

    for (final item in sortedItems) {
      final bool fitsNormal = item.length <= spec.internalLength + 0.1 && item.width <= spec.internalWidth + 0.1;
      final bool fitsRotated = item.rotate && item.width <= spec.internalLength + 0.1 && item.length <= spec.internalWidth + 0.1;
      final bool fitsHeight = item.height <= spec.internalHeight + 0.1;

      // Reject early ONLY if neither orientation fits inside container boundaries or height exceeds internal height
      if (!fitsHeight || (!fitsNormal && !fitsRotated)) {
        unplaced.add(item);
        continue;
      }

      bool isPlaced = false;

      // Evaluate both orientations (swapping Length and Width if rotation is allowed)
      final orientations = <List<double>>[];
      if (fitsNormal) {
        orientations.add([item.length, item.width]);
      }
      if (fitsRotated && (item.length - item.width).abs() > 0.1) {
        orientations.add([item.width, item.length]);
      }
      if (orientations.isEmpty) {
        orientations.add([item.length, item.width]);
      }

      // 1. If stackable, try placing on top of compatible stackable base items
      if (item.isStackable) {
        for (final base in placed) {
          if (!base.item.isStackable) continue;
          final double topZ = base.z + base.height;
          if (topZ + item.height > spec.internalHeight + 0.1) continue;

          // Candidate surface coordinates on top of base
          final List<List<double>> candidateOffsets = [];
          for (final orient in orientations) {
            final L = orient[0];
            final W = orient[1];

            // Try grid positions on base surface
            for (double subX = base.x; subX <= (base.x + base.length - L + 0.1); subX += math.min(L, 10.0)) {
              for (double subY = base.y; subY <= (base.y + base.width - W + 0.1); subY += math.min(W, 10.0)) {
                candidateOffsets.add([subX, subY, L, W]);
              }
            }
          }

          for (final cand in candidateOffsets) {
            final cX = cand[0];
            final cY = cand[1];
            final L = cand[2];
            final W = cand[3];

            if ((cX + L) <= spec.internalLength + 0.1 && (cY + W) <= spec.internalWidth + 0.1) {
              if (!hasCollision(cX, cY, topZ, L, W, item.height)) {
                placed.add(PlacedItem(
                  item: item,
                  x: cX,
                  y: cY,
                  z: topZ,
                  length: L,
                  width: W,
                  height: item.height,
                ));
                isPlaced = true;
                break;
              }
            }
          }
          if (isPlaced) break;
        }
      }

      if (isPlaced) continue;

      // 2. Place on container floor (z = 0) using Extreme Points
      final List<List<double>> floorCandidates = [[0.0, 0.0]];
      for (final p in placed) {
        if (p.x + p.length <= spec.internalLength) floorCandidates.add([p.x + p.length, p.y]);
        if (p.y + p.width <= spec.internalWidth) floorCandidates.add([p.x, p.y + p.width]);
        if (p.x + p.length <= spec.internalLength && p.y + p.width <= spec.internalWidth) {
          floorCandidates.add([p.x + p.length, p.y + p.width]);
        }
      }

      // Sort candidate floor points: Y ascending, then X ascending
      floorCandidates.sort((a, b) {
        final cmpY = a[1].compareTo(b[1]);
        if (cmpY != 0) return cmpY;
        return a[0].compareTo(b[0]);
      });

      for (final cand in floorCandidates) {
        final cX = cand[0];
        final cY = cand[1];

        for (final orient in orientations) {
          final L = orient[0];
          final W = orient[1];

          if ((cX + L) <= spec.internalLength + 0.1 && (cY + W) <= spec.internalWidth + 0.1) {
            if (!hasCollision(cX, cY, 0.0, L, W, item.height)) {
              placed.add(PlacedItem(
                item: item,
                x: cX,
                y: cY,
                z: 0.0,
                length: L,
                width: W,
                height: item.height,
              ));
              isPlaced = true;
              break;
            }
          }
        }
        if (isPlaced) break;
      }

      if (!isPlaced) {
        unplaced.add(item);
      }
    }

    final totalWeight = placed.fold(0.0, (sum, p) => sum + p.item.weight);
    final totalVolume = placed.fold(0.0, (sum, p) => sum + p.item.volumeM3);
    final fits = unplaced.isEmpty && totalWeight <= spec.maxPayloadKg;

    String? failureReason;
    if (unplaced.isNotEmpty) {
      final reasons = <String>[];
      for (final u in unplaced) {
        final bool fitsNormal = u.length <= spec.internalLength + 0.1 && u.width <= spec.internalWidth + 0.1;
        final bool fitsRotated = u.rotate && u.width <= spec.internalLength + 0.1 && u.length <= spec.internalWidth + 0.1;
        final bool fitsHeight = u.height <= spec.internalHeight + 0.1;

        if (!fitsNormal && !fitsRotated) {
          if (u.length > spec.internalWidth && u.width > spec.internalWidth) {
            reasons.add('فشل الرص: تجاوز الطول والعرض الأبعاد القياسية للحاوية (أبعاد الطرد: ${u.length.toStringAsFixed(0)} × ${u.width.toStringAsFixed(0)} سم - أقصى عرض مسموح للحاوية ${spec.internalWidth.toStringAsFixed(0)} سم)');
          } else if (u.length > spec.internalLength || u.width > spec.internalLength) {
            reasons.add('فشل الرص: أبعاد الطرد (${u.length.toStringAsFixed(0)} × ${u.width.toStringAsFixed(0)} سم) تتجاوز الطول الداخلي للحاوية (${spec.internalLength.toStringAsFixed(0)} سم)');
          } else {
            reasons.add('فشل الرص: أبعاد الطرد (${u.length.toStringAsFixed(0)} × ${u.width.toStringAsFixed(0)} سم) تتجاوز الأبعاد القياسية الداخلية للحاوية ${spec.code}');
          }
        } else if (!fitsHeight) {
          reasons.add('فشل الرص: ارتفاع الطرد (${u.height.toStringAsFixed(0)} سم) يتجاوز الارتفاع الداخلي للحاوية (${spec.internalHeight.toStringAsFixed(0)} سم)');
        } else {
          reasons.add('فشل الرص: يتعذر رص الطرد داخل الحاوية بسبب تزاحم المساحة الأرضية أو سعة الاستيعاب');
        }
      }
      failureReason = reasons.toSet().join(' | ');
    } else if (totalWeight > spec.maxPayloadKg) {
      failureReason = 'فشل الرص: إجمالي وزن الحمولة (${totalWeight.toStringAsFixed(0)} kg) يتجاوز الوزن المسموح للحاوية (${spec.maxPayloadKg.toStringAsFixed(0)} kg)';
    }

    return ContainerPackingResult(
      containerCode: spec.code,
      spec: spec,
      placedItems: placed,
      unplacedItems: unplaced,
      totalWeight: totalWeight,
      totalVolume: totalVolume,
      fits: fits,
      failureReason: failureReason,
    );
  }

  static List<ContainerPackingResult> planShipment(
    List<CargoItem> items, {
    bool? forceStackable,
  }) {
    // If forceStackable is specified, override isStackable for all items
    final List<CargoItem> effectiveItems = items.map((i) => CargoItem(
      itemId: i.itemId,
      length: i.length,
      width: i.width,
      height: i.height,
      weight: i.weight,
      rotate: i.rotate,
      isStackable: forceStackable ?? i.isStackable,
      packageType: i.packageType,
      description: i.description,
    )).toList();

    List<CargoItem> remaining = List<CargoItem>.from(effectiveItems);
    final List<ContainerPackingResult> plan = [];
    int guard = 0;

    // Standard container specs for maritime shipping
    final spec20GP = specs.firstWhere((s) => s.code == '20GP');
    final spec40HC = specs.firstWhere((s) => s.code == '40HC');
    final spec40GP = specs.firstWhere((s) => s.code == '40GP');
    final spec45HC = specs.firstWhere((s) => s.code == '45HC');

    while (remaining.isNotEmpty && guard < items.length + 15) {
      guard++;

      // 1. Check if all remaining items fit in a 20GP
      final res20 = packCargo(items: remaining, spec: spec20GP);
      if (res20.fits) {
        plan.add(res20);
        break;
      }

      // 2. Check if all remaining items fit in a 40GP
      final res40 = packCargo(items: remaining, spec: spec40GP);
      if (res40.fits) {
        plan.add(res40);
        break;
      }

      // 3. Check if all remaining items fit in a 40HC (The universal standard high cube)
      final res40HC = packCargo(items: remaining, spec: spec40HC);
      if (res40HC.fits) {
        plan.add(res40HC);
        break;
      }

      // 4. Check if all remaining items fit in a 45HC (only if items exceed 40HC dimensions)
      final hasExtraLongItem = remaining.any((i) => i.length > 1203 || (i.rotate && i.width > 1203));
      if (hasExtraLongItem) {
        final res45HC = packCargo(items: remaining, spec: spec45HC);
        if (res45HC.fits) {
          plan.add(res45HC);
          break;
        }
      }

      // 5. Multi-container packing step: Fill a standard 40HC first (or 45HC if oversized)
      final targetSpec = hasExtraLongItem ? spec45HC : spec40HC;
      final res = packCargo(items: remaining, spec: targetSpec);

      if (res.placedItems.isEmpty) {
        // Fallback to largest available spec
        final fallbackRes = packCargo(items: remaining, spec: spec45HC);
        if (fallbackRes.placedItems.isEmpty) {
          plan.add(ContainerPackingResult(
            containerCode: 'FAILED',
            spec: spec40HC,
            placedItems: [],
            unplacedItems: remaining,
            totalWeight: 0,
            totalVolume: 0,
            fits: false,
            failureReason: fallbackRes.failureReason ?? 'فشل الرص: تجاوز أبعاد الطرد الأبعاد القياسية المسموح بها داخل الحاوية',
          ));
          break;
        }
        plan.add(fallbackRes);
        final placedIds = fallbackRes.placedItems.map((p) => p.item.itemId).toSet();
        remaining = remaining.where((i) => !placedIds.contains(i.itemId)).toList();
      } else {
        plan.add(res);
        final placedIds = res.placedItems.map((p) => p.item.itemId).toSet();
        remaining = remaining.where((i) => !placedIds.contains(i.itemId)).toList();
      }
    }

    return plan;
  }
}


