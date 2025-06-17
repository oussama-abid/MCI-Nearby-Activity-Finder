// src/app/lib/mockData.ts

export function getMockActivities(weather: string) {
    const commonFields = {
        location: 'Bremen',
        weather,
        duration: '1Std',
        imageUrl: "https://images.unsplash.com/photo-1748096728390-0c0f12834975?q=80&w=1974&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
    };
    switch (weather) {
        case 'Clear':
        case 'Sunny':
        case 'Clouds':
            return [
                {
                    id: 'clear1',
                    name: 'Bürgerpark Bremen',
                    type: 'park',
                    lat: 53.0856,
                    lon: 8.8215,
                    distance: '3,8km',
                    accessible: true,
                    favorite: true,
                    ...commonFields
                },
                {
                    id: 'clear2',
                    name: 'Schlachte Riverside Promenade',
                    type: 'walking',
                    lat: 53.0950,
                    lon: 8.8000,
                    distance: '4,7km',
                    accessible: false,
                    favorite: false,
                    ...commonFields
                },
                {
                    id: 'clear3',
                    name: 'Wallanlagen Park',
                    type: 'park',
                    lat: 53.1040,
                    lon: 8.8420,
                    distance: '3,1km',
                    accessible: true,
                    favorite: false,
                    ...commonFields
                },
            ]

        case 'Rain':
        case 'Drizzle':
        case 'Thunderstorm':
            return [
                {
                    id: 'rain1',
                    name: 'Übersee-Museum',
                    type: 'museum',
                    lat: 53.0831,
                    lon: 8.8147,
                    distance: '2km',
                    accessible: true,
                    favorite: false,
                    ...commonFields
                },
                {
                    id: 'rain2',
                    name: 'Kunsthalle Bremen',
                    type: 'art',
                    lat: 53.0779,
                    lon: 8.8199,
                    distance: '3,5km',
                    accessible: true,
                    favorite: true,
                    ...commonFields
                },
            ]

        case 'Snow':
            return [
                {
                    id: 'snow1',
                    name: 'Eisarena Paradice',
                    type: 'ice rink',
                    lat: 53.1012,
                    lon: 8.8721,
                    distance: '4,2km',
                    accessible: false,
                    favorite: false,
                    ...commonFields
                },
                {
                    id: 'snow2',
                    name: 'Café Knigge',
                    type: 'cafe',
                    lat: 53.0771,
                    lon: 8.8073,
                    distance: '3km',
                    accessible: false,
                    favorite: true,
                    ...commonFields
                },
            ]

        default:
            return [
                {
                    id: 'default1',
                    name: 'Bremer Roland & Town Hall',
                    type: 'historic',
                    lat: 53.0650,
                    lon: 8.7900,
                    distance: '2,4km',
                    accessible: true,
                    favorite: true,
                    ...commonFields
                },
                {
                    id: 'default2',
                    name: 'Universum Science Center',
                    type: 'interactive museum',
                    lat: 53.1050,
                    lon: 8.8550,
                    distance: '1,7km',
                    accessible: false,
                    favorite: false,
                    ...commonFields
                },
            ]
    }
}
