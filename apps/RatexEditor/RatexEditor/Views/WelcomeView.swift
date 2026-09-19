import SwiftUI
import AppKit
import UniformTypeIdentifiers

public struct WelcomeView: View {
    @Bindable var workspace: WorkspaceModel
    
    @State private var showingNewProjectSheet = false
    @State private var newProjectName = "MyLatexProject"
    @State private var selectedTemplateIndex = 0
    @State private var isTargetedForDrop = false
    
    public init(workspace: WorkspaceModel) {
        self.workspace = workspace
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            // Left Pane: Welcome & Main Actions
            VStack(alignment: .leading, spacing: 24) {
                // App Branding
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 64, height: 64)
                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                        
                        Text("TeX")
                            .font(.system(size: 26, weight: .black, design: .serif))
                            .foregroundStyle(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ratex Editor")
                            .font(.system(size: 24, weight: .bold))
                        Text("High-performance Rust TeX engine & live preview")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 10)
                
                Divider()
                
                // Action Buttons
                VStack(spacing: 12) {
                    WelcomeActionButton(
                        icon: "folder.badge.gearshape.fill",
                        icon: "folder.fill.badge.gearshape",
                        iconColor: .blue,
                        title: "Open Project Folder…",
                        subtitle: "Open an existing folder with classes, styles, and chapters",
                        shortcut: "⌘O"
                    ) {
                        openProjectFolder()
                    }
                    
                    WelcomeActionButton(
                        icon: "doc.text.fill",
                        iconColor: .orange,
                        title: "Open TeX Document…",
                        subtitle: "Open an individual .tex or .ltx file",
                        shortcut: "⇧⌘O"
                    ) {
                        openSingleDocument()
                    }
                    
                    WelcomeActionButton(
                        icon: "plus.rectangle.on.folder.fill",
                        iconColor: .green,
                        title: "New Project…",
                        subtitle: "Create a new project directory from a template",
                        shortcut: "⌘N"
                    ) {
                        showingNewProjectSheet = true
                    }
                }
                
                Spacer()
                
                // Drag & Drop notice
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.doc")
                        .foregroundStyle(.tertiary)
                    Text("Or drag and drop any folder or .tex file here")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(32)
            .frame(minWidth: 420, maxWidth: .infinity, maxHeight: .infinity)
            
            Divider()
            
            // Right Pane: Recent Projects
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Recent Projects")
                        .font(.headline)
                    Spacer()
                    if !workspace.recentProjects.isEmpty {
                        Button("Clear") {
                            workspace.clearRecents()
                        }
                        .buttonStyle(.borderless)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                
                if workspace.recentProjects.isEmpty {
                    VStack(spacing: 8) {
                        Spacer()
                        Image(systemName: "clock")
                            .font(.system(size: 28))
                            .foregroundStyle(.quaternary)
                        Text("No Recent Workspaces")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(workspace.recentProjects, id: \.self) { url in
                                Button(action: {
                                    workspace.openFolder(url: url)
                                }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "folder.fill")
                                            .foregroundStyle(.blue)
                                            .font(.title3)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(url.lastPathComponent)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .lineLimit(1)
                                            
                                            Text(url.deletingLastPathComponent().path)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                                .truncationMode(.middle)
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(24)
            .frame(width: 320)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.25))
        }
        .frame(minWidth: 760, minHeight: 460)
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(isTargetedForDrop ? Color.accentColor : Color.clear, lineWidth: 3)
        )
        .onDrop(of: [.fileURL], isTargeted: $isTargetedForDrop) { providers in
            handleDrop(providers: providers)
        }
        .sheet(isPresented: $showingNewProjectSheet) {
            NewProjectSheetView(workspace: workspace, isPresented: $showingNewProjectSheet)
        }
    }
    
    private func openProjectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Open Folder"
        panel.message = "Choose a project directory to open in Ratex Editor"
        
        if panel.runModal() == .OK, let url = panel.url {
            workspace.openFolder(url: url)
        }
    }
    
    private func openSingleDocument() {
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
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        _ = provider.loadObject(ofClass: URL.self) { url, _ in
            guard let url = url else { return }
            DispatchQueue.main.async {
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) {
                    if isDir.boolValue {
                        self.workspace.openFolder(url: url)
                    } else {
                        self.workspace.openSingleDocument(url: url)
                    }
                }
            }
        }
        return true
    }
}

// Button row on the Welcome Screen
struct WelcomeActionButton: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let shortcut: String
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(iconColor)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(title)
                            .font(.system(size: 14, weight: .semibold))
                        Spacer()
                        Text(shortcut)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(.tertiary)
                    }
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(isHovered ? Color(nsColor: .controlAccentColor).opacity(0.12) : Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isHovered ? Color.accentColor.opacity(0.4) : Color.gray.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// Modal sheet to create a new project
struct NewProjectSheetView: View {
    let workspace: WorkspaceModel
    @Binding var isPresented: Bool
    
    @State private var projectName = "MyLaTeXProject"
    @State private var selectedParentDir: URL? = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    @State private var selectedTemplate = TeXTemplate.article
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Create New LaTeX Project")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Project Name:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Project Name", text: $projectName)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Location:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Text(selectedParentDir?.path ?? "Choose Location…")
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Button("Browse…") {
                        let panel = NSOpenPanel()
                        panel.canChooseFiles = false
                        panel.canChooseDirectories = true
                        panel.canCreateDirectories = true
                        if panel.runModal() == .OK {
                            selectedParentDir = panel.url
                        }
                    }
                    .controlSize(.small)
                }
                .padding(8)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(6)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Starter Template:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Template", selection: $selectedTemplate) {
                    ForEach(TeXTemplate.all) { tmpl in
                        Text(tmpl.name).tag(tmpl)
                    }
                }
                .pickerStyle(.menu)
            }
            
            Divider()
            
            HStack {
                Spacer()
                Button("Cancel") { isPresented = false }
                    .keyboardShortcut(.cancelAction)
                Button("Create & Open") {
                    if let parent = selectedParentDir {
                        _ = workspace.createProject(
                            at: parent,
                            projectName: projectName,
                            templateSource: selectedTemplate.source
                        )
                        isPresented = false
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedParentDir == nil)
            }
        }
        .padding(22)
        .frame(width: 440)
    }
}

