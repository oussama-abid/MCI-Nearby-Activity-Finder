import { supabase } from "../../app/lib/supabaseClient";

function mapWeatherToTag(main) {
    switch (main.toLowerCase()) {
        case 'clear':
        case 'sunny':
        case 'clouds':
            return 'sunny';
        case 'rain':
        case 'drizzle':
        case 'thunderstorm':
            return 'rainy';
        case 'snow':
            return 'snow';
        default:
            return 'any';
    }
}

function haversineDistance(lat1, lon1, lat2, lon2) {
    const R = 6371;
    const dLat = toRad(lat2 - lat1);
    const dLon = toRad(lon2 - lon1);
    const a = Math.sin(dLat / 2) ** 2 +
        Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
        Math.sin(dLon / 2) ** 2;
    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function toRad(value) {
    return value * Math.PI / 180;
}

export default async function handler(req, res) {
    try {
        const lat = parseFloat(req.query.lat);
        const lng = parseFloat(req.query.lng);
        const radiusKm = parseFloat(req.query.radius) || 25;
        const weather = mapWeatherToTag(req.query.weather || 'any');
        const speedKmh = 5; // marche à pied

        if (!lat || !lng) {
            return res.status(400).json({ error: 'Missing or invalid lat/lng' });
        }

        const { data, error } = await supabase
            .from('activities')
            .select('*')
            .eq('weather_tag', weather);

        if (error) {
            console.error('Supabase error:', error);
            return res.status(500).json({ error: error.message });
        }

        const filtered = data
            .map(activity => {
                const distKm = haversineDistance(lat, lng, activity.lat, activity.lng);
                const durationMin = Math.round((distKm / speedKmh) * 60);
                return {
                    ...activity,
                    distance_km: distKm.toFixed(2),
                    duration: `${durationMin} min`
                };
            })
            .filter(a => parseFloat(a.distance_km) <= radiusKm);

        return res.status(200).json({
            weather: req.query.weather,
            weatherDescription: req.query.weather,
            activities: filtered,
        });
    } catch (e) {
        console.error('Unexpected error:', e);
        return res.status(500).json({ error: e.message });
    }
}
