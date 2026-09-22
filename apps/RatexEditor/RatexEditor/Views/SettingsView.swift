import SwiftUI

/// Native macOS Settings Scene View (⌘,)
public struct SettingsView: View {
    private enum Tabs: Hashable {
        case general, editor, compiler
    }
    
    @AppStorage("editor_font_size") private var defaultFontSize: Double = 13.5
    @AppStorage("editor_preview_split_ratio") private var splitRatio: Double = 0.5
    @AppStorage("auto_compile_delay_ms") private var autoCompileDelayMs: Double = 350
    @AppStorage("auto_compile_enabled") private var autoCompileEnabled: Bool = true
    @AppStorage("show_line_numbers") private var showLineNumbers: Bool = true
    
    public init() {}
    
    public var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
                .tag(Tabs.general)
            
            editorTab
                .tabItem {
                    Label("Editor", systemImage: "character.cursor.ibeam")
                }
                .tag(Tabs.editor)
            
            compilerTab
                .tabItem {
                    Label("Compiler", systemImage: "bolt.fill")
                }
                .tag(Tabs.compiler)
        }
        .padding(20)
        .frame(width: 480, height: 280)
    }
    
    // MARK: - General Tab
    
    private var generalTab: some View {
        Form {
            Section {
                Toggle("Auto-compile on file changes", isOn: $autoCompileEnabled)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Compile debounce:")
                        Spacer()
                        Text("\(Int(autoCompileDelayMs)) ms")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .glassEffect(.regular, in: .capsule)
                    }
                    
                    Slider(
                        value: $autoCompileDelayMs,
                        in: 150...1000,
                        step: 50
                    ) {
                        Text("Compile debounce")
                    } minimumValueLabel: {
                        Text("150ms")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } maximumValueLabel: {
                        Text("1000ms")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 2)
                
                Text("Delay before compiling LaTeX while typing: \(Int(autoCompileDelayMs)) ms")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
    
    // MARK: - Editor Tab
    
    private var editorTab: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Font size:")
                        Spacer()
                        Text(String(format: "%.1f pt", defaultFontSize))
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .glassEffect(.regular, in: .capsule)
                    }
                    
                    Slider(
                        value: $defaultFontSize,
                        in: 10...24,
                        step: 0.5
                    ) {
                        Text("Font size")
                    } minimumValueLabel: {
                        Text("10pt")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } maximumValueLabel: {
                        Text("24pt")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 2)
                
                Text("Default editor font size: \(String(format: "%.1f", defaultFontSize)) pt")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Toggle("Show line numbers", isOn: $showLineNumbers)
            }
        }
        .formStyle(.grouped)
    }
    
    // MARK: - Compiler Tab
    
    private var compilerTab: some View {
        Form {
            Section {
                LabeledContent("Engine") {
                    Text("Embedded Rust TeX (libtex.a)")
                        .foregroundStyle(.secondary)
                }
                
                LabeledContent("Supported Dialects") {
                    Text("LaTeX 2e, Plain TeX")
                        .foregroundStyle(.secondary)
                }
                
                LabeledContent("Default Packages") {
                    Text("amsmath, amssymb, graphicx, babel (IT)")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
    }
}
