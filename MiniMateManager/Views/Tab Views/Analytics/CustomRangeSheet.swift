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
        _startDate = State(initialValue: range.wrappedValue.startDate)
        _endDate = State(initialValue: range.wrappedValue.endDate)
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
                    // Range Logic:
                    // 1. Min: 90 days before endDate
                    // 2. Max: The current endDate
                    DatePicker("",
                               selection: $startDate,
                               in: date(byAdding: -90, to: endDate)...endDate,
                               displayedComponents: .date)
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
                    // Range Logic:
                    // 1. Min: The current startDate
                    // 2. Max: The EARLIER of (startDate + 90 days) OR Today
                    DatePicker("",
                               selection: $endDate,
                               in: startDate...min(Date(), date(byAdding: 90, to: startDate)),
                               displayedComponents: .date)
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
    
    // A helper to get a date +/- days from another date
    func date(byAdding days: Int, to baseDate: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: baseDate) ?? baseDate
    }
}
