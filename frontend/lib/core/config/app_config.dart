/// Application configuration constants
class AppConfig {
  static const String appName = 'Citizen Civic AI';
  static const String appVersion = '1.0.0';
  
  // API Configuration
  static const String apiBaseUrl = 'http://localhost:8000/api/v1';
  static const Duration apiTimeout = Duration(seconds: 30);
  
  // Firebase
  static const String firebaseProjectId = '';
  
  // Google Maps
  static const String googleMapsApiKey = '';
  
  // Supported Languages
  static const List<String> supportedLanguages = ['en', 'ta', 'hi'];
  static const String defaultLanguage = 'en';
  
  // Pagination
  static const int defaultPageSize = 20;
  
  // Location
  static const double defaultLatitude = 13.0827; // Chennai
  static const double defaultLongitude = 80.2707;
  static const double defaultRadiusKm = 10.0;
  
  // Image
  static const int maxImageSize = 10 * 1024 * 1024; // 10 MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];
  
  AppConfig._();
}
