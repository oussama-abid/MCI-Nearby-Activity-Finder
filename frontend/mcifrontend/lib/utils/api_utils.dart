import 'package:latlong2/latlong.dart';
import '../features/home/domain/activity_filter.dart';

/// Builds a filtered URI for the activities API
Uri buildFilteredUri({
  required String baseUrl,
  required String endpoint,
  required ActivityFilter filter,
  required LatLng location,
  required String weather,
  String? userId,
}) {
  // Get filter parameters
  final params = filter.toQueryParams();
  
  // Add location parameters
  params['lat'] = location.latitude.toString();
  params['lng'] = location.longitude.toString();
  
  // Add weather parameter
  params['weather'] = weather;
  
  // Add userId if provided
  if (userId != null && userId.isNotEmpty) {
    params['userId'] = userId;
  }
  
  // Debug print
  print('🔗 Building URI with params: $params');
  
  // Build URI
  final uri = Uri.http(baseUrl, endpoint, params);
  
  print('🌐 Final URI: $uri');
  
  return uri;
}

/// Builds a URI for a specific activity detail
Uri buildActivityDetailUri({
  required String baseUrl,
  required String activityId,
}) {
  return Uri.http(baseUrl, '/api/activities/$activityId');
}

/// Builds a URI for user favorites
Uri buildUserFavoritesUri({
  required String baseUrl,
  required String userId,
}) {
  return Uri.http(baseUrl, '/api/users/$userId/favorites');
}

/// Builds a URI for marking an activity as visited
Uri buildMarkVisitedUri({
  required String baseUrl,
  required String activityId,
  required String userId,
}) {
  return Uri.http(baseUrl, '/api/activities/$activityId/visited', {
    'userId': userId,
  });
}

/// Builds a URI for adding/removing favorites
Uri buildToggleFavoriteUri({
  required String baseUrl,
  required String activityId,
  required String userId,
}) {
  return Uri.http(baseUrl, '/api/activities/$activityId/favorite', {
    'userId': userId,
  });
}

/// Builds a URI for weather data
Uri buildWeatherUri({
  required String baseUrl,
  required LatLng location,
}) {
  return Uri.http(baseUrl, '/api/weather', {
    'lat': location.latitude.toString(),
    'lng': location.longitude.toString(),
  });
}

/// Helper function to encode query parameters safely
Map<String, String> encodeQueryParams(Map<String, dynamic> params) {
  final encoded = <String, String>{};
  
  for (final entry in params.entries) {
    if (entry.value != null) {
      encoded[entry.key] = entry.value.toString();
    }
  }
  
  return encoded;
}

/// Helper function to validate coordinates
bool isValidCoordinate(double? lat, double? lng) {
  if (lat == null || lng == null) return false;
  return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
}

/// Helper function to validate radius
bool isValidRadius(double? radius) {
  if (radius == null) return false;
  return radius > 0 && radius <= 1000; // Max 1000km
}

/// Debug function to log API calls
void logApiCall(String endpoint, Map<String, String> params) {
  print('📡 API Call: $endpoint');
  print('📋 Parameters:');
  params.forEach((key, value) {
    print('  $key: $value');
  });
}