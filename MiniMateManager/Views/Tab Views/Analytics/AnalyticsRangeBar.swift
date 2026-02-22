//
//  AnalyticsRangeBar.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/21/26.
//

import SwiftUI

struct AnalyticsRangeBar: View {
    @EnvironmentObject var VM: AnalyticsViewModel
    @State private var showCustomSheet = false
    
    var body: some View {
        HStack(spacing: 10) {
            
            // Dropdown
            Menu {
                Button("Last 7 days") { VM.range = .last7 }
                Button("Last 30 days") { VM.range = .last30 }
                Button("Last 90 days") { VM.range = .last90 }
            } label: {
                HStack {
                    Text(VM.range.isCustom ? VM.getDateRangeString() + ", \(VM.range.daysBetween) days" : VM.range.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.mainOpp)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.mainOpp.opacity(0.5))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(.subTwo)
                )
            }
            
            // Custom
            Button {
                showCustomSheet = true
            } label: {
                Text("Custom Range")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.blue.opacity(0.9))
                    )
                    .foregroundStyle(.white)
            }
        }
        .sheet(isPresented: $showCustomSheet) {
            CustomRangeSheet(range: $VM.range)
                .presentationDetents([.height(340)])
                .presentationDragIndicator(.visible)
        }
    }
}
