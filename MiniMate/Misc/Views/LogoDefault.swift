//
//  LogoDefault.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/15/26.
//

import SwiftUI

struct LogoDefault: View {
    
    var topPadding: CGFloat = 16
    
    var body: some View {
        Image("logoOpp")
            .resizable()
            .scaledToFit()
            .frame(width: 50, height: 50)
            .grayscale(1.0)
            .opacity(0.5)
            .padding(.top, topPadding)
            .padding(.bottom, 16)
    }
}


