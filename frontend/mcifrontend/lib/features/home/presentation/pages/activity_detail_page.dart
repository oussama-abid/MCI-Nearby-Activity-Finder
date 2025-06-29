import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class ActivityDetailPage extends StatefulWidget {
  final IconData icon;
  final String title;
  final String location;
  final String weather;
  final String temperature;
  final String duration;
  final String distance;
  final LatLng userLocation;
  final LatLng destinationLocation;
  final String? openingHours;
  final String? website;
  final String? contact;
  final String? wikipedia;

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
    this.openingHours,
    this.website,
    this.contact,
    this.wikipedia,
    super.key,
  });

  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  List<LatLng> routePoints = [];

  final String apiKey = 'REMOVED'; // 🔑 Remplace par ta clé ORS

  @override
  void initState() {
    super.initState();
    fetchRoute(widget.userLocation, widget.destinationLocation);
  }

  Future<void> fetchRoute(LatLng start, LatLng end) async {
    final url = Uri.parse(
        'https://api.openrouteservice.org/v2/directions/foot-walking?api_key=$apiKey&start=${start.longitude},${start.latitude}&end=${end.longitude},${end.latitude}');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final coords = data['features'][0]['geometry']['coordinates'] as List;

      setState(() {
        routePoints = coords.map((c) => LatLng(c[1], c[0])).toList();
      });
    } else {
      debugPrint('Failed to fetch route: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayOpeningHours = (widget.openingHours?.isNotEmpty ?? false) ? widget.openingHours! : "None";
    final displayWebsite = (widget.website?.isNotEmpty ?? false) ? widget.website! : "None";
    final displayContact = (widget.contact?.isNotEmpty ?? false) ? widget.contact! : "None";
    final displayWikipedia = (widget.wikipedia?.isNotEmpty ?? false) ? widget.wikipedia! : "None";

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                center: LatLng(
                  (widget.userLocation.latitude + widget.destinationLocation.latitude) / 2,
                  (widget.userLocation.longitude + widget.destinationLocation.longitude) / 2,
                ),
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
                      point: widget.userLocation,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                    ),
                    Marker(
                      point: widget.destinationLocation,
                      width: 40,
                      height: 40,
                      child: CircleAvatar(
                        backgroundColor: Colors.red,
                        child: Icon(widget.icon, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                if (routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routePoints,
                        strokeWidth: 4,
                        color: Colors.green,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Adresse : ${widget.location}", style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Météo : ${widget.weather}"),
                    Text("Temp : ${widget.temperature}"),
                    Text("Durée : ${widget.duration}"),
                  ],
                ),
                const SizedBox(height: 8),
                infoRow(Icons.access_time, displayOpeningHours),
                infoRow(Icons.language, displayWebsite, isLink: displayWebsite != "None"),
                infoRow(Icons.phone, displayContact),
                infoRow(Icons.menu_book, displayWikipedia, isLink: displayWikipedia != "None"),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    final url = Uri.parse(
                        'https://www.google.com/maps/dir/?api=1&origin=${widget.userLocation.latitude},${widget.userLocation.longitude}&destination=${widget.destinationLocation.latitude},${widget.destinationLocation.longitude}&travelmode=walking');
                    launchUrl(url, mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.directions_walk),
                  label: const Text("Afficher dans Google Maps"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget infoRow(IconData icon, String value, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Expanded(
            child: isLink && value != "None"
                ? GestureDetector(
              onTap: () async {
                final url = Uri.parse(value.startsWith('http') ? value : 'https://$value');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
              child: Text(
                value,
                style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                overflow: TextOverflow.ellipsis,
              ),
            )
                : Text(
              value,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
