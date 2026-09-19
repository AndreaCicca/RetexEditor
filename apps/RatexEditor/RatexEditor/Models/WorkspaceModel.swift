import SwiftUI
import Observation

public struct FileNode: Identifiable, Hashable, Sendable {
    public var id: String { url.path }
    public let url: URL
    public let name: String
    public let isDirectory: Bool
    public var children: [FileNode]?
    
    public init(url: URL, isDirectory: Bool, children: [FileNode]? = nil) {
        self.url = url
        self.name = url.lastPathComponent
        self.isDirectory = isDirectory
        self.children = children
    }
    
    public var systemIcon: String {
        if isDirectory {
            return "folder.fill"
        }
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "tex", "ltx":
            return "doc.text.fill"
        case "cls", "sty":
            return "gearshape.fill"
        case "bib":
            return "books.vertical.fill"
        case "png", "jpg", "jpeg", "pdf", "svg":
            return "photo.fill"
        case "tikz":
            return "pencil.and.ruler.fill"
        case "csv", "dat":
            return "tablecells.fill"
        default:
            return "doc.fill"
        }
    }
    
    public var iconColor: Color {
        if isDirectory {
            return .accentColor
        }
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "tex", "ltx":
            return .blue
        case "cls", "sty":
            return .purple
        case "bib":
            return .orange
        case "png", "jpg", "jpeg", "pdf", "svg":
            return .green
        case "tikz":
            return .teal
        case "csv", "dat":
            return .indigo
        default:
            return .secondary
        }
    }
}

@Observable
public final class WorkspaceModel {
    public var rootDirectory: URL? = nil {
        didSet {
            if let root = rootDirectory {
                addToRecent(url: root)
            }
            refreshTree()
        }
    }
    
    public var fileTree: [FileNode] = []
    public var allTexFiles: [URL] = []
    public var selectedFileURL: URL? = nil
    public var entryPointURL: URL? = nil
    
    // Recent workspaces persisted in UserDefaults
    public var recentProjects: [URL] = []
    
    // Active file text cache for autosave
    @ObservationIgnored
    private var saveTask: Task<Void, Never>? = nil
    
    public init() {
        loadRecents()
    }
    
    // MARK: - Open Actions
    
    public func openFolder(url: URL) {
        self.entryPointURL = nil
        self.selectedFileURL = nil
        self.rootDirectory = url.standardizedFileURL
    }
    
    public func openSingleDocument(url: URL) {
        let parentDir = url.deletingLastPathComponent()
        self.entryPointURL = nil
        self.selectedFileURL = url.standardizedFileURL
        self.rootDirectory = parentDir.standardizedFileURL
    }
    
    public func closeWorkspace() {
        self.rootDirectory = nil
        self.fileTree = []
        self.allTexFiles = []
        self.selectedFileURL = nil
        self.entryPointURL = nil
    }
    
    // MARK: - File Tree & Indexing
    
    public func refreshTree() {
        guard let root = rootDirectory else {
            fileTree = []
            allTexFiles = []
            selectedFileURL = nil
            entryPointURL = nil
            return
        }
        
        let (tree, texList) = scanDirectory(url: root)
        self.fileTree = tree
        self.allTexFiles = texList
        
        // Validate entrypoint: if set to a non-existent file, reset to active document mode
        if let entry = entryPointURL, !FileManager.default.fileExists(atPath: entry.path) {
            self.entryPointURL = nil
        }
        
        // Validate selected file
        if let sel = selectedFileURL, !FileManager.default.fileExists(atPath: sel.path) {
            self.selectedFileURL = nil
            autoSelectInitialFile()
        } else if selectedFileURL == nil {
            autoSelectInitialFile()
        }
    }
    
    private func scanDirectory(url: URL) -> ([FileNode], [URL]) {
        let fileManager = FileManager.default
        guard let contents = try? fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return ([], [])
        }
        
        var nodes: [FileNode] = []
        var texFiles: [URL] = []
        
        let ignoredFolders: Set<String> = [".git", "build", "target", ".venv", "__pycache__", "node_modules"]
        
        for item in contents.sorted(by: { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }) {
            let itemName = item.lastPathComponent
            if ignoredFolders.contains(itemName) { continue }
            
            var isDir: ObjCBool = false
            if fileManager.fileExists(atPath: item.path, isDirectory: &isDir) {
                if isDir.boolValue {
                    let (subNodes, subTex) = scanDirectory(url: item)
                    nodes.append(FileNode(url: item, isDirectory: true, children: subNodes))
                    texFiles.append(contentsOf: subTex)
                } else {
                    nodes.append(FileNode(url: item, isDirectory: false))
                    let ext = item.pathExtension.lowercased()
                    if ext == "tex" || ext == "ltx" {
                        texFiles.append(item)
                    }
                }
            }
        }
        
        // Sort folders first, then files alphabetically
        nodes.sort {
            if $0.isDirectory != $1.isDirectory {
                return $0.isDirectory && !$1.isDirectory
            }
            return $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
        
        return (nodes, texFiles)
    }
    
    public func autoSelectInitialFile() {
        guard !allTexFiles.isEmpty else { return }
        if let sel = selectedFileURL, FileManager.default.fileExists(atPath: sel.path) {
            return
        }
        
        // Priority heuristics: Tesi.tex, main.tex, index.tex, or first root .tex
        if let tesi = allTexFiles.first(where: { $0.lastPathComponent.lowercased() == "tesi.tex" }) {
            selectedFileURL = tesi
        } else if let main = allTexFiles.first(where: { $0.lastPathComponent.lowercased() == "main.tex" }) {
            selectedFileURL = main
        } else if let rootTex = allTexFiles.first(where: { $0.deletingLastPathComponent().standardizedFileURL == rootDirectory?.standardizedFileURL }) {
            selectedFileURL = rootTex
        } else {
            selectedFileURL = allTexFiles.first
        }
    }
    
    // MARK: - File CRUD Operations
    
    public func createFile(name: String, inDirectory: URL, initialContent: String = "") -> URL? {
        var fileName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !fileName.contains(".") {
            fileName.append(".tex")
        }
        let targetURL = inDirectory.appendingPathComponent(fileName)
        
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: targetURL.path) {
            return nil
        }
        
        guard let data = initialContent.data(using: .utf8) else { return nil }
        if fileManager.createFile(atPath: targetURL.path, contents: data) {
            refreshTree()
            self.selectedFileURL = targetURL
            return targetURL
        }
        return nil
    }
    
    public func createFolder(name: String, inDirectory: URL) -> URL? {
        let folderName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !folderName.isEmpty else { return nil }
        let targetURL = inDirectory.appendingPathComponent(folderName)
        
        do {
            try FileManager.default.createDirectory(at: targetURL, withIntermediateDirectories: true)
            refreshTree()
            return targetURL
        } catch {
            return nil
        }
    }
    
    public func renameItem(at url: URL, newName: String) -> Bool {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let destination = url.deletingLastPathComponent().appendingPathComponent(trimmed)
        
        do {
            try FileManager.default.moveItem(at: url, to: destination)
            if selectedFileURL == url {
                selectedFileURL = destination
            }
            if entryPointURL == url {
                entryPointURL = destination
            }
            refreshTree()
            return true
        } catch {
            return false
        }
    }
    
    public func deleteItem(at url: URL) -> Bool {
        do {
            try FileManager.default.trashItem(at: url, resultingItemURL: nil)
            if selectedFileURL == url {
                selectedFileURL = nil
                autoSelectInitialFile()
            }
            if entryPointURL == url {
                entryPointURL = nil
            }
            refreshTree()
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Path Helpers
    
    public func relativePath(for url: URL) -> String {
        guard let root = rootDirectory else { return url.lastPathComponent }
        let rootPath = root.standardizedFileURL.path
        let filePath = url.standardizedFileURL.path
        if filePath.hasPrefix(rootPath) {
            var rel = String(filePath.dropFirst(rootPath.count))
            if rel.hasPrefix("/") {
                rel.removeFirst()
            }
            return rel.isEmpty ? url.lastPathComponent : rel
        }
        return url.lastPathComponent
    }
    
    public func isTextEditable(url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        let textExtensions: Set<String> = [
            "tex", "ltx", "cls", "sty", "bib", "tikz", "txt", "md",
            "log", "aux", "bbl", "blg", "cfg", "def", "clo", "csv", "json"
        ]
        return textExtensions.contains(ext)
    }
    
    // MARK: - Project Creation
    
    public func createProject(at parentDirectory: URL, projectName: String, templateSource: String? = nil) -> URL? {
        let trimmed = projectName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let projectDir = parentDirectory.appendingPathComponent(trimmed, isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)
            let mainTex = projectDir.appendingPathComponent("main.tex")
            let initialContent = templateSource ?? TeXTemplate.article.source
            try initialContent.write(to: mainTex, atomically: true, encoding: .utf8)
            self.openFolder(url: projectDir)
            self.entryPointURL = nil
            self.selectedFileURL = mainTex
            return projectDir
        } catch {
            return nil
        }
    }
    
    // MARK: - Autosave Current Document
    
    public func saveActiveFile(content: String) {
        guard let url = selectedFileURL else { return }
        saveTask?.cancel()
        saveTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            try? content.write(to: url, atomically: true, encoding: .utf8)
        }
    }
    
    public func flushSaveNow(content: String, for url: URL? = nil) {
        guard let target = url ?? selectedFileURL else { return }
        saveTask?.cancel()
        try? content.write(to: target, atomically: true, encoding: .utf8)
    }
    
    // MARK: - Recents Persistence
    
    public func clearRecents() {
        recentProjects = []
        UserDefaults.standard.removeObject(forKey: "RatexRecentProjects")
    }
    
    private func loadRecents() {
        if let paths = UserDefaults.standard.stringArray(forKey: "RatexRecentProjects") {
            recentProjects = paths.map { URL(fileURLWithPath: $0) }.filter { FileManager.default.fileExists(atPath: $0.path) }
        }
    }
    
    private func addToRecent(url: URL) {
        var recents = recentProjects.filter { $0.path != url.path }
        recents.insert(url, at: 0)
        if recents.count > 10 {
            recents = Array(recents.prefix(10))
        }
        recentProjects = recents
        UserDefaults.standard.set(recents.map { $0.path }, forKey: "RatexRecentProjects")
    }
}
