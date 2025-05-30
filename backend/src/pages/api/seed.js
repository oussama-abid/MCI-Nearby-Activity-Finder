import { supabase } from "../../app/lib/supabaseClient";

export default async function handler(req, res) {
    const { error } = await supabase.from('activities').insert([
        {
            name: 'Strandbesuch',
            type: 'beach',
            lat: 53.09,
            lng: 8.81,
            duration: '1h',
            weather_tag: 'sunny',
        },
    ]);

    if (error) return res.status(500).json({ error: error.message });
    res.status(200).json({ status: 'ok' });
}
