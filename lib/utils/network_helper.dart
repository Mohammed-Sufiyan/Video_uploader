import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

import '../config.dart';

/// Helper functions for network connectivity and reachability
class NetworkHelper {
  /// Returns true if the device has any network connection
  static Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// Check if backend is reachable within a timeout
  static Future<bool> canReachBackend({Duration? timeout}) async {
    final String url = AppConfig.presignedUrlEndpoint;
    try {
      final uri = Uri.parse(url);
      final response = await http.head(uri).timeout(
          timeout ?? Duration(seconds: AppConfig.connectionTimeoutSeconds));
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  /// Ensures we are online and backend is reachable. Throws with message otherwise.
  static Future<void> ensureNetworkReady() async {
    final online = await isOnline();
    if (!online) {
      throw Exception('No internet connection. Please check your network.');
    }

    final reachable = await canReachBackend();
    if (!reachable) {
      throw Exception('Server not reachable. Please try again later.');
    }
  }
}
