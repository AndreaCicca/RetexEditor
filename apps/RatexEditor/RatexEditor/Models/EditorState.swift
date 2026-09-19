import SwiftUI
import Observation
import PDFKit

@Observable
public final class EditorState {
    // Document source
    public var source: String {
        didSet {
            scheduleCompilation()
        }
    }
    
    // Compilation & Output state
    public var pdfData: Data? = nil
    public var isCompiling: Bool = false
    public var lastStatus: RatexStatus = .success
    public var lastDurationMs: Double = 0
    public var lastPasses: Int = 0
    public var diagnostics: String = ""
    public var log: String = ""
    public var lastCompiledDate: Date? = nil
    
    // UI state
    public var isDiagnosticsDrawerOpen: Bool = false
    public var isMathPaletteOpen: Bool = false
    public var zoomScale: CGFloat = 1.0
    public var editorFontSize: CGFloat = 13.5
    
    @ObservationIgnored
    public var selectedRange: NSRange = NSRange(location: 0, length: 0)
    
    // Debouncer Task
    @ObservationIgnored
    private var compileTask: Task<Void, Never>? = nil
    
    // Project & File state
    public var documentURL: URL? = nil {
        didSet {
            scheduleCompilation()
        }
    }
    public var entryPointURL: URL? = nil {
        didSet {
            scheduleCompilation()
        }
    }
    public var customProjectDirectory: URL? = nil {
        didSet {
            scheduleCompilation()
        }
    }
    public var projectDirectory: URL? {
        customProjectDirectory ?? documentURL?.deletingLastPathComponent()
    }
    
    // Text mutation closure hook (communicates with NSTextView)
    @ObservationIgnored
    public var textModifier: ((_ insert: String?, _ wrapPrefix: String?, _ wrapSuffix: String?, _ placeholder: String?) -> Void)? = nil
    
    // Text full replacement closure hook with Undo support (communicates with NSTextView)
    @ObservationIgnored
    public var textReplacer: ((_ newText: String) -> Void)? = nil
    
    public init(source: String, documentURL: URL? = nil, entryPointURL: URL? = nil) {
        self.source = source
        self.documentURL = documentURL
        self.entryPointURL = entryPointURL
        // Initial compilation
        Task { @MainActor in
            await self.compileImmediate()
        }
    }
    
    public func scheduleCompilation() {
        compileTask?.cancel()
        compileTask = Task { @MainActor in
            // 350ms debounce for smooth typing without premature recompilations
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            await self.compileImmediate()
        }
    }
    
    @MainActor
    public func compileImmediate() async {
        isCompiling = true
        let dir = self.projectDirectory
        
        let targetEntryURL = entryPointURL ?? documentURL
        
        // If target file is not a TeX file (e.g. bib, sty, png), do not invoke ratex engine as root entry
        if let target = targetEntryURL {
            let ext = target.pathExtension.lowercased()
            if !["tex", "ltx"].contains(ext) {
                isCompiling = false
                return
            }
        }
        
        let entryFilename = targetEntryURL?.lastPathComponent ?? "main.tex"
        
        // Determine what source text to compile as entrypoint
        let entrySource: String
        let isEditingEntry = (documentURL == nil || targetEntryURL == nil || documentURL?.standardizedFileURL == targetEntryURL?.standardizedFileURL)
        
        if isEditingEntry {
            entrySource = self.source
        } else if let targetURL = targetEntryURL, let diskSource = try? String(contentsOf: targetURL, encoding: .utf8) {
            entrySource = diskSource
        } else {
            entrySource = self.source
        }
        
        var additionalFiles: [String: Data]
        if let dir = dir {
            additionalFiles = await Task.detached(priority: .userInitiated) {
                EditorState.loadProjectFiles(from: dir, excludingEntry: entryFilename)
            }.value
        } else {
            additionalFiles = [:]
        }
        
        // If editing a sub-file (not the entrypoint), inject the active editor buffer into additionalFiles
        if !isEditingEntry, let docURL = documentURL, let dir = dir {
            let docPath = docURL.standardizedFileURL.path
            let dirPath = dir.standardizedFileURL.path
            if docPath.hasPrefix(dirPath) {
                var rel = String(docPath.dropFirst(dirPath.count))
                if rel.hasPrefix("/") { rel.removeFirst() }
                if let utf8Data = self.source.data(using: .utf8) {
                    additionalFiles[rel] = utf8Data
                    additionalFiles[docURL.lastPathComponent] = utf8Data
                }
            }
        }
        
        // Auto-inject bundled babel italian.ldf for Italian documents
        if additionalFiles["italian.ldf"] == nil {
            if let bundleLdf = Bundle.main.url(forResource: "italian", withExtension: "ldf"),
               let data = try? Data(contentsOf: bundleLdf) {
                additionalFiles["italian.ldf"] = data
            } else {
                let devPath = URL(fileURLWithPath: #filePath)
                    .deletingLastPathComponent()
                    .deletingLastPathComponent()
                    .appendingPathComponent("Resources/italian.ldf")
                if let data = try? Data(contentsOf: devPath) {
                    additionalFiles["italian.ldf"] = data
                }
            }
        }
        
        let result = await RatexEngine.shared.compile(
            source: entrySource,
            filename: entryFilename,
            additionalFiles: additionalFiles
        )
        
        guard !Task.isCancelled else { return }
        
        self.isCompiling = false
        self.lastStatus = result.status
        self.lastDurationMs = result.durationMs
        self.lastPasses = result.passes
        self.diagnostics = result.diagnostics
        self.log = result.log
        self.lastCompiledDate = result.timestamp
        
        if result.isSuccess, let newPdf = result.pdfData {
            self.pdfData = newPdf
        }
    }
    
    public static func loadProjectFiles(from directoryURL: URL, excludingEntry: String = "main.tex") -> [String: Data] {
        var files: [String: Data] = [:]
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return files
        }
        
        let ignoredExtensions: Set<String> = [
            "aux", "log", "out", "toc", "nav", "snm", "vrb", "pyc", "dylib", "so", "lock", "py", "sh"
        ]
        
        let baseStandardized = directoryURL.standardizedFileURL.path
        
        for case let fileURL as URL in enumerator {
            let ext = fileURL.pathExtension.lowercased()
            if ignoredExtensions.contains(ext) { continue }
            
            let pathComponents = fileURL.pathComponents
            if pathComponents.contains(".git") || pathComponents.contains("build") || pathComponents.contains("target") || pathComponents.contains(".venv") || pathComponents.contains("__pycache__") {
                continue
            }
            
            let fullPath = fileURL.standardizedFileURL.path
            guard fullPath.hasPrefix(baseStandardized) else { continue }
            
            var relativePath = String(fullPath.dropFirst(baseStandardized.count))
            if relativePath.hasPrefix("/") {
                relativePath.removeFirst()
            }
            
            if relativePath == excludingEntry || fileURL.lastPathComponent == excludingEntry {
                continue
            }
            
            // Limit to 30MB per asset to avoid memory exhaustion
            if let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
               let size = values.fileSize, size < 30 * 1024 * 1024 {
                if let data = try? Data(contentsOf: fileURL) {
                    files[relativePath] = data
                }
            }
        }
        
        return files
    }
    
    // MARK: - WYSIWYG Actions
    
    public func applyBold() {
        wrapSelection(prefix: "\\textbf{", suffix: "}", placeholder: String(localized: "bold text"))
    }
    
    public func applyItalic() {
        wrapSelection(prefix: "\\textit{", suffix: "}", placeholder: String(localized: "italic text"))
    }
    
    public func applyCode() {
        wrapSelection(prefix: "\\texttt{", suffix: "}", placeholder: String(localized: "code"))
    }
    
    public func applyUnderline() {
        wrapSelection(prefix: "\\underline{", suffix: "}", placeholder: String(localized: "underlined text"))
    }
    
    public func insertHeading(level: Int) {
        switch level {
        case 1:
            wrapSelection(prefix: "\\section{", suffix: "}", placeholder: String(localized: "Section Title"))
        case 2:
            wrapSelection(prefix: "\\subsection{", suffix: "}", placeholder: String(localized: "Subsection Title"))
        case 3:
            wrapSelection(prefix: "\\subsubsection{", suffix: "}", placeholder: String(localized: "Subsubsection Title"))
        default:
            wrapSelection(prefix: "\\paragraph{", suffix: "}", placeholder: String(localized: "Paragraph Title"))
        }
    }
    
    public func insertInlineMath() {
        wrapSelection(prefix: "$", suffix: "$", placeholder: "x")
    }
    
    public func insertDisplayMath() {
        wrapSelection(prefix: "\\[\n", suffix: "\n\\]", placeholder: "f(x) = \\dots")
    }
    
    public func insertFraction() {
        wrapSelection(prefix: "\\frac{", suffix: "}{\(String(localized: "denominator"))}", placeholder: String(localized: "numerator"))
    }
    
    public func insertSqrt() {
        wrapSelection(prefix: "\\sqrt{", suffix: "}", placeholder: "x")
    }
    
    public func insertBulletList() {
        insertText("""
\\begin{itemize}
    \\item First item
    \\item Second item
\\end{itemize}
""")
    }
    
    public func insertNumberedList() {
        insertText("""
\\begin{enumerate}
    \\item First item
    \\item Second item
\\end{enumerate}
""")
    }
    
    public func insertTable() {
        insertText("""
\\begin{center}
\\begin{tabular}{|l|c|r|}
\\hline
\\textbf{Col 1} & \\textbf{Col 2} & \\textbf{Col 3} \\\\
\\hline
Data A & 123 & 45.6 \\\\
Data B & 789 & 0.12 \\\\
\\hline
\\end{tabular}
\\end{center}
""")
    }
    
    public func insertFigure() {
        insertText("""
\\begin{figure}[htbp]
\\centering
% Replace with your figure/tikz/image
\\fbox{\\rule{0pt}{2in} \\rule{0.9\\linewidth}{0pt}}
\\caption{Sample figure caption}
\\label{fig:sample}
\\end{figure}
""")
    }
    
    public func insertMatrix() {
        insertText("""
\\begin{pmatrix}
a & b \\\\
c & d
\\end{pmatrix}
""")
    }
    
    public func insertSymbol(_ symbol: String) {
        insertText(symbol)
    }
    
    // MARK: - Text Modification Helpers
    
    public func insertText(_ text: String) {
        if let modifier = textModifier {
            modifier(text, nil, nil, nil)
        } else {
            // Fallback: append
            self.source.append("\n" + text)
        }
    }
    
    public func wrapSelection(prefix: String, suffix: String, placeholder: String) {
        if let modifier = textModifier {
            modifier(nil, prefix, suffix, placeholder)
        } else {
            self.source.append("\n\(prefix)\(placeholder)\(suffix)")
        }
    }
    
    public func setSourceWithUndo(_ newText: String) {
        if let replacer = textReplacer {
            replacer(newText)
        } else {
            self.source = newText
        }
    }
    
    // MARK: - Text Zoom Helpers
    
    public func increaseFontSize() {
        editorFontSize = min(36.0, editorFontSize + 1.5)
    }
    
    public func decreaseFontSize() {
        editorFontSize = max(9.0, editorFontSize - 1.5)
    }
    
    public func resetFontSize() {
        editorFontSize = 13.5
    }
}

