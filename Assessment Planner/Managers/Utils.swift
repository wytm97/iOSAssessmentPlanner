//
//  Calculations.swift
//  Assessment Planner
//
//  Created by Yasin on 6/6/20.
//  Copyright © 2020 Yasin. All rights reserved.
//

import Foundation
import SwiftUI

public class Utils {
    
    private static let dateFormatter : DateFormatter = DateFormatter()
    
    // MARK: Date Formatter Functions
    
    public static func dateToString(_ date: Date) -> String {
        
        // Wednesday, Sep 12, 2018           --> EEEE, MMM d, yyyy
        // 09/12/2018                        --> MM/dd/yyyy
        // 09-12-2018 14:11                  --> MM-dd-yyyy HH:mm
        // Sep 12, 2:11 PM                   --> MMM d, h:mm a
        // September 2018                    --> MMMM yyyy
        // Sep 12, 2018                      --> MMM d, yyyy
        // Wed, 12 Sep 2018 14:11:54 +0000   --> E, d MMM yyyy HH:mm:ss Z
        // 2018-09-12T14:11:54+0000          --> yyyy-MM-dd'T'HH:mm:ssZ
        // 12.09.18                          --> dd.MM.yy
        // 10:41:02.112                      --> HH:mm:ss.SSS
        
        dateFormatter.dateFormat = "dd MMM yyyy hh:mm a"
        return dateFormatter.string(from: date)
        
    }
    
    public static func dateToDetailedString(_ date: Date) -> String {
        dateFormatter.dateFormat = "EEEE, d MMMM yyyy HH:mm:ss"
        return dateFormatter.string(from: date)
    }
    
    public static func getOverallMark(_ ass: Assessment) -> Int {
        return Int(CGFloat(ass.markAchieved) * (CGFloat(ass.weightage)/100))
    }
    
    /// Calculates the assessment progress using its assigned sub-tasks.
    /// Progress = TotalProgressInEveryTask / TaskCount
    ///
    public static func getAssessmentProgressPercentage(_ tasks: [Task]) -> Float {
        
        let taskCount: Float = Float(tasks.count)
        var progressTotal: Float = 0
        var progress: Float = 0
        
        if taskCount > 0 {
            for task in tasks {
                progressTotal += Float(task.progress)
            }
            progress = progressTotal / taskCount
        }
        
        return progress
        
    }
    
    public static func getAssessmentDaysRemainingAndElapsedPercentage(_ assessment: Assessment) -> (Int, CGFloat) {
        return timeDiffInDays(assessment.handIn!, assessment.due!)
    }
    
    public static func getTaskDaysRemainingAndElapedPercentage(_ task: Task) -> (Int, CGFloat) {
        return timeDiffInDays(task.handIn!, task.due!)
    }
    
    public static func timeDiffInDays(_ d1: Date, _ d2: Date) -> (Int, CGFloat) {
        // From hand-in date to due date. This is the date closed range. assume 88
        let allocatedDays = timeDifferenceInSeconds(d1, d2)
        let daysLeft = timeDifferenceInSeconds(Date(/*now*/), d2)
        if daysLeft <= 0 && allocatedDays == 0 {
            return (0, 100)
        }
        let percentage = CGFloat(((allocatedDays - daysLeft) * 100) / allocatedDays)
        return (Int(daysLeft / 86400), percentage)
    }
    
    public static func getTimeLeftSimplified(_ start: Date, _ end: Date) -> (Int, Int, Int, Int) {
        let components = Calendar.current.dateComponents([.day, .hour, .minute, .second], from: start, to: end)
        return (
            Int(abs(components.day!)),
            Int(abs(components.hour!)),
            Int(abs(components.minute!)),
            Int(abs(components.second!))
        )
    }
    
    
    public static func timeBetweenTwoDates(_ start: Date, _ end: Date) -> (Int, Int) {
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .hour], from: start, to: end)
        return (components.day!, components.hour!)
        
    }
    
    // MARK: Internal APIs
    
    private static func timeDifferenceInSeconds(_ start: Date, _ end: Date) -> Double {
        let difference: TimeInterval? = end.timeIntervalSince(start)
        if Double(difference!) < 0 {
            return 0
        }
        return Double(difference!)
    }
    
    private static func timeDifferenceInDays(_ start: Date, _ end: Date) -> Int {
        let currentCalendar = Calendar.current
        guard let start = currentCalendar.ordinality(of: .day, in: .era, for: start) else {
            return 0
        }
        guard let end = currentCalendar.ordinality(of: .day, in: .era, for: end) else {
            return 0
        }
        return end - start
    }
    
}
