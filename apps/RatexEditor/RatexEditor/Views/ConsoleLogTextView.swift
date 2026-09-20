import SwiftUI
import AppKit

public struct ConsoleLogTextView: NSViewRepresentable {
    let text: String
    let isDiagnostics: Bool
    let fontSize: CGFloat
    let isWrapEnabled: Bool
    let searchQuery: String
    let onNavigateToLine: ((Int) -> Void)?
    
    public init(
        text: String,
        isDiagnostics: Bool = true,
        fontSize: CGFloat = 12.0,
        isWrapEnabled: Bool = true,
        searchQuery: String = "",
        onNavigateToLine: ((Int) -> Void)? = nil
    ) {
        self.text = text
        self.isDiagnostics = isDiagnostics
        self.fontSize = fontSize
        self.isWrapEnabled = isWrapEnabled
        self.searchQuery = searchQuery
        self.onNavigateToLine = onNavigateToLine
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    public func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = !isWrapEnabled
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = true
        scrollView.backgroundColor = ConsoleColors.background
        scrollView.wantsLayer = true
        
        let textView = ConsoleNSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.allowsUndo = false
        textView.isRichText = true
        textView.drawsBackground = true
        textView.backgroundColor = ConsoleColors.background
        textView.onNavigateToLine = onNavigateToLine
        
        // Critical for performance: lazy / non-contiguous layout prevents
        // laying out hundreds of thousands of glyphs synchronously.
        textView.layoutManager?.allowsNonContiguousLayout = true
        
        textView.textContainerInset = NSSize(width: 14, height: 10)
        textView.textContainer?.lineFragmentPadding = 2
        
        applyWrapMode(to: scrollView, textView: textView, isWrapEnabled: isWrapEnabled)
        
        let attributed = Self.buildHighlightedText(
            for: text,
            isDiagnostics: isDiagnostics,
            fontSize: fontSize,
            searchQuery: searchQuery
        )
        textView.textStorage?.setAttributedString(attributed)
        
        context.coordinator.lastText = text
        context.coordinator.lastIsDiagnostics = isDiagnostics
        context.coordinator.lastFontSize = fontSize
        context.coordinator.lastIsWrapEnabled = isWrapEnabled
        context.coordinator.lastSearchQuery = searchQuery
        
        scrollView.documentView = textView
        context.coordinator.textView = textView
        
        return scrollView
    }
    
    public func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? ConsoleNSTextView else { return }
        
        textView.onNavigateToLine = onNavigateToLine
        
        let needsRebuild = context.coordinator.lastText != text ||
            context.coordinator.lastIsDiagnostics != isDiagnostics ||
            context.coordinator.lastFontSize != fontSize ||
            context.coordinator.lastSearchQuery != searchQuery
        
        if context.coordinator.lastIsWrapEnabled != isWrapEnabled {
            context.coordinator.lastIsWrapEnabled = isWrapEnabled
            applyWrapMode(to: scrollView, textView: textView, isWrapEnabled: isWrapEnabled)
        }
        
        if needsRebuild {
            context.coordinator.lastText = text
            context.coordinator.lastIsDiagnostics = isDiagnostics
            context.coordinator.lastFontSize = fontSize
            context.coordinator.lastSearchQuery = searchQuery
            
            let attributed = Self.buildHighlightedText(
                for: text,
                isDiagnostics: isDiagnostics,
                fontSize: fontSize,
                searchQuery: searchQuery
            )
            textView.textStorage?.setAttributedString(attributed)
            
            // Scroll to first search match if search query is active
            if !searchQuery.isEmpty {
                let nsText = text as NSString
                let foundRange = nsText.range(of: searchQuery, options: .caseInsensitive)
                if foundRange.location != NSNotFound {
                    textView.scrollRangeToVisible(foundRange)
                    textView.showFindIndicator(for: foundRange)
                }
            }
        }
    }
    
    private func applyWrapMode(to scrollView: NSScrollView, textView: NSTextView, isWrapEnabled: Bool) {
        if isWrapEnabled {
            scrollView.hasHorizontalScroller = false
            textView.isHorizontallyResizable = false
            textView.autoresizingMask = [.width]
            textView.textContainer?.containerSize = NSSize(
                width: scrollView.contentSize.width,
                height: CGFloat.greatestFiniteMagnitude
            )
            textView.textContainer?.widthTracksTextView = true
        } else {
            scrollView.hasHorizontalScroller = true
            textView.isHorizontallyResizable = true
            textView.autoresizingMask = [.height]
            textView.textContainer?.containerSize = NSSize(
                width: CGFloat.greatestFiniteMagnitude,
                height: CGFloat.greatestFiniteMagnitude
            )
            textView.textContainer?.widthTracksTextView = false
        }
    }
    
    // MARK: - Syntax Highlighter Engine
    
    public static func buildHighlightedText(
        for text: String,
        isDiagnostics: Bool,
        fontSize: CGFloat,
        searchQuery: String
    ) -> NSAttributedString {
        guard !text.isEmpty else { return NSAttributedString() }
        
        let regularFont = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        let boldFont = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .bold)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = max(3.0, fontSize * 0.28)
        
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: regularFont,
            .foregroundColor: ConsoleColors.regularText,
            .paragraphStyle: paragraphStyle
        ]
        
        let attrStr = NSMutableAttributedString(string: text, attributes: baseAttributes)
        let nsText = text as NSString
        let fullLength = nsText.length
        
        var lineStart = 0
        var lineEnd = 0
        var contentsEnd = 0
        var charIndex = 0
        
        let maxLines = 4000
        var lineCount = 0
        
        while charIndex < fullLength && lineCount < maxLines {
            nsText.getLineStart(&lineStart, end: &lineEnd, contentsEnd: &contentsEnd, for: NSRange(location: charIndex, length: 0))
            let lineRange = NSRange(location: lineStart, length: contentsEnd - lineStart)
            let lineStr = nsText.substring(with: lineRange)
            let trimmed = lineStr.trimmingCharacters(in: .whitespaces)
            
            if isDiagnostics {
                if trimmed.hasPrefix("!") || trimmed.hasPrefix("error:") || trimmed.hasPrefix("Error:") {
                    attrStr.addAttribute(.foregroundColor, value: ConsoleColors.errorText, range: lineRange)
                    attrStr.addAttribute(.font, value: boldFont, range: lineRange)
                } else if trimmed.hasPrefix("-->") {
                    attrStr.addAttribute(.foregroundColor, value: ConsoleColors.locationText, range: lineRange)
                    attrStr.addAttribute(.font, value: boldFont, range: lineRange)
                    attrStr.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: lineRange)
                } else if trimmed.hasPrefix("warning:") || trimmed.hasPrefix("Warning:") || trimmed.hasPrefix("LaTeX Warning:") {
                    attrStr.addAttribute(.foregroundColor, value: ConsoleColors.warningText, range: lineRange)
                    attrStr.addAttribute(.font, value: boldFont, range: lineRange)
                } else if trimmed.hasPrefix("= help:") {
                    attrStr.addAttribute(.foregroundColor, value: ConsoleColors.helpText, range: lineRange)
                } else if trimmed.hasPrefix("= while expanding:") || trimmed.hasPrefix("= included from") {
                    attrStr.addAttribute(.foregroundColor, value: ConsoleColors.contextText, range: lineRange)
                } else if trimmed.contains("^^^^^") || trimmed.contains("^^^") {
                    attrStr.addAttribute(.foregroundColor, value: ConsoleColors.caretText, range: lineRange)
                    attrStr.addAttribute(.font, value: boldFont, range: lineRange)
                } else if trimmed.hasPrefix("|") || trimmed.contains(" | ") {
                    if let pipeRange = lineStr.range(of: "|") {
                        let pipeLoc = lineStr.distance(from: lineStr.startIndex, to: pipeRange.upperBound)
                        let numRange = NSRange(location: lineStart, length: min(pipeLoc, lineRange.length))
                        attrStr.addAttribute(.foregroundColor, value: ConsoleColors.lineNumberText, range: numRange)
                    }
                }
            } else {
                // TeX Log mode
                if trimmed.hasPrefix("!") {
                    attrStr.addAttribute(.foregroundColor, value: ConsoleColors.errorText, range: lineRange)
                    attrStr.addAttribute(.font, value: boldFont, range: lineRange)
                } else if trimmed.hasPrefix("l.") {
                    attrStr.addAttribute(.foregroundColor, value: ConsoleColors.locationText, range: lineRange)
                    attrStr.addAttribute(.font, value: boldFont, range: lineRange)
                } else if trimmed.contains("Warning:") || trimmed.hasPrefix("Overfull \\hbox") || trimmed.hasPrefix("Underfull \\hbox") {
                    attrStr.addAttribute(.foregroundColor, value: ConsoleColors.warningText, range: lineRange)
                } else if trimmed.hasPrefix("Output written on") {
                    attrStr.addAttribute(.foregroundColor, value: ConsoleColors.successText, range: lineRange)
                    attrStr.addAttribute(.font, value: boldFont, range: lineRange)
                } else if trimmed.hasPrefix("Transcript written on") {
                    attrStr.addAttribute(.foregroundColor, value: ConsoleColors.lineNumberText, range: lineRange)
                } else if trimmed.hasPrefix("(") && (trimmed.contains(".tex") || trimmed.contains(".sty") || trimmed.contains(".cls")) {
                    attrStr.addAttribute(.foregroundColor, value: ConsoleColors.lineNumberText, range: lineRange)
                }
            }
            
            charIndex = lineEnd
            lineCount += 1
        }
        
        // Apply search match highlights
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespaces)
        if !trimmedQuery.isEmpty {
            var searchRange = NSRange(location: 0, length: fullLength)
            while searchRange.location < fullLength {
                let found = nsText.range(of: trimmedQuery, options: .caseInsensitive, range: searchRange)
                if found.location != NSNotFound {
                    attrStr.addAttribute(.backgroundColor, value: ConsoleColors.searchHighlight, range: found)
                    searchRange.location = found.location + max(1, found.length)
                    searchRange.length = fullLength - searchRange.location
                } else {
                    break
                }
            }
        }
        
        return attrStr
    }
    
    public class Coordinator {
        fileprivate weak var textView: ConsoleNSTextView?
        var lastText: String = ""
        var lastIsDiagnostics: Bool = true
        var lastFontSize: CGFloat = 12.0
        var lastIsWrapEnabled: Bool = true
        var lastSearchQuery: String = ""
    }
}

// MARK: - Custom Console NSTextView with Click-to-Jump Support

fileprivate final class ConsoleNSTextView: NSTextView {
    var onNavigateToLine: ((Int) -> Void)?
    
    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let charIndex = characterIndexForInsertion(at: point)
        
        if charIndex < (string as NSString).length {
            let nsStr = string as NSString
            let lineRange = nsStr.lineRange(for: NSRange(location: charIndex, length: 0))
            let lineStr = nsStr.substring(with: lineRange)
            
            // Check for Rustc/Ratex pointer: --> file.tex:18:9
            if let targetLine = extractLineNumber(from: lineStr) {
                onNavigateToLine?(targetLine)
            }
        }
        
        super.mouseDown(with: event)
    }
    
    private func extractLineNumber(from string: String) -> Int? {
        // Pattern 1: --> filename:18:9
        if let arrowRange = string.range(of: "-->") {
            let afterArrow = String(string[arrowRange.upperBound...])
            let parts = afterArrow.components(separatedBy: ":")
            if parts.count >= 2, let line = Int(parts[1].trimmingCharacters(in: .whitespaces)) {
                return line
            }
        }
        // Pattern 2: l.42 \command
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("l.") {
            let numPart = trimmed.dropFirst(2).prefix(while: { $0.isNumber })
            if let line = Int(numPart) {
                return line
            }
        }
        return nil
    }
}

// MARK: - Palette Colors Supporting Light & Dark macOS Modes

private enum ConsoleColors {
    static let background = NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(deviceRed: 0.11, green: 0.12, blue: 0.14, alpha: 1.0)
            : NSColor(deviceRed: 0.96, green: 0.97, blue: 0.98, alpha: 1.0)
    }
    
    static let regularText = NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(deviceRed: 0.88, green: 0.90, blue: 0.93, alpha: 1.0)
            : NSColor(deviceRed: 0.15, green: 0.17, blue: 0.20, alpha: 1.0)
    }
    
    static let errorText = NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(deviceRed: 1.0, green: 0.40, blue: 0.40, alpha: 1.0)
            : NSColor(deviceRed: 0.82, green: 0.12, blue: 0.12, alpha: 1.0)
    }
    
    static let warningText = NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(deviceRed: 1.0, green: 0.68, blue: 0.24, alpha: 1.0)
            : NSColor(deviceRed: 0.78, green: 0.44, blue: 0.05, alpha: 1.0)
    }
    
    static let locationText = NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(deviceRed: 0.38, green: 0.76, blue: 1.0, alpha: 1.0)
            : NSColor(deviceRed: 0.05, green: 0.45, blue: 0.85, alpha: 1.0)
    }
    
    static let lineNumberText = NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(deviceRed: 0.48, green: 0.52, blue: 0.60, alpha: 1.0)
            : NSColor(deviceRed: 0.55, green: 0.58, blue: 0.65, alpha: 1.0)
    }
    
    static let caretText = NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(deviceRed: 1.0, green: 0.82, blue: 0.30, alpha: 1.0)
            : NSColor(deviceRed: 0.85, green: 0.55, blue: 0.05, alpha: 1.0)
    }
    
    static let helpText = NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(deviceRed: 0.35, green: 0.88, blue: 0.60, alpha: 1.0)
            : NSColor(deviceRed: 0.08, green: 0.58, blue: 0.32, alpha: 1.0)
    }
    
    static let contextText = NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(deviceRed: 0.75, green: 0.58, blue: 1.0, alpha: 1.0)
            : NSColor(deviceRed: 0.52, green: 0.25, blue: 0.78, alpha: 1.0)
    }
    
    static let successText = NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(deviceRed: 0.35, green: 0.88, blue: 0.55, alpha: 1.0)
            : NSColor(deviceRed: 0.10, green: 0.60, blue: 0.30, alpha: 1.0)
    }
    
    static let searchHighlight = NSColor.systemYellow.withAlphaComponent(0.35)
}
