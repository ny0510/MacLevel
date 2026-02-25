import SwiftUI

@main
struct MacLevelApp: App {
    @StateObject private var motionManager = MotionManager()
    
    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(motionManager)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: motionManager.isLevel ? "scope" : "circle.dotted")
                Text(String(format: "%.1f°", max(abs(motionManager.roll), abs(motionManager.pitch))))
            }
        }
        .menuBarExtraStyle(.window)
    }
}
