require('dotenv').config();

const { fetchAndInsert } = require('../../app/lib/fetchAndInsertCore');

(async () => {
    console.log("✅ SUPABASE_URL =", process.env.SUPABASE_URL); // debug
    await fetchAndInsert({
        lat: 53.0793,
        lon: 8.8017,
        radius: 10000,
        limit: 50
    });
})();
