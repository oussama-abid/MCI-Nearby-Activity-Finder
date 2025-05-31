import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mcifrontend/shared/widgets/tooltip_marker.dart';
import 'package:mcifrontend/features/home/presentation/pages/activity_detail_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../../utils/weather_utils.dart';
import '../../domain/activity_filter.dart';
import '../widgets/filter_sheet.dart';

double offsetLat(double lat, double offset) => lat + offset;
double offsetLng(double lon, double offset) => lon + offset;

void main() => runApp(DayventureApp());

class DayventureApp extends StatelessWidget {
  const DayventureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dayventure',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MainNavigation(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = <Widget>[
    MapPage(),
    Center(child: Text('Liste der Ausflüge')),
    Center(child: Text('Filteroptionen')),
    Center(child: Text('Einstellungen')),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Karte'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Liste'),
          BottomNavigationBarItem(icon: Icon(Icons.filter_alt), label: 'Filter'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Einstellungen'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

List<String> userFavorites = [];
List<String> visitedActivityIds = [];

class MapPage extends StatefulWidget {

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final LatLng userLocation = LatLng(53.0793, 8.8017);
  ActivityFilter currentFilter = ActivityFilter();
 // Bremen
  final String currentWeather = 'sunny';

  LatLng getCenter(List<Map<String, dynamic>> activities, LatLng fallback) {
    if (activities.isEmpty) return fallback;

    final avgLat = activities.map((a) => a['lat'] as num).reduce((a, b) => a + b) / activities.length;
    final avgLon = activities.map((a) => a['lon'] as num).reduce((a, b) => a + b) / activities.length;

    return LatLng(avgLat.toDouble(), avgLon.toDouble());
  }

  IconData getWeatherIcon(String weather) {
    switch (weather.toLowerCase()) {
      case 'clear':
      case 'sunny':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
      case 'drizzle':
        return Icons.umbrella;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'snow':
        return Icons.ac_unit;
      case 'mist':
      case 'fog':
        return Icons.blur_on;
      default:
        return Icons.help_outline;
    }
  }

  IconData getIconForType(String type) {
    switch (type) {
      case 'bike':
        return Icons.directions_bike;
      case 'hiking':
        return Icons.hiking;
      case 'beach':
        return Icons.beach_access;
      case 'museum':
        return Icons.museum;
      case 'park':
        return Icons.park;
      case 'art':
        return Icons.brush;
      default:
        return Icons.place;
    }
  }

  Future<Map<String, dynamic>> fetchActivities({ActivityFilter? filter}) async {
    final lat = userLocation.latitude;
    final lon = userLocation.longitude;

    final uri = Uri.http('172.31.240.1:3001', '/api/activities', {
      'lat': '$lat',
      'lon': '$lon',
      if (filter != null) ...{
        if (filter.accessibleOnly) 'accessible': 'true',
        if (filter.favoritesOnly) 'favoritesOnly': 'true',
        if (filter.radiusKm < 100) 'radius': filter.radiusKm.toString(),
        if (filter.interests.isNotEmpty) 'interests': filter.interests.join(','),
      }
    });

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'weather': data['weather'],
        'weatherDescription': data['weatherDescription'],
        'activities': List<Map<String, dynamic>>.from(data['activities']),
      };
    } else {
      throw Exception('Failed to load activities');
    }
  }

  @override
  Widget build(BuildContext context) {

    return FutureBuilder(
      future: fetchActivities(filter: currentFilter),
      builder: (context, asyncSnapshot) {
        if (asyncSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (asyncSnapshot.hasError) {
          return Center(child: Text('Error: ${asyncSnapshot.error}'));
        }

        final weather = asyncSnapshot.data!['weather'] as String;

        print("-----------------------");
        print(asyncSnapshot.data?['weatherDescription']);
        final weatherDescription = asyncSnapshot.data?['weatherDescription'] ?? 'klar';

        final activities = asyncSnapshot.data!['activities'] as List<Map<String, dynamic>>;

        final Distance distanceCalc = Distance();

        final filteredActivities = activities.where((activity) {
          // Check type (interest)
          if (currentFilter.interests.isNotEmpty && !currentFilter.interests.contains(activity['type'])) {
            return false;
          }

          // Accessible only
          if (currentFilter.accessibleOnly && activity['accessible'] != true) {
            return false;
          }

          // Favorites only
          if (currentFilter.favoritesOnly && !(userFavorites.contains(activity['id']))) {
            return false;
          }

          // Show only within radius
          if (currentFilter.radiusKm < 100) {
            final dist = distanceCalc.as(
                LengthUnit.Kilometer,
                userLocation,
                LatLng(activity['lat'], activity['lon'])
            );
            if (dist > currentFilter.radiusKm) return false;
          }

          // Show visited?
          if (!currentFilter.showVisited && visitedActivityIds.contains(activity['id'])) {
            return false;
          }

          return true;
        }).toList();

        final recommendedActivities = activities.where((activity) {
          return activity != null &&
              activity['lat'] != null &&
              activity['lon'] != null &&
              activity['name'] != null &&
              activity['type'] != null;
        }).toList();

        print('Recommended activities (${recommendedActivities.length}): $recommendedActivities');

        return Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                center: getCenter(filteredActivities, userLocation),
                zoom: 12.7,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: userLocation,
                      width: 60,
                      height: 60,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_pin, size: 40, color: Colors.blue),
                          SizedBox(height: 2),
                          Text("ICI", style: TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                    ...filteredActivities.map((activity) => Marker(
                      point: LatLng((activity['lat'] as num).toDouble(), (activity['lon'] as num).toDouble()),
                      width: 160,
                      height: 60,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ActivityDetailPage(
                                icon: getIconForType(activity['type'] ?? 'default'),
                                title: activity['name'] ?? 'Nom inconnu',
                                location: activity['location'] ?? 'Emplacement inconnu',
                                weather: activity['weather'] ?? 'clear',
                                temperature: (activity['weather'] ?? 'clear').split(',')[0],
                                duration: activity['duration'] ?? '1h',
                                distance: '4,2 km entfernt',
                                userLocation: userLocation,
                                destinationLocation: LatLng(
                                  (activity['lat'] as num).toDouble(),
                                  (activity['lon'] as num).toDouble(),
                                ),
                              ),
                            ),
                          );
                        },
                        child: TooltipMarker(
                          icon: getIconForType(activity['type']),
                          label: activity['name'],
                          color: Colors.green[700]!,
                        ),
                      ),
                    )),
                  ],
                ),
              ],
            ),

            // Boutons flottants (Filter + Start)
            Positioned(
              top: 50,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                        });
                      }
                    },
                    icon: Icon(Icons.filter_alt),
                    label: Text("Filter"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 3,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: implémenter la recherche ou les suggestions
                    },
                    child: Text("Start"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      elevation: 3,
                    ),
                  ),
                ],
              ),
            ),

            // Badge météo en bas à gauche
            Positioned(
              bottom: 20,
              left: 16,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(getWeatherIcon(weather), color: Colors.orange, size: 24),
                    SizedBox(width: 8),
                    Text(
                      '${translateWeather(weatherDescription, locale: 'de')} – Bremen',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          ],
        );
      }
    );

  }
}
