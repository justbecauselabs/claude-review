import SwiftUI
import CodeReviewKit

struct MainReviewView: View {
    @Environment(AppViewModel.self) var appViewModel
    @State private var showingReviewSummary = false
    
    var body: some View {
        HSplitView {
            // Left sidebar - File list
            FileListView()
                .frame(minWidth: 250, idealWidth: 300, maxWidth: 400)
            
            // Right side - Diff view
            if let selectedFile = appViewModel.selectedFileChange {
                DiffView(fileChange: selectedFile)
                    .frame(minWidth: 500)
            } else {
                // No file selected placeholder
                VStack(spacing: 20) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("Select a file to review")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("Choose a file from the list to view its changes")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: {
                    Task {
                        await appViewModel.refreshRepository()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh repository")
                
                Button(action: {
                    showingReviewSummary = true
                }) {
                    HStack {
                        Image(systemName: "doc.text")
                        Text("Generate Review")
                    }
                }
                .disabled(appViewModel.fileChanges.isEmpty)
                .help("Generate review prompt for Claude")
            }
            
            ToolbarItem(placement: .navigation) {
                Button(action: {
                    appViewModel.repositoryPath = nil
                    appViewModel.fileChanges = []
                    appViewModel.selectedFileChange = nil
                    appViewModel.comments = []
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .help("Back to welcome screen")
            }
        }
        .sheet(isPresented: $showingReviewSummary) {
            ReviewSummaryView()
        }
        .onAppear {
            // Select first file if none selected
            if appViewModel.selectedFileChange == nil && !appViewModel.fileChanges.isEmpty {
                appViewModel.selectFileChange(appViewModel.fileChanges.first)
            }
        }
    }
}

#Preview {
    @Previewable @State var vm = {
        let vm = AppViewModel()
        // Add some mock data for preview
        vm.fileChanges = [
            FileChange(filePath: "src/main.swift", status: .modified, diffContent: "mock diff"),
            FileChange(filePath: "tests/test.swift", status: .added, diffContent: "mock diff")
        ]
        return vm
    }()
    
    MainReviewView()
        .environment(vm)
}