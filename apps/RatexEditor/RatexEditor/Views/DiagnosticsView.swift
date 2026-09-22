import SwiftUI
import AppKit

public struct DiagnosticsView: View {
    @Bindable var state: EditorState
    @Binding var drawerHeight: Double
    var maxDrawerHeight: CGFloat
    
    @State private var filterQuery = ""
    
    public init(
        state: EditorState,
        drawerHeight: Binding<Double>? = nil,
        maxDrawerHeight: CGFloat = 600
    ) {
        self.state = state
        self._drawerHeight = drawerHeight ?? .constant(240)
        self.maxDrawerHeight = maxDrawerHeight
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            headerBar
            contentArea
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    // MARK: - Minimalist Header Bar
    
    private var headerBar: some View {
        HStack(spacing: 10) {
            // Diagnostics Title & Status Indicator
            HStack(spacing: 6) {
                Image(systemName: "terminal.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                
                Text(String(localized: "Diagnostics"))
                    .font(.system(size: 12, weight: .semibold))
                
                if state.isCompiling {
                    ProgressView()
                        .controlSize(.mini)
                } else if state.diagnostics.isEmpty {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.system(size: 10))
                } else {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .glassEffect(.regular, in: .capsule)
            
            Spacer(minLength: 16)
            
            // Search / Filter Field
            HStack(spacing: 5) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                
                TextField(String(localized: "Search in text…"), text: $filterQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                
                if !filterQuery.isEmpty {
                    Button(action: { filterQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3.5)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color(nsColor: .separatorColor).opacity(0.4), lineWidth: 0.5)
            )
            .frame(minWidth: 110, maxWidth: 200)
            
            // Close Button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                    state.isDiagnosticsDrawerOpen = false
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(3)
            }
            .buttonStyle(.glass)
            .controlSize(.mini)
            .help("Close Diagnostics (⇧⌘D)")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.bar)
    }
    
    // MARK: - Content Area
    
    @ViewBuilder
    private var contentArea: some View {
        if state.diagnostics.isEmpty {
            cleanBuildEmptyState
        } else {
            ConsoleLogTextView(
                text: state.diagnostics,
                isDiagnostics: true,
                fontSize: 12.5,
                isWrapEnabled: true,
                searchQuery: filterQuery,
                onNavigateToLine: { line in
                    state.scrollToLine(line)
                }
            )
        }
    }
    
    // MARK: - Empty State
    
    private var cleanBuildEmptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(.green)
            
            Text("No Diagnostics")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.primary)
            
            Text("No compiler errors or issues reported.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
