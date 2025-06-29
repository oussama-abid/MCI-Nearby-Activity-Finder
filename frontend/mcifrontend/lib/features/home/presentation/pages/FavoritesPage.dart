import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../../shared/supabase_client.dart';
import '../../../../shared/widgets/getIcon_for_type.dart';
import 'activity_detail_page.dart';
import 'map_page.dart' show userFavorites, filteredActivitiesGlobal;
import '../../../../utils/user_id_helper.dart';

class FavoritesPage extends StatefulWidget {
  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {

  String? userId;

  @override
  void initState() {
    super.initState();
    getOrCreateUserId().then((id) {
      setState(() {
        userId = id;
      });
    });
  }

  Future<void> toggleFavorite(String activityId, String userId) async {
    final response = await supabase
        .from('activities')
        .select('user_favorites')
        .eq('id', activityId)
        .single();

    final currentFavorites = List<String>.from(response.data['user_favorites'] ?? []);

    final isFavorite = currentFavorites.contains(userId);
    if (isFavorite) {
      currentFavorites.remove(userId);
    } else {
      currentFavorites.add(userId);
    }

    await supabase
        .from('activities')
        .update({'user_favorites': currentFavorites})
        .eq('id', activityId);

    // Tu peux mettre à jour userFavorites local si tu veux re-rendre la UI rapidement :
    setState(() {
      if (isFavorite) {
        userFavorites.remove(activityId);
      } else {
        userFavorites.add(activityId);
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    if (filteredActivitiesGlobal.isEmpty) {
      return Center(child: Text("Aucune activité disponible ou chargement en cours."));
    }
    final favoriteActivities = filteredActivitiesGlobal
        .where((activity) => userFavorites.contains(activity['id']))
        .toList();

    if (favoriteActivities.isEmpty) {
      return Center(child: Text("Aucune activité favorite pour le moment."));
    }

    return ListView.builder(
      padding: EdgeInsets.only(top: 16, bottom: 100),
      itemCount: favoriteActivities.length,
      itemBuilder: (context, index) {
        final activity = favoriteActivities[index];

        final lat = activity['lat'] ?? activity['latitude'];
        final lng = activity['lng'] ?? activity['lon'] ?? activity['longitude'];

        final destination = (lat != null && lng != null)
            ? LatLng((lat as num).toDouble(), (lng as num).toDouble())
            : LatLng(0, 0);

        if (lat == null || lng == null) {
          print("Activité sans coordonnées valides : \${activity['name']}");
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ActivityDetailPage(
                  icon: getIconForType(activity['type'] ?? 'default'),
                  title: activity['name'] ?? 'Nom inconnu',
                  location: activity['location'] ?? 'Emplacement inconnu',
                  weather: activity['weather'] ?? 'clear',
                  temperature: (activity['weather'] ?? 'clear').toString().split(',')[0],
                  duration: activity['duration'] ?? '1h',
                  distance: activity['distance'] ?? '–',
                  userLocation: LatLng(53.0793, 8.8017),
                  destinationLocation: destination,
                ),
              ),
            );
          },
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                          if (userId != null) {
                            toggleFavorite(activity['id'], userId!);
                          }
                        },
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(
                            userFavorites.contains(activity['id'])
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity['name'] ?? '',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 18, color: Colors.blueAccent),
                          SizedBox(width: 6),
                          Text(activity['duration'] ?? '–'),
                          Spacer(),
                          Icon(Icons.place, size: 18, color: Colors.redAccent),
                          SizedBox(width: 6),
                          Text(activity['distance'] ?? '–'),
                        ],
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
  }
}
