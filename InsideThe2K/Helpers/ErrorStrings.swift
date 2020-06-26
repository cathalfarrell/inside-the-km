//
//  ErrorStrings.swift
//  InsideThe5K
//
//  Created by Cathal Farrell on 28/05/2020.
//  Copyright © 2020 Cathal Farrell. All rights reserved.
//

import Foundation

enum ErrorString: String {
    case networkError = "Something went wrong - please try again later."
    case badEirCode = "Sorry but your location could not be determined with that Eircode."
    case failedToParse = "Oops something went wrong - please try again later."
}
