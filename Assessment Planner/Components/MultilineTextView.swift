//
//  MultilineTextField.swift
//  Assessment Planner
//
//  Created by Yasin on 6/6/20.
//  Copyright © 2020 Yasin. All rights reserved.
//

import SwiftUI
import UIKit
import Combine

struct MultilineTextField: UIViewRepresentable {
    
    @Binding var text: String
    @Binding var height: CGFloat
    
    var onEditingChanged: (() -> Void)? = nil
    
    func makeCoordinator() -> MultilineTextField.Coordinator {
        return MultilineTextField.Coordinator(parent: self)
    }
    
    func makeUIView(context: UIViewRepresentableContext<MultilineTextField>) -> UITextView {
        let textView = UITextView()
        textView.isEditable = true
        textView.isUserInteractionEnabled = true
        textView.isScrollEnabled = true
        textView.text = "Type Some Notes..."
        textView.textColor = .label
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.delegate = context.coordinator
        self.height = textView.contentSize.height
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: UIViewRepresentableContext<MultilineTextField>) {
        uiView.text = text
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        
        let parent: MultilineTextField
        
        init(parent: MultilineTextField) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            self.parent.text = textView.text
                .trimmingCharacters(in: .whitespaces)
                .trimmingCharacters(in: .illegalCharacters)
            self.parent.height = textView.contentSize.height
            if self.parent.onEditingChanged != nil {
                self.parent.onEditingChanged!()
            }
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {

        }
        
    }
    
}