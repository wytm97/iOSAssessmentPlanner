//
//  ModuleDeleteView.swift
//  Assessment Planner
//
//  Created by Yasin on 6/6/20.
//  Copyright © 2020 Yasin. All rights reserved.
//

import SwiftUI

struct ModuleDeleteView: View {
    
    @EnvironmentObject var message: AlertManager
    @FetchRequest(fetchRequest: Module.getAllModules()) var modules: FetchedResults<Module>
    var didSaveSomething = NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
    
    @Binding var show: Bool
    
    var body: some View {
        FormModalWrapper(
            cancelButtonText: "Close",
            showSubmitButton: false,
            disableSubmit: .constant(true),
            show: $show,
            title: "Available Modules"
        ) {
            if modules.count == 0 {
                noModulesMessage
            } else {
                ForEach(modules, id: \.self) { (module: Module) in
                    ModuleItem(module: module)
                }
            }
        }.onReceive(didSaveSomething) { _ in
            if self.modules.count == 0 {
                self.show = false
            }
        }
    }
    
    var noModulesMessage: some View {
        Text("No modules available for display!")
            .font(.callout)
            .foregroundColor(.gray)
            .opacity(0.5)
    }
    
}

struct ModuleItem: View {
    
    @EnvironmentObject var message: AlertManager
    @Environment(\.managedObjectContext) var moc
    
    var module: Module
    
    var body: some View {
        VStack {
            if module.level != nil && module.name != nil && module.leader != nil && module.assessments != nil {
                HStack(spacing: 15) {
                    VStack(alignment: .center) {
                        Text("\(module.level ?? "")").bold()
                    }
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(module.code ?? "")").font(.caption)
                        Text("\(module.name ?? "")").font(.headline)
                        Text("Module Leader: \(module.leader ?? "")").font(.subheadline)
                        Divider()
                        Text("Created at: \(Utils.dateToString(module.createdAt ?? Date()))").font(.caption).foregroundColor(.gray)
                    }
                    Spacer()
                    VStack {
                        Text("No. of Assessments: \(module.assessments!.count)").font(.caption)
                        Button(action: onRemoveModuleClick) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Remove Module")
                            }.foregroundColor(.red)
                        }
                    }
                }
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(lineWidth: 1)
                        .foregroundColor(Color.gray)
                )
            } else {
                EmptyView()
            }
        }
    }
    
    func onRemoveModuleClick() -> Void {
        
        let msg = "Are you sure you want to delete this module? once you delete you cannot undo " +
        "this action. It will remove all the associated assessments and it's related tasks!"
        
        message.alert(configuration: AlertConfig(
            title: "Delete \(module.name!)",
            message: msg,
            confirmText: "Delete",
            confirmCallback: self.goRemove,
            confirmIsDestructive: true,
            cancelIsVisible: true,
            cancelText: "Cancel"
            )
        )
        
    }
    
    func goRemove() -> Void {
        
        for a in module.assessments! { // Delete each assessment
            for t in a.tasks! { // Delete each task
                CalendarManager.shared.deleteCalendarEventAsync(id: String(t.eventIdentifier!))
                self.moc.delete(t)
                try? self.moc.save()
            }
            CalendarManager.shared.deleteCalendarEventAsync(id: String(a.eventIdentifier!))
            self.moc.delete(a)
            try? self.moc.save()
        }
        
        self.moc.delete(module)
        try? self.moc.save()
        self.moc.refreshAllObjects()
        
    }
    
}
