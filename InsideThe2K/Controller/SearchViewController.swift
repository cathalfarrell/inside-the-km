//
//  SearchViewController.swift
//  InsideThe2K
//
//  Created by Cathal Farrell on 29/03/2020.
//  Copyright © 2020 Cathal Farrell. All rights reserved.
//

import UIKit
import Alamofire
import CoreLocation

let baseUrl = "https://maps.googleapis.com/maps/api/geocode/json?address="
let apiKey = "<YOUR MAP API KEY>"

class SearchViewController: UIViewController {

    @IBOutlet weak var eircodeTextField: UITextField!
    @IBOutlet weak var textLabel: UILabel!

    var eircodeEntered = ""
    var myLocation: CLLocationCoordinate2D!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Eircode"

        // Do any additional setup after loading the view.
    }
    
    @IBAction func searchTapped(_ sender: Any) {

        guard let eircode = eircodeTextField.text, !eircode.isEmpty else { return }
        print("Eircode: \(eircode)")
        eircodeEntered = eircode

        let cleanedEircode = eircode.replacingOccurrences(of: " ", with: "")

        var urlString = baseUrl
        urlString += cleanedEircode
        urlString += "+IRELAND&key="
        urlString += apiKey

        fetchData(for: urlString)
    }

    fileprivate func pushToMapVC() {
        //Push new view onto stack
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let mapVC = storyboard.instantiateViewController(withIdentifier: "MapViewController")
            as? MapViewController {
            mapVC.myHomeLocation = self.myLocation
            mapVC.eircodeEntered = self.eircodeEntered
            self.navigationController?.pushViewController(mapVC, animated: true)
        }
    }

    func fetchData(for url: String) {

        print("🔥 Getting gps from eircode: \(url)..")

        AF.request(url).responseJSON { (response) in
            if let error = response.error {
                print("Error: \(error)")
                self.updateText(with: "\(ErrorString.networkError.rawValue) - \(error.localizedDescription)")
            } else {

                guard let data = response.data else {return}
                print("Data: \(data)")

                if let decodedResponse = try? JSONDecoder().decode(GeoCode.self, from: data) {
                    // we have good data – go back to the main thread
                    DispatchQueue.main.async {
                        // update our UI

                        print("Response: \(decodedResponse)")
                        guard let geoCode = decodedResponse.results.first else {
                            print("No results found")
                            return
                        }
                        let lat = geoCode.geometry.location.lat
                        let long = geoCode.geometry.location.lng
                        self.myLocation = CLLocationCoordinate2D(latitude: CLLocationDegrees(lat), longitude: CLLocationDegrees(long))

                        print("📍Coordinates: \(String(describing: self.myLocation))")
                        self.pushToMapVC()
                    }

                    // everything is good, so we can exit
                    return
                } else {
                    print("We could not parse the data")
                    self.updateText(with: ErrorString.failedToParse.rawValue)
                }
            }
        }
    }

    func updateText(with string: String) {
        self.textLabel.text = string
    }
}
