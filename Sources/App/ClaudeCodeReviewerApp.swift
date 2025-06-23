import SwiftUI

@main
struct ClaudeCodeReviewerApp: App {
    @State private var appViewModel = AppViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appViewModel)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open Repository...") {
                    appViewModel.openRepository()
                }
                .keyboardShortcut("O", modifiers: .command)
            }
        }
    }
}