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
	
	@IBOutlet weak var newCollection: UIButton!
	@IBOutlet weak var photoCollectionView: UICollectionView!
	@IBOutlet weak var mapView: MKMapView!
	
	@IBOutlet weak var noPhotosLabel: UILabel!
	private var selectedPhotos:[NSIndexPath]?
	private var isFetchingData = false
	
    override func viewDidLoad() {
        super.viewDidLoad()

		mapView.userInteractionEnabled = false
		
		photoCollectionView.backgroundColor = UIColor.whiteColor()
		photoCollectionView.delegate = self
		photoCollectionView.dataSource = self
		photoCollectionView.allowsMultipleSelection = true
		
		fetchedResultsController.delegate = self
		
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
		if let pin = self.pin {
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
	
	func loadfetchedResultsController() {
		//get results from the fetchedResultsController
		do {
			try fetchedResultsController.performFetch()
		} catch {
			let fetchError = error as NSError
			print("\(fetchError), \(fetchError.userInfo)")
			alertUI(withTitle: "Failed Query", message: "Failed to load photos")
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
						self.newCollection.setTitle("New Collection", forState: .Normal)
					})
			})
		} else {
			newCollection.enabled = false
			
			if let pin = self.pin, let _ = pin.photos {
				isFetchingData = true
				for photo in fetchedResultsController.fetchedObjects as! [Photo] {
					photo.pin = nil
					coreDataStack.saveMainContext()
				}
				isFetchingData = false
			}
			
			getPhotos()
		}
	}
	
	func removePhotosFromPin(indexPath:NSIndexPath) {
		let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
		photo.pin = nil
		self.coreDataStack.saveMainContext()
		
		if let indexToRemove = self.selectedPhotos?.indexOf(indexPath) {
			self.selectedPhotos?.removeAtIndex(indexToRemove)
		}
	}

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
							
							if self.photoURLs?.keys.count > FlickrClient.Constants.UIConstants.MaxPhotoCount {
								//get random indexes
								var photoIndexes = Set<Int>()
								
								let count = self.photoURLs?.keys.count
						
								repeat {
									photoIndexes.insert(Int(arc4random_uniform(UInt32(count!))))
									
								} while photoIndexes.count < FlickrClient.Constants.UIConstants.MaxPhotoCount
								
								let urls = Array(self.photoURLs!.keys)

								for index in photoIndexes {

									performUIUpdatesOnMain({ () -> Void in
										let photo = Photo(context: self.coreDataStack.managedObjectContext)
										photo.dateTaken = self.photoURLs![urls[index]]!
										photo.imageUrl = urls[index]
										photo.pin = self.pin!
										self.coreDataStack.saveMainContext()
									})
								}
								
								//save context
								performUIUpdatesOnMain({ () -> Void in
									self.photoCollectionView.hidden = false
									self.newCollection.enabled = true
									self.coreDataStack.saveMainContext()
								})
								
							} else {
								if self.photoURLs!.keys.count > 0 {
									//just get the images from the url
									for urlString in self.photoURLs!.keys {
										performUIUpdatesOnMain({ () -> Void in
											let photo = Photo(context: self.coreDataStack.managedObjectContext)
											photo.imageUrl = urlString
											photo.dateTaken = self.photoURLs![urlString]!
											photo.pin = self.pin!
											self.coreDataStack.saveMainContext()
										})
									}
									
									//save context
									performUIUpdatesOnMain({ () -> Void in
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
					cell.photoCellImageView.alpha = 0.5
				}
			} else {
				cell.photoCellImageView.alpha = 1.0
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
		
		if let image = photo.image {
			cell.loadingView.hidden = true
			
			//put the image in the cell
			cell.photoCellImageView.image = image
		} else {
			//show activity indicator view
			performDownloadsAndUpdateInBackground({ () -> Void in
				if let url = NSURL(string: photo.imageUrl) {
					if let imageData = NSData(contentsOfURL: url) {
						let image = UIImage(data: imageData)
						performUIUpdatesOnMain({ () -> Void in
							photo.image = image
							cell.loadingView.hidden = true
							self.coreDataStack.saveMainContext()
							cell.photoCellImageView.image = image
						})
					}
				}
			})
		}
		
		return configure(cell, forRowAtIndexPath: indexPath)
		
	}
}

extension PhotoViewController : NSFetchedResultsControllerDelegate {
	func controllerDidChangeContent(controller: NSFetchedResultsController) {
		photoCollectionView.reloadData()
	}
	
	func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
		switch type {
		case .Delete:
			if isFetchingData {
				photoCollectionView.reloadData()
			} else {
				photoCollectionView.deleteItemsAtIndexPaths(Array(arrayLiteral: indexPath!))
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
