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
        Picker("Section", selection: $pickedSection) {
            ForEach(leaderboardSection.allCases, id: \.self) { section in
                Label(section.rawValue, systemImage: section.sfSymbol)
                    .tag(section)
            }
        }
        .pickerStyle(.segmented)
    }
}
