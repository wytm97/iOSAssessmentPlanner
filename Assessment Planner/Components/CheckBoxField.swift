//
//  CheckBoxField.swift
//  Assessment Planner
//
//  Created by Yasin on 6/6/20.
//  Copyright © 2020 Yasin. All rights reserved.
//

import SwiftUI

struct CheckBoxField: View {
    
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    let label: String
    let size: CGFloat
    let marked: Bool
    let textSize: Int
    let onAction: (Bool) -> Void
    
    init(
        label:String = "",
        size: CGFloat = 10,
        marked: Bool = false,
        textSize: Int = 14,
        onAction: @escaping (_ isOn: Bool) -> Void
    ) {
        self.label = label
        self.size = size
        self.marked = marked
        self.textSize = textSize
        self.onAction = onAction
    }
    
    @State var isMarked:Bool = false
    
    var body: some View {
        Button(action: {
            self.isMarked.toggle()
            self.onAction(self.isMarked)
        }) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: self.isMarked ? "checkmark.square" : "square")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: self.size, height: self.size)
                if self.label != "" {
                    Text(label)
                        .font(Font.system(size: size))
                }
            }.foregroundColor(colorScheme == .dark ? Color.white : Color.black)
        }.foregroundColor(colorScheme == .dark ? Color.white : Color.black)
            .onAppear{
                if self.marked {
                    self.isMarked.toggle()
                    self.onAction(self.isMarked)
                }
        }
    }
    
}

struct CheckBoxFieldView_Previews: PreviewProvider {
    static var previews: some View {
        CheckBoxField(
            label: "Some Label",
            size: 40,
            onAction: { _ in }
        ).previewLayout(.sizeThatFits)
    }
}
