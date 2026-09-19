import SwiftUI
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
    
    public func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.displaysPageBreaks = true
        pdfView.autoScales = true
        pdfView.backgroundColor = NSColor.windowBackgroundColor
        pdfView.wantsLayer = true
        pdfView.layer?.drawsAsynchronously = true
        
        context.coordinator.pdfView = pdfView
        
        if let data = pdfData, let document = PDFDocument(data: data) {
            pdfView.document = document
        }
        
        return pdfView
    }
    
    public func updateNSView(_ pdfView: PDFView, context: Context) {
        // Only update document if data actually changed
        if context.coordinator.lastData != pdfData {
            context.coordinator.lastData = pdfData
            
            if let data = pdfData, let document = PDFDocument(data: data) {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                
                let currentDestination = pdfView.currentDestination
                let currentPage = pdfView.currentPage
                
                pdfView.document = document
                
                // Restore destination or page so scroll position is preserved without jumping or flickering
                if let dest = currentDestination, let page = dest.page {
                    let pageIndex = document.index(for: page)
                    if pageIndex != NSNotFound, let targetPage = document.page(at: pageIndex) {
                        pdfView.go(to: PDFDestination(page: targetPage, at: dest.point))
                    }
                } else if let page = currentPage {
                    let pageIndex = document.index(for: page)
                    let safeIndex = (pageIndex != NSNotFound && pageIndex < document.pageCount) ? pageIndex : 0
                    if let targetPage = document.page(at: safeIndex) {
                        pdfView.go(to: targetPage)
                    }
                }
                
                CATransaction.commit()
            } else if pdfData == nil {
                pdfView.document = nil
            }
        }
        
        // Handle explicit scale changes if not auto-scaling
        if zoomScale != context.coordinator.lastScale {
            context.coordinator.lastScale = zoomScale
            if zoomScale > 0 {
                pdfView.autoScales = false
                pdfView.scaleFactor = zoomScale
            } else {
                pdfView.autoScales = true
            }
        }
    }
    
    public class Coordinator {
        weak var pdfView: PDFView?
        var lastData: Data? = nil
        var lastScale: CGFloat = 1.0
    }
}

