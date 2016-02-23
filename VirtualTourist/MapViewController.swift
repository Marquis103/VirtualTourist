//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Marquis Dennis on 2/21/16.
//  Copyright © 2016 Marquis Dennis. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {

	@IBOutlet weak var mapView: MKMapView!
	
	@IBOutlet weak var editButton: UIBarButtonItem!
	var mapSettings =  [String:AnyObject]()
	var deleteButton:UIButton!
	var isMapEditing = false
	var buttonHeight:CGFloat = 0.0
	var coreDataStack:CoreDataStack!
	
	var mapSettingsPath: String {
		let manager = NSFileManager.defaultManager()
		let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
		
		return url.URLByAppendingPathComponent("mapset").path!
	}
	
	/*lazy var fetchedResultsController:NSFetchedResultsController = {
		//create the fetch request
		let fetchRequest = NSFetchRequest(entityName: "Pin")
		
		//create the fetched results controller
		let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataStack.sharedInstance.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
		
		return fetchedResultsController
	}()*/
	
	@IBAction func editPins(sender: UIBarButtonItem) {
		isMapEditing = !isMapEditing
		
		if isMapEditing {
			editButton.title = "Done"
			adjustMapHeight(true)
		} else {
			editButton.title = "Edit"
			adjustMapHeight(false)
		}
	}
	
	//percentage of height for delete button in any orientation
	var buttonHeightConstant:CGFloat = 0.096
	
	//MARK: View Controller Life Cycle
	override func viewDidLoad() {
		super.viewDidLoad()
		
		mapView.delegate = self
		
		//create delete pin button
		setupDeleteButton()
		
		//add long press gesture for pins
		let longPressGesture = UILongPressGestureRecognizer(target: self, action: "addPinToMap:")
		longPressGesture.minimumPressDuration = 1
		mapView.addGestureRecognizer(longPressGesture)
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		//reposition map region and span
		if let settingsDict = NSKeyedUnarchiver.unarchiveObjectWithFile(mapSettingsPath) as? [String:AnyObject] {
			let latitude = settingsDict["latitude"] as! CLLocationDegrees
			let longitude = settingsDict["longitude"] as! CLLocationDegrees
			let mapCenter = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
			
			mapView.centerCoordinate = mapCenter
			
			let latDelta = (settingsDict["latitudeDelta"] as! CLLocationDegrees) ?? mapView.region.span.latitudeDelta
			let longDelta = (settingsDict["longitudeDelta"] as! CLLocationDegrees) ?? mapView.region.span.longitudeDelta
			let mapSpan = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta)
			
			mapView.region.span = mapSpan
		}
		
		//drop all pins from the managed object context
		reloadPins()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	//MARK: Functions
	
	//get data out of the managed object context
	func alertUI(withTitle title:String, message:String) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
		let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
		alert.addAction(action)
		presentViewController(alert, animated: true, completion: nil)
	}
	
	func reloadPins() {
		let fetchRequest = NSFetchRequest(entityName: "Pin")
		
		do {
			if let results = try CoreDataStack.sharedInstance.managedObjectContext.executeFetchRequest(fetchRequest) as? [Pin] {
				for mapPin in results {
					let pin = PinAnnotation()
					let latitude = mapPin.latitude as! CLLocationDegrees
					let longitude = mapPin.longitude as! CLLocationDegrees
					pin.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
					
					pin.pin = mapPin
					mapView.addAnnotation(pin)
				}
			}
		} catch {
			alertUI(withTitle: "Query Error", message: "There was an error retrieving the pins from the database!")
		}
	}
	
	func adjustMapHeight(buttonOnScreen:Bool) {
		buttonHeight = buttonHeightConstant * CGRectGetMaxY(view.bounds)
		
		if buttonOnScreen {
			self.deleteButton.hidden = !buttonOnScreen
			
			UIView.animateWithDuration(0.7, animations: { () -> Void in
				self.mapView.frame.origin.y -= self.buttonHeight
				self.deleteButton.frame.origin.y -=  self.buttonHeight
			})
			
		} else {
			UIView.animateWithDuration(0.7, animations: { () -> Void in
				self.mapView.frame.origin.y = 0
				self.deleteButton.frame.origin.y = CGRectGetMaxY(self.view.bounds)
				}, completion: { (complete) -> Void in
					self.deleteButton.hidden = !buttonOnScreen
			})
		}
	}
	
	override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
		buttonHeight = buttonHeightConstant * CGRectGetMaxY(view.bounds)
		let buttonOriginY = (deleteButton.hidden) ? CGRectGetMaxY(view.bounds) : CGRectGetMaxY(view.bounds) - buttonHeight
		deleteButton.frame = CGRect(x: 0, y: buttonOriginY, width: view.bounds.size.width, height: buttonHeight)
	}
	
	func setupDeleteButton() {
		deleteButton = UIButton()
		deleteButton.hidden = true
		buttonHeight = buttonHeightConstant * CGRectGetMaxY(view.bounds)
		deleteButton.frame = CGRect(x: 0, y: CGRectGetMaxY(view.bounds), width: view.bounds.size.width, height: buttonHeightConstant * CGRectGetMaxY(view.bounds))
		deleteButton.backgroundColor = UIColor.redColor()
		deleteButton.setTitle("Tap Pins to Delete!", forState: .Normal)
		
		view.addSubview(deleteButton)
	}
	
	//MARK: Map Functions
	func addPinToMap(longPressGesture:UILongPressGestureRecognizer) {
		if longPressGesture.state == .Began {
			let pin = PinAnnotation()
			let touchCoord = longPressGesture.locationInView(mapView)
			pin.coordinate = mapView.convertPoint(touchCoord, toCoordinateFromView: mapView)
			
			let pinEntity = Pin(context: coreDataStack.managedObjectContext)
			pinEntity.latitude = Float(pin.coordinate.latitude)
			pinEntity.longitude = Float(pin.coordinate.longitude)
			pin.pin = pinEntity
			mapView.addAnnotation(pin)
			
			//save the pin
			coreDataStack.saveMainContext()
			
		}
	}
}

extension MapViewController : MKMapViewDelegate {
	func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
		//capture the map settings after the map region has changed
		mapSettings["latitudeDelta"] = mapView.region.span.latitudeDelta
		mapSettings["longitudeDelta"] = mapView.region.span.longitudeDelta
		mapSettings["latitude"] = mapView.centerCoordinate.latitude
		mapSettings["longitude"] = mapView.centerCoordinate.longitude
		
		NSKeyedArchiver.archiveRootObject(mapSettings, toFile: mapSettingsPath)
	}
	
	func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
		let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: nil)
		pinView.animatesDrop = true
		return pinView
	}
	
	func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
		if isMapEditing {
			//delete annotation
			if let annotation = view.annotation as? PinAnnotation {
				if let pin = annotation.pin {
					coreDataStack.managedObjectContext.deleteObject(pin)
					mapView.removeAnnotation(annotation)
				}
				
				//save the context
				coreDataStack.saveMainContext()
			}
		} else {
			//get images for pin location
			if let annotation = view.annotation {
				print("\(annotation.coordinate)")
			}
		}
	}
}

extension MapViewController : NSFetchedResultsControllerDelegate {
	
}