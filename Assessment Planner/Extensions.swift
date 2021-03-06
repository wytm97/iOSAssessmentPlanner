//
//  Extensions.swift
//  Assessment Planner
//
//  Created by Yasin on 6/6/20.
//  Copyright © 2020 Yasin. All rights reserved.
//

import Foundation
import SwiftUI

extension Set {
    func elementAtIndex<T>(at: Int) -> T {
        return self[self.index(self.startIndex, offsetBy: at)] as! T
    }
}

extension View {
    func attachToaster(data: Binding<ToastData>, show: Binding<Bool>) -> some View {
        self.modifier(SweetToastModifier(data: data, show: show))
    }
}

extension View {
    func attachAlert(isPresented: Binding<Bool>, conf: AlertConfig) -> some View {
        self.alert(isPresented: isPresented) {
            if !conf.cancelIsVisible {
                return Alert(
                    title: Text(conf.title),
                    message: Text(conf.message),
                    dismissButton:
                    conf.confirmIsDestructive ?
                        .destructive(Text(conf.confirmText), action: conf.confirmCallback) :
                        .default(Text(conf.confirmText), action: conf.confirmCallback)
                )
            } else {
                return Alert(
                    title: Text(conf.title),
                    message: Text(conf.message),
                    primaryButton:
                    conf.confirmIsDestructive ?
                        .destructive(Text(conf.confirmText), action: conf.confirmCallback) :
                        .default(Text(conf.confirmText), action: conf.confirmCallback),
                    secondaryButton: .cancel(Text(conf.cancelText), action: conf.cancelCallback)
                )
            }
        }
    }
}

extension String {
    func matches(regex: NSRegularExpression) -> Bool {
        let range = NSRange(location: 0, length: self.utf16.count)
        return regex.firstMatch(in: self, options: [], range: range) != nil
    }
}

extension Color {
    init(hex: Int, alpha: Double = 1) {
        let components = (
            R: Double((hex >> 16) & 0xff) / 255,
            G: Double((hex >> 08) & 0xff) / 255,
            B: Double((hex >> 00) & 0xff) / 255
        )
        self.init(
            .sRGB,
            red: components.R,
            green: components.G,
            blue: components.B,
            opacity: alpha
        )
    }
}

extension View {
    func alignTextLeft() -> some View {
        self.modifier(TextLeftAlignModifier())
    }
}

extension Date {
    func resetSeconds() -> Date? {
        let calendar = Calendar.current
        var components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second, .nanosecond],
            from: self
        )
        components.second = 0
        components.nanosecond = 0
        return calendar.date(from: components)
    }
}
