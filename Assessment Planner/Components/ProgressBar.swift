//
//  ProgressBar.swift
//  Assessment Planner
//
//  Created by Yasin on 6/6/20.
//  Copyright © 2020 Yasin. All rights reserved.
//

import SwiftUI

struct ProgressBar: View {
    
    @Binding var value: Float
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle().frame(width: geometry.size.width , height: geometry.size.height)
                    .opacity(0.3)
                    .foregroundColor(Color.gray)
                Rectangle()
                    .frame(
                        width: min(
                            CGFloat(self.value) * geometry.size.width,
                            geometry.size.width
                        ),
                        height: geometry.size.height
                )
                    .foregroundColor(self.getFgColor(val: self.value))
                    .animation(.linear(duration: 0.3))
            }.cornerRadius(45.0)
        }
    }
    
    func getFgColor(val: Float) -> Color {
        if val >= 0.80 {
            return Color.red
        } else if val >= 0.60 {
            return Color.orange
        } else if val >= 0.30 {
            return Color.yellow
        } else {
            return Color.green
        }
    }
    
}

struct ProgressBarView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressBar(value: .constant(0.1))
            .frame(height: 20)
            .previewLayout(.sizeThatFits)
    }
}
