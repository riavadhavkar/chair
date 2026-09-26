import CoreLocation
import Foundation

/// Values from SetWatch.xcconfig (via SetWatchInfo.plist) plus app-wide constants.
enum AppConfig {
    static let backendBaseURL: URL? = {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "SetWatchBackendURL") as? String,
              !raw.isEmpty, !raw.hasPrefix("$(") else { return nil }
        return URL(string: raw)
    }()

    static let useMockData: Bool = {
        let flag = (Bundle.main.object(forInfoDictionaryKey: "SetWatchUseMockData") as? String)?.uppercased()
        return flag != "NO" || backendBaseURL == nil
    }()

    /// Where the map starts before (or without) a location fix: the West Village.
    static let fallbackCenter = CLLocationCoordinate2D(latitude: 40.7347, longitude: -74.0036)

    /// The client-side gate. The server allows a little more (150 m) for GPS drift.
    static let checkInRadius: CLLocationDistance = 100
    static let requiredAccuracy: CLLocationAccuracy = 65
    static let todayRadius: CLLocationDistance = 1600

    static func makeService() -> SetWatchService {
        if !useMockData, let backendBaseURL {
            return RemoteSetWatchService(baseURL: backendBaseURL, deviceID: DeviceID.current)
        }
        return MockSetWatchService()
    }
}

/// Anonymous per-install id; the server stores only this, the spot and the time.
enum DeviceID {
    static let current: String = {
        let key = "deviceID"
        if let existing = UserDefaults.standard.string(forKey: key) { return existing }
        let fresh = UUID().uuidString
        UserDefaults.standard.set(fresh, forKey: key)
        return fresh
    }()
}
