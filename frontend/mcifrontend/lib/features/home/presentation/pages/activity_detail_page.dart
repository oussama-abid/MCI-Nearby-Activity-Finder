import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mcifrontend/utils/weather_utils.dart';

class ActivityDetailPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String location;
  final String weather;
  final String temperature;
  final String duration;
  final String distance;
  final LatLng userLocation;
  final LatLng destinationLocation;

  const ActivityDetailPage({
    required this.icon,
    required this.title,
    required this.location,
    required this.weather,
    required this.temperature,
    required this.duration,
    required this.distance,
    required this.userLocation,
    required this.destinationLocation,
    super.key,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      center: LatLng(
                        (userLocation.latitude + destinationLocation.latitude) / 2,
                        (userLocation.longitude + destinationLocation.longitude) / 2,
                      ),
                      zoom: 13.0,
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
                            width: 40,
                            height: 40,
                            child: Icon(Icons.my_location, color: Colors.blue, size: 30),
                          ),
                          Marker(
                            point: destinationLocation,
                            width: 40,
                            height: 40,
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.blue,
                                child: Icon(icon, color: Colors.white, size: 20),
                              ),
                          ),
                        ],
                      ),
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [userLocation, destinationLocation],
                            strokeWidth: 3,
                            color: Colors.black87,
                          ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Hero(
                      tag: 'icon-$title',
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.black),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Ort Tracking", style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: Colors.blue,
                                child: Icon(icon, color: Colors.white),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    Text(location),
                                  ],
                                ),
                              ),
                              Text(distance),
                            ],
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text(translateWeather(weather, locale: 'de')),
                              Text(temperature),
                              Text(duration),
                            ],
                          ),
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {},
                                  icon: Icon(Icons.directions, color: Colors.white,),
                                  label: Text("Route anzeigen", style: TextStyle(color: Colors.white),),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              IconButton(
                                onPressed: () {},
                                icon: Icon(Icons.favorite_border),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
