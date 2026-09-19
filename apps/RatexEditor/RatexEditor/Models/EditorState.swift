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
    public var selectedRange: NSRange = NSRange(location: 0, length: 0)
    
    // Debouncer Task
    @ObservationIgnored
    private var compileTask: Task<Void, Never>? = nil
    
    // Text mutation closure hook (communicates with NSTextView)
    @ObservationIgnored
    public var textModifier: ((_ insert: String?, _ wrapPrefix: String?, _ wrapSuffix: String?, _ placeholder: String?) -> Void)? = nil
    
    public init(source: String) {
        self.source = source
        // Initial compilation
        Task { @MainActor in
            await self.compileImmediate()
        }
    }
    
    public func scheduleCompilation() {
        compileTask?.cancel()
        compileTask = Task { @MainActor in
            // 150ms debounce
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard !Task.isCancelled else { return }
            await self.compileImmediate()
        }
    }
    
    @MainActor
    public func compileImmediate() async {
        isCompiling = true
        let currentSource = self.source
        
        let result = await RatexEngine.shared.compile(source: currentSource)
        
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

