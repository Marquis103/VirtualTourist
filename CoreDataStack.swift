//
//  CoreDataStack.swift
//  MemeMe
//
//  Created by Marquis Dennis on 2/2/16.
//  Copyright © 2016 Marquis Dennis. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStack : NSObject {
	static let sharedInstance = CoreDataStack()
	static let moduleName = "pinPhotos"
	
	struct Constants {
		struct EntityNames {
			static let PhotoEntityName = "Photo"
			static let PinEntityName = "Pin"
		}
	}
	
	//save managed context if changes exist
	func saveMainContext() {
		if managedObjectContext.hasChanges {
			do {
				try managedObjectContext.save()
			} catch {
				print("There was an error saving main managed object context! \(error)")
			}
		}
	}
	
	lazy var persistentStoreCoordinator:NSPersistentStoreCoordinator = {
		//location of the managed object model persisted on disk
		let modelURL = NSBundle.mainBundle().URLForResource(moduleName, withExtension: "momd")!
		
		//instantiate the persistent store coordinator
		let coordinator = NSPersistentStoreCoordinator(managedObjectModel: NSManagedObjectModel(contentsOfURL: modelURL)!)
		
		//application documents directory where user files are stored
		let applicationDocumentsDirectory = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last!
		
		//location on disk of the actual persistent store
		let persistentStoreURL = applicationDocumentsDirectory.URLByAppendingPathComponent("\(moduleName).sqlite")
		
		//add the persistent store to the persistent store coordinator
		do {
			try coordinator.addPersistentStoreWithType(NSSQLiteStoreType,
				configuration: nil,
				URL: persistentStoreURL,
				options: [NSMigratePersistentStoresAutomaticallyOption: true,
					NSInferMappingModelAutomaticallyOption : true])
		} catch {
			fatalError("Persistent store error! \(error)")
		}
		
		return coordinator
		
	}()
	
	//create managed object context
	lazy var managedObjectContext:NSManagedObjectContext = {
		let managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
		managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
		return managedObjectContext
	}()
	
	/*lazy var memeEntity:NSEntityDescription = {
		guard let entity = NSEntityDescription.entityForName("Meme", inManagedObjectContext: self.managedObjectContext) else {
			fatalError("Entity could not be found!")
		}
		
		return entity
	}()*/
}