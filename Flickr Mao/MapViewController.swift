//
//  MapViewController.swift
//  Flickr Map
//
//  Created by Митько Евгений on 08.04.16.
//  Copyright © 2016 Evgeny Mitko. All rights reserved.
//

import UIKit
import MapKit
import FlickrKit
import SAMCache

class MapViewController: UIViewController, MKMapViewDelegate, UITextFieldDelegate {

    var numberOfPhotos = 50
    var numberOfLoadedPhotos = 0
    var photoArray = [[String : AnyObject]]() {
        didSet {
            for item in photoArray {
                createAnnotations(item)
            }
//            print("this is map data - \(self.photoArray)")
//            self.placeAnnotations()
        }
    }
    var annotationsArray = [PhotoAnnotation]()
    var photoToPass: UIImage?
    var titleToPass = String()
    var placeToPass = String()
    var dictToPass = [String:AnyObject]()

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let photoArrayChache = cache.objectForKey("photoArray") {
            self.photoArray = photoArrayChache as! [[String:AnyObject]]
        }
        // set initial location in Moscow
        let initialLocation = CLLocation(latitude: 55.745827, longitude: 37.612153)
        mapView.setCenterCoordinate(initialLocation.coordinate, animated: true)

        
        
        
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if searchField.text?.characters.count > 0 {
            let searchKey = searchField.text!
            self.mapView.removeAnnotations(annotationsArray)
            getFlickrPhotosForSearchKey(searchKey)
        }
        self.view.endEditing(true)
        return true
    }
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
    func createAnnotations(photoDictionary: [String : AnyObject]) {
        let url = fk.photoURLForSize(FKPhotoSizeSmall320, fromPhotoDictionary: photoDictionary)
        let urlRequest = NSURLRequest(URL: url)
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config)
        
        let task = session.dataTaskWithRequest(urlRequest, completionHandler: {(data, response, error) in
            
            var photoData = NSData()
            if (data != nil) && (response != nil)  {
                photoData = data!
                cache.setObject(data, forKey: "\(photoDictionary["id"] as! String)_data")
            } else if error != nil {
                print(error?.userInfo)
                photoData = cache.objectForKey("\(photoDictionary["id"] as! String)_data") as! NSData
            }
            dispatch_async(dispatch_get_main_queue(), {
                
                
                let search = FKFlickrPhotosGeoGetLocation()
                search.photo_id = photoDictionary["id"] as! String
                var location = [String:AnyObject]()
                    fk.call(search) { (result, error) in
                    if (result != nil) {
                        location = result["photo"]!["location"] as! [String : AnyObject]
                        cache.setObject(location, forKey: "\(photoDictionary["id"] as! String)_location")
                        
                    } else {
                        if let locationDict = cache.objectForKey("\(photoDictionary["id"] as! String)_location") {
                            location = locationDict as! [String:AnyObject]
                        }
                        print("no location")
                    }
                        dispatch_async(dispatch_get_main_queue(), {
                        let annotation = PhotoAnnotation(photoDict: photoDictionary, title: photoDictionary["title"] as! String,
                                                    locationName: self.getPlaceName(location), //location["locality"]!["content"] as! String,
                                                    discipline: "Sculpture",
                                                    coordinate: CLLocationCoordinate2D(latitude: Double(location["latitude"] as! String)!, longitude: Double(location["longitude"] as! String)!),
                                                    image: UIImage(data: data!)!)
                        
                        
                                                        self.annotationsArray.append(annotation)
                            
                            self.mapView.addAnnotation(annotation)
                          self.numberOfLoadedPhotos += 1
                            if self.numberOfLoadedPhotos == self.numberOfPhotos {
                                //stopLoad
                            }
                        })

                }
            })
        })
        task.resume()
    }
    
    func createAnnotationItem(){
        
    }
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        
        let pin = annotation as! PhotoAnnotation
        
        let identifier = "Pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
        if pinView == nil{
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            pinView?.canShowCallout = true
        }else{
            pinView?.annotation = annotation
        }
        
//        pinView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        
//        pinView!.canShowCallout = true
//        pinView!.image = nil
        pinView!.detailCalloutAccessoryView = UIImageView(image: pin.image)
        let btn = UIButton(type: .DetailDisclosure)
        pinView!.rightCalloutAccessoryView = btn
        return pinView

       
    }
    
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let annotation = view.annotation as! PhotoAnnotation
        photoToPass = annotation.image
        dictToPass = annotation.photoDict
        titleToPass = annotation.title!
        placeToPass = annotation.locationName
        performSegueWithIdentifier("showPhoto", sender: self)
    }

    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showPhoto" {
            let vc = segue.destinationViewController as! PhotoViewController
            if let photo = photoToPass {
                vc.photo = photo
                vc.photoDictionary = dictToPass
            }
        }
    }
    
    
    
    //This method Checks if there is a country and/or place name in 'location' dictionary and constructs a String
    func getPlaceName(locationDict: [String : AnyObject]) -> String {
        var city = ""
        var place = ""
        var resultName = String()
        if let cityName = locationDict["locality"] {
            city = cityName["_content"] as! String
        }
        if let placeName = locationDict["neighbourhood"] {
            place = placeName["_content"] as! String
        }
        if city != "" {
            if place != "" {
                resultName = "\(city), \(place)"
            } else {
                resultName = city
            }
        } else {
            if place != "" {
                resultName = place
            }
        }
        return resultName
    }
    
    
    //This method constructs a search request and assign 'result' to 'photoArray' property
    func getFlickrPhotosForSearchKey (searchKey: String) {
        let search = FKFlickrPhotosSearch()
        search.text = searchKey
        search.geo_context = "0"
        search.per_page = "\(numberOfPhotos)"
        fk.call(search) { (responce, error) in
            if responce != nil {
                self.photoArray = responce!["photos"]!["photo"] as! [[String : AnyObject]]
                cache.setObject(self.photoArray, forKey: "photoArray")
            } else {
                let noConnectionView = UIView(frame: CGRect(x: 0, y: -20, width: UIScreen.mainScreen().bounds.size.width, height: 20))
                noConnectionView.backgroundColor = UIColor.redColor()
                self.view.bringSubviewToFront(noConnectionView)
                
                self.view.addSubview(noConnectionView)
                
                UIView.animateWithDuration(1, animations: { 
                    noConnectionView.layer.position.y += noConnectionView.frame.size.height
                })

                let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(5 * Double(NSEC_PER_SEC)))
                dispatch_after(delayTime, dispatch_get_main_queue()) {
                    UIView.animateWithDuration(1, animations: {
                        noConnectionView.layer.position.y -= noConnectionView.frame.size.height
                    })
                }

                print("ERROR - \(error.userInfo)")
            }
        }
        
    }

    
    
}