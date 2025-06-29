import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../domain/activity_filter.dart';

class FilterSheet extends StatefulWidget {
  final ActivityFilter initialFilter;

  const FilterSheet({super.key, required this.initialFilter});

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late ActivityFilter filter;
  late TextEditingController peopleController;
  late TextEditingController childrenController;
  late TextEditingController ageController;
  final interestOptions = {
    'Natur': 'natural',
    'Museen': 'museum',
    'Spiele': 'playground',
    'Kultur': 'cultural',
    'Historisch': 'historic',
  };

  @override
  void initState() {
    super.initState();
    filter = widget.initialFilter;
    peopleController = TextEditingController(text: filter.peopleCount.toString());
    childrenController = TextEditingController(text: filter.childrenCount.toString());
    ageController = TextEditingController(text: filter.childAge.toString());
  }

  @override
  void dispose() {
    peopleController.dispose();
    childrenController.dispose();
    ageController.dispose();
    super.dispose();
  }

  void updateFilter(ActivityFilter updated) {
    setState(() {
      filter = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Filteroptionen", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          _buildNumberField('Anzahl Personen', peopleController),
          _buildNumberField('Anzahl der Kinder', childrenController),
          _buildNumberField('Alter von Kind 1', ageController),

          _buildDropdown(
              'Interessen',
              interestOptions.entries
                  .firstWhere(
                    (e) => e.value == filter.interests.firstOrNull,
                orElse: () => const MapEntry('Unbekannt', ''),
              )
                  .key,
              interestOptions.keys.toList(),
                  (selectedLabel) {
                final backendTag = interestOptions[selectedLabel]!;
                updateFilter(filter..interests = [backendTag]);
              }
          ),

          _buildSlider('Radius (km)', filter.radiusKm, 5, 100, (v) {
            updateFilter(filter..radiusKm = v);
          }),

          _buildRatingStars('Popularität', filter.popularity, (v) {
            updateFilter(filter..popularity = v);
          }),

          _buildSwitch('Auf das Wetter achten', filter.considerWeather, (v) {
            updateFilter(filter..considerWeather = v);
          }),
          _buildSwitch('Barrierefrei', filter.accessibleOnly, (v) {
            updateFilter(filter..accessibleOnly = v);
          }),
          _buildSwitch('Nur Favoriten anzeigen', filter.favoritesOnly, (v) {
            updateFilter(filter..favoritesOnly = v);
          }),
          _buildSwitch('Bereits besuchte Orte anzeigen', filter.showVisited, (v) {
            updateFilter(filter..showVisited = v);
          }),

          _buildDropdown('Umgebung', filter.environment, ['Stadt', 'Land', 'See'], (value) {
            updateFilter(filter..environment = value);
          }),

          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              filter.peopleCount = int.tryParse(peopleController.text) ?? 1;
              filter.childrenCount = int.tryParse(childrenController.text) ?? 0;
              filter.childAge = int.tryParse(ageController.text) ?? 0;

              Navigator.pop(context, filter);
            },
            child: const Text("Anwenden"),
          )
        ],
      ),
    );
  }
}

Widget _buildNumberField(String label, TextEditingController controller) {
  return TextFormField(
    controller: controller,
    decoration: InputDecoration(labelText: label),
    keyboardType: TextInputType.number,
  );
}

Widget _buildDropdown(String label, dynamic value, List<String> options, Function(String) onChanged) {
  return DropdownButtonFormField<String>(
    value: (value is String && options.contains(value)) ? value : null,
    decoration: InputDecoration(labelText: label),
    items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
    onChanged: (v) {
      if (v != null) onChanged(v);
    },
  );
}

Widget _buildSlider(String label, double value, double min, double max, Function(double) onChanged) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('$label: ${value.toStringAsFixed(0)} km'),
      Slider(
        value: value,
        min: min,
        max: max,
        divisions: ((max - min) / 5).round(),
        onChanged: onChanged,
      ),
    ],
  );
}

Widget _buildRatingStars(String label, int rating, Function(int) onChanged) {
  return Row(
    children: [
      Text(label),
      const SizedBox(width: 8),
      ...List.generate(5, (i) {
        return IconButton(
          onPressed: () => onChanged(i + 1),
          icon: Icon(
            Icons.star,
            color: i < rating ? Colors.amber : Colors.grey,
          ),
        );
      }),
    ],
  );
}

Widget _buildSwitch(String label, bool value, Function(bool) onChanged) {
  return SwitchListTile(
    title: Text(label),
    value: value,
    onChanged: onChanged,
  );
}
