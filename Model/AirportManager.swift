import Foundation
import CoreLocation

protocol AirportManagerDelegate {
    func didupdateAirport(_ airportManager: AirportManager, airports: Array<AirportModel>)
    func didFailAirport(error: Error)
}

struct AirportManager {
    let airportURL = "https://opensky-network.org/api/airports/region"
    var delegate: AirportManagerDelegate?
    
    func getAirportInfo(topLatitude: Double, bottomLatitude: Double, leftLongitude: Double, rightLongitude: Double) {
        let urlString = "\(airportURL)?lamin=\(bottomLatitude)&lomin=\(leftLongitude)&lamax=\(topLatitude)&lomax=\(rightLongitude)"
        if let url = URL(string: urlString) {
            let session = URLSession(configuration: .default)
            let task = session.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    self.delegate?.didFailAirport(error : error!)
                    return
                }
                if let safeData = data {
                    //print(String(data: safeData, encoding: .utf8))
                    if let airports = self.parseJSON(safeData) {
                        self.delegate?.didupdateAirport(self, airports: airports)
                    }
                }
            }
            task.resume()
        }
    }
    
    func parseJSON(_ data: Data ) -> Array<AirportModel>? {
        let decorder = JSONDecoder()
        do {
            let airportsData: [AirportData] = try decorder.decode([AirportData].self, from: data)
            var result: Array<AirportModel> = Array()
            for a in airportsData  {
                let airportsData = AirportModel(icao: a.icao, iata: a.iata, name: a.name, city: a.city, type: a.type, longitude: a.position.longitude, latitude: a.position.latitude)
                result.append(airportsData)
            }
            return result
            
        } catch {
            print(error.localizedDescription)
            delegate?.didFailAirport(error: error)
            return nil
        }
        
    }
}

struct AirportData: Codable {
    let icao: String?
    let iata: String?
    let name: String
    let city: String?
    let type: String?
    let position: Position
}

struct Position: Codable {
    let latitude: Double
    let longitude: Double
}
