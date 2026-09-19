import SwiftUI
import AppKit

public struct ProjectSidebarView: View {
    @Bindable var workspace: WorkspaceModel
    var onSelectFile: (URL) -> Void
    
    // Modal & Sheet state
    @State private var showingNewFileSheet = false
    @State private var showingNewFolderSheet = false
    @State private var showingRenameSheet = false
    @State private var showingDeleteAlert = false
    
    @State private var targetParentDirectory: URL? = nil
    @State private var targetItemToRename: URL? = nil
    @State private var targetItemToDelete: URL? = nil
    
    @State private var inputName: String = ""
    
    public init(workspace: WorkspaceModel, onSelectFile: @escaping (URL) -> Void) {
        self.workspace = workspace
        self.onSelectFile = onSelectFile
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Sidebar Header
            HStack(spacing: 6) {
                Image(systemName: "folder.fill")
                    .foregroundStyle(Color.accentColor)
                Text(workspace.rootDirectory?.lastPathComponent ?? "Project")
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Spacer()
                
                // Actions Menu
                Menu {
                    Button(action: {
                        targetParentDirectory = workspace.rootDirectory
                        inputName = ""
                        showingNewFileSheet = true
                    }) {
                        Label("New File…", systemImage: "doc.badge.plus")
                    }
                    
                    Button(action: {
                        targetParentDirectory = workspace.rootDirectory
                        inputName = ""
                        showingNewFolderSheet = true
                    }) {
                        Label("New Folder…", systemImage: "folder.badge.plus")
                    }
                    
                    Divider()
                    
                    Button(action: {
                        workspace.refreshTree()
                    }) {
                        Label("Refresh Tree", systemImage: "arrow.clockwise")
                    }
                    
                    if let root = workspace.rootDirectory {
                        Button(action: {
                            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: root.path)
                        }) {
                            Label("Reveal in Finder", systemImage: "macwindow")
                        }
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: {
                        workspace.closeWorkspace()
                    }) {
                        Label("Close Project", systemImage: "xmark.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 14))
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
            
            Divider()
            
            // File Tree List
            if workspace.fileTree.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "folder")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text("Empty Directory")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Create main.tex") {
                        if let root = workspace.rootDirectory {
                            _ = workspace.createFile(name: "main.tex", inDirectory: root, initialContent: TeXTemplate.article.source)
                        }
                    }
                    .controlSize(.small)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(workspace.fileTree) { node in
                        FileTreeNodeRow(
                            node: node,
                            workspace: workspace,
                            onSelectFile: onSelectFile,
                            onNewFile: { dir in
                                targetParentDirectory = dir
                                inputName = ""
                                showingNewFileSheet = true
                            },
                            onNewFolder: { dir in
                                targetParentDirectory = dir
                                inputName = ""
                                showingNewFolderSheet = true
                            },
                            onRename: { url in
                                targetItemToRename = url
                                inputName = url.lastPathComponent
                                showingRenameSheet = true
                            },
                            onDelete: { url in
                                targetItemToDelete = url
                                showingDeleteAlert = true
                            }
                        )
                    }
                }
                .listStyle(.sidebar)
            }
            
            Divider()
            
            // Bottom bar: Project entrypoint info & quick actions
            HStack(spacing: 6) {
                Image(systemName: "play.circle.fill")
                    .foregroundStyle(.blue)
                    .font(.caption)
                Text(workspace.entryPointURL?.lastPathComponent ?? "No Entry")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                Button(action: {
                    targetParentDirectory = workspace.rootDirectory
                    inputName = ""
                    showingNewFileSheet = true
                }) {
                    Image(systemName: "plus")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .help("New File in Project Root")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))
        }
        // New File Sheet
        .sheet(isPresented: $showingNewFileSheet) {
            VStack(alignment: .leading, spacing: 14) {
                Text("New Document")
                    .font(.headline)
                
                Text("Create file inside: \(targetParentDirectory?.lastPathComponent ?? "Project")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                TextField("File name (e.g. chapter_1.tex)", text: $inputName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { createNewFileAction() }
                
                HStack {
                    Spacer()
                    Button("Cancel") { showingNewFileSheet = false }
                        .keyboardShortcut(.cancelAction)
                    Button("Create") { createNewFileAction() }
                        .keyboardShortcut(.defaultAction)
                        .disabled(inputName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding()
            .frame(width: 320)
        }
        // New Folder Sheet
        .sheet(isPresented: $showingNewFolderSheet) {
            VStack(alignment: .leading, spacing: 14) {
                Text("New Folder")
                    .font(.headline)
                
                Text("Create folder inside: \(targetParentDirectory?.lastPathComponent ?? "Project")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                TextField("Folder name", text: $inputName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { createNewFolderAction() }
                
                HStack {
                    Spacer()
                    Button("Cancel") { showingNewFolderSheet = false }
                        .keyboardShortcut(.cancelAction)
                    Button("Create") { createNewFolderAction() }
                        .keyboardShortcut(.defaultAction)
                        .disabled(inputName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding()
            .frame(width: 320)
        }
        // Rename Sheet
        .sheet(isPresented: $showingRenameSheet) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Rename Item")
                    .font(.headline)
                
                Text("Current name: \(targetItemToRename?.lastPathComponent ?? "")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                TextField("New name", text: $inputName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { renameItemAction() }
                
                HStack {
                    Spacer()
                    Button("Cancel") { showingRenameSheet = false }
                        .keyboardShortcut(.cancelAction)
                    Button("Rename") { renameItemAction() }
                        .keyboardShortcut(.defaultAction)
                        .disabled(inputName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding()
            .frame(width: 320)
        }
        // Delete Confirmation Alert
        .alert("Delete Item?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Move to Trash", role: .destructive) {
                if let target = targetItemToDelete {
                    _ = workspace.deleteItem(at: target)
                }
            }
        } message: {
            Text("Are you sure you want to move \"\(targetItemToDelete?.lastPathComponent ?? "this item")\" to the Trash?")
        }
    }
    
    private func createNewFileAction() {
        guard let dir = targetParentDirectory ?? workspace.rootDirectory else { return }
        let name = inputName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        if let createdURL = workspace.createFile(name: name, inDirectory: dir) {
            onSelectFile(createdURL)
        }
        showingNewFileSheet = false
    }
    
    private func createNewFolderAction() {
        guard let dir = targetParentDirectory ?? workspace.rootDirectory else { return }
        let name = inputName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        _ = workspace.createFolder(name: name, inDirectory: dir)
        showingNewFolderSheet = false
    }
    
    private func renameItemAction() {
        guard let item = targetItemToRename else { return }
        let newName = inputName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !newName.isEmpty else { return }
        _ = workspace.renameItem(at: item, newName: newName)
        showingRenameSheet = false
    }
}

// Recursive row for file hierarchy
struct FileTreeNodeRow: View {
    let node: FileNode
    let workspace: WorkspaceModel
    let onSelectFile: (URL) -> Void
    let onNewFile: (URL) -> Void
    let onNewFolder: (URL) -> Void
    let onRename: (URL) -> Void
    let onDelete: (URL) -> Void
    
    var isSelected: Bool {
        workspace.selectedFileURL == node.url
    }
    
    var isEntryPoint: Bool {
        workspace.entryPointURL == node.url
    }
    
    var body: some View {
        if node.isDirectory {
            DisclosureGroup {
                if let children = node.children {
                    ForEach(children) { child in
                        FileTreeNodeRow(
                            node: child,
                            workspace: workspace,
                            onSelectFile: onSelectFile,
                            onNewFile: onNewFile,
                            onNewFolder: onNewFolder,
                            onRename: onRename,
                            onDelete: onDelete
                        )
                    }
                }
            } label: {
                rowLabel
            }
            .contextMenu {
                directoryContextMenu
            }
        } else {
            Button(action: {
                if workspace.isTextEditable(url: node.url) {
                    onSelectFile(node.url)
                }
            }) {
                rowLabel
            }
            .buttonStyle(.plain)
            .listRowBackground(isSelected ? Color.accentColor.opacity(0.18) : Color.clear)
            .contextMenu {
                fileContextMenu
            }
        }
    }
    
    private var rowLabel: some View {
        HStack(spacing: 6) {
            Image(systemName: node.systemIcon)
                .foregroundStyle(node.iconColor)
                .frame(width: 16)
            
            Text(node.name)
                .font(.system(size: 12))
                .lineLimit(1)
                .foregroundStyle(isSelected ? Color.primary : (node.isDirectory ? .primary : .secondary))
            
            Spacer()
            
            if isEntryPoint {
                Text("Entry")
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(4)
            }
        }
        .contentShape(Rectangle())
    }
    
    @ViewBuilder
    private var directoryContextMenu: some View {
        Button(action: { onNewFile(node.url) }) {
            Label("New File Here…", systemImage: "doc.badge.plus")
        }
        Button(action: { onNewFolder(node.url) }) {
            Label("New Folder Here…", systemImage: "folder.badge.plus")
        }
        Divider()
        Button(action: { onRename(node.url) }) {
            Label("Rename…", systemImage: "pencil")
        }
        Button(role: .destructive, action: { onDelete(node.url) }) {
            Label("Delete", systemImage: "trash")
        }
        Divider()
        Button(action: {
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: node.url.path)
        }) {
            Label("Reveal in Finder", systemImage: "macwindow")
        }
    }
    
    @ViewBuilder
    private var fileContextMenu: some View {
        let ext = node.url.pathExtension.lowercased()
        if ext == "tex" || ext == "ltx" {
            Button(action: {
                workspace.entryPointURL = node.url
            }) {
                Label("Set as Project Entry Point", systemImage: "play.circle")
            }
            Divider()
        }
        
        Button(action: {
            onNewFile(node.url.deletingLastPathComponent())
        }) {
            Label("New File Beside…", systemImage: "doc.badge.plus")
        }
        
        Button(action: { onRename(node.url) }) {
            Label("Rename…", systemImage: "pencil")
        }
        
        Button(role: .destructive, action: { onDelete(node.url) }) {
            Label("Delete", systemImage: "trash")
        }
        
        Divider()
        
        Button(action: {
            NSWorkspace.shared.activateFileViewerSelecting([node.url])
        }) {
            Label("Reveal in Finder", systemImage: "macwindow")
        }
    }
}
