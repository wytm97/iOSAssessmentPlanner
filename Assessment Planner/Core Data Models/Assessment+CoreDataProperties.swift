//
//  Assessment+CoreDataProperties.swift
//  Assessment Planner
//
//  Created by Yasin on 6/6/20.
//  Copyright © 2020 Yasin. All rights reserved.
//
//

import Foundation
import CoreData

extension Assessment {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Assessment> {
        return NSFetchRequest<Assessment>(entityName: "Assessment")
    }

    @NSManaged public var addToCalendar: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var due: Date?
    @NSManaged public var eventIdentifier: String?
    @NSManaged public var handIn: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var markAchieved: Int16
    @NSManaged public var name: String?
    @NSManaged public var notes: String?
    @NSManaged public var priority: String?
    @NSManaged public var reminderBefore: String?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var weightage: Int16
    @NSManaged public var module: Module?
    @NSManaged public var tasks: Set<Task>?

}

// MARK: Generated accessors for tasks

extension Assessment {

    @objc(addTasksObject:)
    @NSManaged public func addToTasks(_ value: Task)

    @objc(removeTasksObject:)
    @NSManaged public func removeFromTasks(_ value: Task)

    @objc(addTasks:)
    @NSManaged public func addToTasks(_ values: NSSet)

    @objc(removeTasks:)
    @NSManaged public func removeFromTasks(_ values: NSSet)

}
