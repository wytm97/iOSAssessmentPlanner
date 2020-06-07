//
//  DetailView.swift
//  Assessment Planner
//
//  Created by Yasin on 6/6/20.
//  Copyright © 2020 Yasin. All rights reserved.
//

import SwiftUI

struct DetailView: View {
    
    @EnvironmentObject var message: AlertManager
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @Environment(\.managedObjectContext) var moc
    @FetchRequest var tasks: FetchedResults<Task>
    
    /// The assessment must be passed from the parent view whether its editing or not.
    var assessment: Assessment
    
    /// Task will be non-nil when in editing mode.
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
                VStack {
                    self.summary
                    Divider()
                    self.controlPanelSection
                    Divider()
                    self.taskList
                    Spacer()
                }
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
            self.presentationSheet
                .environment(\.managedObjectContext, self.moc)
                .environmentObject(self.message)
        }
        
    }
    
    var presentationSheet: some View {
        VStack {
            if self.activeModal == .editAssessment {
                AssessmentManageView(
                    show: self.$showModal,
                    editing: true,
                    assessment: self.assessment
                )
            } else if self.activeModal == .addTask {
                TaskManageView(
                    assessment: self.assessment,
                    editing: false,
                    task: self.editingTask,
                    show: self.$showModal
                )
            } else if self.activeModal == .editTask {
                TaskManageView(
                    assessment: self.assessment,
                    editing: true,
                    task: self.editingTask,
                    show: self.$showModal
                )
            } else if self.activeModal == .detailedInfo {
                AssessmentDetails(
                    show: self.$showModal,
                    assessment: self.assessment
                )
            } else {
                EmptyView()
            }
        }
    }
    
    // MARK: Task list view section
    
    var taskList: some View {
        VStack {
            if tasks.count > 0 && self.showTasksList {
                ScrollView {
                    ForEach(tasks, id: \.self) { task in
                        VStack {
                            if (self.showCompletedTasks || task.progress < 100) {
                                TaskListItem(
                                    id: 0,
                                    task: task,
                                    onEditClick: self.onTaskEditButtonClick,
                                    onDeleteClick: self.onTaskDeleteButtonClick,
                                    onCompleteClick: self.onTaskCompletedCheckBoxClick
                                )
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
                            .font(.callout)
                            .id(UUID())
                            .fixedSize()
                        Image(systemName: self.showCompletedTasks ? "eye.slash.fill" : "eye.fill")
                            .font(.callout)
                            .id(UUID())
                            .fixedSize()
                    }
                    .padding(12)
                    .background(Color.pink)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
        .padding(.horizontal, 15)
        .frame(maxWidth: .infinity, minHeight: 40)
    }
    
    // MARK: Event Handlers
    
    func onTaskEditButtonClick(_ index: Int, _ task: Task) -> Void {
        self.editingTask = task
        self.activeModal = .editTask
        self.showModal.toggle()
    }
    
    func onTaskDeleteButtonClick(_ index: Int, _ task: Task) -> Void {
        
        message.alert(configuration: AlertConfig(
            title: "Delete \(task.name!)?",
            message: "Are you sure you want to delete this task forever? you cannot undo this action.",
            confirmText: "Delete",
            confirmCallback: {
                CalendarManager.shared.deleteCalendarEventAsync(id: String(task.eventIdentifier!))
                self.moc.delete(task)
                try? self.moc.save()
                self.moc.refreshAllObjects()
        },
            confirmIsDestructive: true,
            cancelIsVisible: true,
            cancelText: "Cancel")
        )
        
    }
    
    func onTaskCompletedCheckBoxClick(_ index: Int, _ task: Task, _ checked: Bool) -> Void {
        task.progress = checked ? 100 : 0
        try? self.moc.save()
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.5,
            execute: DispatchWorkItem {
                self.moc.refresh(task, mergeChanges: true)
                self.moc.refreshAllObjects()
            }
        )
    }
    
}

enum DetailViewModal {
    case editAssessment, editTask, addTask, detailedInfo
}
