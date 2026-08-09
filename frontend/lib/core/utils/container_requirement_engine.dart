class ContainerSpec {
  final String code;
  final String name;
  final double internalVolumeCbm;
  final double maxPayloadKg;

  const ContainerSpec({
    required this.code,
    required this.name,
    required this.internalVolumeCbm,
    required this.maxPayloadKg,
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
    ContainerSpec(code: '20GP', name: "20' General Purpose Container", internalVolumeCbm: 33.2, maxPayloadKg: 21700.0),
    ContainerSpec(code: '40GP', name: "40' General Purpose Container", internalVolumeCbm: 67.7, maxPayloadKg: 26500.0),
    ContainerSpec(code: '40HC', name: "40' High Cube Container", internalVolumeCbm: 76.4, maxPayloadKg: 26500.0),
    ContainerSpec(code: '45HC', name: "45' High Cube Container", internalVolumeCbm: 86.0, maxPayloadKg: 27700.0),
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
    final double volumeUsabilityFactor = isStackable ? 1.0 : 0.50;

    for (final spec in specs) {
      final double effectiveVolumeCbm = spec.internalVolumeCbm * volumeUsabilityFactor;
      final int countByVol = effectiveVolumeCbm > 0 ? (totalCbm / effectiveVolumeCbm).ceil() : 1;
      final int countByWeight = spec.maxPayloadKg > 0 ? (totalWeightKg / spec.maxPayloadKg).ceil() : 1;
      final int rawReq = countByVol > countByWeight ? countByVol : countByWeight;
      final int reqCount = rawReq < 1 ? 1 : rawReq;

      final double spaceUtil = (totalCbm / (reqCount * effectiveVolumeCbm)) * 100;
      final double payloadUtil = (totalWeightKg / (reqCount * spec.maxPayloadKg)) * 100;

      comparisons.add({
        'spec': spec,
        'reqCount': reqCount,
        'effectiveVolumeCbm': effectiveVolumeCbm,
        'spaceUtil': spaceUtil > 100 ? 100.0 : spaceUtil,
        'payloadUtil': payloadUtil > 100 ? 100.0 : payloadUtil,
        'score': (reqCount * 100) - ((spaceUtil + payloadUtil) / 2),
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
}
