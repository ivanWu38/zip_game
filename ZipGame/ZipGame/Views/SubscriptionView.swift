import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var selectedPlan: SubscriptionPlan = .yearly
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient.zipBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            // Header
                            headerSection

                            // Benefits
                            benefitsSection

                            // Plans
                            plansSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }

                    // Bottom Section (fixed)
                    bottomSection
                }
            }
            .navigationTitle("Play Without Ads")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.zipTextSecondary)
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .task {
                // Reload products when view appears
                if subscriptionService.products.isEmpty {
                    await subscriptionService.loadProducts()
                }
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Enjoy smoother gameplay with zero interruptions.")
                .font(.system(size: 18, weight: .regular, design: .rounded))
                .foregroundColor(Color.zipTextTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    // MARK: - Benefits Section
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BenefitRow(
                text: "Remove all ads",
                description: "enjoy uninterrupted gameplay"
            )
            BenefitRow(
                text: "Customize your board",
                description: "unlock all color themes"
            )
            BenefitRow(
                text: "Unique fonts",
                description: "personalize your game style"
            )
            BenefitRow(
                text: "Support the developers",
                description: "help us improve the game"
            )
        }
        .padding(.vertical, 8)
    }

    // MARK: - Plans Section
    private var plansSection: some View {
        VStack(spacing: 12) {
            if subscriptionService.isLoading {
                // Loading state
                ProgressView()
                    .frame(height: 200)
            } else if subscriptionService.products.isEmpty {
                // Error message when products can't be loaded
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(Color.zipTextTertiary)

                    Text("Unable to load subscription options")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(Color.zipTextSecondary)

                    Text("Please check your internet connection and try again.")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(Color.zipTextTertiary)
                        .multilineTextAlignment(.center)

                    Button(action: {
                        Task {
                            await subscriptionService.loadProducts()
                        }
                    }) {
                        Text("Retry")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(Color.zipPrimary)
                            )
                    }
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // Real products loaded
                ForEach(SubscriptionPlan.allCases) { plan in
                    if let product = subscriptionService.product(for: plan) {
                        PlanCard(
                            plan: plan,
                            product: product,
                            isSelected: selectedPlan == plan,
                            pricePerMonth: subscriptionService.pricePerMonth(for: product),
                            billingDescription: subscriptionService.billingDescription(for: product)
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedPlan = plan
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Bottom Section
    private var bottomSection: some View {
        VStack(spacing: 16) {
            Divider()
                .background(Color.zipCardBorder)

            // Subscribe Button
            Button(action: {
                Task {
                    await purchase()
                }
            }) {
                HStack {
                    if isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else if let product = selectedProduct {
                        Text("Subscribe - \(product.displayPrice)")
                            .font(.system(size: 19, weight: .bold, design: .rounded))
                    } else {
                        Text("Subscribe")
                            .font(.system(size: 19, weight: .bold, design: .rounded))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(subscriptionService.products.isEmpty ? Color.zipPrimary.opacity(0.5) : Color.zipPrimary)
                )
            }
            .disabled(isPurchasing || subscriptionService.products.isEmpty)
            .padding(.horizontal, 20)

            // Terms and Restore
            VStack(spacing: 8) {
                Text("Cancel anytime. ")
                    .foregroundColor(Color.zipTextTertiary)
                +
                Text("[Terms of Use](https://www.apple.com/legal/internet-services/itunes/dev/stdeula/)")
                    .foregroundColor(Color.zipPrimary)
                +
                Text(" and ")
                    .foregroundColor(Color.zipTextTertiary)
                +
                Text("[Privacy Policy](https://ikuheikure.xyz/apps/ZipGame/)")
                    .foregroundColor(Color.zipPrimary)
                +
                Text(" apply.")
                    .foregroundColor(Color.zipTextTertiary)
            }
            .font(.system(size: 13, weight: .regular, design: .rounded))
            .environment(\.openURL, OpenURLAction { url in
                UIApplication.shared.open(url)
                return .handled
            })

            Button("Restore Purchases") {
                Task {
                    await subscriptionService.restorePurchases()
                }
            }
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .foregroundColor(Color.zipPrimary)
            .padding(.bottom, 16)
        }
        .background(Color.zipBackgroundEnd)
    }

    // MARK: - Helpers
    private var selectedProduct: Product? {
        subscriptionService.product(for: selectedPlan)
    }

    private func purchase() async {
        guard let product = selectedProduct else { return }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let success = try await subscriptionService.purchase(product)
            if success {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Benefit Row
struct BenefitRow: View {
    let text: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.zipPrimary)
                .frame(width: 8, height: 8)
                .padding(.top, 7)

            Text("\(text) – \(description)")
                .font(.system(size: 17, weight: .regular, design: .rounded))
                .foregroundColor(Color.zipTextPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Plan Card
struct PlanCard: View {
    let plan: SubscriptionPlan
    let product: Product
    let isSelected: Bool
    let pricePerMonth: String?
    let billingDescription: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 10) {
                        Text(plan.displayName)
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.zipTextPrimary)

                        if let savings = plan.savingsPercentage {
                            Text("Save \(savings)%")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.zipPrimary)
                                )
                        }
                    }

                    if billingDescription.isEmpty {
                        Text(product.displayPrice + " / Month")
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundColor(Color.zipTextPrimary)
                    } else {
                        Text(billingDescription)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(Color.zipTextPrimary)

                        if let monthly = pricePerMonth {
                            Text("\(monthly) / Month")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(Color.zipTextTertiary)
                        }
                    }
                }

                Spacer()

                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.zipPrimary : Color.zipCardBorder, lineWidth: 2)
                        .frame(width: 26, height: 26)

                    if isSelected {
                        Circle()
                            .fill(Color.zipPrimary)
                            .frame(width: 26, height: 26)

                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.zipCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.zipPrimary : Color.zipCardBorder, lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SubscriptionView()
}
