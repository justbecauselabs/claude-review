import SwiftUI
import CodeReviewKit

struct FileListView: View {
    @Environment(AppViewModel.self) var appViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Files")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(appViewModel.fileChanges.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // File list
            if appViewModel.fileChanges.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 30))
                        .foregroundColor(.secondary)
                    
                    Text("No unstaged changes")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Modify files in your repository to review them")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(appViewModel.fileChanges, id: \.id, selection: Binding(
                    get: { appViewModel.selectedFileChange },
                    set: { appViewModel.selectFileChange($0) }
                )) { fileChange in
                    FileRowView(fileChange: fileChange)
                        .tag(fileChange)
                }
                .listStyle(SidebarListStyle())
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct FileRowView: View {
    let fileChange: FileChange
    @Environment(AppViewModel.self) var appViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .font(.system(size: 12, weight: .medium))
                .frame(width: 16)
            
            // File path
            VStack(alignment: .leading, spacing: 2) {
                Text(fileName)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                
                if !directoryPath.isEmpty {
                    Text(directoryPath)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Comment count badge
            if commentCount > 0 {
                Text("\(commentCount)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
    
    private var fileName: String {
        URL(fileURLWithPath: fileChange.filePath).lastPathComponent
    }
    
    private var directoryPath: String {
        let url = URL(fileURLWithPath: fileChange.filePath)
        let directory = url.deletingLastPathComponent().path
        return directory == "/" ? "" : directory
    }
    
    private var statusIcon: String {
        switch fileChange.status {
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
    
    private var statusColor: Color {
        switch fileChange.status {
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
    
    private var commentCount: Int {
        appViewModel.comments.filter { $0.filePath == fileChange.filePath }.count
    }
}

#Preview {
    FileListView()
        .environment({
            let vm = AppViewModel()
            vm.fileChanges = [
                FileChange(filePath: "src/main.swift", status: .modified),
                FileChange(filePath: "tests/test.swift", status: .added),
                FileChange(filePath: "docs/README.md", status: .deleted)
            ]
            return vm
        }())
        .frame(width: 300, height: 400)
}