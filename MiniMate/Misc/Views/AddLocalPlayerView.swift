import SwiftUI

struct AddLocalPlayerView: View {
    // Moved to a constant or static property for better performance
    let colors: [(name: String, color: Color)] = [
        ("red", .red),
        ("orange", .orange),
        ("yellow", .yellow),
        ("green", .green),
        ("blue", .blue),
        ("indigo", .indigo),
        ("purple", .purple),
        ("pink", .pink),
        ("brown", .brown)
    ]
    
    @EnvironmentObject var gameVM: GameViewModel
    @EnvironmentObject var hostVM: HostViewModel
    
    @State var newPlayerName = ""
    @State var newPlayerEmail = ""
    @State var playerBallColor: String? = nil
    
    @State private var viewContentHeight: CGFloat = 0
    
    var isDisabled: Bool {
        gameVM.getCourse() != nil
        ?
        newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        newPlayerEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        ProfanityFilter.containsBlockedWord(newPlayerName) ||
        !newPlayerEmail.isValidEmail
        :
        newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        ProfanityFilter.containsBlockedWord(newPlayerName)
    }
    
    @Binding var showColor: Bool
    
    var body: some View {
        VStack(spacing: 18) {
            headerSection
                .padding(.horizontal, 24)
            nameAndEmailRow
                .padding(.horizontal, 24)
            HStack{
                Spacer()
                Text("Ball Color")
                    .font(.footnote)
                    .foregroundStyle(.mainOpp)
                Spacer()
            }
            .padding(.horizontal, 24)
            colorRow
                .contentMargins(.horizontal, 24)
            buttonRow
                .padding(.horizontal, 24)
        }
        .padding(.top, 24)
        .presentationDetents([.fraction(0.42)])
        .presentationDragIndicator(.visible)
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
    
    private var nameAndEmailRow: some View {
        VStack(spacing: 12) {
            HStack {
                TextField("Name", text: $newPlayerName)
                    .characterLimit($newPlayerName, maxLength: 18)
            }
            
            if gameVM.getCourse() != nil {
                Divider()
                    .frame(height: 1) // Force the height so it can't disappear
                    .background(Color.mainOpp.opacity(0.2)) // Ensure it's visible
                TextField("Email", text: $newPlayerEmail)
                    .autocapitalization(.none)   // starts lowercase / no auto-cap
                    .keyboardType(.emailAddress)
            }
        }
        .padding(16)
        .fixedSize(horizontal: false, vertical: true)
        .background(RoundedRectangle(cornerRadius: 30).fill(.mainOpp.opacity(0.15)))
    }
    
    private var colorRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack{
                ForEach(colors, id: \.name) { colorOption in
                    Button {
                        withAnimation{
                            playerBallColor = colorOption.name
                        }
                    } label: {
                        Circle()
                            .fill(.mainOpp.opacity(0.15))
                            .frame(width: 44, height: 44) // Increased touch target
                            .overlay {
                                Circle()
                                    .fill(playerBallColor == colorOption.name ? colorOption.color.opacity(0.3) : colorOption.color)
                                    .frame(width: 32, height: 32)
                            }
                    }
                    .buttonStyle(PlainButtonStyle()) // Removes default button flash
                }
            }
        }
    }


    private var buttonRow: some View {
        HStack{
            Button(action: dismiss) {
                Text("Cancel")
                    .font(.title3)
                    .foregroundStyle(.mainOpp)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                
                    .background{
                        Capsule()
                            .fill(.mainOpp.opacity(0.15))
                    }
            }
            .buttonStyle(.plain)
            
            Button{
                hostVM.addPlayer(gameVM, newPlayerName: newPlayerName, newPlayerEmail: newPlayerEmail, playerBallColor: playerBallColor)
                dismiss()
            } label: {
                Text("Add")
                    .font(.title3)
                    .foregroundStyle(.mainOpp)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background{
                        Capsule()
                            .fill(.mainOpp.opacity(0.15))
                    }
            }
            .buttonStyle(.plain)
            .disabled(isDisabled)
        }
    }
    
    // MARK: - Logic
    
    private func dismiss() {
        showColor = false
    }
}
