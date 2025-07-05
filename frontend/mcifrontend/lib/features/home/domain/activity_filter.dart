class ActivityFilter {
  int peopleCount;
  int childrenCount;
  int childAge;
  List<String> interests;
  double radiusKm;
  int popularity;
  bool considerWeather;
  bool accessibleOnly;
  bool favoritesOnly;
  bool showVisited;
  String environment;
  
  // Additional filters to match backend
  String duration;
  String priceRange;
  double rating;

  ActivityFilter({
    this.peopleCount = 1,
    this.childrenCount = 0,
    this.childAge = 0,
    this.interests = const [],
    this.radiusKm = 25.0,
    this.popularity = 0,
    this.considerWeather = false,
    this.accessibleOnly = false,
    this.favoritesOnly = false,
    this.showVisited = true, // Changed default to true to match backend
    this.environment = 'any', // Changed from 'Stadt' to 'any'
    this.duration = 'any',
    this.priceRange = 'any',
    this.rating = 0.0,
  });

  // Copy constructor
  ActivityFilter.from(ActivityFilter other) :
    peopleCount = other.peopleCount,
    childrenCount = other.childrenCount,
    childAge = other.childAge,
    interests = List.from(other.interests),
    radiusKm = other.radiusKm,
    popularity = other.popularity,
    considerWeather = other.considerWeather,
    accessibleOnly = other.accessibleOnly,
    favoritesOnly = other.favoritesOnly,
    showVisited = other.showVisited,
    environment = other.environment,
    duration = other.duration,
    priceRange = other.priceRange,
    rating = other.rating;

  // Convert to query parameters map
  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    
    params['peopleCount'] = peopleCount.toString();
    params['childrenCount'] = childrenCount.toString();
    params['childAge'] = childAge.toString();
    params['radius'] = radiusKm.toString();
    params['popularity'] = popularity.toString();
    params['considerWeather'] = considerWeather.toString();
    params['accessibleOnly'] = accessibleOnly.toString();
    params['favoritesOnly'] = favoritesOnly.toString();
    params['showVisited'] = showVisited.toString();
    params['rating'] = rating.toString();
    
    if (interests.isNotEmpty) {
      params['interests'] = interests.join(',');
    }
    
    if (environment != 'any') {
      params['environment'] = environment;
    }
    
    if (duration != 'any') {
      params['duration'] = duration;
    }
    
    if (priceRange != 'any') {
      params['priceRange'] = priceRange;
    }
    
    return params;
  }

  // Create from query parameters
  factory ActivityFilter.fromQueryParams(Map<String, String> params) {
    return ActivityFilter(
      peopleCount: int.tryParse(params['peopleCount'] ?? '1') ?? 1,
      childrenCount: int.tryParse(params['childrenCount'] ?? '0') ?? 0,
      childAge: int.tryParse(params['childAge'] ?? '0') ?? 0,
      radiusKm: double.tryParse(params['radius'] ?? '25.0') ?? 25.0,
      popularity: int.tryParse(params['popularity'] ?? '0') ?? 0,
      considerWeather: params['considerWeather'] == 'true',
      accessibleOnly: params['accessibleOnly'] == 'true',
      favoritesOnly: params['favoritesOnly'] == 'true',
      showVisited: params['showVisited'] != 'false', // Default to true
      environment: params['environment'] ?? 'any',
      duration: params['duration'] ?? 'any',
      priceRange: params['priceRange'] ?? 'any',
      rating: double.tryParse(params['rating'] ?? '0.0') ?? 0.0,
      interests: params['interests']?.split(',').where((s) => s.isNotEmpty).toList() ?? [],
    );
  }

  // Check if filter has active filters (not default values)
  bool get hasActiveFilters {
    return childrenCount > 0 ||
           interests.isNotEmpty ||
           radiusKm != 25.0 ||
           popularity > 0 ||
           considerWeather ||
           accessibleOnly ||
           favoritesOnly ||
           !showVisited ||
           environment != 'any' ||
           duration != 'any' ||
           priceRange != 'any' ||
           rating > 0.0;
  }

  // Reset to default values
  void reset() {
    peopleCount = 1;
    childrenCount = 0;
    childAge = 0;
    interests = [];
    radiusKm = 25.0;
    popularity = 0;
    considerWeather = false;
    accessibleOnly = false;
    favoritesOnly = false;
    showVisited = true;
    environment = 'any';
    duration = 'any';
    priceRange = 'any';
    rating = 0.0;
  }

  @override
  String toString() {
    return 'ActivityFilter('
        'peopleCount: $peopleCount, '
        'childrenCount: $childrenCount, '
        'childAge: $childAge, '
        'interests: $interests, '
        'radiusKm: $radiusKm, '
        'popularity: $popularity, '
        'considerWeather: $considerWeather, '
        'accessibleOnly: $accessibleOnly, '
        'favoritesOnly: $favoritesOnly, '
        'showVisited: $showVisited, '
        'environment: $environment, '
        'duration: $duration, '
        'priceRange: $priceRange, '
        'rating: $rating'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ActivityFilter) return false;
    
    return peopleCount == other.peopleCount &&
           childrenCount == other.childrenCount &&
           childAge == other.childAge &&
           interests.toString() == other.interests.toString() &&
           radiusKm == other.radiusKm &&
           popularity == other.popularity &&
           considerWeather == other.considerWeather &&
           accessibleOnly == other.accessibleOnly &&
           favoritesOnly == other.favoritesOnly &&
           showVisited == other.showVisited &&
           environment == other.environment &&
           duration == other.duration &&
           priceRange == other.priceRange &&
           rating == other.rating;
  }

  @override
  int get hashCode {
    return Object.hash(
      peopleCount,
      childrenCount,
      childAge,
      interests,
      radiusKm,
      popularity,
      considerWeather,
      accessibleOnly,
      favoritesOnly,
      showVisited,
      environment,
      duration,
      priceRange,
      rating,
    );
  }
}