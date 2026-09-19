import SwiftUI
import AppKit
import UniformTypeIdentifiers

@main
struct RatexEditorApp: App {
    @State private var workspace = WorkspaceModel()
    
    var body: some Scene {
        WindowGroup {
            WorkspaceRootView(workspace: workspace)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Project…") {
                    NotificationCenter.default.post(name: .newProjectRequested, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command])
                
                Button("Open Project Folder…") {
                    openFolderDialog()
                }
                .keyboardShortcut("o", modifiers: [.command])
                
                Button("Open TeX Document…") {
                    openDocumentDialog()
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
                
                Divider()
                
                Button("Close Project") {
                    workspace.closeWorkspace()
                }
                .keyboardShortcut("w", modifiers: [.command, .shift])
                .disabled(workspace.rootDirectory == nil)
            }
            
            CommandMenu("Typeset") {
                Button("Recompile Document") {
                    NotificationCenter.default.post(name: .recompileRequested, object: nil)
                }
                .keyboardShortcut("r", modifiers: [.command])
                
                Divider()
                
                Button("Toggle Math Palette") {
                    NotificationCenter.default.post(name: .toggleMathPaletteRequested, object: nil)
                }
                .keyboardShortcut("m", modifiers: [.command, .shift])
                
                Button("Toggle Diagnostics Drawer") {
                    NotificationCenter.default.post(name: .toggleDiagnosticsRequested, object: nil)
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])
            }
            
            CommandMenu("Format (TeX)") {
                Button("Bold (\\textbf)") {
                    NotificationCenter.default.post(name: .formatBoldRequested, object: nil)
                }
                .keyboardShortcut("b", modifiers: [.command])
                
                Button("Italic (\\textit)") {
                    NotificationCenter.default.post(name: .formatItalicRequested, object: nil)
                }
                .keyboardShortcut("i", modifiers: [.command])
                
                Button("Underline (\\underline)") {
                    NotificationCenter.default.post(name: .formatUnderlineRequested, object: nil)
                }
                .keyboardShortcut("u", modifiers: [.command])
                
                Button("Monospace Code (\\texttt)") {
                    NotificationCenter.default.post(name: .formatCodeRequested, object: nil)
                }
                .keyboardShortcut("k", modifiers: [.command])
                
                Divider()
                
                Button("Inline Math ($...$)") {
                    NotificationCenter.default.post(name: .formatInlineMathRequested, object: nil)
                }
                .keyboardShortcut("4", modifiers: [.command, .shift]) // Cmd+$
                
                Button("Display Equation (\\[...\\])") {
                    NotificationCenter.default.post(name: .formatDisplayMathRequested, object: nil)
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
            }
        }
    }
    
    private func openFolderDialog() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Open Project Folder"
        panel.message = "Choose a project directory to open in Ratex Editor"
        if panel.runModal() == .OK, let url = panel.url {
            workspace.openFolder(url: url)
        }
    }
    
    private func openDocumentDialog() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [
            UTType("org.tug.tex") ?? .plainText,
            UTType.plainText
        ]
        panel.prompt = "Open Document"
        if panel.runModal() == .OK, let url = panel.url {
            workspace.openSingleDocument(url: url)
        }
    }
}

struct WorkspaceRootView: View {
    @Bindable var workspace: WorkspaceModel
    @State private var showingNewProjectSheet = false
    
    var body: some View {
        Group {
            if workspace.rootDirectory == nil {
                WelcomeView(workspace: workspace)
            } else {
                MainSplitView(workspace: workspace)
            }
        }
        .navigationTitle(windowTitle)
        .onReceive(NotificationCenter.default.publisher(for: .newProjectRequested)) { _ in
            showingNewProjectSheet = true
        }
        .sheet(isPresented: $showingNewProjectSheet) {
            NewProjectSheetView(workspace: workspace, isPresented: $showingNewProjectSheet)
        }
    }
    
    private var windowTitle: String {
        if let root = workspace.rootDirectory {
            if let entry = workspace.entryPointURL {
                return "\(root.lastPathComponent) — \(entry.lastPathComponent)"
            }
            return root.lastPathComponent
        }
        return "Ratex Editor"
    }
}

extension Notification.Name {
    static let newProjectRequested = Notification.Name("ratex.newProjectRequested")
    static let recompileRequested = Notification.Name("ratex.recompileRequested")
    static let toggleMathPaletteRequested = Notification.Name("ratex.toggleMathPaletteRequested")
    static let toggleDiagnosticsRequested = Notification.Name("ratex.toggleDiagnosticsRequested")
    static let formatBoldRequested = Notification.Name("ratex.formatBoldRequested")
    static let formatItalicRequested = Notification.Name("ratex.formatItalicRequested")
    static let formatUnderlineRequested = Notification.Name("ratex.formatUnderlineRequested")
    static let formatCodeRequested = Notification.Name("ratex.formatCodeRequested")
    static let formatInlineMathRequested = Notification.Name("ratex.formatInlineMathRequested")
    static let formatDisplayMathRequested = Notification.Name("ratex.formatDisplayMathRequested")
}
