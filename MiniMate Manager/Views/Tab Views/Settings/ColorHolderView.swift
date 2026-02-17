//
//  ColorHolderView.swift
//  MiniMate Manager
//
//  Created by Garrett Butchko on 12/21/25.
//

import SwiftUI

struct ColorHolderView: View {
    
    var color: Color? = nil
    
    let showFunction: () -> Void
    let deleteFunction: () -> Void
    
    var body: some View {
        if let color {
            Button {
                deleteFunction()
            } label: {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 40, height: 40)
                    .overlay{
                        Circle()
                            .fill(color)
                            .frame(width: 30, height: 30)
                    }
            }
        } else {
            Button {
                withAnimation(){
                    showFunction()
                }
            } label: {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: "plus")
                            .resizable()
                            .frame(width: 20, height: 20)
                    }
            }
        }
    }
}


