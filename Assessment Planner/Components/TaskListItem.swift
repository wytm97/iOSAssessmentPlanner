//
//  TaskListItem.swift
//  Assessment Planner
//
//  Created by Yasin on 6/6/20.
//  Copyright © 2020 Yasin. All rights reserved.
//

import SwiftUI

struct TaskListItem: View {
    
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    var didSaveSomething = NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
    
    // MARK: Struct params
    
    var id: Int
    var task: Task
    var onEditClick: (_ id: Int, _ task: Task) -> Void
    var onDeleteClick: (_ id: Int, _ task: Task) -> Void
    var onCompleteClick: (_ id: Int, _ task: Task, _ isOn: Bool) -> Void
    
    @State var progress: Float = 0.0
    
    @State var days: Int = 0
    @State var hours: Int = 0
    @State var minutes: Int = 0
    @State var seconds: Int = 0
    @State var trigger: Bool = true
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // MARK: View components
    
    var body: some View {
        HStack(spacing: 25) {
            taskQuickOptions
            Divider()
            taskDetails
            taskSummary
            Divider()
            taskControls
        }
        .opacity(task.progress == 100 ? 0.5 : 1)
        .frame(maxHeight: 100)
        .padding(15)
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(style: StrokeStyle(
                    lineWidth: 2,
                    lineCap: .round,
                    lineJoin: .round,
                    miterLimit: .infinity,
                    dash: [20, task.progress == 100 ? 5 : 0],
                    dashPhase: 0)
            ).foregroundColor(Color.gray)
        ).onReceive(didSaveSomething, perform: { _ in
            self.checkAndStartTimer()
            if self.task.due != nil && self.task.handIn != nil {
                self.updateProgress()
            }
        }).onAppear {
            self.updateProgress()
            DispatchQueue.main.asyncAfter(
                deadline: .now(),
                execute: DispatchWorkItem { self.checkAndStartTimer() }
            )
        }.onDisappear {
            self.trigger = false
            self.timer.upstream.connect().cancel()
        }
        
    }
    
    var taskQuickOptions: some View {
        VStack {
            CheckBoxField(
                size: 30,
                marked: self.task.progress == 100,
                onAction: { (isOn) in withAnimation(.default) { self.onCompleteClick(self.id, self.task, isOn)  } }
            )
        }
    }
    
    var taskDetails: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                Text("\(days) Days, \(hours) Hours, \(minutes) Minutes, \(seconds) Seconds Remaining")
                    .font(.callout).fontWeight(.light)
                    .onReceive(timer) { (input) in
                        if self.trigger {
                            self.updateCountDown()
                        }
                }.multilineTextAlignment(.center)
            }.frame(minWidth: 0, maxWidth: .infinity)
            ProgressBar(value: self.$progress)
                .frame(height: 15)
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 0))
            HStack(alignment: .center, spacing: 15) {
                Text(self.task.name ?? "")
                    .font(.body)
                    .bold()
                    .strikethrough(self.task.progress == 100)
                Divider()
                Text("Due on \(Utils.dateToString(task.due!))")
                    .font(.callout)
                    .italic()
            }
            .frame(minWidth: 0, maxWidth: .infinity, maxHeight: 20)
            HStack(alignment: .center, spacing: 15) {
                Text(task.notes!)
                    .strikethrough(self.task.progress == 100)
                    .multilineTextAlignment(.leading)
                    .lineLimit(8)
                    .font(.callout)
            }.frame(minWidth: 0, maxWidth: .infinity, maxHeight: 50)
        }
    }
    
    var taskSummary: some View {
        VStack {
            ProgressRing(
                color1: #colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1),
                color2: #colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1),
                width: 80, height: 80,
                percent: CGFloat(self.task.progress),
                show: .constant(true)
            )
        }
    }
    
    var taskControls: some View {
        VStack(spacing: 20) {
            Button(action: { self.onEditClick(self.id, self.task) }) {
                VStack(alignment: .center, spacing: 5) {
                    Image(systemName: "square.and.pencil")
                }.font(.body)
            }
            .foregroundColor(.accentColor)
            Divider()
            Button(action: {
                withAnimation {
                    self.onDeleteClick(self.id, self.task)
                }
            }) {
                VStack(alignment: .center, spacing: 5) {
                    Image(systemName: "trash")
                }.font(.body)
            }
            .foregroundColor(.red)
        }.fixedSize()
    }
    
    // MARK: Event Handlers
    
    func checkAndStartTimer() -> Void {
        // if the current time is larger than the task's due time then its no
        // point of showing a countdown.
        if self.task.due != nil && self.task.due! < Date() || self.task.progress == 100 {
            self.trigger = false
        } else {
            self.trigger = true
        }
    }
    
    func updateCountDown() -> Void {
        if let d = task.due {
            let (daysLeft, hoursLeft, minutesLeft, secondsLeft) = Utils.getTimeLeftSimplified(d, Date())
            self.days = daysLeft
            self.hours = hoursLeft
            self.minutes = minutesLeft
            self.seconds = secondsLeft
        }
        if days+hours+minutes+seconds == 0 {
            trigger = false
        }
    }
    
    // MARK: Progress Updators
    
    func updateProgress() -> Void {
        let (_, percentage) = Utils.getTaskDaysRemainingAndElapedPercentage(self.task)
        self.progress = Float(percentage) / 100
    }
    
}
