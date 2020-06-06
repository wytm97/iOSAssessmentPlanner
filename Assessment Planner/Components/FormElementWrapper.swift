//
//  FormElementWrapper.swift
//  Assessment Planner
//
//  Created by Yasin on 6/6/20.
//  Copyright © 2020 Yasin. All rights reserved.
//

import SwiftUI

struct FormElementWrapper<Content:View>: View {
    
    private(set) var content: Content
    
    public init(@ViewBuilder _ content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading) { content }
            .padding(10)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(lineWidth: 1)
                    .foregroundColor(Color.gray)
        )
    }
    
}
