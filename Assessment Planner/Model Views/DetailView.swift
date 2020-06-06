//
//  DetailView.swift
//  Assessment Planner
//
//  Created by Yasin on 6/6/20.
//  Copyright © 2020 Yasin. All rights reserved.
//

import SwiftUI

struct DetailView: View {
    
    @EnvironmentObject var appState: GlobalState
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @Environment(\.managedObjectContext) var managedObjectContext
    @FetchRequest var tasks: FetchedResults<Task>
    
    /// The assessment must be passed from the parent view
    /// whether its editing or not.
    var assessment: Assessment
    
    /// Task will be nil when not in editing mode. It means the user
    /// has requested to add a new task.
    @State var editingTask: Task? = nil
    @State var showAnimation: Bool = false
    @State var showModal: Bool = false
    @State var showTasksList: Bool = true
    @State var activeModal: DetailViewModal = .editAssessment
    @State var showCompletedTasks: Bool = false
    
    init(ass: Assessment) {
        self._tasks = FetchRequest(
            fetchRequest: Task.getAllTasksWithAssessment(ass)
        )
        self.assessment = ass
    }
    
    var body: some View {
        NavigationView {
            if self.assessment.name == nil {
                Text("Please Choose/Create an Assessment")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .opacity(0.5)
            } else {
                wrapper
                    .frame(minWidth: 300, maxWidth: .infinity)
                    .navigationBarTitle(
                        Text("Tasks of \(assessment.module!.name!) \(assessment.name!)"),
                        displayMode: .inline
                )
            }
        }
        .navigationBarItems(leading: assessmentFullInfoButton,trailing: assessmentEditButton)
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: self.$showModal) {
            if self.activeModal == .editAssessment {
                AssessmentManageView(
                    show: self.$showModal,
                    editing: true,
                    assessment: self.assessment
                )
                    .environment(\.managedObjectContext, self.managedObjectContext)
                    .environmentObject(self.appState)
            } else if self.activeModal == .addTask {
                TaskManageView(
                    assessment: self.assessment,
                    editing: false,
                    task: self.editingTask,
                    show: self.$showModal
                )
                    .environment(\.managedObjectContext, self.managedObjectContext)
                    .environmentObject(self.appState)
            } else if self.activeModal == .editTask {
                TaskManageView(
                    assessment: self.assessment,
                    afterEditing: self.afterEditingATask,
                    editing: true,
                    task: self.editingTask,
                    show: self.$showModal
                )
                    .environment(\.managedObjectContext, self.managedObjectContext)
                    .environmentObject(self.appState)
            } else if self.activeModal == .detailedInfo {
                AssessmentDetails(assessment: self.assessment)
                    .environment(\.managedObjectContext, self.managedObjectContext)
                    .environmentObject(self.appState)
            }
        }
    }
    
    func afterEditingATask(_ task: Task) -> Void {
        self.showTasksList = false
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.05,
            execute: DispatchWorkItem {
                self.showTasksList = true
                self.managedObjectContext.refreshAllObjects()
            }
        )
    }
    
    // MARK: Task list view section
    
    var wrapper: some View {
        VStack {
            self.summary
            Divider()
            self.controlPanelSection
            Divider()
            self.taskList
            Spacer()
        }
    }
    
    var taskList: some View {
        VStack {
            if tasks.count > 0 && self.showTasksList {
                ScrollView {
                    ForEach(tasks/*.filter { showCompletedTasks || $0.progress < 100 }*/, id: \.self) { task in
                        VStack {
                            if (self.showCompletedTasks || task.progress < 100) {
                                TaskListItem(
                                    id: 0,
                                    task: task,
                                    onEditClick: self.onTaskEditButtonClick,
                                    onDeleteClick: self.onTaskDeleteButtonClick,
                                    onCompleteClick: self.onTaskCompletedCheckBoxClick
                                )
                                // Divider()
                            }
                        }
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 15)
                    }
                }
            } else {
                HStack {
                    Text("No Tasks Available")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .opacity(0.5)
                }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            }
        }
    }
    
    var assessmentEditButton: some View {
        Button(action: {
            self.activeModal = .editAssessment
            self.showModal.toggle()
        }) {
            if self.assessment.name == nil {
                EmptyView()
            } else {
                HStack {
                    Text("Edit")
                    Image(systemName: "square.and.pencil")
                }
            }
        }
    }
    
    var assessmentFullInfoButton: some View {
        Button(action: {
            self.activeModal = .detailedInfo
            self.showModal.toggle()
        }) {
            if self.assessment.name == nil {
                EmptyView()
            } else {
                HStack {
                    Text("Detailed Information")
                    Image(systemName: "info.circle")
                        .font(.body)
                        .foregroundColor(Color.blue)
                }
            }
        }
    }
    
    // MARK: Summary Section
    
    var summary: some View {
        HStack {
            completionRate
            HStack {
                Spacer()
                infomation
                Spacer()
            }
            timeLeft
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: 280)
    }
    
    var infomation: some View {
        HStack {
            Spacer()
            VStack {
                Text("\(assessment.name!)")
                    .font(.title)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(minWidth: 0, maxWidth: .infinity)
                HStack {
                    Text("Hand-In Date")
                        .bold()
                        .font(.headline)
                    Text("\(Utils.dateToString(assessment.handIn!))")
                        .font(.subheadline)
                }.padding()
                HStack {
                    Text("\(assessment.priority!) Priority")
                        .font(.caption)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(AssessmentPriority.fromRawValue(
                    str: assessment.priority!
                ).color())
                    .cornerRadius(100)
                Text("\(assessment.notes!)")
                    .lineLimit(4)
                    .multilineTextAlignment(.center)
                    .font(.callout)
                    .padding(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0))
                Text("Achieved Mark: \(Utils.getOverallMark(assessment))%")
                    .font(.callout)
                    .bold()
                    .padding(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0))
            }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            Spacer()
        }
    }
    
    var completionRate: some View {
        let p = Utils.getAssessmentProgressPercentage(tasks.map {$0 as Task})
        return VStack(alignment: .center, spacing: 30.0) {
            HStack {
                Text("Tasks Completion Percentage")
                    .font(.caption)
                    .foregroundColor(.black)
            }
            .padding(10)
            .background(Color.white)
            .opacity(0.85)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 20)
            .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
            ProgressRing(
                color1: #colorLiteral(red: 0.2196078449, green: 0.007843137719, blue: 0.8549019694, alpha: 1),
                color2: #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1),
                width: 120, height: 120,
                percent: CGFloat(p),
                show: $showAnimation
            )
        }.frame(minWidth: 200, maxHeight: .infinity)
    }
    
    var timeLeft: some View {
        let (days, percentage) = Utils.getAssessmentDaysRemainingAndElapsedPercentage(assessment)
        return VStack(spacing: 30.0) {
            HStack {
                Text("Days Left Before Deadline")
                    .font(.caption)
                    .foregroundColor(.black)
            }
            .padding(10)
            .background(Color.white)
            .opacity(0.85)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 20)
            .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
            ProgressRing(
                color1: #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1),
                color2: #colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1),
                width: 120, height: 120,
                percent: percentage,
                customLabel: String(days),
                type: .days,
                show: $showAnimation
            )
        }.frame(minWidth: 200, maxHeight: .infinity)
    }
    
    // MARK: Control Panel Section
    
    var controlPanelSection: some View {
        HStack {
            VStack {
                Text("This assessment's due date is on")
                    .bold()
                    .font(.headline)
                Text("\(Utils.dateToString(assessment.due!))")
                    .font(.subheadline)
            }.padding()
            Spacer()
            Button(action: {
                self.activeModal = .addTask
                self.showModal.toggle()
            }) {
                HStack {
                    Text("Add Task").font(.callout)
                    Image(systemName: "plus")
                }
                .padding(12)
                .background(Color.green)
                .foregroundColor(Color(hex: 0x00251a))
                .cornerRadius(10)
            }
            if tasks.count > 0 {
                Button(action: {
                    DispatchQueue.main.asyncAfter(deadline: .now()) {
                        withAnimation(.default) {
                            self.showCompletedTasks.toggle()
                        }
                    }
                }) {
                    HStack {
                        Text(self.showCompletedTasks ? "Hide Completed Tasks" : "Show Completed Tasks")
                            //.bold()
                            .font(.callout)
                            //.foregroundColor(Color(hex: 0x560027))
                            .id(UUID())
                            .fixedSize()
                        Image(systemName: self.showCompletedTasks ? "eye.slash.fill" : "eye.fill")
                            .font(.callout)
                            //.foregroundColor(Color(hex: 0x560027))
                            .id(UUID())
                            .fixedSize()
                    }
                    .padding(12)
                    .background(self.showCompletedTasks ? Color.red : Color.pink)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
        .padding(.horizontal, 15)
            //.background(Color(hex: 0x232323, alpha: 0.7))
            .frame(maxWidth: .infinity, minHeight: 40)
    }
    
    // MARK: Event Handlers
    
    func onTaskEditButtonClick(_ index: Int, _ task: Task) -> Void {
        self.editingTask = task
        self.activeModal = .editTask
        self.showModal.toggle()
    }
    
    func onTaskDeleteButtonClick(_ index: Int, _ task: Task) -> Void {
        appState.showAlert(conf: AlertConfiguration(
            title: "Delete \(task.name!)?",
            message: "Are you sure you want to delete this task forever? You cannot undo this action.",
            confirmButtonText: "Yes",
            confirmCallback: {
                CalendarManager.shared.deleteCalendarEventAsync(id: String(task.eventIdentifier!))
                self.managedObjectContext.delete(task)
                try? self.managedObjectContext.save()
                self.managedObjectContext.refreshAllObjects()
        }))
    }
    
    func onTaskCompletedCheckBoxClick(_ index: Int, _ task: Task, _ checked: Bool) -> Void {
        if checked {
            task.progress = 100
        } else {
            task.progress = 0
        }
        try? self.managedObjectContext.save()
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.5,
            execute: DispatchWorkItem {
                self.managedObjectContext.refresh(task, mergeChanges: true)
                self.managedObjectContext.refreshAllObjects()
            }
        )
    }
    
}

enum DetailViewModal {
    case editAssessment, editTask, addTask, detailedInfo
}
