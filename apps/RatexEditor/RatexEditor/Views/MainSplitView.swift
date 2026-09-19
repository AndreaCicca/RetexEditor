import SwiftUI
import AppKit

public struct MainSplitView: View {
    @Bindable var workspace: WorkspaceModel
    @State private var state: EditorState
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    public init(workspace: WorkspaceModel) {
        self.workspace = workspace
        
        let initialURL = workspace.selectedFileURL ?? workspace.entryPointURL
        let initialSource: String
        if let url = initialURL, let content = try? String(contentsOf: url, encoding: .utf8) {
            initialSource = content
        } else {
            initialSource = TeXTemplate.article.source
        }
        
        let editorState = EditorState(
            source: initialSource,
            documentURL: initialURL,
            entryPointURL: workspace.entryPointURL
        )
        editorState.customProjectDirectory = workspace.rootDirectory
        self._state = State(initialValue: editorState)
    }
    
    public var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Native macOS Collapsible Sidebar
            ProjectSidebarView(workspace: workspace) { clickedURL in
                switchToFile(clickedURL)
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 320)
        } detail: {
            VStack(spacing: 0) {
                // Top WYSIWYG Toolbar
                WYSIWYGToolbar(
                    state: state,
                    workspace: workspace,
                    onToggleSidebar: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            columnVisibility = (columnVisibility == .detailOnly) ? .all : .detailOnly
                        }
                    }
                )
                
                Divider()
                
                // 2-Pane Split View: [Source Editor] | [PDF Preview]
                HSplitView {
                    // Center: LaTeX Source Editor
                    VStack(spacing: 0) {
                        HStack(spacing: 6) {
                            Image(systemName: activeFileIcon)
                                .foregroundStyle(.blue)
                                .font(.caption)
                            
                            Text(activeFileName)
                                .font(.system(size: 12, weight: .semibold))
                                .lineLimit(1)
                            
                            if isCurrentFileEntryPoint {
                                Text("Entry Point")
                                    .font(.system(size: 9, weight: .bold))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1.5)
                                    .background(Color.blue.opacity(0.2))
                                    .foregroundStyle(.blue)
                                    .cornerRadius(4)
                            } else if let entry = workspace.entryPointURL {
                                Text("(Building: \(entry.lastPathComponent))")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("\(state.source.count) chars")
                                .font(.system(size: 11))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                        
                        Divider()
                        
                        SourceEditorView(state: state)
                    }
                    .frame(minWidth: 320, maxWidth: .infinity)
                    
                    // Right: Live PDFKit Preview
                    VStack(spacing: 0) {
                        HStack(spacing: 8) {
                            Text("Live PDF Preview")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            // Zoom controls
                            ControlGroup {
                                Button(action: {
                                    if state.zoomScale <= 0 { state.zoomScale = 1.0 }
                                    state.zoomScale = max(0.5, state.zoomScale - 0.15)
                                }) {
                                    Image(systemName: "minus.magnifyingglass")
                                }
                                .help("Zoom Out")
                                
                                Button(action: { state.zoomScale = 1.0 }) {
                                    Text(state.zoomScale <= 0 ? "Fit" : "\(Int(state.zoomScale * 100))%")
                                        .font(.system(size: 10, weight: .medium))
                                }
                                .help("Reset Zoom (100%)")
                                
                                Button(action: {
                                    if state.zoomScale <= 0 { state.zoomScale = 1.0 }
                                    state.zoomScale = min(3.0, state.zoomScale + 0.15)
                                }) {
                                    Image(systemName: "plus.magnifyingglass")
                                }
                                .help("Zoom In")
                                
                                Button(action: {
                                    state.zoomScale = (state.zoomScale == 0 ? 1.0 : 0)
                                }) {
                                    Image(systemName: "arrow.left.and.right")
                                        .foregroundStyle(state.zoomScale == 0 ? Color.accentColor : Color.primary)
                                }
                                .help("Fit to Width")
                            }
                            
                            if state.pdfData != nil {
                                Button(action: exportPDF) {
                                    Label("Export…", systemImage: "arrow.down.doc")
                                        .font(.system(size: 11))
                                }
                                .buttonStyle(.borderless)
                                .help("Export Master PDF to Disk")
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                        
                        Divider()
                        
                        if let pdfData = state.pdfData {
                            PDFKitRepresentable(pdfData: pdfData, zoomScale: state.zoomScale)
                        } else if state.isCompiling {
                            VStack(spacing: 12) {
                                ProgressView()
                                Text("Compiling LaTeX document…")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.secondary)
                                Text("No Preview Available")
                                    .font(.headline)
                                Text("Check diagnostics for compilation issues.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Button("Show Diagnostics") {
                                    state.isDiagnosticsDrawerOpen = true
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .frame(minWidth: 360, maxWidth: .infinity)
                }
                
                // Bottom Drawer: Diagnostics & TeX Log
                if state.isDiagnosticsDrawerOpen {
                    DiagnosticsView(state: state)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        // Sync active changes to disk and workspace
        .onChange(of: state.source) { _, newValue in
            workspace.saveActiveFile(content: newValue)
        }
        .onChange(of: workspace.entryPointURL) { _, newEntry in
            state.entryPointURL = newEntry
            state.scheduleCompilation()
        }
        .onChange(of: workspace.selectedFileURL) { _, newSelected in
            if let newSelected = newSelected, newSelected != state.documentURL {
                switchToFile(newSelected)
            }
        }
        .onAppear {
            state.customProjectDirectory = workspace.rootDirectory
            state.entryPointURL = workspace.entryPointURL
            if let sel = workspace.selectedFileURL {
                switchToFile(sel)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .recompileRequested)) { _ in
            Task { @MainActor in
                await state.compileImmediate()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleSidebarRequested)) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                columnVisibility = (columnVisibility == .detailOnly) ? .all : .detailOnly
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleMathPaletteRequested)) { _ in
            state.isMathPaletteOpen.toggle()
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleDiagnosticsRequested)) { _ in
            state.isDiagnosticsDrawerOpen.toggle()
        }
        .onReceive(NotificationCenter.default.publisher(for: .formatBoldRequested)) { _ in
            state.applyBold()
        }
        .onReceive(NotificationCenter.default.publisher(for: .formatItalicRequested)) { _ in
            state.applyItalic()
        }
        .onReceive(NotificationCenter.default.publisher(for: .formatUnderlineRequested)) { _ in
            state.applyUnderline()
        }
        .onReceive(NotificationCenter.default.publisher(for: .formatCodeRequested)) { _ in
            state.applyCode()
        }
        .onReceive(NotificationCenter.default.publisher(for: .formatInlineMathRequested)) { _ in
            state.insertInlineMath()
        }
        .onReceive(NotificationCenter.default.publisher(for: .formatDisplayMathRequested)) { _ in
            state.insertDisplayMath()
        }
    }
    
    private var activeFileName: String {
        if let doc = state.documentURL {
            return workspace.relativePath(for: doc)
        }
        return "Untitled.tex"
    }
    
    private var activeFileIcon: String {
        let ext = state.documentURL?.pathExtension.lowercased() ?? "tex"
        switch ext {
        case "cls", "sty": return "gearshape.fill"
        case "bib": return "books.vertical.fill"
        default: return "doc.text.fill"
        }
    }
    
    private var isCurrentFileEntryPoint: Bool {
        guard let doc = state.documentURL, let entry = workspace.entryPointURL else { return false }
        return doc.standardizedFileURL == entry.standardizedFileURL
    }
    
    private func switchToFile(_ newURL: URL) {
        // 1. Flush changes in current editor buffer to disk
        if let currentURL = state.documentURL {
            workspace.flushSaveNow(content: state.source, for: currentURL)
        }
        
        // 2. Load the content of the clicked file
        guard let newContent = try? String(contentsOf: newURL, encoding: .utf8) else {
            return
        }
        
        workspace.selectedFileURL = newURL
        state.documentURL = newURL
        state.source = newContent
        state.entryPointURL = workspace.entryPointURL
        state.customProjectDirectory = workspace.rootDirectory
        state.scheduleCompilation()
    }
    
    private func exportPDF() {
        guard let data = state.pdfData else { return }
        let panel = NSSavePanel()
        panel.title = "Export Compiled PDF"
        panel.allowedContentTypes = [.pdf]
        let baseName = workspace.entryPointURL?.deletingPathExtension().lastPathComponent ?? "document"
        panel.nameFieldStringValue = "\(baseName).pdf"
        
        if panel.runModal() == .OK, let url = panel.url {
            try? data.write(to: url)
        }
    }
}
