import SwiftUI

struct NameEntryModal: View {
    @Binding var isPresented: Bool
    @State private var playerName: String = ""
    @FocusState private var nameFieldFocused: Bool
    let onSubmit: (String) -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(AppTheme.titleGradient)
                        .frame(width: 52, height: 52)
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                .shadow(color: AppTheme.primary.opacity(0.5), radius: 10, y: 4)

                Text("New High Score!")
                    .font(AppTheme.displayFont(22))
                    .foregroundColor(.white)

                Text("Enter your name for the leaderboard")
                    .font(AppTheme.bodyFont(13))
                    .foregroundColor(AppTheme.textSecondary)

                TextField("Your name", text: $playerName)
                    .font(AppTheme.bodyFont(17, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 10)
                    .frame(maxWidth: 220)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(nameFieldFocused ? AppTheme.primary : Color.white.opacity(0.15), lineWidth: 1.5)
                            )
                    )
                    .focused($nameFieldFocused)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .onSubmit { save() }

                HStack(spacing: 22) {
                    Button("Skip") {
                        isPresented = false
                    }
                    .font(AppTheme.bodyFont(15))
                    .foregroundColor(AppTheme.textTertiary)
                    .buttonStyle(PressableButtonStyle())

                    Button("Save") {
                        save()
                    }
                    .font(AppTheme.titleFont(18))
                    .foregroundColor(AppTheme.primary)
                    .buttonStyle(PressableButtonStyle())
                }
                .padding(.top, 2)
            }
            .padding(26)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 22)
                        .fill(AppTheme.backgroundBottom.opacity(0.35))
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(AppTheme.primary.opacity(0.3), lineWidth: 1)
                }
            )
            .frame(maxWidth: 340)
        }
        .onAppear {
            nameFieldFocused = true
        }
    }

    private func save() {
        let name = playerName.trimmingCharacters(in: .whitespaces)
        onSubmit(name.isEmpty ? "AAA" : name)
        isPresented = false
    }
}
