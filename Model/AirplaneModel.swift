import Foundation

struct AirplaneModel {
    let icao24: String
    let callsign: String
    var getCallsign: String {
        return callsign.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    let latitude: Double
    let longitude: Double
    let true_track: Double
    let baro_altitude: Double?
    let geo_altitude: Double?
    let origin_country: String
    let velocity: Double?
    let vertical_rate: Double?
}
