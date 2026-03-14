//
//  String+Extensions.swift
//  MiniMate
//
//  Created by GitHub Copilot on 2026-03-13.
//

import Foundation

extension String {
    func sanitizedForFirebaseID() -> String {
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-")
        return self.unicodeScalars
            .filter { allowed.contains($0) }
            .map(String.init)
            .joined()
    }
}
