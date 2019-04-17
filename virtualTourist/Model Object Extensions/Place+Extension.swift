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
import CoreData

extension Place{
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        creationDate = Date()
    }
    
    static func == (lhs: Place, rhs: Place) -> Bool {
        if (rhs.image == lhs.image){
            return true
        }
        return false
    }
}
