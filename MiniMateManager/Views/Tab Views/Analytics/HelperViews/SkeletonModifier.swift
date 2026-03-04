//
//  SkeletonModifier.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/26/26.
//
import SwiftUI

// 1. Create the Shimmer Effect
struct SkeletonModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .redacted(reason: .placeholder) // Built-in SwiftUI ghosting
            .overlay(
                GeometryReader { geo in
                    Color.white.opacity(0.3)
                        .mask(Rectangle().fill(
                            LinearGradient(colors: [.clear, .mainOpp.opacity(0.5), .clear],
                                           startPoint: .leading,
                                           endPoint: .trailing)
                        ))
                        .offset(x: -geo.size.width + (geo.size.width * 2 * phase))
                }
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    @ViewBuilder
    func skeleton(active: Bool) -> some View {
        if active {
            self.modifier(SkeletonModifier())
        } else {
            self
        }
    }
}
