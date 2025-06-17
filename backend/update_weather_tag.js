// eslint-disable-next-line @typescript-eslint/no-require-imports
require('dotenv').config();
// eslint-disable-next-line @typescript-eslint/no-require-imports
const axios = require('axios');
// eslint-disable-next-line @typescript-eslint/no-require-imports
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_ANON_KEY // Service Role nécessaire pour update
);

const LAT = 53.0793;
const LON = 8.8017;
const OPENWEATHER_KEY = process.env.OPENWEATHER_API_KEY;

function mapWeatherToTag(mainWeather) {
    switch (mainWeather.toLowerCase()) {
        case 'clear':
        case 'clouds':
        case 'sunny':
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

function determineTagFromType(type) {
    // Les types en plein air (recommandés par beau temps)
    const sunnyTypes = ['hiking', 'bike', 'beach', 'historic'];
    const rainyTypes = ['museum'];

    if (sunnyTypes.includes(type)) return 'sunny';
    if (rainyTypes.includes(type)) return 'rainy';

    return 'any';
}

async function updateWeatherTags() {
    try {
        // 1. Obtenir météo actuelle
        const res = await axios.get('https://api.openweathermap.org/data/2.5/weather', {
            params: { lat: LAT, lon: LON, appid: OPENWEATHER_KEY }
        });

        const currentWeather = res.data.weather[0].main;
        const tag = mapWeatherToTag(currentWeather);
        console.log(`🌤 Météo à Brême : ${currentWeather} → Tag actuel = ${tag}`);

        // 2. Récupérer toutes les activités
        const { data: activities, error } = await supabase.from('activities').select('*');
        if (error) throw error;

        // 3. Mettre à jour avec le tag correct pour chaque type
        for (const activity of activities) {
            const newTag = determineTagFromType(activity.type);

            await supabase
                .from('activities')
                .update({ weather_tag: newTag })
                .eq('id', activity.id);

            console.log(`🔄 ${activity.name} → ${activity.type} → tag = ${newTag}`);
        }

        console.log('✅ weather_tag mis à jour pour toutes les activités.');
    } catch (err) {
        console.error('❌ Erreur :', err.message);
    }
}

updateWeatherTags();
