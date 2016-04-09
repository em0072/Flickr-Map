//
//  PhotoViewController.swift
//  Flickr Map
//
//  Created by Митько Евгений on 08.04.16.
//  Copyright © 2016 Evgeny Mitko. All rights reserved.
//

import UIKit
import FlickrKit

class PhotoViewController: UIViewController, UIScrollViewDelegate {
    
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    //MARK: Properties
    var photo = UIImage()
    var photoDictionary = [String:AnyObject]()
    var titleOfPhoto = String()
    var placeOfPhoto = String()
    
    //MARK: View Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.scrollView.minimumZoomScale = 1.0
        self.scrollView.maximumZoomScale = 5.0
        imageView.image = photo
        getImage(photoDictionary)
        
        //Add Double Tap
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(PhotoViewController.doubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        self.view.addGestureRecognizer(doubleTap)
        
    }
    
    //MARK: ScrollView Delegates
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
    //MARK: Helper Methods
    
    // Downloads the image from Flickr
    func getImage(dict: [String: AnyObject]) {
        let url = fk.photoURLForSize(FKPhotoSizeLarge1024, fromPhotoDictionary: dict)
        let urlRequest = NSURLRequest(URL: url)
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config)
        let task = session.dataTaskWithRequest(urlRequest, completionHandler: {(data, response, error) in
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
    
    func doubleTap(tap: UITapGestureRecognizer) {
        if self.scrollView.zoomScale > 1 {
         self.scrollView.setZoomScale(1, animated: true)
        } else {
            self.scrollView.setZoomScale(4, animated: true)
        }
    }
    
    //MARK: IBActions
    @IBAction func dismissButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
