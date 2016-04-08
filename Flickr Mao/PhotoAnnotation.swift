//
//  PhotoAnnotation.swift
//  Flickr Map
//
//  Created by Митько Евгений on 08.04.16.
//  Copyright © 2016 Evgeny Mitko. All rights reserved.
//

import UIKit
import MapKit

class PhotoAnnotation: NSObject, MKAnnotation{

    let photoDict: [String:AnyObject]
    let title: String?
    let locationName: String
    let discipline: String
    let coordinate: CLLocationCoordinate2D
    //Retrieve an image
    var image: UIImage
    
    init(photoDict: [String:AnyObject], title: String, locationName: String, discipline: String, coordinate: CLLocationCoordinate2D, image: UIImage) {
        self.photoDict = photoDict
        self.title = title
        self.locationName = locationName
        self.discipline = discipline
        self.coordinate = coordinate
        self.image = image
        super.init()
    }
    
    var subtitle: String? {
        return locationName
    }
    
}
