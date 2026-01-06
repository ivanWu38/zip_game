import SwiftUI
import GoogleMobileAds

// MARK: - AdMob Configuration
struct AdMobConfig {
    // Production Ad Unit ID
    static let bannerAdUnitID = "ca-app-pub-5654617376526903/5513143481"

    // Test Ad Unit ID (use this during development)
    static let testBannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"

    // Set to false for production, true for testing
    #if DEBUG
    static let useTestAds = true
    #else
    static let useTestAds = false
    #endif

    static var currentBannerAdUnitID: String {
        useTestAds ? testBannerAdUnitID : bannerAdUnitID
    }
}

// MARK: - AdMob Manager
class AdMobManager: ObservableObject {
    static let shared = AdMobManager()

    @Published var isAdsInitialized = false

    private init() {}

    func initialize() {
        GADMobileAds.sharedInstance().start { [weak self] status in
            print("AdMob SDK initialized")
            DispatchQueue.main.async {
                self?.isAdsInitialized = true
            }
        }
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
