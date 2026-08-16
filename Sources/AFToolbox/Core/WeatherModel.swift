import CoreLocation
import Foundation

struct WeatherDay: Codable, Identifiable {
    let date: Date
    let code: Int
    let tMax: Double
    let tMin: Double
    let rainProb: Int
    var id: Date { date }
}

struct WeatherState: Codable {
    let place: String
    let temperature: Double
    let code: Int
    let wind: Double
    let humidity: Int
    let days: [WeatherDay]
    let fetched: Date
}

/// Wetter am aktuellen Standort (CoreLocation) mit Fallback-Ort aus den
/// Einstellungen. Daten: Open-Meteo — nutzt für die Schweiz die ICON-CH-Modelle
/// von MeteoSchweiz. Letzter Stand wird gecacht (offline sichtbar).
@MainActor
final class WeatherModel: NSObject, ObservableObject {
    @Published var state: WeatherState?
    @Published var loading = false
    @Published var errorText: String?
    @Published var usingFallback = false

    private let manager = CLLocationManager()
    private var lastFetch: Date?
    private static let cacheKey = "weatherCache"

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        if let data = UserDefaults.standard.data(forKey: Self.cacheKey),
           let cached = try? JSONDecoder().decode(WeatherState.self, from: data) {
            state = cached
        }
    }

    func refreshIfNeeded() {
        if let lastFetch, Date().timeIntervalSince(lastFetch) < 900 { return }
        refresh()
    }

    func refresh() {
        errorText = nil
        loading = true
        // Screenshot-Modus (Doku): nie den echten Standort abbilden
        if ProcessInfo.processInfo.arguments.contains("--screenshot") {
            fetchWithFallback()
            return
        }
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorized, .authorizedAlways:
            manager.requestLocation()
        default:
            fetchWithFallback()
        }
    }

    private func fetchWithFallback() {
        usingFallback = true
        let defaults = UserDefaults.standard
        let lat = defaults.double(forKey: "weatherLat")
        let lon = defaults.double(forKey: "weatherLon")
        guard lat != 0 || lon != 0 else {
            loading = false
            errorText = "Keine Ortung aktiv — Fallback-Ort in den Einstellungen setzen."
            return
        }
        let place = defaults.string(forKey: "weatherPlace") ?? "Fallback-Ort"
        Task { await fetch(lat: lat, lon: lon, place: place) }
    }

    private func fetch(lat: Double, lon: Double, place: String) async {
        loading = true
        defer { loading = false }
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)"
            + "&current=temperature_2m,weather_code,wind_speed_10m,relative_humidity_2m"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max"
            + "&timezone=auto&forecast_days=6"
        guard let url = URL(string: urlString) else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let current = json["current"] as? [String: Any],
                  let daily = json["daily"] as? [String: Any],
                  let temperature = (current["temperature_2m"] as? NSNumber)?.doubleValue,
                  let code = (current["weather_code"] as? NSNumber)?.intValue else {
                errorText = "Wetterdaten nicht lesbar"
                return
            }
            let wind = (current["wind_speed_10m"] as? NSNumber)?.doubleValue ?? 0
            let humidity = (current["relative_humidity_2m"] as? NSNumber)?.intValue ?? 0

            let times = daily["time"] as? [String] ?? []
            let codes = (daily["weather_code"] as? [Any])?.map { ($0 as? NSNumber)?.intValue ?? 0 } ?? []
            let maxima = (daily["temperature_2m_max"] as? [Any])?.map { ($0 as? NSNumber)?.doubleValue ?? 0 } ?? []
            let minima = (daily["temperature_2m_min"] as? [Any])?.map { ($0 as? NSNumber)?.doubleValue ?? 0 } ?? []
            let rain = (daily["precipitation_probability_max"] as? [Any])?.map { ($0 as? NSNumber)?.intValue ?? 0 } ?? []

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            var days: [WeatherDay] = []
            // Index 0 = heute (steckt schon in «aktuell») — Vorhersage sind die Tage 1–5
            for index in 1..<min(times.count, codes.count, maxima.count, minima.count, max(rain.count, 1)) {
                guard let date = formatter.date(from: times[index]) else { continue }
                days.append(WeatherDay(date: date,
                                       code: codes[index],
                                       tMax: maxima[index],
                                       tMin: minima[index],
                                       rainProb: index < rain.count ? rain[index] : 0))
            }

            let newState = WeatherState(place: place, temperature: temperature, code: code,
                                        wind: wind, humidity: humidity, days: days, fetched: Date())
            state = newState
            lastFetch = Date()
            errorText = nil
            if let encoded = try? JSONEncoder().encode(newState) {
                UserDefaults.standard.set(encoded, forKey: Self.cacheKey)
            }
        } catch {
            errorText = "Wetter nicht abrufbar (offline?)"
        }
    }

    // MARK: - Geocoding (Fallback-Ort in den Einstellungen)

    static func geocode(_ name: String) async -> (name: String, lat: Double, lon: Double)? {
        let query = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        guard let url = URL(string: "https://geocoding-api.open-meteo.com/v1/search?name=\(query)&count=1&language=de") else {
            return nil
        }
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = json["results"] as? [[String: Any]],
              let first = results.first,
              let foundName = first["name"] as? String,
              let lat = (first["latitude"] as? NSNumber)?.doubleValue,
              let lon = (first["longitude"] as? NSNumber)?.doubleValue else {
            return nil
        }
        return (foundName, lat, lon)
    }

    // MARK: - WMO-Wettercodes

    static func symbol(for code: Int) -> String {
        switch code {
        case 0: return "sun.max"
        case 1: return "sun.min"
        case 2: return "cloud.sun"
        case 3: return "cloud"
        case 45, 48: return "cloud.fog"
        case 51...57: return "cloud.drizzle"
        case 61...67: return "cloud.rain"
        case 71...77, 85, 86: return "cloud.snow"
        case 80...82: return "cloud.heavyrain"
        case 95...99: return "cloud.bolt.rain"
        default: return "cloud"
        }
    }

    static func text(for code: Int) -> String {
        switch code {
        case 0: return "Klar"
        case 1: return "Meist sonnig"
        case 2: return "Teils bewölkt"
        case 3: return "Bedeckt"
        case 45, 48: return "Nebel"
        case 51...57: return "Nieselregen"
        case 61...67: return "Regen"
        case 71...77, 85, 86: return "Schnee"
        case 80...82: return "Schauer"
        case 95...99: return "Gewitter"
        default: return "Bewölkt"
        }
    }
}

extension WeatherModel: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            switch status {
            case .authorized, .authorizedAlways:
                self.manager.requestLocation()
            case .denied, .restricted:
                self.fetchWithFallback()
            default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        Task { @MainActor in
            self.usingFallback = false
            let placemarks = try? await CLGeocoder().reverseGeocodeLocation(location)
            let place = placemarks?.first?.locality ?? placemarks?.first?.name ?? "Standort"
            await self.fetch(lat: location.coordinate.latitude,
                             lon: location.coordinate.longitude,
                             place: place)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.fetchWithFallback()
        }
    }
}
