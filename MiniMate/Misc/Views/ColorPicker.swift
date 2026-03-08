import SwiftUI

struct AddLocalPlayerView: View {
    // Moved to a constant or static property for better performance
    let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .indigo, .purple, .pink, .brown]
    @State var canAdd: Bool = false
    
    @Binding var showColor: Bool
    let function: (_ color: Color) -> Void
    
    var body: some View {
        ZStack {
            // Background dimming - simplified
            Color.black.opacity(0.25)
                .ignoresSafeArea()
                .onTapGesture { dismiss() } // Allow tapping outside to dismiss
            
            // Popup card
            VStack(spacing: 24) {
                headerSection
                
                colorRow
                
                buttonRow
            }
            .padding(24)
            .background {
                RoundedRectangle(cornerRadius: 38, style: .continuous)
                    .ifAGENoDefaultColor()
                    .cardShadow()
            }
            .padding(.horizontal, 30)
            .transition(.scale(scale: 0.9).combined(with: .opacity))
        }
    }
    
    // MARK: - Subviews
    private var headerSection: some View {
        HStack {
            Spacer()
            Text("Add Local Player")
                .font(.system(.title3, weight: .regular))
            Spacer()
        }
    }
    
    private var colorRow: some View {
        ScrollView(.horizontal) {
            ForEach(colors, id: \.self) { color in
                Button {
                    function(color)
                    dismiss()
                } label: {
                    Circle()
                        .fill(.mainOpp.opacity(0.15))
                        .frame(width: 44, height: 44) // Increased touch target
                        .overlay {
                            Circle()
                                .fill(color)
                                .frame(width: 32, height: 32)
                        }
                }
                .buttonStyle(PlainButtonStyle()) // Removes default button flash
            }
        }
    }


    private var buttonRow: some View {
        HStack{
            Button(action: dismiss) {
                Text("Cancel")
                    .font(.title3)
                    .foregroundStyle(.mainOpp)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                
                    .background{
                        Capsule()
                            .fill(.mainOpp.opacity(0.15))
                    }
            }
            .buttonStyle(.plain)
            
            Button(action: dismiss) {
                Text("Add")
                    .font(.title3)
                    .foregroundStyle(canAdd ? .mainOpp : .mainOpp.opacity(0.5))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background{
                        Capsule()
                            .fill(.mainOpp.opacity(0.15))
                    }
            }
            .buttonStyle(.plain)
            .disabled(!canAdd)
        }
    }
    
    // MARK: - Logic
    
    private func dismiss() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            showColor = false
        }
    }
}
