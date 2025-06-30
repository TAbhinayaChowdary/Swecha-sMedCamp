import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ConnectionTest {
  static Future<bool> testBackendConnection() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/admin/stats'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('✅ Backend connection successful');
        return true;
      } else {
        print('❌ Backend connection failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Backend connection error: $e');
      return false;
    }
  }

  static Future<void> testAllEndpoints() async {
    final endpoints = [
      '/auth/login',
      '/patients',
      '/vitals',
      '/queue',
      '/inventory',
      '/admin/stats',
    ];

    print('🔍 Testing backend endpoints...\n');

    for (final endpoint in endpoints) {
      try {
        final response = await http.get(
          Uri.parse('${AppConfig.baseUrl}$endpoint'),
          headers: {
            'Content-Type': 'application/json',
          },
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200 || response.statusCode == 401) {
          print('✅ $endpoint - OK (${response.statusCode})');
        } else {
          print('❌ $endpoint - Failed (${response.statusCode})');
        }
      } catch (e) {
        print('❌ $endpoint - Error: $e');
      }
    }
  }

  static void printConnectionInfo() {
    print('📡 Backend Configuration:');
    print('   Base URL: ${AppConfig.baseUrl}');
    print('   App Name: ${AppConfig.appName}');
    print('   Version: ${AppConfig.appVersion}');
    print('   Timeout: ${AppConfig.connectionTimeout}ms\n');
  }
} 