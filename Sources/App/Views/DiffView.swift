import SwiftUI
import CodeReviewKit

struct DiffView: View {
    let fileChange: FileChange
    @Environment(AppViewModel.self) var appViewModel
    @State private var diffViewModel = DiffViewModel()
    @State private var showingCommentPopover = false
    @State private var selectedLineForComment: Int?
    @State private var newCommentText = ""
    @State private var commentEndLine: Int?
    @State private var showingInlineComment = false
    @State private var inlineCommentLineNumber: Int?
    @State private var inlineCommentText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // File header
            fileHeader
            
            Divider()
            
            // Diff content
            if diffViewModel.splitDiffLines.isEmpty {
                emptyDiffView
            } else {
                diffContentView
            }
        }
        .onAppear {
            diffViewModel.fileChange = fileChange
            diffViewModel.parseDiff()
        }
        .onChange(of: fileChange) { _, newFileChange in
            diffViewModel.fileChange = newFileChange
            diffViewModel.parseDiff()
        }
    }
    
    private var fileHeader: some View {
        HStack(spacing: 12) {
            // File status icon
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(fileName)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(fileChange.filePath)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Comment count
            if commentCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left")
                        .font(.caption)
                    Text("\(commentCount)")
                        .font(.caption)
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var emptyDiffView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No diff available")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("This file has no readable diff content")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var diffContentView: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0, pinnedViews: []) {
                ForEach(Array(diffViewModel.splitDiffLines.enumerated()), id: \.offset) { index, splitLine in
                    DiffLineView(
                        splitLine: splitLine,
                        comments: commentsForLine(splitLine),
                        onAddComment: { lineNumber in
                            selectedLineForComment = lineNumber
                            showingCommentPopover = true
                        },
                        onAddInlineComment: { lineNumber in
                            inlineCommentLineNumber = lineNumber
                            showingInlineComment = true
                        },
                        showingInlineComment: showingInlineComment && inlineCommentLineNumber == getLineNumber(for: splitLine),
                        inlineCommentText: $inlineCommentText,
                        onSaveInlineComment: addInlineComment,
                        onCancelInlineComment: cancelInlineComment
                    )
                }
            }
        }
        .background(Color(NSColor.textBackgroundColor))
        .popover(isPresented: $showingCommentPopover) {
            commentPopoverView
        }
    }
    
    private var commentPopoverView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Add Comment")
                    .font(.headline)
                Spacer()
                Button("Cancel") {
                    showingCommentPopover = false
                    resetCommentForm()
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("End Line (Optional)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    TextField("End line number", value: $commentEndLine, format: .number)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Clear") {
                        commentEndLine = nil
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Comment")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $newCommentText)
                    .frame(minHeight: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            }
            
            HStack {
                Spacer()
                Button("Add Comment") {
                    addComment()
                }
                .disabled(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 300)
    }
    
    // MARK: - Helper Properties
    
    private var fileName: String {
        URL(fileURLWithPath: fileChange.filePath).lastPathComponent
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
    
    // MARK: - Helper Methods
    
    private func commentsForLine(_ splitLine: DiffViewModel.SplitDiffLine) -> [ReviewComment] {
        let lineNumber = splitLine.rightLine?.newLineNumber ?? splitLine.leftLine?.oldLineNumber ?? 0
        return appViewModel.comments.filter { $0.filePath == fileChange.filePath && $0.startLine == lineNumber }
    }
    
    private func addComment() {
        guard let lineNumber = selectedLineForComment,
              !newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let comment = ReviewComment(
            filePath: fileChange.filePath,
            startLine: lineNumber,
            endLine: commentEndLine,
            text: newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        appViewModel.addComment(comment)
        showingCommentPopover = false
        resetCommentForm()
    }
    
    private func resetCommentForm() {
        selectedLineForComment = nil
        newCommentText = ""
        commentEndLine = nil
    }
    
    private func getLineNumber(for splitLine: DiffViewModel.SplitDiffLine) -> Int {
        return splitLine.rightLine?.newLineNumber ?? splitLine.leftLine?.oldLineNumber ?? 0
    }
    
    private func addInlineComment() {
        guard let lineNumber = inlineCommentLineNumber,
              !inlineCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let comment = ReviewComment(
            filePath: fileChange.filePath,
            startLine: lineNumber,
            endLine: nil,
            text: inlineCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        appViewModel.addComment(comment)
        cancelInlineComment()
    }
    
    private func cancelInlineComment() {
        showingInlineComment = false
        inlineCommentLineNumber = nil
        inlineCommentText = ""
    }
    
}

struct DiffLineView: View {
    let splitLine: DiffViewModel.SplitDiffLine
    let comments: [ReviewComment]
    let onAddComment: (Int) -> Void
    let onAddInlineComment: (Int) -> Void
    let showingInlineComment: Bool
    @Binding var inlineCommentText: String
    let onSaveInlineComment: () -> Void
    let onCancelInlineComment: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main diff line
            HStack(spacing: 0) {
                // Left side (old) - no interactions
                DiffSideView(
                    diffLine: splitLine.leftLine,
                    side: .left,
                    onAddComment: onAddComment,
                    onAddInlineComment: onAddInlineComment,
                    isHovering: false,
                    isInteractive: false
                )
                
                // Divider
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 1)
                
                // Right side (new) - interactive
                DiffSideView(
                    diffLine: splitLine.rightLine,
                    side: .right,
                    onAddComment: onAddComment,
                    onAddInlineComment: onAddInlineComment,
                    isHovering: isHovering,
                    isInteractive: true
                )
                .contentShape(Rectangle())
                .onHover { hovering in
                    isHovering = hovering
                }
            }
            
            // Comments for this line
            if !comments.isEmpty {
                VStack(spacing: 4) {
                    ForEach(comments, id: \.id) { comment in
                        CommentView(comment: comment)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.05))
            }
            
            // Inline comment input
            if showingInlineComment {
                InlineCommentView(
                    commentText: $inlineCommentText,
                    onSave: onSaveInlineComment,
                    onCancel: onCancelInlineComment
                )
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(Color.yellow.opacity(0.1))
            }
        }
    }
}

struct DiffSideView: View {
    let diffLine: DiffLine?
    let side: Side
    let onAddComment: (Int) -> Void
    let onAddInlineComment: (Int) -> Void
    let isHovering: Bool
    let isInteractive: Bool
    
    enum Side {
        case left, right
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Line number
            if let diffLine = diffLine {
                let lineNumber = side == .left ? diffLine.oldLineNumber : diffLine.newLineNumber
                if let lineNumber = lineNumber {
                    ZStack {
                        if isInteractive {
                            Button(action: {
                                onAddComment(lineNumber)
                            }) {
                                Text("\(lineNumber)")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .frame(minWidth: 40, alignment: .trailing)
                            }
                            .buttonStyle(.plain)
                            .help("Click to add comment")
                            
                            // [+] button overlay
                            if isHovering {
                                Button(action: {
                                    onAddInlineComment(lineNumber)
                                }) {
                                    Text("[+]")
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 2)
                                        .background(Color.blue)
                                        .cornerRadius(2)
                                }
                                .buttonStyle(.plain)
                                .help("Add inline comment")
                            }
                        } else {
                            // Non-interactive line number (left side)
                            Text("\(lineNumber)")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(minWidth: 40, alignment: .trailing)
                        }
                    }
                    .frame(minWidth: 40, alignment: .trailing)
                } else {
                    Text("")
                        .frame(minWidth: 40)
                }
            } else {
                Text("")
                    .frame(minWidth: 40)
            }
            
            // Line content
            if let diffLine = diffLine {
                HStack(spacing: 0) {
                    Text(diffLine.content)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(textColor(for: diffLine.type))
                        .lineLimit(1)
                    
                    Spacer(minLength: 0)
                }
            } else {
                Spacer()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(backgroundColor(for: diffLine?.type))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func backgroundColor(for type: DiffLine.LineType?) -> Color {
        guard let type = type else { return Color.clear }
        
        switch type {
        case .added:
            return Color.green.opacity(0.15)
        case .removed:
            return Color.red.opacity(0.15)
        case .hunkHeader:
            return Color.blue.opacity(0.1)
        case .context:
            return Color.clear
        }
    }
    
    private func textColor(for type: DiffLine.LineType) -> Color {
        switch type {
        case .added:
            return Color.green
        case .removed:
            return Color.red
        case .hunkHeader:
            return Color.blue
        case .context:
            return Color.primary
        }
    }
}

struct CommentView: View {
    let comment: ReviewComment
    @Environment(AppViewModel.self) var appViewModel
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "bubble.left")
                .foregroundColor(.blue)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Line \(comment.startLine)\(comment.endLine.map { "-\($0)" } ?? "")")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Button(action: {
                        appViewModel.deleteComment(comment)
                    }) {
                        Image(systemName: "trash")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .help("Delete comment")
                }
                
                Text(comment.text)
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.8))
        .cornerRadius(6)
    }
}

struct InlineCommentView: View {
    @Binding var commentText: String
    let onSave: () -> Void
    let onCancel: () -> Void
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Add comment")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            HStack(spacing: 8) {
                TextField("Enter your comment...", text: $commentText, axis: .vertical)
                    .lineLimit(1...3)
                    .textFieldStyle(.roundedBorder)
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        if !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            onSave()
                        }
                    }
                
                VStack(spacing: 4) {
                    Button("Save") {
                        onSave()
                    }
                    .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .keyboardShortcut(.return, modifiers: [.command])
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    
                    Button("Cancel") {
                        onCancel()
                    }
                    .keyboardShortcut(.escape)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
}

#Preview {
    DiffView(fileChange: FileChange(
        filePath: "src/main.swift",
        status: .modified,
        diffContent: """
        @@ -1,3 +1,4 @@
         func main() {
        -    print("Hello")
        +    print("Hello, World!")
        +    return 0
         }
        """
    ))
    .environment(AppViewModel())
    .frame(width: 800, height: 600)
}