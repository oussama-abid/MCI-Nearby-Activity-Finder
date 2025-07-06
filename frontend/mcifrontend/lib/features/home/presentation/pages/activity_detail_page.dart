import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

class ActivityDetailPage extends StatefulWidget {
  final IconData icon;
  final String title;
  final String location;
  final String weather;
  final String temperature;
  final LatLng userLocation;
  final LatLng destinationLocation;
  final String? openingHours;
  final String? website;
  final String? contact;
  final String? wikipedia;
  final List<String>? interests;
  final int? popularity;

  const ActivityDetailPage({
    required this.icon,
    required this.title,
    required this.location,
    required this.weather,
    required this.temperature,
    required this.userLocation,
    required this.destinationLocation,
    this.openingHours,
    this.website,
    this.contact,
    this.wikipedia,
    this.interests,
    this.popularity,
    super.key,
  });

  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage>
    with TickerProviderStateMixin {
  List<LatLng> routePoints = [];
  bool isLoading = true;
  bool isNavigationLoading = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Route information from API
  String calculatedDuration = 'Calcul...';
  String calculatedDistance = 'Calcul...';
  double? routeDistanceMeters;
  double? routeDurationSeconds;

  final String apiKey = 'REMOVED';

  @override
  void initState() {
    super.initState();
    _initAnimations();
    fetchRoute(widget.userLocation, widget.destinationLocation);
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> fetchRoute(LatLng start, LatLng end) async {
    final url = Uri.parse(
        'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey&start=${start.longitude},${start.latitude}&end=${end.longitude},${end.latitude}');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coords = data['features'][0]['geometry']['coordinates'] as List;
        
        final properties = data['features'][0]['properties'];
        final summary = properties['summary'];
        
        routeDistanceMeters = (summary['distance'] as num).toDouble();
        routeDurationSeconds = (summary['duration'] as num).toDouble();

        setState(() {
          routePoints = coords.map((c) => LatLng(c[1], c[0])).toList();
          calculatedDistance = _formatDistance(routeDistanceMeters!);
          calculatedDuration = _formatDuration(routeDurationSeconds!);
          isLoading = false;
        });
      } else {
        debugPrint('Failed to fetch route: ${response.body}');
        setState(() {
          _calculateStraightLineDistance();
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Route fetch error: $e');
      setState(() {
        _calculateStraightLineDistance();
        isLoading = false;
      });
    }
  }

  void _calculateStraightLineDistance() {
    double distanceInMeters = Geolocator.distanceBetween(
      widget.userLocation.latitude,
      widget.userLocation.longitude,
      widget.destinationLocation.latitude,
      widget.destinationLocation.longitude,
    );
    
    double drivingSpeedKmh = 30.0;
    double drivingSpeedMs = drivingSpeedKmh * 1000 / 3600;
    double estimatedDurationSeconds = distanceInMeters / drivingSpeedMs;
    
    distanceInMeters *= 1.4;
    estimatedDurationSeconds *= 1.4;
    
    setState(() {
      calculatedDistance = _formatDistance(distanceInMeters);
      calculatedDuration = _formatDuration(estimatedDurationSeconds);
    });
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      double km = meters / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
  }

  String _formatDuration(double seconds) {
    int minutes = (seconds / 60).round();
    if (minutes < 60) {
      return '$minutes min';
    } else {
      int hours = minutes ~/ 60;
      int remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${remainingMinutes}min';
      }
    }
  }

  Future<void> _startNavigation() async {
    setState(() {
      isNavigationLoading = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationError('Les services de localisation sont désactivés.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationError('L\'autorisation de localisation est refusée.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationError('L\'autorisation de localisation est refusée définitivement.');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final url = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&origin=${position.latitude},${position.longitude}&destination=${widget.destinationLocation.latitude},${widget.destinationLocation.longitude}&travelmode=driving');
      
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showLocationError('Impossible d\'ouvrir Google Maps.');
      }
    } catch (e) {
      debugPrint('Navigation error: $e');
      _showLocationError('Erreur lors de l\'obtention de votre position: $e');
    } finally {
      setState(() {
        isNavigationLoading = false;
      });
    }
  }

  void _showLocationError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.favorite_border, color: Colors.white),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Enhanced Map Section
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(
                        (widget.userLocation.latitude + widget.destinationLocation.latitude) / 2,
                        (widget.userLocation.longitude + widget.destinationLocation.longitude) / 2,
                      ),
                      initialZoom: 14.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: widget.userLocation,
                            width: 50,
                            height: 50,
                            child: TweenAnimationBuilder(
                              tween: Tween<double>(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 1200),
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.my_location,
                                      color: Colors.blue,
                                      size: 30,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Marker(
                            point: widget.destinationLocation,
                            width: 50,
                            height: 50,
                            child: TweenAnimationBuilder(
                              tween: Tween<double>(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 1500),
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.9),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.red.withOpacity(0.4),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      widget.icon,
                                      color: Colors.white,
                                      size: 25,
                                    ),
                                  ),
                                );
                              },
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
                              color: Colors.blue,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                // Floating weather card
                Positioned(
                  top: 100,
                  right: 16,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wb_sunny, color: Colors.orange, size: 24),
                          const SizedBox(height: 4),
                          Text(
                            widget.temperature,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            widget.weather,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Enhanced Info Section
          Expanded(
            flex: 2,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Title
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Location
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.location,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Quick stats - now using calculated values
                      _buildEnhancedStats(),
                      const SizedBox(height: 24),
                      // Detailed info
                      _buildInfoSection(),
                      const SizedBox(height: 24),
                      // Action buttons
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    final infos = [
      {
        'icon': Icons.access_time,
        'label': 'Horaires',
        'value': widget.openingHours?.isNotEmpty == true ? widget.openingHours! : 'Non disponible',
        'isLink': false,
      },
      {
        'icon': Icons.language,
        'label': 'Site web',
        'value': widget.website?.isNotEmpty == true ? widget.website! : 'Non disponible',
        'isLink': widget.website?.isNotEmpty == true,
      },
      {
        'icon': Icons.phone,
        'label': 'Contact',
        'value': widget.contact?.isNotEmpty == true ? widget.contact! : 'Non disponible',
        'isLink': false,
      },
      {
        'icon': Icons.menu_book,
        'label': 'Wikipedia',
        'value': widget.wikipedia?.isNotEmpty == true ? widget.wikipedia! : 'Non disponible',
        'isLink': widget.wikipedia?.isNotEmpty == true,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Popularity Section
        if (widget.popularity != null) ...[
          const Text(
            'Popularité',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          _buildPopularityIndicator(widget.popularity!),
          const SizedBox(height: 16),
        ],
        
        // Interests/Categories Section
        if (widget.interests?.isNotEmpty == true) ...[
          const Text(
            'Catégories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          _buildInterestTags(widget.interests!),
          const SizedBox(height: 16),
        ],
        
        // Regular Information Section
        const Text(
          'Informations',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...infos.map((info) => _buildInfoTile(
          info['icon'] as IconData,
          info['label'] as String,
          info['value'] as String,
          isLink: info['isLink'] as bool,
        )).toList(),
      ],
    );
  }

  Widget _buildPopularityIndicator(int popularity) {
    double rating = (popularity / 10.0) * 5.0; // Convert 1-10 scale to 1-5 scale
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ), // This was the missing closing parenthesis
      child: Row(
        children: [
          // Star rating
          Row(
            children: List.generate(5, (index) {
              if (index < rating.floor()) {
                return const Icon(Icons.star, color: Colors.amber, size: 20);
              } else if (index == rating.floor() && rating % 1 >= 0.5) {
                return const Icon(Icons.star_half, color: Colors.amber, size: 20);
              } else {
                return const Icon(Icons.star_border, color: Colors.amber, size: 20);
              }
            }),
          ),
          const SizedBox(width: 8),
          // Rating text
          Text(
            '${rating.toStringAsFixed(1)}/5',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 8),
          // Popularity text
          Text(
            '($popularity/10)',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestTags(List<String> interests) {
    // Color palette for different categories
    final Map<String, Color> categoryColors = {
      'historic': Colors.brown,
      'monuments': Colors.grey,
      'memorials': Colors.purple,
      'burial_places': Colors.indigo,
      'interesting_places': Colors.green,
      'nature': Colors.lightGreen,
      'cultural': Colors.pink,
      'museums': Colors.teal,
      'entertainment': Colors.orange,
      'sports': Colors.red,
      'food': Colors.deepOrange,
      'shopping': Colors.blue,
      'architecture': Colors.blueGrey,
      'art': Colors.deepPurple,
      'religion': Colors.amber,
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: interests.map((interest) {
        // Clean up the interest name
        String cleanInterest = interest
            .replaceAll('_', ' ')
            .replaceAll('other ', '')
            .trim();
        
        // Get color for category
        Color tagColor = categoryColors[interest.toLowerCase()] ?? Colors.blue;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: tagColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tagColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getInterestIcon(interest),
                size: 16,
                color: tagColor,
              ),
              const SizedBox(width: 6),
              Text(
                cleanInterest.toLowerCase().split(' ').map((word) => 
                  word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : word
                ).join(' '),
                style: TextStyle(
                  color: tagColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  IconData _getInterestIcon(String interest) {
    switch (interest.toLowerCase()) {
      case 'historic':
      case 'monuments':
        return Icons.account_balance;
      case 'memorials':
      case 'burial_places':
        return Icons.local_florist;
      case 'interesting_places':
        return Icons.place;
      case 'nature':
        return Icons.nature;
      case 'cultural':
      case 'museums':
        return Icons.museum;
      case 'entertainment':
        return Icons.theater_comedy;
      case 'sports':
        return Icons.sports;
      case 'food':
        return Icons.restaurant;
      case 'shopping':
        return Icons.shopping_bag;
      case 'architecture':
        return Icons.architecture;
      case 'art':
        return Icons.palette;
      case 'religion':
        return Icons.church;
      default:
        return Icons.tag;
    }
  }

  Widget _buildInfoTile(IconData icon, String label, String value, {bool isLink = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ), // Added this closing parenthesis
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ), // Properly closed this decoration too
            child: Icon(icon, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                isLink && value != 'Non disponible'
                    ? GestureDetector(
                        onTap: () async {
                          final url = Uri.parse(value.startsWith('http') ? value : 'https://$value');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          }
                        },
                        child: Text(
                          value,
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : Text(
                        value,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildEnhancedStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatCard(Icons.schedule, 'Durée', calculatedDuration),
        _buildStatCard(Icons.directions_car, 'Distance', calculatedDistance),
        if (widget.popularity != null)
          _buildStatCard(Icons.star, 'Popularité', '${widget.popularity}/10')
        else
          _buildStatCard(Icons.thermostat, 'Temp', widget.temperature),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Primary action button
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.blue, Colors.blueAccent],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: isNavigationLoading ? null : _startNavigation,
            icon: isNavigationLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.directions_walk, color: Colors.white),
            label: Text(
              isNavigationLoading ? 'Localisation...' : 'Démarrer la navigation',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Secondary action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // Share functionality
                },
                icon: const Icon(Icons.share, color: Colors.grey),
                label: const Text(
                  'Partager',
                  style: TextStyle(color: Colors.grey),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // Call functionality
                },
                icon: const Icon(Icons.call, color: Colors.grey),
                label: const Text(
                  'Appeler',
                  style: TextStyle(color: Colors.grey),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}