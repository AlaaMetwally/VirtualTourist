//
//  FlickrConfig.swift
//  virtualTourist
//
//  Created by Geek on 3/30/19.
//  Copyright © 2019 Geek. All rights reserved.
//

import Foundation
import MapKit

class FlickrConfig {
    var longitude: Double
    var latitude: Double
    var coordinate: CLLocationCoordinate2D
    var methodParameters = [
        Constants.FlickrParametersKeys.APIKey : Constants.FlickrParametersValues.APIKey,
        Constants.FlickrParametersKeys.Extras : Constants.FlickrParametersValues.Extras,
        Constants.FlickrParametersKeys.Format : Constants.FlickrParametersValues.Format,
        Constants.FlickrParametersKeys.Method : Constants.FlickrParametersValues.Method,
        Constants.FlickrParametersKeys.NoJsonCallBack : Constants.FlickrParametersValues.NoJsonCallBack,
        Constants.FlickrParametersKeys.UserId : Constants.FlickrParametersValues.UserId,
        Constants.FlickrParametersKeys.SafeSearch : Constants.FlickrParametersValues.SafeSearch
        ] as [String : Any]
    
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
        var coordinate: CLLocationCoordinate2D {
            get {
                let coordinate = CLLocationCoordinate2DMake(latitude as CLLocationDegrees, longitude as CLLocationDegrees)
                return coordinate
            }
        }
        self.coordinate = coordinate
    }
 
    func getBbox(latitude: Double,longitude: Double) -> String{
        if longitude != nil && latitude != nil{
            let minimumLon = max(longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
            let minimumLat = max(latitude - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
            let maximumLon = min(longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
            let maximumLat = min(latitude + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
            return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
        }
        else{
            return "0,0,0,0"
        }
    }
    
    func flickrURL() -> URL{
        var components = URLComponents()
        methodParameters[Constants.FlickrParametersKeys.BBox ] = getBbox(latitude: latitude,longitude: longitude)
        
        components.host = Constants.Flickr.APIHost
        components.scheme = Constants.Flickr.APIScheme
        components.path = Constants.Flickr.APIPath
        
        components.queryItems =  [URLQueryItem]()
        
        for (key, value) in methodParameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
}
