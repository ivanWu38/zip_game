import SwiftUI

struct ATTPromptView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var attService = ATTService.shared

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    // Don't dismiss on background tap
                }

            // Prompt card
            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.zipPrimary.opacity(0.15))
                        .frame(width: 80, height: 80)

                    Image(systemName: "sparkles")
                        .font(.system(size: 36))
                        .foregroundColor(Color.zipPrimary)
                }

                // Title
                Text("Better Ad Experience")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Color.zipTextPrimary)
                    .multilineTextAlignment(.center)

                // Description
                VStack(spacing: 12) {
                    Text("Allow tracking to see ads that match your interests instead of random content.")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(Color.zipTextSecondary)
                        .multilineTextAlignment(.center)

                    Text("This won't increase the number of ads you see.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(Color.zipTextTertiary)
                        .multilineTextAlignment(.center)
                }

                // Buttons
                VStack(spacing: 12) {
                    // Continue button
                    Button(action: {
                        Task {
                            await attService.requestTrackingPermission()
                            dismiss()
                        }
                    }) {
                        Text("Continue")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.zipPrimary)
                            )
                    }

                    // Not Now button
                    Button(action: {
                        attService.skipTracking()
                        dismiss()
                    }) {
                        Text("Not Now")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(Color.zipTextTertiary)
                    }
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.zipCardBackground)
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 32)
        }
    }
}

#Preview {
    ATTPromptView()
}
