import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:mcifrontend/features/home/presentation/pages/activity_detail_page.dart';
import 'package:mcifrontend/shared/widgets/getIcon_for_type.dart';

// Detailed weather data class to handle your API response
class DetailedWeatherData {
  final bool success;
  final Location location;
  final Weather weather;
  final Temperature temperature;
  final Conditions conditions;
  final Wind wind;
  final Sun sun;
  final Meta meta;

  DetailedWeatherData({
    required this.success,
    required this.location,
    required this.weather,
    required this.temperature,
    required this.conditions,
    required this.wind,
    required this.sun,
    required this.meta,
  });

  factory DetailedWeatherData.fromJson(Map<String, dynamic> json) {
    return DetailedWeatherData(
      success: json['success'] ?? false,
      location: Location.fromJson(json['location'] ?? {}),
      weather: Weather.fromJson(json['weather'] ?? {}),
      temperature: Temperature.fromJson(json['temperature'] ?? {}),
      conditions: Conditions.fromJson(json['conditions'] ?? {}),
      wind: Wind.fromJson(json['wind'] ?? {}),
      sun: Sun.fromJson(json['sun'] ?? {}),
      meta: Meta.fromJson(json['meta'] ?? {}),
    );
  }
}

class Location {
  final double lat;
  final double lng;
  final String coordinates;

  Location({required this.lat, required this.lng, required this.coordinates});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
      coordinates: json['coordinates'] ?? '',
    );
  }
}

class Weather {
  final String main;
  final String description;
  final String icon;
  final String mapped;
  final String iconUrl;

  Weather({
    required this.main,
    required this.description,
    required this.icon,
    required this.mapped,
    required this.iconUrl,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      main: json['main'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      mapped: json['mapped'] ?? '',
      iconUrl: json['iconUrl'] ?? '',
    );
  }
}

class Temperature {
  final int current;
  final int feelsLike;
  final int min;
  final int max;
  final String unit;

  Temperature({
    required this.current,
    required this.feelsLike,
    required this.min,
    required this.max,
    required this.unit,
  });

  factory Temperature.fromJson(Map<String, dynamic> json) {
    return Temperature(
      current: json['current'] ?? 0,
      feelsLike: json['feelsLike'] ?? 0,
      min: json['min'] ?? 0,
      max: json['max'] ?? 0,
      unit: json['unit'] ?? '°C',
    );
  }
}

class Conditions {
  final int humidity;
  final int pressure;
  final int visibility;
  final int cloudiness;

  Conditions({
    required this.humidity,
    required this.pressure,
    required this.visibility,
    required this.cloudiness,
  });

  factory Conditions.fromJson(Map<String, dynamic> json) {
    return Conditions(
      humidity: json['humidity'] ?? 0,
      pressure: json['pressure'] ?? 0,
      visibility: json['visibility'] ?? 0,
      cloudiness: json['cloudiness'] ?? 0,
    );
  }
}

class Wind {
  final double speed;
  final int direction;
  final double? gust;
  final String speedUnit;

  Wind({
    required this.speed,
    required this.direction,
    this.gust,
    required this.speedUnit,
  });

  factory Wind.fromJson(Map<String, dynamic> json) {
    return Wind(
      speed: (json['speed'] ?? 0.0).toDouble(),
      direction: json['direction'] ?? 0,
      gust: json['gust']?.toDouble(),
      speedUnit: json['speedUnit'] ?? 'm/s',
    );
  }
}

class Sun {
  final String sunrise;
  final String sunset;

  Sun({required this.sunrise, required this.sunset});

  factory Sun.fromJson(Map<String, dynamic> json) {
    return Sun(
      sunrise: json['sunrise'] ?? '',
      sunset: json['sunset'] ?? '',
    );
  }
}

class Meta {
  final String timestamp;
  final String source;
  final String apiVersion;

  Meta({required this.timestamp, required this.source, required this.apiVersion});

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      timestamp: json['timestamp'] ?? '',
      source: json['source'] ?? '',
      apiVersion: json['apiVersion'] ?? '',
    );
  }
}

// Activity data class
class Activity {
  final String id;
  final String title;
  final String description;
  final String category;
  final String? imageUrl;
  final String? location;
  final double? rating;
  final String? duration;
  final String? price;
  final String? openingHours;
  final String? website;
  final String? contact;
  final String? wikipedia;
  final List<String>? interests;
  final int? popularity;
  final DateTime? createdAt;
  final double? lat;
  final double? lng;
  final String? weatherTag;
  final bool? accessible;
  final String? environment;
  final List<String>? userFavorites;
  final List<String>? visitedBy;
  final int? peopleCount;
  final int? childrenCount;
  final String? childAge;
  final bool? considerWeather;
  final bool? favoritesOnly;
  final bool? enfantFriendly;
  final int? durationMinutes;
  final String? distance;
  final double? distanceKm;

  Activity({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.imageUrl,
    this.location,
    this.rating,
    this.duration,
    this.price,
    this.openingHours,
    this.website,
    this.contact,
    this.wikipedia,
    this.interests,
    this.popularity,
    this.createdAt,
    this.lat,
    this.lng,
    this.weatherTag,
    this.accessible,
    this.environment,
    this.userFavorites,
    this.visitedBy,
    this.peopleCount,
    this.childrenCount,
    this.childAge,
    this.considerWeather,
    this.favoritesOnly,
    this.enfantFriendly,
    this.durationMinutes,
    this.distance,
    this.distanceKm,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id']?.toString() ?? '',
      title: json['name'] ?? '', // Changed from 'title' to 'name'
      description: json['description'] ?? json['name'] ?? '', // Use name as fallback for description
      category: json['type'] ?? '', // Changed from 'category' to 'type'
      imageUrl: json['image_url'], // Changed from 'imageUrl' to 'image_url'
      location: json['location']?.toString(),
      rating: json['rating']?.toDouble(),
      duration: json['duration']?.toString(),
      price: json['price_range']?.toString(), // Changed from 'price' to 'price_range'
      openingHours: json['opening_hours']?.toString(),
      website: json['website']?.toString(),
      contact: json['contact']?.toString(),
      wikipedia: json['wikipedia']?.toString(),
      interests: json['interests'] != null 
          ? List<String>.from(json['interests'].map((x) => x.toString()))
          : null,
      popularity: json['popularity']?.toInt(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      lat: json['lat']?.toDouble(),
      lng: json['lng']?.toDouble(),
      weatherTag: json['weather_tag']?.toString(),
      accessible: json['accessible'] as bool?,
      environment: json['environment']?.toString(),
      userFavorites: json['user_favorites'] != null 
          ? List<String>.from(json['user_favorites'].map((x) => x.toString()))
          : null,
      visitedBy: json['visited_by'] != null 
          ? List<String>.from(json['visited_by'].map((x) => x.toString()))
          : null,
      peopleCount: json['people_count']?.toInt(),
      childrenCount: json['children_count']?.toInt(),
      childAge: json['child_age']?.toString(),
      considerWeather: json['consider_weather'] as bool?,
      favoritesOnly: json['favorites_only'] as bool?,
      enfantFriendly: json['enfant_friendly'] as bool?,
      durationMinutes: json['duration_minutes']?.toInt(),
      distance: json['distance']?.toString(),
      distanceKm: json['distanceKm']?.toDouble(),
    );
  }
}
// Filter class (you'll need to implement this based on your current filter structure)
class ActivityFilter {
  // Add your filter properties here
  final String? category;
  final double? maxDistance;
  final String? priceRange;

  ActivityFilter({
    this.category,
    this.maxDistance,
    this.priceRange,
  });

  @override
  String toString() {
    return 'ActivityFilter{category: $category, maxDistance: $maxDistance, priceRange: $priceRange}';
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DetailedWeatherData? _weatherData;
  String _locationName = 'Bremen, Deutschland';
  bool _isLoading = true;
  String _errorMessage = '';
  Position? _currentPosition;
  List<Activity> _activities = [];
  bool _isLoadingActivities = false;
  String _activitiesError = '';
  
  // Add your filter and user ID here
  final ActivityFilter currentFilter = ActivityFilter();
  final String userId = 'your_user_id'; // Replace with actual user ID

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Get current location
      final position = await _getCurrentPosition();
      
      // Fetch weather data
      final weatherData = await _fetchWeatherData(position.latitude, position.longitude);
      
      // Get location name
      final locationName = await _getLocationName(position.latitude, position.longitude);
      
      setState(() {
        _weatherData = weatherData;
        _locationName = locationName;
        _currentPosition = position;
        _isLoading = false;
      });

      // Load activities after weather data is loaded
      _loadActivities();
    } catch (e) {
      print('Error loading weather data: $e');
      setState(() {
        _errorMessage = 'Could not load weather data';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadActivities() async {
    if (_currentPosition == null || _weatherData == null) return;

    setState(() {
      _isLoadingActivities = true;
      _activitiesError = '';
    });

    try {
      final activitiesData = await fetchActivities();
      final activities = (activitiesData['activities'] as List)
          .map<Activity>((item) => Activity.fromJson(item))
          .toList();

      setState(() {
        _activities = activities;
        _isLoadingActivities = false;
      });
    } catch (e) {
      print('Error loading activities: $e');
      setState(() {
        _activitiesError = 'Could not load activities';
        _isLoadingActivities = false;
      });
    }
  }

  Future<Map<String, dynamic>> fetchActivities() async {
    print('🚀 fetchActivities() STARTED');
    
    if (_currentPosition == null || _weatherData == null) {
      throw Exception('Position or weather data not available');
    }

    final lat = _currentPosition!.latitude;
    final lng = _currentPosition!.longitude;
    final currentWeatherCondition = _weatherData!.weather.mapped;
    final weatherDescription = _weatherData!.weather.description;

    final uri = buildFilteredUri(
      baseUrl: '192.168.80.1:3000',
      endpoint: '/api/activities',
      filter: currentFilter,
      location: _currentPosition!,
      weather: currentWeatherCondition,
      userId: userId,
    );

    print('📡 URI called: $uri');
    print(currentFilter.toString());

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        final activities = (data['activities'] as List)
            .map<Map<String, dynamic>>(
              (item) => Map<String, dynamic>.from(item),
            )
            .toList();

        return {
          'weather': currentWeatherCondition,
          'weatherDescription': weatherDescription,
          'activities': activities,
        };
      } catch (e) {
        throw Exception('Data format error');
      }
    } else {
      throw Exception('Failed to load activities');
    }
  }

  Uri buildFilteredUri({
    required String baseUrl,
    required String endpoint,
    required ActivityFilter filter,
    required Position location,
    required String weather,
    required String userId,
  }) {
    Map<String, String> queryParams = {
      'lat': location.latitude.toString(),
      'lng': location.longitude.toString(),
      'weather': weather,
      'userId': userId,
    };

    // Add filter parameters
    if (filter.category != null) {
      queryParams['category'] = filter.category!;
    }
    if (filter.maxDistance != null) {
      queryParams['maxDistance'] = filter.maxDistance!.toString();
    }
    if (filter.priceRange != null) {
      queryParams['priceRange'] = filter.priceRange!;
    }

    return Uri.http(baseUrl, endpoint, queryParams);
  }
void _navigateToActivityDetail(Activity activity) {
  // Access properties directly from the Activity object
  final lat = activity.lat;
  final lng = activity.lng;

  final destination = (lat != null && lng != null)
      ? LatLng((lat as num).toDouble(), (lng as num).toDouble())
      : LatLng(0, 0);

  if (lat == null || lng == null) {
    print("Activity without valid coordinates: ${activity.title}");
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ActivityDetailPage(
        icon: getIconForType(activity.category ?? 'default'),
        title: activity.title ?? 'Nom inconnu',
        location: activity.location ?? activity.location ?? 'Emplacement inconnu',
        weather: _weatherData?.weather.description ?? 'Unknown weather',
        temperature: '${_weatherData?.temperature.current ?? 'N/A'}°',
        userLocation: LatLng(
          _currentPosition?.latitude ?? 53.0793,
          _currentPosition?.longitude ?? 8.8017,
        ),
        destinationLocation: destination,
        // Optional parameters from Activity object if available
        openingHours: activity.openingHours,
        website: activity.website,
        contact: activity.contact,
        wikipedia: activity.wikipedia,
      ),
    ),
  );
}
  Future<Position> _getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Use default Bremen coordinates
      return Position(
        latitude: 53.0793,
        longitude: 8.8017,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Use default Bremen coordinates
        return Position(
          latitude: 53.0793,
          longitude: 8.8017,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Use default Bremen coordinates
      return Position(
        latitude: 53.0793,
        longitude: 8.8017,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 5),
    );
  }

  Future<DetailedWeatherData> _fetchWeatherData(double lat, double lng) async {
    final uri = Uri.http(
      '192.168.80.1:3000',
      '/api/weather',
      {
        'lat': lat.toString(),
        'lng': lng.toString(),
      },
    );

    print('🌤️ Fetching weather from: $uri');

    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['error'] != null) {
        throw Exception(data['error']);
      }
      return DetailedWeatherData.fromJson(data);
    } else {
      throw Exception('Weather API returned ${response.statusCode}');
    }
  }

  Future<String> _getLocationName(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=10&addressdetails=1',
      );

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'flutter-dayventure-app'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          final city = address['city'] ?? 
                      address['town'] ?? 
                      address['village'] ?? 
                      address['municipality'] ?? 
                      'Unknown City';
          final country = address['country'] ?? 'Unknown Country';
          return '$city, $country';
        }
      }
    } catch (e) {
      print('Error getting location name: $e');
    }
    return 'Unknown Location';
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
        return Icons.grain;
      case 'snow':
        return Icons.ac_unit;
      case 'thunderstorm':
        return Icons.flash_on;
      default:
        return Icons.wb_sunny;
    }
  }

  Color _getWeatherColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return const Color(0xFFFFE62E);
      case 'clouds':
        return Colors.grey;
      case 'rain':
        return Colors.blue;
      case 'snow':
        return Colors.lightBlue;
      case 'thunderstorm':
        return Colors.deepPurple;
      default:
        return const Color(0xFFFFE62E);
    }
  }

  String _getWeatherDescription(String description) {
    // Translate common weather descriptions to German
    switch (description.toLowerCase()) {
      case 'clear sky':
        return 'Klarer Himmel';
      case 'few clouds':
        return 'Wenige Wolken';
      case 'scattered clouds':
        return 'Vereinzelte Wolken';
      case 'broken clouds':
        return 'Überwiegend bewölkt';
      case 'overcast clouds':
        return 'Bedeckt';
      case 'light rain':
        return 'Leichter Regen';
      case 'moderate rain':
        return 'Mäßiger Regen';
      case 'heavy rain':
        return 'Starker Regen';
      case 'sunny':
        return 'Sonnig';
      default:
        return description;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'outdoor':
        return Icons.nature_people;
      case 'indoor':
        return Icons.home;
      case 'sports':
        return Icons.sports_soccer;
      case 'culture':
        return Icons.museum;
      case 'food':
        return Icons.restaurant;
      case 'entertainment':
        return Icons.movie;
      case 'shopping':
        return Icons.shopping_bag;
      default:
        return Icons.local_activity;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF0071BC),
                ),
              )
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage,
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadWeatherData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0071BC),
                          ),
                          child: Text(
                            'Retry',
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        // Top bar with title and weather icon
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Dayventure',
                                style: GoogleFonts.montserrat(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              Icon(
                                _getWeatherIcon(_weatherData?.weather.mapped ?? 'sunny'),
                                color: _getWeatherColor(_weatherData?.weather.mapped ?? 'sunny'),
                                size: 49,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        
                        // Temperature
                        Text(
                          '${_weatherData?.temperature.current ?? 19}°',
                          style: GoogleFonts.montserrat(
                            fontSize: 80,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF534E4E),
                          ),
                        ),
                        const SizedBox(height: 10),
                        
                        // Weather description
                        Text(
                          _getWeatherDescription(_weatherData?.weather.description ?? 'Sonnig'),
                          style: GoogleFonts.montserrat(
                            fontSize: 24,
                            color: const Color(0xFFA29B9B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Location
                        Text(
                          _locationName,
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        
                        // Weather details
                        if (_weatherData != null) ...[
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildWeatherDetail(
                                  'Gefühlt',
                                  '${_weatherData!.temperature.feelsLike}°',
                                  Icons.thermostat,
                                ),
                                _buildWeatherDetail(
                                  'Luftfeuchte',
                                  '${_weatherData!.conditions.humidity}%',
                                  Icons.water_drop,
                                ),
                                _buildWeatherDetail(
                                  'Wind',
                                  '${_weatherData!.wind.speed.toStringAsFixed(1)} ${_weatherData!.wind.speedUnit}',
                                  Icons.air,
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 40),
                        
                        // Activities carousel
                        _buildActivitiesCarousel(),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildWeatherDetail(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFF0071BC),
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            color: const Color(0xFFA29B9B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF534E4E),
          ),
        ),
      ],
    );
  }
Widget _buildActivitiesCarousel() {
  // Sort activities by popularity (descending) and take top 5
 final topActivities = (_activities
  .where((activity) => activity.popularity != null)
  .toList()
  ..sort((a, b) => (b.popularity ?? 0).compareTo(a.popularity ?? 0)))
  .take(5)
  .toList();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Top Aktivitäten',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF534E4E),
              ),
            ),
            if (_isLoadingActivities)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF0071BC),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      
      if (_activitiesError.isNotEmpty)
        Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  _activitiesError,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _loadActivities,
                  child: Text(
                    'Erneut versuchen',
                    style: GoogleFonts.montserrat(
                      color: const Color(0xFF0071BC),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
      else if (topActivities.isEmpty && !_isLoadingActivities)
        Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Icon(
                  Icons.local_activity,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  'Keine Aktivitäten gefunden',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        )
      else
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            itemCount: topActivities.length,
            itemBuilder: (context, index) {
              final activity = topActivities[index];
              return Container(
                width: 300,
                margin: const EdgeInsets.only(right: 16),
                child: _buildActivityCard(activity),
              );
            },
          ),
        ),
    ],
  );
}

  Widget _buildActivityCard(Activity activity) {
     return GestureDetector(
    onTap: () => _navigateToActivityDetail(activity),
    child:  Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Activity image or icon
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              color: const Color(0xFF0071BC).withOpacity(0.1),
            ),
            child: activity.imageUrl != null
                ? ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: Image.network(
                      activity.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildActivityIcon(activity.category);
                      },
                    ),
                  )
                : _buildActivityIcon(activity.category),
          ),
          
          // Activity details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF534E4E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity.description,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: const Color(0xFFA29B9B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (activity.rating != null) ...[
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Color(0xFFFFE62E),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              activity.rating!.toStringAsFixed(1),
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                color: const Color(0xFF534E4E),
                              ),
                            ),
                          ],
                          if (activity.rating != null && activity.duration != null)
                            const SizedBox(width: 8),
                          if (activity.duration != null) ...[
                            const Icon(
                              Icons.access_time,
                              size: 16,
                              color: Color(0xFFA29B9B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              activity.duration!,
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                color: const Color(0xFF534E4E),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (activity.price != null)
                        Text(
                          activity.price!,
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0071BC),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),);
  }

  Widget _buildActivityIcon(String category) {
    return Center(
      child: Icon(
        _getCategoryIcon(category),
        size: 48,
        color: const Color(0xFF0071BC),
      ),
    );
  }
}