import { supabase } from "../../../app/lib/supabaseClient";
import axios from "axios";

const OPENWEATHER_KEY = process.env.OPENWEATHER_API_KEY;

// Map OpenWeather → nos tags internes
function mapWeatherToTag(mainWeather) {
    switch (mainWeather.toLowerCase()) {
        case "clear":
        case "clouds":
        case "sunny":
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

export default async function handler(req, res) {
    const { lat, lon } = req.query;

    if (!lat || !lon) {
        return res.status(400).json({ error: "Latitude et longitude requises" });
    }

    try {
        // 1. Appel OpenWeather
        const weatherRes = await axios.get(
            `https://api.openweathermap.org/data/2.5/weather`,
            {
                params: {
                    lat,
                    lon,
                    appid: OPENWEATHER_KEY,
                },
            }
        );

        const weatherMain = weatherRes.data.weather[0].main;
        const weatherTag = mapWeatherToTag(weatherMain);

        // 2. Requête Supabase filtrée
        const { data, error } = await supabase
            .from("activities")
            .select("*")
            .ilike("weather_tag", `%${weatherTag}%`);

        if (error) throw error;

        return res.status(200).json({
            weather: weatherMain,
            tag: weatherTag,
            activities: data,
        });
    } catch (e) {
        console.error(e.message);
        return res.status(500).json({ error: "Erreur serveur", details: e.message });
    }
}
