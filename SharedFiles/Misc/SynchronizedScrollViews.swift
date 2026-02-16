import SwiftUI

struct SyncedScrollViewRepresentable<Content: View>: UIViewRepresentable {
    @Binding var scrollOffset: CGFloat
    @Binding var syncSourceID: UUID?
    let viewID = UUID()
    let content: () -> Content

    func makeCoordinator() -> Coordinator {
        Coordinator(scrollOffset: $scrollOffset, syncSourceID: $syncSourceID, viewID: viewID)
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.alwaysBounceHorizontal = true
        scrollView.backgroundColor = .clear  // <-- Clear background for scroll view

        let hostedVC = UIHostingController(rootView:
            content()
                .background(Color.clear)  // <-- Clear background for SwiftUI content
                .scrollIndicators(.hidden)
        )
        hostedVC.view.translatesAutoresizingMaskIntoConstraints = false
        hostedVC.view.backgroundColor = .clear  // <-- Clear background for hosted view

        scrollView.addSubview(hostedVC.view)

        NSLayoutConstraint.activate([
            hostedVC.view.topAnchor.constraint(equalTo: scrollView.topAnchor),
            hostedVC.view.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            hostedVC.view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            hostedVC.view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            hostedVC.view.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        if syncSourceID != viewID && !scrollView.isDragging && scrollView.contentOffset.x != scrollOffset {
            scrollView.setContentOffset(CGPoint(x: scrollOffset, y: 0), animated: false)
        }
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        @Binding var scrollOffset: CGFloat
        @Binding var syncSourceID: UUID?
        let viewID: UUID

        init(scrollOffset: Binding<CGFloat>, syncSourceID: Binding<UUID?>, viewID: UUID) {
            _scrollOffset = scrollOffset
            _syncSourceID = syncSourceID
            self.viewID = viewID
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard syncSourceID != viewID else { return }

            DispatchQueue.main.async {
                self.syncSourceID = self.viewID
                self.scrollOffset = scrollView.contentOffset.x
            }

            // Clear sourceID after frame to avoid sync locks
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                if self.syncSourceID == self.viewID {
                    self.syncSourceID = nil
                }
            }
        }
    }
}
