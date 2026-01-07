import Foundation
import AppTrackingTransparency
import AdSupport

@MainActor
class ATTService: ObservableObject {
    static let shared = ATTService()

    private let defaults = UserDefaults.standard
    private let hasShownPromptKey = "zip_hasShownATTPrompt"
    private let hasCompletedFirstPuzzleKey = "zip_hasCompletedFirstPuzzle"

    @Published var shouldShowPrePrompt = false
    @Published var trackingStatus: ATTrackingManager.AuthorizationStatus = .notDetermined

    private init() {
        updateTrackingStatus()
    }

    // Check if we've already shown the prompt
    var hasShownPrompt: Bool {
        defaults.bool(forKey: hasShownPromptKey)
    }

    // Check if user has completed first puzzle
    var hasCompletedFirstPuzzle: Bool {
        defaults.bool(forKey: hasCompletedFirstPuzzleKey)
    }

    // Mark that user has completed their first puzzle
    func markFirstPuzzleCompleted() {
        defaults.set(true, forKey: hasCompletedFirstPuzzleKey)

        // Check if we should show the ATT prompt
        checkAndShowPromptIfNeeded()
    }

    // Check conditions and show pre-prompt if needed
    func checkAndShowPromptIfNeeded() {
        // Don't show if already shown
        guard !hasShownPrompt else { return }

        // Don't show if user hasn't completed first puzzle yet
        guard hasCompletedFirstPuzzle else { return }

        // Don't show if already determined (user already made a choice via Settings)
        guard trackingStatus == .notDetermined else { return }

        // Show the pre-prompt
        shouldShowPrePrompt = true
    }

    // Called when user taps "Continue" on pre-prompt
    func requestTrackingPermission() async {
        // Mark as shown
        defaults.set(true, forKey: hasShownPromptKey)

        // Request permission
        let status = await ATTrackingManager.requestTrackingAuthorization()
        trackingStatus = status

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
