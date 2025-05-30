String translateWeather(String weather, {String locale = 'de'}) {
  final w = weather.toLowerCase();

  const translations = {
    'clear': {
      'de': 'Sonnig',
      'fr': 'Ensoleillé',
      'en': 'Clear',
    },
    'clouds': {
      'de': 'Bewölkt',
      'fr': 'Nuageux',
      'en': 'Cloudy',
    },
    'rain': {
      'de': 'Regen',
      'fr': 'Pluie',
      'en': 'Rain',
    },
    'snow': {
      'de': 'Schnee',
      'fr': 'Neige',
      'en': 'Snow',
    },
    'thunderstorm': {
      'de': 'Gewitter',
      'fr': 'Orage',
      'en': 'Thunderstorm',
    },
    'drizzle': {
      'de': 'Nieselregen',
      'fr': 'Bruine',
      'en': 'Drizzle',
    },
    'mist': {
      'de': 'Nebel',
      'fr': 'Brouillard',
      'en': 'Mist',
    },
    'fog': {
      'de': 'Nebel',
      'fr': 'Brouillard',
      'en': 'Fog',
    },
  };

  return translations[w]?[locale] ?? weather;
}
