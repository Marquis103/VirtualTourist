//
//  PinAnnotation.swift
//  VirtualTourist
//
//  Created by Marquis Dennis on 2/22/16.
//  Copyright © 2016 Marquis Dennis. All rights reserved.
//

import MapKit

class PinAnnotation: MKPointAnnotation {
	var pin:Pin?
	
	override init() {
		super.init()
	}
	
	init(withManagedPin pin:Pin) {
		super.init()
		
		self.pin = pin
	}
}
