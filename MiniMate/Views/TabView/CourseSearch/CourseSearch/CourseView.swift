//
//  GameView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/6/25.
//

import SwiftUI
import MapKit

// MARK: - CourseViewContainer

/// The new entry point for this screen. It creates and wires up all the necessary
/// ViewModels and injects them into the view hierarchy.
struct CourseViewContainer: View {
    @EnvironmentObject var locationHandler: LocationHandler
    @EnvironmentObject var viewManager: ViewManager
    @EnvironmentObject var authModel: AuthViewModel

    /// This is the original ViewModel that un-refactored subviews still depend on.
    /// We create it here so we can pass it to the new `CourseSearchViewModel`
    /// and also provide it as an EnvironmentObject.
    @StateObject private var courseViewModel = CourseViewModel()

    var body: some View {
        // Create the new ViewModel, injecting its dependencies.
        let searchViewModel = CourseSearchViewModel(
            locationHandler: locationHandler,
            courseViewModel: courseViewModel
        )

        // The refactored CourseView now takes the new ViewModel.
        CourseView(viewModel: searchViewModel)
            // Provide the original view model to subviews like CourseSearchResultsView.
            .environmentObject(courseViewModel)
    }
}


// MARK: - CourseView

struct CourseView: View {
    @StateObject var viewModel: CourseSearchViewModel

    init(viewModel: CourseSearchViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        GeometryReader { geometry in
            if viewModel.hasLocationAccess {
                ZStack {
                    mapView
                    
                    VStack {
                        HStack {
                            Text("Course Search")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .padding()
                                .frame(height: 40)
                                .background(Material.regular, in: RoundedRectangle(cornerRadius: 25))
                                .cardShadow()
                            
                            Spacer()
                            
                            LocationButton(action: viewModel.recenterMap)
                                .cardShadow()
                        }
                        
                        Spacer()
                        
                        if !viewModel.isSearchPanelVisible {
                            CourseSearchButton()
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        } else {
                            VStack {
                                if viewModel.selectedMapItem != nil {
                                    CourseResultViewContainer()
                                        .transition(.move(edge: .trailing).combined(with: .opacity))
                                } else {
                                    CourseSearchResultsView()
                                        .transition(.move(edge: .leading).combined(with: .opacity))
                                }
                            }
                            .background(Material.regular)
                            .clipShape(RoundedRectangle(cornerRadius: 25))
                            .cardShadow()
                            .frame(height: geometry.size.height * 0.4)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .animation(.spring, value: viewModel.selectedMapItem)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                    .animation(.spring, value: viewModel.isSearchPanelVisible)
                }
            } else {
                VStack {
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
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear(perform: viewModel.onAppear)
    }
    
    private var mapView: some View {
        Map(position: $viewModel.mapCameraPosition, selection: $viewModel.selectedMapItem) {
            ForEach(viewModel.mapItems, id: \.self) { item in
                let name = item.name ?? "Unknown"
                let isSupported = viewModel.nameExists[name] ?? false
                
                Marker(name, coordinate: item.placemark.coordinate)
                    .tint(isSupported ? .purple : .green)
            }
            UserAnnotation()
        }
        .mapControls {
            MapCompass().mapControlVisibility(.hidden)
        }
        .animation(.spring, value: viewModel.mapCameraPosition)
    }
}

private struct LocationButton: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Material.regular)
                    .frame(width: 40, height: 40)
                
                Image(systemName: "location.fill")
                    .resizable()
                    .foregroundColor(.primary)
                    .frame(width: 20, height: 20)
            }
        }
    }
}

// MARK: - Placeholder View Modifier
// This is a placeholder for your custom .cardShadow() modifier
private struct CardShadow: ViewModifier {
    func body(content: Content) -> some View {
        content.shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

private extension View {
    func cardShadow() -> some View {
        self.modifier(CardShadow())
    }
}

