require('dotenv').config();
const axios = require('axios');
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_ROLE_KEY
);

const LAT = 53.0793; // Bremen
const LON = 8.8017;
const RADIUS = 5000; // mètres
const API_KEY = process.env.OPENTRIPMAP_API_KEY;

const TYPES_AUTORISES = ['natural', 'cultural', 'historic', 'architecture', 'sport'];

function detectType(kinds) {
    if (kinds.includes('natural')) return 'hiking';
    if (kinds.includes('sport')) return 'bike';
    if (kinds.includes('cultural')) return 'museum';
    return 'generic';
}

function detectWeatherTag(kinds) {
    if (kinds.includes('natural') || kinds.includes('sport')) return 'sunny';
    if (kinds.includes('cultural')) return 'rainy';
    return 'any';
}

async function fetchAndInsert() {
    try {
        const res = await axios.get('https://api.opentripmap.com/0.1/en/places/radius', {
            params: {
                apikey: API_KEY,
                lat: LAT,
                lon: LON,
                radius: RADIUS,
                format: 'json',
                limit: 30,
            }
        });

        const rawPlaces = res.data;

        const filtered = rawPlaces.filter(p =>
            p.kinds && TYPES_AUTORISES.some(type => p.kinds.includes(type))
        );

        const prepared = filtered.map(p => ({
            name: p.name || 'Unbenannter Ort',
            lat: p.point.lat,
            lng: p.point.lon,
            type: detectType(p.kinds),
            weather_tag: detectWeatherTag(p.kinds),
            duration: '1h', // optionnel, fixe ou randomisable
        }));

        const { data, error } = await supabase.from('activities').insert(prepared);
        if (error) throw error;

        console.log(`✅ ${prepared.length} activités insérées.`);
    } catch (e) {
        console.error('❌ Erreur :', e.message);
    }
}

fetchAndInsert();
