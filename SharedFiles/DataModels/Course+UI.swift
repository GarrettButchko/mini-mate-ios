//
//  Course+UI.swift
//  MiniMate
//
//  Created by Garrett Butchko on 12/19/25.
//

import SwiftUI

extension Course {
    var scoreCardColor: Color? {
        guard let value = scoreCardColorDT else { return nil }
        return Color.fromString(value)?.opacity(0.4)
    }
    
    var courseColors: [Color]? {
        guard let values = courseColorsDT else { return nil }
        let colors = values.compactMap { Color.fromString($0) }
        return colors.isEmpty ? nil : colors
    }
}

extension Color {
    /// Converts a string to a Color. Accepts both named colors and hex values.
    /// - Parameter string: A color name (e.g., "red") or hex value (e.g., "#FF5733" or "FF5733")
    /// - Returns: A Color if conversion is successful, nil otherwise
    static func fromString(_ string: String) -> Color? {
        let lowercased = string.lowercased()
        
        // Check if it's a hex value
        if lowercased.hasPrefix("#") || lowercased.count == 6 || lowercased.count == 8 {
            if let color = colorFromHex(string) {
                return color
            }
        }
        
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
    }
    
    /// Converts a hex string to a Color
    /// - Parameter hex: Hex string (with or without #, 6 or 8 characters for RGB or RGBA)
    /// - Returns: A Color if hex is valid, nil otherwise
    private static func colorFromHex(_ hex: String) -> Color? {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let length = hexSanitized.count
        let r, g, b, a: Double
        
        if length == 6 {
            r = Double((rgb & 0xFF0000) >> 16) / 255.0
            g = Double((rgb & 0x00FF00) >> 8) / 255.0
            b = Double(rgb & 0x0000FF) / 255.0
            a = 1.0
        } else if length == 8 {
            r = Double((rgb & 0xFF000000) >> 24) / 255.0
            g = Double((rgb & 0x00FF0000) >> 16) / 255.0
            b = Double((rgb & 0x0000FF00) >> 8) / 255.0
            a = Double(rgb & 0x000000FF) / 255.0
        } else {
            return nil
        }
        
        return Color(red: r, green: g, blue: b, opacity: a)
    }
}
