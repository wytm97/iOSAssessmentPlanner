//
//  Task+CoreDataProperties.swift
//  Assessment Planner
//
//  Created by Yasin on 6/6/20.
//  Copyright © 2020 Yasin. All rights reserved.
//
//

import Foundation
import CoreData


extension Task {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Task> {
        return NSFetchRequest<Task>(entityName: "Task")
    }

    @NSManaged public var addToCalendar: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var due: Date?
    @NSManaged public var eventIdentifier: String?
    @NSManaged public var handIn: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var notes: String?
    @NSManaged public var progress: Int16
    @NSManaged public var reminderBefore: String?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var assessment: Assessment?

}
