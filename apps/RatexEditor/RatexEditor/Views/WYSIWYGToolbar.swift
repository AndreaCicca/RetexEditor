import SwiftUI
import AppKit

public struct WYSIWYGToolbar: View {
    @Bindable var state: EditorState
    var workspace: WorkspaceModel? = nil
    var onToggleSidebar: (() -> Void)? = nil
    
    @State private var isCompileHovered = false
    @State private var isDiagHovered = false
    @State private var isStatusHovered = false
    
    public init(state: EditorState, workspace: WorkspaceModel? = nil, onToggleSidebar: (() -> Void)? = nil) {
        self.state = state
        self.workspace = workspace
        self.onToggleSidebar = onToggleSidebar
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            // Sidebar Toggle Button
            if let toggle = onToggleSidebar {
                Button(action: toggle) {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 12, weight: .medium))
                        .padding(5)
                }
                .buttonStyle(.plain)
                .liquidGlass(cornerRadius: 6, isInteractive: true)
                .help("Toggle File Explorer Sidebar (⌘⌃S)")
                
                Divider()
                    .frame(height: 16)
                    .opacity(0.4)
            }
            
            // Text Formatting Group
            ControlGroup {
                Button(action: { state.applyBold() }) {
                    Image(systemName: "bold")
                }
                .help("Bold (\\textbf) (⌘B)")
                
                Button(action: { state.applyItalic() }) {
                    Image(systemName: "italic")
                }
                .help("Italic (\\textit) (⌘I)")
                
                Button(action: { state.applyUnderline() }) {
                    Image(systemName: "underline")
                }
                .help("Underline (\\underline) (⌘U)")
                
                Button(action: { state.applyCode() }) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                }
                .help("Monospace Code (\\texttt)")
            }
            .liquidGlass(cornerRadius: 7)
            
            // Section Headings Menu
            Menu {
                Button("Section (\\section)") { state.insertHeading(level: 1) }
                Button("Subsection (\\subsection)") { state.insertHeading(level: 2) }
                Button("Subsubsection (\\subsubsection)") { state.insertHeading(level: 3) }
                Button("Paragraph (\\paragraph)") { state.insertHeading(level: 4) }
            } label: {
                Label("Heading", systemImage: "text.quote")
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 3)
            }
            .menuStyle(.borderlessButton)
            .liquidGlass(cornerRadius: 6, isInteractive: true)
            .fixedSize()
            
            // Insert Elements Menu
            Menu {
                Button("Bullet List (itemize)") { state.insertBulletList() }
                Button("Numbered List (enumerate)") { state.insertNumberedList() }
                Divider()
                Button("Table (tabular)") { state.insertTable() }
                Button("Figure with Caption") { state.insertFigure() }
                Button("Matrix (pmatrix)") { state.insertMatrix() }
            } label: {
                Label("Insert", systemImage: "plus.app")
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 3)
            }
            .menuStyle(.borderlessButton)
            .liquidGlass(cornerRadius: 6, isInteractive: true)
            .fixedSize()
            
            // Lorem Ipsum & Templates Menu
            Menu {
                Section("Document Templates") {
                    ForEach(TeXTemplate.all) { template in
                        Button(action: {
                            state.source = template.source
                        }) {
                            Label(template.name, systemImage: template.icon)
                        }
                    }
                }
                
                Divider()
                
                Section("Lorem Ipsum Text") {
                    Button("Insert Paragraph") {
                        state.insertText("""
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.
""")
                    }
                    Button("Insert Short Sample") {
                        state.insertText("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.")
                    }
                    Button("Insert Multi-paragraph") {
                        state.insertText("""
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Curabitur vel hendrerit libero, vitae dapibus nisi. Mauris posuere, velit vel suscipit tincidunt, turpis odio auctor risus, ut dignissim lectus nisl vitae diam.

Nullam ac urna eu felis dapibus condimentum sit amet a augue. Sed non neque elit. Sed ut imperdiet nisi. Proin condimentum fermentum nunc. Etiam pharetra, erat sed fermentum feugiat, velit mauris egestas quam.
""")
                    }
                }
            } label: {
                Label("Lorem Ipsum", systemImage: "doc.plaintext")
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 3)
            }
            .menuStyle(.borderlessButton)
            .liquidGlass(cornerRadius: 6, isInteractive: true)
            .fixedSize()
            .help("Insert default templates and Lorem Ipsum dummy text")
            
            Divider()
                .frame(height: 16)
                .opacity(0.4)
            
            // Math Group
            ControlGroup {
                Button(action: { state.insertInlineMath() }) {
                    Text("$…$")
                        .font(.system(size: 12, weight: .bold, design: .serif))
                }
                .help("Inline Math ($...$)")
                
                Button(action: { state.insertDisplayMath() }) {
                    Text("$$")
                        .font(.system(size: 12, weight: .bold, design: .serif))
                }
                .help("Display Equation (\\[...\\])")
                
                Button(action: { state.insertFraction() }) {
                    Image(systemName: "divide")
                }
                .help("Fraction (\\frac{a}{b})")
                
                Button(action: { state.insertSqrt() }) {
                    Text("√")
                        .font(.system(size: 13, weight: .semibold))
                }
                .help("Square Root (\\sqrt{x})")
            }
            .liquidGlass(cornerRadius: 7)
            
            // Math Palette Popover Button
            Button(action: { state.isMathPaletteOpen.toggle() }) {
                Label("Math", systemImage: "function")
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            .liquidGlass(cornerRadius: 6, isInteractive: true, tint: state.isMathPaletteOpen ? .blue : nil)
            .popover(isPresented: $state.isMathPaletteOpen, arrowEdge: .bottom) {
                MathPaletteView(state: state)
            }
            .help("Open LaTeX Math Symbol Palette (⇧⌘M)")
            
            Divider()
                .frame(height: 16)
                .opacity(0.4)
            
            // Project Entrypoint Selector
            if let ws = workspace, !ws.allTexFiles.isEmpty {
                Menu {
                    Text("Project Entrypoint (Master TeX file):")
                        .font(.caption)
                    Divider()
                    ForEach(ws.allTexFiles, id: \.self) { texURL in
                        Button(action: {
                            ws.entryPointURL = texURL
                            state.entryPointURL = texURL
                            state.scheduleCompilation()
                        }) {
                            HStack {
                                Text(ws.relativePath(for: texURL))
                                if texURL == ws.entryPointURL {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "play.circle.fill")
                            .foregroundStyle(.blue)
                        Text("Entry: \(ws.entryPointURL?.lastPathComponent ?? "Select…")")
                            .font(.system(size: 11, weight: .medium))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                }
                .menuStyle(.borderlessButton)
                .liquidGlass(cornerRadius: 6, isInteractive: true, tint: .blue)
                .fixedSize()
                .help("Select LaTeX Project Entry Point (Master File to Compile)")
            }

            Spacer()
            
            // Status & Performance Liquid Glass Capsule
            HStack(spacing: 6) {
                if state.isCompiling {
                    ProgressView()
                        .controlSize(.small)
                    Text("Compiling...")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                } else if state.lastStatus == .success {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.3))
                            .frame(width: 10, height: 10)
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                    }
                    Text(String(format: "%.1f ms (%d pass%@)", state.lastDurationMs, state.lastPasses, state.lastPasses == 1 ? "" : "es"))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                } else {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 6, height: 6)
                    Text(state.lastStatus.description)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4.5)
            .liquidGlassCapsule(
                tint: state.lastStatus == .success ? Color.green : (state.isCompiling ? Color.blue : Color.red),
                isHovered: isStatusHovered
            )
            .onHover { isStatusHovered = $0 }
            
            // Manual Compile Button (Liquid Glass lens)
            Button(action: {
                Task { @MainActor in
                    await state.compileImmediate()
                }
            }) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.orange)
                    .padding(5)
            }
            .buttonStyle(.plain)
            .liquidGlass(cornerRadius: 14, isInteractive: true, isHovered: isCompileHovered, tint: .orange)
            .onHover { isCompileHovered = $0 }
            .help("Recompile Document (⌘R)")
            
            // Diagnostics Drawer Toggle Button (Liquid Glass lens)
            Button(action: { state.isDiagnosticsDrawerOpen.toggle() }) {
                Image(systemName: state.diagnostics.isEmpty ? "terminal" : "exclamationmark.bubble.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(state.diagnostics.isEmpty ? (state.isDiagnosticsDrawerOpen ? Color.accentColor : Color.primary) : Color.orange)
                    .padding(5)
            }
            .buttonStyle(.plain)
            .liquidGlass(
                cornerRadius: 14,
                isInteractive: true,
                isHovered: isDiagHovered,
                tint: state.isDiagnosticsDrawerOpen ? Color.accentColor : nil
            )
            .onHover { isDiagHovered = $0 }
            .help("Toggle Compiler Log & Diagnostics (⇧⌘D)")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .liquidGlassBar(hasBottomBorder: true, hasTopHighlight: true)
    }
}
