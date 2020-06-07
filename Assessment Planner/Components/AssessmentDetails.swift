//
//  AssessmentDetails.swift
//  Assessment Planner
//
//  Created by Yasin on 6/6/20.
//  Copyright © 2020 Yasin. All rights reserved.
//

import SwiftUI

struct AssessmentDetails: View {
    
    let assessment: Assessment
    
    var body: some View {
        FormModalWrapper(
            cancelButtonText: "Close",
            showSubmitButton: false,
            submitButtonText: "",
            onSubmit: {},
            disableSubmit: .constant(true),
            show: .constant(true),
            title: "Details of \(assessment.name!)") {
                basic
                marks
                time
                notes
                tasks
                events
                meta
        }
    }
    
    var basic: some View {
        Group {
            VStack(alignment: .leading, spacing: 5) {
                KeyValueText(key: "Name", value: "\(assessment.name!)")
                KeyValueText(key: "Priority", value: "\(assessment.priority!)")
                KeyValueText(key: "Level", value: "\(assessment.module!.level!)")
                KeyValueText(key: "Module", value: "\(assessment.module!.name!)")
                KeyValueText(key: "Module Leader", value: "\(assessment.module!.leader!)")
                KeyValueText(key: "Module Code", value: "\(assessment.module!.code!)")
            }
            .padding(10)
            .frame(minWidth: 0, maxWidth: .infinity)
            Divider()
        }
    }
    
    var marks: some View {
        Group {
            VStack(alignment: .leading, spacing: 5) {
                KeyValueText(key: "Weightage", value: "\(assessment.weightage)")
                KeyValueText(key: "Mark Achieved", value: "\(assessment.markAchieved)")
                KeyValueText(key: "Calculated Total", value: "\(Utils.getOverallMark(assessment))")
            }
            .padding(10)
            .frame(minWidth: 0, maxWidth: .infinity)
            Divider()
        }
    }
    
    var time: some View {
        let (days, hours) = Utils.timeBetweenTwoDates(assessment.handIn!, assessment.due!)
        return Group {
            VStack(alignment: .leading, spacing: 5) {
                KeyValueText(key: "Hand-in date", value: "\(Utils.dateToDetailedString(assessment.handIn!))")
                KeyValueText(key: "Due date", value: "\(Utils.dateToDetailedString(assessment.due!))")
                KeyValueText(key: "Days allocated", value: "\(days) days\(hours != 0 ? " and \(hours) hours" : "")")
            }
            .padding(10)
            .frame(minWidth: 0, maxWidth: .infinity)
            Divider()
        }
    }
    
    var notes: some View {
        Group {
            VStack(alignment: .leading, spacing: 10) {
                Text("Additional Notes")
                    .italic()
                    .foregroundColor(.gray)
                    .alignTextLeft()
                Text(assessment.notes!)
                    .fontWeight(.light)
                    .padding()
                    .alignTextLeft()
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(lineWidth: 1)
                            .foregroundColor(Color.gray)
                )
            }
            .padding(10)
            .frame(minWidth: 0, maxWidth: .infinity)
            Divider()
        }
    }
    
    var tasks: some View {
        let totalNumberOfTasks = assessment.tasks!.count
        let totalCompleted = assessment.tasks!.filter { $0.progress == 100 }.count
        return Group {
            VStack(alignment: .leading, spacing: 5) {
                KeyValueText(key: "Total Number of Tasks", value: "\(totalNumberOfTasks)")
                KeyValueText(key: "Total Completed", value: "\(totalCompleted)")
                
            }
            .padding(10)
            .frame(minWidth: 0, maxWidth: .infinity)
            Divider()
        }
    }
    
    var events: some View {
        let reminder = AlarmOffset.fromRawValue(str: assessment.reminderBefore!).textualRepresentation()
        return Group {
            VStack(alignment: .leading, spacing: 5) {
                KeyValueText(key: "Added to Calendar Events?", value: "\(assessment.addToCalendar ? "Yes" : "No")")
                KeyValueText(key: "Reminder Before Starting the Event", value: "\(reminder)")
            }
            .padding(10)
            .frame(minWidth: 0, maxWidth: .infinity)
            Divider()
        }
    }
    
    var meta: some View {
        Group {
            VStack(alignment: .leading, spacing: 5) {
                KeyValueText(key: "Created at", value: "\(Utils.dateToDetailedString(assessment.createdAt!))")
                KeyValueText(key: "Last Updated at", value: "\(Utils.dateToDetailedString(assessment.updatedAt!))")
            }
            .padding(10)
            .frame(minWidth: 0, maxWidth: .infinity)
        }
    }
    
}


struct KeyValueText: View {
    
    let key: String?
    let value: String
    
    var body: some View {
        HStack(spacing: 10) {
            if self.key != nil {
                Text(self.key!)
                    .italic()
                    .foregroundColor(.gray)
                    .alignTextLeft()
            }
            Text(self.value)
                .fontWeight(.light)
        }
        .frame(minWidth: 0, maxWidth: .infinity)
    }
    
}
