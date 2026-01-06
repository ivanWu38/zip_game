import SwiftUI

extension Color {
    static let zipBlue = Color.blue
    static let zipBackground = Color(.systemBackground)
    static let zipSecondary = Color(.systemGray6)
}

extension View {
    func zipCardStyle() -> some View {
        self
            .padding()
            .background(Color.zipSecondary)
            .cornerRadius(12)
    }
}
