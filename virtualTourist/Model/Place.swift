//
//  Place.swift
//  virtualTourist
//
//  Created by Geek on 3/31/19.
//  Copyright © 2019 Geek. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class Place: Equatable{
    static func == (lhs: Place, rhs: Place) -> Bool {
        if (rhs.image == lhs.image){
            return true
        }
        return false
    }
    
    var title: String = ""
    var image: String = ""
    var coordinates: CLLocationCoordinate2D?

    init(title: String, image: String, coordinates: CLLocationCoordinate2D) {
        self.title = title
        self.image = image
        self.coordinates = coordinates
    }

}
