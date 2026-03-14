//
//  DateUtils.swift
//  MiniMate
//
//  Created by GitHub Copilot on 2026-03-13.
//

import Foundation

func makeWeekID(from date: Date = Date()) -> String {
    var calendar = Calendar(identifier: .iso8601)
    calendar.firstWeekday = 2 // Monday
    
    let weekOfYear = calendar.component(.weekOfYear, from: date)
    let yearForWeek = calendar.component(.yearForWeekOfYear, from: date)
    
    return String(format: "%d-W%02d", yearForWeek, weekOfYear)
}

func makeDayID(from date: Date = Date()) -> String {
    var calendar = Calendar(identifier: .iso8601)
    calendar.timeZone = TimeZone.current
    
    let year  = calendar.component(.year, from: date)
    let month = calendar.component(.month, from: date)
    let day   = calendar.component(.day, from: date)
    
    return String(format: "%04d-%02d-%02d", year, month, day)
}
