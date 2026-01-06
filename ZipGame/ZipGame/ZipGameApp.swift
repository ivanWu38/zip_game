import SwiftUI
import GoogleMobileAds

@main
struct ZipGameApp: App {
    init() {
        // Initialize Google Mobile Ads SDK
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}
