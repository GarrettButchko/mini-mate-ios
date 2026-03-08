//
//  RollingNumberText.swift
//  MiniMate
//
//  Created by Garrett Butchko on 3/8/26.
//
import SwiftUI

struct RollingNumberText: View, Animatable {
    var value: Double
    var font: Font
    var textColor: Color
    var debugMode: Bool = false
    
    var animatableData: Double {
        get { value }
        set { value = newValue }
    }
    
    private var displayValue: Int {
        Int(max(0, value).rounded(.towardZero))
    }
    
    var body: some View {
        let digits = Array(String(displayValue))
        
        HStack(spacing: 0) {
            ForEach(Array(digits.enumerated()), id: \.offset) { index, ch in
                if let digit = ch.wholeNumberValue {
                    RollingDigitColumn(
                        digit: digit,
                        value: value,
                        indexFromRight: digits.count - 1 - index,
                        font: font,
                        textColor: textColor,
                        debugMode: debugMode
                    )
                } else {
                    Text(String(ch))
                        .font(font)
                        .foregroundStyle(textColor)
                }
            }
        }
        .monospacedDigit()
        .overlay(alignment: .bottom) {
            if debugMode {
                VStack(spacing: 2) {
                    Text("\(value, specifier: "%.2f")")
                        .font(.caption2)
                        .foregroundStyle(.red)
                    Text("\(displayValue)")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
                .padding(4)
                .background(.black.opacity(0.7))
                .cornerRadius(4)
                .offset(y: 40)
            }
        }
    }
}

private struct RollingDigitColumn: View {
    let digit: Int
    let value: Double
    let indexFromRight: Int
    let font: Font
    let textColor: Color
    let debugMode: Bool
    
    @State private var digitHeight: CGFloat = 0
    
    private var placeValue: Double {
        pow(10.0, Double(indexFromRight))
    }
    
    // Fractional progress for this digit's wheel.
    private var wheelPosition: Double {
        (max(0, value) / placeValue).truncatingRemainder(dividingBy: 10)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<10, id: \.self) { n in
                Text("\(n)")
                    .font(font)
                    .foregroundStyle(textColor)
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .onAppear {
                                    if digitHeight == 0 { digitHeight = proxy.size.height }
                                }
                        }
                    )
            }
        }
        .offset(y: -CGFloat(wheelPosition.rounded(.towardZero)) * digitHeight)
        .frame(height: digitHeight == 0 ? nil : digitHeight, alignment: .top)
        .clipped()
        .overlay(alignment: .center) {
            // Keeps layout stable while measuring on first frame.
            if digitHeight == 0 {
                Text("\(digit)")
                    .font(font)
                    .foregroundStyle(.clear)
            }
        }
        .overlay(alignment: .top) {
            if debugMode {
                VStack(spacing: 1) {
                    Text("\(digit)")
                        .font(.system(size: 8))
                        .foregroundStyle(.green)
                    Text("\(indexFromRight)")
                        .font(.system(size: 8))
                        .foregroundStyle(.blue)
                    Text("\(Int(placeValue))")
                        .font(.system(size: 8))
                        .foregroundStyle(.cyan)
                    Text("\(wheelPosition, specifier: "%.2f")")
                        .font(.system(size: 8))
                        .foregroundStyle(.yellow)
                }
                .padding(2)
                .background(.black.opacity(0.7))
                .cornerRadius(3)
                .offset(y: -50)
            }
        }
    }
}
