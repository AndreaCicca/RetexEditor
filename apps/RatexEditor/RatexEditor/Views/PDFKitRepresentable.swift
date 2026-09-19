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
            
            let currentPage = pdfView.currentPage
            let currentDestination = pdfView.currentDestination
            
            if let data = pdfData, let document = PDFDocument(data: data) {
                pdfView.document = document
                
                // Restore destination or page so scroll position is preserved during live typing
                if let dest = currentDestination, let page = dest.page {
                    let pageIndex = pdfView.document?.index(for: page) ?? 0
                    if pageIndex < (pdfView.document?.pageCount ?? 0), let targetPage = pdfView.document?.page(at: pageIndex) {
                        pdfView.go(to: PDFDestination(page: targetPage, at: dest.point))
                    }
                } else if let page = currentPage {
                    let pageIndex = pdfView.document?.index(for: page) ?? 0
                    if pageIndex < (pdfView.document?.pageCount ?? 0), let targetPage = pdfView.document?.page(at: pageIndex) {
                        pdfView.go(to: targetPage)
                    }
                }
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

