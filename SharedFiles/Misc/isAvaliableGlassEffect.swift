//
//
//  isAvaliableGlassEffect.swift
//  MiniMate
//
//  Created by Garrett Butchko on 12/19/25.
//
import SwiftUI

extension Shape {
    @ViewBuilder
    func ifAvailableGlassEffect(strokeWidth: CGFloat = 1, opacity: CGFloat = 0.30, makeColor: Color? = nil) -> some View {
        let fillColor = (makeColor ?? Color.sub).opacity(opacity)
        let strokeColor = (makeColor ?? Color.subTwo)

        if #available(iOS 26.0, *) {
            self
                .fill(fillColor)
                .glassEffect(in: self)
                .clipShape(self) // clip BEFORE adding border
                .overlay(self.stroke(strokeColor, lineWidth: strokeWidth)) // ← correct border
        } else {
            self
                .fill(.ultraThinMaterial)
                .overlay(self.fill(fillColor))
                .clipShape(self)
                .overlay(self.stroke(strokeColor, lineWidth: strokeWidth))
        }
    }
}

extension Shape {
    @ViewBuilder
    func ifAGENoDefaultColor() -> some View {
        if #available(iOS 26.0, *) {
            self
                .fill(.regularMaterial)
                .glassEffect(.clear, in: self)
        } else {
            self
                .fill(.ultraThinMaterial)
                .clipShape(self)
        }
    }
}


extension View {
    @ViewBuilder
    func ultraThinMaterialVsColor(makeColor: Color?) -> some View {
        if let makeColor {
            self
                .background(makeColor.opacity(0.50))
        } else {
            self
                .background(.ultraThinMaterial)
        }
    }
}

extension Color {
    func subVsColor(makeColor: Color?) -> Color {
        if let makeColor {
            return makeColor.opacity(0.50)
        } else {
            return .sub
        }
    }
}

extension Color {
    /// Returns a 50% opaque version of the provided color,
    /// or defaults to the custom '.subTwo' asset.
    static func subTwoVsColor (makeColor: Color?) -> Color {
        makeColor?.opacity(0.50).mix(with: .subTwo, by: 0.7) ?? .subTwo
    }
}
extension Shape {
    @ViewBuilder
    func subVsColor(makeColor: Color?) -> some View {
        if let makeColor {
            self
                .fill(makeColor.opacity(0.50))
        } else {
            self
                .fill(.sub)
        }
    }
}

extension Shape {
    @ViewBuilder
    func subTwoVsColor(makeColor: Color?) -> some View {
        if let makeColor {
            self
                .fill(makeColor.opacity(0.50).mix(with: .subTwo, by: 0.7))
        } else {
            self
                .fill(.subTwo)
        }
    }
}

extension Shape {
    @ViewBuilder
    func ultraThinMaterialVsColorFill(makeColor: Color?) -> some View {
        if let makeColor {
            self
                .fill(makeColor.opacity(0.50))
        } else {
            self
                .fill(.ultraThinMaterial)
        }
    }
}


