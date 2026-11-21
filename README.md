# MCI: Nearby Activity Finder

A mobile app that suggests leisure activities near you, based on your
location, the current weather and who you are with.

University team project at Hochschule Bremen, summer semester 2025,
by Oussama Ben Abid and Yvann Dongmo.

## Features

- **Map** of nearby activities (parks, museums, historic sites, sport and
  nature) with clustered markers; tap one to see its details
- **Home screen** with the current weather and the top 5 suggestions
- **Filters:** group size, children and their age, interests, radius,
  popularity, wheelchair access, and weather-aware suggestions
  (museums when it rains, parks when it is sunny)
- **Activity details** with distance and estimated duration
- **Favourites** and visited places
- **German and English**

## Architecture

```
Flutter app ──HTTP──► Next.js API routes ──► Supabase (PostgreSQL)
                             │
                             ├──► OpenTripMap API (places)
                             └──► OpenWeatherMap API (weather)
```

Import scripts load places from OpenTripMap and tag them (weather type,
child-friendly, accessibility, popularity), so the API can filter quickly.

## Tech stack

- **App:** Flutter (Dart), flutter_map with marker clustering, geolocator,
  Lottie, Flutter localization
- **Backend:** Next.js API routes (JavaScript/TypeScript), Supabase
- **Data:** OpenTripMap, OpenWeatherMap

## My part (Oussama)

Mainly the app: splash screen and navigation, the home screen with live
weather and the top suggestions, the filter screen, the project structure,
and the map interaction (selecting activities, cluster taps, the detail
page with distance and duration).

## Run it locally

You need your own Supabase project and free API keys from
[OpenTripMap](https://opentripmap.io) and
[OpenWeatherMap](https://openweathermap.org/api).

**Backend** (`backend/`):

```bash
cd backend
cp .env.example .env.local   # then fill in your keys
npm install
npm run dev
```

**App** (`frontend/mcifrontend/`):

```bash
cd frontend/mcifrontend
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=REMOVED \
  --dart-define=SUPABASE_ANON_KEY=your-supabase-anon-key
```

## Status

A finished university project; it is not maintained.
