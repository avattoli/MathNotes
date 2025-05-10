//
//  DrawingCanvasView.swift
//  MathNotes
//
//  Created by Ayush Vattoli on 2025-05-10.
//


import SwiftUI
import PencilKit

struct DrawingCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    var brushColor: Color
    var brushWidth: CGFloat
    var canvasSize: CGSize
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        
        // Configure drawing tool
        canvasView.tool = PKInkingTool(.pen, color: UIColor(brushColor), width: brushWidth)
        
        // Set drawing and styling
        canvasView.drawing = drawing
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        
        // Set drawing policy to pencil only (no finger drawing)
        canvasView.drawingPolicy = .pencilOnly
        
        // Enable gestures
        setupGestures(canvasView)
        
        // Set delegate for drawing changes
        canvasView.delegate = context.coordinator
        
        // Set the content size and zoom limits
        updateCanvasSize(canvasView)
        
        return canvasView
    }
    
    private func setupGestures(_ canvasView: PKCanvasView) {
        // Enable zooming
        canvasView.minimumZoomScale = 0.1
        canvasView.maximumZoomScale = 5.0
        
        
        // Enable scrolling and bouncing
        if let scrollView = findScrollView(in: canvasView) {
            scrollView.alwaysBounceVertical = true
            scrollView.alwaysBounceHorizontal = true
            scrollView.showsVerticalScrollIndicator = false
            scrollView.showsHorizontalScrollIndicator = false
        }
    }
    
    private func findScrollView(in view: UIView) -> UIScrollView? {
        if let scrollView = view as? UIScrollView {
            return scrollView
        }
        
        for subview in view.subviews {
            if let scrollView = findScrollView(in: subview) {
                return scrollView
            }
        }
        
        return nil
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Update tool with current color and width
        uiView.tool = PKInkingTool(.pen, color: UIColor(brushColor), width: brushWidth)
        
        // Update drawing if changed externally
        if uiView.drawing != drawing {
            uiView.drawing = drawing
        }
        updateCanvasSize(uiView)
    }
    
    private func updateCanvasSize(_ canvasView: PKCanvasView) {
        // Set the content size to match the visible area
        canvasView.contentSize = canvasSize
        canvasView.minimumZoomScale = 1.0
        canvasView.maximumZoomScale = 5.0
        if canvasView.zoomScale < 1.0 {
            canvasView.setZoomScale(1.0, animated: false)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(drawing: $drawing)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var drawing: Binding<PKDrawing>
        
        init(drawing: Binding<PKDrawing>) {
            self.drawing = drawing
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            drawing.wrappedValue = canvasView.drawing
        }
    }
}



