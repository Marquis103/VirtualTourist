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
		static let imageLocation = "imageLocation"
		static let dateTaken = "dateTaken"
		static let imageURL = "imageUrl"
	}
	
	private var photosFilePath: String {
		return NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first!
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
		
		imageLocation = dictionary[Keys.imageLocation] as? String
		dateTaken = dictionary[Keys.dateTaken] as! NSDate
		imageUrl = dictionary[Keys.imageURL] as! String
	}

	override func prepareForDeletion() {
		//delete photos from disk
		
		if let imageLocation = self.imageLocation {
			if NSFileManager.defaultManager().fileExistsAtPath(NSURL(string: self.photosFilePath)!.URLByAppendingPathComponent(imageLocation).path!) {
				do {
					try NSFileManager.defaultManager().removeItemAtPath(NSURL(string: self.photosFilePath)!.URLByAppendingPathComponent(imageLocation).path!)
				} catch {
					let deleteError = error as NSError
					print(deleteError)
				}
			}
		}
	}
}
