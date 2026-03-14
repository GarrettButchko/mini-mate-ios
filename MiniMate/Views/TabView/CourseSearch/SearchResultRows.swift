//
//  SearchResultRow.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/27/25.
//

import SwiftUI
import MarqueeText
import MapKit

// MARK: - Search Results View
struct CourseSearchResultsView: View {
    @EnvironmentObject var courseViewModel: CourseViewModel
    @EnvironmentObject var locationHandler: LocationHandler
    @State private var showRetryButton = false
    @State var titleHeight: CGFloat = 30
    
    var body: some View {
        ZStack {
            if courseViewModel.isLoadingCourses || locationHandler.mapItems.isEmpty {
                VStack(spacing: 15) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Trying to find nearby courses...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if showRetryButton {
                        Button(action: {
                            courseViewModel.searchNearby(locationHandler: locationHandler)
                        }) {
                            Text("Try Again")
                                .fontWeight(.semibold)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    showRetryButton = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        withAnimation(){
                            showRetryButton = true
                        }
                    }
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading) {
                        if let userCoord = locationHandler.userLocation {
                            ForEach(locationHandler.mapItems, id: \.self) { mapItem in
                                if locationHandler.mapItems.count > 0 && mapItem != locationHandler.mapItems[0]{
                                    Divider()
                                }
                                SearchResultRow(item: mapItem, userLocation: userCoord)
                            }
                        } else {
                            Text("Fetching location...")
                        }
                    }
                    Rectangle()
                        .fill(.clear)
                        .frame(height: 4)
                }
                .mask(
                    VStack(spacing: 0){
                        // 1. The 40pt fade-in area
                        LinearGradient(
                            colors: [.clear, .black],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: titleHeight)
                        
                        Rectangle()
                            .fill(.black)
                    }
                )
                .contentMargins(.horizontal, 16)
                .contentMargins(.top, 54)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                
            }
            
            VStack{
                HStack {
                    Text("Courses")
                        .font(.title3).fontWeight(.bold)
                        .foregroundStyle(.mainOpp)
                    Spacer()
                    Button {
                        courseViewModel.cancel(locationHandler: locationHandler)
                    } label: {
                        Text("Cancel")
                            .frame(width: 70, height: 30)
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
                .padding()
                .padding(.bottom, 16)
                .background {
                    GeometryReader { proxy in
                        Color.clear
                            .task(id: proxy.size) {
                                titleHeight = proxy.size.height // Capture the size and monitor changes
                            }
                    }
                }
                Spacer()
            }
        }
        .cardShadow()
    }
}



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
