//
//  Module+CoreDataClass.swift
//  Assessment Planner
//
//  Created by Yasin on 6/6/20.
//  Copyright © 2020 Yasin. All rights reserved.
//
//

import Foundation
import CoreData

public class Module: NSManagedObject, Identifiable {
    
    // MARK: Fetch Functions
    
    @nonobjc public class func getAllModules() -> NSFetchRequest<Module> {
        let request: NSFetchRequest<Module> = Module.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        return request
    }
    
    // MARK: To String
    
    public override var description: String {
        return "[code:\(code!), name:\(name!)," +
        " level:\(level!), leader:\(leader!)]"
    }
    
    // MARK: LifeCyle Hooks
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        setValue(UUID(), forKey: "id")
        setValue(Date(), forKey: "createdAt")
    }
    
}

public enum ModuleLevel: String, CaseIterable {
    
    case l3 = "Level 3"
    case l4 = "Level 4"
    case l5 = "Level 5"
    case l6 = "Level 6"
    case l7 = "Level 7"
    
    static func values() -> [String] {
        return [
            l3.rawValue,
            l4.rawValue,
            l5.rawValue,
            l6.rawValue,
            l7.rawValue
        ]
    }
    
}
