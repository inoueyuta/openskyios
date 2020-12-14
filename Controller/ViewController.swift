import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {
    @IBOutlet var mapView: MKMapView!
    let locationManager = CLLocationManager()
    var airportManager = AirportManager()
    var airplaneManager = AirplaneManager()
    var selectedAirplaneManager : SelectedAirplaneManager?
    var timer = Timer()
    //表示されている空港合計数
    var totalAirportCount: Int = 0
    //表示されている飛行機
    var airplanes: [AirplaneModel] = Array()
    //選択された飛行機View
    var selectedAirplaneAnnotationView: MKAnnotationView?
    
    //現在地ボタン押下時
    @IBAction func getCurrentLocation(sender: UIButton) {
        locationManager.requestLocation()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        //精度を低くすることで位置情報取得時間を短縮する
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.activityType = .other
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        var resion = MKCoordinateRegion()
        //位置情報取得不可の時のデフォルトは東京駅
        resion.center = CLLocationCoordinate2DMake(35.6809591, 139.7673068)
        resion.span.latitudeDelta = 1
        resion.span.longitudeDelta = 1
        mapView.setRegion(resion, animated: false)
        mapView.mapType = .standard
        mapView.showsUserLocation = true
        //コンパスの位置を現在地ボタンをかぶらないように移動
        let compass = MKCompassButton(mapView: mapView)
        compass.frame.origin = CGPoint(x: 20, y: 40)
        view.addSubview(compass)
        mapView.showsCompass = false
        
        airportManager.delegate = self
        airplaneManager.delegate = self
        mapView.delegate = self
        
        getAirport()
        startGetAirplaneTimer()
    }
    
    //飛行機取得
    func startGetAirplaneTimer() {
        let rect = mapView.visibleMapRect
        let northWestPoint = MKMapPoint(x: rect.minX, y: rect.minY)
        let southEastPoint = MKMapPoint(x: rect.maxX, y: rect.maxY)
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true, block: { (timer) in
            self.airplaneManager.getAirplaneInfo(topLatitude: northWestPoint.coordinate.latitude, bottomLatitude: southEastPoint.coordinate.latitude, leftLongitude: northWestPoint.coordinate.longitude, rightLongitude: southEastPoint.coordinate.longitude)
        })
        //キャンセル可能にするため少し遅延
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.timer.fire()
        }
    }
    
    //飛行場取得
    func getAirport() {
        let rect = mapView.visibleMapRect
        let northWestPoint = MKMapPoint(x: rect.minX, y: rect.minY)
        let southEastPoint = MKMapPoint(x: rect.maxX, y: rect.maxY)
        airportManager.getAirportInfo(topLatitude: northWestPoint.coordinate.latitude, bottomLatitude: southEastPoint.coordinate.latitude, leftLongitude: northWestPoint.coordinate.longitude, rightLongitude: southEastPoint.coordinate.longitude)
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            let lat = location.coordinate.latitude
            let lon = location.coordinate.longitude
            var resion = MKCoordinateRegion()
            resion.center = CLLocationCoordinate2DMake(lat, lon)
            resion.span.latitudeDelta = 1
            resion.span.longitudeDelta = 1
            mapView.setRegion(resion, animated: false)
            mapView.mapType = .standard
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status  = CLLocationManager.authorizationStatus()
        switch status {
            case .authorizedAlways, .authorizedWhenInUse:
                manager.requestLocation()
        case .notDetermined, .denied, .restricted:
                break
            default:
                break
        }
    }
}

extension ViewController: AirportManagerDelegate {
    func didupdateAirport(_ airportManager: AirportManager, airports: Array<AirportModel>) {
        DispatchQueue.main.async {
            self.clearAirport()
            for airport in airports {
                let annotation = AirportAnnotation()
                annotation.coordinate = CLLocationCoordinate2DMake(airport.latitude, airport.longitude)
                annotation.title = airport.name
                annotation.type = airport.type!
                self.mapView.addAnnotation(annotation)
            }
            self.totalAirportCount = airports.count
        }
    }
    
    func didFailAirport(error: Error) {
        print("error: \(error)")
    }
    
    func clearAirport() {
        for annotation in mapView.annotations {
            if (annotation is AirportAnnotation) {
                mapView.removeAnnotation(annotation)
            }
        }
    }
}

extension ViewController: AirplaneManagerDelegate {
    func didupdateAirplane(_ airplaneManager: AirplaneManager, airplanes: Array<AirplaneModel>) {
        DispatchQueue.main.async {
            self.clearAirplane()
            self.clearRoute()
            for	i in 0..<airplanes.count{
                let annotation = AirplaneAnnotation()
                annotation.index = i
                let airplane = airplanes[i]
                annotation.coordinate = CLLocationCoordinate2DMake(airplane.latitude,airplane.longitude)
                annotation.title = "便名: \(airplanes[i].callsign)"
                annotation.airplane = airplane
                //選択された飛行機のルート表示
                if self.selectedAirplaneManager?.airplane.callsign == airplane.callsign {
                    if let safeDepartuerAirport = self.selectedAirplaneManager?.departuerAirport , let safeArraivalAirport = self.selectedAirplaneManager?.arrivalAirport {
                        self.updateRoute(departuerAirport: safeDepartuerAirport, arraivalAirport: safeArraivalAirport, airplane: airplane)
                    }
                }
                self.mapView.addAnnotation(annotation)
            }
            self.airplanes = airplanes
        }
    }
    
    func didFailAirplane(error: Error) {
        print("error: \(error)")
    }
    
    func clearAirplane() {
        for annotation in mapView.annotations {
            if (annotation is AirplaneAnnotation) {
                mapView.removeAnnotation(annotation)
            }
        }
    }
}

extension ViewController: SelectedAirplaneManagerDelegate {
    func didupdateRoute(_ selectedAirplaneManager: SelectedAirplaneManager, departuerAirport: AirportModel?, arraivalAirport: AirportModel?) {
        if let safeDepartuerAirport = departuerAirport , let safeArraivalAirport = arraivalAirport {
            DispatchQueue.main.async {
                if let ano = self.selectedAirplaneAnnotationView?.annotation as? AirplaneAnnotation {
                    let airplane = ano.airplane!
                    //飛行機を連続して選択した場合に、飛行機の情報で更新するのを防ぐ
                    if (selectedAirplaneManager.airplane.icao24 == airplane.icao24) {
                        self.selectedAirplaneAnnotationView?.detailCalloutAccessoryView = self.createDetailCallout(airplane: airplane, departureAirport: safeDepartuerAirport.getShortName, arrivalAirport: safeArraivalAirport.getShortName)
                        self.updateRoute(departuerAirport:safeDepartuerAirport, arraivalAirport: safeArraivalAirport, airplane: selectedAirplaneManager.airplane)
                    }
                }
            }
        }
    }
    
    //ルートを表示
    func updateRoute(departuerAirport: AirportModel, arraivalAirport: AirportModel, airplane: AirplaneModel) {
        let coordinateDepartuerAirport = CLLocationCoordinate2DMake(departuerAirport.latitude, departuerAirport.longitude)
        let coordinateArraivalAirport = CLLocationCoordinate2DMake(arraivalAirport.latitude, arraivalAirport.longitude)
        let airplane = CLLocationCoordinate2DMake(airplane.latitude, airplane.longitude)
        let route1 = MKPolyline(coordinates: [coordinateDepartuerAirport, airplane], count: 2)
        route1.title = "departureRoute"
        let route2 = MKPolyline(coordinates: [coordinateArraivalAirport, airplane], count: 2)
        route2.title = "arraivalRoute"
        self.mapView.addOverlay(route1)
        self.mapView.addOverlay(route2)
    }
    
    func didFailSelectedAirplane(error: Error) {
        print("error: \(error)")
    }
    
    func clearRoute() {
        for poll in mapView.overlays {
            mapView.removeOverlay(poll)
        }
    }
    
}

//Annotationのカスタマイズ
extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifer = "identifer"
        if let ano = annotation as? AirplaneAnnotation {
            let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifer)
            let image: UIImage?
            if self.airplanes.count < 50 {
                image = UIImage(named: "airplane")
            } else {
                image = UIImage(named: "airplane_small")
            }
            let airplane = ano.airplane!
            let newImage = image?.rotate(radians: Float(airplane.true_track)*(.pi/180))
            annotationView.image = newImage
            annotationView.detailCalloutAccessoryView = createDetailCallout(airplane: airplane, departureAirport: nil, arrivalAirport: nil)
            annotationView.canShowCallout = true
            return annotationView
        } else if let ano = annotation as? AirportAnnotation {
            let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifer)
            if totalAirportCount < 50 {
                if "large_airport" == ano.type {
                    annotationView.image = UIImage(named: "airport")
                } else {
                    annotationView.image = UIImage(named: "airport_small")
                }
            } else {
                if "large_airport" == ano.type {
                    annotationView.image = UIImage(named: "airport_small")
                }
            }
            annotationView.canShowCallout = true
            return annotationView
        }
        return nil
    }
    
    //飛行機選択時に表示する情報
    func createDetailCallout(airplane: AirplaneModel, departureAirport: String?, arrivalAirport: String?) -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = NSLayoutConstraint.Axis.vertical
        stackView.alignment = UIStackView.Alignment.leading
        let label1 = UILabel()
        label1.frame = CGRect(x: 0,y: 0,width: 200,height: 0)
        label1.text = "出発: \(departureAirport ?? "")"
        stackView.addArrangedSubview(label1)
        let label2 = UILabel()
        label2.frame = CGRect(x: 0,y: 0,width: 200,height: 0)
        label2.text = "到着: \(arrivalAirport ?? "")"
        stackView.addArrangedSubview(label2)
        let label3 = UILabel()
        label3.frame = CGRect(x: 0,y: 0,width: 200,height: 0)
        label3.text = "機体番号: \(airplane.icao24)"
        stackView.addArrangedSubview(label3)
        let label4 = UILabel()
        label4.frame = CGRect(x: 0,y: 0,width: 200,height: 0)
        label4.text = "国名: \(airplane.origin_country)"
        stackView.addArrangedSubview(label4)
        let label5 = UILabel()
        label5.frame = CGRect(x: 0,y: 0,width: 200,height: 0)
        label5.text = "気圧高度: \(airplane.baro_altitude ?? 0.0)"
        stackView.addArrangedSubview(label5)
        let label6 = UILabel()
        label6.frame = CGRect(x: 0,y: 0,width: 200,height: 0)
        label6.text = "幾何学的高度: \(airplane.geo_altitude ?? 0.0)"
        stackView.addArrangedSubview(label6)
        let label7 = UILabel()
        label7.frame = CGRect(x: 0,y: 0,width: 200,height: 0)
        label7.text = "速度: \(airplane.velocity ?? 0.0)"
        stackView.addArrangedSubview(label7)
        let label8 = UILabel()
        label8.frame = CGRect(x: 0,y: 0,width: 200,height: 0)
        label8.text = "上下の速度: \(airplane.vertical_rate ?? 0.0)"
        stackView.addArrangedSubview(label8)
        return stackView
    }
    
    //Annotation選択時
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotation = view.annotation as? AirplaneAnnotation {
            print("didSelect")
            selectedAirplaneAnnotationView = view
            clearRoute()
            timer.invalidate()
            let airplane = airplanes[annotation.index]
            self.selectedAirplaneManager = SelectedAirplaneManager.init(airplane: airplane)
            self.selectedAirplaneManager?.arrivalAirport = nil
            self.selectedAirplaneManager?.departuerAirport = nil
            self.selectedAirplaneManager!.delegate = self
            self.selectedAirplaneManager!.getDepartureAndArrivalAirport()
        }
    }
    
    //Annotaion解除時
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        if let annotation = view.annotation as? AirplaneAnnotation {
            print("didDeselect")
            timer.invalidate()
            startGetAirplaneTimer()
        }
    }
    
    //領域変更時
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print("regionDidChangeAnimated")
        let selectedAirplane: Bool = selectedAirplaneAnnotationView?.isSelected ?? false
//        if(!selectedAirplane || (selectedAirplane && !animated) ) {
//            timer.invalidate()
//            getAirport()
//            startGetAirplaneTimer()
//        }
        if(!animated) {
            timer.invalidate()
            getAirport()
            startGetAirplaneTimer()
        }
        
    }
    
    //ルートのカスタマイズ
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let polyLineRenderer = MKPolylineRenderer(overlay: overlay)
        if overlay.title == "arraivalRoute" {
            polyLineRenderer.lineDashPattern = [15, 10]
        }
        polyLineRenderer.lineWidth = 3
        polyLineRenderer.strokeColor = .yellow
        return polyLineRenderer
    }
}

extension UIImage {
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!

        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        // Draw the image at its center
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}
