import { supabase } from "../../app/lib/supabaseClient";
import { fetchAndInsert } from "../../app/lib/fetchAndInsertCore";

function mapWeatherToTag(main) {
    switch (main.toLowerCase()) {
        case "clear":
        case "sunny":
        case "clouds":
            return "sunny";
        case "rain":
        case "drizzle":
        case "thunderstorm":
            return "rainy";
        case "snow":
            return "snow";
        default:
            return "any";
    }
}

function haversineDistance(lat1, lon1, lat2, lon2) {
    const R = 6371;
    const dLat = toRad(lat2 - lat1);
    const dLon = toRad(lon2 - lon1);
    const a =
        Math.sin(dLat / 2) ** 2 +
        Math.cos(toRad(lat1)) *
        Math.cos(toRad(lat2)) *
        Math.sin(dLon / 2) ** 2;
    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function toRad(value) {
    return (value * Math.PI) / 180;
}

function parseQueryParam(value, defaultValue, type = 'string') {
    if (!value) return defaultValue;
    
    switch (type) {
        case 'int':
            const intVal = parseInt(value);
            return isNaN(intVal) ? defaultValue : intVal;
        case 'float':
            const floatVal = parseFloat(value.replace(',', '.'));
            return isNaN(floatVal) ? defaultValue : floatVal;
        case 'bool':
            return value === 'true';
        case 'array':
            return value.split(',').filter(Boolean);
        default:
            return value;
    }
}

export default async function handler(req, res) {
    // Add CORS headers
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

    // Handle preflight requests
    if (req.method === 'OPTIONS') {
        res.status(200).end();
        return;
    }

    try {
        console.log('📥 Received query parameters:', req.query);
        
        // Parse location parameters
        const lat = parseQueryParam(req.query.lat, null, 'float');
        const lng = parseQueryParam(req.query.lng, null, 'float');
        const radiusKm = parseQueryParam(req.query.radius, 25, 'float');
        
        // Validate required parameters
        if (isNaN(lat) || isNaN(lng) || isNaN(radiusKm)) {
            return res.status(400).json({ 
                error: "Invalid or missing lat/lng/radius parameters",
                received: { lat, lng, radius: radiusKm }
            });
        }

        // Parse weather parameters
        const weatherRaw = parseQueryParam(req.query.weather, "any");
        const weather = mapWeatherToTag(weatherRaw);
        const considerWeather = parseQueryParam(req.query.considerWeather, false, 'bool');

        // Parse filter parameters
        const childrenCount = parseQueryParam(req.query.childrenCount, 0, 'int');
        const childAge = parseQueryParam(req.query.childAge, 0, 'int');
        const popularity = parseQueryParam(req.query.popularity, 0, 'int');
        const accessibleOnly = parseQueryParam(req.query.accessibleOnly, false, 'bool');
        const favoritesOnly = parseQueryParam(req.query.favoritesOnly, false, 'bool');
        const showVisited = parseQueryParam(req.query.showVisited, true, 'bool');
        const environment = parseQueryParam(req.query.environment, null);
        const interests = parseQueryParam(req.query.interests, [], 'array');
        const userId = parseQueryParam(req.query.userId, null);

        // Parse additional filter parameters (commonly used)
        const duration = parseQueryParam(req.query.duration, null);
        const priceRange = parseQueryParam(req.query.priceRange, null);
        const rating = parseQueryParam(req.query.rating, 0, 'float');

        console.log('🔍 Parsed filters:', {
            location: { lat, lng, radius: radiusKm },
            weather: { raw: weatherRaw, mapped: weather, consider: considerWeather },
            children: { count: childrenCount, age: childAge },
            other: { popularity, accessibleOnly, favoritesOnly, showVisited, environment, interests, userId }
        });

        const speedKmh = 5;

        // Fetch and insert activities from external sources
        await fetchAndInsert({ lat, lon: lng, radius: radiusKm * 1000 });

        // Build Supabase query
        let query = supabase.from("activities").select("*");

        // Apply filters
        if (considerWeather && weather !== "any") {
            query = query.eq("weather_tag", weather);
        }
        
        if (accessibleOnly) {
            query = query.eq("accessible", true);
        }
        
        if (popularity > 0) {
            query = query.gte("popularity", popularity);
        }
        
        if (environment && environment !== "any") {
            query = query.eq("environment", environment);
        }
        
        if (interests.length > 0) {
            query = query.overlaps("interests", interests);
        }
        
        if (favoritesOnly && userId) {
            query = query.contains("user_favorites", [userId]);
        }
        
        if (!showVisited && userId) {
            query = query.not("visited_by", "cs", `{${userId}}`);
        }

        if (childrenCount > 0 && childAge < 10) {
            query = query.eq("enfant_friendly", true);
        }

        // Apply rating filter if specified
        if (rating > 0) {
            query = query.gte("rating", rating);
        }

        // Apply duration filter if specified
        if (duration && duration !== "any") {
            switch (duration) {
                case "short":
                    query = query.lte("duration_minutes", 60);
                    break;
                case "medium":
                    query = query.and("duration_minutes.gte.61", "duration_minutes.lte.180");
                    break;
                case "long":
                    query = query.gte("duration_minutes", 181);
                    break;
            }
        }

        // Apply price range filter if specified
        if (priceRange && priceRange !== "any") {
            switch (priceRange) {
                case "free":
                    query = query.eq("price_range", "free");
                    break;
                case "low":
                    query = query.in("price_range", ["free", "low"]);
                    break;
                case "medium":
                    query = query.in("price_range", ["free", "low", "medium"]);
                    break;
                case "high":
                    // No filter for high - show all
                    break;
            }
        }

        console.log('📊 Executing Supabase query...');
        const { data, error } = await query;

        if (error) {
            console.error("❌ Supabase error:", error);
            return res.status(500).json({ error: error.message });
        }

        console.log(`📈 Found ${data.length} activities before distance filtering`);

        // Filter by distance and add calculated fields
        const result = data
            .map((a) => {
                const distKm = haversineDistance(lat, lng, a.lat, a.lng);
                const durationMin = Math.round((distKm / speedKmh) * 60);
                return {
                    ...a,
                    distance: `${distKm.toFixed(2)} km`,
                    duration: `${durationMin} min`,
                    distanceKm: distKm, // Keep numeric value for filtering
                };
            })
            .filter((a) => a.distanceKm <= radiusKm)
            .sort((a, b) => a.distanceKm - b.distanceKm); // Sort by distance

        console.log(`📊 Final result: ${result.length} activities within ${radiusKm}km`);

        return res.status(200).json({
            weather: weather,
            weatherDescription: weatherRaw,
            activities: result,
            filters: {
                applied: {
                    location: { lat, lng, radius: radiusKm },
                    weather: considerWeather ? weather : null,
                    children: childrenCount > 0 ? { count: childrenCount, age: childAge } : null,
                    accessibility: accessibleOnly,
                    favorites: favoritesOnly,
                    visited: showVisited,
                    environment: environment !== "any" ? environment : null,
                    interests: interests.length > 0 ? interests : null,
                    popularity: popularity > 0 ? popularity : null,
                    rating: rating > 0 ? rating : null,
                    duration: duration !== "any" ? duration : null,
                    priceRange: priceRange !== "any" ? priceRange : null,
                }
            }
        });

    } catch (e) {
        console.error("❌ Unexpected error:", e.message, e.stack);
        return res.status(500).json({ 
            error: e.message,
            stack: process.env.NODE_ENV === 'development' ? e.stack : undefined
        });
    }
}