//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Marquis Dennis on 2/21/16.
//  Copyright © 2016 Marquis Dennis. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {

	@IBOutlet weak var mapView: MKMapView!
	
	@IBOutlet weak var editButton: UIBarButtonItem!
	var mapSettings =  [String:AnyObject]()
	var deleteButton:UIButton!
	var isMapEditing = false
	var buttonHeight:CGFloat = 0.0
	
	var mapSettingsPath: String {
		let manager = NSFileManager.defaultManager()
		let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
		
		return url.URLByAppendingPathComponent("mapset").path!
	}
	
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
		longPressGesture.minimumPressDuration = 2
		mapView.addGestureRecognizer(longPressGesture)
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		if let settingsDict = NSKeyedUnarchiver.unarchiveObjectWithFile(mapSettingsPath) as? [String:AnyObject] {
			let mapCenter = CLLocationCoordinate2D(latitude: settingsDict["latitude"] as! CLLocationDegrees, longitude: settingsDict["longitude"] as! CLLocationDegrees)
			let latDelta = (settingsDict["latitudeDelta"] as! CLLocationDegrees) ?? mapView.region.span.latitudeDelta
			let longDelta = (settingsDict["longitudeDelta"] as! CLLocationDegrees) ?? mapView.region.span.longitudeDelta
			let mapSpan = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta)
			mapView.region = MKCoordinateRegion(center: mapCenter, span: mapSpan)
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	//MARK: Functions
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
			let pin = MKPointAnnotation()
			let touchCoord = longPressGesture.locationInView(mapView)
			pin.coordinate = mapView.convertPoint(touchCoord, toCoordinateFromView: mapView)
			mapView.addAnnotation(pin)
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
		print("we tapped it")
	}
}

