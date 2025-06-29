import { supabase } from "../../app/lib/supabaseClient";
const { fetchAndInsert } = require("../../app/lib/fetchAndInsertCore");

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

export default async function handler(req, res) {
    try {
        const lat = parseFloat(req.query.lat);
        const lng = parseFloat(req.query.lng);
        const radiusRaw = (req.query.radius || '25').replace(',', '.');
        const radiusKm = parseFloat(radiusRaw);
        const weatherRaw = req.query.weather || "any";
        const weather = mapWeatherToTag(weatherRaw);

        const peopleCount = parseInt(req.query.peopleCount || '1');
        const childrenCount = parseInt(req.query.childrenCount || '0');
        const childAge = parseInt(req.query.childAge || '0');
        const popularity = parseInt(req.query.popularity || '0');
        const considerWeather = req.query.considerWeather === 'true';
        const accessibleOnly = req.query.accessibleOnly === 'true';
        const favoritesOnly = req.query.favoritesOnly === 'true';
        const showVisited = req.query.showVisited === 'true';
        const environment = req.query.environment || null;
        const interests = req.query.interests ? req.query.interests.split(',') : [];
        const userId = req.query.userId || null;

        const speedKmh = 5;

        if (isNaN(lat) || isNaN(lng) || isNaN(radiusKm)) {
            return res.status(400).json({ error: "Invalid or missing lat/lng/radius" });
        }

        await fetchAndInsert({ lat, lon: lng, radius: radiusKm * 1000 });

        let query = supabase.from("activities").select("*");

        if (considerWeather) {
            query = query.eq("weather_tag", weather);
        }
        if (accessibleOnly) {
            query = query.eq("accessible", true);
        }
        if (popularity > 0) {
            query = query.gte("popularity", popularity);
        }
        if (environment) {
            query = query.eq("environment", environment);
        }
        if (interests.length > 0) {
            query = query.overlaps("interests", interests);
        }
        if (favoritesOnly && userId) {
            query = query.contains("user_favorites", [userId]);
        }
        if (!showVisited && userId) {
            query = query.not("visited_by", "cs", `[\"${userId}\"]`);
        }

        if (childrenCount > 0 && childAge < 10) {
            query = query.eq("enfant_friendly", true);
        }

        const { data, error } = await query;

        if (error) {
            console.error("❌ Supabase error:", error);
            return res.status(500).json({ error: error.message });
        }

        const result = data
            .map((a) => {
                const distKm = haversineDistance(lat, lng, a.lat, a.lng);
                const durationMin = Math.round((distKm / speedKmh) * 60);
                return {
                    ...a,
                    distance: `${distKm.toFixed(2)} km`,
                    duration: `${durationMin} min`,
                };
            })
            .filter((a) => parseFloat(a.distance) <= radiusKm);

        console.log(`📊 Activités retenues : ${result.length}`);

        return res.status(200).json({
            weather: weather,
            weatherDescription: weatherRaw,
            activities: result,
        });

    } catch (e) {
        console.error("❌ Unexpected error:", e.message);
        return res.status(500).json({ error: e.message });
    }
}
