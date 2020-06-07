//
//  AssessmentManageView.swift
//  Assessment Planner
//
//  Created by Yasin on 6/6/20.
//  Copyright © 2020 Yasin. All rights reserved.
//

import SwiftUI
import Combine

struct AssessmentManageView: View {
    
    // MARK: Pre-Compile the Regex Patterns
    
    private let NAME_REGEX = try? NSRegularExpression(pattern: "^[ a-zA-Z\\d_.\\-]{3,50}$")
    private let RANGE_0_TO_100_REGEX = try? NSRegularExpression(pattern: "^(?:100|[1-9][0-9]|[0-9])$")
    
    @EnvironmentObject var message: AlertManager
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(fetchRequest: Module.getAllModules()) var modules: FetchedResults<Module>
    @State var reminderList: [String] = AlarmOffset.rawValues()
    @State var priorityList: [String] = AssessmentPriority.values()
    // Needed for dynamically adjusting the `notes textview`
    @State var mulTextFieldHeight: CGFloat = 80
    
    @Binding var show: Bool
    
    @State var selectedModule: Int = 0
    @State var name: String = ""
    @State var addToCalendar: Bool = false
    @State var dueDate: Date = Date()
    @State var handInDate: Date = Date()
    @State var notes: String = ""
    @State var selectedPriority: Int = 1
    @State var weightage: String = "0"
    @State var markAchieved: String = "0"
    @State var selectedReminder: Int = 0
    @State var hadCalendarEvent: Bool = false
    
    // MARK: Editing transformer state
    // Pass down from the parent when editing an assessment
    
    @State var editing: Bool = false
    @State var assessment: Assessment? = nil
    
    // MARK: View declaraction
    
    var body: some View {
        FormModalWrapper(
            submitButtonText: editing ? "Save" : "Add",
            onSubmit: editing ? self.onSaveButtonClick : self.onAddButtonClick,
            disableSubmit: .constant(false),
            show: $show, title: editing ? "Editing: \(self.assessment!.name!)" : "Create New Assessment") {
                moduleFormField
                nameFormField
                HStack {
                    weightageFormField
                    if editing { /// Initially this is hidden
                        markAchievedField
                    }
                }
                notesFormField
                priorityFormField
                addToCalendarFormField
                reminderFormField
                handInDateFormField
                dueDateFormField
        }.onAppear {
            if self.editing && self.assessment != nil {
                /// Mutate the state back to old properties. This a delayed task to ensure
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
    
    // MARK: FormField UI elements
    
    var moduleFormField: some View {
        FormElementWrapper {
            HStack {
                Text("Select the Module")
                    .font(.headline)
                Text("(\(self.modules.count) Available)")
                    .font(.callout)
            }
            HStack {
                if self.modules.count == 0 {
                    Text("Please Create a Module First!")
                        .padding()
                        .foregroundColor(.gray)
                } else {
                    Picker(selection: self.$selectedModule, label: Text("Module")) {
                        ForEach(0..<self.modules.count, id: \.self) { (index) in
                            Text(self.modules[index].name!)
                                .font(.callout)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .labelsHidden()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 50)
            .clipped()
        }
    }
    
    var nameFormField: some View {
        FormElementWrapper {
            Text("Assessment Name").font(.headline)
            TextField("Coursework 2", text: $name)
        }
    }
    
    var weightageFormField: some View {
        FormElementWrapper {
            Text("Weightage %").font(.headline)
            TextField("50%", text: $weightage).keyboardType(.decimalPad)
        }
    }
    
    var markAchievedField: some View {
        FormElementWrapper {
            Text("Mark Achieved %")
                .font(.headline)
            TextField("95", text: $markAchieved)
                .keyboardType(.numberPad)
        }
    }
    
    var notesFormField: some View {
        FormElementWrapper {
            Text("Notes (Optional)")
                .font(.headline)
            MultilineTextField(text: $notes, height: $mulTextFieldHeight)
                .animation(.linear)
                .frame(height: mulTextFieldHeight)
        }
    }
    
    var priorityFormField: some View {
        FormElementWrapper {
            Text("Assessment Priority").font(.headline)
            Picker(selection: self.$selectedPriority, label: Text("Assessment Priority")){
                ForEach(0..<self.priorityList.count) { index in
                    Text(self.priorityList[index]).tag(index)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .labelsHidden()
        }
        .frame(minWidth: 100, maxWidth: .infinity)
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
        }
        .frame(minWidth: 100, maxWidth: .infinity)
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
            Text("Assessment Hand-In Date").font(.headline)
            HStack {
                DatePicker(
                    selection: $handInDate,
                    displayedComponents: [.hourAndMinute, .date],
                    label: { Text("Hand-In Date") }
                )
                    .labelsHidden()
                    .frame(height: 70)
                    .clipped()
            }.frame(minWidth: 100, maxWidth: .infinity)
        }
    }
    
    var dueDateFormField: some View {
        FormElementWrapper {
            Text("Assessment Due Date").font(.headline)
            HStack {
                DatePicker(
                    selection: $dueDate,
                    displayedComponents: [.hourAndMinute, .date],
                    label: { Text("Due Date") }
                )
                    .labelsHidden()
                    .frame(height: 70)
                    .clipped()
            }.frame(minWidth: 100, maxWidth: .infinity)
        }
    }
    
    // MARK: Convenient functions
    
    func mapFromExistingModel() -> Void {
        
        selectedModule = self.modules.firstIndex(of: self.assessment!.module!)!
        name = self.assessment!.name!
        addToCalendar = self.assessment!.addToCalendar
        dueDate = self.assessment!.due!
        handInDate = self.assessment!.handIn!
        notes = self.assessment!.notes!
        selectedPriority = self.priorityList.firstIndex(of: self.assessment!.priority!)!
        weightage = String(self.assessment!.weightage)
        markAchieved = String(self.assessment!.markAchieved)
        selectedReminder = self.reminderList.firstIndex(of: self.assessment!.reminderBefore!)!
        
        hadCalendarEvent = self.assessment!.addToCalendar
        
        // if add to calendar is present then check whether the calendar
        // event is present in the calendar event store. if not then set
        // state back to default values and reflect the changes in the model.
        
        if addToCalendar && self.assessment!.eventIdentifier! != "" {
            executeIfHasPermission {
                if !CalendarManager.shared.hasSuchEvent(id: self.assessment!.eventIdentifier!) {
                    DispatchQueue.main.async {
                        print("event is not present. defaulting calendar event state")
                        // reset current state
                        self.addToCalendar = false
                        self.hadCalendarEvent = false
                        self.selectedReminder = 0
                        // reset model
                        self.assessment!.eventIdentifier = ""
                        self.assessment!.addToCalendar = false
                        self.assessment?.reminderBefore = AlarmOffset.none.rawValue
                        try? self.moc.save()
                        self.moc.refreshAllObjects()
                    }
                }
            }
        }
        
    }
    
    func resolveAddToCalendarDesciption() -> String {
        
        if addToCalendar {
            if editing && hadCalendarEvent {
                return "A calendar event is already created"
            } else if editing && !hadCalendarEvent {
                return "A calendar event will be created for this assessment"
            } else {
                return "A calendar event will be created"
            }
        } else {
            if editing && hadCalendarEvent {
                return "The calendar event will be removed"
            } else if editing && !hadCalendarEvent {
                return "No calendar events created for this assessment"
            } else {
                return "No calendar events will be created"
            }
        }
        
    }
    
    
    // MARK: Event handlers
    
    func onAddButtonClick() -> Void {
        
        if !isFormValid() {
            return
        }
        
        if addToCalendar {
            executeIfHasPermission {
                /// This block executes when user want to add to calendar events with or without a reminder offset.
                CalendarManager.shared.createEvent(self.constructCalendarEvent()) { (res: CalendarManagerResponse) in
                    if case .created(let identifier) = res {
                        self.__createAssessmentModel(identifier: identifier)
                    } else if res == .error(.eventAlreadyExistsInCalendar) {
                        self.message.alert(
                            title: "Duplicate Event",
                            message: "There's a event already in the caledar with the same name, notes, date, and alarms!"
                        )
                    } else {
                        self.message.alert(
                            title: "Cannot Create Calendar Event",
                            message: "Failed to create calendar event and therefore cannot create this assessment!"
                        )
                    }
                }
            }
        } else {
            /// If this block executes it means user did not selected any calendar events. We can create a clean assessment.
            self.__createAssessmentModel(identifier: nil)
        }
        
    }
    
    func onSaveButtonClick() -> Void {
        
        if !isFormValid() {
            return
        }
        
        // DELETE THE CALENDAR EVENT AND UPDATE THE MODEL
        if !addToCalendar && hadCalendarEvent {
            executeIfHasPermission {
                CalendarManager.shared.deleteEvent(self.assessment!.eventIdentifier!) { (res) in
                    /// No matter whats the response is we should force remove the eventIdentifier from the
                    /// existing model and save the changes.
                    self.assessment!.eventIdentifier = ""
                    self.__updateAssessmentModel()
                }
            }
            return
        }
        
        // CREATE A CALENDAR EVENT AND UPDATE MODEL
        if addToCalendar && !hadCalendarEvent {
            executeIfHasPermission {
                CalendarManager.shared.createEvent(self.constructCalendarEvent()) { (res: CalendarManagerResponse) in
                    /// New event is created for the existing assessment model now we can assign the identifier and proceed to save it in the core-data container.
                    if case .created(let identifier) = res {
                        self.assessment!.eventIdentifier = identifier
                        self.__updateAssessmentModel()
                        return
                    }
                    /// Failed to create and add the event to the calendar. However we still can save the task without the `calendar event` and the `reminder`. We also need
                    /// to revert the current state back to default to indicate attempt was not successfull.
                    if case .error(.eventNotAddedToCalendar( _)) = res {
                        self.addToCalendar = false
                        self.__updateAssessmentModel()
                        self.message.alert(
                            title: "Failed to Add to Calendar",
                            message: "Please try this operation again later."
                        )
                        return
                    }
                    /// Detected an identical event in the calendar event store. in this case it's safe to leave it as it is and inform the user that event was not created and revert the state
                    /// back to default and save the task without the `calendar event` and the `reminder`
                    if res == .error(.eventAlreadyExistsInCalendar) {
                        self.addToCalendar = false
                        self.__updateAssessmentModel()
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
        if addToCalendar && hadCalendarEvent && cPropsChanged() {
            executeIfHasPermission {
                CalendarManager.shared.updateEvent(
                    eventIdentifier: self.assessment!.eventIdentifier!,
                    updatedEvent: self.constructCalendarEvent()
                ) { (res) in
                    /// For some reason the event for this assessment is not existed in the event store, then simply just proceed to assign a new `eventIdentifier`
                    if case .created(let identifier) = res {
                        self.assessment!.eventIdentifier = identifier
                        self.__updateAssessmentModel() /// update with new identifier
                    } else if res == .updated {
                        self.__updateAssessmentModel()
                    } else if res == .error(.eventFailedToUpdate) {
                        self.message.alert(
                            title: "Failed to Update",
                            message: "Assessment did not save properly!"
                        )
                    }
                }
            }
            return
        }
        
        // OPTIMIZED CHECK IF NEEDED TO BE UPDATED
        if (addToCalendar && hadCalendarEvent && ncPropsChanged()) || propsChanged() {
            self.__updateAssessmentModel()
            return
        }
        
        // NO UPDATES
        self.show = false
        self.message.toast(
            title: "No Changes",
            message: "You didn't make any changes to update the assessment.",
            type: .info
        )
        
    }
    
    
    // MARK: Mutating Functions
    
    private func __updateAssessmentModel() -> Void {
        
        assessment!.name = name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .controlCharacters)
            .trimmingCharacters(in: .illegalCharacters)
        assessment!.weightage = Int16(weightage)!
        assessment!.notes = notes.trimmingCharacters(in: .whitespaces)
        assessment!.priority = priorityList[selectedPriority]
        assessment!.addToCalendar = addToCalendar
        assessment!.markAchieved = Int16(markAchieved)!
        assessment!.handIn = handInDate.resetSeconds()!
        assessment!.due = dueDate.resetSeconds()!
        assessment!.module = modules[selectedModule]
        assessment!.reminderBefore = addToCalendar ? reminderList[selectedReminder] : AlarmOffset.none.rawValue
        // updatedAt is attached in a lifecycle hook
        
        do {
            try moc.save()
            moc.refreshAllObjects()
            self.show = false
            message.toast(
                title: "Updated Assessment",
                message:"You have successfully updated \(assessment!.name!) Assessment.",
                type: .success
            )
        } catch let error {
            message.alert(title: "Couldn't update assessment", message: error.localizedDescription)
        }
        
    }
    
    private func __createAssessmentModel(identifier: String?) -> Void {
        
        if addToCalendar && identifier == nil {
            message.alert(
                title: "Unknown Identifier",
                message: "Failed create calendar event and therefore unable to create the assessment."
            )
            return
        }
        
        let assessment = Assessment(context: moc)
        
        assessment.name = name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .controlCharacters)
            .trimmingCharacters(in: .illegalCharacters)
        assessment.weightage = Int16(weightage)!
        assessment.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        assessment.priority = priorityList[selectedPriority]
        assessment.addToCalendar = addToCalendar
        assessment.eventIdentifier = identifier ?? "" /// only if addToCalendar is true
        assessment.markAchieved = Int16(0) /// initially this is 0
        assessment.handIn = handInDate.resetSeconds()!
        assessment.due = dueDate.resetSeconds()!
        assessment.module = modules[selectedModule] /// Assign the selected module
        assessment.tasks = []
        assessment.reminderBefore = addToCalendar ? reminderList[selectedReminder] : AlarmOffset.none.rawValue
        // updatedAt, createdAt, id are attached in lifecycle hooks
        
        do {
            try moc.save()
            self.show = false
            message.toast(
                title: "Created Assessment",
                message: "You have successfully created \(assessment.name!) assessment.",
                type: .success
            )
        } catch let error {
            message.alert(
                title: "Couldn't save assessment",
                message: error.localizedDescription
            )
        }
        
    }
    
    
    // MARK: Validators
    
    private func isFormValid() -> Bool {
        
        if modules.count == 0 {
            message.alert(
                title: "No Module Found!",
                message: "Before adding a assessment you must create and assign a module."
            )
            return false
        }
        
        if !name.matches(regex: NAME_REGEX!) {
            message.alert(
                title: "Invalid Name",
                message: "Assessment name should be atleast 3 characters and must not" +
                " exceed 50 characters and should not contain special characters."
            )
            return false
        }
        
        if !(notes.count <= 200) {
            message.alert(
                title: "Notes Too Large",
                message: "Assessment notes should not exceed 200 characters"
            )
            return false
        }
        
        if !weightage.matches(regex: RANGE_0_TO_100_REGEX!) {
            message.alert(
                title: "Invalid Weightage Value",
                message: "Weightage must be in the range of 0 to 100"
            )
            return false
        }
        
        if !markAchieved.matches(regex: RANGE_0_TO_100_REGEX!) {
            message.alert(
                title: "Invalid Mark Value",
                message: "Mark achieved must be in the range of 0 to 100"
            )
            return false
        }
        
        let (start, end) = (handInDate.resetSeconds()!, dueDate.resetSeconds()!)
        if (start.compare(end) == .orderedDescending) || (start.compare(end) == .orderedSame) {
            message.alert(
                title: "Date Range Out of Order",
                message: "Hand-in date should always be less than the due date"
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
    
    private func cPropsChanged() -> Bool {
        return (assessment!.name! != name ||
            assessment!.reminderBefore != reminderList[selectedReminder] ||
            assessment!.handIn!.compare(handInDate) != .orderedSame ||
            assessment!.due!.compare(dueDate) != .orderedSame ||
            assessment!.notes! != notes)
    }
    
    private func ncPropsChanged() -> Bool {
        return (assessment!.module!.id?.uuidString != modules[selectedModule].id!.uuidString ||
            String(assessment!.weightage) != weightage ||
            String(assessment!.markAchieved) != markAchieved ||
            assessment!.priority! != priorityList[selectedPriority])
    }
    
    private func propsChanged() -> Bool {
        return (assessment!.name! != name ||
            assessment!.reminderBefore != reminderList[selectedReminder] ||
            assessment!.handIn!.compare(handInDate) != .orderedSame ||
            assessment!.due!.compare(dueDate) != .orderedSame ||
            assessment!.notes! != notes ||
            assessment!.module!.id?.uuidString != modules[selectedModule].id!.uuidString ||
            String(assessment!.weightage) != weightage ||
            String(assessment!.markAchieved) != markAchieved ||
            assessment!.priority! != priorityList[selectedPriority])
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
