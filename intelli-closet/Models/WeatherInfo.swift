import Foundation

struct WeatherInfo {
    let temperature: Double
    let feelsLike: Double
    let condition: String
    let humidity: Double
    let windSpeed: Double

    var summary: String {
        "温度\(Int(temperature))°C（体感\(Int(feelsLike))°C），\(condition)，湿度\(Int(humidity * 100))%，风速\(Int(windSpeed))km/h"
    }
}
