//
//  AssessmentListItem.swift
//  Assessment Planner
//
//  Created by Yasin on 6/6/20.
//  Copyright © 2020 Yasin. All rights reserved.
//

import SwiftUI

struct AssessmentListItem: View {
    
    var priority: String
    var name: String
    var moduleName: String
    var subtaskCount: Int
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "flag")
                .foregroundColor(AssessmentPriority.fromRawValue(str: priority).color())
                .font(.title)
                .padding()
                .fixedSize()
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.body)
                    .bold()
                Text(moduleName)
                    .font(.callout)
                Text(String(subtaskCount) + " subtasks")
                    .font(.caption)
                    .italic()
            }
            .padding(5)
        }
        .padding(.horizontal, 3)
        .padding(.vertical, 2)
    }
    
}

struct AssessmentListItem_Previews: PreviewProvider {
    static var previews: some View {
        AssessmentListItem(
            priority: "Low",
            name: "Assessment Name",
            moduleName: "Module Name",
            subtaskCount: 16
        ).previewLayout(.sizeThatFits)
    }
}
