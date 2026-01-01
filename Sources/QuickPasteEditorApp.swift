import SwiftUI

@main
struct QuickPasteEditorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 400, minHeight: 300)
                .onAppear {
                    appDelegate.setMainWindowIfNeeded(NSApplication.shared.windows.first)
                }
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
    }
}
