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
    var isEraser: Bool
    var eraserWidth: CGFloat
    
    func makeUIView(context: Context) -> PKCanvasView {
        // Set drawing and styling
        canvasView.drawing = drawing
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        
        // Set drawing policy to allow any input
        canvasView.drawingPolicy = .anyInput
        
        // Set the appropriate tool
        updateTool(canvasView)
        
        // Set delegate for drawing changes
        canvasView.delegate = context.coordinator
        
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Update tool based on current settings
        updateTool(uiView)
        
        // Update drawing if changed externally
        if uiView.drawing != drawing {
            uiView.drawing = drawing
        }
    }
    
    private func updateTool(_ canvasView: PKCanvasView) {
        if isEraser {
            canvasView.tool = PKEraserTool(.vector, width: eraserWidth)
        } else {
            canvasView.tool = PKInkingTool(.pen, color: UIColor(color), width: width)
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

