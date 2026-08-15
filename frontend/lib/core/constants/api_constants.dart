import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get serverUrl {
    if (kIsWeb) {
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : '127.0.0.1';
      final port = Uri.base.port == 8000 ? 8000 : 8000;
      return 'http://$host:$port';
    }
    return 'http://127.0.0.1:8000';
  }

  static String get baseUrl => '$serverUrl/api/v1';

  // Endpoints
  static String get importFiles => '$baseUrl/import-files';
  static String get suppliers => '$baseUrl/suppliers';
  static String get customs => '$baseUrl/customs';
}
