import SwiftUI
import CodeReviewKit

struct WelcomeView: View {
    @Environment(AppViewModel.self) var appViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "git.branch")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 10) {
                Text("Claude Code Reviewer")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Select a Git repository to review unstaged changes")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if appViewModel.isLoading {
                ProgressView("Loading repository...")
                    .padding()
            } else {
                Button(action: {
                    appViewModel.openRepository()
                }) {
                    HStack {
                        Image(systemName: "folder.badge.plus")
                        Text("Open Repository")
                    }
                    .font(.title3)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            
            if let errorMessage = appViewModel.errorMessage {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("Error")
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                        Spacer()
                    }
                    
                    Text(errorMessage)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if errorMessage.contains("not a Git repository") {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("💡 Tips:")
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            Text("• Make sure you're selecting the root folder of a Git repository")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("• Look for a folder that contains a '.git' subfolder")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else if errorMessage.contains("No unstaged changes") {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("💡 Next steps:")
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            Text("• Make changes to files in your repository")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("• Save your files to see the changes appear here")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Button("Try Again") {
                        appViewModel.openRepository()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(16)
                .background(Color.red.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.2), lineWidth: 1)
                )
                .cornerRadius(12)
            }
            
            VStack(spacing: 8) {
                Text("Make sure you have unsaved changes in your repository")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Modify files in your repository to see changes for review")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    WelcomeView()
        .environment(AppViewModel())
}