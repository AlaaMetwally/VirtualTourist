//
//  Constants.swift
//  virtualTourist
//
//  Created by Geek on 3/30/19.
//  Copyright © 2019 Geek. All rights reserved.
//

import Foundation

struct Constants {
    struct Flickr{
        static let APIScheme = "https"
        static let APIHost = "api.flickr.com"
        static let APIPath = "/services/rest"
        
        static let SearchBBoxHalfWidth = 1.0
        static let SearchBBoxHalfHeight = 1.0
        static let SearchLatRange = (-90.0, 90.0)
        static let SearchLonRange = (-180.0, 180.0)
    }
    
    struct FlickrParametersKeys{
        static let Method = "method"
        static let APIKey = "api_key"
        static let BBox = "bbox"
        static let Extras = "extras"
        static let Format = "format"
        static let SafeSearch = "safe_search"
        static let NoJsonCallBack = "nojsoncallback"
        static let UserId = "user_id"
        static let Text = "text"
        static let Page = "page"
    }
    
    struct FlickrParametersValues{
        static let Method = "flickr.photos.search"
        static let APIKey = "9287218e802461657d69bc1a26c5c7d6"
        static let Extras = "url_m"
        static let Format = "json"
        static let SafeSearch = 1
        static let NoJsonCallBack = 1
        static let UserId = "170749678@N08"
    }
    
    struct FlickrResponseKeys {
        static let Title = "title"
        static let Pages = "pages"
        static let Photo = "photo"
        static let Photos = "photos"
        static let Total = "total"
        static let MediumURL = "url_m"
        static let Status = "stat"
    }
    
    struct FlickrResponseValues {
        static let OkStatus = "OK"
    }
}
