import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mcifrontend/shared/widgets/tooltip_marker.dart';
import 'package:mcifrontend/features/home/presentation/pages/activity_detail_page.dart';

double offsetLat(double lat, double offset) => lat + offset;
double offsetLng(double lng, double offset) => lng + offset;

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

class MapPage extends StatelessWidget {
  final LatLng userLocation = LatLng(53.0793, 8.8017); // Bremen

  @override
  Widget build(BuildContext context) {

    final List<Map<String, dynamic>> activities = [
      {
        'name': 'Radtour am See',
        'location': LatLng(offsetLat(userLocation.latitude, 0.012), offsetLng(userLocation.longitude, 0.0080)),
        'icon': Icons.directions_bike,
        'duration': '1h 30min',
        'weather': '23°C, sonnig',
      },
      {
        'name': 'Wanderung am Berg',
        'location': LatLng(offsetLat(userLocation.latitude, -0.0030), offsetLng(userLocation.longitude, 0.0040)),
        'icon': Icons.hiking,
        'duration': '2h',
        'weather': '21°C, leicht bewölkt',
      },
      {
        'name': 'Strandbesuch',
        'location': LatLng(offsetLat(userLocation.latitude, -0.01), offsetLng(userLocation.longitude, -0.009)),
        'icon': Icons.beach_access,
        'duration': '1h',
        'weather': '25°C, sonnig',
      },
    ];

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            center: userLocation,
            zoom: 14.0,
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
                      Icon(Icons.my_location, size: 28, color: Colors.blue),
                      SizedBox(height: 2),
                      Text("ICI", style: TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
                ...activities.map((activity) => Marker(
                  point: activity['location'],
                  width: 160,
                  height: 60,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ActivityDetailPage(
                            icon: activity['icon'],
                            title: activity['name'],
                            location: 'Naturpark Bremen', // ou selon l'activité
                            weather: activity['weather'],
                            temperature: activity['weather'].split(',')[0], // ex : Sonnig
                            duration: activity['duration'],
                            distance: '4,2 km entfernt', // fictif pour l’instant
                            userLocation: userLocation,
                            destinationLocation: activity['location'],
                          ),
                        ),
                      );
                    },
                    child: TooltipMarker(
                      icon: activity['icon'],
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
                onPressed: () {
                  // TODO: implémenter le filtre
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
                Icon(Icons.wb_sunny, color: Colors.orange, size: 24),
                SizedBox(width: 8),
                Text(
                  "Sonnig, 19°C",
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
}
