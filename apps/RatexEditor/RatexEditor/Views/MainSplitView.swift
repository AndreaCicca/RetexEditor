import SwiftUI
import AppKit

public struct MainSplitView: View {
    @Bindable var state: EditorState
    @Binding var document: TeXDocument
    
    public init(state: EditorState, document: Binding<TeXDocument>) {
        self.state = state
        self._document = document
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Top WYSIWYG formatting toolbar
            WYSIWYGToolbar(state: state)
            
            Divider()
            
            // Split view: Left Source Editor, Right PDF Live Preview
            HSplitView {
                // Left: Source Editor
                VStack(spacing: 0) {
                    HStack {
                        Text("LaTeX Source")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(state.source.count) chars")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    
                    SourceEditorView(state: state)
                }
                .frame(minWidth: 320, maxWidth: .infinity)
                
                // Right: PDFKit Live Preview
                VStack(spacing: 0) {
                    HStack {
                        Text("Live PDF Preview")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if state.pdfData != nil {
                            Button(action: exportPDF) {
                                Label("Export PDF…", systemImage: "arrow.down.doc")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    
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
                            Text("Fix compilation errors or press Recompile.")
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
        .onChange(of: state.source) { _, newValue in
            // Synchronize back with Document model
            document.text = newValue
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                // Templates quick menu
                Menu {
                    ForEach(TeXTemplate.all) { template in
                        Button(action: {
                            state.source = template.source
                        }) {
                            Label(template.name, systemImage: template.icon)
                        }
                    }
                } label: {
                    Label("Templates", systemImage: "sparkles")
                }
                .help("Insert LaTeX Template")
                
                // Export PDF button
                Button(action: exportPDF) {
                    Label("Export PDF", systemImage: "square.and.arrow.up")
                }
                .disabled(state.pdfData == nil)
                .help("Export Compiled PDF")
            }
        }
    }
    
    private func exportPDF() {
        guard let data = state.pdfData else { return }
        let panel = NSSavePanel()
        panel.title = "Export Compiled PDF"
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "document.pdf"
        
        if panel.runModal() == .OK, let url = panel.url {
            try? data.write(to: url)
        }
    }
}

