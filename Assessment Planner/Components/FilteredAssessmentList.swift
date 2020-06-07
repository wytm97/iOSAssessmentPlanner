//
//  FilteredAssessmentList.swift
//  Assessment Planner
//
//  Created by Yasin on 6/6/20.
//  Copyright © 2020 Yasin. All rights reserved.
//

import SwiftUI

struct FilteredAssessmentList: View {
    
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var message: AlertManager
    @FetchRequest var assessments: FetchedResults<Assessment>
    
    init(priorityFilter: String?, moduleFilter: Module?) {
        self._assessments = FetchRequest(
            fetchRequest: Assessment.getAllAssessmentsMatching(
                priority: priorityFilter, module: moduleFilter
            )
        )
    }
    
    var body: some View {
        VStack {
            if self.assessments.count > 0 {
                List {
                    ForEach(self.assessments, id: \.self) { (assessment: Assessment) in
                        NavigationLink(destination: VStack {
                            DetailView(ass: assessment) /// Detail view
                        }) {
                            AssessmentListItem( /// List item card
                                priority: assessment.priority!,
                                name: assessment.name!,
                                moduleName: assessment.module!.name!,
                                subtaskCount: assessment.tasks!.count
                            )
                        }
                    }.onDelete(perform: self.onDeleteClicked)
                }
            } else {
                Text("No Assessments Found")
                    .font(.callout)
                    .foregroundColor(.gray)
                    .opacity(0.5)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            }
        }
    }
    
    func onDeleteClicked(at offsets: IndexSet) -> Void {
        
        // Convert the indexset into an array to quick access
        let indexes = Array(offsets)
        
        // invariant: we expect the offsets length to be 1 all the
        // time so we can avoid a loop.
        assert(indexes.count == 1, "indexes length was not 1")
        
        // Determine the selected assessment instance.
        let ass: Assessment = assessments[indexes[0]]
        
        message.alert(configuration: AlertConfig(
            title: "Delete \(ass.name!)?",
            message: "Are you sure you want to delete this assessment? you cannot undo this action.",
            confirmText: "Delete",
            confirmCallback: { self.goDelete(ass) },
            confirmIsDestructive: true,
            cancelIsVisible: true,
            cancelText: "Cancel")
        )
        
    }
    
    func goDelete(_ ass: Assessment) -> Void {
        CalendarManager.shared.deleteCalendarEventAsync(id: String(ass.eventIdentifier!))
        self.moc.delete(ass)
        try? self.moc.save()
        self.moc.refreshAllObjects()
    }
    
}
