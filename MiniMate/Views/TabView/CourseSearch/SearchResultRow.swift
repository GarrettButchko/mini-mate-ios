//
//  SearchResultRow.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/27/25.
//

import SwiftUI
import MapKit
import MarqueeText

struct SearchResultRow: View {
    @EnvironmentObject var VM: CourseViewModel
    @EnvironmentObject var locationHandler: LocationHandler
    
    let item: MKMapItem
    let userLocation: CLLocationCoordinate2D
    @State private var isSupported: Bool = false
    let courseRepo = CourseRepository()
    
    var body: some View {
        Button {
            VM.updatePosition(mapItem: item, locationHandler: locationHandler)
            if let name = item.name, isSupported {
                VM.getCourse(name: name)
            } else {
                VM.selectedCourse = nil
            }
        } label: {
            HStack{
                VStack(alignment: .leading) {
                    
                    MarqueeText(
                        text: "\(item.name ?? "Unknown Place")",
                        font: UIFont.preferredFont(forTextStyle: .headline),
                        leftFade: 16,
                        rightFade: 16,
                        startDelay: 3
                    )
                    .foregroundStyle(.mainOpp)
                    
                    let offsetLat = userLocation.latitude - 0.015
                    let distanceInMiles = CLLocation(latitude: offsetLat, longitude: userLocation.longitude)
                        .distance(from: CLLocation(latitude: item.placemark.coordinate.latitude,
                                                   longitude: item.placemark.coordinate.longitude)) / 1609.34
                
                    MarqueeText(
                        text: "\(String(format: "%.1f", distanceInMiles)) mi - \(VM.getPostalAddress(from: item))",
                        font: UIFont.preferredFont(forTextStyle: .subheadline),
                        leftFade: 16,
                        rightFade: 16,
                        startDelay: 4
                    )
                    .foregroundStyle(.mainOpp)
                }
                .frame(height: 50)
                Spacer()
                
                if isSupported{
                    ZStack{
                        Circle()
                            .fill(.purple.opacity(0.3))
                            .frame(width: 24, height: 24)
                        
                        Image("logo_svg")
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .foregroundStyle(.mainOpp)
                            .frame(width: 17, height: 17)
                    }
                }
            }
        }
        .onAppear(){
            preloadNameChecks()
        }
        .onChange(of: item) { _, _ in
            preloadNameChecks()
        }
    }
    
    func preloadNameChecks() {
        if let name = item.name {
            courseRepo.courseNameExistsAndSupported(name) { exists in
                if exists {
                    DispatchQueue.main.async {
                        isSupported = true
                    }
                }
            }
        }
    }
}
