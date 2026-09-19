import SwiftUI
import AppKit

public struct ConsoleLogTextView: NSViewRepresentable {
    let text: String
    let isError: Bool
    
    public init(text: String, isError: Bool = false) {
        self.text = text
        self.isError = isError
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator()
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
        
        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.allowsUndo = false
        textView.isRichText = false
        textView.drawsBackground = true
        textView.backgroundColor = NSColor.textBackgroundColor
        
        // Critical for performance: lazy / non-contiguous layout prevents
        // laying out hundreds of thousands of glyphs at once synchronously.
        textView.layoutManager?.allowsNonContiguousLayout = true
        
        let font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        textView.font = font
        textView.textColor = isError ? NSColor.systemRed : NSColor.labelColor
        textView.textContainerInset = NSSize(width: 10, height: 8)
        textView.textContainer?.lineFragmentPadding = 2
        
        textView.autoresizingMask = [.width]
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.containerSize = NSSize(
            width: scrollView.contentSize.width,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer?.widthTracksTextView = true
        
        textView.string = text
        context.coordinator.lastText = text
        context.coordinator.lastIsError = isError
        
        scrollView.documentView = textView
        context.coordinator.textView = textView
        
        return scrollView
    }
    
    public func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        
        if context.coordinator.lastIsError != isError {
            context.coordinator.lastIsError = isError
            textView.textColor = isError ? NSColor.systemRed : NSColor.labelColor
        }
        
        if context.coordinator.lastText != text {
            context.coordinator.lastText = text
            let font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
            let color = isError ? NSColor.systemRed : NSColor.labelColor
            
            // Assigning string directly with allowsNonContiguousLayout enabled
            // executes in <1ms even for massive logs.
            textView.string = text
            textView.font = font
            textView.textColor = color
        }
    }
    
    public class Coordinator {
        weak var textView: NSTextView?
        var lastText: String = ""
        var lastIsError: Bool = false
    }
}

