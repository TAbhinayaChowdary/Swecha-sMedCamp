import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ApiService {
  // Base URL for your backend
  static String get baseUrl => AppConfig.baseUrl;

  // Shared preferences instance
  static late SharedPreferences _prefs;

  // Initialize shared preferences
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Get stored token
  static String? get token => _prefs.getString('auth_token');

  // Store token
  static Future<void> setToken(String token) async {
    await _prefs.setString('auth_token', token);
  }

  // Clear token (logout)
  static Future<void> clearToken() async {
    await _prefs.remove('auth_token');
  }

  // Generic GET request
  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Generic POST request
  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to post data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Generic PUT request
  static Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Generic DELETE request
  static Future<void> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Authentication methods
  static Future<Map<String, dynamic>> login(String username, String password) async {
    return await post('/auth/login', {
      'username': username,
      'password': password,
    });
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    return await post('/auth/register', userData);
  }

  // Patient methods
  static Future<Map<String, dynamic>> getPatients() async {
    return await get('/patients');
  }

  static Future<Map<String, dynamic>> createPatient(Map<String, dynamic> patientData) async {
    return await post('/patients', patientData);
  }

  static Future<Map<String, dynamic>> updatePatient(String patientId, Map<String, dynamic> patientData) async {
    return await put('/patients/$patientId', patientData);
  }

  static Future<void> deletePatient(String patientId) async {
    return await delete('/patients/$patientId');
  }

  // Vitals methods
  static Future<Map<String, dynamic>> getVitals(String patientId) async {
    return await get('/vitals/$patientId');
  }

  static Future<Map<String, dynamic>> createVitals(Map<String, dynamic> vitalsData) async {
    return await post('/vitals', vitalsData);
  }

  // Queue methods
  static Future<Map<String, dynamic>> getQueue() async {
    return await get('/queue');
  }

  static Future<Map<String, dynamic>> addToQueue(Map<String, dynamic> queueData) async {
    return await post('/queue', queueData);
  }

  // Inventory methods
  static Future<Map<String, dynamic>> getInventory() async {
    return await get('/inventory');
  }

  static Future<Map<String, dynamic>> updateInventory(String itemId, Map<String, dynamic> inventoryData) async {
    return await put('/inventory/$itemId', inventoryData);
  }

  // Admin methods
  static Future<Map<String, dynamic>> getAdminStats() async {
    return await get('/admin/stats');
  }

  static Future<Map<String, dynamic>> getDoctors() async {
    return await get('/admin/doctors');
  }

  static Future<Map<String, dynamic>> assignDoctor(Map<String, dynamic> assignmentData) async {
    return await post('/doctor-assign', assignmentData);
  }
} 