//
//  Extensions.swift
//  Assessment Planner
//
//  Created by Yasin on 6/6/20.
//  Copyright © 2020 Yasin. All rights reserved.
//

import Foundation
import SwiftUI

extension NSRegularExpression {
    convenience init(_ pattern: String) {
        do {
            try self.init(pattern: pattern)
        } catch {
            preconditionFailure("Illegal regular expression: \(pattern).")
        }
    }
}

extension NSRegularExpression {
    func matches(_ string: String) -> Bool {
        let range = NSRange(location: 0, length: string.utf16.count)
        return firstMatch(in: string, options: [], range: range) != nil
    }
}

extension String {
    static func ~= (lhs: String, rhs: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: rhs) else { return false }
        let range = NSRange(location: 0, length: lhs.utf16.count)
        return regex.firstMatch(in: lhs, options: [], range: range) != nil
    }
}

extension String {
    func matchesExact(_ regex: String) -> Bool {
        return self.range(
            of: regex,
            options: .regularExpression
            ) != nil
    }
}

extension Set {
    func elementAtIndex<T>(at: Int) -> T {
        return self[self.index(self.startIndex, offsetBy: at)] as! T
    }
}

extension View {
    func toast(data: Binding<ToastData>, show: Binding<Bool>) -> some View {
        self.modifier(SweetToastModifier(data: data, show: show))
    }
}

extension Binding {
    func didSet(execute: @escaping (Value) -> Void) -> Binding {
        return Binding(
            get: {
                return self.wrappedValue
        },
            set: {
                execute($0)
                self.wrappedValue = $0
        }
        )
    }
}

extension View {
    func attachAlert(isPresented: Binding<Bool>, data: AlertConfiguration) -> some View {
        self.alert(isPresented: isPresented) {
            Alert(
                title: Text(data.title),
                message: Text(data.message),
                primaryButton: .default(Text(data.confirmButtonText ?? "Okay"), action: data.confirmCallback ?? {}),
                secondaryButton: .cancel()
            )
        }
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
