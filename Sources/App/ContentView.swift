import SwiftUI
import CodeReviewKit

struct ContentView: View {
    @Environment(AppViewModel.self) var appViewModel
    
    var body: some View {
        Group {
            if appViewModel.fileChanges.isEmpty {
                WelcomeView()
            } else {
                MainReviewView()
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}