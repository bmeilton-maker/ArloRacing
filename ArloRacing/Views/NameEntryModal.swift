import SwiftUI

struct NameEntryModal: View {
    @Binding var isPresented: Bool
    @State private var playerName: String = ""
    let onSubmit: (String) -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("New High Score!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Enter your name for the leaderboard")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.gray)

                TextField("Your name", text: $playerName)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 250)
                    .autocorrectionDisabled()

                HStack(spacing: 16) {
                    Button("Skip") {
                        isPresented = false
                    }
                    .foregroundColor(.gray)

                    Button("Save") {
                        let name = playerName.trimmingCharacters(in: .whitespaces)
                        onSubmit(name.isEmpty ? "AAA" : name)
                        isPresented = false
                    }
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.15, green: 0.15, blue: 0.2))
            )
        }
    }
}
