import SwiftUI
import AppKit

public struct WYSIWYGToolbar: View {
    @Bindable var state: EditorState
    var workspace: WorkspaceModel? = nil
    var onToggleSidebar: (() -> Void)? = nil
    
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
                }
                .help("Toggle File Explorer Sidebar")
                
                Divider()
                    .frame(height: 18)
            }
            
            // Text Formatting Group
            ControlGroup {
                Button(action: { state.applyBold() }) {
                    Image(systemName: "bold")
                }
                .help("Bold (\\textbf)")
                
                Button(action: { state.applyItalic() }) {
                    Image(systemName: "italic")
                }
                .help("Italic (\\textit)")
                
                Button(action: { state.applyUnderline() }) {
                    Image(systemName: "underline")
                }
                .help("Underline (\\underline)")
                
                Button(action: { state.applyCode() }) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                }
                .help("Monospace Code (\\texttt)")
            }
            
            // Section Headings Menu
            Menu {
                Button("Section (\\section)") { state.insertHeading(level: 1) }
                Button("Subsection (\\subsection)") { state.insertHeading(level: 2) }
                Button("Subsubsection (\\subsubsection)") { state.insertHeading(level: 3) }
                Button("Paragraph (\\paragraph)") { state.insertHeading(level: 4) }
            } label: {
                Label("Heading", systemImage: "text.quote")
            }
            .menuStyle(.borderlessButton)
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
            }
            .menuStyle(.borderlessButton)
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
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help("Insert default templates and Lorem Ipsum dummy text")
            
            Divider()
                .frame(height: 18)
            
            // Math Group
            ControlGroup {
                Button(action: { state.insertInlineMath() }) {
                    Text("$…$")
                        .font(.system(size: 13, weight: .bold, design: .serif))
                }
                .help("Inline Math ($...$)")
                
                Button(action: { state.insertDisplayMath() }) {
                    Text("$$")
                        .font(.system(size: 13, weight: .bold, design: .serif))
                }
                .help("Display Equation (\\[...\\])")
                
                Button(action: { state.insertFraction() }) {
                    Image(systemName: "divide")
                }
                .help("Fraction (\\frac{a}{b})")
                
                Button(action: { state.insertSqrt() }) {
                    Text("√")
                        .font(.system(size: 14, weight: .semibold))
                }
                .help("Square Root (\\sqrt{x})")
            }
            
            // Math Palette Popover Button
            Button(action: { state.isMathPaletteOpen.toggle() }) {
                Label("Math", systemImage: "function")
            }
            .popover(isPresented: $state.isMathPaletteOpen, arrowEdge: .bottom) {
                MathPaletteView(state: state)
            }
            .help("Open LaTeX Math Symbol Palette")
            
            Divider()
                .frame(height: 18)
            
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
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                    }
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .help("Select LaTeX Project Entry Point (Master File to Compile)")
            }

            Spacer()
            
            // Status & Performance Pill
            HStack(spacing: 6) {
                if state.isCompiling {
                    ProgressView()
                        .controlSize(.small)
                    Text("Compiling...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if state.lastStatus == .success {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text(String(format: "%.1f ms (%d pass%@)", state.lastDurationMs, state.lastPasses, state.lastPasses == 1 ? "" : "es"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                    Text(state.lastStatus.description)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
            
            // Manual Compile Button
            Button(action: {
                Task { @MainActor in
                    await state.compileImmediate()
                }
            }) {
                Image(systemName: "bolt.fill")
            }
            .help("Recompile Document (Cmd+R)")
            
            // Diagnostics Drawer Toggle Button
            Button(action: { state.isDiagnosticsDrawerOpen.toggle() }) {
                Image(systemName: state.diagnostics.isEmpty ? "terminal" : "exclamationmark.bubble.fill")
                    .foregroundStyle(state.diagnostics.isEmpty ? Color.primary : Color.orange)
            }
            .help("Toggle Compiler Log & Diagnostics")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
