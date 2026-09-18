import 'dart:collection';

class ClientDiagnosticEvent {
  final String timestamp;
  final String category; // NETWORK, UI_ERROR, SYSTEM
  final String message;
  final String? requestId;
  final int? statusCode;
  final int? durationMs;

  ClientDiagnosticEvent({
    required this.timestamp,
    required this.category,
    required this.message,
    this.requestId,
    this.statusCode,
    this.durationMs,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp,
        'category': category,
        'message': message,
        'request_id': requestId,
        'status_code': statusCode,
        'duration_ms': durationMs,
      };
}

class ClientDiagnosticsService {
  ClientDiagnosticsService._();
  static final ClientDiagnosticsService instance = ClientDiagnosticsService._();

  static const int maxEvents = 100;
  final Queue<ClientDiagnosticEvent> _events = Queue<ClientDiagnosticEvent>();

  void recordNetworkEvent({
    required String method,
    required String path,
    required int statusCode,
    required int durationMs,
    String? requestId,
  }) {
    _addEvent(ClientDiagnosticEvent(
      timestamp: DateTime.now().toIso8601String(),
      category: 'NETWORK',
      message: '$method $path',
      requestId: requestId,
      statusCode: statusCode,
      durationMs: durationMs,
    ));
  }

  void recordError(String message, {String? requestId, Object? error}) {
    _addEvent(ClientDiagnosticEvent(
      timestamp: DateTime.now().toIso8601String(),
      category: 'UI_ERROR',
      message: error != null ? '$message: $error' : message,
      requestId: requestId,
    ));
  }

  void _addEvent(ClientDiagnosticEvent event) {
    if (_events.length >= maxEvents) {
      _events.removeFirst();
    }
    _events.add(event);
  }

  List<ClientDiagnosticEvent> getEvents() {
    return _events.toList().reversed.toList();
  }

  String exportLogText() {
    final buffer = StringBuffer();
    buffer.writeln('=== Sorour Logistics Desktop Client Diagnostics Log ===');
    buffer.writeln('Generated at: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total events: ${_events.length}');
    buffer.writeln('-------------------------------------------------------');
    for (final e in _events) {
      buffer.writeln(
          '[${e.timestamp}] [${e.category}] ${e.message} ${e.statusCode != null ? '(Status: ${e.statusCode})' : ''} ${e.durationMs != null ? '(${e.durationMs}ms)' : ''} ${e.requestId != null ? '[ID: ${e.requestId}]' : ''}');
    }
    return buffer.toString();
  }
}
