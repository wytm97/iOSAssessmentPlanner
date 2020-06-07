//
//  TaskManageView.swift
//  Assessment Planner
//
//  Created by Yasin on 6/6/20.
//  Copyright © 2020 Yasin. All rights reserved.
//

import SwiftUI
import Combine

struct TaskManageView: View {
    
    // MARK: Pre-Compile the Regex Patterns
    
    private let NAME_REGEX = try? NSRegularExpression(pattern: "^[ a-zA-Z\\d_.\\-]{3,50}$")
    private let RANGE_0_TO_100_REGEX = try? NSRegularExpression(pattern: "^(?:100|[1-9][0-9]|[0-9])$")
    
    @EnvironmentObject var message: AlertManager
    @Environment(\.managedObjectContext) var moc
    @State var reminderList: [String] = AlarmOffset.rawValues()
    
    // MARK: FormField variables
    
    @State var name: String = ""
    @State var notes: String = ""
    @State var addToCalendar: Bool = false
    @State var handInDate: Date = Date()
    @State var dueDate: Date = Date()
    @State var progress: Double = 0
    @State var selectedReminder: Int = 0
    @State var hadCalendarEvent: Bool = false
    
    // MARK: Assessment belonging this task
    
    var assessment: Assessment
    
    // MARK: Editing transformer state (Optional)
    
    @State var editing: Bool = false
    @State var task: Task? = nil
    
    // MARK: Dynamic state properties of the view
    
    @Binding var show: Bool
    
    // MARK: View components
    
    var body: some View {
        FormModalWrapper(
            submitButtonText: editing ? "Save" : "Add",
            onSubmit: editing ? self.onSaveButtonClicked : self.onAddButtonClicked,
            disableSubmit: .constant(false),
            show: $show,
            title: editing ? "Editing: \(self.task!.name!)" : "Create New Task"
        ) {
            nameFormField
            notesFormField
            addToCalendarFormField
            reminderFormField
            handInDateFormField
            dueDateFormField
            if editing {
                progressFormField
            }
        }.onAppear {
            if self.editing && self.task != nil {
                /// Mutate the state back to old properties. This a delayed task
                /// not to conflict with the rendering process.
                DispatchQueue.main.asyncAfter(
                    deadline: .now(),
                    execute: DispatchWorkItem {
                        self.mapFromExistingModel()
                    }
                )
            }
        }
    }
    
    var nameFormField: some View {
        FormElementWrapper {
            Text("Task Name").font(.headline)
            TextField(
                "Create Master Detail View",
                text: $name
            )
        }.frame(minWidth: 0, maxWidth: .infinity)
    }
    
    var notesFormField: some View {
        FormElementWrapper {
            Text("Task Notes (Optional)")
                .font(.headline)
            TextField(
                "Enter notes here....",
                text: $notes
            )
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
        }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 70)
    }
    
    var addToCalendarFormField: some View {
        FormElementWrapper {
            Text("Add to Calendar Events?")
                .font(.headline)
            Toggle(isOn: $addToCalendar) {
                HStack {
                    Text(resolveAddToCalendarDesciption())
                        .font(.body)
                        .foregroundColor(Color.gray)
                    Image(systemName: addToCalendar ?
                        "checkmark.circle.fill" : "multiply.square.fill")
                        .font(.body)
                        .foregroundColor(addToCalendar ? Color.green : Color.red)
                }
            }
        }.frame(minWidth: 0, maxWidth: .infinity)
    }
    
    var reminderFormField: some View {
        FormElementWrapper {
            HStack {
                Text("Remind Me").font(.headline)
                Text("\(AlarmOffset.fromRawValue(str: reminderList[selectedReminder]).textualRepresentation())")
                    .font(.callout)
            }
            HStack {
                Picker(selection: self.$selectedReminder, label: Text("Reminder")){
                    ForEach(0..<self.reminderList.count) { index in
                        Text(self.reminderList[index]).tag(index)
                    }
                }
                .disabled(!addToCalendar)
                .opacity(!addToCalendar ? 0.3 : 1)
                .pickerStyle(SegmentedPickerStyle())
            }.frame(minWidth: 100, maxWidth: .infinity)
        }
    }
    
    var handInDateFormField: some View {
        FormElementWrapper {
            Text("Task Start Date").font(.headline)
            HStack {
                DatePicker(
                    selection: $handInDate,
                    in: self.getEnclosedRange(),
                    displayedComponents: [.hourAndMinute, .date],
                    label: { Text("Task Start Date") }
                )
                    .labelsHidden()
                    .frame(height: 70)
                    .clipped()
            }.frame(minWidth: 0, maxWidth: .infinity)
        }.frame(minWidth: 0, maxWidth: .infinity)
    }
    
    var dueDateFormField: some View {
        FormElementWrapper {
            Text("Task Due Date").font(.headline)
            HStack {
                DatePicker(
                    selection: $dueDate,
                    in: self.getEnclosedRange(),
                    displayedComponents: [.hourAndMinute, .date],
                    label: { Text("Task Due Date") }
                )
                    .labelsHidden()
                    .frame(height: 70)
                    .clipped()
            }.frame(minWidth: 0, maxWidth: .infinity)
        }.frame(minWidth: 0, maxWidth: .infinity)
    }
    
    var progressFormField: some View {
        FormElementWrapper {
            Text("Task Progress (\(Int(progress))%)")
                .font(.headline)
            Slider(value: $progress, in: 0...100, step: 1)
        }
    }
    
    // MARK: Convenient functions
    
    func mapFromExistingModel() -> Void {
        
        name = self.task!.name!
        addToCalendar = self.task!.addToCalendar
        dueDate = self.task!.due!
        handInDate = self.task!.handIn!
        notes = self.task!.notes!
        progress = Double(self.task!.progress)
        selectedReminder = self.reminderList.firstIndex(of: self.task!.reminderBefore!)!
        
        self.hadCalendarEvent = self.task!.addToCalendar
        
    }
    
    func getEnclosedRange() -> ClosedRange<Date> {
        var dateClosedRange: ClosedRange<Date> {
            let min = Calendar.current.date(byAdding: .second, value: -1, to: assessment.handIn!)!
            let max = Calendar.current.date(byAdding: .second, value: 1, to: assessment.due!)!
            return min...max
        }
        return dateClosedRange
    }
    
    func resolveAddToCalendarDesciption() -> String {
        
        if addToCalendar {
            if editing && hadCalendarEvent {
                return "A calendar event is already created"
            } else if editing && !hadCalendarEvent {
                return "A calendar event will be created for this task"
            } else {
                return "A calendar event will be created"
            }
        } else {
            if editing && hadCalendarEvent {
                return "The calendar event will be removed"
            } else if editing && !hadCalendarEvent {
                return "No calendar events created for this task"
            } else {
                return "No calendar events will be created"
            }
        }
        
    }
    
    
    // MARK: Event Handlers
    
    func onAddButtonClicked() -> Void {
        
        if !isFormValid() {
            return
        }
        
        if addToCalendar {
            executeIfHasPermission {
                CalendarManager.shared.createEvent(self.constructCalendarEvent()) { (res: CalendarManagerResponse) in
                    if case .created(let identifier) = res {
                        self.__createTaskModel(identifier: identifier)
                    } else if res == .error(.eventAlreadyExistsInCalendar) {
                        self.message.alert(
                            title: "Duplicate Event",
                            message: "There's a event already in the caledar with the same name, notes, date, and alarms!"
                        )
                    } else {
                        self.message.alert(
                            title: "Cannot Create Calendar Event",
                            message: "Failed to create calendar event and therefore cannot create this task!"
                        )
                    }
                }
            }
        } else {
            self.__createTaskModel(identifier: nil)
        }
        
    }
    
    func onSaveButtonClicked() -> Void {
        
        if !isFormValid() {
            return
        }
        
        // DELETE THE CALENDAR EVENT AND UPDATE THE MODEL
        if !addToCalendar && hadCalendarEvent {
            executeIfHasPermission {
                CalendarManager.shared.deleteEvent(self.task!.eventIdentifier!) { (res) in
                    /// No matter whats the response is we should force remove the eventIdentifier from the
                    /// existing model and save the changes.
                    self.task!.eventIdentifier = ""
                    self.__updateTaskModel()
                }
            }
            return
        }
        
        // CREATE A CALENDAR EVENT AND UPDATE MODEL
        if addToCalendar && !hadCalendarEvent {
            executeIfHasPermission {
                CalendarManager.shared.createEvent(self.constructCalendarEvent()) { (res: CalendarManagerResponse) in
                    if case .created(let identifier) = res {
                        self.task!.eventIdentifier = identifier
                        self.__updateTaskModel()
                        return
                    }
                    if case .error(.eventNotAddedToCalendar( _)) = res {
                        self.addToCalendar = false
                        self.__updateTaskModel()
                        self.message.alert(
                            title: "Failed to Add to Calendar",
                            message: "Please try adding this task to calendar later."
                        )
                        return
                    }
                    if res == .error(.eventAlreadyExistsInCalendar) {
                        self.addToCalendar = false
                        self.__updateTaskModel()
                        self.message.alert(
                            title: "Duplicate Event",
                            message: "Didn't create any new event because one is already created."
                        )
                        return
                    }
                }
            }
            return
        }
        
        // UPDATE THE EXISTING CALENDAR EVENT AND UPDATE THE MODEL
        if addToCalendar && hadCalendarEvent && calendarPropsChanged() {
            executeIfHasPermission {
                CalendarManager.shared.updateEvent(
                    eventIdentifier: self.task!.eventIdentifier!,
                    updatedEvent: self.constructCalendarEvent()
                ) { (res) in
                    if case .created(let identifier) = res {
                        self.task!.eventIdentifier = identifier
                        self.__updateTaskModel()
                    } else if res == .updated {
                        self.__updateTaskModel()
                    } else if res == .error(.eventFailedToUpdate) {
                        self.message.alert(
                            title: "Failed to Update",
                            message: "Task did not save properly!"
                        )
                    }
                }
            }
            return
        }
        
        // OPTIMIZED CHECK IF NEEDED TO BE UPDATED
        if (addToCalendar && hadCalendarEvent && nonCalendarPropsChanged()) || anyPropChanged() {
            self.__updateTaskModel()
            return
        }
        
        // NO UPDATES
        self.show = false
        self.message.toast(
            title: "No Changes",
            message: "You didn't make any changes to update the task.",
            type: .info
        )
        
    }
    
    // MARK: Mutating Functions
    
    private func __updateTaskModel() -> Void {
        
        task!.name = name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .controlCharacters)
            .trimmingCharacters(in: .illegalCharacters)
        task!.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        task!.addToCalendar = addToCalendar
        task!.progress = Int16(progress)
        task!.handIn = handInDate.resetSeconds()!
        task!.due = dueDate.resetSeconds()!
        task!.reminderBefore = reminderList[selectedReminder]
        // updatedAt is attached in a lifecycle hook
        
        do {
            moc.refresh(task!, mergeChanges: true)
            try moc.save()
            self.show = false
            moc.refreshAllObjects()
            message.toast(
                title: "Updated Task",
                message:"You have successfully updated \(task!.name!) Task.",
                type: .success
            )
        } catch let error {
            message.alert(title: "Couldn't update task", message: error.localizedDescription)
        }
        
    }
    
    private func __createTaskModel(identifier: String?) -> Void {
        
        if addToCalendar && identifier == nil {
            message.alert(
                title: "Unknown Identifier",
                message: "Failed create calendar event and therefore unable to create assessment."
            )
            return
        }
        
        let newTask = Task(context: moc)
        
        newTask.name = name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .controlCharacters)
            .trimmingCharacters(in: .illegalCharacters)
        newTask.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        newTask.addToCalendar = addToCalendar
        newTask.progress = 0
        newTask.reminderBefore = addToCalendar ? reminderList[selectedReminder] : AlarmOffset.none.rawValue
        newTask.handIn = handInDate.resetSeconds()!
        newTask.due = dueDate.resetSeconds()!
        newTask.eventIdentifier = identifier ?? ""
        newTask.assessment = self.assessment
        // updatedAt, createdAt, id are attached in lifecycle hooks
        
        do {
            moc.insert(newTask)
            try moc.save()
            self.show = false
            message.toast(
                title: "Created Task",
                message: "You have successfully created \(newTask.name!) Task.",
                type: .success
            )
        } catch let error {
            message.alert(
                title: "Couldn't save task",
                message: error.localizedDescription
            )
        }
        
    }
    
    // MARK: Validators
    
    private func isFormValid() -> Bool {
        
        if !name.matches(regex: NAME_REGEX!) {
            message.alert(
                title: "Invalid Name",
                message: "Assessment name should be atleast 3 characters and must not" +
                " exceed 50 characters and should not contain special characters."
            )
            return false
        }
        
        if !(notes.count <= 150) {
            message.alert(
                title: "Notes Too Large",
                message: "Task notes should not exceed 150 characters. Keep it simple!"
            )
            return false
        }
        
        let (start, end) = (handInDate.resetSeconds()!, dueDate.resetSeconds()!)
        if (start.compare(end) == .orderedDescending) || (start.compare(end) == .orderedSame) {
            message.alert(
                title: "Date Range Out of Order",
                message: "Hand-in date should always be less than the due date."
            )
            return false
        }
        
        return true
        
    }
    
    // MARK: Permissions
    
    private func executeIfHasPermission(task: @escaping () -> Void) -> Void {
        CalendarManager.shared.doCheckPermissions { (response: CalendarManagerResponse) in
            if response == .success {
                task()
            } else if response == .error(.calendarAccessDeniedOrRestricted) {
                self.message.alert(
                    title: "Access Denied",
                    message: "Please grant access to the calendar. Settings > Privacy > Assessment Planner > Calendar"
                )
            } else {
                self.message.alert(
                    title: "Unexpected Error",
                    message: "Cannot access to calendar application."
                )
            }
        }
    }
    
    // MARK: Helper Functions
    
    private func calendarPropsChanged() -> Bool {
        return (task!.name! != name ||
            task!.reminderBefore != reminderList[selectedReminder] ||
            task!.handIn!.compare(handInDate) != .orderedSame ||
            task!.due!.compare(dueDate) != .orderedSame ||
            task!.notes! != notes)
    }
    
    private func nonCalendarPropsChanged() -> Bool {
        return task!.progress != Int(self.progress)
    }
    
    private func anyPropChanged() -> Bool {
        return (task!.name! != name ||
            task!.reminderBefore != reminderList[selectedReminder] ||
            task!.handIn!.compare(handInDate) != .orderedSame ||
            task!.due!.compare(dueDate) != .orderedSame ||
            task!.progress != Int(progress) ||
            task!.notes! != notes)
    }
    
    private func constructCalendarEvent() -> CalendarEvent {
        let event = CalendarEvent(
            title: self.name,
            startDate: self.handInDate,
            endDate: self.dueDate,
            notes: self.notes,
            alarmOffset: AlarmOffset.fromRawValue(str: self.reminderList[self.selectedReminder])
        )
        return event
    }
    
}
