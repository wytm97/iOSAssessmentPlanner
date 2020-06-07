//
//  ModuleAddView.swift
//  Assessment Planner
//
//  Created by Yasin on 6/6/20.
//  Copyright © 2020 Yasin. All rights reserved.
//

import SwiftUI

struct ModuleAddView: View {
    
    private let MODULE_NAME_REGEX = try? NSRegularExpression(pattern: "^[ a-zA-Z.\\d\\-_]{3,50}$")
    private let PERSON_NAME_REGEX = try? NSRegularExpression(pattern: "^[ a-zA-Z.]{3,40}$")
    private let MODULE_CODE_REGEX = try? NSRegularExpression(pattern: "^[ a-zA-Z\\d_.\\-]{3,15}$")
    
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var message: AlertManager
    var moduleLevels: [String] = ModuleLevel.values()
    
    @Binding var show: Bool
    @State var moduleName = ""
    @State var moduleCode = ""
    @State var moduleLeader = ""
    @State var selectedLevel: Int = 0
    
    // MARK: View Declaractions
    
    var body: some View {
        FormModalWrapper(
            onSubmit: self.onAddButtonClick,
            disableSubmit: .constant(false),
            show: $show,
            title: "Create New Module") {
                nameField
                codeField
                levelField
                leaderField
        }
    }
    
    var nameField: some View {
        FormElementWrapper {
            Text("Module Name").font(.headline)
            TextField("Mobile Native Programming", text: $moduleName).font(.body)
        }
    }
    
    var codeField: some View {
        FormElementWrapper {
            Text("Module Code").font(.headline)
            TextField("6COSC004W", text: $moduleCode)
        }
    }
    
    var levelField: some View {
        FormElementWrapper {
            Text("Module Level").font(.headline)
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
            Text("Module Leader").font(.headline)
            TextField("Guhanathan Poravi", text: $moduleLeader)
        }
    }
    
    // MARK: Event Handlers
    
    func onAddButtonClick() -> Void {
        
        if !isFormValid() {
            return
        }
        
        /// Mapping the state to the model. Note that we dont assign `id` and `createdAt`
        /// properties here. This is because we assign them automatically when creating a new
        /// `Module` instance.
        
        let module = Module(context: self.moc)
        
        module.code = moduleCode
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .controlCharacters)
            .trimmingCharacters(in: .illegalCharacters)
        module.name = moduleName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .controlCharacters)
            .trimmingCharacters(in: .illegalCharacters)
        module.level = moduleLevels[selectedLevel]
        module.leader = moduleLeader
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .controlCharacters)
            .trimmingCharacters(in: .illegalCharacters)
        module.assessments = []
        
        do {
            try self.moc.save()
            self.show = false
            self.message.toast(
                title: "Module Created",
                message: "You have successfully created \(module.code!)-\(module.name!) module",
                type: .success
            )
        } catch let error {
            print(error)
            self.message.alert(title: "Error", message: error.localizedDescription)
        }
        
    }
    
    // MARK: Validators
    
    func isFormValid() -> Bool {
        
        if !moduleName.matches(regex: MODULE_NAME_REGEX!) {
            message.alert(
                title: "Invalid Module Name",
                message: "Module name should be atleast 3 characters and must not" +
                " exceed 50 characters and should not contain special characters."
            )
            return false
        }
        
        if !moduleCode.matches(regex: MODULE_CODE_REGEX!) {
            message.alert(
                title: "Invalid Module Code",
                message: "Module code should be atleast 3 characters and must not" +
                " exceed 15 characters."
            )
            return false
        }
        
        if !moduleLeader.matches(regex: PERSON_NAME_REGEX!) {
            message.alert(
                title: "Invalid Leader Name",
                message: "Module leader name should be atleast 3 characters and must not" +
                " exceed 40 characters. Special characters are not allowed."
            )
            return false
        }
        
        return true
        
    }
    
}
