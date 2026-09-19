import SwiftUI
import AppKit
import PDFKit

public struct PDFKitRepresentable: NSViewRepresentable {
    let pdfData: Data?
    let zoomScale: CGFloat
    
    public init(pdfData: Data?, zoomScale: CGFloat = 1.0) {
        self.pdfData = pdfData
        self.zoomScale = zoomScale
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    public func makeNSView(context: Context) -> SmoothPDFContainerView {
        let container = SmoothPDFContainerView()
        context.coordinator.containerView = container
        container.updateDocument(data: pdfData, zoomScale: zoomScale)
        return container
    }
    
    public func updateNSView(_ container: SmoothPDFContainerView, context: Context) {
        container.updateDocument(data: pdfData, zoomScale: zoomScale)
    }
    
    public class Coordinator {
        weak var containerView: SmoothPDFContainerView?
    }
}

/// Custom container view that hosts PDFView and an overlay snapshot view to eliminate any black flash or flickering on recompile.
public final class SmoothPDFContainerView: NSView {
    public let pdfView = PDFView()
    private let overlayView = NSImageView()
    private var lastData: Data? = nil
    private var lastScale: CGFloat = 1.0
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        wantsLayer = true
        layerContentsRedrawPolicy = .onSetNeedsDisplay
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.displaysPageBreaks = true
        pdfView.backgroundColor = NSColor.windowBackgroundColor
        pdfView.wantsLayer = true
        pdfView.layerContentsRedrawPolicy = .onSetNeedsDisplay
        pdfView.layer?.drawsAsynchronously = true
        
        overlayView.imageScaling = .scaleAxesIndependently
        overlayView.isHidden = true
        overlayView.wantsLayer = true
        
        addSubview(pdfView)
        addSubview(overlayView)
    }
    
    public override func layout() {
        super.layout()
        if pdfView.frame != bounds {
            pdfView.frame = bounds
        }
        if overlayView.isHidden && overlayView.frame != bounds {
            overlayView.frame = bounds
        }
    }
    
    public func updateDocument(data: Data?, zoomScale: CGFloat) {
        guard let data = data, !data.isEmpty else {
            pdfView.document = nil
            overlayView.isHidden = true
            lastData = nil
            return
        }
        
        // If data hasn't changed, only update zoom scale if necessary
        if lastData == data {
            applyScale(zoomScale)
            return
        }
        
        // 1. Take snapshot of current view before swapping document to prevent any black frame
        if pdfView.document != nil && bounds.width > 0 && bounds.height > 0 {
            if let rep = pdfView.bitmapImageRepForCachingDisplay(in: bounds) {
                pdfView.cacheDisplay(in: bounds, to: rep)
                let snapshot = NSImage(size: bounds.size)
                snapshot.addRepresentation(rep)
                overlayView.image = snapshot
                overlayView.frame = bounds
                overlayView.alphaValue = 1.0
                overlayView.isHidden = false
            }
        }
        
        lastData = data
        
        guard let newDoc = PDFDocument(data: data) else {
            overlayView.isHidden = true
            return
        }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        // Save destination & page index
        let currentDest = pdfView.currentDestination
        let currentPage = pdfView.currentPage
        let pageIndex = currentPage != nil ? (pdfView.document?.index(for: currentPage!) ?? 0) : 0
        
        // Swap document in-place
        pdfView.document = newDoc
        applyScale(zoomScale)
        
        // Restore destination or page so scroll position stays locked
        if let dest = currentDest, let page = dest.page {
            let idx = newDoc.index(for: page)
            let safeIdx = (idx != NSNotFound && idx < newDoc.pageCount) ? idx : 0
            if let targetPage = newDoc.page(at: safeIdx) {
                pdfView.go(to: PDFDestination(page: targetPage, at: dest.point))
            }
        } else if let targetPage = newDoc.page(at: min(pageIndex, newDoc.pageCount - 1)) {
            pdfView.go(to: targetPage)
        }
        
        CATransaction.commit()
        
        // 2. Smoothly fade out overlay once the new document has drawn its pages
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self = self else { return }
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.06
                self.overlayView.animator().alphaValue = 0.0
            }, completionHandler: {
                self.overlayView.isHidden = true
                self.overlayView.alphaValue = 1.0
                self.overlayView.image = nil
            })
        }
    }
    
    private func applyScale(_ scale: CGFloat) {
        guard scale != lastScale else { return }
        lastScale = scale
        
        if scale > 0 {
            if pdfView.autoScales {
                pdfView.autoScales = false
            }
            if abs(pdfView.scaleFactor - scale) > 0.001 {
                pdfView.scaleFactor = scale
            }
        } else {
            pdfView.autoScales = true
        }
    }
}
