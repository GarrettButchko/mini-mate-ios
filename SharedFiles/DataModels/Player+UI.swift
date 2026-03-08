//
//  Player+UI.swift
//  MiniMate
//
//  Created by Garrett Butchko on 3/8/26.
//
import SwiftUI

extension Player {
    
    var ballColor: Color {
        stringToColor(ballColorDT) ?? .mainOpp
    }
    
    private func stringToColor(_ string: String?) -> Color? {
        if let string = string {
            let lowercased = string.lowercased()
            // Named color map
            let map: [String: Color] = [
                "red": .red,
                "orange": .orange,
                "yellow": .yellow,
                "green": .green,
                "blue": .blue,
                "indigo": .indigo,
                "purple": .purple,
                "pink": .pink,
                "cyan": .cyan,
                "brown": .brown
            ]
            
            return map[lowercased]
        } else {
            return .mainOpp
        }
    }
    
}
