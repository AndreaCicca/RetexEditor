import SwiftUI

public struct WYSIWYGToolbar: View {
    @Bindable var state: EditorState
    
    public var body: some View {
        HStack(spacing: 8) {
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
                Label("Math Palette", systemImage: "function")
            }
            .popover(isPresented: $state.isMathPaletteOpen, arrowEdge: .bottom) {
                MathPaletteView(state: state)
            }
            .help("Open LaTeX Math Symbol Palette")
            
            // Project Folder Indicator & Selector
            Menu {
                if let dir = state.projectDirectory {
                    Text("Directory: \(dir.path)")
                        .font(.caption)
                    Divider()
                    Button("Change Project Folder…") {
                        selectProjectFolder()
                    }
                    Button("Clear Project Folder") {
                        state.customProjectDirectory = nil
                    }
                } else {
                    Button("Select Project Folder…") {
                        selectProjectFolder()
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: state.projectDirectory != nil ? "folder.fill" : "folder.badge.plus")
                        .foregroundStyle(state.projectDirectory != nil ? Color.accentColor : Color.secondary)
                    Text(state.projectDirectory?.lastPathComponent ?? "Project Folder")
                        .font(.caption)
                        .lineLimit(1)
                }
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help(state.projectDirectory?.path ?? "Link document to a project directory for custom .cls, .sty, bib, and images")

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
    
    private func selectProjectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select Project Folder"
        panel.message = "Choose the directory containing your LaTeX classes (.cls), styles (.sty), bibliographies, and images"
        if panel.runModal() == .OK, let url = panel.url {
            state.customProjectDirectory = url
        }
    }
}

