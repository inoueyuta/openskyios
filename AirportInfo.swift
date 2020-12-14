//
//  AirportInfo.swift
//  opensky
//
//  Created by inoue yuta on 2020/11/21.
//

import Foundation
import CoreLocation

struct AirportModel {
    let icao: String;
    let iata: String;
    let name: String;
    let city: String;
    let type: String;
    let longitude: CLLocationDegrees;
    let latitude: CLLocationDegrees;
    
    var getShortNam: String {
        if(name.contains(" International Airport")) {
            return name
        } else if (name.contains(" Airport")) {
            return name
        } else {
            return name
        }
    }
}
