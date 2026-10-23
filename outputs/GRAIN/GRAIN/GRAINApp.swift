import AVFoundation
import SwiftUI

@main
struct GRAINApp: App {
    @StateObject private var editor = EditorViewModel()
    @AppStorage("didPrimeInitialNetworkAccess") private var didPrimeInitialNetworkAccess = false

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(editor)
                .preferredColorScheme(.dark)
                .onAppear(perform: GrainHaptics.prepare)
                .task {
                    await primeInitialPermissionsAndNetwork()
                }
        }
    }

    private func primeInitialPermissionsAndNetwork() async {
        async let cameraPermission: Bool = requestInitialCameraAccess()
        let request = URLRequest(
            url: URL(string: "https://captive.apple.com/hotspot-detect.html")!,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: 6
        )
        if !didPrimeInitialNetworkAccess {
            didPrimeInitialNetworkAccess = true
            async let networkAccess: Void = primeNetworkAccess(request)
            _ = await (cameraPermission, networkAccess)
        } else {
            _ = await cameraPermission
        }
    }

    private func requestInitialCameraAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .video) {
                    continuation.resume(returning: $0)
                }
            }
        default:
            return false
        }
    }

    private func primeNetworkAccess(_ request: URLRequest) async {
        _ = try? await URLSession.shared.data(for: request)
    }
}
