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
    
    @EnvironmentObject var appState: GlobalState
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @State var reminderList: [String] = AlarmOffset.rawValues()
    
    // MARK: FormField variables
    
    @State var name: String = ""
    @State var notes: String = ""
    @State var addToCalendar: Bool = false
    @State var handInDate: Date = Date()
    @State var dueDate: Date = Date()
    @State var progress: Double = 0
    @State var selectedReminder: Int = 0
    
    // MARK: Assessment belonging this task
    
    var assessment: Assessment
    
    // MARK: Editing transformer state (Optional)
    
    @State var afterEditing: ((_ task: Task) -> Void)? = nil
    @State var editing: Bool = false
    @State var task: Task? = nil
    @State var hadCalendarEvent: Bool = false
    
    // MARK: Dynamic state properties of the view
    
    @Binding var show: Bool
    @State var shouldDisableSubmit: Bool = true
    
    // MARK: View components
    
    var body: some View {
        FormModalWrapper(
            submitButtonText: editing ? "Save" : "Add",
            onSubmit: editing ? self.onSaveButtonClick : self.onAddButtonClick,
            disableSubmit: $shouldDisableSubmit,
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
            if self.editing {
                /// Validate invariant
                assert(self.task != nil, "nil task! cannot edit")
                /// Mutate the state back to old properties. This a delayed task
                /// not to conflict with the rendering process.
                DispatchQueue.main.asyncAfter(
                    deadline: .now(),
                    execute: DispatchWorkItem {
                        self.mapObjectToState()
                        self.checkFormValidity()
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
                text: $name,
                onEditingChanged: { _ in self.checkFormValidity() }
            )
        }.frame(minWidth: 0, maxWidth: .infinity)
    }
    
    var notesFormField: some View {
        FormElementWrapper {
            Text("Task Notes (Optional)")
                .font(.headline)
            TextField(
                "Enter notes here....",
                text: $notes,
                onEditingChanged: { _ in self.checkFormValidity() }
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
                    Text(addToCalendar ?
                        "A calendar event will be created for this task" : "No calendar event will be created")
                        .font(.body)
                        .foregroundColor(Color.gray)
                    Image(systemName: addToCalendar ?
                        "checkmark.circle.fill" : "multiply.square.fill")
                        .font(.body)
                        .foregroundColor(addToCalendar ? Color.green : Color.orange)
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
                    in: self.getValidRange(),
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
                    in: self.getValidRange(),
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
            Text("Task Progress (%)")
                .font(.headline)
            HStack(alignment: .center) {
                Text("\(Int(progress))%")
                    .font(.headline)
                    //.fontWeight(.light)
                    .padding()
                    .background(
                        Circle().foregroundColor(Color.green)
                )
            }.frame(minWidth: 0, maxWidth: .infinity)
            Slider(value: $progress, in: 0...100, step: 1, onEditingChanged: {_ in
                self.checkFormValidity()
            })
        }
    }
    
    // MARK: Convenient functions
    
    func mapObjectToState() -> Void {
        
        name = self.task!.name!
        addToCalendar = self.task!.addToCalendar
        dueDate = self.task!.due!
        handInDate = self.task!.handIn!
        notes = self.task!.notes!
        progress = Double(self.task!.progress)
        selectedReminder = self.reminderList.firstIndex(of: self.task!.reminderBefore!)!
        
        self.hadCalendarEvent = self.task!.addToCalendar
        
    }
    
    func executeIfHasPermission(task: @escaping () -> Void) -> Void {
        CalendarManager.shared.doCheckPermissions { (response: CalendarManagerResponse) in
            if response == .success {
                task()
            } else if response == .error(.calendarAccessDeniedOrRestricted) {
                self.appState.showAlert(
                    title: "Access Denied",
                    message: "Please grant access to the calendar. Settings > Privacy > Assessment Planner > Calendar"
                )
            } else {
                self.appState.showAlert(
                    title: "Unexpected Error",
                    message: "Cannot access to calendar application."
                )
            }
        }
    }
    
    func getValidRange() -> ClosedRange<Date> {
        var dateClosedRange: ClosedRange<Date> {
            let min = Calendar.current.date(byAdding: .second, value: -1, to: self.assessment.handIn!)!
            let max = Calendar.current.date(byAdding: .second, value: 1, to: self.assessment.due!)!
            return min...max
        }
        return dateClosedRange
    }
    
    // MARK: Event handlers
    
    func onAddButtonClick() -> Void {
        
        /// check if the date range is out of order
        if !checkIfDatesAreValid() {
            self.appState.showAlert(
                title: "Invalid Date Range",
                message: "Date range is out of order! Make sure hand-in date is always less than the due date."
            )
            return
        }
        
        if addToCalendar {
            /// this block executes when user has selected a calendar
            /// event and a reminder offset.
            self.executeIfHasPermission {
                CalendarManager.shared.createEvent(CalendarEvent(
                    title: self.name,
                    startDate: self.handInDate,
                    endDate: self.dueDate,
                    notes: self.notes,
                    alarmOffset: AlarmOffset.fromRawValue(str: self.reminderList[self.selectedReminder])
                )) { (res: CalendarManagerResponse) in
                    
                    if case .created(let identifier) = res {
                        self.createTaskModel(identifier: identifier)
                    } else if res == .error(.eventAlreadyExistsInCalendar) {
                        self.appState.showAlert(
                            title: "Duplicate Event",
                            message: "There's a event already in the caledar with the same name, notes, date ranges, and alarms!"
                        )
                    } else {
                        self.appState.showAlert(
                            title: "Cannot Create Calendar Event",
                            message: "Failed to create calendar event and therefore cannot create this task!"
                        )
                    }
                    
                }
            }
        } else {
            /// If this block executes it means user did not selected any
            /// calendar events. We can create a clean task.
            self.createTaskModel(identifier: nil)
        }
        
    }
    
    func onSaveButtonClick() -> Void {
        
        /// Check if the date range is out of order
        if !checkIfDatesAreValid() {
            self.appState.showAlert(
                title: "Invalid Date Range",
                message: "Date range is out of order! Make sure hand-in date is always less than the due date."
            )
            return
        }
        
        /// `DELETE EVENT AND UPDATE MODEL` remove the event from the task and the calendar.
        if !addToCalendar && self.hadCalendarEvent {
            self.selectedReminder = reminderList.firstIndex(of: AlarmOffset.none.rawValue)!
            self.executeIfHasPermission {
                CalendarManager.shared.deleteEvent(self.task!.eventIdentifier!) { (res) in
                    /// no matter whats the response is we should force remove the eventIdentifier and update it in the model.
                    self.task!.eventIdentifier = ""
                    self.updateTaskModel()
                    print("task: removed calendar event")
                }
            }
            return
        }
        
        /// `CREATE EVENT AND UPDATE MODEL` create a new calendar event for this task
        if addToCalendar && !self.hadCalendarEvent {
            self.executeIfHasPermission {
                let event = CalendarEvent(
                    title: self.name,
                    startDate: self.handInDate,
                    endDate: self.dueDate,
                    notes: self.notes,
                    alarmOffset: AlarmOffset.fromRawValue(str: self.reminderList[self.selectedReminder])
                )
                CalendarManager.shared.createEvent(event) { (res: CalendarManagerResponse) in
                    /// New event is created for the existing task model now we
                    /// can assign the identifier and proceed to save it in the
                    /// core-data container.
                    if case .created(let identifier) = res {
                        self.task!.eventIdentifier = identifier
                        self.updateTaskModel()
                        print("task: created a new event in the calendar")
                        return
                    }
                    /// Failed to create and add the event to the calendar. However we still can
                    /// save the task without the `calendar event` and the `reminder`.
                    /// We also need to revert the current state back to default to indicate attempt was
                    /// not successfull.
                    if case .error(.eventNotAddedToCalendar(let message)) = res {
                        self.addToCalendar = false
                        self.selectedReminder = 0
                        self.updateTaskModel()
                        print("task: event not added to the calendar. but updated the model", message)
                        return
                    }
                    /// Detected an identical event in the calendar event store. in this case
                    /// it's safe to leave it as it is and inform the user that event was not created
                    /// and revert the state back to default and save the task without the
                    /// `calendar event` and the `reminder`
                    if res == .error(.eventAlreadyExistsInCalendar) {
                        self.addToCalendar = false
                        self.selectedReminder = 0
                        self.updateTaskModel()
                        self.appState.showAlert(
                            title: "Cannot Create Calendar Event",
                            message: "There's a identical event in the calendar. Therefore cannot create a event for this task."
                        )
                        print("task: event not added to the calendar because it already exists!")
                        return
                    }
                }
            }
            return
        }
        
        /// Optimized check if need to be updated
        if addToCalendar && self.hadCalendarEvent {
            
            /// first we check whether we need to do some changes to the
            /// calendar event by simply checking the properties used for
            /// creating a calendar event.
            
            if  self.task!.name! != name ||
                self.task!.reminderBefore != reminderList[self.selectedReminder] ||
                self.task!.handIn!.compare(handInDate) != .orderedSame ||
                self.task!.due!.compare(dueDate) != .orderedSame ||
                self.task!.notes! != notes
            {
                
                /// yes there are changes in the state so we need to update the calendar event.
                
                self.executeIfHasPermission {
                    let event = CalendarEvent(
                        title: self.name,
                        startDate: self.handInDate,
                        endDate: self.dueDate,
                        notes: self.notes,
                        alarmOffset: AlarmOffset.fromRawValue(str: self.reminderList[self.selectedReminder])
                    )
                    CalendarManager.shared.updateEvent(
                        eventIdentifier: self.task!.eventIdentifier!,
                        updatedEvent: event
                    ) { (res) in
                        /// for some reason the event for this task is not existed in the
                        /// event store, then simply just proceed to assign a new `eventIdentifier`
                        if case .created(let identifier) = res {
                            self.task!.eventIdentifier = identifier
                            self.updateTaskModel() /// update with new identifier
                            print("task: created a brand new event and assigned the new event id")
                        } else if res == .updated {
                            self.updateTaskModel()
                            print("task: updated the calendar event")
                        } else if res == .error(.eventFailedToUpdate) {
                            self.appState.showAlert(
                                title: "Failed to Update",
                                message: "Task did not save properly!"
                            )
                            print("task: failed to update the calendar event")
                        }
                    }
                }
                
            } else if Double(self.task!.progress) != Double(progress) {
                /// if this block executes it means we need to update this task
                /// because progress property got changed!
                self.updateTaskModel()
            }
            return
            
        }
        
        if  self.task!.name! != name ||
            self.task!.reminderBefore != reminderList[self.selectedReminder] ||
            self.task!.handIn!.compare(handInDate) != .orderedSame ||
            self.task!.due!.compare(dueDate) != .orderedSame ||
            self.task!.notes! != notes ||
            Double(self.task!.progress) != Double(progress)
        {
            self.updateTaskModel()
            print("task: updated by default")
        } else {
            self.show = false
            self.appState.showToast(
                title: "No Changes",
                detail: "You didn't make any changes to update the task.",
                type: .info
            )
        }
        
    }
    
    // MARK: Mutating Functions
    
    func updateTaskModel() -> Void {
        
        task!.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        task!.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        task!.addToCalendar = addToCalendar
        task!.progress = Int16(progress)
        task!.handIn = handInDate
        task!.due = dueDate
        task!.reminderBefore = reminderList[selectedReminder]
        
        do {
            self.managedObjectContext.refresh(task!, mergeChanges: true)
            self.managedObjectContext.refreshAllObjects()
            try managedObjectContext.save()
            self.show = false
            if self.editing && self.afterEditing != nil {
                self.afterEditing!(self.task!)
            }
            self.appState.showToast(
                title: "Updated Task",
                detail: "You have successfully updated \(self.task!.name!) Task.",
                type: .success
            )
        } catch let error {
            self.show = false
            self.appState.showAlert(
                title: "Couldn't update task",
                message: error.localizedDescription
            )
        }
        
    }
    
    func createTaskModel(identifier: String?) -> Void {
        
        if addToCalendar && identifier == nil {
            self.appState.showAlert(
                title: "Unknown Identifier",
                message: "Couldn't create calendar event for the task!"
            )
            return
        }
        
        let newTask = Task(context: self.managedObjectContext)
        
        newTask.due = self.dueDate
        newTask.name = self.name.trimmingCharacters(in: .whitespacesAndNewlines)
        newTask.notes = self.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        newTask.addToCalendar = self.addToCalendar
        newTask.progress = 0
        newTask.reminderBefore = self.addToCalendar ? self.reminderList[self.selectedReminder] : AlarmOffset.none.rawValue
        newTask.handIn = handInDate
        newTask.eventIdentifier = identifier ?? ""
        newTask.assessment = self.assessment
        
        do {
            managedObjectContext.insert(newTask)
            try managedObjectContext.save()
            self.show = false
            self.appState.showToast(
                title: "Created Task",
                detail: "You have successfully created \(newTask.name!) task.",
                type: .success
            )
        } catch let error {
            self.appState.showAlert(
                title: "Couldn't save task",
                message: error.localizedDescription
            )
        }
        
    }
    
    // MARK: Validator Functions
    
    func checkFormValidity() -> Void {
        let isNameValid = name.matchesExact("^[ a-zA-Z\\d_.\\-]{3,50}$") // ascii, max 3...50 char
        let isNotesValid = notes.count <= 200 // max char count is 200
        let isProgressValid = String(Int(progress)).matchesExact("^(?:100|[1-9][0-9]|[0-9])$") // 0...100
        self.shouldDisableSubmit = (
            !isNameValid ||
                !isNotesValid ||
                !isProgressValid
        )
    }
    
    func checkIfDatesAreValid() -> Bool {
        return self.handInDate.compare(self.dueDate) == .orderedAscending ||
            self.handInDate.compare(self.dueDate) == .orderedSame
    }
    
}
