import SwiftUI
import AppKit
import UniformTypeIdentifiers

public struct MainSplitView: View {
    @Bindable var workspace: WorkspaceModel
    @State private var state: EditorState
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @AppStorage("editor_preview_split_ratio") private var splitRatio: Double = 0.5
    @State private var isHoveringDivider = false
    @State private var isDraggingDivider = false
    @State private var dragStartRatio: CGFloat? = nil
    
    @AppStorage("diagnostics_drawer_height") private var drawerHeight: Double = 240
    @State private var isHoveringDrawerDivider = false
    @State private var isDraggingDrawerDivider = false
    @State private var dragStartDrawerHeight: CGFloat? = nil
    
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
            ProjectSidebarView(workspace: workspace) { clickedURL in
                switchToFile(clickedURL)
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 320)
        } detail: {
            GeometryReader { windowGeo in
                let isSidebarOpen: Bool = {
                    if columnVisibility == .detailOnly { return false }
                    if let window = NSApp.windows.first(where: { $0.isVisible }) ?? NSApp.keyWindow {
                        return (window.frame.width - windowGeo.size.width) >= 150
                    }
                    return columnVisibility != .detailOnly
                }()
                
                VStack(spacing: 0) {
                    EditorToolbar(
                        state: state,
                        workspace: workspace,
                        isSidebarOpen: isSidebarOpen,
                        availableWidth: windowGeo.size.width
                    )
                    
                    Divider()
                    
                    splitPanes
                    
                    if state.isDiagnosticsDrawerOpen {
                        VerticalResizeDividerHandle(
                            isHovering: $isHoveringDrawerDivider,
                            isDragging: $isDraggingDrawerDivider,
                            onDragChanged: { deltaY in
                                let start = dragStartDrawerHeight ?? CGFloat(drawerHeight)
                                if dragStartDrawerHeight == nil {
                                    dragStartDrawerHeight = start
                                }
                                let newHeight = start - deltaY
                                let maxDrawer = max(140, windowGeo.size.height - 180)
                                drawerHeight = Double(min(max(newHeight, 110), maxDrawer))
                            },
                            onDragEnded: {
                                dragStartDrawerHeight = nil
                            },
                            onResetHeight: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    drawerHeight = 240
                                }
                            }
                        )
                        .frame(height: 12)
                        
                        DiagnosticsView(
                            state: state,
                            drawerHeight: $drawerHeight,
                            maxDrawerHeight: max(140, windowGeo.size.height - 180)
                        )
                        .frame(height: CGFloat(drawerHeight))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .frame(width: windowGeo.size.width, height: windowGeo.size.height)
            }
        }
        .navigationSplitViewStyle(.balanced)
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
        .modifier(EditorNotificationsModifier(
            state: state
        ))
    }
    
    // MARK: - Split Panes
    
    private var splitPanes: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let dividerWidth: CGFloat = 16
            let availableWidth = max(0, totalWidth - dividerWidth)
            let minEditor: CGFloat = 300
            let minPreview: CGFloat = 320
            
            let safeRatio: CGFloat = {
                guard availableWidth > (minEditor + minPreview) else { return 0.5 }
                let minRatio = minEditor / availableWidth
                let maxRatio = 1.0 - (minPreview / availableWidth)
                return min(max(CGFloat(splitRatio), minRatio), maxRatio)
            }()
            
            let editorWidth: CGFloat = {
                guard availableWidth > (minEditor + minPreview) else {
                    return availableWidth / 2
                }
                return availableWidth * safeRatio
            }()
            
            let previewWidth: CGFloat = {
                guard availableWidth > (minEditor + minPreview) else {
                    return availableWidth / 2
                }
                return availableWidth - editorWidth
            }()
            
            HStack(spacing: 0) {
                editorPane
                    .frame(width: editorWidth)
                    .clipped()
                
                ResizeDividerHandle(
                    isHovering: $isHoveringDivider,
                    isDragging: $isDraggingDivider,
                    onDragChanged: { deltaX in
                        guard availableWidth > (minEditor + minPreview) else { return }
                        let start = dragStartRatio ?? safeRatio
                        if dragStartRatio == nil {
                            dragStartRatio = start
                        }
                        let deltaRatio = deltaX / availableWidth
                        let newRatio = start + deltaRatio
                        let minRatio = minEditor / availableWidth
                        let maxRatio = 1.0 - (minPreview / availableWidth)
                        splitRatio = Double(min(max(newRatio, minRatio), maxRatio))
                    },
                    onDragEnded: {
                        dragStartRatio = nil
                    },
                    onResetSplit: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            splitRatio = 0.5
                        }
                    }
                )
                .frame(width: dividerWidth)
                
                previewPane
                    .frame(width: previewWidth)
                    .clipped()
            }
            .frame(width: totalWidth, height: geometry.size.height)
        }
    }
    
    // MARK: - Editor Pane
    
    private var editorPane: some View {
        VStack(spacing: 0) {
            editorSubheader
            Divider()
            SourceEditorView(state: state)
        }
    }
    
    private var editorSubheader: some View {
        HStack(spacing: 8) {
            Image(systemName: activeFileIcon)
                .foregroundStyle(.blue)
                .font(.caption)
            
            Text(activeFileName)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
            
            if isCurrentFileEntryPoint {
                Text(workspace.entryPointURL == nil ? String(localized: "Active Document") : String(localized: "Entry Point"))
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .foregroundStyle(.blue)
                    .glassEffect(.regular, in: .capsule)
            } else {
                if let entry = workspace.entryPointURL {
                    Text(String.localizedStringWithFormat(NSLocalizedString("(Building: %@)", comment: ""), entry.lastPathComponent))
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                
                if let doc = state.documentURL, ["tex", "ltx"].contains(doc.pathExtension.lowercased()) {
                    Button(action: {
                        setAsCurrentEntryPoint()
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "play.circle.fill")
                            Text("Compile This File")
                        }
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.blue)
                    }
                    .buttonStyle(.glass)
                    .controlSize(.mini)
                    .help("Set this file as project entry point and compile it")
                }
            }
            
            Spacer()
            
            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 8) {
                    // Font Size Stepper
                    HStack(spacing: 4) {
                        Button(action: { state.decreaseFontSize() }) {
                            Image(systemName: "minus")
                                .font(.system(size: 9, weight: .semibold))
                                .padding(4)
                        }
                        .buttonStyle(.plain)
                        .help("Decrease Font Size (⌘-)")
                        
                        Text(String(format: "%.1f pt", state.editorFontSize))
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .frame(minWidth: 44, alignment: .center)
                        
                        Button(action: { state.increaseFontSize() }) {
                            Image(systemName: "plus")
                                .font(.system(size: 9, weight: .semibold))
                                .padding(4)
                        }
                        .buttonStyle(.plain)
                        .help("Increase Font Size (⌘+)")
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .glassEffect(.regular, in: .rect(cornerRadius: 6))
                    
                    Button(action: { reloadCurrentFileFromDisk() }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 9, weight: .semibold))
                            .padding(4)
                    }
                    .buttonStyle(.glass)
                    .help("Reload active file from disk")
                }
            }
            
            Text("•")
                .font(.system(size: 10))
                .foregroundStyle(.quaternary)
            
            Text("\(state.source.count) chars")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(.bar)
    }
    
    // MARK: - Preview Pane
    
    private var previewPane: some View {
        VStack(spacing: 0) {
            previewSubheader
            Divider()
            previewContent
        }
    }
    
    private var previewSubheader: some View {
        HStack(spacing: 8) {
            Text("Live PDF Preview")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 8) {
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
                    .controlSize(.small)
                    
                    if let pdfData = state.pdfData {
                        ShareLink(
                            item: DocumentPDFExport(
                                data: pdfData,
                                title: (workspace.entryPointURL ?? state.documentURL)?.deletingPathExtension().lastPathComponent ?? "document"
                            ),
                            preview: SharePreview(
                                (workspace.entryPointURL ?? state.documentURL)?.deletingPathExtension().lastPathComponent ?? "document",
                                image: Image(systemName: "doc.text.fill")
                            )
                        ) {
                            Label("Share…", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.glass)
                        .controlSize(.small)
                        .help("Share Compiled PDF via AirDrop, Mail, Messages…")
                        
                        Button(action: exportPDF) {
                            Label("Export…", systemImage: "arrow.down.doc")
                        }
                        .buttonStyle(.glassProminent)
                        .controlSize(.small)
                        .help("Export Master PDF to Disk")
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(.bar)
    }
    
    @ViewBuilder
    private var previewContent: some View {
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
    
    // MARK: - Helpers
    
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
        guard let doc = state.documentURL else { return false }
        guard let entry = workspace.entryPointURL else { return true }
        return doc.standardizedFileURL == entry.standardizedFileURL
    }
    
    private func setAsCurrentEntryPoint() {
        guard let doc = state.documentURL else { return }
        workspace.entryPointURL = doc
        state.entryPointURL = doc
        state.scheduleCompilation()
    }
    
    private func reloadCurrentFileFromDisk() {
        guard let currentURL = state.documentURL else { return }
        switchToFile(currentURL, forceReload: true)
    }
    
    private func switchToFile(_ newURL: URL, forceReload: Bool = false) {
        if !forceReload, let currentURL = state.documentURL, currentURL != newURL {
            workspace.flushSaveNow(content: state.source, for: currentURL)
        }
        
        guard let newContent = try? String(contentsOf: newURL, encoding: .utf8) else {
            return
        }
        
        workspace.selectedFileURL = newURL
        state.documentURL = newURL
        state.source = newContent
        
        // If entrypoint points to an invalid path, reset to active document mode
        if let entry = workspace.entryPointURL, !FileManager.default.fileExists(atPath: entry.path) {
            workspace.entryPointURL = nil
        }
        
        state.entryPointURL = workspace.entryPointURL
        state.customProjectDirectory = workspace.rootDirectory
        state.scheduleCompilation()
    }
    
    private func exportPDF() {
        guard let data = state.pdfData else { return }
        let panel = NSSavePanel()
        panel.title = String(localized: "Export Compiled PDF")
        panel.allowedContentTypes = [.pdf]
        let baseName = (workspace.entryPointURL ?? state.documentURL)?.deletingPathExtension().lastPathComponent ?? "document"
        panel.nameFieldStringValue = "\(baseName).pdf"
        
        if panel.runModal() == .OK, let url = panel.url {
            try? data.write(to: url)
        }
    }
}

// MARK: - Dedicated Notification Handler ViewModifier

private struct EditorNotificationsModifier: ViewModifier {
    @Bindable var state: EditorState
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .recompileRequested)) { _ in
                Task { @MainActor in
                    await state.compileImmediate()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .toggleSidebarRequested)) { _ in
                NSApp.sendAction(#selector(NSSplitViewController.toggleSidebar(_:)), to: nil, from: nil)
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
            .onReceive(NotificationCenter.default.publisher(for: .zoomInTextRequested)) { _ in
                state.increaseFontSize()
            }
            .onReceive(NotificationCenter.default.publisher(for: .zoomOutTextRequested)) { _ in
                state.decreaseFontSize()
            }
            .onReceive(NotificationCenter.default.publisher(for: .resetTextZoomRequested)) { _ in
                state.resetFontSize()
            }
    }
}

// MARK: - Draggable Split Divider Handle

public struct ResizeDividerHandle: View {
    @Binding var isHovering: Bool
    @Binding var isDragging: Bool
    let onDragChanged: (CGFloat) -> Void
    let onDragEnded: () -> Void
    let onResetSplit: () -> Void
    
    public init(
        isHovering: Binding<Bool>,
        isDragging: Binding<Bool>,
        onDragChanged: @escaping (CGFloat) -> Void,
        onDragEnded: @escaping () -> Void,
        onResetSplit: @escaping () -> Void
    ) {
        self._isHovering = isHovering
        self._isDragging = isDragging
        self.onDragChanged = onDragChanged
        self.onDragEnded = onDragEnded
        self.onResetSplit = onResetSplit
    }
    
    public var body: some View {
        ZStack {
            // Full-height 16pt hit area
            Color.clear
                .contentShape(Rectangle())
            
            // Centered 1pt separator line
            Rectangle()
                .fill(Color(nsColor: .separatorColor))
                .frame(width: 1)
            
            // Visual grab handle pill
            Capsule()
                .fill(
                    (isHovering || isDragging)
                    ? Color.accentColor
                    : Color.secondary.opacity(0.35)
                )
                .frame(width: (isHovering || isDragging) ? 6 : 5, height: 42)
                .glassEffect(.regular.interactive(), in: .capsule)
                .overlay(
                    VStack(spacing: 3) {
                        ForEach(0..<3) { _ in
                            Circle()
                                .fill(Color.white.opacity((isHovering || isDragging) ? 0.95 : 0.65))
                                .frame(width: 2, height: 2)
                        }
                    }
                )
                .shadow(
                    color: (isHovering || isDragging) ? Color.accentColor.opacity(0.4) : Color.black.opacity(0.1),
                    radius: (isHovering || isDragging) ? 3 : 1,
                    y: 1
                )
                .animation(.easeInOut(duration: 0.15), value: isHovering || isDragging)
        }
        .frame(width: 16)
        .overlay(ResizeCursorView().allowsHitTesting(false))
        .onHover { hovering in
            isHovering = hovering
            if hovering {
                NSCursor.resizeLeftRight.push()
            } else if !isDragging {
                NSCursor.pop()
            }
        }
        .gesture(
            DragGesture(minimumDistance: 1, coordinateSpace: .global)
                .onChanged { gesture in
                    if !isDragging {
                        isDragging = true
                        NSCursor.resizeLeftRight.set()
                    }
                    onDragChanged(gesture.translation.width)
                }
                .onEnded { _ in
                    isDragging = false
                    onDragEnded()
                    if !isHovering {
                        NSCursor.arrow.set()
                    }
                }
        )
        .simultaneousGesture(
            TapGesture(count: 2).onEnded {
                onResetSplit()
            }
        )
        .help(String(localized: "Drag to resize • Double-click to reset (50/50)"))
    }
}

private struct ResizeCursorView: NSViewRepresentable {
    func makeNSView(context: Context) -> CursorHostingNSView {
        CursorHostingNSView()
    }
    
    func updateNSView(_ nsView: CursorHostingNSView, context: Context) {}
}

private class CursorHostingNSView: NSView {
    override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: .resizeLeftRight)
    }
}

// MARK: - Draggable Vertical Split Divider Handle

public struct VerticalResizeDividerHandle: View {
    @Binding var isHovering: Bool
    @Binding var isDragging: Bool
    let onDragChanged: (CGFloat) -> Void
    let onDragEnded: () -> Void
    let onResetHeight: () -> Void
    
    public init(
        isHovering: Binding<Bool>,
        isDragging: Binding<Bool>,
        onDragChanged: @escaping (CGFloat) -> Void,
        onDragEnded: @escaping () -> Void,
        onResetHeight: @escaping () -> Void
    ) {
        self._isHovering = isHovering
        self._isDragging = isDragging
        self.onDragChanged = onDragChanged
        self.onDragEnded = onDragEnded
        self.onResetHeight = onResetHeight
    }
    
    public var body: some View {
        ZStack {
            // Full-width 12pt hit area
            Color.clear
                .contentShape(Rectangle())
            
            // Centered 1pt separator line
            Rectangle()
                .fill(Color(nsColor: .separatorColor))
                .frame(height: 1)
            
            // Visual grab handle pill
            Capsule()
                .fill(
                    (isHovering || isDragging)
                    ? Color.accentColor
                    : Color.secondary.opacity(0.35)
                )
                .frame(width: 44, height: (isHovering || isDragging) ? 5 : 4)
                .glassEffect(.regular.interactive(), in: .capsule)
                .overlay(
                    HStack(spacing: 3) {
                        ForEach(0..<3) { _ in
                            Circle()
                                .fill(Color.white.opacity((isHovering || isDragging) ? 0.95 : 0.65))
                                .frame(width: 2, height: 2)
                        }
                    }
                )
                .shadow(
                    color: (isHovering || isDragging) ? Color.accentColor.opacity(0.4) : Color.black.opacity(0.1),
                    radius: (isHovering || isDragging) ? 3 : 1,
                    y: 1
                )
                .animation(.easeInOut(duration: 0.15), value: isHovering || isDragging)
        }
        .frame(height: 12)
        .overlay(VerticalResizeCursorView().allowsHitTesting(false))
        .onHover { hovering in
            isHovering = hovering
            if hovering {
                NSCursor.resizeUpDown.push()
            } else if !isDragging {
                NSCursor.pop()
            }
        }
        .gesture(
            DragGesture(minimumDistance: 1, coordinateSpace: .global)
                .onChanged { gesture in
                    if !isDragging {
                        isDragging = true
                        NSCursor.resizeUpDown.set()
                    }
                    onDragChanged(gesture.translation.height)
                }
                .onEnded { _ in
                    isDragging = false
                    onDragEnded()
                    if !isHovering {
                        NSCursor.arrow.set()
                    }
                }
        )
        .simultaneousGesture(
            TapGesture(count: 2).onEnded {
                onResetHeight()
            }
        )
        .help(String(localized: "Drag to resize • Double-click to reset"))
    }
}

private struct VerticalResizeCursorView: NSViewRepresentable {
    func makeNSView(context: Context) -> VerticalCursorHostingNSView {
        VerticalCursorHostingNSView()
    }
    
    func updateNSView(_ nsView: VerticalCursorHostingNSView, context: Context) {}
}

private class VerticalCursorHostingNSView: NSView {
    override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: .resizeUpDown)
    }
}

// MARK: - Native macOS Transferable for PDF Sharing

private struct DocumentPDFExport: Transferable {
    let data: Data
    let title: String
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .pdf) { export in
            export.data
        }
        .suggestedFileName { export in
            "\(export.title).pdf"
        }
    }
}

