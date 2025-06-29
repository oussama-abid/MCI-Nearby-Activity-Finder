// eslint-disable-next-line @typescript-eslint/no-require-imports
require('dotenv').config();
// eslint-disable-next-line @typescript-eslint/no-require-imports
const axios = require('axios');
// eslint-disable-next-line @typescript-eslint/no-require-imports
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_ANON_KEY
);

const OT_API_KEY = process.env.OPENTRIPMAP_API_KEY;
const OW_API_KEY = process.env.OPENWEATHER_API_KEY;

const TYPES_AUTORISES = ['natural', 'cultural', 'historic', 'architecture', 'sport', 'museum', 'park', 'monuments'];
const TAGS_EXCLUS = [
    'stolperstein', 'plaque', 'memorial', 'manhole', 'financial',
    'office', 'administrative', 'government', 'commercial',
    'supermarket', 'bank', 'business', 'residential'
];

const images = {
    hiking: "https://images.unsplash.com/photo-1472396961693-142e6e269027?q=80&w=2152&auto=format&fit=crop&ixlib=rb-4.1.0",
    bike: "https://images.unsplash.com/photo-1509395176047-4a66953fd231",
    museum: "https://images.unsplash.com/photo-1492305175278-3b3afaa2f31f?w=600&auto=format&fit=crop&q=60",
    historic: "https://images.unsplash.com/photo-1501028725025-d36415ffe456?q=80&w=2070&auto=format&fit=crop",
    beach: "https://images.unsplash.com/photo-1507525428034-b723cf961d3e",
    generic: "https://images.unsplash.com/photo-1503264116251-35a269479413"
};

function detectType(tags) {
    if (tags.includes('natural') || tags.includes('park') || tags.includes('forest')) return 'hiking';
    if (tags.includes('sport') || tags.includes('stadium') || tags.includes('fitness')) return 'bike';
    if (tags.includes('cultural') || tags.includes('museum') || tags.includes('art')) return 'museum';
    if (tags.includes('architecture') || tags.includes('historic') || tags.includes('monuments')) return 'historic';
    if (tags.includes('beach') || tags.includes('river') || tags.includes('water')) return 'beach';
    return 'generic';
}

function detectWeatherTag(tags) {
    const sunnyTags = ['natural', 'park', 'forest', 'sport'];
    const rainyTags = ['museum', 'cultural', 'indoor', 'monuments', 'historic'];
    if (tags.some(tag => sunnyTags.some(s => tag.includes(s)))) return 'sunny';
    if (tags.some(tag => rainyTags.some(r => tag.includes(r)))) return 'rainy';
    return 'any';
}

async function fetchAndInsert({ lat, lon, radius = 5000, limit = 30 } = {}) {
    try {
        const weatherRes = await axios.get('https://api.openweathermap.org/data/2.5/weather', {
            params: { lat, lon, appid: OW_API_KEY }
        });
        const currentWeather = weatherRes.data.weather[0].main;
        console.log(`🌤 Météo actuelle : ${currentWeather}`);

        const res = await axios.get('https://api.opentripmap.com/0.1/en/places/radius', {
            params: {
                apikey: OT_API_KEY,
                lat,
                lon,
                radius,
                format: 'json',
                limit
            }
        });

        const rawPlaces = res.data;

        const filtered = rawPlaces.filter(place => {
            const tags = place.kinds?.toLowerCase().split(',') || [];
            const name = place.name?.toLowerCase() || '';
            const nomNonTouristique = /bank|sparkasse|finanz|plaque|memorial|zentrum|business|gmbh|office/.test(name);

            return (
                place.name &&
                tags.length > 0 &&
                TYPES_AUTORISES.some(auth => tags.includes(auth)) &&
                !TAGS_EXCLUS.some(ex => tags.includes(ex)) &&
                !nomNonTouristique &&
                place.xid
            );
        });

        const prepared = [];
        const coordSet = new Set();

        for (const place of filtered) {
            try {
                const detailRes = await axios.get(`https://api.opentripmap.com/0.1/en/places/xid/${place.xid}`, {
                    params: { apikey: OT_API_KEY }
                });

                const detail = detailRes.data;
                const tags = place.kinds.toLowerCase().split(',');
                const type = detectType(tags);
                const weather_tag = detectWeatherTag(tags);

                if (!detail.point?.lat || !detail.point?.lon) {
                    console.warn(`❌ Lieu sans coordonnées valides: ${place.name}`);
                    continue;
                }

                const coordKey = `${detail.point.lat},${detail.point.lon}`;
                if (coordSet.has(coordKey)) {
                    console.log(`ℹ️ Doublon ignoré: ${detail.name}`);
                    continue;
                }
                coordSet.add(coordKey);

                const imageUrl = detail.preview?.source || images[type] || images['generic'];

                prepared.push({
                    name: detail.name || 'Unbenannter Ort',
                    lat: detail.point.lat,
                    lng: detail.point.lon,
                    type,
                    weather_tag,
                    duration: '1h',
                    image_url: imageUrl
                });

                console.log(`✅ Ajout: ${detail.name} (${detail.point.lat}, ${detail.point.lon})`);
            } catch (err) {
                console.warn(`⚠️ Erreur pour ${place.name}: ${err.message}`);
            }
        }

        const { error } = await supabase
            .from('activities')
            .upsert(prepared, {
                onConflict: ['name', 'lat', 'lng']
            });

        if (error) throw error;

        console.log(`🎉 ${prepared.length} activités insérées ou mises à jour.\n`);
    } catch (e) {
        console.error('❌ Erreur principale :', e.message);
    }
}

// Appelle ici pour une ville spécifique (ex. Hamburg)
fetchAndInsert({ lat: 53.5511, lon: 9.9937, radius: 6000, limit: 40 });
