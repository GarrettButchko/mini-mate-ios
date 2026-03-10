//
//  DataCardView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/26/26.
//
import SwiftUI
import MarqueeText

struct DataCard: View {
    var data: DataPointObject
    var title: String
    var infoText: String = "No Text Yet"
    var color: Color = .sub
    var cornerRadius: CGFloat = 12
    var fontStyle: UIFont.TextStyle = .subheadline
    
    var body: some View {
        
        VStack(spacing: 8) {
            HStack{
                MarqueeText(
                    text: title,
                    font: UIFont.preferredFont(forTextStyle: fontStyle),
                    leftFade: 16,
                    rightFade: 16,
                    startDelay: 2,
                    alignment: .leading
                )
                .foregroundStyle(.mainOpp)
        
                Spacer()
                
                InfoButton(infoText: infoText)
            }
            
            HStack{
                Text(data.value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(data.deltaColor != nil ? data.deltaColor! : .mainOpp)
                    .lineLimit(1) // Ensures the text stays on one line while shrinking
                    .minimumScaleFactor(0.5) // Allows text to shrink down to 75% of its original size
                if let delta = data.delta, let deltaColor = data.deltaColor {
                    Text(delta)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(deltaColor)
                        .lineLimit(1) // Ensures the text stays on one line while shrinking
                        .minimumScaleFactor(0.5) // Allows text to shrink down to 50% of its original size
                }
                Spacer()
            }
            
        }
        .padding()
        .background{
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(color)
        }
    }
}
