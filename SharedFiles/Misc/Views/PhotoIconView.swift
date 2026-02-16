import SwiftUI

struct PhotoIconView<Background: ShapeStyle>: View {
    let photoURL: URL?
    let name: String
    let imageSize: CGFloat
    var background: Background

    var body: some View {
        VStack {
            ZStack {
                /// Background circle
                Circle()
                    .fill(background)
                    .frame(width: imageSize + 10, height: imageSize + 10)

                /// Photo
                AsyncImage(url: photoURL) { phase in
                    switch phase {
                    case .empty:
                        Image("logoOpp")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: imageSize, height: imageSize)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit) // show full image
                            .frame(width: imageSize, height: imageSize)
                            .clipShape(Circle()) // keeps the round shape
                    case .failure:
                        Image("logoOpp")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: imageSize, height: imageSize)
                    @unknown default:
                        Image("logoOpp")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: imageSize, height: imageSize)
                    }
                }
            }
            /// Name on the bottom with dynamic text size
            Text(name)
                .font(.system(size: imageSize * 0.3)) // Dynamic font size based on imageSize
                .lineLimit(1)
                .foregroundStyle(.mainOpp)
        }
    }
}

