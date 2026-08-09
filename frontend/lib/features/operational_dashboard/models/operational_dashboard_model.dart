import '../../import_files/models/import_file_model.dart';

class DashboardBroker {
  final int? brokerId;
  final String brokerName;

  DashboardBroker({this.brokerId, required this.brokerName});

  factory DashboardBroker.fromJson(Map<String, dynamic> json) {
    return DashboardBroker(
      brokerId: json['broker_id'],
      brokerName: json['broker_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'broker_id': brokerId,
        'broker_name': brokerName,
      };
}

class OperationalDashboardData {
  final int shipmentCount;
  final List<ImportFileModel> shipments;
  final String lastUpdatedAt;
  final List<DashboardBroker> availableBrokers;
  final Map<String, int> phaseCounts;

  OperationalDashboardData({
    required this.shipmentCount,
    required this.shipments,
    required this.lastUpdatedAt,
    required this.availableBrokers,
    required this.phaseCounts,
  });

  factory OperationalDashboardData.fromJson(Map<String, dynamic> json) {
    var rawShipments = json['shipments'] as List<dynamic>? ?? [];
    var rawBrokers = json['available_brokers'] as List<dynamic>? ?? [];
    var rawPhaseCounts = json['phase_counts'] as Map<String, dynamic>? ?? {};

    Map<String, int> parsedPhaseCounts = {};
    rawPhaseCounts.forEach((key, value) {
      parsedPhaseCounts[key] = (value as num).toInt();
    });

    return OperationalDashboardData(
      shipmentCount: json['shipment_count'] ?? 0,
      shipments: rawShipments.map((e) => ImportFileModel.fromJson(e)).toList(),
      lastUpdatedAt: json['last_updated_at'] ?? '',
      availableBrokers: rawBrokers.map((e) => DashboardBroker.fromJson(e)).toList(),
      phaseCounts: parsedPhaseCounts,
    );
  }
}
