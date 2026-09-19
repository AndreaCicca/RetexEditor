import SwiftUI
import AppKit

public struct DiagnosticsView: View {
    @Bindable var state: EditorState
    @State private var selectedTab = 0
    
    public init(state: EditorState) {
        self.state = state
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            // Header bar
            HStack(spacing: 12) {
                Picker("", selection: $selectedTab) {
                    Text("Diagnostics").tag(0)
                    Text("TeX Log").tag(1)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 220)
                
                // Status indicator
                if selectedTab == 0 {
                    if state.diagnostics.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("No errors")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("Issues detected")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                }
                
                Spacer()
                
                Button(action: {
                    let content = selectedTab == 0 ? state.diagnostics : state.log
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(content, forType: .string)
                }) {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .help("Copy content to clipboard")
                
                Button(action: { state.isDiagnosticsDrawerOpen = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .help("Close Diagnostics Drawer")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(nsColor: .controlBackgroundColor))
            
            // Content
            ScrollView(.vertical) {
                let content = selectedTab == 0 ? state.diagnostics : state.log
                Text(content.isEmpty ? (selectedTab == 0 ? "No diagnostics or errors reported." : "TeX log is empty.") : content)
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(selectedTab == 0 && state.lastStatus != .success ? Color.red : Color.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .textSelection(.enabled)
            }
            .background(Color(nsColor: .textBackgroundColor))
        }
        .frame(height: 180)
    }
}
