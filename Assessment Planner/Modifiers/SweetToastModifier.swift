//
//  SweetToastModifier.swift
//  Assessment Planner
//
//  Created by Yasin on 6/6/20.
//  Copyright © 2020 Yasin. All rights reserved.
//

import SwiftUI

struct SweetToastModifier: ViewModifier {
    
    @Binding var data: ToastData
    @Binding var show: Bool
    @State var task: DispatchWorkItem?
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            ZStack {
                content.blur(radius: self.show ? 0.3 : 0)
                if self.show {
                    VStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 2) {
                            if self.data.title != "" {
                                Text(self.data.title)
                                    .bold()
                            }
                            Text(self.data.detail).font(
                                Font.system(
                                    size: 15,
                                    weight: Font.Weight.light,
                                    design: Font.Design.default
                                )
                            ).multilineTextAlignment(.leading).lineLimit(2)
                        }
                        .frame(width: geometry.size.width * 0.3)
                        .foregroundColor(Color.black)
                        .padding(10)
                        .background(self.data.type.tintColor)
                        .cornerRadius(8)
                        .shadow(radius: 20)
                    }
                    .padding()
                    .animation(Animation.spring())
                    .transition(AnyTransition.move(edge: .bottom).combined(with: .opacity))
                    .onTapGesture { withAnimation { self.show = false } }
                    .onAppear {
                        self.task = DispatchWorkItem {
                            withAnimation { self.show = false }
                        }
                        // Auto dismiss after 2.5 seconds, and cancel the task if view
                        // disappear before the auto dismiss.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: self.task!)
                    }
                    .onDisappear { self.task?.cancel() }
                }
            }
        }
    }
    
}

public struct ToastData {
    var title: String
    var detail: String
    var type: ToastType
}

public enum ToastType {
    case info
    case warning
    case success
    case error
    var tintColor: Color {
        switch self {
        case .info:     return Color(red: 67/255, green: 154/255, blue: 215/255)
        case .success:  return Color.green
        case .warning:  return Color.yellow
        case .error:    return Color.red
        }
    }
}
