//
//  PhotoViewController.swift
//  Flickr Map
//
//  Created by Митько Евгений on 08.04.16.
//  Copyright © 2016 Evgeny Mitko. All rights reserved.
//

import UIKit
import FlickrKit

class PhotoViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!

    var photo = UIImage()
    var photoDictionary = [String:AnyObject]()
    var titleOfPhoto = String()
    var placeOfPhoto = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = photo
        
        getImage(photoDictionary)
        
        
        
    }
    
    
    func getImage(dict: [String: AnyObject]) {
        let url = fk.photoURLForSize(FKPhotoSizeLarge1024, fromPhotoDictionary: dict)
        let urlRequest = NSURLRequest(URL: url)
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config)
        
        let task = session.dataTaskWithRequest(urlRequest, completionHandler: {(data, response, error) in
            //        FKDUDefaultDiskCache.sharedDiskCache().storeData(data, forKey: key)
            
            
            var photoData = NSData()
            if (data != nil) && (response != nil)  {
                photoData = data!
                cache.setObject(data, forKey: "\(self.photoDictionary["id"] as! String)_dataBig")
            } else if error != nil {
                print(error?.userInfo)
                if let data = cache.objectForKey("\(self.photoDictionary["id"] as! String)_dataBig") {
                    photoData = data as! NSData
                } else {
                   photoData = UIImageJPEGRepresentation(self.photo, 1)!
                }
            }

            dispatch_async(dispatch_get_main_queue(), {
                self.imageView.image = UIImage(data: photoData)!
            })
        })
        
        task.resume()
        
    }
    
    @IBAction func dismissButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
