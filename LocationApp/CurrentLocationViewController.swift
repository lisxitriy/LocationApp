//
//  CurrentLocationViewController.swift
//  LocationApp
//
//  Created by Olga Trofimova on 28.03.2021.
//

import UIKit
import CoreLocation

class CurrentLocationViewController: UIViewController, CLLocationManagerDelegate {
    
    
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var longitudeLabel: UILabel!
    @IBOutlet var latitudeLabel: UILabel!
    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var tagButton: UIButton!
    @IBOutlet var getButton: UIButton!
    
    var location: CLLocation?
    var updatingLocation = false
    var lastLocationError: Error?
    
    let geocoder = CLGeocoder()
    var placemark: CLPlacemark?
    var performReverseGeocoding = false
    var lastGeocodingError: Error?
    
    let locationManager = CLLocationManager()
    
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateLabels()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        скрыть панель навигации с текущего экрана
        navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
      super.viewWillDisappear(animated)
      navigationController?.isNavigationBarHidden = false
    }

    //MARK: - Actions
    @IBAction func getLocation() {
        
        let authStatus = locationManager.authorizationStatus
        
        // проверить разрешение на получение обновления данных 
        if authStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            return
        }
        
        if authStatus == .denied || authStatus == .restricted {
            showLocationServicesDeniedAlert()
            return
        }
        
        if updatingLocation {
            stopLocationManager()
        } else {
            location = nil
            lastLocationError = nil
            placemark = nil
            lastGeocodingError = nil
            startLocationManager()
        }
        
       updateLabels()
    }

    //MARK: - CLLocationManagerDelegate
    
//    методы делегата для locationManager
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("didFailWithError \(error.localizedDescription)")
        
//       CLError.locationUnknown означает, что диспетчер местоположения не смог получить местоположение прямо сейчас, но это не означает, что все потеряно
        
        if (error as NSError).code == CLError.locationUnknown.rawValue { //
            return
        }
        
        lastLocationError = error
        stopLocationManager()
        updateLabels()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last!
        print("didUpdateLocations \(newLocation)")
        
// Если время, когда данный объект местоположения был определен слишком давно (сейчас это 5 секунд) то это кешированный результат.
        if newLocation.timestamp.timeIntervalSinceNow < -5 {
            return
        }
        
//чтобы проверить явл ли эти показания более точные, чем предыдущие
        if newLocation.horizontalAccuracy < 0 {
            return
        }
        
        var distance = CLLocationDistance(Double.greatestFiniteMagnitude)
        
        if let location = location {
            distance = newLocation.distance(from: location)
        }
        
//все еще проверяем точность и проверяем самое ли первое это обновление экземпляра
        if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy {
        
        lastLocationError = nil
        location = newLocation
        }
        
//Если точность нового местоположения равна или лучше, чем желаемая точность,  можно прекратить запрашивать обновления у менеджера местоположения
        
        if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy {
            print("We're done")
            stopLocationManager()
            
            if distance > 0 {
                performReverseGeocoding = false
            }
        }
        
        updateLabels()
        
        if !performReverseGeocoding {
            print("Going to geocode")
            
            performReverseGeocoding = true
            
            geocoder.reverseGeocodeLocation(newLocation) { placemarks, error in
//                if let error = error {
//                print("Reverse Geocoding error: \(error.localizedDescription)")
//                return
//                }
//
//                if let places = placemarks {
//                    print("Found places: \(places)")
//                }
                
                self.lastGeocodingError = error
                
                if error == nil, let places = placemarks, !places.isEmpty {
                    self.placemark = places.last!
                } else {
                    self.placemark = nil
                }
                
                self.performReverseGeocoding = false
                self.updateLabels()
            }
        } else if distance < 1 {
            let timeInterval = newLocation.timestamp.timeIntervalSince(location!.timestamp)
            if timeInterval > 10 {
                print("Force done")
                stopLocationManager()
                updateLabels()
            }
        }
    }
    
    func updateLabels() {
        if let location = location {
//            %.8f - 8 цифр после точки (f - floating-point)
            latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
            longitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
            tagButton.isHidden = false
            messageLabel.text = ""
            
            if let placemark = placemark {
                addressLabel.text = string(from: placemark)
            } else if performReverseGeocoding {
                addressLabel.text = "Searching for Address..."
            } else if lastGeocodingError != nil {
                addressLabel.text = "Error Finding Address"
            } else {
                addressLabel.text = "No Address Found"
            }
        } else {
            latitudeLabel.text = ""
            longitudeLabel.text = ""
            addressLabel.text = ""
            tagButton.isHidden = true
//            messageLabel.text = "Tap 'Get My Location' to Start"
            let statusMessage: String
            
            if let error = lastLocationError as NSError? {
                if error.domain == kCLErrorDomain && error.code == CLError.denied.rawValue {
                    statusMessage = "Location Services Disabled"
                } else {
                    statusMessage = "Error Getting Location"
                }
            } else if !CLLocationManager.locationServicesEnabled() {
                statusMessage = "Location Services Disabled"
            } else if updatingLocation {
                statusMessage = "Searching..."
            } else {
                statusMessage = "Tap 'Get My Location' to Start"
            }
            messageLabel.text = statusMessage
        }
        
        configureGetButton()
    }
    
    func startLocationManager(){
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            updatingLocation = true
            
            timer = Timer.scheduledTimer(timeInterval: 60,
                                         target: self,
                                         selector: #selector(didTimeOut),
                                         userInfo: nil,
                                         repeats: false)
        }
    }
    
    func stopLocationManager() {
        if updatingLocation {
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation = false
            
            if let timer = timer {
                timer.invalidate()
            }
        }
    }
    
    @objc func didTimeOut() {
        print("Time out")
        if location == nil {
            stopLocationManager()
            lastLocationError = NSError(domain: "MyLocationsErrorDomain", code: 1, userInfo: nil)
            updateLabels()
        }
    }
    
    func configureGetButton() {
        if updatingLocation {
            getButton.setTitle("Stop", for: .normal)
        } else {
            getButton.setTitle("Get My Location", for: .normal)
        }
    }
    
    func string(from placemark: CLPlacemark) -> String {
        var line1 = ""
        
        if let tmp = placemark.subThoroughfare {
            line1 += tmp + " "
        }
        
        if let tmp = placemark.thoroughfare {
            line1 += tmp
        }
        
        var line2 = ""
        
        if let tmp = placemark.locality {
            line2 += tmp + " "
        }
        
        if let tmp = placemark.administrativeArea {
            line2 += tmp + " "
        }
        
        if let tmp = placemark.postalCode {
            line2 += tmp
        }
        
        return line1 + "\n" + line2
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "TagLocation" {
            let controller = segue.destination as! LocationDetailsViewController
            controller.coordinate = location!.coordinate
            controller.placemark = placemark
        }
    }
    
    //MARK: - Helper Methods
    
    func showLocationServicesDeniedAlert() {
        let alert = UIAlertController(title: "Location Services Disabled", message: "Please enable location services for this app in Settings.", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        alert.addAction(okAction)
        
        present(alert, animated: true, completion: nil)
    }
}

