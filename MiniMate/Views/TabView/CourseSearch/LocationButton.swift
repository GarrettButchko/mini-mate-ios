//
//  LocationButton.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/27/25.
//

import SwiftUI
import MapKit

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
