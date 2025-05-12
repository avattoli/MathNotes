//
//  DrawingCanvasView.swift
//  MathNotes
//
//  Created by Ayush Vattoli on 2025-05-10.
//

import SwiftUI
import PencilKit

struct DrawingCanvasView: UIViewRepresentable {
    var canvasView: PKCanvasView
    @Binding var drawing: PKDrawing
    @Binding var color: Color
    @Binding var width: CGFloat
    
    func makeUIView(context: Context) -> PKCanvasView {
        // Configure drawing tool
        canvasView.tool = PKInkingTool(.pen, color: UIColor(color), width: width)
        
        // Set drawing and styling
        canvasView.drawing = drawing
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        
        // Set drawing policy to pencil only (no finger drawing)
        canvasView.drawingPolicy = .anyInput // Changed to allow finger drawing for testing
        
        // Set delegate for drawing changes
        canvasView.delegate = context.coordinator
        
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Update tool with current color and width
        uiView.tool = PKInkingTool(.pen, color: UIColor(color), width: width)
        
        // Update drawing if changed externally
        if uiView.drawing != drawing {
            uiView.drawing = drawing
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
            Task { @MainActor in
                drawing.wrappedValue = canvasView.drawing
            }
        }
    }
}

