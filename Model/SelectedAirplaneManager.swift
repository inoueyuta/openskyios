import Foundation

protocol SelectedAirplaneManagerDelegate {
    func didupdateRoute(_ selectedAirplaneManager: SelectedAirplaneManager, departuerAirport: AirportModel?, arraivalAirport: AirportModel?)
    func didFailSelectedAirplane(error: Error)
}

class SelectedAirplaneManager {
    let airplaneRoutesURL = "https://opensky-network.org/api/routes?callsign="
    let airportURL = "https://opensky-network.org/api/airports/?icao="
    var delegate: SelectedAirplaneManagerDelegate?
    var departuerAirport: AirportModel?
    var arrivalAirport: AirportModel?
    var airplane: AirplaneModel
    
    init(airplane: AirplaneModel) {
        self.airplane = airplane
    }
    
    func getDepartureAndArrivalAirport() {
        let urlString = "\(airplaneRoutesURL)\(airplane.getCallsign)"
        if let url = URL(string: urlString) {
            let session = URLSession(configuration: .default)
            let task = session.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    self.delegate?.didFailSelectedAirplane(error : error!)
                    return
                }
                if let safeData = data {
                    //print(String(data: safeData, encoding: .utf8))
                    self.parseJSON(safeData)
                }
            }
            task.resume()
        }
    }
    
    func parseJSON(_ data: Data ) {
        let decorder = JSONDecoder()
        do {
            let routeData: RouteData = try decorder.decode(RouteData.self, from: data)
            if let route = routeData.route {
                let departuerAirportName = route[0]
                getAirportInfo(airportName: departuerAirportName, isDeparture: true)
                let arraivalAirportName = route[1]
                getAirportInfo(airportName: arraivalAirportName, isDeparture: false)
                delegate?.didupdateRoute(self, departuerAirport: departuerAirport, arraivalAirport: arrivalAirport)
            }
        } catch {
            print(error.localizedDescription)
            delegate?.didFailSelectedAirplane(error: error)
        }
        
    }
    
    func getAirportInfo(airportName: String, isDeparture: Bool) {
        let semaphore = DispatchSemaphore(value: 0)
        if let url = URL(string: "\(airportURL)\(airportName)") {
            let session = URLSession(configuration: .default)
            let task = session.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    self.delegate?.didFailSelectedAirplane(error : error!)
                    return
                }
                if let safeData = data {
                    //print(String(data: safeData, encoding: .utf8))
                    if let airport = self.parseAirportJSON(safeData) {
                        if isDeparture {
                            self.departuerAirport = airport
                        } else {
                            self.arrivalAirport = airport
                        }
                    }
                }
                semaphore.signal()
            }
            task.resume()
            semaphore.wait()
        }
    }
    
    func parseAirportJSON(_ data: Data ) -> AirportModel? {
        let decorder = JSONDecoder()
        do {
            let a: AirportData = try decorder.decode(AirportData.self, from: data)
            let result = AirportModel(icao: a.icao, iata: a.iata, name: a.name, city: a.city, type: a.type, longitude: a.position.longitude, latitude: a.position.latitude)
            return result
            
        } catch {
            print(error.localizedDescription)
            delegate?.didFailSelectedAirplane(error: error)
            return nil
        }
    }
}

struct RouteData: Codable {
    let route: Array<String>?
}


