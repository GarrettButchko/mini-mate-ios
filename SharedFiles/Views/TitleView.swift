import SwiftUI

struct TitleView: View {
    
    var colors: [Color]
    var isManager: Bool
    
    init(colors: [Color]?, isManager: Bool = false) {
        self.colors = colors ?? [.red, .orange, .yellow, .green, .blue, .purple, .indigo, .pink]
        self.isManager = isManager
    }

    
    var body: some View {
        ZStack {
            // Foreground Title text
            VStack {
                HStack {
                    Text("Mini")
                    Spacer()
                }
                
                HStack {
                    Spacer()
                    Text(isManager ? "Manager" : "Mate")
                }
            }
            .font(isManager ? .title : .largeTitle)
            .bold()
            .foregroundColor(.mainOpp)
            .frame(width: isManager ? 150 : 130)
            
            // Orbiting background
            OrbitingCirclesView(colors: colors)
                .frame(width: 220, height: 150)
                .clipped()
        }
        .frame(width: 220, height: 150)
    }
}

// MARK: - Orbiting Circle Model
struct OrbitingCircle: Identifiable {
    let id = UUID()
    let angleOffset: Double
    let size: Double
    let speedMultiplier: Double
    let verticalScale: Double
    let color: Color
}

// MARK: - Circle Animation View
struct OrbitingCirclesView: View {
    let colors: [Color]
    @State private var orbitingCircles: [OrbitingCircle] = []
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            TimelineView(.animation) { timeline in
                let date = timeline.date.timeIntervalSinceReferenceDate
                let baseRotation = date * 50
                
                ZStack {
                    ForEach(orbitingCircles) { circle in
                        let angle = baseRotation * circle.speedMultiplier + circle.angleOffset
                        let radians = angle * .pi / 180
                        
                        // Use geometry for positioning
                        let x = (width * 0.4) * cos(radians)
                        let y = (circle.verticalScale / 60.0 * (height * 0.4)) * sin(radians)
                        
                        let scale = 0.5 + 0.5 * (1 + sin(radians))
                        
                        Circle()
                            .fill(circle.color)
                            .frame(width: circle.size * scale, height: circle.size * scale)
                            .position(x: width / 2 + x, y: height / 2 + y)
                            .opacity(0.4 + 0.6 * scale)
                    }
                }
            }
        }
        .onAppear {
            if orbitingCircles.isEmpty {
                generateCircles()
            }
        }
        .onChange(of: colors) {
            generateCircles()
        }
    }
    
    private func generateCircles() {
        orbitingCircles = (0..<8).map { index in
            OrbitingCircle(
                angleOffset: Double(index) * (360 / 8),
                size: Double.random(in: 10...20),
                speedMultiplier: Double.random(in: 0.8...1.2),
                verticalScale: Double.random(in: 30...60),
                color: colors[index % colors.count]
            )
        }
    }
}
