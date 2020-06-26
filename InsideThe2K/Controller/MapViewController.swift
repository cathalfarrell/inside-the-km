//
//  ViewController.swift
//  InsideThe2K
//
//  Created by Cathal Farrell on 28/03/2020.
//  Copyright © 2020 Cathal Farrell. All rights reserved.
//

import UIKit
import GoogleMaps
import AVFoundation

class MapViewController: UIViewController {

    var myHomeLocation: CLLocationCoordinate2D!
    var eircodeEntered = "" //Used on marker
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var mapView: GMSMapView!
    var zoomLevel: Float = 11.5
    var allowedDistance: Double = 5000.0

    var sirenSoundEffect: AVAudioPlayer?
    var currentCircle: GMSCircle!

    @IBOutlet weak var stackViewBackground: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var distancePicker: UISegmentedControl!


    fileprivate func askForPermissionToTrackYourLocation() {
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.activityType = .fitness
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.requestAlwaysAuthorization()
        locationManager.distanceFilter = 10
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
    }

    fileprivate func drawMap() {
        // Do any additional setup after loading the view.
        mapView = nil

        // Create a GMSCameraPosition that tells the map to display the
        // coordinate -33.86,151.20 at zoom level 6.
        let camera = GMSCameraPosition.camera(withLatitude: myHomeLocation.latitude,
                                              longitude: myHomeLocation.longitude,
                                              zoom: zoomLevel)
        mapView = GMSMapView.map(withFrame: self.view.frame, camera: camera)
        mapView.settings.compassButton = true
        mapView.settings.myLocationButton = true
        mapView.isMyLocationEnabled = true

        self.stackViewBackground.layer.cornerRadius = 10

        self.view.addSubview(mapView)
        self.view.bringSubviewToFront(self.stackViewBackground)
        self.view.bringSubviewToFront(self.stackView)
        self.view.bringSubviewToFront(self.distancePicker)

        // Creates a marker in the center of the map.
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: myHomeLocation.latitude, longitude: myHomeLocation.longitude)
        marker.title = "Home"
        marker.snippet = "\(eircodeEntered)"
        marker.map = mapView

        // The myLocation attribute of the mapView may be null
        if let mylocation = mapView.myLocation {
            print("User's location: \(mylocation)")
        } else {
            print("User's location is unknown")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Inside The KM" 

        askForPermissionToTrackYourLocation()

        drawMap()

        addCircle()
        setUpTheAlarm()
    }

    @IBAction func trackingControlChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            locationManager.startUpdatingLocation()
        } else {
            stopTheAlarm()
            locationManager.stopUpdatingLocation()
        }
    }


    @IBAction func distanceChanged(_ sender: UISegmentedControl) {
        let picked = sender.selectedSegmentIndex

        switch picked {
        case 0:
            allowedDistance = 1000
            zoomLevel = 14
        case 1:
            allowedDistance = 2000
            zoomLevel = 13
        case 2:
            allowedDistance = 5000
            zoomLevel = 11.5
        case 3:
            allowedDistance = 10000
            zoomLevel = 10.5
        case 4:
            allowedDistance = 20000
            zoomLevel = 9.7
        default:
            print("Not handled this segment")
        }

        drawMap()
        addCircle()
    }


    func addCircle() {
        let circleCenter = CLLocationCoordinate2D(latitude: myHomeLocation.latitude, longitude: myHomeLocation.longitude)
        let circ = GMSCircle(position: circleCenter, radius: allowedDistance)
        circ.fillColor = UIColor(red: 1.0, green: 0, blue: 0, alpha: 0.25)
        circ.strokeColor = .red
        circ.strokeWidth = 2
        circ.map = mapView
    }

    func checkDistanceFromHome() {
        let homeLocation = CLLocation(latitude: CLLocationDegrees(myHomeLocation.latitude), longitude: CLLocationDegrees(myHomeLocation.longitude))
        if let distance = currentLocation?.distance(from: homeLocation) {
            print("Distance from home: \(distance)")
            if distance >  allowedDistance {
                showAlert()
                soundTheAlarm()
            }
        }
    }

    func showAlert() {
        // Set title, message and alert style
        let alertController = UIAlertController(title: "WARNING", message: "You in danger gurl!", preferredStyle: .alert)

        // You can add plural action.
        let okAction = UIAlertAction(title: "OK", style: .default) { action in
            print("OK action occured.")
            self.stopTheAlarm()
        }

        // Add the action.
        alertController.addAction(okAction)

        // Show alert
        present(alertController, animated: true, completion: nil)
    }

    func setUpTheAlarm() {

        // Access the shared, singleton audio session instance
        let session = AVAudioSession.sharedInstance()
        do {
            // Configure the audio session for movie playback
            try session.setCategory(AVAudioSession.Category.playback,
                                    mode: AVAudioSession.Mode.moviePlayback,
                                    options: [.mixWithOthers])
        } catch let error as NSError {
            print("Failed to set the audio session category and mode: \(error.localizedDescription)")
        }


        if let path = Bundle.main.path(forResource: "siren", ofType: "wav") {
            let url = URL(fileURLWithPath: path)

            do {
                sirenSoundEffect = try AVAudioPlayer(contentsOf: url)
            } catch let err {
                // couldn't load file :(
                print("Error: \(err.localizedDescription)")
            }
        } else {
            print("Missing sound file.")
        }

    }

    func soundTheAlarm() {
        sirenSoundEffect?.play()
    }

    func stopTheAlarm() {
        sirenSoundEffect?.stop()
    }
}

extension MapViewController: CLLocationManagerDelegate {

    // Handle incoming location events.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
      let location: CLLocation = locations.last!
      print("📍 Location Retrieved: \(location)")

      currentLocation = location

      checkDistanceFromHome()
    }

    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
      switch status {
      case .restricted:
        print("Location access was restricted.")
      case .denied:
        print("User denied access to location.")
      case .notDetermined:
        print("Location status not determined.")
      case .authorizedAlways: fallthrough
      case .authorizedWhenInUse:
        print("Location status is OK.")
      default:
        print("Unknown status \(status)")
      }

    }

    // Handle location manager errors.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
      locationManager.stopUpdatingLocation()
      print("Error: \(error)")
    }

}
