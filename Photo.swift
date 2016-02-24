//
//  Photo.swift
//  VirtualTourist
//
//  Created by Marquis Dennis on 2/22/16.
//  Copyright © 2016 Marquis Dennis. All rights reserved.
//

import UIKit
import CoreData


class Photo: NSManagedObject {

	struct Keys {
		static let image = "image"
		static let dateTaken = "dateTaken"
	}
	
	override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
		super.init(entity: entity, insertIntoManagedObjectContext: context)
	}
	
	init(context: NSManagedObjectContext) {
		guard let photoEntity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context) else {
			fatalError("Could not create Photo Entity Description!")
		}
		
		super.init(entity: photoEntity, insertIntoManagedObjectContext: context)
	}
	
	init(dictionary: [String:AnyObject], context: NSManagedObjectContext) {
		guard let photoEntity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context) else {
			fatalError("Could not create Photo Entity Description!")
		}
		
		super.init(entity: photoEntity, insertIntoManagedObjectContext: context)
		
		image = dictionary[Keys.image] as! UIImage
		dateTaken = dictionary[Keys.dateTaken] as! NSDate
	}

}
