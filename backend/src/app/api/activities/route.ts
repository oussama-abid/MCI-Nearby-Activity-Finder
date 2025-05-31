// @ts-ignore

import { NextResponse } from 'next/server'
import { getMockActivities } from '@/app/lib/mockData'
import getDistance from 'geolib/es/getDistance'

const WEATHER_API = 'https://api.openweathermap.org/data/2.5/weather'
const WEATHER_KEY = process.env.OPENWEATHER_API_KEY

export async function GET(req: Request) {
    const { searchParams } = new URL(req.url)

    const lat = searchParams.get('lat')
    const lon = searchParams.get('lon')

    if (!lat || !lon) {
        return NextResponse.json({ error: 'Missing lat or lon' }, { status: 400 })
    }

    // Lecture des filtres
    const accessibleParam = searchParams.get('accessible')
    const accessible = accessibleParam === 'true' ? true : accessibleParam === 'false' ? false : undefined

    const favoritesOnly = searchParams.get('favoritesOnly') === 'true'
    const interests = searchParams.get('interests')?.split(',') ?? []
    const radius = parseFloat(searchParams.get('radius') ?? '100')

    // Favoris utilisateur (mock)
    const userFavorites = ['default1']

    // 1. Météo
    const weatherRes = await fetch(
        `${WEATHER_API}?lat=${lat}&lon=${lon}&appid=${WEATHER_KEY}&units=metric`
    )
    const weatherData = await weatherRes.json()
    const weather   = weatherData.weather?.[0]?.main ?? 'Clear'
    const weatherDescription = weatherData.weather?.[0]?.description ?? 'klar'

    // 2. Activités selon la météo
    let activities = getMockActivities(weather )

    // 3. Filtrage
    activities = activities.filter(act => {
        if (accessible !== undefined && act.accessible !== accessible) return false
        if (favoritesOnly && !userFavorites.includes(act.id)) return false
        if (interests.length > 0 && !interests.includes(act.type)) return false

        const dist = getDistance(
            { latitude: parseFloat(lat), longitude: parseFloat(lon) },
            { latitude: act.lat, longitude: act.lon }
        ) / 1000

        if (dist > radius) return false

        return true
    })

    // 4. Réponse finale
    return NextResponse.json({
        weather,
        weatherDescription,
        activities,
    })
}
//