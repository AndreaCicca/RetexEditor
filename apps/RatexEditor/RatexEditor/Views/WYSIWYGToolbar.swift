import SwiftUI
import AppKit

public struct WYSIWYGToolbar: View {
    @Bindable var state: EditorState
    var workspace: WorkspaceModel? = nil
    
    @State private var isStatusHovered = false
    @State private var pendingTemplate: TeXTemplate? = nil
    @State private var showingTemplateConfirmation = false
    
    public init(state: EditorState, workspace: WorkspaceModel? = nil) {
        self.state = state
        self.workspace = workspace
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            // Text Formatting Group (native macOS ControlGroup)
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
            .controlSize(.small)
            
            // Section Headings Menu (native macOS bordered menu)
            Menu {
                Button("Section (\\section)") { state.insertHeading(level: 1) }
                Button("Subsection (\\subsection)") { state.insertHeading(level: 2) }
                Button("Subsubsection (\\subsubsection)") { state.insertHeading(level: 3) }
                Button("Paragraph (\\paragraph)") { state.insertHeading(level: 4) }
            } label: {
                Label("Heading", systemImage: "text.quote")
            }
            .menuStyle(.button)
            .controlSize(.small)
            .fixedSize()
            
            // Insert Elements Menu (native macOS bordered menu)
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
            .menuStyle(.button)
            .controlSize(.small)
            .fixedSize()
            
            // Lorem Ipsum Text Menu (native macOS bordered menu)
            Menu {
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

Fusce vehicula dolor arcu, sit amet blandit dolor mollis nec. Donec viverra eleifend lacus, vitae ullamcorper metus.
""")
                }
            } label: {
                Label("Lorem Ipsum", systemImage: "doc.plaintext")
            }
            .menuStyle(.button)
            .controlSize(.small)
            .fixedSize()
            .help("Insert Lorem Ipsum dummy text at cursor position")
            
            // Starter Templates Menu (native macOS bordered menu)
            Menu {
                ForEach(TeXTemplate.all) { template in
                    Button(action: {
                        handleTemplateSelected(template)
                    }) {
                        Label(template.name, systemImage: template.icon)
                    }
                }
            } label: {
                Label("Templates", systemImage: "doc.badge.ellipsis")
            }
            .menuStyle(.button)
            .controlSize(.small)
            .fixedSize()
            .help("Apply a starter LaTeX document template")
            
            Divider()
                .frame(height: 16)
                .opacity(0.4)
            
            // Math Group (native macOS ControlGroup)
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
            .controlSize(.small)
            
            // Math Palette Popover Button
            Button(action: { state.isMathPaletteOpen.toggle() }) {
                Label("Math", systemImage: "function")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .popover(isPresented: $state.isMathPaletteOpen, arrowEdge: .bottom) {
                MathPaletteView(state: state)
            }
            .help("Open LaTeX Math Symbol Palette (⇧⌘M)")
            
            // Project Entrypoint Selector (native macOS bordered menu)
            if let ws = workspace, !ws.allTexFiles.isEmpty {
                Menu {
                    Text("Project Entrypoint (Master TeX file):")
                        .font(.caption)
                    Divider()
                    
                    Button(action: {
                        ws.entryPointURL = nil
                        state.entryPointURL = nil
                        state.scheduleCompilation()
                    }) {
                        HStack {
                            if let doc = state.documentURL {
                                Label("Active Document (\(doc.lastPathComponent))", systemImage: "doc.text")
                            } else {
                                Label("Active Document (Auto)", systemImage: "doc.text")
                            }
                            if ws.entryPointURL == nil {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    
                    Divider()
                    
                    ForEach(ws.allTexFiles, id: \.self) { texURL in
                        Button(action: {
                            ws.entryPointURL = texURL
                            state.entryPointURL = texURL
                            state.scheduleCompilation()
                        }) {
                            HStack {
                                Text(ws.relativePath(for: texURL))
                                if ws.entryPointURL?.standardizedFileURL == texURL.standardizedFileURL {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "play.circle.fill")
                            .foregroundStyle(.blue)
                        if let entry = ws.entryPointURL {
                            Text("Master: \(entry.lastPathComponent)")
                                .lineLimit(1)
                        } else if let doc = state.documentURL {
                            Text("Active: \(doc.lastPathComponent)")
                                .lineLimit(1)
                        } else {
                            Text(String(localized: "Active Document"))
                                .lineLimit(1)
                        }
                    }
                }
                .menuStyle(.button)
                .controlSize(.small)
                .fixedSize()
                .help("Select LaTeX Project Entry Point (Master File to Compile)")
            }

            Spacer()
            
            // Status & Performance Capsule
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
                    Text(String.localizedStringWithFormat(
                        NSLocalizedString("%1$.1f ms (%2$lld passes)", comment: ""),
                        state.lastDurationMs,
                        Int64(state.lastPasses)
                    ))
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
            
            // Manual Compile Button (native macOS bordered button)
            Button(action: {
                Task { @MainActor in
                    await state.compileImmediate()
                }
            }) {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(.orange)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("Recompile Document (⌘R)")
            
            // Diagnostics Drawer Toggle Button (native macOS bordered button)
            Button(action: { state.isDiagnosticsDrawerOpen.toggle() }) {
                Image(systemName: state.diagnostics.isEmpty ? "terminal" : "exclamationmark.bubble.fill")
                    .foregroundStyle(state.diagnostics.isEmpty ? (state.isDiagnosticsDrawerOpen ? Color.accentColor : Color.primary) : Color.orange)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("Toggle Compiler Log & Diagnostics (⇧⌘D)")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .liquidGlassBar(hasBottomBorder: true, hasTopHighlight: true)
        .confirmationDialog(
            "Replace Document Content?",
            isPresented: $showingTemplateConfirmation,
            presenting: pendingTemplate
        ) { template in
            Button("Replace Document", role: .destructive) {
                state.setSourceWithUndo(template.source)
                pendingTemplate = nil
            }
            Button("Cancel", role: .cancel) {
                pendingTemplate = nil
            }
        } message: { template in
            Text("Applying the '\(template.name)' template will replace all text in '\(state.documentURL?.lastPathComponent ?? "Untitled.tex")'. This action can be undone with ⌘Z.")
        }
    }
    
    private func handleTemplateSelected(_ template: TeXTemplate) {
        if state.source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            state.setSourceWithUndo(template.source)
        } else {
            pendingTemplate = template
            showingTemplateConfirmation = true
        }
    }
}
