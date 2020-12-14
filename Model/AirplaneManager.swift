import Foundation

protocol AirplaneManagerDelegate {
    func didupdateAirplane(_ airplaneManager: AirplaneManager, airplanes: Array<AirplaneModel>)
    func didFailAirplane(error: Error)
}

struct AirplaneManager {
    let airplaneURL = "https://opensky-network.org/api/states/all"
    var delegate: AirplaneManagerDelegate?
    
    func getAirplaneInfo(topLatitude: Double, bottomLatitude: Double, leftLongitude: Double, rightLongitude: Double) {
        let urlString = "\(airplaneURL)?lamin=\(bottomLatitude)&lomin=\(leftLongitude)&lamax=\(topLatitude)&lomax=\(rightLongitude)"
        if let url = URL(string: urlString) {
            let session = URLSession(configuration: .default)
            let task = session.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    self.delegate?.didFailAirplane(error : error!)
                    return
                }
                if let safeData = data {
                    //print(String(data: safeData, encoding: .utf8))
                    if let airports = self.parseJSON(safeData) {
                        self.delegate?.didupdateAirplane(self, airplanes: airports)
                    }
                }
            }
            task.resume()
        }
    }
    
    func parseJSON(_ data: Data ) -> Array<AirplaneModel>? {
        let decorder = JSONDecoder()
        do {
            let airplaneData: AirplaneData = try decorder.decode(AirplaneData.self, from: data)
            var result: Array<AirplaneModel> = Array()
            if let datas: Array<Array<AnyType?>> = airplaneData.states {
                for data: Array<AnyType?> in datas {
                    let airplaneModel = AirplaneModel(icao24: data[0]?.value as! String, callsign: data[1]?.value as! String , latitude: data[6]?.value as! Double, longitude: data[5]?.value as! Double, true_track: data[10]?.value as! Double , baro_altitude: data[7]?.value as? Double , geo_altitude: data[13]?.value as? Double , origin_country: data[2]?.value as! String , velocity: data[9]?.value as? Double , vertical_rate: data[11]?.value as? Double)
                    result.append(airplaneModel)
                }
            }
            return result
            
        } catch {
            print(error.localizedDescription)
            delegate?.didFailAirplane(error: error)
            return nil
        }
        
    }
}

struct AirplaneData: Decodable {
    let states: Array<Array<AnyType?>>?
}

struct AnyType: Decodable {
    var value: Any?
    init(from decorder: Decoder) throws {
        if let double = try? Double(from: decorder) {
            value = double
        } else if let int = try? Int(from: decorder) {
            value = int
        } else if let boolean = try? Bool(from: decorder) {
            value = boolean
        } else if let s = try? String(from: decorder) {
            value = s
        } else {
            value = nil
        }
    }
}
