import 'package:latlong2/latlong.dart';
import '../features/home/domain/activity_filter.dart';

Uri buildFilteredUri({
  required String baseUrl,
  required String endpoint,
  required ActivityFilter filter,
  required LatLng location,
  required String weather,
  String? userId,
}) {
  final queryParams = {
    'weather': weather,
    'lat': location.latitude.toString(),
    'lng': location.longitude.toString(),
    'radius': filter.radiusKm.toString(),
    'peopleCount': filter.peopleCount.toString(),
    'childrenCount': filter.childrenCount.toString(),
    'childAge': filter.childAge.toString(),
    'popularity': filter.popularity.toString(),
    'considerWeather': filter.considerWeather.toString(),
    'accessibleOnly': filter.accessibleOnly.toString(),
    'favoritesOnly': filter.favoritesOnly.toString(),
    'showVisited': filter.showVisited.toString(),
    'environment': filter.environment,
  };

  if (filter.interests.isNotEmpty) {
    queryParams['interests'] = filter.interests.join(',');
  }
  if (userId != null) {
    queryParams['userId'] = userId;
  }

  return Uri.http(baseUrl, endpoint, queryParams);
}
