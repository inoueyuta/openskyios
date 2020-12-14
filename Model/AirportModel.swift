import Foundation
import CoreLocation

struct AirportModel {
    let icao: String?
    var iata: String?
    let name: String
    let city: String?
    let type: String?
    let longitude: Double
    let latitude: Double
    
    var getShortName: String {
        if(name.contains(" International Airport")) {
            return String(name.prefix(name.count - " International Airport".count))
        } else if (name.contains(" Airport")) {
            return String(name.prefix(name.count - " Airport".count))
        } else {
            return name
        }
    }
}
