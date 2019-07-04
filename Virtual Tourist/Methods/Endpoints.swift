//
//  Endpoints.swift
//  Virtual Tourist
//
//  Created by Tucker on 6/25/19.
//  Copyright © 2019 Tucker. All rights reserved.
//


//TODO build URLS
import Foundation
import UIKit

let apiKey = "71a88fffbe917745364c199abcecebaf"


struct FlickrSearchEndpoint {
    static let scheme = "https"
    static let host = "www.flickr.com"
    static let path = "/services/rest"
    static let method = "flickr.photos.search"
}



// MARK: - Pictures
struct Pictures: Codable {
    var photos: Photos
    let stat: String
}

// MARK: - Photos
struct Photos: Codable {
    let page, pages, perpage: Int
    let total: String
    var long: Double?
    var lat: Double?
    var photo: [PhotoInfo]
}

// MARK: - Photo
struct PhotoInfo: Codable {
    let id: String
    let owner: String
    let secret, server: String
    let farm: Int
    let title: String?
    let ispublic, isfriend, isfamily: Int?
}


func buildUrl(lat:Double,long:Double,pageNumber:Int) -> URLComponents{

    var components = URLComponents()
    components.scheme = FlickrSearchEndpoint.scheme
    components.host = FlickrSearchEndpoint.host
    components.path = FlickrSearchEndpoint.path
    components.queryItems = [
        URLQueryItem(name: "method", value: FlickrSearchEndpoint.method),
        URLQueryItem(name: "api_key", value: apiKey),
        URLQueryItem(name: "lat", value: String(format: "%.0f", lat)),
        URLQueryItem(name: "lon", value: String(format: "%.0f", long)),
        URLQueryItem(name: "geo_context", value: "2"),
        URLQueryItem(name: "radius", value: "5"),
        URLQueryItem(name: "radius_units", value: "mi"),
        URLQueryItem(name: "per_page", value: "20"),
        URLQueryItem(name: "page",value: String(pageNumber)),
        URLQueryItem(name: "format", value: "json"),
        URLQueryItem(name: "nojsoncallback", value: "1")
        
    ]
    return components
}


func buildImageUrlV2(server:String,id:String,secret:String,farm:Int) -> URLComponents{
    var components = URLComponents()
    let farmid = String(farm)
    components.scheme = FlickrSearchEndpoint.scheme
    components.host = "farm\(farmid).staticflickr.com"
    components.path = "/\(server)/\(id)_\(secret).png"
    return components
}
