import { supabase } from "../../app/lib/supabaseClient";

export default async function handler(req, res){
    const { data, error } = await supabase.from('activities').select('*');
    if (error) return res.status(500).json({ error: error.message })
    res.status(200).json(data);
}