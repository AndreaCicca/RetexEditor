import SwiftUI
import AppKit

public struct SourceEditorView: NSViewRepresentable {
    @Bindable var state: EditorState
    var fontSize: CGFloat
    
    public init(state: EditorState) {
        self.state = state
        self.fontSize = state.editorFontSize
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self, initialSource: state.source, initialFontSize: state.editorFontSize)
    }
    
    public func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = true
        scrollView.backgroundColor = NSColor.textBackgroundColor
        scrollView.wantsLayer = true
        scrollView.layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
        scrollView.layerContentsRedrawPolicy = .onSetNeedsDisplay
        
        let textView = LaTeXNSTextView()
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        
        // Typography & readable styling with scalable font size
        let font = NSFont.monospacedSystemFont(ofSize: state.editorFontSize, weight: .regular)
        textView.font = font
        textView.textColor = NSColor.labelColor
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.drawsBackground = true
        textView.insertionPointColor = NSColor.controlAccentColor
        textView.wantsLayer = true
        textView.layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
        textView.layerContentsRedrawPolicy = .onSetNeedsDisplay
        
        // Generous, beautiful padding for optimal readability
        textView.textContainerInset = NSSize(width: 32, height: 22)
        textView.textContainer?.lineFragmentPadding = 4
        
        // Balanced line height
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = max(3.0, state.editorFontSize * 0.33)
        textView.defaultParagraphStyle = paragraphStyle
        textView.typingAttributes = [
            .font: font,
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraphStyle
        ]
        
        // Responsive width layout
        textView.autoresizingMask = [.width]
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.containerSize = NSSize(
            width: scrollView.contentSize.width,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer?.widthTracksTextView = true
        
        textView.string = state.source
        textView.delegate = context.coordinator
        
        // Apply initial attributes
        if let storage = textView.textStorage, storage.length > 0 {
            storage.addAttribute(.font, value: font, range: NSRange(location: 0, length: storage.length))
            storage.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: storage.length))
        }
        
        scrollView.documentView = textView
        context.coordinator.textView = textView
        
        // Connect the state modifier closure
        // Connect the state modifier closures
        state.textModifier = { [weak textView] insert, wrapPrefix, wrapSuffix, placeholder in
            guard let textView = textView else { return }
            textView.applyWYSIWYG(insert: insert, wrapPrefix: wrapPrefix, wrapSuffix: wrapSuffix, placeholder: placeholder)
        }
        state.textReplacer = { [weak textView] newText in
            guard let textView = textView else { return }
            textView.replaceAllTextWithUndo(newText: newText)
        }
        
        return scrollView
    }
    
    public func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? LaTeXNSTextView else { return }
        
        // Only update if source changed externally (NOT during resize or user typing)
        // 1. Update font size if changed via Cmd+ / Cmd-
        if context.coordinator.lastFontSize != state.editorFontSize {
            context.coordinator.lastFontSize = state.editorFontSize
            let newFont = NSFont.monospacedSystemFont(ofSize: state.editorFontSize, weight: .regular)
            textView.font = newFont
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = max(3.0, state.editorFontSize * 0.33)
            textView.defaultParagraphStyle = paragraphStyle
            textView.typingAttributes = [
                .font: newFont,
                .foregroundColor: NSColor.labelColor,
                .paragraphStyle: paragraphStyle
            ]
            
            if let storage = textView.textStorage, storage.length > 0 {
                storage.beginEditing()
                storage.addAttribute(.font, value: newFont, range: NSRange(location: 0, length: storage.length))
                storage.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: storage.length))
                storage.endEditing()
            }
        }
        
        // 2. Only update if source changed externally (NOT during resize or user typing)
        if context.coordinator.lastSource != state.source && !context.coordinator.isInternalUpdate {
            context.coordinator.lastSource = state.source
            let selectedRanges = textView.selectedRanges
            let currentLength = (state.source as NSString).length
            let clampedRanges = textView.selectedRanges.compactMap { val -> NSValue? in
                let r = val.rangeValue
                if r.location + r.length <= currentLength {
                    return val
                } else if r.location <= currentLength {
                    return NSValue(range: NSRange(location: r.location, length: currentLength - r.location))
                } else {
                    return NSValue(range: NSRange(location: currentLength, length: 0))
                }
            }
            textView.string = state.source
            textView.selectedRanges = selectedRanges
            textView.selectedRanges = clampedRanges.isEmpty ? [NSValue(range: NSRange(location: 0, length: 0))] : clampedRanges
            
            // Re-apply font attributes to new string
            let currentFont = NSFont.monospacedSystemFont(ofSize: state.editorFontSize, weight: .regular)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = max(3.0, state.editorFontSize * 0.33)
            if let storage = textView.textStorage, storage.length > 0 {
                storage.beginEditing()
                storage.addAttribute(.font, value: currentFont, range: NSRange(location: 0, length: storage.length))
                storage.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: storage.length))
                storage.endEditing()
            }
        }
    }
    
    public class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SourceEditorView
        weak var textView: LaTeXNSTextView?
        var isInternalUpdate = false
        var lastSource: String
        var lastFontSize: CGFloat
        
        init(_ parent: SourceEditorView, initialSource: String, initialFontSize: CGFloat) {
            self.parent = parent
            self.lastSource = initialSource
            self.lastFontSize = initialFontSize
        }
        
        public func textDidChange(_ notification: Notification) {
            guard let tv = textView else { return }
            isInternalUpdate = true
            let newText = tv.string
            lastSource = newText
            parent.state.source = newText
            parent.state.selectedRange = tv.selectedRange()
            DispatchQueue.main.async {
                self.isInternalUpdate = false
            }
        }
        
        public func textViewDidChangeSelection(_ notification: Notification) {
            guard let tv = textView else { return }
            parent.state.selectedRange = tv.selectedRange()
        }
    }
}

// Custom NSTextView with helper for formatting insertions and shared undo manager
final class LaTeXNSTextView: NSTextView {
    override var undoManager: UndoManager? {
        // Share window undoManager so Cmd+Z routes natively and seamlessly
        return window?.undoManager ?? super.undoManager
    }
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command) {
            let chars = event.charactersIgnoringModifiers ?? ""
            if chars == "+" || chars == "=" {
                NotificationCenter.default.post(name: .zoomInTextRequested, object: nil)
                return true
            } else if chars == "-" {
                NotificationCenter.default.post(name: .zoomOutTextRequested, object: nil)
                return true
            } else if chars == "0" {
                NotificationCenter.default.post(name: .resetTextZoomRequested, object: nil)
                return true
            }
        }
        return super.performKeyEquivalent(with: event)
    }
    
    func applyWYSIWYG(insert: String?, wrapPrefix: String?, wrapSuffix: String?, placeholder: String?) {
        let range = self.selectedRange()
        
        if let insert = insert {
            if self.shouldChangeText(in: range, replacementString: insert) {
                self.replaceCharacters(in: range, with: insert)
                self.didChangeText()
                self.setSelectedRange(NSRange(location: range.location + (insert as NSString).length, length: 0))
            }
        } else if let prefix = wrapPrefix, let suffix = wrapSuffix {
            let selectedText = (self.string as NSString).substring(with: range)
            let body = selectedText.isEmpty ? (placeholder ?? "") : selectedText
            let replacement = "\(prefix)\(body)\(suffix)"
            
            if self.shouldChangeText(in: range, replacementString: replacement) {
                self.replaceCharacters(in: range, with: replacement)
                self.didChangeText()
                let newCursor = range.location + (prefix as NSString).length + (body as NSString).length
                self.setSelectedRange(NSRange(location: newCursor, length: 0))
            }
        }
    }
    
    func replaceAllTextWithUndo(newText: String) {
        let fullRange = NSRange(location: 0, length: (self.string as NSString).length)
        if self.shouldChangeText(in: fullRange, replacementString: newText) {
            self.replaceCharacters(in: fullRange, with: newText)
            self.didChangeText()
            self.setSelectedRange(NSRange(location: 0, length: 0))
        }
    }
}
