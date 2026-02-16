//
//  CharacterLimitModifier.swift
//  MiniMate
//
//  Created by Garrett Butchko on 6/11/25.
//

import SwiftUI

/// A SwiftUI ViewModifier to limit the number of characters in a TextField
struct CharacterLimitModifier: ViewModifier {
    @Binding var text: String
    let maxLength: Int
    
    func body(content: Content) -> some View {
        content
            .onChange(of: text) { oldValue, newValue in
                if newValue.count > maxLength {
                    text = String(newValue.prefix(maxLength))
                }
            }
    }
}

extension View {
    /// Restricts a TextField's text to a maximum character count.
    func characterLimit(_ text: Binding<String>, maxLength: Int) -> some View {
        self.modifier(CharacterLimitModifier(text: text, maxLength: maxLength))
    }
}
