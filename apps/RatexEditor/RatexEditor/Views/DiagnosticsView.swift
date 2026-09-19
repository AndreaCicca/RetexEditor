import SwiftUI

public struct DiagnosticsView: View {
    @Bindable var state: EditorState
    @State private var selectedTab = 0
    
    public var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            // Header bar
            HStack {
                Picker("View", selection: $selectedTab) {
                    Text("Diagnostics").tag(0)
                    Text("TeX Log").tag(1)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                
                Spacer()
                
                Button(action: {
                    let content = selectedTab == 0 ? state.diagnostics : state.log
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(content, forType: .string)
                }) {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                
                Button(action: { state.isDiagnosticsDrawerOpen = false }) {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(nsColor: .controlBackgroundColor))
            
            // Content
            ScrollView(.vertical) {
                let content = selectedTab == 0 ? state.diagnostics : state.log
                Text(content.isEmpty ? "No diagnostics or errors reported." : content)
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(selectedTab == 0 && state.lastStatus != .success ? Color.red : Color.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .textSelection(.enabled)
            }
            .background(Color(nsColor: .textBackgroundColor))
        }
        .frame(height: 160)
    }
}

