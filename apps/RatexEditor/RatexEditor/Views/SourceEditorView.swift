import SwiftUI
import AppKit

public struct SourceEditorView: NSViewRepresentable {
    @Bindable var state: EditorState
    
    public init(state: EditorState) {
        self.state = state
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        
        let textView = LaTeXNSTextView()
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textColor = NSColor.labelColor
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.autoresizingMask = [.width]
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        
        textView.string = state.source
        textView.delegate = context.coordinator
        
        scrollView.documentView = textView
        context.coordinator.textView = textView
        
        // Connect the state modifier closure
        state.textModifier = { [weak textView] insert, wrapPrefix, wrapSuffix, placeholder in
            guard let textView = textView else { return }
            textView.applyWYSIWYG(insert: insert, wrapPrefix: wrapPrefix, wrapSuffix: wrapSuffix, placeholder: placeholder)
        }
        
        return scrollView
    }
    
    public func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        // Only update if changed externally (e.g. from template picker or external reset)
        if textView.string != state.source && !context.coordinator.isInternalUpdate {
            let selectedRanges = textView.selectedRanges
            textView.string = state.source
            textView.selectedRanges = selectedRanges
        }
    }
    
    public class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SourceEditorView
        weak var textView: NSTextView?
        var isInternalUpdate = false
        
        init(_ parent: SourceEditorView) {
            self.parent = parent
        }
        
        public func textDidChange(_ notification: Notification) {
            guard let tv = textView else { return }
            isInternalUpdate = true
            parent.state.source = tv.string
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
}

