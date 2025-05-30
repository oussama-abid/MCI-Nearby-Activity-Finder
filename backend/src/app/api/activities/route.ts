// /app/api/activities/route.ts

import { NextResponse } from 'next/server'
import { getMockActivities } from '@/app/lib/mockData'

const WEATHER_API = 'https://api.openweathermap.org/data/2.5/weather'
const WEATHER_KEY = process.env.OPENWEATHER_API_KEY

export async function GET(req: Request) {
    const { searchParams } = new URL(req.url)
    const lat = searchParams.get('lat')
    const lon = searchParams.get('lon')

    if (!lat || !lon) {
        return NextResponse.json({ error: 'Missing lat or lon' }, { status: 400 })
    }

    // 1. Obtenir la météo
    const weatherRes = await fetch(
        `${WEATHER_API}?lat=${lat}&lon=${lon}&appid=${WEATHER_KEY}&units=metric`
    )
    const weatherData = await weatherRes.json()
    const weather = weatherData.weather?.[0]?.main ?? 'Clear'

    // 2. Récupérer les activités simulées en fonction de la météo
    const activities = getMockActivities(weather)

    // 3. Retour JSON final
    return NextResponse.json({
        weather,
        activities,
    })
}
