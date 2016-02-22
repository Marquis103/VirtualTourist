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
	
	var mapSettings =  [String:AnyObject]()
	
	var mapSettingsPath: String {
		let manager = NSFileManager.defaultManager()
		let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
		
		return url.URLByAppendingPathComponent("mapset").path!
	}
	
	//MARK: View Controller Life Cycle
	override func viewDidLoad() {
		super.viewDidLoad()
		
		mapView.delegate = self
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
}

