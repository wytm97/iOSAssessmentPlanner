//
//  Task+CoreDataClass.swift
//  Assessment Planner
//
//  Created by Yasin on 6/6/20.
//  Copyright © 2020 Yasin. All rights reserved.
//
//

import Foundation
import CoreData

public class Task: NSManagedObject {
    
    // MARK: Fetch Functions
    
    @nonobjc public class func getAllTasks() -> NSFetchRequest<Task> {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "due", ascending: true),
            NSSortDescriptor(key: "progress", ascending: true)
        ]
        return request
    }
    
    @nonobjc public class func getAllTasksWithAssessment(_ ass: Assessment) -> NSFetchRequest<Task> {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        request.predicate = NSPredicate(format: "assessment = %@", argumentArray: [ass])
        request.sortDescriptors = [
            NSSortDescriptor(key: "due", ascending: true),
            NSSortDescriptor(key: "progress", ascending: true)
        ]
        return request
    }
    
    // MARK: Comparator
    
    public static func < (lhs: Task, rhs: Task) -> Bool {
        return lhs.due?.compare(rhs.due!) == ComparisonResult.orderedDescending
    }
    
    // MARK: LifeCycle Hooks
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        setValue(UUID(), forKey: "id")
        setValue(Date(), forKey: "createdAt")
    }
    
    public override func willSave() {
        if self.changedValues()["updatedAt"] == nil {
            setValue(Date(), forKey: "updatedAt")
        } else {
            super.willSave()
        }
    }
    
    // MARK: To String
    
    public override var description: String {
        return "{\naddToCalendar:\(addToCalendar),\n" +
            "createdAt: \(String(describing: createdAt)),\n" +
            "due: \(due!)\n" +
            "progress: \(progress)\n" +
            "name: \(name!)\n" +
            "reminderBefore: \(reminderBefore!)\n" +
            "handIn: \(handIn!)\n" +
            "eventIdentifier: \(eventIdentifier!)\n" +
        "assessment: \(String(describing: assessment!))\n}"
    }
    
}
