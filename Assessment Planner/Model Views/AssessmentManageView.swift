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
    
    @EnvironmentObject var appState: GlobalState
    @Environment(\.managedObjectContext) var managedObjectContext
    @FetchRequest(fetchRequest: Module.getAllModules()) var modules: FetchedResults<Module>
    
    @State var reminderList: [String] = AlarmOffset.rawValues()
    @State var priorityList: [String] = AssessmentPriority.values()
    @Binding var show: Bool
    @State var mulTextFieldHeight: CGFloat = 70
    
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
    
    @State var shouldDisableSubmit: Bool = true
    
    // MARK: Editing transformer state
    
    @State var editing: Bool = false
    @State var assessment: Assessment? = nil
    @State var hadCalendarEvent: Bool = false
    
    // MARK: View declaraction
    
    var body: some View {
        FormModalWrapper(
            submitButtonText: editing ? "Save" : "Add",
            onSubmit: editing ? self.onSaveButtonClick : self.onAddButtonClick,
            disableSubmit: $shouldDisableSubmit,
            show: $show, title: editing ? "Editing: \(self.assessment!.name!)" : "Create New Assessment") {
                moduleFormField
                nameFormField
                HStack {
                    weightageFormField
                    if editing { // Initially this is hidden
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
            if self.editing {
                // Invariant
                assert(self.assessment != nil, "nil assessment cannot edit")
                // Mutate the state back to old properties. This a delayed task
                // not to conflict with the rendering process.
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
        
        let valBind = Binding<String>(get: {
            self.name
        }, set: {
            self.name = $0
            print("changed name")
        })
        
        return FormElementWrapper {
            Text("Assessment Name").font(.headline)
            TextField("Coursework 2", text: valBind, onEditingChanged: { _ in
                self.checkFormValidity()
                
            })
        }
        
    }
    
    var weightageFormField: some View {
        FormElementWrapper {
            Text("Weightage %").font(.headline)
            TextField("50%", text: self.$weightage, onEditingChanged: { _ in self.checkFormValidity() }).keyboardType(.decimalPad)
        }
    }
    
    var markAchievedField: some View {
        FormElementWrapper {
            Text("Mark Achieved %")
                .font(.headline)
            TextField("95", text: self.$markAchieved, onEditingChanged: { _ in self.checkFormValidity() })
                .keyboardType(.numberPad)
        }
    }
    
    var notesFormField: some View {
        FormElementWrapper {
            Text("Notes (Optional)")
                .font(.headline)
            VStack {
                MultilineTextField(text: $notes, height: $mulTextFieldHeight, onEditingChanged: {
                    print("changed", self.notes)
                }).animation(.linear)
                    .frame(height: mulTextFieldHeight)
                
            }
            //            TextField(
            //                "Enter notes here....",
            //                text: $notes,onEditingChanged: { _ in self.checkFormValidity() })
            //                .lineLimit(nil)
            //                .multilineTextAlignment(.leading)
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
                    Text(addToCalendar ?
                        "A calendar event will be created" : "No calendar event will be created")
                        .font(.body)
                        .foregroundColor(Color.gray)
                    Image(systemName: addToCalendar ?
                        "checkmark.circle.fill" : "multiply.square.fill")
                        .font(.body)
                        .foregroundColor(addToCalendar ? Color.green : Color.orange)
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
    
    func mapObjectToState() -> Void {
        
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
    
    func delayedExecution(task: @escaping () -> Void) -> Void {
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 5,
            execute: DispatchWorkItem { task() }
        )
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
                        self.createAssessmentModel(identifier: identifier)
                    } else if res == .error(.eventAlreadyExistsInCalendar) {
                        self.appState.showAlert(
                            title: "Duplicate Event",
                            message: "There's a event already in the caledar with the same name, notes, date ranges, and alarms!"
                        )
                    } else {
                        self.appState.showAlert(
                            title: "Cannot Create Calendar Event",
                            message: "Failed to create calendar event and therefore cannot create this  assessment!"
                        )
                    }
                }
            }
        } else {
            /// If this block executes it means user did not selected any
            /// calendar events. We can create a clean assessment.
            self.createAssessmentModel(identifier: nil)
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
        
        /// `DELETE EVENT AND UPDATE MODEL` remove the event from the assessment and the calendar.
        if !addToCalendar && self.hadCalendarEvent {
            self.selectedReminder = reminderList.firstIndex(of: AlarmOffset.none.rawValue)!
            self.executeIfHasPermission {
                CalendarManager.shared.deleteEvent(self.assessment!.eventIdentifier!) { (res) in
                    /// no matter whats the response is we should force remove the eventIdentifier and update it in the model.
                    self.assessment!.eventIdentifier = ""
                    self.updateAssessmentModel()
                    print("assessment: removed calendar event")
                }
            }
            return
        }
        
        /// `CREATE EVENT AND UPDATE MODEL` create a new calendar event for this assessment
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
                    /// New event is created for the existing assessment model now we
                    /// can assign the identifier and proceed to save it in the
                    /// core-data container.
                    if case .created(let identifier) = res {
                        self.assessment!.eventIdentifier = identifier
                        self.updateAssessmentModel()
                        print("assessment: created a new event in the calendar")
                        return
                    }
                    /// Failed to create and add the event to the calendar. However we still can
                    /// save the task without the `calendar event` and the `reminder`.
                    /// We also need to revert the current state back to default to indicate attempt was
                    /// not successfull.
                    if case .error(.eventNotAddedToCalendar(let message)) = res {
                        self.addToCalendar = false
                        self.selectedReminder = 0
                        self.updateAssessmentModel()
                        print("assessment: event not added to the calendar. but updated the model", message)
                        return
                    }
                    /// Detected an identical event in the calendar event store. in this case
                    /// it's safe to leave it as it is and inform the user that event was not created
                    /// and revert the state back to default and save the task without the
                    /// `calendar event` and the `reminder`
                    if res == .error(.eventAlreadyExistsInCalendar) {
                        self.addToCalendar = false
                        self.selectedReminder = 0
                        self.updateAssessmentModel()
                        self.appState.showAlert(
                            title: "Cannot Create Calendar Event",
                            message: "There's a identical event in the calendar. Therefore cannot create a event for this assessment."
                        )
                        print("assessment: event not added to the calendar because it already exists!")
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
            
            if  self.assessment!.name! != name ||
                self.assessment!.reminderBefore != reminderList[self.selectedReminder] ||
                self.assessment!.handIn!.compare(handInDate) != .orderedSame ||
                self.assessment!.due!.compare(dueDate) != .orderedSame ||
                self.assessment!.notes! != notes
            {
                
                // if this block executes it means we need to update the calendar event.
                
                self.executeIfHasPermission {
                    CalendarManager.shared.updateEvent(
                        eventIdentifier: self.assessment!.eventIdentifier!,
                        updatedEvent: CalendarEvent(
                            title: self.name,
                            startDate: self.handInDate,
                            endDate: self.dueDate,
                            notes: self.notes,
                            alarmOffset: AlarmOffset.fromRawValue(str: self.reminderList[self.selectedReminder])
                    )) { (res) in
                        /// for some reaason the event for this assessment is not existed in the
                        /// event store, then simply just proceed to assign a new `eventIdentifier`
                        if case .created(let identifier) = res {
                            self.assessment!.eventIdentifier = identifier
                            self.updateAssessmentModel() /// update with new identifier
                            print("task: created a brand new event and assigned the new event id")
                        } else if res == .updated {
                            self.updateAssessmentModel()
                            print("updated the calendar event")
                        } else if res == .error(.eventFailedToUpdate) {
                            self.appState.showAlert(
                                title: "Failed to Update",
                                message: "Assessment did not save properly!"
                            )
                            print("task: failed to update the calendar event")
                        }
                    }
                }
                
            } else if (self.assessment!.module!.id?.uuidString != modules[selectedModule].id!.uuidString ||
                String(self.assessment!.weightage) != weightage ||
                String(self.assessment!.markAchieved) != markAchieved ||
                self.assessment!.priority! != priorityList[selectedPriority]) {
                // if this block executes it means we need to update this assessment
                // because one of the properties got changed! while add to calendar is clicked
                self.updateAssessmentModel()
            }
            return
        }
        
        if  self.assessment!.name! != name ||
            self.assessment!.reminderBefore != reminderList[self.selectedReminder] ||
            self.assessment!.handIn!.compare(handInDate) != .orderedSame ||
            self.assessment!.due!.compare(dueDate) != .orderedSame ||
            self.assessment!.notes! != notes ||
            self.assessment!.module!.id?.uuidString != modules[selectedModule].id!.uuidString ||
            String(self.assessment!.weightage) != weightage ||
            String(self.assessment!.markAchieved) != markAchieved ||
            self.assessment!.priority! != priorityList[selectedPriority]
        {
            self.updateAssessmentModel()
            print("updated by default")
        } else {
            self.show = false
            self.appState.showToast(
                title: "No Changes",
                detail: "You didn't make any changes to update the assessment.",
                type: .info
            )
        }
        
        
    }
    
    // MARK: Mutating Functions
    
    func updateAssessmentModel() -> Void {
        
        assessment!.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        assessment!.weightage = Int16(weightage)!
        assessment!.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        assessment!.priority = priorityList[selectedPriority]
        assessment!.addToCalendar = addToCalendar
        assessment!.markAchieved = Int16(markAchieved)!
        assessment!.handIn = handInDate
        assessment!.due = dueDate
        assessment!.module = modules[selectedModule]
        assessment!.reminderBefore = reminderList[selectedReminder]
        
        do {
            try managedObjectContext.save()
            self.managedObjectContext.refreshAllObjects()
            self.show = false
            self.appState.showToast(
                title: "Updated Assessment",
                detail: "You have successfully updated \(assessment!.name!) Assessment.",
                type: .success
            )
        } catch let error {
            self.show = false
            self.appState.showAlert(
                title: "Couldn't update assessment",
                message: error.localizedDescription
            )
        }
        
    }
    
    func createAssessmentModel(identifier: String?) -> Void {
        
        if addToCalendar && identifier == nil {
            self.appState.showAlert(
                title: "Unknown Identifier",
                message: "Couldn't create calendar event!"
            )
            return
        }
        
        let assessment = Assessment(context: self.managedObjectContext)
        
        assessment.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        assessment.weightage = Int16(weightage)!
        assessment.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        assessment.priority = priorityList[selectedPriority]
        assessment.addToCalendar = addToCalendar
        assessment.eventIdentifier = identifier ?? ""
        assessment.markAchieved = Int16(0)
        assessment.handIn = handInDate
        assessment.due = dueDate
        assessment.module = modules[selectedModule] /// Assign the selected module
        assessment.tasks = []
        assessment.reminderBefore = addToCalendar ? reminderList[selectedReminder] : AlarmOffset.none.rawValue
        
        do {
            try managedObjectContext.save()
            self.show = false
            self.appState.showToast(
                title: "Created Assessment",
                detail: "You have successfully created \(assessment.name!) Assessment.",
                type: .success
            )
        } catch let error {
            self.show = false
            self.appState.showAlert(
                title: "Couldn't save assessment",
                message: error.localizedDescription
            )
        }
        
    }
    
    // MARK: Validator Functions
    
    func checkFormValidity() -> Void {
        
        /// Other fields are constrained inputs. There's no keyboard interactions
        /// with those fields.
        let isNameValid = name.matchesExact("^[ a-zA-Z\\d_.\\-]{3,50}$") /// ascii, max 3...50 char
        let notesValid = notes.count <= 200 /// max char count is 200
        let isWeightageValid = weightage.matchesExact("^(?:100|[1-9][0-9]|[0-9])$") /// 0...100
        let isMarkValid = markAchieved.matchesExact("^(?:100|[1-9][0-9]|[0-9])$") /// 0...100
        
        self.shouldDisableSubmit = (
            !isNameValid ||
                !notesValid ||
                !isWeightageValid ||
                !isMarkValid ||
                modules.count == 0
        )
        
    }
    
    func checkIfDatesAreValid() -> Bool {
        return self.handInDate.compare(self.dueDate) == .orderedAscending ||
            self.handInDate.compare(self.dueDate) == .orderedSame
    }
    
}
