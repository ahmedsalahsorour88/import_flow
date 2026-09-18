import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

/// Configures TLS / SSL certificate validation for desktop and mobile platforms.
/// Enables secure HTTPS communication over private local area networks (LAN)
/// with self-signed SAN certificates while enforcing standard CA verification for public domains.
void configureDioTls(Dio dio) {
  if (!kIsWeb) {
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = (X509Certificate cert, String host, int port) {
          // Allow self-signed certificates for localhost and private subnets (RFC 1918)
          final isLocalhost = host == 'localhost' || host == '127.0.0.1';
          final isPrivateLan = host.startsWith('192.168.') ||
              host.startsWith('10.') ||
              (host.startsWith('172.') && _isClassBPrivate(host));
          return isLocalhost || isPrivateLan;
        };
        return client;
      },
    );
  }
}

bool _isClassBPrivate(String host) {
  final parts = host.split('.');
  if (parts.length >= 2) {
    final secondOctet = int.tryParse(parts[1]);
    if (secondOctet != null && secondOctet >= 16 && secondOctet <= 31) {
      return true;
    }
  }
  return false;
}
