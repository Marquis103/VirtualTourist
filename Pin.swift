//
//  Pin.swift
//  VirtualTourist
//
//  Created by Marquis Dennis on 2/22/16.
//  Copyright © 2016 Marquis Dennis. All rights reserved.
//

import Foundation
import CoreData


class Pin: NSManagedObject {

	struct Keys {
		static let latitude = "latitude"
		static let longitude = "longitude"
	}
	
	override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
		super.init(entity: entity, insertIntoManagedObjectContext: context)
	}
	
	init(context: NSManagedObjectContext) {
		guard let pinEntity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context) else {
			fatalError("Could not create Pin Entity Description!")
		}
		
		super.init(entity: pinEntity, insertIntoManagedObjectContext: context)
	}
	
	init(dictionary: [String:AnyObject], context: NSManagedObjectContext) {
		guard let pinEntity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context) else {
			fatalError("Could not create Pin Entity Description!")
		}
		
		super.init(entity: pinEntity, insertIntoManagedObjectContext: context)
		
		latitude = dictionary[Keys.latitude] as! Float
		longitude = dictionary[Keys.longitude] as! Float
	}

}
