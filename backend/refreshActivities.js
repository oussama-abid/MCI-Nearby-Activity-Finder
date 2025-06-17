require('dotenv').config();
const axios = require('axios');
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY);

const LAT = 53.0793;
const LON = 8.8017;
const RADIUS = 5000;
const LIMIT = 50;

const OT_API_KEY = process.env.OPENTRIPMAP_API_KEY;
const OW_API_KEY = process.env.OPENWEATHER_API_KEY;

const TYPES_AUTORISES = ['natural', 'cultural', 'historic', 'architecture', 'sport', 'museum', 'park', 'monuments'];
const TAGS_EXCLUS = ['stolperstein', 'plaque', 'memorial', 'manhole', 'financial', 'office', 'administrative', 'government', 'commercial', 'supermarket', 'bank', 'business', 'residential'];

const images = {
    hiking: "https://images.unsplash.com/photo-1472396961693-142e6e269027",
    bike: "https://images.unsplash.com/photo-1509395176047-4a66953fd231",
    museum: "https://images.unsplash.com/photo-1492305175278-3b3afaa2f31f",
    historic: "https://images.unsplash.com/photo-1501028725025-d36415ffe456",
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

function determineTagFromType(type) {
    const sunnyTypes = ['hiking', 'bike', 'beach', 'historic'];
    const rainyTypes = ['museum'];
    if (sunnyTypes.includes(type)) return 'sunny';
    if (rainyTypes.includes(type)) return 'rainy';
    return 'any';
}

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

async function fetchAndInsert() {
    try {
        const weatherRes = await axios.get('https://api.openweathermap.org/data/2.5/weather', {
            params: { lat: LAT, lon: LON, appid: OW_API_KEY }
        });
        const currentWeather = weatherRes.data.weather[0].main;
        console.log(`🌤 Météo actuelle : ${currentWeather}`);

        const res = await axios.get('https://api.opentripmap.com/0.1/en/places/radius', {
            params: {
                apikey: OT_API_KEY,
                lat: LAT,
                lon: LON,
                radius: RADIUS,
                format: 'json',
                limit: LIMIT,
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

                if (!detail.point || !detail.point.lat || !detail.point.lon) continue;

                const coordKey = `${detail.point.lat},${detail.point.lon}`;
                if (coordSet.has(coordKey)) continue;
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

                console.log(`✅ Ajouté : ${detail.name}`);
            } catch (err) {
                console.warn(`⚠️ Erreur détail : ${place.name}`);
            }
        }

        const { error } = await supabase
            .from('activities')
            .upsert(prepared, {
                onConflict: ['name', 'lat', 'lng'],
            });
        if (error) throw error;

        console.log(`🎉 ${prepared.length} activités insérées ou mises à jour avec succès.`);

        await updateWeatherTags();

    } catch (e) {
        console.error('❌ Erreur globale :', e.message);
    }
}

async function updateWeatherTags() {
    try {
        const { data: activities, error } = await supabase.from('activities').select('*');
        if (error) throw error;

        for (const activity of activities) {
            const newTag = determineTagFromType(activity.type);
            await supabase
                .from('activities')
                .update({ weather_tag: newTag })
                .eq('id', activity.id);

            console.log(`🔄 ${activity.name} → ${activity.type} → tag = ${newTag}`);
        }

        console.log('Tous les weather_tag ont été mis à jour.');
    } catch (err) {
        console.error('Erreur mise à jour des tags météo :', err.message);
    }
}

// Lancement principal
fetchAndInsert();
