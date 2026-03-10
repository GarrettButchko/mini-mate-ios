//
//  LeaderBoardSectionToggleView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 3/9/26.
//
import SwiftUI

struct LeaderBoardSectionToggleView: View {
    @Binding var pickedSection: leaderboardSection

    var body: some View {
        Menu {
            ForEach(leaderboardSection.allCases, id: \.self) { section in
                Button(section.rawValue) {
                    pickedSection = section
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: pickedSection.sfSymbol)
                    .frame(width: 16)
                Text(pickedSection.rawValue)
                    .lineLimit(1)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .foregroundStyle(.white)
            .background {
                RoundedRectangle(cornerRadius: 25)
                    .fill(.blue)
            }
        }
    }
}
