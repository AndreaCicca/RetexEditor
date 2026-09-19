import SwiftUI
import AppKit

public struct DiagnosticsView: View {
    @Bindable var state: EditorState
    @State private var selectedTab = 0
    @State private var isCopyHovered = false
    @State private var isCloseHovered = false
    
    public init(state: EditorState) {
        self.state = state
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header bar in Liquid Glass
            HStack(spacing: 12) {
                Picker("", selection: $selectedTab) {
                    Text("Diagnostics").tag(0)
                    Text("TeX Log").tag(1)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 220)
                .liquidGlass(cornerRadius: 7)
                
                // Status indicator capsule
                if selectedTab == 0 {
                    if state.diagnostics.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("No errors")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .liquidGlassCapsule(tint: .green)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("Issues detected")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.orange)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .liquidGlassCapsule(tint: .orange)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    let content = selectedTab == 0 ? state.diagnostics : state.log
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(content, forType: .string)
                }) {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
                .liquidGlass(cornerRadius: 6, isInteractive: true, isHovered: isCopyHovered)
                .onHover { isCopyHovered = $0 }
                .help("Copy content to clipboard")
                
                Button(action: { state.isDiagnosticsDrawerOpen = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                        .padding(5)
                }
                .buttonStyle(.plain)
                .liquidGlass(cornerRadius: 12, isInteractive: true, isHovered: isCloseHovered)
                .onHover { isCloseHovered = $0 }
                .help("Close Diagnostics Drawer")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .liquidGlassBar(hasBottomBorder: true, hasTopHighlight: true)
            
            // Content
            ScrollView(.vertical) {
                let content = selectedTab == 0 ? state.diagnostics : state.log
                Text(content.isEmpty ? (selectedTab == 0 ? "No diagnostics or errors reported." : "TeX log is empty.") : content)
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(selectedTab == 0 && state.lastStatus != .success ? Color.red : Color.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .textSelection(.enabled)
            }
            .background(Color(nsColor: .textBackgroundColor).opacity(0.85))
        }
        .frame(height: 180)
    }
}
