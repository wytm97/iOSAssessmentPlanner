//
//  GlobalState.swift
//  Assessment Planner
//
//  Created by Yasin on 6/6/20.
//  Copyright © 2020 Yasin. All rights reserved.
//

import Foundation
import Combine
import CoreData
import SwiftUI

public class AlertManager: ObservableObject {
    
    // Initial values are needed to emit the first event
    
    @Published var showToast: Bool = false
    @Published var toastData: ToastData = ToastData(title: "", detail: "", type: .success)
    @Published var showAlert: Bool = false
    @Published var alertConf: AlertConfig = AlertConfig(title: "Sample Title", message: "Some Message")
    
    // MARK: UI Triggers
    
    public func alert(configuration: AlertConfig, after: Double = 0) -> Void {
        DispatchQueue.main.asyncAfter(deadline: .now() + after) {
            self.alertConf = configuration
            self.showAlert = true
        }
    }
    
    public func alert(title: String, message: String, after: Double = 0) -> Void {
        DispatchQueue.main.asyncAfter(deadline: .now() + after) {
            self.alertConf = AlertConfig(title: title, message: message)
            self.showAlert = true
        }
    }
    
    public func toast(title: String, message: String, type: ToastType, after: Double = 1.7) -> Void {
        DispatchQueue.main.asyncAfter(deadline: .now() + after) {
            self.toastData = ToastData(title: title, detail: message, type: type)
            self.showToast = true
        }
    }
    
}

public struct AlertConfig {
    var title: String
    var message: String
    var confirmText: String = "Okay"
    var confirmCallback: (() -> Void) = {}
    var confirmIsDestructive: Bool = false
    var cancelIsVisible: Bool = false
    var cancelText: String = "Cancel"
    var cancelCallback: (() -> Void) = {}
}
