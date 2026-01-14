import SwiftUI
import GoogleMobileAds

// MARK: - AdMob Configuration
struct AdMobConfig {
    // Production Ad Unit IDs
    static let bannerAdUnitID = "ca-app-pub-5654617376526903/5513143481"
    static let interstitialAdUnitID = "ca-app-pub-5654617376526903/1788077936"

    // Test Ad Unit IDs (use these during development)
    static let testBannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    static let testInterstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"

    // Set to false for production, true for testing
    #if DEBUG
    static let useTestAds = true
    #else
    static let useTestAds = false
    #endif

    static var currentBannerAdUnitID: String {
        useTestAds ? testBannerAdUnitID : bannerAdUnitID
    }

    static var currentInterstitialAdUnitID: String {
        useTestAds ? testInterstitialAdUnitID : interstitialAdUnitID
    }
}

// MARK: - AdMob Manager
@MainActor
class AdMobManager: NSObject, ObservableObject {
    static let shared = AdMobManager()

    @Published var isAdsInitialized = false

    // Interstitial Ad
    private var interstitialAd: GADInterstitialAd?
    private var isLoadingInterstitial = false

    // Frequency Control
    private let completionCountKey = "zip_adCompletionCount"
    private let showAdEveryNCompletions = 3

    private var completionCount: Int {
        get { UserDefaults.standard.integer(forKey: completionCountKey) }
        set { UserDefaults.standard.set(newValue, forKey: completionCountKey) }
    }

    override private init() {
        super.init()
    }

    nonisolated func initialize() {
        GADMobileAds.sharedInstance().start { status in
            print("AdMob SDK initialized")
            Task { @MainActor in
                self.isAdsInitialized = true
                self.loadInterstitialAd()
            }
        }
    }

    // MARK: - Interstitial Ad

    func loadInterstitialAd() {
        guard !isLoadingInterstitial else { return }
        isLoadingInterstitial = true

        let request = GADRequest()
        GADInterstitialAd.load(
            withAdUnitID: AdMobConfig.currentInterstitialAdUnitID,
            request: request
        ) { [weak self] ad, error in
            Task { @MainActor in
                self?.isLoadingInterstitial = false

                if let error = error {
                    print("Failed to load interstitial ad: \(error.localizedDescription)")
                    return
                }

                print("Interstitial ad loaded successfully")
                self?.interstitialAd = ad
                self?.interstitialAd?.fullScreenContentDelegate = self
            }
        }
    }

    /// Call this when a game is completed. Returns true if ad was shown.
    @discardableResult
    func onGameCompleted() -> Bool {
        // Check if user is premium
        if SubscriptionService.shared.isPremium {
            return false
        }

        completionCount += 1

        // Show ad every N completions
        if completionCount >= showAdEveryNCompletions {
            completionCount = 0
            return showInterstitialAd()
        }

        return false
    }

    private func showInterstitialAd() -> Bool {
        guard let interstitialAd = interstitialAd else {
            print("Interstitial ad not ready, loading new one")
            loadInterstitialAd()
            return false
        }

        guard let rootViewController = getRootViewController() else {
            print("Could not find root view controller")
            return false
        }

        interstitialAd.present(fromRootViewController: rootViewController)
        return true
    }

    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return nil
        }

        // Find the topmost presented view controller
        var topController = rootViewController
        while let presented = topController.presentedViewController {
            topController = presented
        }
        return topController
    }
}

// MARK: - GADFullScreenContentDelegate
extension AdMobManager: GADFullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Interstitial ad dismissed, loading next one")
        Task { @MainActor in
            self.interstitialAd = nil
            self.loadInterstitialAd()
        }
    }

    nonisolated func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Interstitial ad failed to present: \(error.localizedDescription)")
        Task { @MainActor in
            self.interstitialAd = nil
            self.loadInterstitialAd()
        }
    }

    nonisolated func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Interstitial ad will present")
    }
}

// MARK: - Banner Ad View (UIViewRepresentable)
struct BannerAdView: UIViewRepresentable {
    let adUnitID: String

    init(adUnitID: String = AdMobConfig.currentBannerAdUnitID) {
        self.adUnitID = adUnitID
    }

    func makeUIView(context: Context) -> GADBannerView {
        let bannerView = GADBannerView(adSize: GADAdSizeBanner)
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = getRootViewController()
        bannerView.delegate = context.coordinator
        bannerView.load(GADRequest())
        return bannerView
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return nil
        }
        return rootViewController
    }

    class Coordinator: NSObject, GADBannerViewDelegate {
        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            print("Banner ad loaded successfully")
        }

        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            print("Banner ad failed to load: \(error.localizedDescription)")
        }
    }
}

// MARK: - Adaptive Banner Ad View
struct AdaptiveBannerAdView: UIViewRepresentable {
    let adUnitID: String
    @Binding var adHeight: CGFloat

    init(adUnitID: String = AdMobConfig.currentBannerAdUnitID, adHeight: Binding<CGFloat> = .constant(50)) {
        self.adUnitID = adUnitID
        self._adHeight = adHeight
    }

    func makeUIView(context: Context) -> GADBannerView {
        let bannerView = GADBannerView()
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = getRootViewController()
        bannerView.delegate = context.coordinator

        // Get adaptive banner size
        let viewWidth = UIScreen.main.bounds.width
        bannerView.adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(viewWidth)

        bannerView.load(GADRequest())
        return bannerView
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(adHeight: $adHeight)
    }

    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return nil
        }
        return rootViewController
    }

    class Coordinator: NSObject, GADBannerViewDelegate {
        @Binding var adHeight: CGFloat

        init(adHeight: Binding<CGFloat>) {
            self._adHeight = adHeight
        }

        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            print("Adaptive banner ad loaded successfully")
            DispatchQueue.main.async {
                self.adHeight = bannerView.adSize.size.height
            }
        }

        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            print("Adaptive banner ad failed to load: \(error.localizedDescription)")
        }
    }
}

// MARK: - Banner Container View
struct BannerContainerView: View {
    @State private var adHeight: CGFloat = 50

    var body: some View {
        VStack(spacing: 0) {
            AdaptiveBannerAdView(adHeight: $adHeight)
                .frame(height: adHeight)
        }
        .frame(maxWidth: .infinity)
        .background(Color.zipTabBarBackground)
    }
}

#if DEBUG
// MARK: - Preview Helper
struct BannerAdView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            BannerContainerView()
        }
    }
}
#endif
