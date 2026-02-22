import Foundation
import CoreLocation
import WeatherKit

@Observable
class WeatherService: NSObject, CLLocationManagerDelegate {
    static let shared = WeatherService()

    private let locationManager = CLLocationManager()
    private let weatherService = WeatherKit.WeatherService.shared
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?

    var lastWeather: WeatherInfo?
    var locationError: Error?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func fetchWeather() async throws -> WeatherInfo {
        let location = try await requestLocation()
        let weather = try await weatherService.weather(for: location)
        let current = weather.currentWeather

        let info = WeatherInfo(
            temperature: current.temperature.value,
            feelsLike: current.apparentTemperature.value,
            condition: current.condition.description,
            humidity: current.humidity,
            windSpeed: current.wind.speed.value
        )
        lastWeather = info
        return info
    }

    func fetchWeatherByCity(_ city: String) async throws -> WeatherInfo {
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.geocodeAddressString(city)
        guard let location = placemarks.first?.location else {
            throw WeatherError.cityNotFound
        }
        let weather = try await weatherService.weather(for: location)
        let current = weather.currentWeather

        let info = WeatherInfo(
            temperature: current.temperature.value,
            feelsLike: current.apparentTemperature.value,
            condition: current.condition.description,
            humidity: current.humidity,
            windSpeed: current.wind.speed.value
        )
        lastWeather = info
        return info
    }

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
