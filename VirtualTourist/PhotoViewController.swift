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
	var pin:Pin?
	var photoURLs:[String:NSDate]?
	@IBOutlet weak var newCollection: UIButton!
	@IBOutlet weak var photoCollectionView: UICollectionView!
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var noPhotosLabel: UILabel!
	private var selectedPhotos:[NSIndexPath]?
	private var isFetchingData = false
	private var photosFilePath: String {
		return NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first!
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()

		mapView.userInteractionEnabled = false
		
		photoCollectionView.backgroundColor = UIColor.whiteColor()
		photoCollectionView.delegate = self
		photoCollectionView.dataSource = self
		photoCollectionView.allowsMultipleSelection = true
		
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
		
		loadfetchedResultsController()
		
		//array for selected items -- used to alleviate reusable cells being selected
		selectedPhotos = [NSIndexPath]()
    }
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		noPhotosLabel.hidden = true
		
		if pin?.photos?.count <= 0 {
			newCollection.enabled = false
			getPhotos()
		}
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	
	override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
		
		//set region
		if let pin = pin {
			let latitude = pin.latitude as! CLLocationDegrees
			let longitude = pin.longitude as! CLLocationDegrees
			let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
			let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
			mapView.setRegion(region, animated: true)
		}
	}
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		
		let width = CGRectGetWidth(view.frame) / 3
		let layout = photoCollectionView.collectionViewLayout as! UICollectionViewFlowLayout
		layout.itemSize = CGSize(width: width - 1, height: width - 1)
		
	}
	
	//MARK: - Shared Context
	lazy var sharedContext: NSManagedObjectContext = {
		CoreDataStack.sharedInstance.managedObjectContext
	}()
	
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
		let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
		
		return fetchedResultsController
		
	}()
	
	func loadfetchedResultsController() {
		fetchedResultsController.delegate = self
		
		//get results from the fetchedResultsController
		do {
			try self.fetchedResultsController.performFetch()
		} catch {
			let fetchError = error as NSError
			print("\(fetchError), \(fetchError.userInfo)")
			self.alertUI(withTitle: "Failed Query", message: "Failed to load photos")
		}
	}
	
	//MARK: Functions
	
	@IBAction func photoAction(sender: UIButton) {
		if selectedPhotos?.count > 0 {
			photoCollectionView.performBatchUpdates({ () -> Void in
				for indexPath in (self.selectedPhotos?.sort({ $0.item > $1.item}))! {
					self.removePhotosFromPin(indexPath)
				}
				
				}, completion: { (completed) -> Void in
					performUIUpdatesOnMain({ () -> Void in
						self.photoCollectionView.deleteItemsAtIndexPaths(self.selectedPhotos!)
						self.selectedPhotos?.removeAll()
						self.newCollection.setTitle("New Collection", forState: .Normal)
					})
			})
		} else {
			newCollection.enabled = false
			
			photoCollectionView.performBatchUpdates({ () -> Void in
				if let pin = self.pin, let _ = pin.photos {
					self.isFetchingData = true
					for photo in self.fetchedResultsController.fetchedObjects as! [Photo] {
						self.sharedContext.deleteObject(photo)
					}
					
					CoreDataStack.sharedInstance.saveMainContext()
					
				}
				}, completion: { (completed) -> Void in
					self.isFetchingData = false
					self.getPhotos()
			})
		}
	}
	
	func removePhotosFromPin(indexPath:NSIndexPath) {
		handleManagedObjectContextOperations { () -> Void in
			let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
			self.sharedContext.deleteObject(photo)
			CoreDataStack.sharedInstance.saveMainContext()
		}
	}

	func alertUI(withTitle title:String, message:String) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
		let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
		alert.addAction(action)
		presentViewController(alert, animated: true, completion: nil)
	}
	
	//MARK: - Get Photos from Flickr
	func getPhotos(fromCache cache:Bool = false) {
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
						
						if self.photoURLs!.keys.count > 0 {
							handleManagedObjectContextOperations({ () -> Void in
								for urlString in self.photoURLs!.keys {
									
									if let photoFileName = urlString.componentsSeparatedByString("/").last {
										
										let photo = Photo(context: self.sharedContext)
										photo.imageUrl = urlString
										photo.dateTaken = self.photoURLs![urlString]!
										photo.pin = self.pin!
										photo.imageLocation = photoFileName
										CoreDataStack.sharedInstance.saveMainContext()
									}
								}
								
								//performUIUpdatesOnMain({ () -> Void in
								self.photoCollectionView.hidden = false
								self.newCollection.enabled = true
								
							})
							
						} else {
							performUIUpdatesOnMain({ () -> Void in
								self.photoCollectionView.hidden = true
								self.newCollection.enabled = true
								self.noPhotosLabel.hidden = false
								
							})
						}
					}
				}
			}
		}
	}
}

extension PhotoViewController : UICollectionViewDelegate {
	func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
		
		return true
	}
	
	func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
		if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? PhotoViewCell {
			cell.selected = true
			selectedPhotos?.append(indexPath)
			newCollection.setTitle("Remove Selected Pictures", forState: .Normal)
			configure(cell, forRowAtIndexPath: indexPath)
		}
	}
	
	func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
		if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? PhotoViewCell {
			cell.selected = false
			if let indexToRemove = selectedPhotos?.indexOf(indexPath) {
				selectedPhotos?.removeAtIndex(indexToRemove)
			}
			
			if selectedPhotos?.count == 0 {
				newCollection.setTitle("New Collection", forState: .Normal)
			}
			
			configure(cell, forRowAtIndexPath: indexPath)
		}
	}
}

extension PhotoViewController : UICollectionViewDataSource {
	func configure(cell: PhotoViewCell, forRowAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		if let indexSet = selectedPhotos {
			if indexSet.contains(indexPath) {
				if cell.photoCellImageView.alpha == 1.0 {
					performUIUpdatesOnMain({ () -> Void in
						cell.photoCellImageView.alpha = 0.5
					})
				}
			} else {
				performUIUpdatesOnMain({ () -> Void in
					cell.photoCellImageView.alpha = 1.0
				})
			}
		}
		
		return cell
	}
	
	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		if let sectionInfo = fetchedResultsController.sections {
			return sectionInfo[section].numberOfObjects
		} else {
			return 0
		}
	}
	
	func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
		
		return 1
	}
	
	func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier("photoCell", forIndexPath: indexPath) as! PhotoViewCell
		
		let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
		
		let imageLocation = photo.imageLocation!
		
		if NSFileManager.defaultManager().fileExistsAtPath(NSURL(string: self.photosFilePath)!.URLByAppendingPathComponent(imageLocation).path!) {
			cell.photoCellImageView.image = UIImage(contentsOfFile: NSURL(string: self.photosFilePath)!.URLByAppendingPathComponent(imageLocation).path!)
			cell.loadingView.hidden = true
		} else {
			//if the file does not exist download it from the Internet and save it
			if let imageURL = NSURL(string: photo.imageUrl) {
				performDownloadsAndUpdateInBackground({ () -> Void in
					if let imageData = NSData(contentsOfURL: imageURL) {
						//save file
						imageData.writeToFile(NSURL(string: self.photosFilePath)!.URLByAppendingPathComponent(imageURL.lastPathComponent!).path!, atomically: true)
						
						performUIUpdatesOnMain({ () -> Void in
							cell.photoCellImageView.image = UIImage(data: imageData)
							cell.loadingView.hidden = true
						})
					}
				})
			}
		}
		
		return configure(cell, forRowAtIndexPath: indexPath)
	}
}

extension PhotoViewController : NSFetchedResultsControllerDelegate {
	func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
		switch type {
		case .Delete:
			if isFetchingData {
				photoCollectionView.reloadData()
			}
			break
			
		case .Insert:
			photoCollectionView.reloadData()
			break
			
		default:
			return
		}
	}
}
