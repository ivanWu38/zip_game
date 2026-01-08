import Foundation
import AppTrackingTransparency
import AdSupport

@MainActor
class ATTService: ObservableObject {
    static let shared = ATTService()

    private let defaults = UserDefaults.standard
    private let hasShownPromptKey = "zip_hasShownATTPrompt"

    @Published var shouldShowPrePrompt = false
    @Published var trackingStatus: ATTrackingManager.AuthorizationStatus = .notDetermined
    @Published var hasCompletedATTFlow = false  // True when user has made a decision

    private init() {
        updateTrackingStatus()
        // If user already made a choice (not .notDetermined), mark flow as completed
        if trackingStatus != .notDetermined {
            hasCompletedATTFlow = true
        }
    }

    // Check if we've already shown the prompt
    var hasShownPrompt: Bool {
        defaults.bool(forKey: hasShownPromptKey)
    }

    // Check if ATT prompt should be shown on app launch
    func checkAndShowPromptOnLaunch() {
        // Don't show if already shown
        guard !hasShownPrompt else {
            hasCompletedATTFlow = true
            return
        }

        // Don't show if already determined (user already made a choice via Settings)
        guard trackingStatus == .notDetermined else {
            hasCompletedATTFlow = true
            return
        }

        // Show the pre-prompt immediately on app launch
        shouldShowPrePrompt = true
    }

    // Called when user taps "Continue" on pre-prompt
    func requestTrackingPermission() async {
        // Mark as shown
        defaults.set(true, forKey: hasShownPromptKey)

        // Request permission
        let status = await ATTrackingManager.requestTrackingAuthorization()
        trackingStatus = status
        hasCompletedATTFlow = true
        shouldShowPrePrompt = false

        // Log result
        switch status {
        case .authorized:
            print("ATT: User authorized tracking")
        case .denied:
            print("ATT: User denied tracking")
        case .restricted:
            print("ATT: Tracking restricted")
        case .notDetermined:
            print("ATT: Not determined")
        @unknown default:
            print("ATT: Unknown status")
        }
    }

    // Called when user taps "Not Now" on pre-prompt
    func skipTracking() {
        // Mark as shown so we don't ask again
        defaults.set(true, forKey: hasShownPromptKey)
        shouldShowPrePrompt = false
        hasCompletedATTFlow = true
    }

    // Update current tracking status
    private func updateTrackingStatus() {
        trackingStatus = ATTrackingManager.trackingAuthorizationStatus
    }

    // Check if tracking is authorized
    var isTrackingAuthorized: Bool {
        trackingStatus == .authorized
    }
}
