import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mcifrontend/features/home/domain/activity_filter.dart';
import 'package:mcifrontend/features/home/presentation/widgets/filter_sheet.dart';
import 'package:mcifrontend/shared/widgets/getIcon_for_type.dart';
import '../../../../utils/api_utils.dart';
import 'activity_detail_page.dart';
import '../../../../utils/user_id_helper.dart';

// Add this class for city suggestions
LatLng? _userActualLocation; // Add this line
LatLng _currentCenter = LatLng(53.0793, 8.8017); // Keep this for map center

class CitySuggestion {
  final String name;
  final String displayName;
  final LatLng coordinates;

  CitySuggestion({
    required this.name,
    required this.displayName,
    required this.coordinates,
  });

  factory CitySuggestion.fromJson(Map<String, dynamic> json) {
    return CitySuggestion(
      name: json['name'] ?? '',
      displayName: json['display_name'] ?? '',
      coordinates: LatLng(double.parse(json['lat']), double.parse(json['lon'])),
    );
  }
}

// Add weather data class
class WeatherData {
  final String description;
  final double temperature;
  final String condition;
  final String icon;

  WeatherData({
    required this.description,
    required this.temperature,
    required this.condition,
    required this.icon,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    try {
      // Your API returns nested structure, so we need to extract from the right places
      final weather = json['weather'] as Map<String, dynamic>?;
      final temperature = json['temperature'] as Map<String, dynamic>?;
      
      return WeatherData(
        description: weather?['description'] ?? 'Unknown',
        temperature: _safeToDouble(temperature?['current']) ?? 20.0,
        condition: weather?['main'] ?? 'clear',
        icon: weather?['mapped'] ?? 'sunny', // Use the mapped weather condition
      );
    } catch (e) {
      print('❌ Error parsing weather JSON: $e');
      print('📄 Received JSON: $json');
      
      // Return fallback data if parsing fails
      return WeatherData(
        description: 'Weather data currently unavailable',
        temperature: 20.0,
        condition: 'clear',
        icon: 'sunny',
      );
    }
  }
    static double? _safeToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('⚠️ Could not parse "$value" as double');
        return null;
      }
    }
    return null;
  }

}


List<String> userFavorites = [];
List<Map<String, dynamic>> filteredActivitiesGlobal = [];

IconData _getWeatherIcon(String condition) {
  switch (condition) {
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
    case 'drizzle':
      return Icons.grain;
    case 'mist':
    case 'fog':
      return Icons.blur_on;
    default:
      return Icons.wb_sunny;
  }
}

Color _getWeatherColor(String condition) {
  switch (condition) {
    case 'clear':
      return Colors.orange;
    case 'clouds':
      return Colors.grey;
    case 'rain':
      return Colors.blue;
    case 'snow':
      return Colors.lightBlue;
    case 'thunderstorm':
      return Colors.deepPurple;
    case 'drizzle':
      return Colors.blueAccent;
    case 'mist':
    case 'fog':
      return Colors.grey;
    default:
      return Colors.orange;
  }
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  LatLng _currentCenter = LatLng(53.0793, 8.8017); // Default Bremen
  late Future<Map<String, dynamic>> _futureData;
  bool showMap = true;
  String weatherDescription = '';
  double currentTemperature = 20.0;
  String currentWeatherCondition = 'clear';
  String currentWeatherIcon = 'sunny';
  final TextEditingController _locationController = TextEditingController();
  ActivityFilter currentFilter = ActivityFilter();
  bool _loading = false;
  List<Map<String, dynamic>> _activities = [];
  String? userId;
  bool _isLocationLoaded = false;
  bool _locationPermissionGranted = false;

  // Add these variables for city suggestions
  List<CitySuggestion> _citySuggestions = [];
  bool _showSuggestions = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final FocusNode _focusNode = FocusNode();

@override
void initState() {
  super.initState();
  _initUser();
  _checkLocationSettings(); // Check settings first
  _initLocationAndLoadData(); // Then initialize
  _setupFocusListener();
}

  void _setupFocusListener() {
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _hideSuggestions();
      }
    });
  }

  void _initUser() async {
    final id = await getOrCreateUserId();
    setState(() {
      userId = id;
    });
  }

  // NEW: Fetch weather data from API
Future<WeatherData> _fetchWeatherDataWithUri(LatLng location) async {
  try {
    // Create URI similar to how buildFilteredUri works in fetchActivities
    final uri = Uri.http(
      '192.168.80.1:3000',
      '/api/weather',
      {
        'lat': location.latitude.toString(),
        'lng': location.longitude.toString(),
      },
    );
    
    print('🌤️ Weather API URI: $uri');
    
    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    print('🌤️ Weather API Response Status: ${response.statusCode}');
    print('🌤️ Weather API Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['error'] != null) {
        throw Exception(data['error']);
      }
      return WeatherData.fromJson(data);
    } else {
      print('❌ Weather API error: ${response.statusCode} - ${response.body}');
      throw Exception('Weather API returned ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Error fetching weather: $e');
    return WeatherData(
      description: 'Weather data currently unavailable',
      temperature: 20.0,
      condition: 'clear',
      icon: 'sunny',
    );
  }
}


  // UPDATED: Load weather data when location changes
 Future<void> _updateWeatherForLocation(LatLng location) async {
  try {
    final weatherData = await _fetchWeatherDataWithUri(location);
    setState(() {
      weatherDescription = weatherData.description;
      currentTemperature = weatherData.temperature;
      currentWeatherCondition = weatherData.condition;
      currentWeatherIcon = weatherData.icon;
    });
  } catch (e) {
    print('Error updating weather: $e');
    setState(() {
      weatherDescription = 'Weather data currently unavailable';
      currentTemperature = 20.0;
      currentWeatherCondition = 'clear';
      currentWeatherIcon = 'sunny';
    });
  }
}

 Future<void> _initLocationAndLoadData() async {
  // Start both operations in parallel
  final locationFuture = _getCurrentLocationWithFallback();
  final dataFuture = _loadInitialData();
  
  // Wait for both with a timeout
  try {
    await Future.wait([
      locationFuture,
      dataFuture,
    ]).timeout(const Duration(seconds: 8));
  } catch (e) {
    print('Timeout or error during initialization: $e');
    setState(() => _loading = false);
  }
}

Future<void> _checkLocationSettings() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    _showLocationSettingsDialog();
    return;
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    _showPermissionDialog();
    return;
  }

  if (permission == LocationPermission.deniedForever) {
    _showPermissionSettingsDialog();
    return;
  }
}

void _showLocationSettingsDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Location Services Disabled'),
      content: const Text('Please enable location services in your device settings to use this feature.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            Geolocator.openLocationSettings();
          },
          child: const Text('Open Settings'),
        ),
      ],
    ),
  );
}

void _showPermissionDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Location Permission Required'),
      content: const Text('This app needs location permission to show activities near you.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            _getCurrentLocationWithFallback();
          },
          child: const Text('Grant Permission'),
        ),
      ],
    ),
  );
}

void _showPermissionSettingsDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Location Permission Denied'),
      content: const Text('Location permission is permanently denied. Please enable it in app settings.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            Geolocator.openAppSettings();
          },
          child: const Text('Open Settings'),
        ),
      ],
    ),
  );
}

  // UPDATED: Get current location and fetch weather
  Future<void> _getCurrentLocation() async {
  setState(() => _loading = true);

  try {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationError('Location services are disabled. Please enable them in settings.');
      setState(() => _loading = false);
      return;
    }

    // Check location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showLocationError('Location permissions are denied. Using default location.');
        setState(() => _loading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showLocationError('Location permissions are permanently denied. Please enable them in settings.');
      setState(() => _loading = false);
      return;
    }

    // OPTIMIZED: Use balanced accuracy and shorter timeout
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium, // Changed from high to medium
      timeLimit: const Duration(seconds: 5), // Reduced from 10 to 5 seconds
    );

    final newLocation = LatLng(position.latitude, position.longitude);
    
    setState(() {
      _userActualLocation = newLocation;
      _currentCenter = newLocation;
      _isLocationLoaded = true;
      _locationPermissionGranted = true;
      _loading = false;
    });

    // Move map to current location
    _mapController.move(_currentCenter, 13);

    // Update weather for new location
    await _updateWeatherForLocation(newLocation);

    // Update location controller with current city name
    _updateLocationControllerWithCurrentCity();
  } catch (e) {
    print('Error getting location: $e');
    _showLocationError('Could not get current location. Using default location.');
    setState(() => _loading = false);
  }
}

Future<void> _getCurrentLocationWithFallback() async {
  setState(() => _loading = true);

  try {
    // First try to get last known position (faster)
    Position? lastKnownPosition = await Geolocator.getLastKnownPosition();
    
    if (lastKnownPosition != null) {
      // Use last known position immediately
      final newLocation = LatLng(lastKnownPosition.latitude, lastKnownPosition.longitude);
      
      setState(() {
        _userActualLocation = newLocation;
        _currentCenter = newLocation;
        _isLocationLoaded = true;
        _locationPermissionGranted = true;
        _loading = false;
      });
      
      _mapController.move(_currentCenter, 13);
      
      // Update weather for this location
      await _updateWeatherForLocation(newLocation);
      
      _updateLocationControllerWithCurrentCity();
      
      // Optional: Get fresh location in background
      _getCurrentLocationFresh();
      return;
    }
    
    // If no last known position, get current location
    await _getCurrentLocationFresh();
  } catch (e) {
    print('Error getting location: $e');
    _showLocationError('Could not get current location. Using default location.');
    setState(() => _loading = false);
  }
}

Future<void> _getCurrentLocationFresh() async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 5),
    );

    final newLocation = LatLng(position.latitude, position.longitude);

    setState(() {
      _userActualLocation = newLocation;
      _currentCenter = newLocation;
      _isLocationLoaded = true;
      _locationPermissionGranted = true;
    });

    _mapController.move(_currentCenter, 13);
    
    // Update weather for new location
    await _updateWeatherForLocation(newLocation);
    
    _updateLocationControllerWithCurrentCity();
  } catch (e) {
    print('Error getting fresh location: $e');
  }
}

  void _showLocationError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _updateLocationControllerWithCurrentCity() async {
    try {
      final cityName = await _getCityNameFromCoordinates(_userActualLocation ?? _currentCenter);
      if (cityName != null && mounted) {
        setState(() {
          _locationController.text = cityName;
        });
      }
    } catch (e) {
      print('Error getting city name: $e');
    }
  }

  Future<String?> _getCityNameFromCoordinates(LatLng coordinates) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=json&lat=${coordinates.latitude}&lon=${coordinates.longitude}&zoom=10&addressdetails=1',
    );

    try {
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'flutter-dayventure-app'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          // Try to get city name from different possible fields
          return address['city'] ??
              address['town'] ??
              address['village'] ??
              address['municipality'] ??
              address['county'] ??
              'Unknown Location';
        }
      }
    } catch (e) {
      print("Error getting city name: $e");
    }
    return null;
  }

  // Add this method to fetch city suggestions
  Future<void> _fetchCitySuggestions(String query) async {
    if (query.length < 2) {
      setState(() {
        _citySuggestions = [];
        _showSuggestions = false;
      });
      _hideSuggestions();
      return;
    }

    try {
      List<CitySuggestion> allSuggestions = [];

      // First, search for German cities
      final germanUri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=10&addressdetails=1&countrycodes=de&type=city',
      );

      final germanResponse = await http.get(
        germanUri,
        headers: {'User-Agent': 'flutter-dayventure-app'},
      );

      if (germanResponse.statusCode == 200) {
        final germanData = jsonDecode(germanResponse.body);
        if (germanData is List) {
          final germanSuggestions = germanData.map((item) {
            return CitySuggestion.fromJson(item);
          }).toList();
          allSuggestions.addAll(germanSuggestions);
        }
      }

      // If we don't have enough German results, add international results
      if (allSuggestions.length < 8) {
        final internationalUri = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=10&addressdetails=1&type=city',
        );

        final internationalResponse = await http.get(
          internationalUri,
          headers: {'User-Agent': 'flutter-dayventure-app'},
        );

        if (internationalResponse.statusCode == 200) {
          final internationalData = jsonDecode(internationalResponse.body);
          if (internationalData is List) {
            final internationalSuggestions = internationalData.map((item) {
              return CitySuggestion.fromJson(item);
            }).toList();

            // Add international suggestions that aren't already in the list
            for (final suggestion in internationalSuggestions) {
              if (!allSuggestions.any(
                (existing) =>
                    existing.name.toLowerCase() ==
                        suggestion.name.toLowerCase() &&
                    existing.coordinates.latitude ==
                        suggestion.coordinates.latitude &&
                    existing.coordinates.longitude ==
                        suggestion.coordinates.longitude,
              )) {
                allSuggestions.add(suggestion);
              }
            }
          }
        }
      }
      // Limit to 8 suggestions total
      final limitedSuggestions = allSuggestions.take(8).toList();

      setState(() {
        _citySuggestions = limitedSuggestions;
        _showSuggestions = limitedSuggestions.isNotEmpty;
      });

      if (_showSuggestions) {
        _showSuggestionsOverlay();
      } else {
        _hideSuggestions();
      }
    } catch (e) {
      print("Error fetching city suggestions: $e");
    }
  }

  // UPDATED: Select suggestion and update weather
  void _selectSuggestion(CitySuggestion suggestion) async {
    setState(() {
      _locationController.text = suggestion.name;
      _currentCenter = suggestion.coordinates;
      _loading = true; // Add loading state
    });

    _hideSuggestions();
    _focusNode.unfocus();

    // Move map to selected location
    _mapController.move(suggestion.coordinates, 13);

    // Update weather for new location
    await _updateWeatherForLocation(suggestion.coordinates);

    // Automatically reload activities for new location
    _futureData = _loadInitialData();

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Moved to: ${suggestion.name}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Updated suggestions overlay with better styling and more items
  void _showSuggestionsOverlay() {
    _hideSuggestions(); // Remove existing overlay first

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width:
            MediaQuery.of(context).size.width -
            32 -
            100, // Account for margins and filter button
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 52), // Position below the search bar
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(
                maxHeight: 300,
              ), // Increased height for more suggestions
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _citySuggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _citySuggestions[index];
                  final isGerman =
                      suggestion.displayName.contains('Deutschland') ||
                      suggestion.displayName.contains('Germany');

                  return InkWell(
                    onTap: () => _selectSuggestion(suggestion),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.withOpacity(0.2),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isGerman ? Icons.location_city : Icons.public,
                            color: isGerman ? Colors.red : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        suggestion.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: isGerman
                                              ? Colors.black
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    if (isGerman)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: const Text(
                                          'DE',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (suggestion.displayName.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      suggestion.displayName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideSuggestions() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _showSuggestions = false;
    });
  }

  // UPDATED: Load initial data with weather
  Future<Map<String, dynamic>> _loadInitialData() async {
    setState(() => _loading = true);
    try {
      // Update weather for current location
      await _updateWeatherForLocation(_currentCenter);
      
      final data = await fetchActivities();
      setState(() {
        _loading = false;
        _activities = (data['activities'] as List)
            .map<Map<String, dynamic>>(
              (item) => Map<String, dynamic>.from(item),
            )
            .toList();
      });
      return data;
    } catch (e) {
      print('❌ Error in _loadInitialData: $e');
      setState(() => _loading = false);
      return {
        'weather': currentWeatherCondition,
        'weatherDescription': weatherDescription,
        'activities': [],
      };
    }
  }

  Future<LatLng?> getCoordinatesFromLocation(String locationName) async {
    if (locationName.trim().isEmpty) return null;

    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(locationName)}&format=json&limit=1&addressdetails=1',
    );

    try {
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'flutter-dayventure-app'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          final item = data[0];
          final latStr = item['lat']?.toString();
          final lonStr = item['lon']?.toString();

          if (latStr != null && lonStr != null) {
            final lat = double.tryParse(latStr);
            final lon = double.tryParse(lonStr);

            if (lat != null && lon != null) {
              return LatLng(lat, lon);
            }
          }
        }
      }
    } catch (e) {
      print("Geolocation error: $e");
    }
    return null;
  }

  // UPDATED: Search and move to location with weather update
  Future<void> _searchAndMoveToLocation() async {
    final location = _locationController.text.trim();
    if (location.isEmpty) return;

    _hideSuggestions();
    _focusNode.unfocus();
    setState(() => _loading = true);

    try {
      final coords = await getCoordinatesFromLocation(location);
      if (coords != null) {
        setState(() {
          _currentCenter = coords;
          _loading = false;
        });

        // Animate to the new location
        _mapController.move(coords, 13);

        // Update weather for new location
        await _updateWeatherForLocation(coords);

        // Reload activities for new location
        _futureData = _loadInitialData();

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Moved to: $location'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() => _loading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Location "$location" not found. Please try a different search.',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      print('Search error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error searching for location. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // UPDATED: Recenter to current location with weather update
  Future<void> _recenterToCurrentLocation() async {
    if (!_locationPermissionGranted) {
      await _getCurrentLocation();
      return;
    }

    setState(() => _loading = true);

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      final newLocation = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _userActualLocation = newLocation;
        _currentCenter = newLocation;
        _loading = false;
      });

      _mapController.move(_currentCenter, 13);
      
      // Update weather for new location
      await _updateWeatherForLocation(newLocation);
      
      _updateLocationControllerWithCurrentCity();
      _futureData = _loadInitialData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Centered to current location'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      _showLocationError('Could not get current location');
    }
  }

  // UPDATED: Fetch activities with real weather condition
  Future<Map<String, dynamic>> fetchActivities() async {
    print('🚀 fetchActivities() STARTED');
    final lat = _currentCenter.latitude;
    final lng = _currentCenter.longitude;

    final uri = buildFilteredUri(
      baseUrl: '192.168.80.1:3000',
      endpoint: '/api/activities',
      filter: currentFilter,
      location: _currentCenter,
      weather: currentWeatherCondition, // Use real weather condition
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
        filteredActivitiesGlobal = activities;
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

  // UPDATED: Navigate to activity detail with real weather data
 void _navigateToActivityDetail(Map<String, dynamic> activity) {
  final lat = activity['lat'] ?? activity['latitude'];
  final lng = activity['lng'] ?? activity['lon'] ?? activity['longitude'];

  final destination = (lat != null && lng != null)
      ? LatLng((lat as num).toDouble(), (lng as num).toDouble())
      : LatLng(0, 0);

  if (lat == null || lng == null) {
    print("Activity without valid coordinates: ${activity['name']}");
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ActivityDetailPage(
        icon: getIconForType(activity['type'] ?? 'default'),
        title: activity['name'] ?? 'Nom inconnu',
        location: activity['location'] ?? activity['address'] ?? 'Emplacement inconnu',
        weather: weatherDescription.isNotEmpty ? weatherDescription : 'Loading weather...', // Use real weather
        temperature: _parseTemperature(activity['temperature']), // Parse from activity temperature
        userLocation: _userActualLocation ?? _currentCenter,
        destinationLocation: destination,
        // Optional parameters from database if available
        openingHours: activity['opening_hours'],
        website: activity['website'],
        contact: activity['contact'],
        wikipedia: activity['wikipedia'],
      ),
    ),
  );
}

String _parseTemperature(dynamic temperature) {
  if (temperature == null) return '20°C';
  
  String tempStr = temperature.toString();
  
  // If it's already a temperature format (like "25°C")
  if (tempStr.contains('°')) {
    return tempStr;
  }
  
  // If it's a numeric value, add °C
  final numTemp = double.tryParse(tempStr);
  if (numTemp != null) {
    return '${numTemp.round()}°C';
  }
  
  // Default fallback
  return '20°C';
}

  // Replace your entire build method with this fixed version:

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content area
          if (showMap)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentCenter,
                initialZoom: 13,
                maxZoom: 18,
                minZoom: 3,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
                onTap: (tapPosition, point) {
                  _hideSuggestions();
                  _focusNode.unfocus();
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                // Current location marker
                if (_isLocationLoaded && _userActualLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 40,
                        height: 40,
                        point: _userActualLocation!, // Use actual location
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.blue,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                // FIXED CLUSTER IMPLEMENTATION
                if (_activities.isNotEmpty)
                  MarkerClusterLayerWidget(
                    options: MarkerClusterLayerOptions(
                      maxClusterRadius: 45,
                      size: const Size(40, 40),
                      markers: _activities.map((activity) {
                        return Marker(
                          width: 40,
                          height: 40,
                          point: LatLng(activity['lat'], activity['lng']),
                          child: GestureDetector(
                            onTap: () => _navigateToActivityDetail(activity),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        );
                      }).toList(),
                      builder: (context, markers) => GestureDetector(
                        onTap: () {
                          // When cluster is tapped, zoom in to show individual markers
                          if (markers.isNotEmpty) {
                            final bounds = _calculateBounds(markers);
                            // Calculate center point of the cluster
                            final center = LatLng(
                              (bounds.north + bounds.south) / 2,
                              (bounds.east + bounds.west) / 2,
                            );

                            // Calculate appropriate zoom level based on current zoom
                            double currentZoom = _mapController.camera.zoom;
                            double newZoom = currentZoom + 2;

                            // If only 2 markers and they're close, zoom in more aggressively
                            if (markers.length <= 2) {
                              newZoom = currentZoom + 3;
                            }

                            // Ensure we don't exceed maximum zoom
                            if (newZoom > 18) newZoom = 18;

                            // Move map to center of cluster with increased zoom
                            _mapController.move(center, newZoom);
                          }
                        },
                        child: Container(
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            markers.length.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            )
          else
            // Fixed ListView container with proper constraints
            Column(
              children: [
                // Space for the search bar
                const SizedBox(height: 120),
                // Expanded ListView that takes remaining space
                Expanded(
                  child: FutureBuilder(
                    future: _futureData,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData ||
                          snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final activities =
                          snapshot.data!['activities']
                              as List<Map<String, dynamic>>;

                      if (activities.isEmpty) {
                        return const Center(
                          child: Text(
                            'No activities found',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.only(
                          bottom: 100,
                        ), // Space for floating buttons
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: activities.length,
                        itemBuilder: (context, index) {
                          final activity = activities[index];
                          return GestureDetector(
                            onTap: () => _navigateToActivityDetail(activity),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              elevation: 4,
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Stack(
                                    children: [
                                      Image.network(
                                        activity['image_url'] ??
                                            'https://via.placeholder.com/400',
                                        fit: BoxFit.cover,
                                        height: 160,
                                        width: double.infinity,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                height: 160,
                                                width: double.infinity,
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.image_not_supported,
                                                  size: 50,
                                                  color: Colors.grey,
                                                ),
                                              );
                                            },
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              final id = activity['id'];
                                              if (userFavorites.contains(id)) {
                                                userFavorites.remove(id);
                                              } else {
                                                userFavorites.add(id);
                                              }
                                            });
                                          },
                                          child: CircleAvatar(
                                            backgroundColor: Colors.white,
                                            child: Icon(
                                              userFavorites.contains(
                                                    activity['id'],
                                                  )
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          activity['name'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.schedule,
                                              size: 18,
                                              color: Colors.blueAccent,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(activity['duration'] ?? '–'),
                                            const Spacer(),
                                            const Icon(
                                              Icons.place,
                                              size: 18,
                                              color: Colors.redAccent,
                                            ),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                activity['distance'] ?? '–',
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (activity['address'] != null &&
                                            activity['address']
                                                .toString()
                                                .isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.location_on,
                                                  size: 16,
                                                  color: Colors.grey,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    activity['address'],
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),

          // Loading overlay
          if (_loading)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  color: Colors.white.withOpacity(0.4),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),

          // Search bar - positioned on top
          Positioned(
            top: 60,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(
                  child: CompositedTransformTarget(
                    link: _layerLink,
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _locationController,
                              focusNode: _focusNode,
                              decoration: const InputDecoration.collapsed(
                                hintText: 'Search for a city or location...',
                              ),
                              onChanged: (value) {
                                _fetchCitySuggestions(value);
                              },
                              onSubmitted: (value) =>
                                  _searchAndMoveToLocation(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.search, color: Colors.blue),
                            onPressed: _searchAndMoveToLocation,
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.my_location,
                              color: Colors.green,
                            ),
                            onPressed: _recenterToCurrentLocation,
                            tooltip: 'Current Location',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    _hideSuggestions();
                    final result = await showModalBottomSheet<ActivityFilter>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (context) => Padding(
                        padding: MediaQuery.of(context).viewInsets,
                        child: FilterSheet(initialFilter: currentFilter),
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        currentFilter = result;
                        _futureData = _loadInitialData();
                      });
                    }
                  },
                  icon: const Icon(Icons.filter_alt),
                  label: const Text("Filter"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // Floating action button
          Positioned(
            bottom: 90,
            right: 16,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) =>
                  RotationTransition(turns: animation, child: child),
              child: FloatingActionButton(
                key: ValueKey(showMap),
                tooltip: showMap ? 'Show List' : 'Show Map',
                backgroundColor: Colors.blueAccent,
                onPressed: () {
                  _hideSuggestions();
                  setState(() => showMap = !showMap);
                },
                child: Icon(
                  showMap ? Icons.list : Icons.map,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Weather info
Positioned(
  bottom: 20,
  left: 16,
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _getWeatherIcon(currentWeatherIcon),
          color: _getWeatherColor(currentWeatherCondition),
          size: 24,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${currentTemperature.round()}°C',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              weatherDescription,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ],
    ),
  ),
),
        ],
      ),
    );
  }

  // Helper method to calculate bounds for camera fitting
  LatLngBounds _calculateBounds(List<Marker> markers) {
    if (markers.isEmpty) return LatLngBounds.fromPoints([_currentCenter]);

    double minLat = markers.first.point.latitude;
    double maxLat = markers.first.point.latitude;
    double minLng = markers.first.point.longitude;
    double maxLng = markers.first.point.longitude;

    for (final marker in markers) {
      minLat = minLat < marker.point.latitude ? minLat : marker.point.latitude;
      maxLat = maxLat > marker.point.latitude ? maxLat : marker.point.latitude;
      minLng = minLng < marker.point.longitude
          ? minLng
          : marker.point.longitude;
      maxLng = maxLng > marker.point.longitude
          ? maxLng
          : marker.point.longitude;
    }

    return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }
}
