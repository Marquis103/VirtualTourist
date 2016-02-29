//
//  Photo+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Marquis Dennis on 2/29/16.
//  Copyright © 2016 Marquis Dennis. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Photo {

    @NSManaged var dateTaken: NSDate
    @NSManaged var imageLocation: String?
    @NSManaged var imageUrl: String
    @NSManaged var pin: Pin?

}
