//
//  GeoCode.swift
//  InsideThe5K
//
//  Created by Cathal Farrell on 28/05/2020.
//  Copyright © 2020 Cathal Farrell. All rights reserved.
//

import Foundation

struct GeoCode: Codable {
    var results: [GeoPoint]
}

struct Location: Codable {
    var lat: Double
    var lng: Double
}

struct Geometry: Codable {
    var location: Location
}

struct GeoPoint: Codable {
    var geometry: Geometry
}
