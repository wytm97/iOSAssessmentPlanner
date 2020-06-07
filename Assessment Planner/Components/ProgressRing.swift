//
//  ProgressRing.swift
//  Assessment Planner
//
//  Created by Yasin on 6/6/20.
//  Copyright © 2020 Yasin. All rights reserved.
//

import SwiftUI

struct ProgressRing: View {
    
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    var color1 = #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1)
    var color2 = #colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1)
    var width: CGFloat = 300
    var height: CGFloat = 300
    var percent: CGFloat = 88
    var customLabel: String = "88"
    var type: RingValueType = .percentage
    
    let labelDownScale: CGFloat = 0.7
    let captionDownScale: CGFloat = 0.3
    
    @Binding var show: Bool
    
    var body: some View {
        
        /// Dynamic scaling properties
        let multiplier = width / 44
        let progress = 1 - (percent / 100)
        self.animateImmediately()
        
        return ZStack {
            /// Background circle
            Circle()
                .stroke(
                    colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1),
                    style: StrokeStyle(lineWidth: 5 * multiplier)
            ).frame(width: width, height: height)
            /// Progress circle
            Circle()
                .trim(from: show ? progress : 1, to: 1)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(color1), Color(color2)]),
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    ),
                    style: StrokeStyle(
                        lineWidth: 5 * multiplier,
                        lineCap: .round,
                        lineJoin: .round,
                        miterLimit: .infinity,
                        dash: [20, 0],
                        dashPhase: 0
                    )
            )
                .rotationEffect(Angle(degrees: 90))
                .rotation3DEffect(Angle(degrees: 180), axis: (x: 1, y: 0, z: 0))
                .frame(width: width, height: height)
                .animation(Animation.easeInOut.delay(0.3))
                .shadow(
                    color: Color(color2).opacity(0.1),
                    radius: 3 * multiplier,
                    x: 0,
                    y: 3 * multiplier
            )
            if type == .percentage {
                VStack(alignment: .center) {
                    if percent == 100 {
                        Image(systemName: "checkmark")
                            .foregroundColor(Color.green)
                            .font(.system(size: (14 * multiplier) * labelDownScale))
                    } else {
                        Text("\(Int(percent))%")
                            .font(.system(size: (14 * multiplier) * labelDownScale))
                            .fontWeight(.bold)
                            .id(UUID())
                            .onTapGesture {
                                self.show = false
                        }
                    }
                    Text("Completed").font(.system(size: (14 * multiplier) * captionDownScale))
                }
            } else {
                VStack(alignment: .center) {
                    Text(self.customLabel)
                        .font(.system(size: (14 * multiplier) * labelDownScale))
                        .fontWeight(.bold)
                        .id(UUID())
                        .onTapGesture {
                            self.show = false
                    }
                    Text(Int(self.customLabel) == 1 ? "Day" : "Days")
                        .font(.system(size: (14 * multiplier) * captionDownScale))
                }
            }
        }
        
    }
    
    func animateImmediately() -> Void {
        DispatchQueue.main.asyncAfter(
            deadline: .now(),
            execute: DispatchWorkItem { self.show = true }
        )
    }
    
}

enum RingValueType {
    case percentage, days
}

struct ProgressRingView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressRing(show: .constant(true))
    }
}
