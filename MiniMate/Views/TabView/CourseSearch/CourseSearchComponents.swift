//
//  CourseSearchComponents.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/27/25.
//

import SwiftUI
import MapKit

// MARK: - Search Button
struct CourseSearchButton: View {
    @EnvironmentObject var courseViewModel: CourseViewModel
    @EnvironmentObject var locationHandler: LocationHandler
    
    var body: some View {
        Button {
            courseViewModel.searchNearby(locationHandler: locationHandler)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.blue)
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.white)
                    Text("Search for Nearby Courses")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
        }
        .frame(height: 50)
        .transition(.move(edge: .bottom).combined(with: .opacity).combined(with: .blurReplace()))
        .cardShadow()
    }
}

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

// MARK: - Course Result View
struct CourseResultView: View {
    @EnvironmentObject var locationHandler: LocationHandler
    @EnvironmentObject var courseViewModel: CourseViewModel
    @StateObject var viewModel = LookAroundViewModel()
    
    @State var titleHeight: CGFloat = 30
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    CourseDirectionsButton()
                    
                    if let course = courseViewModel.selectedCourse, course.isSupported {
                        CourseSupportedLocationCard(
                            course: course,
                            locationName: locationHandler.selectedItem?.name
                        )
                        
                        if course.socialLinks.count >= 1{
                            CourseSocialMediaCard(course: course)
                        }
                    } else {
                        CourseClaimButton()
                    }
                    
                    lookAroundSection
                    
                    CourseContactInfoCard(selectedItem: locationHandler.selectedItem)
                    
                    CourseLocationInfoCard(selectedItem: locationHandler.selectedItem)
                }
                .onAppear {
                    if let selected = locationHandler.selectedItem {
                        viewModel.fetchScene(for: selected)
                    }
                }
                .onChange(of: locationHandler.selectedItem) { oldItem, newItem in
                    if let newItem = newItem {
                        viewModel.fetchScene(for: newItem)
                    }
                }
            }
            .mask{
                VStack(spacing: 0) {
                    // 1. The 40pt fade-in area
                    LinearGradient(
                        colors: [.clear, .black],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: titleHeight) // Match the top content margin + padding
                    
                    // 2. The rest of the content (fully visible)
                    Rectangle()
                        .fill(.black)
                }
            }
                
            .contentMargins([.horizontal, .bottom], 16)
            .contentMargins(.top, 62)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            
            VStack{
                CourseResultViewHeader()
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
    }
    
    private var lookAroundSection: some View {
        Group {
            switch viewModel.result {
            case .loading:
                HStack {
                    Spacer()
                    ProgressView("Loading Look Around...")
                    Spacer()
                }
                .frame(height: 100)
                
            case .found:
                LookAroundPreview(scene: $viewModel.scene)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .cardShadow()
                
            case .error(let message):
                Text(message)
                    .padding()
                    .background(.sub)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            case .noSceneFound:
                EmptyView()
            case .idle:
                EmptyView()
            }
        }
    }
}
