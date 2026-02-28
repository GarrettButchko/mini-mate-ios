//
//  DataCardView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/26/26.
//
import SwiftUI

struct DataCard: View {
    var data: DataPointObject
    var title: String
    var infoText: String = "No Text Yet"
    var color: Color = .sub
    var cornerRadius: CGFloat = 12
    var fontStyle: Font = .system(size: 14, weight: .semibold)
    
    var body: some View {
        
        VStack(spacing: 8) {
            HStack{
                Text(title)
                    .foregroundStyle(.mainOpp)
                    .font(fontStyle)
                
                Spacer()
                
                InfoButton(infoText: infoText)
            }
            
            HStack{
                Text(data.value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(data.deltaColor != nil ? data.deltaColor! : .mainOpp)
                if let delta = data.delta, let deltaColor = data.deltaColor {
                    Text(delta)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(deltaColor)
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
