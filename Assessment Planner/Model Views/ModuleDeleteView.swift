//
//  ModuleDeleteView.swift
//  Assessment Planner
//
//  Created by Yasin on 6/6/20.
//  Copyright © 2020 Yasin. All rights reserved.
//

import SwiftUI

struct ModuleDeleteView: View {
    
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var appState: GlobalState
    @FetchRequest(fetchRequest: Module.getAllModules()) var modules: FetchedResults<Module>
    
    @Binding var show: Bool
    
    var body: some View {
        FormModalWrapper(
            showSubmitButton: false,
            onSubmit: {},
            disableSubmit: .constant(true),
            show: $show,
            title: "Available Modules"
        ) {
            if modules.count == 0 {
                Text("No modules available for display!")
                    .font(.callout)
                    .foregroundColor(.gray)
                    .opacity(0.5)
            } else {
                ForEach(modules, id: \.self) { (module: Module) in
                    VStack {
                        HStack(spacing: 15) {
                            VStack(alignment: .center) {
                                Text("\(module.level!)")
                                    .bold()
                            }
                            Divider()
                            VStack(alignment: .leading, spacing: 8) {
                                Text("\(module.code!)").font(.caption)
                                Text("\(module.name!)")
                                    .font(.headline)
                                Text("Module Leader: \(module.leader!)")
                                    .font(.subheadline)
                                Divider()
                                Text("Created at: \(Utils.dateToString(module.createdAt!))")
                                    .font(.caption).foregroundColor(.gray)
                            }
                            Spacer()
                            VStack {
                                Text("Assessment Count \(module.assessments!.count)").font(.caption)
                                Button(action: {
                                    self.appState.showAlert(conf: AlertConfiguration(
                                        title: "Delete this module?",
                                        message: "Are you sure you want to delete this module forever? Once you delete you cannot undo this action. It will remove all the associated assessments and it's related tasks from your account!",
                                        confirmButtonText: "Yes",
                                        confirmCallback: {
                                            let name = String(module.name!)
                                            for a in module.assessments! {
                                                for t in a.tasks! {
                                                    CalendarManager.shared.deleteCalendarEventAsync(id: String(t.eventIdentifier!))
                                                    self.managedObjectContext.delete(t)
                                                    try? self.managedObjectContext.save()
                                                }
                                                CalendarManager.shared.deleteCalendarEventAsync(id: String(a.eventIdentifier!))
                                                self.managedObjectContext.delete(a)
                                                try? self.managedObjectContext.save()
                                            }
                                            self.managedObjectContext.delete(module)
                                            try? self.managedObjectContext.save()
                                            self.managedObjectContext.refreshAllObjects()
                                            self.show = false
                                            self.appState.showToast(
                                                title: "Deleted Module",
                                                detail: "You have delete \(name) module and all it's associated assessments.",
                                                type: .info
                                            )
                                    }))
                                }) {
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
                    }
                }
            }
        }
    }
    
}

struct ViewModules_Previews: PreviewProvider {
    static var previews: some View {
        ModuleDeleteView(show: .constant(true))
            .previewLayout(.sizeThatFits)
    }
}
