import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get serverUrl {
    if (kIsWeb) {
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : '127.0.0.1';
      final cleanHost = (host == 'localhost' || host == '0.0.0.0') ? '127.0.0.1' : host;
      return 'http://$cleanHost:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  static String get baseUrl => '$serverUrl/api/v1';

  // Endpoints
  static String get importFiles => '$baseUrl/import-files';
  static String get suppliers => '$baseUrl/suppliers';
  static String get customs => '$baseUrl/customs';
}
