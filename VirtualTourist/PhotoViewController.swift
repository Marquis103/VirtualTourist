//
//  PhotoViewController.swift
//  VirtualTourist
//
//  Created by Marquis Dennis on 2/22/16.
//  Copyright © 2016 Marquis Dennis. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoViewController: UIViewController {
	private let mapHeight:CGFloat = 0.35
	var coreDataStack:CoreDataStack!
	var pin:Pin?
	
	@IBOutlet weak var mapView: MKMapView!
	
    override func viewDidLoad() {
        super.viewDidLoad()

		//set mapheight to 12% of view
		//mapView.frame.size.height = mapHeight * view.bounds.height
		mapView.userInteractionEnabled = false
		//set region
		if let pin = self.pin {
			let latitude = pin.latitude as! CLLocationDegrees
			let longitude = pin.longitude as! CLLocationDegrees
			let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
			let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
			mapView.setRegion(region, animated: true)
			
			//drop annotation at pin
			let marker = MKPointAnnotation()
			marker.coordinate = center
			mapView.addAnnotation(marker)
		}
    }
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		getPhotos(fromCache: false)
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
		mapView.frame.size.height = mapHeight * view.bounds.height
	}
	
	//MARK: Functions
	//get data out of the managed object context
	func alertUI(withTitle title:String, message:String) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
		let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
		alert.addAction(action)
		presentViewController(alert, animated: true, completion: nil)
	}
	
	func getPhotos(fromCache cache:Bool = false) {
		if cache {
			
		} else {
			FlickrClient.sharedClient.getPhotosByLocation(using: pin!) { (result, error) -> Void in
				guard error == nil else {
					self.alertUI(withTitle: "Failed Query", message: "Could not retrieve images for this pin location")
					return
				}
				
				if let photos = result {
					if let photosDict = photos["photos"] as? [String:AnyObject] {
						if let photosDesc = photosDict["photo"] as? [[String:AnyObject]] {
							for (_, photoItem) in photosDesc.enumerate() {
								if let photoURL = photoItem["url_m"] as? String {
									print(photoURL)
								}
							}
						}
					}
				}
			}
		}
	}

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
