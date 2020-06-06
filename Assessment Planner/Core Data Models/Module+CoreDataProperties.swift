//
//  Module+CoreDataProperties.swift
//  Assessment Planner
//
//  Created by Yasin on 6/6/20.
//  Copyright © 2020 Yasin. All rights reserved.
//
//

import Foundation
import CoreData

extension Module {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Module> {
        return NSFetchRequest<Module>(entityName: "Module")
    }

    @NSManaged public var code: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var leader: String?
    @NSManaged public var level: String?
    @NSManaged public var name: String?
    @NSManaged public var assessments: Set<Assessment>?

}

// MARK: Generated accessors for assessments

extension Module {

    @objc(addAssessmentsObject:)
    @NSManaged public func addToAssessments(_ value: Assessment)

    @objc(removeAssessmentsObject:)
    @NSManaged public func removeFromAssessments(_ value: Assessment)

    @objc(addAssessments:)
    @NSManaged public func addToAssessments(_ values: NSSet)

    @objc(removeAssessments:)
    @NSManaged public func removeFromAssessments(_ values: NSSet)

}
