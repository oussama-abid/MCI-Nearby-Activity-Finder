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

  ActivityFilter({
    this.peopleCount = 1,
    this.childrenCount = 0,
    this.childAge = 0,
    this.interests = const [],
    this.radiusKm = 25,
    this.popularity = 0,
    this.considerWeather = false,
    this.accessibleOnly = false,
    this.favoritesOnly = false,
    this.showVisited = false,
    this.environment = 'Stadt',
  });

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
        'environment: $environment'
        ')';
  }
}
