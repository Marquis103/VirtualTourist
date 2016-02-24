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
	var photoURLs:[String:NSDate]?
	
	@IBOutlet weak var mapView: MKMapView!
	
    override func viewDidLoad() {
        super.viewDidLoad()

		//set mapheight to % of view height
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
		
		//get results from the fetchedResultsController
		do {
			try fetchedResultsController.performFetch()
		} catch {
			let fetchError = error as NSError
			print("\(fetchError), \(fetchError.userInfo)")
			alertUI(withTitle: "Failed Query", message: "Failed to load photos")
		}
    }
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		var objectCount = 0
		
		if let sections = fetchedResultsController.sections {
			objectCount = sections.count
		}
		
		
		//if there are objects in the fetched results controller display those images
		if objectCount == 0 {
			
			getPhotos()
		}
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
		mapView.frame.size.height = mapHeight * view.bounds.height
	}
	
	//MARK: NSFetchedResultsController
	lazy var fetchedResultsController : NSFetchedResultsController = {
		//create the fetch request
		let fetchRequest = NSFetchRequest(entityName: "Photo")
		
		//add a sort descriptor, enforces a sort order on the results
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateTaken", ascending: false)]
		
		//add a predicate to only get photos for the specified pin
		if let latitude = self.pin?.latitude, let longitude = self.pin?.longitude {
			let predicate = NSPredicate(format: "(pin.latitude == %@) AND (pin.longitude == %@)", latitude, longitude)
			fetchRequest.predicate = predicate
		}
		
		//create fetched results controller
		let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.coreDataStack.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
		
		return fetchedResultsController
		
	}()
	
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
							self.photoURLs = [String:NSDate]()
							let dateFormatter = NSDateFormatter()
							dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
							for (_, photoItem) in photosDesc.enumerate() {
								if let photoURL = photoItem["url_m"] as? String, let dateTaken = photoItem["datetaken"] as? String {
									//photo urls of images to be downloaded
									self.photoURLs![photoURL] = dateFormatter.dateFromString(dateTaken)
								}
							}
							
							//push downloading of images to global background queue (GCDBlackBox.swift)
							performDownloadsAndUpdateInBackground({ () -> Void in
								if self.photoURLs?.keys.count > FlickrClient.Constants.UIConstants.MaxPhotoCount {
									//get random indexes
									var photoIndexes = Set<Int>()
									
									let count = self.photoURLs?.keys.count
									
									//get random indexes
									repeat {
										photoIndexes.insert(Int(arc4random_uniform(UInt32(count! + 1))))
										
									} while photoIndexes.count < FlickrClient.Constants.UIConstants.MaxPhotoCount
									
									
									let urls = Array(self.photoURLs!.keys)
									
									for index in photoIndexes {
										if let url = NSURL(string: urls[index]) {
											if let imageData = NSData(contentsOfURL: url) {
												let image = UIImage(data: imageData)
												performUIUpdatesOnMain({ () -> Void in
													let photo = Photo(context: self.coreDataStack.managedObjectContext)
													photo.image = image!
													photo.dateTaken = self.photoURLs![urls[index]]!
													photo.pin = self.pin!
												})
											}
										}
									}
								} else {
									//just get the images from the url
									for urlString in self.photoURLs!.keys {
										if let url = NSURL(string: urlString) {
											if let imageData = NSData(contentsOfURL: url) {
												let image = UIImage(data: imageData)
												performUIUpdatesOnMain({ () -> Void in
													let photo = Photo(context: self.coreDataStack.managedObjectContext)
													photo.image = image!
													photo.dateTaken = self.photoURLs![urlString]!
													photo.pin = self.pin!
												})
											}
										}
									}
								}
							})
							
							//save context
							self.coreDataStack.saveMainContext()
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
