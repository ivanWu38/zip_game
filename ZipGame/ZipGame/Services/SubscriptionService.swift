import Foundation
import StoreKit

// MARK: - Subscription Plan
enum SubscriptionPlan: String, CaseIterable, Identifiable {
    case monthly = "com.zipgame.premium.monthly.v2"
    case quarterly = "com.zipgame.premium.quarterly"
    case yearly = "com.zipgame.premium.yearly"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .monthly: return "subscription.plan.monthly".localized
        case .quarterly: return "subscription.plan.quarterly".localized
        case .yearly: return "subscription.plan.yearly".localized
        }
    }

    var savingsPercentage: Int? {
        switch self {
        case .monthly: return nil
        case .quarterly: return 11
        case .yearly: return 58
        }
    }

    var sortOrder: Int {
        switch self {
        case .monthly: return 0
        case .quarterly: return 1
        case .yearly: return 2
        }
    }
}

// MARK: - Subscription Service
@MainActor
class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedSubscriptions: [Product] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isPremium = false
    @Published var errorMessage: String?

    private var updateListenerTask: Task<Void, Error>?

    private let productIds = Set(SubscriptionPlan.allCases.map { $0.rawValue })

    private init() {
        updateListenerTask = listenForTransactions()

        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        print("🔄 Loading products for IDs: \(productIds)")

        do {
            let storeProducts = try await Product.products(for: productIds)
            print("✅ Loaded \(storeProducts.count) products")
            for product in storeProducts {
                print("   - \(product.id): \(product.displayPrice)")
            }
            products = storeProducts.sorted { product1, product2 in
                let plan1 = SubscriptionPlan(rawValue: product1.id)
                let plan2 = SubscriptionPlan(rawValue: product2.id)
                return (plan1?.sortOrder ?? 0) < (plan2?.sortOrder ?? 0)
            }
        } catch {
            print("❌ Failed to load products: \(error)")
            print("   Error details: \(error.localizedDescription)")
            errorMessage = "Failed to load subscription options"
        }
    }

    // MARK: - Purchase
    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateSubscriptionStatus()
            await transaction.finish()
            return true

        case .userCancelled:
            return false

        case .pending:
            return false

        @unknown default:
            return false
        }
    }

    // MARK: - Restore Purchases
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
        } catch {
            print("Failed to restore purchases: \(error)")
            errorMessage = "Failed to restore purchases"
        }
    }

    // MARK: - Update Subscription Status
    func updateSubscriptionStatus() async {
        var purchasedSubs: [Product] = []

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                if transaction.productType == .autoRenewable {
                    if let product = products.first(where: { $0.id == transaction.productID }) {
                        purchasedSubs.append(product)
                    }
                }
            } catch {
                print("Transaction verification failed: \(error)")
            }
        }

        purchasedSubscriptions = purchasedSubs
        isPremium = !purchasedSubs.isEmpty

        // Persist premium status for offline access
        UserDefaults.standard.set(isPremium, forKey: "zip_isPremium")
    }

    // MARK: - Listen for Transactions
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try await self?.checkVerifiedAsync(result)
                    if let transaction = transaction {
                        await self?.updateSubscriptionStatus()
                        await transaction.finish()
                    }
                } catch {
                    print("Transaction update failed verification: \(error)")
                }
            }
        }
    }

    // MARK: - Verify Transaction (Async version for detached task)
    private func checkVerifiedAsync<T>(_ result: VerificationResult<T>) async throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Verify Transaction
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Helper Methods
    func product(for plan: SubscriptionPlan) -> Product? {
        products.first { $0.id == plan.rawValue }
    }

    func pricePerMonth(for product: Product) -> String? {
        guard let subscription = product.subscription else { return nil }

        let price = product.price
        let unit = subscription.subscriptionPeriod.unit
        let value = subscription.subscriptionPeriod.value

        var monthlyPrice: Decimal

        switch unit {
        case .month:
            monthlyPrice = price / Decimal(value)
        case .year:
            monthlyPrice = price / Decimal(value * 12)
        case .week:
            monthlyPrice = price * Decimal(4) / Decimal(value)
        case .day:
            monthlyPrice = price * Decimal(30) / Decimal(value)
        @unknown default:
            return nil
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceFormatStyle.locale

        return formatter.string(from: monthlyPrice as NSDecimalNumber)
    }

    func billingDescription(for product: Product) -> String {
        guard let subscription = product.subscription else { return "" }

        let unit = subscription.subscriptionPeriod.unit
        let value = subscription.subscriptionPeriod.value

        switch unit {
        case .month:
            if value == 1 {
                return ""
            } else if value == 3 {
                return String(format: "subscription.billing.quarterly".localized, product.displayPrice)
            } else {
                return String(format: "subscription.billing.months".localized, value, product.displayPrice)
            }
        case .year:
            return String(format: "subscription.billing.yearly".localized, product.displayPrice)
        case .week:
            return String(format: "subscription.billing.weekly".localized, product.displayPrice)
        case .day:
            return String(format: "subscription.billing.daily".localized, product.displayPrice)
        @unknown default:
            return ""
        }
    }
}

// MARK: - Store Error
enum StoreError: Error {
    case failedVerification
}
