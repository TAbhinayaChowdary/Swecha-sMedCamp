class AppConfig {
  // Backend API configuration
  static const String devBaseUrl = 'http://192.168.71.211:5002/api'; // Android emulator
  static const String iosBaseUrl = 'http://localhost:5002/api'; // iOS simulator
  static const String prodBaseUrl = 'https://your-production-domain.com/api'; // Production
  
  // Get the appropriate base URL based on platform
  static String get baseUrl {
    // You can add platform detection here if needed
    // For now, we'll use the Android emulator URL
    return devBaseUrl;
  }
  
  // API endpoints
  static const String authEndpoint = '/auth';
  static const String patientsEndpoint = '/patients';
  static const String vitalsEndpoint = '/vitals';
  static const String queueEndpoint = '/queue';
  static const String inventoryEndpoint = '/inventory';
  static const String adminEndpoint = '/admin';
  static const String doctorAssignEndpoint = '/doctor-assign';
  
  // App settings
  static const String appName = 'Medical Camp';
  static const String appVersion = '1.0.0';
  
  // Timeout settings
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  
  // Pagination settings
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
} 