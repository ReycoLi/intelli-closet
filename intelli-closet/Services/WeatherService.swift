import Foundation
import CoreLocation
import MapKit

@Observable
class WeatherService: NSObject, CLLocationManagerDelegate {
    static let shared = WeatherService()

    private let locationManager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?

    var lastWeather: WeatherInfo?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func fetchWeather() async throws -> WeatherInfo {
        let location = try await requestLocation()
        return try await fetchOpenMeteo(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
    }

    func fetchWeatherByCity(_ city: String) async throws -> WeatherInfo {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = city
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        guard let mapItem = response.mapItems.first else {
            throw WeatherError.cityNotFound
        }
        let coord = mapItem.location.coordinate
        return try await fetchOpenMeteo(latitude: coord.latitude, longitude: coord.longitude)
    }

    // MARK: - Open-Meteo API (free, no key required)

    private func fetchOpenMeteo(latitude: Double, longitude: Double) async throws -> WeatherInfo {
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&current=temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code&timezone=auto"
        guard let url = URL(string: urlString) else {
            throw WeatherError.cityNotFound
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let current = json?["current"] as? [String: Any] else {
            throw WeatherError.cityNotFound
        }

        let temp = current["temperature_2m"] as? Double ?? 20
        let feelsLike = current["apparent_temperature"] as? Double ?? temp
        let humidity = (current["relative_humidity_2m"] as? Double ?? 50) / 100.0
        let windSpeed = current["wind_speed_10m"] as? Double ?? 0
        let weatherCode = current["weather_code"] as? Int ?? 0

        let info = WeatherInfo(
            temperature: temp,
            feelsLike: feelsLike,
            condition: Self.weatherCondition(from: weatherCode),
            humidity: humidity,
            windSpeed: windSpeed
        )
        lastWeather = info
        return info
    }

    private static func weatherCondition(from code: Int) -> String {
        switch code {
        case 0: return "晴天"
        case 1: return "大部晴朗"
        case 2: return "多云"
        case 3: return "阴天"
        case 45, 48: return "雾"
        case 51, 53, 55: return "毛毛雨"
        case 61, 63, 65: return "雨"
        case 66, 67: return "冻雨"
        case 71, 73, 75: return "雪"
        case 77: return "雪粒"
        case 80, 81, 82: return "阵雨"
        case 85, 86: return "阵雪"
        case 95: return "雷暴"
        case 96, 99: return "冰雹雷暴"
        default: return "未知"
        }
    }

    // MARK: - Location

    private func requestLocation() async throws -> CLLocation {
        locationManager.requestWhenInUseAuthorization()
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            locationManager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            locationContinuation?.resume(returning: location)
            locationContinuation = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(throwing: error)
        locationContinuation = nil
    }
}

enum WeatherError: LocalizedError {
    case cityNotFound
    case locationDenied

    var errorDescription: String? {
        switch self {
        case .cityNotFound: return "未找到该城市"
        case .locationDenied: return "定位权限被拒绝"
        }
    }
}
