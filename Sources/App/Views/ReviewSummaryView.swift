import SwiftUI
import CodeReviewKit

struct ReviewSummaryView: View {
    @Environment(AppViewModel.self) var appViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var reviewPrompt = ""
    @State private var copied = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                Divider()
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Summary stats
                        summaryStatsView
                        
                        Divider()
                        
                        // Generated prompt
                        promptView
                    }
                    .padding()
                }
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .onAppear {
            reviewPrompt = appViewModel.generateReviewPrompt()
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Review Summary")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if let repoPath = appViewModel.repositoryPath {
                    Text(URL(fileURLWithPath: repoPath).lastPathComponent)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: {
                    appViewModel.copyReviewPrompt()
                    copied = true
                    
                    // Reset copied state after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        copied = false
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: copied ? "checkmark" : "doc.on.clipboard")
                            .foregroundColor(copied ? .green : .primary)
                        Text(copied ? "Copied!" : "Copy to Clipboard")
                    }
                }
                .disabled(reviewPrompt.isEmpty)
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var summaryStatsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Changes Overview")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    title: "Files Changed",
                    value: "\(appViewModel.fileChanges.count)",
                    icon: "doc.text",
                    color: .blue
                )
                
                StatCard(
                    title: "Comments",
                    value: "\(appViewModel.comments.count)",
                    icon: "bubble.left",
                    color: .orange
                )
                
                StatCard(
                    title: "Issues",
                    value: "\(criticalCommentCount)",
                    icon: "exclamationmark.triangle",
                    color: criticalCommentCount > 0 ? .red : .green
                )
            }
            
            // File breakdown
            if !appViewModel.fileChanges.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("File Breakdown")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(statusCounts.sorted(by: { $0.key.rawValue < $1.key.rawValue }), id: \.key) { status, count in
                        HStack {
                            Image(systemName: statusIcon(for: status))
                                .foregroundColor(statusColor(for: status))
                                .frame(width: 16)
                            
                            Text(status.rawValue.capitalized)
                                .font(.caption)
                            
                            Spacer()
                            
                            Text("\(count)")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
        }
    }
    
    private var promptView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Generated Review Prompt")
                    .font(.headline)
                
                Spacer()
                
                Text("\(reviewPrompt.count) characters")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("Copy this prompt and paste it into Claude or your preferred AI assistant:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ScrollView {
                Text(reviewPrompt)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(NSColor.textBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            }
            .frame(minHeight: 200)
        }
    }
    
    // MARK: - Helper Properties
    
    private var criticalCommentCount: Int {
        // Since severity is removed, we'll just count all comments
        appViewModel.comments.count
    }
    
    private var statusCounts: [FileChange.GitStatus: Int] {
        Dictionary(grouping: appViewModel.fileChanges, by: \.status)
            .mapValues { $0.count }
    }
    
    // MARK: - Helper Methods
    
    private func statusIcon(for status: FileChange.GitStatus) -> String {
        switch status {
        case .added:
            return "plus.circle.fill"
        case .modified:
            return "pencil.circle.fill"
        case .deleted:
            return "minus.circle.fill"
        case .renamed:
            return "arrow.right.circle.fill"
        case .copied:
            return "doc.on.doc.fill"
        default:
            return "questionmark.circle.fill"
        }
    }
    
    private func statusColor(for status: FileChange.GitStatus) -> Color {
        switch status {
        case .added:
            return .green
        case .modified:
            return .orange
        case .deleted:
            return .red
        case .renamed:
            return .blue
        case .copied:
            return .purple
        default:
            return .gray
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    ReviewSummaryView()
        .environment({
            let vm = AppViewModel()
            vm.fileChanges = [
                FileChange(filePath: "src/main.swift", status: .modified),
                FileChange(filePath: "tests/test.swift", status: .added),
                FileChange(filePath: "docs/old.md", status: .deleted)
            ]
            vm.comments = [
                ReviewComment(filePath: "src/main.swift", startLine: 10, text: "This could be improved"),
                ReviewComment(filePath: "src/main.swift", startLine: 20, text: "Potential bug here")
            ]
            return vm
        }())
}