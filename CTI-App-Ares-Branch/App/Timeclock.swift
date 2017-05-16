//
//  Timeclock.swift
//  CTI Translators
//
//  Created by Adeo
//  Copyright © 2016 CTI. All rights reserved.
//

import Foundation
import CoreData

/*********   MODEL TIMECLOCK   ***********/
class Timeclock: NSManagedObject {
    @NSManaged var fecha: Date?
    @NSManaged var branch: String?
    @NSManaged var company: String?
    @NSManaged var end_code: String?
    @NSManaged var end_time: Date?
    @NSManaged var id: NSNumber?
    @NSManaged var ipad: NSNumber?
    @NSManaged var job: NSNumber?
    @NSManaged var start_code: String?
    @NSManaged var start_time: Date?
    @NSManaged var status: NSNumber?
    @NSManaged var telephone: String?
    
// Insert code here to add functionality to your managed object subclass
    var isOverdue: Bool {return (Date().compare(self.end_time!) == ComparisonResult.orderedDescending)}
}
