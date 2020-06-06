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

public class GlobalState: ObservableObject {
    
    @Published var showToast: Bool = false
    @Published var showAlert: Bool = false
    
    // Initial values are needed to emit the first event
    
    @Published var toastData: ToastData = ToastData(title: "", detail: "", type: .success)
    @Published var alertData: AlertConfiguration = AlertConfiguration(title: "", message: "")
    
    // MARK: UI Triggers
    
    public func showToast(title: String, detail: String, type: ToastType) -> Void {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
            self.toastData = ToastData(title: title, detail: detail, type: type)
            self.showToast = true
        }
    }
    
    public func showAlert(title: String, message: String) -> Void {
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            self.alertData = AlertConfiguration(title: title, message: message)
            self.showAlert = true
        }
    }
    
    public func showAlert(conf: AlertConfiguration) -> Void {
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            self.alertData = conf
            self.showAlert = true
        }
    }
    
}

public struct AlertConfiguration {
    var title: String
    var message: String
    var confirmButtonText: String?
    var confirmCallback: (() -> Void)?
}

