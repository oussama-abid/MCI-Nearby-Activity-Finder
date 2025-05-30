// /app/api/activities/route.ts

import { NextResponse } from 'next/server'

const WEATHER_API = 'https://api.openweathermap.org/data/2.5/weather'
const TRIPMAP_API = 'https://api.opentripmap.com/0.1/en/places/radius'
const WEATHER_KEY = process.env.OPENWEATHER_API_KEY
const TRIPMAP_KEY = 'REMOVED'

type Feature = {
    properties: {
        xid: string
        name: string
        kinds: string
    }
    geometry: {
        coordinates: [number, number] // [lon, lat]
    }
}

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

    // 2. Déduire un filtre d’activité (ex: s’il pleut => éviter outdoor)
    const isRainy = ['Rain', 'Thunderstorm', 'Drizzle'].includes(weather)
    const kinds = isRainy ? 'cultural,museums,interesting_places' : 'natural,parks,foods'

    // 3. Obtenir les lieux
    const tripRes = await fetch(
        `${TRIPMAP_API}?radius=2000&lon=${lon}&lat=${lat}&limit=10&kinds=${kinds}&apikey=${TRIPMAP_KEY}`
    )
    const tripData = await tripRes.json()

    return NextResponse.json({
        weather,
        activities: tripData.features?.map((f: Feature) => ({
            id: f.properties.xid,
            name: f.properties.name,
            type: f.properties.kinds,
            lat: f.geometry.coordinates[1],
            lon: f.geometry.coordinates[0],
        })),
    })
}
