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
    'Alle': [],
    'Natur': ['natural'],
    'Museen': ['museum'],
    'Spiele': ['playground'],
    'Kultur': ['cultural'],
    'Historisch': ['historic'],
    'Sport': ['sport'],
    'Unterhaltung': ['entertainment'],
  };

  final environmentOptions = {
    'Alle': 'any',
    'Stadt': 'urban',
    'Land': 'rural',
    'See': 'water',
    'Natur': 'nature',
  };

  final durationOptions = {
    'Alle': 'any',
    'Kurz (< 1h)': 'short',
    'Mittel (1-3h)': 'medium',
    'Lang (> 3h)': 'long',
  };

  final priceRangeOptions = {
    'Alle': 'any',
    'Kostenlos': 'free',
    'Günstig': 'low',
    'Mittel': 'medium',
    'Teuer': 'high',
  };

  @override
  void initState() {
    super.initState();
    // Create a copy of the initial filter to avoid modifying the original
    filter = ActivityFilter.from(widget.initialFilter);
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

  void updateFilter(Function(ActivityFilter) updateFunction) {
    setState(() {
      updateFunction(filter);
    });
  }

  String _getInterestLabel() {
    if (filter.interests.isEmpty) return 'Alle';
    for (var entry in interestOptions.entries) {
      if (entry.value.isNotEmpty && 
          entry.value.length == filter.interests.length &&
          entry.value.every((interest) => filter.interests.contains(interest))) {
        return entry.key;
      }
    }
    return 'Alle';
  }

  String _getEnvironmentLabel() {
    for (var entry in environmentOptions.entries) {
      if (entry.value == filter.environment) {
        return entry.key;
      }
    }
    return 'Alle';
  }

  String _getDurationLabel() {
    for (var entry in durationOptions.entries) {
      if (entry.value == filter.duration) {
        return entry.key;
      }
    }
    return 'Alle';
  }

  String _getPriceRangeLabel() {
    for (var entry in priceRangeOptions.entries) {
      if (entry.value == filter.priceRange) {
        return entry.key;
      }
    }
    return 'Alle';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Filteroptionen", 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                ),
                if (filter.hasActiveFilters)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        filter.reset();
                        peopleController.text = filter.peopleCount.toString();
                        childrenController.text = filter.childrenCount.toString();
                        ageController.text = filter.childAge.toString();
                      });
                    },
                    child: const Text("Zurücksetzen"),
                  ),
              ],
            ),
          ),
          
          // Filter content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Group Section
                  _buildSectionHeader('Gruppe'),
                  _buildNumberField('Anzahl Personen', peopleController),
                  const SizedBox(height: 8),
                  _buildNumberField('Anzahl der Kinder', childrenController),
                  const SizedBox(height: 8),
                  if (filter.childrenCount > 0)
                    _buildNumberField('Alter von Kind 1', ageController),
                  
                  const SizedBox(height: 20),
                  
                  // Location Section
                  _buildSectionHeader('Standort'),
                  _buildSlider('Radius (km)', filter.radiusKm, 5, 100, (v) {
                    updateFilter((f) => f.radiusKm = v);
                  }),
                  
                  const SizedBox(height: 20),
                  
                  // Activity Section
                  _buildSectionHeader('Aktivität'),
                  _buildDropdown(
                    'Interessen',
                    _getInterestLabel(),
                    interestOptions.keys.toList(),
                    (selectedLabel) {
                      final interests = interestOptions[selectedLabel]!;
                      updateFilter((f) => f.interests = List.from(interests));
                    }
                  ),
                  const SizedBox(height: 8),
                  _buildDropdown(
                    'Umgebung',
                    _getEnvironmentLabel(),
                    environmentOptions.keys.toList(),
                    (selectedLabel) {
                      final environment = environmentOptions[selectedLabel]!;
                      updateFilter((f) => f.environment = environment);
                    }
                  ),
                  const SizedBox(height: 8),
                  _buildDropdown(
                    'Dauer',
                    _getDurationLabel(),
                    durationOptions.keys.toList(),
                    (selectedLabel) {
                      final duration = durationOptions[selectedLabel]!;
                      updateFilter((f) => f.duration = duration);
                    }
                  ),
                  const SizedBox(height: 8),
                  _buildDropdown(
                    'Preis',
                    _getPriceRangeLabel(),
                    priceRangeOptions.keys.toList(),
                    (selectedLabel) {
                      final priceRange = priceRangeOptions[selectedLabel]!;
                      updateFilter((f) => f.priceRange = priceRange);
                    }
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Quality Section
                  _buildSectionHeader('Qualität'),
                  _buildRatingStars('Mindestbewertung', filter.rating.toInt(), (v) {
                    updateFilter((f) => f.rating = v.toDouble());
                  }),
                  const SizedBox(height: 8),
                  _buildRatingStars('Popularität', filter.popularity, (v) {
                    updateFilter((f) => f.popularity = v);
                  }),
                  
                  const SizedBox(height: 20),
                  
                  // Preferences Section
                  _buildSectionHeader('Einstellungen'),
                  _buildSwitch('Auf das Wetter achten', filter.considerWeather, (v) {
                    updateFilter((f) => f.considerWeather = v);
                  }),
                  _buildSwitch('Barrierefrei', filter.accessibleOnly, (v) {
                    updateFilter((f) => f.accessibleOnly = v);
                  }),
                  _buildSwitch('Nur Favoriten anzeigen', filter.favoritesOnly, (v) {
                    updateFilter((f) => f.favoritesOnly = v);
                  }),
                  _buildSwitch('Bereits besuchte Orte anzeigen', filter.showVisited, (v) {
                    updateFilter((f) => f.showVisited = v);
                  }),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Abbrechen"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Update filter from text controllers
                      filter.peopleCount = int.tryParse(peopleController.text) ?? 1;
                      filter.childrenCount = int.tryParse(childrenController.text) ?? 0;
                      filter.childAge = int.tryParse(ageController.text) ?? 0;

                      Navigator.pop(context, filter);
                    },
                    child: const Text("Anwenden"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.blueAccent,
        ),
      ),
    );
  }

  Widget _buildNumberField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        // Update filter immediately when children count changes
        if (label.contains('Kinder')) {
          final count = int.tryParse(value) ?? 0;
          updateFilter((f) => f.childrenCount = count);
        }
      },
    );
  }

  Widget _buildDropdown(String label, String value, List<String> options, Function(String) onChanged) {
    return DropdownButtonFormField<String>(
      value: options.contains(value) ? value : options.first,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label),
          ),
          ...List.generate(5, (i) {
            return IconButton(
              onPressed: () => onChanged(rating == i + 1 ? 0 : i + 1), // Allow deselection
              icon: Icon(
                Icons.star,
                color: i < rating ? Colors.amber : Colors.grey,
                size: 20,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSwitch(String label, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }
}