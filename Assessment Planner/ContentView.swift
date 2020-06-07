//
//  ContentView.swift
//  Assessment Planner
//
//  Created by Yasin on 6/6/20.
//  Copyright © 2020 Yasin. All rights reserved.
//

import SwiftUI
import CoreData

struct ContentView: View {
    
    // MARK: Constants
    
    let FILTER_ALL_TEXT = "ALL"
    
    // MARK: Envrionment Variables
    
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(fetchRequest: Assessment.getAllAssessments()) var assessments: FetchedResults<Assessment>
    @FetchRequest(fetchRequest: Module.getAllModules()) var modules: FetchedResults<Module>
    @EnvironmentObject var message: AlertManager
    
    // MARK: Filters State
    
    var priorities: [String] = AssessmentPriority.values()
    
    @State var selectedPriorityFilter: String = ""
    @State var selectedModuleFilter: String = ""
    @State var filterPriority: String? = nil
    @State var filterModule: Module? = nil
    @State var currentModuleIndex = 0
    @State var currentPriorityIndex = 0
    
    // MARK: Dynamic state properties of this view
    
    @State var showActiveViewSheetModal: Bool = false
    @State var activeSheetModal: ActiveSheetModal = .addModuleView
    
    // MARK: View Declaration
    
    var body: some View {
        NavigationView {
            VStack {
                filters
                FilteredAssessmentList(
                    priorityFilter: self.filterPriority,
                    moduleFilter: self.filterModule
                )
            }
            .navigationBarTitle(Text("Assessments"), displayMode: .large)
            .navigationBarItems(leading: addModuleShortcutButton, trailing: addAssessmentButton)
            .navigationViewStyle(DoubleColumnNavigationViewStyle())
            /// Initial view if none of the list items is selected or is just empty.
            Text("Please Choose/Create an Assessment")
                .font(.headline)
                .foregroundColor(.gray)
                .opacity(0.5)
        }
        .sheet(isPresented: self.$showActiveViewSheetModal) {
            /// This parent view can show upto 3 different view in context.
            /// The parent should also give child sheet access to the environment's variables.
            if self.activeSheetModal == .addModuleView {
                ModuleAddView(show: self.$showActiveViewSheetModal)
                    .environment(\.managedObjectContext, self.moc)
                    .environmentObject(self.message)
            } else if self.activeSheetModal == .addAssessmentView {
                AssessmentManageView(show: self.$showActiveViewSheetModal)
                    .environment(\.managedObjectContext, self.moc)
                    .environmentObject(self.message)
            } else {
                ModuleDeleteView(show: self.$showActiveViewSheetModal)
                    .environment(\.managedObjectContext, self.moc)
                    .environmentObject(self.message)
            }
        }
        .attachAlert(isPresented: $message.showAlert, conf: message.alertConf)
        .attachToaster(data: $message.toastData, show: $message.showToast)
        .onAppear { self.mapFilterToView() }
        
    }
    
    var addModuleShortcutButton: some View {
        HStack(spacing: 10) {
            Button(action: {
                self.activeSheetModal = .addModuleView
                self.showActiveViewSheetModal.toggle()
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title)
                    .foregroundColor(Color.pink)
            }
            Button(action: {
                self.activeSheetModal = .viewModulesView
                self.showActiveViewSheetModal.toggle()
            }) {
                Image(systemName: "text.badge.minus")
                    .font(.title)
                    .foregroundColor(Color.pink)
            }
        }
    }
    
    var addAssessmentButton: some View {
        Button(action: {
            self.activeSheetModal = .addAssessmentView
            self.showActiveViewSheetModal.toggle()
        }) {
            Text("Add")
                .font(.body)
                .foregroundColor(Color.green)
            Image(systemName: "plus.circle")
                .font(.title)
                .foregroundColor(Color.green)
        }
    }
    
    // MARK: Filters View
    
    var filter1: some View {
        Button(action: self.onPriorityFilterTap) {
            VStack(alignment: .center) {
                HStack(alignment: .center) {
                    Text("Target Priority").font(.callout)
                    Image(systemName: "slider.horizontal.3").font(.callout)
                }
                Text(self.selectedPriorityFilter).font(.caption).lineLimit(1)
            }
            .padding(6)
            .frame(minWidth: 0, maxWidth: .infinity)
        }.contextMenu {
            Button(action: {
                self.filterPriority = nil
                self.mapFilterToView()
            }) {
                Text(FILTER_ALL_TEXT).font(.callout).lineLimit(1)
            }
            ForEach(priorities, id: \.self) { value in
                Button(action: {
                    self.filterPriority = value
                    self.mapFilterToView()
                }) {
                    Text(value).font(.callout).lineLimit(1)
                }
            }
        }
    }
    
    var filter2: some View {
        Button(action: self.onModuleFilterTap) {
            VStack(alignment: .center) {
                HStack(alignment: .center) {
                    Text("Target Module").font(.callout)
                    Image(systemName: "slider.horizontal.3").font(.callout)
                }
                Text(self.selectedModuleFilter).font(.caption).lineLimit(1)
            }
            .padding(6)
            .frame(minWidth: 0, maxWidth: .infinity)
        }.contextMenu {
            Button(action: {
                self.filterModule = nil
                self.mapFilterToView()
            }) {
                Text(FILTER_ALL_TEXT).font(.callout).lineLimit(1)
            }
            ForEach(modules, id: \.self) { (module: Module) in
                Button(action: {
                    self.filterModule = module
                    self.mapFilterToView()
                }) {
                    Text(module.name!).font(.callout).lineLimit(1)
                }
            }
        }
    }
    
    var filters: some View {
        VStack {
            Divider()
            HStack(alignment: .center) {
                filter2
                Divider().fixedSize()
                filter1
            }.padding(0/*prevent default*/)
            Divider()
        }
    }
    
    // MARK: Event Handlers
    
    func mapFilterToView() -> Void {
        if self.filterModule == nil {
            self.selectedModuleFilter = FILTER_ALL_TEXT
        } else {
            self.selectedModuleFilter = self.filterModule!.name!
        }
        if self.filterPriority == nil {
            self.selectedPriorityFilter = FILTER_ALL_TEXT
        } else {
            self.selectedPriorityFilter = self.filterPriority!
        }
    }
    
    func onModuleFilterTap() -> Void {
        
        self.currentModuleIndex = self.currentModuleIndex + 1
        
        if currentModuleIndex > 0 { // move into the fetched modules
            if modules.indices.contains(currentModuleIndex - 1) {
                self.filterModule = modules[currentModuleIndex - 1]
            } else {
                self.filterModule = nil
                self.currentModuleIndex = 0
            }
        }
        
        self.mapFilterToView()
        
    }
    
    func onPriorityFilterTap() -> Void {
        
        self.currentPriorityIndex = self.currentPriorityIndex + 1
        
        if currentPriorityIndex > 0 { // move into the fetched modules
            if priorities.indices.contains(currentPriorityIndex - 1) {
                self.filterPriority = priorities[currentPriorityIndex - 1]
            } else {
                self.filterPriority = nil
                self.currentPriorityIndex = 0
            }
        }
        
        self.mapFilterToView()
        
    }
    
}

enum ActiveSheetModal {
    case addModuleView, addAssessmentView, viewModulesView
}
