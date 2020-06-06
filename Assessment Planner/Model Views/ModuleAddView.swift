//
//  ModuleAddView.swift
//  Assessment Planner
//
//  Created by Yasin on 6/6/20.
//  Copyright © 2020 Yasin. All rights reserved.
//

import SwiftUI

struct ModuleAddView: View {
    
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var appState: GlobalState
    @Binding var show: Bool
    
    // MARK: Form state variables
    
    @State var moduleName = ""
    @State var moduleCode = ""
    @State var moduleLeader = ""
    @State var selectedLevel: Int = 0
    @State var shouldDisableSubmit: Bool = true
    
    var moduleLevels: [String] = ModuleLevel.values()
    
    // MARK: View Declaractions
    
    var body: some View {
        FormModalWrapper(
            onSubmit: self.onAddButtonClick,
            disableSubmit: $shouldDisableSubmit,
            show: $show,
            title: "Create New Module") {
                nameField
                codeField
                levelField
                leaderField
        }.onAppear {
            DispatchQueue.main.asyncAfter(
                deadline: .now(),
                execute: DispatchWorkItem {
                    self.checkFormValidity()
            })
        }
    }
    
    var nameField: some View {
        FormElementWrapper {
            Text("Module Name")
                .font(.headline)
            TextField(
                "Mobile Native Programming",
                text: $moduleName,
                onEditingChanged: { _ in self.checkFormValidity() }
            ).font(.body)
        }
    }
    
    var codeField: some View {
        FormElementWrapper {
            Text("Module Code").font(.headline)
            TextField(
                "6COSC004W",
                text: $moduleCode,
                onEditingChanged: { _ in self.checkFormValidity() }
            )
        }
    }
    
    var levelField: some View {
        FormElementWrapper {
            Text("Module Level")
                .font(.headline)
            Picker(selection: $selectedLevel, label: Text("Module Level")) {
                ForEach(0..<self.moduleLevels.count) { i in
                    Text(self.moduleLevels[i]).tag(i)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .labelsHidden()
        }
    }
    
    var leaderField: some View {
        FormElementWrapper {
            Text("Module Leader")
                .font(.headline)
            TextField(
                "Guhanathan Poravi",
                text: $moduleLeader,
                onEditingChanged: { _ in self.checkFormValidity() }
            )
        }
    }
    
    // MARK: Event Handlers
    
    func onAddButtonClick() -> Void {
        
        /// Mapping the state to the model. Note that we dont assign `id` and `createdAt`
        /// properties here. This is because we assign them automatically when creating a new
        /// `Module` instance.
        
        let module = Module(context: self.managedObjectContext)
        module.code = moduleCode.trimmingCharacters(in: .whitespacesAndNewlines)
        module.name = moduleName.trimmingCharacters(in: .whitespacesAndNewlines)
        module.level = moduleLevels[selectedLevel]
        module.leader = moduleLeader.trimmingCharacters(in: .whitespacesAndNewlines)
        module.assessments = []
        
        do {
            try self.managedObjectContext.save()
            self.show = false
            self.appState.showToast(
                title: "Module Created",
                detail: "You have successfully created \(module.code!)-\(module.name!) module",
                type: .success
            )
        } catch let error {
            print(error)
            self.appState.showAlert(title: "Error", message: error.localizedDescription)
        }
        
    }
    
    func checkFormValidity() -> Void {
        let isNameValid = moduleName.matchesExact("^[ a-zA-Z\\d_.\\-]{3,40}$") // 3..40 mix char ascii
        let isCodeValid = moduleCode.matchesExact("^[ a-zA-Z\\d_.\\-]{3,15}$") // 3..15 mix char ascii
        let isLeaderNameValid = moduleLeader.matchesExact("^[ a-zA-Z_.]{3,40}$") // name should only have alphabetic
        let isLevelValid = selectedLevel >= 0 && selectedLevel <= 5 // 0..5
        self.shouldDisableSubmit = (
            !isNameValid ||
                !isCodeValid ||
                !isLeaderNameValid ||
                !isLevelValid
        )
    }
    
}

struct ModuleManageView_Previews: PreviewProvider {
    static var previews: some View {
        ModuleAddView(
            show: .constant(true)
        )
    }
}
