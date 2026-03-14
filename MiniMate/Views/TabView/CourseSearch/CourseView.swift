//
//  GameView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/6/25.
//

import SwiftUI
import MapKit

// MARK: - CourseView

struct CourseView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var locationHandler: LocationHandler
    
    @EnvironmentObject var viewManager: ViewManager
    @EnvironmentObject var authModel: AuthViewModel
    @StateObject var courseViewModel: CourseViewModel
    
    @State private var showRetryButton = false
    
    @StateObject var viewModel = LookAroundViewModel()
    
    init() {
        _courseViewModel = StateObject(
            wrappedValue: CourseViewModel()
        )
    }
    
    var body: some View {
        GeometryReader { geometry in
            if locationHandler.hasLocationAccess {
                ZStack {
                    // MARK: - Map
                    mapView
                    
                    // MARK: - Overlay UI
                    VStack {
                        // Top Bar
                        HStack {
                            
                            Text("Course Search")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .padding()
                                .frame(height: 40)
                                .background(content: {
                                    RoundedRectangle(cornerRadius: 25)
                                        .ifAvailableGlassEffect()
                                })
                                .cardShadow()
                            
                            Spacer()
                            
                            LocationButton(cameraPosition: $courseViewModel.position, isUpperHalf: $courseViewModel.isUpperHalf, selectedResult: locationHandler.bindingForSelectedItem(), locationHandler: locationHandler)
                                .cardShadow()
                        }
                        
                        Spacer()
                        
                        // Bottom Panel
                        if !courseViewModel.isUpperHalf {
                            CourseSearchButton()
                        } else {
                            VStack {
                                if locationHandler.selectedItem != nil {
                                    CourseResultView()
                                        .transition(.move(edge: .trailing).combined(with: .opacity))
                                } else {
                                    CourseSearchResultsView()
                                        .transition(.move(edge: .leading).combined(with: .opacity))
                                }
                            }
                            .background {
                                RoundedRectangle(cornerRadius: 25)
                                    .ifAvailableGlassEffect()
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 25))
                            .cardShadow()
                            .frame(height: geometry.size.height * 0.4)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
                .environmentObject(courseViewModel)
            } else {
                HStack(alignment: .center){
                    Spacer()
                    VStack(alignment: .center){
                        Spacer()
                        Text("Please enable Location Services for this app.\n\nTap 'Open Settings' → Location → Allow While Using the App.")
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 8)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .onAppear {
            courseViewModel.onAppearance(locationHandler: locationHandler)
        }
    }
    
    var mapView: some View {
        Map(position: $courseViewModel.position, selection: locationHandler.bindingForSelectedItem()) {
            withAnimation(){
                ForEach(locationHandler.mapItems, id: \.self) { item in
                    let name = item.name ?? "Unknown"
                    let exists = courseViewModel.nameExists[name] ?? false
                    
                    Marker(name, coordinate: item.placemark.coordinate)
                        .tint(exists ? .purple : .green)
                }
                
            }
            UserAnnotation()
        }
        .onChange(of: locationHandler.selectedItem) { oldValue, newValue in
            withAnimation {
                courseViewModel.setPosition(locationHandler.updateCameraPosition(newValue))
            }
        }
        .onAppear {
            courseViewModel.preloadNameChecks(for: locationHandler.mapItems)
        }
        .onChange(of: locationHandler.mapItems) {
            courseViewModel.preloadNameChecks(for: locationHandler.mapItems)
        }
        .mapControls {
            MapCompass()
                .mapControlVisibility(.hidden)
        }
    }
}

struct LocationButton: View {
    @Binding var cameraPosition: MapCameraPosition
    @Binding var isUpperHalf: Bool
    @Binding var selectedResult: MKMapItem?
    @ObservedObject var locationHandler: LocationHandler
    
    var body: some View {
        Button(action: {
            withAnimation {
                cameraPosition = locationHandler.updateCameraPosition(selectedResult)
            }
        }) {
            ZStack {
                Circle()
                    .ifAvailableGlassEffect()
                    .frame(width: 40, height: 40)
                
                Image(systemName: "location.fill")
                    .resizable()
                    .foregroundColor(.mainOpp)
                    .frame(width: 20, height: 20)
            }
        }
    }
}

