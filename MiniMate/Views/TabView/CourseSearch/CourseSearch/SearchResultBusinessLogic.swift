// SearchResultBusinessLogic.swift
// MiniMate

import Foundation

/// A platform-agnostic class designed to be easily migrated to a Kotlin Multiplatform shared module.
/// It contains pure business, calculation, and formatting rules for search results.
class SearchResultBusinessLogic {
    
    // MARK: - Configuration Rules
    
    /// The amount of time to wait before showing the retry button
    var retryButtonDelay: TimeInterval {
        return 3.0
    }
    
    // MARK: - Location Calculations
    
    /// Calculates an adjusted latitude for centering/distance calculations
    func getOffsetLatitude(baseLatitude: Double) -> Double {
        return baseLatitude - 0.015
    }
    
    /// Converts distance in meters to miles
    func metersToMiles(meters: Double) -> Double {
        return meters / 1609.34
    }
    
    // MARK: - Presentation Formatting
    
    /// Formats the distance to a single decimal point
    func formatDistance(_ distanceInMiles: Double) -> String {
        return String(format: "%.1f", distanceInMiles)
    }
    
    /// Constructs the final subtitle string combining distance and address
    func buildSubtitle(distanceInMiles: Double, address: String) -> String {
        let formattedDistance = formatDistance(distanceInMiles)
        return "\(formattedDistance) mi - \(address)"
    }
}
