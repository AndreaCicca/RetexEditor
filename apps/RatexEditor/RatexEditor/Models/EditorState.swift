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
    
    public init(source: String, documentURL: URL? = nil) {
        self.source = source
        self.documentURL = documentURL
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
        let currentSource = self.source
        let entryFilename = documentURL?.lastPathComponent ?? "main.tex"
        let dir = self.projectDirectory
        
        let additionalFiles: [String: Data]
        if let dir = dir {
            additionalFiles = await Task.detached(priority: .userInitiated) {
                EditorState.loadProjectFiles(from: dir, excludingEntry: entryFilename)
            }.value
        } else {
            additionalFiles = [:]
        }
        
        let result = await RatexEngine.shared.compile(
            source: currentSource,
            filename: entryFilename,
            additionalFiles: additionalFiles
        )
        
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
        
        let allowedExtensions: Set<String> = [
            "tex", "cls", "sty", "bib", "bst", "bbl", "def", "clo", "cfg",
            "png", "jpg", "jpeg", "pdf", "svg", "eps", "txt", "dat", "csv"
        ]
        
        let baseStandardized = directoryURL.standardizedFileURL.path
        
        for case let fileURL as URL in enumerator {
            let ext = fileURL.pathExtension.lowercased()
            guard allowedExtensions.contains(ext) else { continue }
            
            let pathComponents = fileURL.pathComponents
            if pathComponents.contains(".git") || pathComponents.contains("build") || pathComponents.contains("target") {
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
            
            // Limit to 20MB per asset to avoid memory exhaustion
            if let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
               let size = values.fileSize, size < 20 * 1024 * 1024 {
                if let data = try? Data(contentsOf: fileURL) {
                    files[relativePath] = data
                }
            }
        }
        
        return files
    }
    
    // MARK: - WYSIWYG Actions
    
    public func applyBold() {
        wrapSelection(prefix: "\\textbf{", suffix: "}", placeholder: "bold text")
    }
    
    public func applyItalic() {
        wrapSelection(prefix: "\\textit{", suffix: "}", placeholder: "italic text")
    }
    
    public func applyCode() {
        wrapSelection(prefix: "\\texttt{", suffix: "}", placeholder: "code")
    }
    
    public func applyUnderline() {
        wrapSelection(prefix: "\\underline{", suffix: "}", placeholder: "underlined text")
    }
    
    public func insertHeading(level: Int) {
        switch level {
        case 1:
            wrapSelection(prefix: "\\section{", suffix: "}", placeholder: "Section Title")
        case 2:
            wrapSelection(prefix: "\\subsection{", suffix: "}", placeholder: "Subsection Title")
        case 3:
            wrapSelection(prefix: "\\subsubsection{", suffix: "}", placeholder: "Subsubsection Title")
        default:
            wrapSelection(prefix: "\\paragraph{", suffix: "}", placeholder: "Paragraph Title")
        }
    }
    
    public func insertInlineMath() {
        wrapSelection(prefix: "$", suffix: "$", placeholder: "x")
    }
    
    public func insertDisplayMath() {
        wrapSelection(prefix: "\\[\n", suffix: "\n\\]", placeholder: "f(x) = \\dots")
    }
    
    public func insertFraction() {
        wrapSelection(prefix: "\\frac{", suffix: "}{denominator}", placeholder: "numerator")
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
}

