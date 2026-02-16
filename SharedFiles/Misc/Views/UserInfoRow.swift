//
//  UserInfoRow.swift
//  MiniMate
//
//  Created by Garrett Butchko on 6/4/25.
//

import SwiftUI

// Reusable row for displaying static user info
struct UserInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text("\(label):")
            Text(value)
        }
    }
}
