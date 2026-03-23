//
//  CardShadowModifier.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/15/25.
//

import SwiftUI

// MARK: - Card Shadow Modifier

struct CardShadowModifier: ViewModifier {
    var color: Color = Color.black.opacity(0.1)
    var radius: CGFloat = 10
    var x: CGFloat = 0
    var y: CGFloat = 5
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color, radius: radius, x: x, y: y)
    }
}

// MARK: - View Extension

extension View {
    /// Applies the standard card shadow used throughout the app
    /// - Parameters:
    ///   - color: Shadow color (default: black with 0.1 opacity)
    ///   - radius: Shadow radius (default: 10)
    ///   - x: Horizontal offset (default: 0)
    ///   - y: Vertical offset (default: 5)
    func cardShadow(color: Color = Color.black.opacity(0.1), radius: CGFloat = 10, x: CGFloat = 0, y: CGFloat = 5) -> some View {
        modifier(CardShadowModifier(color: color, radius: radius, x: x, y: y))
    }
}
