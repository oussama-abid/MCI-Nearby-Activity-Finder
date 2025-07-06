// /api/weather.js - Complete weather endpoint (GET version)
export default async function handler(req, res) {
    // Add CORS headers
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

    // Handle preflight requests
    if (req.method === 'OPTIONS') {
        res.status(200).end();
        return;
    }

    // Only accept GET requests
    if (req.method !== 'GET') {
        return res.status(405).json({ 
            error: 'Method not allowed. Use GET.',
            allowedMethods: ['GET']
        });
    }

    try {
        console.log('🌤️ Weather endpoint called');
        console.log('📍 Query parameters:', req.query);
        
        // Extract coordinates from query parameters
        const { lat, lng, lon } = req.query;
        const longitude = lng || lon; // Accept both lng and lon
        
        // Validate required parameters
        if (!lat || !longitude) {
            return res.status(400).json({ 
                error: "Missing required parameters: lat and lng/lon are required",
                received: { lat, lng: longitude },
                example: "GET /api/weather?lat=53.0793&lng=8.8017"
            });
        }

        // Convert to numbers if they're strings
        const latitude = parseFloat(lat);
        const longitudeNum = parseFloat(longitude);

        // Validate coordinate ranges
        if (isNaN(latitude) || isNaN(longitudeNum)) {
            return res.status(400).json({ 
                error: "Invalid coordinates. Lat and lng must be valid numbers",
                received: { lat, lng: longitude }
            });
        }

        if (latitude < -90 || latitude > 90 || longitudeNum < -180 || longitudeNum > 180) {
            return res.status(400).json({ 
                error: "Invalid coordinate ranges. Lat must be -90 to 90, lng must be -180 to 180",
                received: { lat: latitude, lng: longitudeNum }
            });
        }

        console.log(`🌍 Fetching weather for coordinates: ${latitude}, ${longitudeNum}`);

        // Fetch weather data
        const weatherData = await fetchCurrentWeather(latitude, longitudeNum);
        
        if (!weatherData) {
            return res.status(500).json({ 
                error: "Unable to fetch weather data. Please try again later.",
                coordinates: { lat: latitude, lng: longitudeNum },
                suggestion: "Check if coordinates are valid and API is accessible"
            });
        }

        // Map weather to your app's tag system
        const mappedWeather = mapWeatherToTag(weatherData.main);

        console.log(`✅ Weather data retrieved successfully for ${latitude}, ${longitudeNum}`);
        console.log(`🏷️ Weather: ${weatherData.main} → ${mappedWeather}`);

        // Return comprehensive weather response
        return res.status(200).json({
            success: true,
            location: {
                lat: latitude,
                lng: longitudeNum,
                coordinates: `${latitude}, ${longitudeNum}`
            },
            weather: {
                main: weatherData.main,
                description: weatherData.description,
                icon: weatherData.icon,
                mapped: mappedWeather, // Your app's simplified weather tag
                iconUrl: `https://openweathermap.org/img/wn/${weatherData.icon}@2x.png`
            },
            temperature: {
                current: weatherData.temperature,
                feelsLike: weatherData.feelsLike,
                min: weatherData.tempMin,
                max: weatherData.tempMax,
                unit: "°C"
            },
            conditions: {
                humidity: weatherData.humidity,
                pressure: weatherData.pressure,
                visibility: weatherData.visibility,
                cloudiness: weatherData.cloudiness
            },
            wind: {
                speed: weatherData.windSpeed,
                direction: weatherData.windDirection,
                gust: weatherData.windGust,
                speedUnit: "m/s"
            },
            sun: {
                sunrise: weatherData.sunrise,
                sunset: weatherData.sunset
            },
            meta: {
                timestamp: new Date().toISOString(),
                source: "OpenWeatherMap API",
                apiVersion: "2.5"
            }
        });

    } catch (error) {
        console.error("❌ Weather endpoint error:", error);
        return res.status(500).json({ 
            error: "Internal server error",
            message: error.message,
            coordinates: req.query?.lat && req.query?.lng ? 
                { lat: req.query.lat, lng: req.query.lng } : null,
            stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
        });
    }
}

// Weather fetching function
async function fetchCurrentWeather(lat, lng) {
    try {
        const API_KEY = process.env.OPENWEATHER_API_KEY;
        
        if (!API_KEY) {
            throw new Error('OpenWeatherMap API key not configured. Please set OPENWEATHER_API_KEY environment variable.');
        }

        // Build API URL with metric units
        const url = `https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lng}&appid=${API_KEY}&units=metric`;
        
        console.log('🌐 Calling OpenWeatherMap API...');
        console.log('🔗 URL:', url.replace(API_KEY, '***API_KEY***'));
        
        const response = await fetch(url, {
            method: 'GET',
            headers: {
                'User-Agent': 'Weather-App/1.0'
            }
        });
        
        const data = await response.json();
        
        if (!response.ok) {
            console.error('❌ OpenWeatherMap API error:', data);
            throw new Error(`Weather API error (${response.status}): ${data.message || 'Unknown error'}`);
        }

        console.log('✅ OpenWeatherMap API response received');
        console.log('🌤️ Weather:', data.weather[0].main, '-', data.weather[0].description);
        console.log('🌡️ Temperature:', Math.round(data.main.temp), '°C');

        // Process and return weather data
        return {
            main: data.weather[0].main,
            description: data.weather[0].description,
            icon: data.weather[0].icon,
            temperature: Math.round(data.main.temp),
            feelsLike: Math.round(data.main.feels_like),
            tempMin: Math.round(data.main.temp_min),
            tempMax: Math.round(data.main.temp_max),
            humidity: data.main.humidity,
            pressure: data.main.pressure,
            visibility: data.visibility ? Math.round(data.visibility / 1000) : null, // Convert to km
            windSpeed: data.wind?.speed || 0,
            windDirection: data.wind?.deg || 0,
            windGust: data.wind?.gust || null,
            cloudiness: data.clouds?.all || 0,
            sunrise: data.sys?.sunrise ? new Date(data.sys.sunrise * 1000).toISOString() : null,
            sunset: data.sys?.sunset ? new Date(data.sys.sunset * 1000).toISOString() : null,
            country: data.sys?.country || null,
            cityName: data.name || null
        };

    } catch (error) {
        console.error('❌ Error fetching weather data:', error.message);
        console.error('🔍 Error details:', error);
        return null;
    }
}

// Weather mapping function - maps OpenWeatherMap conditions to your app's tags
function mapWeatherToTag(main) {
    if (!main) return "any";
    
    switch (main.toLowerCase()) {
        case "clear":
            return "sunny";
        case "clouds":
            return "sunny"; // Cloudy but still good for outdoor activities
        case "rain":
        case "drizzle":
        case "thunderstorm":
            return "rainy";
        case "snow":
        case "sleet":
            return "snow";
        case "mist":
        case "fog":
        case "haze":
        case "dust":
        case "sand":
        case "ash":
        case "squall":
        case "tornado":
            return "any"; // Unclear conditions
        default:
            console.warn(`⚠️ Unknown weather condition: ${main}`);
            return "any";
    }
}

// Utility function to validate coordinates (optional export for testing)
export function validateCoordinates(lat, lng) {
    const latitude = parseFloat(lat);
    const longitude = parseFloat(lng);
    
    if (isNaN(latitude) || isNaN(longitude)) {
        return { valid: false, error: "Coordinates must be valid numbers" };
    }
    
    if (latitude < -90 || latitude > 90) {
        return { valid: false, error: "Latitude must be between -90 and 90" };
    }
    
    if (longitude < -180 || longitude > 180) {
        return { valid: false, error: "Longitude must be between -180 and 180" };
    }
    
    return { valid: true, lat: latitude, lng: longitude };
}