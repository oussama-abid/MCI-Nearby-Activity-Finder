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
import '../../../../utils/api_utils.dart';
import 'activity_detail_page.dart';
import '../../../../utils/user_id_helper.dart';

// Add this class for city suggestions
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
      coordinates: LatLng(
        double.parse(json['lat']),
        double.parse(json['lon']),
      ),
    );
  }
}

List<String> userFavorites = [];
List<Map<String, dynamic>> filteredActivitiesGlobal = [];

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
    _initLocationAndLoadData();
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

  Future<void> _initLocationAndLoadData() async {
    await _getCurrentLocation();
    _futureData = _loadInitialData();
  }

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

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _currentCenter = LatLng(position.latitude, position.longitude);
        _isLocationLoaded = true;
        _locationPermissionGranted = true;
        _loading = false;
      });

      // Move map to current location
      _mapController.move(_currentCenter, 13);
      
      // Update location controller with current city name
      _updateLocationControllerWithCurrentCity();

    } catch (e) {
      print('Error getting location: $e');
      _showLocationError('Could not get current location. Using default location.');
      setState(() => _loading = false);
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
      final cityName = await _getCityNameFromCoordinates(_currentCenter);
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
      'https://nominatim.openstreetmap.org/reverse?format=json&lat=${coordinates.latitude}&lon=${coordinates.longitude}&zoom=10&addressdetails=1'
    );
    
    try {
      final response = await http.get(uri, headers: {
        'User-Agent': 'flutter-dayventure-app'
      });
      
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

    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&addressdetails=1&type=city'
    );
    
    try {
      final response = await http.get(uri, headers: {
        'User-Agent': 'flutter-dayventure-app'
      });
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          final suggestions = data.take(5).map((item) {
            return CitySuggestion.fromJson(item);
          }).toList();
          
          setState(() {
            _citySuggestions = suggestions;
            _showSuggestions = suggestions.isNotEmpty;
          });
          
          if (_showSuggestions) {
            _showSuggestionsOverlay();
          } else {
            _hideSuggestions();
          }
        }
      }
    } catch (e) {
      print("Error fetching city suggestions: $e");
    }
  }

  void _showSuggestionsOverlay() {
    _hideSuggestions(); // Remove existing overlay first
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 32 - 100, // Account for margins and filter button
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 52), // Position below the search bar
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
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
                  return InkWell(
                    onTap: () => _selectSuggestion(suggestion),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_city,
                            color: Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  suggestion.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (suggestion.displayName.isNotEmpty)
                                  Text(
                                    suggestion.displayName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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

  void _selectSuggestion(CitySuggestion suggestion) {
    setState(() {
      _locationController.text = suggestion.name;
      _currentCenter = suggestion.coordinates;
    });
    
    _hideSuggestions();
    _focusNode.unfocus();
    
    // Move map to selected location
    _mapController.move(suggestion.coordinates, 13);
    
    // Reload activities for new location
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

  Future<Map<String, dynamic>> _loadInitialData() async {
    setState(() => _loading = true);
    try {
      final data = await fetchActivities();
      setState(() {
        _loading = false;
        _activities = (data['activities'] as List)
            .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
            .toList();
      });
      return data;
    } catch (e) {
      print('❌ Erreur dans _loadInitialData: $e');
      setState(() => _loading = false);
      return {
        'weather': 'unknown',
        'weatherDescription': 'Erreur',
        'activities': [],
      };
    }
  }

  Future<LatLng?> getCoordinatesFromLocation(String locationName) async {
    if (locationName.trim().isEmpty) return null;
    
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(locationName)}&format=json&limit=1&addressdetails=1'
    );
    
    try {
      final response = await http.get(uri, headers: {
        'User-Agent': 'flutter-dayventure-app'
      });
      
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
      print("Erreur de géolocalisation: $e");
    }
    return null;
  }

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
              content: Text('Location "$location" not found. Please try a different search.'),
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

      setState(() {
        _currentCenter = LatLng(position.latitude, position.longitude);
        _loading = false;
      });

      _mapController.move(_currentCenter, 13);
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

  Future<Map<String, dynamic>> fetchActivities() async {
    print('🚀 fetchActivities() DÉMARRÉ');
    final lat = _currentCenter.latitude;
    final lng = _currentCenter.longitude;

    final uri = buildFilteredUri(
      baseUrl: '192.168.80.1:3000',
      endpoint: '/api/activities',
      filter: currentFilter,
      location: _currentCenter,
      weather: 'clear',
      userId: userId,
    );
    print('📡 URI appelée : $uri');
    print(currentFilter.toString());
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        final activities = (data['activities'] as List)
            .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
            .toList();
        filteredActivitiesGlobal = activities;
        weatherDescription = data['weatherDescription'] ?? '';
        return {
          'weather': data['weather'],
          'weatherDescription': data['weatherDescription'],
          'activities': activities,
        };
      } catch (e) {
        throw Exception('Erreur de format de données');
      }
    } else {
      throw Exception('Failed to load activities');
    }
  }

  // Method to navigate to activity detail page
  void _navigateToActivityDetail(Map<String, dynamic> activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityDetailPage(
          icon: Icons.place,
          title: activity['name'] ?? '',
          location: activity['address'] ?? '',
          weather: weatherDescription,
          temperature: activity['temperature'] ?? '–',
          duration: activity['duration'] ?? '–',
          distance: activity['distance'] ?? '–',
          userLocation: _currentCenter, // Use actual current location
          destinationLocation: LatLng(activity['lat'], activity['lng']),
          openingHours: activity['openingHours'],
          website: activity['website'],
          contact: activity['contact'],
          wikipedia: activity['wikipedia'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (showMap)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentCenter,
                initialZoom: 13,
                maxZoom: 18,
                minZoom: 3,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
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
                if (_isLocationLoaded)
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 40,
                        height: 40,
                        point: _currentCenter,
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.blue,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
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
                              size: 40
                            ),
                          ),
                        );
                      }).toList(),
                      builder: (context, markers) => GestureDetector(
                        onTap: () {
                          // When cluster is tapped, zoom in to show individual markers
                          if (markers.isNotEmpty) {
                            final bounds = _calculateBounds(markers);
                            _mapController.fitCamera(CameraFit.bounds(bounds: bounds));
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
                            ),
                          ),
                        ),
                      ),
                      onClusterTap: (cluster) {
                        // Alternative cluster tap handler
                        final bounds = _calculateBounds(cluster.markers);
                        _mapController.fitCamera(CameraFit.bounds(bounds: bounds));
                      },
                    ),
                  ),
              ],
            )
          else
            FutureBuilder(
              future: _futureData,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.connectionState != ConnectionState.done) {
                  return const SizedBox.shrink();
                }
                final activities = snapshot.data!['activities'] as List<Map<String, dynamic>>;
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 130, bottom: 100),
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return GestureDetector(
                      onTap: () => _navigateToActivityDetail(activity),
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        elevation: 4,
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                Image.network(
                                  activity['image_url'] ?? 'https://via.placeholder.com/400',
                                  fit: BoxFit.cover,
                                  height: 160,
                                  width: double.infinity,
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
                                        userFavorites.contains(activity['id']) ? Icons.favorite : Icons.favorite_border,
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activity['name'] ?? '',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.schedule, size: 18, color: Colors.blueAccent),
                                      const SizedBox(width: 6),
                                      Text(activity['duration'] ?? '–'),
                                      const Spacer(),
                                      const Icon(Icons.place, size: 18, color: Colors.redAccent),
                                      const SizedBox(width: 6),
                                      Text(activity['distance'] ?? '–'),
                                    ],
                                  )
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
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
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
                                hintText: 'Search for a city or location...'
                              ),
                              onChanged: (value) {
                                _fetchCitySuggestions(value);
                              },
                              onSubmitted: (value) => _searchAndMoveToLocation(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.search, color: Colors.blue),
                            onPressed: _searchAndMoveToLocation,
                          ),
                          IconButton(
                            icon: const Icon(Icons.my_location, color: Colors.green),
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
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
          Positioned(
            bottom: 90,
            right: 16,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => RotationTransition(turns: animation, child: child),
              child: FloatingActionButton(
                key: ValueKey(showMap),
                tooltip: showMap ? 'Show List' : 'Show Map',
                backgroundColor: Colors.blueAccent,
                onPressed: () {
                  _hideSuggestions();
                  setState(() => showMap = !showMap);
                },
                child: Icon(showMap ? Icons.list : Icons.map, color: Colors.white,),
              ),
            ),
          ),
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
                  const Icon(Icons.wb_sunny, color: Colors.orange, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    weatherDescription.isNotEmpty ? weatherDescription : 'Loading...',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
      minLng = minLng < marker.point.longitude ? minLng : marker.point.longitude;
      maxLng = maxLng > marker.point.longitude ? maxLng : marker.point.longitude;
    }

    return LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }
}