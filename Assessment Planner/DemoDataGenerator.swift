//
//  DemoDataGenerator.swift
//  Assessment Planner
//
//  Created by Yasin on 6/6/20.
//  Copyright © 2020 Yasin. All rights reserved.
//

import Foundation
import CoreData

class DemoDataGenerator {
    
    static func generate(managedObjectContext: NSManagedObjectContext) -> Void {
        
        func getDate(str: String) -> Date? {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            dateFormatter.timeZone = TimeZone.current
            dateFormatter.locale = Locale.current
            return dateFormatter.date(from: str)
        }
        
        do {
            
            let fetchRequest3: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Task")
            let deleteRequest3 = NSBatchDeleteRequest(fetchRequest: fetchRequest3)
            try managedObjectContext.persistentStoreCoordinator?.execute(
                deleteRequest3,
                with: managedObjectContext
            )
            
            let fetchRequest2: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Assessment")
            let deleteRequest2 = NSBatchDeleteRequest(fetchRequest: fetchRequest2)
            try managedObjectContext.persistentStoreCoordinator?.execute(
                deleteRequest2,
                with: managedObjectContext
            )
            
            let fetchRequest1: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Module")
            let deleteRequest1 = NSBatchDeleteRequest(fetchRequest: fetchRequest1)
            try managedObjectContext.persistentStoreCoordinator?.execute(
                deleteRequest1,
                with: managedObjectContext
            )
            
            try managedObjectContext.save()
            
        } catch let error as NSError {
            print(error)
        }
        
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 1.5,
            execute: DispatchWorkItem {
                
                let module1 = Module(context: managedObjectContext)
                module1.code = "6COSC004W.2"
                module1.name = "Mobile Native Programming"
                module1.level = "Level 6"
                module1.leader = "Guhanathan Poravi"
                module1.assessments = []
                
                let module2 = Module(context: managedObjectContext)
                module2.code = "6COSC012C.Y"
                module2.name = "Final Year Project"
                module2.level = "Level 6"
                module2.leader = "Kaneeka Vidanage"
                module2.assessments = []
                
                let module3 = Module(context: managedObjectContext)
                module3.code = "6SENG004C.1"
                module3.name = "Concurrent Programming"
                module3.level = "Level 6"
                module3.leader = "Achala Aponso"
                module3.assessments = []
                
                // Create Assessments 2 for each
                
                // let currentDate = Date()
                // var dateComponent = DateComponents()
                // dateComponent.day = 1
                // let futureDate = Calendar.current.date(byAdding: dateComponent, to: currentDate)
                
                let a1 = Assessment(context: managedObjectContext)
                a1.name = "Coursework 1"
                a1.weightage = 40
                a1.notes = "A financial calculator application"
                a1.priority = "Important"
                a1.addToCalendar = false
                a1.eventIdentifier = ""
                a1.markAchieved = 0
                a1.handIn = getDate(str: "2020-06-01T00:00:00")
                a1.due = getDate(str: "2020-07-01T23:59:59")
                a1.module = module1 /// Assign the selected module
                a1.tasks = []
                a1.reminderBefore = AlarmOffset.none.rawValue
                
                let a2 = Assessment(context: managedObjectContext)
                a2.name = "Coursework 2"
                a2.weightage = 60
                a2.notes = "A assessment planner application"
                a2.priority = "Critical"
                a2.addToCalendar = false
                a2.eventIdentifier = ""
                a2.markAchieved = 0
                a2.handIn = getDate(str: "2020-04-01T00:00:00")
                a2.due = getDate(str: "2020-06-03T23:59:59")
                a2.module = module1 /// Assign the selected module
                a2.tasks = []
                a2.reminderBefore = AlarmOffset.none.rawValue
                
                //--
                
                let a3 = Assessment(context: managedObjectContext)
                a3.name = "Coursework"
                a3.weightage = 40
                a3.notes = "Banking system application implement using Java and model it with FSP"
                a3.priority = "Low"
                a3.addToCalendar = false
                a3.eventIdentifier = ""
                a3.markAchieved = 0
                a3.handIn = getDate(str: "2020-03-15T00:00:00")
                a3.due = getDate(str: "2020-06-15T23:59:59")
                a3.module = module3 /// Assign the selected module
                a3.tasks = []
                a3.reminderBefore = AlarmOffset.none.rawValue
                
                let a4 = Assessment(context: managedObjectContext)
                a4.name = "Examination"
                a4.weightage = 60
                a4.notes = "Final examination of the module (2 FSP questions, and 4 other)"
                a4.priority = "Normal"
                a4.addToCalendar = false
                a4.eventIdentifier = ""
                a4.markAchieved = 0
                a4.handIn = getDate(str: "2020-06-18T14:30:00")
                a4.due = getDate(str: "2020-06-18T16:30:00")
                a4.module = module3 /// Assign the selected module
                a4.tasks = []
                a4.reminderBefore = AlarmOffset.none.rawValue
                
                //--
                
                let a5 = Assessment(context: managedObjectContext)
                a5.name = "Software Requirement Specification"
                a5.weightage = 0
                a5.notes = "Include onion diagram, functional & non-functional requirements."
                a5.priority = "Low"
                a5.addToCalendar = false
                a5.eventIdentifier = ""
                a5.markAchieved = 0
                a5.handIn = getDate(str: "2020-05-28T00:00:00")
                a5.due = getDate(str: "2020-06-28T23:59:59")
                a5.module = module2 /// Assign the selected module
                a5.tasks = []
                a5.reminderBefore = AlarmOffset.none.rawValue
                
                let a6 = Assessment(context: managedObjectContext)
                a6.name = "Draft Thesis"
                a6.weightage = 0
                a6.notes = "Include all chapters SRS, Methodology, Testing, Implementation, etc"
                a6.priority = "Critical"
                a6.addToCalendar = false
                a6.eventIdentifier = ""
                a6.markAchieved = 0
                a6.handIn = getDate(str: "2020-06-01T00:00:00")
                a6.due = getDate(str: "2020-06-28T23:59:59")
                a6.module = module2 /// Assign the selected module
                a6.reminderBefore = AlarmOffset.none.rawValue
                
                let t1 = Task(context: managedObjectContext)
                t1.due = getDate(str: "2020-06-06T00:00:00")
                t1.name = "Literature Review Chapter"
                t1.notes = "Add references and paraphrase existing systems properly. Also, add conceptual map."
                t1.addToCalendar = false
                t1.progress = 40
                t1.reminderBefore = AlarmOffset.none.rawValue
                t1.handIn = getDate(str: "2020-06-01T00:00:00")
                t1.eventIdentifier = ""
                t1.assessment = a6
                
                let t2 = Task(context: managedObjectContext)
                t2.due = getDate(str: "2020-06-16T00:00:00")
                t2.name = "Implementation Chapter"
                t2.notes = "Add core implementation code snippets. List technologies utilized and justify why used."
                t2.addToCalendar = false
                t2.progress = 100
                t2.reminderBefore = AlarmOffset.none.rawValue
                t2.handIn = getDate(str: "2020-06-01T00:00:00")
                t2.eventIdentifier = ""
                t2.assessment = a6
                
                let t3 = Task(context: managedObjectContext)
                t3.due = getDate(str: "2020-06-26T00:00:00")
                t3.name = "Testing Chapter"
                t3.notes = "Add functional and non-functional testing. Add performance test results of algorithms."
                t3.addToCalendar = false
                t3.progress = 18
                t3.reminderBefore = AlarmOffset.none.rawValue
                t3.handIn = getDate(str: "2020-06-01T00:00:00")
                t3.eventIdentifier = ""
                t3.assessment = a6
                
                a6.tasks = [t1, t2, t3]
                
                module1.assessments!.insert(a1)
                module1.assessments!.insert(a2)
                
                module2.assessments!.insert(a5)
                module2.assessments!.insert(a6)
                
                module3.assessments!.insert(a3)
                module3.assessments!.insert(a4)
                
                try? managedObjectContext.save()
                managedObjectContext.refreshAllObjects()
                
            }
        )
    }
    
}

