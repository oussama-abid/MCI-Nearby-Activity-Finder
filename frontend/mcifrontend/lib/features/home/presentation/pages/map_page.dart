import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:mcifrontend/features/home/domain/activity_filter.dart';
import 'package:mcifrontend/features/home/presentation/widgets/filter_sheet.dart';

import '../../../../utils/api_utils.dart';
import 'activity_detail_page.dart';
import '../../../../utils/user_id_helper.dart';

List<String> userFavorites = [];
List<Map<String, dynamic>> filteredActivitiesGlobal = [];

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  LatLng _currentCenter = LatLng(53.0793, 8.8017); // Bremen
  late Future<Map<String, dynamic>> _futureData;
  bool showMap = true;
  String weatherDescription = '';
  final TextEditingController _locationController = TextEditingController();
  ActivityFilter currentFilter = ActivityFilter();
  bool _loading = false;
  List<Map<String, dynamic>> _activities = [];
  String? userId;

  @override
  void initState() {
    super.initState();
    _initUser();
    _futureData = _loadInitialData();
  }

  void _initUser() async {
    final id = await getOrCreateUserId();
    setState(() {
      userId = id;
    });
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
    final uri = Uri.parse('https://nominatim.openstreetmap.org/search?q=$locationName&format=json&limit=1');
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

  Future<Map<String, dynamic>> fetchActivities() async {
    print('🚀 fetchActivities() DÉMARRÉ');
    final lat = _currentCenter.latitude;
    final lng = _currentCenter.longitude;

    final uri = buildFilteredUri(
      baseUrl: '10.0.2.2',
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
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                if (_activities.isNotEmpty)
                  MarkerClusterLayerWidget(
                    options: MarkerClusterLayerOptions(
                      maxClusterRadius: 45,
                      size: const Size(40, 40),
                      markers: _activities.map((item) {
                        return Marker(
                          width: 40,
                          height: 40,
                          point: LatLng(item['lat'], item['lng']),
                          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                        );
                      }).toList(),
                      builder: (context, markers) => Container(
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          markers.length.toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ActivityDetailPage(
                              icon: Icons.place, // ou autre selon l'activité
                              title: activity['name'] ?? '',
                              location: activity['address'] ?? '',
                              weather: weatherDescription,
                              temperature: activity['temperature'] ?? '–',
                              duration: activity['duration'] ?? '–',
                              distance: activity['distance'] ?? '–',
                              userLocation: LatLng(53.0793, 8.8017), // TODO: remplace par vraie position GPS
                              destinationLocation: LatLng(activity['lat'], activity['lng']),
                              openingHours: activity['openingHours'],
                              website: activity['website'],
                              contact: activity['contact'],
                              wikipedia: activity['wikipedia'],
                            ),
                          ),
                        );
                      },
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
                            decoration: const InputDecoration.collapsed(hintText: 'Entrez un lieu'),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () async {
                            final location = _locationController.text.trim();
                            final coords = await getCoordinatesFromLocation(location);
                            if (coords != null) {
                              setState(() {
                                _currentCenter = coords;
                                _mapController.move(coords, 12);
                                _futureData = _loadInitialData();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () async {
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
                tooltip: showMap ? 'Afficher la liste' : 'Afficher la carte',
                backgroundColor: Colors.blueAccent,
                onPressed: () => setState(() => showMap = !showMap),
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
                    weatherDescription.isNotEmpty ? weatherDescription : 'Chargement...',
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
}
