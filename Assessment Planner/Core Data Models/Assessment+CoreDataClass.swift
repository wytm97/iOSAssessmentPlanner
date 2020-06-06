//
//  Assessment+CoreDataClass.swift
//  Assessment Planner
//
//  Created by Yasin on 6/6/20.
//  Copyright © 2020 Yasin. All rights reserved.
//
//

import Foundation
import CoreData
import SwiftUI

public class Assessment: NSManagedObject, Identifiable, Comparable {
    
    // MARK: Life Cycle Hooks
    
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
    
    // MARK: Fetch Functions
    
    @nonobjc public class func getAllAssessments() -> NSFetchRequest<Assessment> {
        let request: NSFetchRequest<Assessment> = Assessment.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "due", ascending: false)]
        return request
    }
    
    @nonobjc public class func getAllAssessmentsMatching(priority: String?, module: Module?) -> NSFetchRequest<Assessment> {
        
        // User requested all the assessments
        if priority == nil && module == nil {
            return getAllAssessments()
        }
        
        // We need to build the predicate dynamically.
        
        var predicate: NSPredicate
        
        if module != nil && priority == nil {
            predicate = NSPredicate(format: "module = %@", argumentArray: [module!])
        } else if module == nil && priority != nil {
            predicate = NSPredicate(format: "priority = %@", argumentArray: [priority!])
        } else {
            predicate = NSPredicate(format: "priority = %@ AND module = %@", argumentArray: [priority!, module!])
        }
        
        let request: NSFetchRequest<Assessment> = Assessment.fetchRequest()
        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(key: "due", ascending: false)]
        return request
        
    }
    
    // MARK: Comparator
    
    public static func < (lhs: Assessment, rhs: Assessment) -> Bool {
        return lhs.due?.compare(rhs.due!) == ComparisonResult.orderedDescending
    }
    
    // MARK: To String
    
    public override var description: String {
        return "{\naddToCalendar:\(addToCalendar),\n" +
            "createdAt: \(String(describing: createdAt)),\n" +
            "due: \(due!)\n" +
            "markAchieved: \(markAchieved)\n" +
            "name: \(name!)\n" +
            "priority: \(priority!)\n" +
            "handIn: \(handIn!)\n" +
            "eventIdentifier: \(eventIdentifier!)\n" +
        "module: \(String(describing: module!))\n}"
    }
    
}


public enum AssessmentPriority: String, CaseIterable {
    
    case low = "Low"
    case normal = "Normal"
    case important = "Important"
    case critical = "Critical"
    
    // MARK: Static
    
    static func values() -> [String] {
        return [
            low.rawValue,
            normal.rawValue,
            important.rawValue,
            critical.rawValue
        ]
    }
    
    static func fromRawValue(str: String) -> AssessmentPriority {
        switch str {
        case "Low":
            return .low
        case "Normal":
            return .normal
        case "Important":
            return .important
        case "Critical":
            return .critical
        default:
            return .low
        }
    }
    
    // MARK: Instance
    
    func color() -> Color {
        switch self {
        case .low:
            return .green
        case .normal:
            return .yellow
        case .important:
            return .orange
        case .critical:
            return .red
        }
    }
    
}
