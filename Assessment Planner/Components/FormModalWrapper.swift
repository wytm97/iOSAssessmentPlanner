//
//  FormModalWrapper.swift
//  Assessment Planner
//
//  Created by Yasin on 6/6/20.
//  Copyright © 2020 Yasin. All rights reserved.
//

import SwiftUI

struct FormModalWrapper<Content:View>: View {
    
    @EnvironmentObject var appState: GlobalState
    @Binding var show: Bool
    @Binding var disableSubmit: Bool
    
    var showSubmitButton: Bool
    var submitButtonText: String
    var onSubmit: () -> Void
    var title: String
    var content: Content
    
    init(
        showSubmitButton: Bool = true,
        submitButtonText: String = "Add",
        onSubmit: @escaping (() -> Void),
        disableSubmit: Binding<Bool>,
        show: Binding<Bool>,
        title: String,
        @ViewBuilder content:() -> Content
    ) {
        self.showSubmitButton = showSubmitButton
        self.submitButtonText = submitButtonText
        self.onSubmit = onSubmit
        self._disableSubmit = disableSubmit
        self._show = show
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .center, spacing: 10) {
                    self.content
                }.padding(40)
            }
            .navigationBarItems(leading: cancelButtonField, trailing: submitButtonField)
            .navigationBarTitle(Text(self.title), displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .attachAlert(isPresented: $appState.showAlert, data: appState.alertData)
    }
    
    var submitButtonField: some View {
        Button(action: self.onSubmit) {
            if self.showSubmitButton {
                HStack {
                    Text(submitButtonText)
                    Image(systemName: "plus.circle.fill")
                }
            }
        }.disabled(disableSubmit)
    }
    
    var cancelButtonField: some View {
        Button(action: { self.show = false }){
            HStack {
                Text("Cancel")
                    .foregroundColor(.red)
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
        }
    }
    
}
