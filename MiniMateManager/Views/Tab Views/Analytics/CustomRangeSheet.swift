//
//  CustomRangeSheet.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/21/26.
//

import SwiftUI

struct CustomRangeSheet: View {
    @EnvironmentObject var VM: AnalyticsViewModel
    @Environment(\.dismiss) private var dismiss
    @Binding var range: AnalyticsRange
    
    @State private var startDate: Date
    @State private var endDate: Date
    
    init(range: Binding<AnalyticsRange>) {
        self._range = range
        
        // Set initial dates from the current range
        let today = Date()
        let defaultStart = Calendar.current.date(byAdding: .day, value: -30, to: today) ?? today
        
        if case let .custom(s, e) = range.wrappedValue {
            _startDate = State(initialValue: s)
            _endDate = State(initialValue: e)
        } else {
            _startDate = State(initialValue: defaultStart)
            _endDate = State(initialValue: today)
        }
    }
    
    var body: some View {
        VStack(spacing: 14) {
            
            HStack {
                Text("Custom Range - \(VM.daysBetween(startDate, endDate)) days")
                    .font(.headline)
                Spacer()
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 16) {
                
                Text("From")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack {
                    DatePicker("", selection: $startDate, displayedComponents: .date)
                        .labelsHidden()
                    Spacer()
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                
                Text("To")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack {
                    DatePicker("", selection: $endDate, in: startDate...Date(), displayedComponents: .date)
                        .labelsHidden()
                    Spacer()
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            HStack(spacing: 10) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .overlay {
                            RoundedRectangle(cornerRadius: 25)
                                .strokeBorder(.blue.opacity(0.3), lineWidth: 2)
                        }
                }
                
                Button {
                    // Normalize dates just in case
                    let s = min(startDate, endDate)
                    let e = max(startDate, endDate)
                    range = .custom(start: s, end: e)
                    dismiss()
                } label: {
                    Text("Apply")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.blue.opacity(0.9))
                        )
                        .foregroundStyle(.white)
                }
            }
        }
        .padding([.top, .horizontal], 30)
        .presentationDetents([.fraction(0.4)])
        .presentationDragIndicator(.visible)
    }
}
