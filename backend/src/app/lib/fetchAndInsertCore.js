require('dotenv').config();
const axios = require('axios');
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY);
const OT_API_KEY = process.env.OPENTRIPMAP_API_KEY;
const OW_API_KEY = process.env.OPENWEATHER_API_KEY;

const TYPES_AUTORISES = ['natural', 'cultural', 'historic', 'architecture', 'sport', 'museum', 'park', 'monuments'];
const TAGS_EXCLUS = [
    'stolperstein', 'plaque', 'memorial', 'manhole', 'financial',
    'office', 'administrative', 'government', 'commercial',
    'supermarket', 'bank', 'business', 'residential'
];

const images = {
    hiking: "https://images.unsplash.com/photo-1472396961693-142e6e269027?q=80",
    bike: "https://images.unsplash.com/photo-1509395176047-4a66953fd231",
    museum: "https://images.unsplash.com/photo-1492305175278-3b3afaa2f31f?w=600",
    historic: "https://images.unsplash.com/photo-1501028725025-d36415ffe456?q=80",
    beach: "https://images.unsplash.com/photo-1507525428034-b723cf961d3e",
    generic: "https://images.unsplash.com/photo-1503264116251-35a269479413"
};

// 🔎 Deductions
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
    if (tags.some(tag => sunnyTags.includes(tag))) return 'sunny';
    if (tags.some(tag => rainyTags.includes(tag))) return 'rainy';
    return 'any';
}

function isAccessible(tags) {
    return tags.includes("wheelchair") || tags.includes("paved") || tags.includes("accessible");
}

function inferPopularity(detail) {
    let score = 0;
    if (detail.wikipedia) score += 2;
    if (detail.wikidata) score += 2;
    if (detail.preview) score += 1;
    if (detail.otm) score += 1;
    return score;
}

function isChildFriendly(tags, name = "") {
    const keywords = ["zoo", "park", "playground", "aquarium", "theme_park", "kids"];
    const nameLower = name.toLowerCase();
    return keywords.some(tag => tags.includes(tag)) || /enfant|kids|spielplatz|family/.test(nameLower);
}

async function fetchFromWikidata(wikidataId) {
    const endpoint = 'https://query.wikidata.org/sparql';
    const query = `
    SELECT ?website ?contact ?wikipedia ?opening WHERE {
      OPTIONAL { wd:${wikidataId} wdt:P856 ?website. }
      OPTIONAL { wd:${wikidataId} wdt:P1329 ?contact. }
      OPTIONAL { wd:${wikidataId} wdt:P856 ?wikipedia. }
      OPTIONAL { wd:${wikidataId} wdt:P3025 ?opening. }
    }
    LIMIT 1
  `;
    const res = await axios.get(endpoint, {
        headers: { 'Accept': 'application/sparql-results+json' },
        params: { query }
    });

    const bindings = res.data.results.bindings[0] || {};
    return {
        website: bindings.website?.value || null,
        contact: bindings.contact?.value || null,
        wikipedia: bindings.wikipedia?.value || null,
        opening_hours: bindings.opening?.value || null,
    };
}

// ✅ Récupère les valeurs existantes
async function fetchExistingActivity(lat, lng, name) {
    const { data } = await supabase
        .from('activities')
        .select(`
      accessible,
      enfant_friendly,
      popularity,
      children_count,
      people_count,
      child_age,
      consider_weather,
      favorites_only,
      show_visited
    `)
        .eq('lat', lat)
        .eq('lng', lng)
        .eq('name', name)
        .maybeSingle();

    return data || {};
}

async function fetchAndInsert({ lat, lon, radius = 5000, limit = 30 } = {}) {
    console.log("📍 fetchAndInsert →", { lat, lon, radius, limit });

    try {
        const weatherRes = await axios.get('https://api.openweathermap.org/data/2.5/weather', {
            params: { lat, lon, appid: OW_API_KEY }
        });
        const currentWeather = weatherRes.data.weather[0].main;
        console.log(`☁️ Météo actuelle : ${currentWeather}`);

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
                const defaultAccessible = isAccessible(tags);
                const defaultEnfantFriendly = isChildFriendly(tags, detail.name || '');
                const defaultPopularity = inferPopularity(detail);

                if (!detail.point?.lat || !detail.point?.lon) continue;

                const coordKey = `${detail.point.lat},${detail.point.lon}`;
                if (coordSet.has(coordKey)) continue;
                coordSet.add(coordKey);

                const existing = await fetchExistingActivity(detail.point.lat, detail.point.lon, detail.name);

                const accessible = existing.accessible ?? defaultAccessible;
                const enfant_friendly = existing.enfant_friendly ?? defaultEnfantFriendly;
                const popularity = existing.popularity ?? defaultPopularity;

                const children_count = existing.children_count ?? null;
                const people_count = existing.people_count ?? null;
                const child_age = existing.child_age ?? null;
                const consider_weather = existing.consider_weather ?? false;
                const favorites_only = existing.favorites_only ?? false;
                const show_visited = existing.show_visited ?? false;

                const imageUrl = detail.preview?.source || images[type] || images['generic'];
                let website = detail.url || detail.otm || null;
                let contact = detail.contact?.phone || detail.contact?.email || null;
                let wikipedia = detail.wikipedia || null;
                let opening_hours = detail.opening_hours?.text || null;

                const wikidataId = detail.wikidata || detail.sources?.wikidata || null;
                if (wikidataId) {
                    const wikidataDetails = await fetchFromWikidata(wikidataId);
                    opening_hours = wikidataDetails.opening_hours || opening_hours;
                    contact = wikidataDetails.contact || contact;
                    website = wikidataDetails.website || website;
                    wikipedia = wikidataDetails.wikipedia || wikipedia;
                }

                prepared.push({
                    name: detail.name || 'Unbenannter Ort',
                    lat: detail.point.lat,
                    lng: detail.point.lon,
                    type,
                    weather_tag,
                    duration: '1h',
                    image_url: imageUrl,
                    website,
                    contact,
                    wikipedia,
                    opening_hours,
                    accessible,
                    popularity,
                    enfant_friendly,
                    interests: tags,
                    children_count,
                    people_count,
                    child_age,
                    consider_weather,
                    favorites_only,
                    show_visited
                });

                console.log(`✅ Ajout: ${detail.name}`);
            } catch (err) {
                console.warn(`⚠️ Erreur sur ${place.name}: ${err.message}`);
            }
        }

        const { error } = await supabase
            .from('activities')
            .upsert(prepared, {
                onConflict: ['name', 'lat', 'lng']
            });

        if (error) throw error;

        console.log(`🎉 ${prepared.length} activités insérées/mises à jour.\n`);
    } catch (e) {
        console.error('❌ Erreur principale :', e.message);
    }
}

module.exports = { fetchAndInsert };
