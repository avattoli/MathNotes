//
//  FileEditorView.swift
//  MathNotes
//
//  Created by Ayush Vattoli on 2025-05-10.
//

import SwiftUI
import PencilKit

struct FileEditorView: View {
    @ObservedObject var file: File
    @State private var brushColor: Color = .black
    @State private var brushWidth: CGFloat = 1.0
    @State private var showingSaveAlert = false
    @State private var toolbarMinimized = false
    @State private var scrollOffset: CGFloat = 0
    @State private var saveWorkItem: DispatchWorkItem?
    @State private var recognizedText: String = ""
    @State private var isRecognizing: Bool = false
    @State private var showRecognizedText: Bool = false
    @Environment(\.scenePhase) private var scenePhase
    
    private let recognitionService = HandwritingRecognitionService()

    let colors: [Color] = [.black, .red, .blue, .green, .purple, .orange]
    let brushSizes: [CGFloat] = [1, 2, 3, 5, 8, 13]

    var body: some View {
        VStack(spacing: 0) {
            if !toolbarMinimized {
                HStack {
                    // Color picker
                    HStack(spacing: 8) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .stroke(Color.gray, lineWidth: brushColor == color ? 2 : 0)
                                )
                                .onTapGesture {
                                    brushColor = color
                                }
                        }
                    }
                    Spacer()
                    // Brush size slider
                    HStack {
                        Text("Size")
                        Picker("Brush Size", selection: $brushWidth) {
                            ForEach(brushSizes, id: \.self) { size in
                                Text("\(Int(size))")
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 200)
                    }
                    Spacer()
                    
                    // Math recognition button
                    Button(action: {
                        recognizeCurrentDrawing()
                    }) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                            Text("Recognize Math")
                        }
                        .padding(8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .disabled(isRecognizing)
                    
                    Spacer()
                    
                    // Minimize button
                    Button(action: {
                        withAnimation {
                            toolbarMinimized.toggle()
                        }
                    }) {
                        Image(systemName: toolbarMinimized ? "chevron.down" : "chevron.up")
                    }
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .shadow(radius: 2)
            } else {
                Button(action: {
                    withAnimation {
                        toolbarMinimized.toggle()
                    }
                }) {
                    Image(systemName: "chevron.down")
                        .padding(8)
                }
            }
            
            ZStack {
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(file.drawings.indices, id: \.self) { idx in
                                DrawingCanvasView(
                                    canvasView: PKCanvasView(),
                                    drawing: $file.drawings[idx],
                                    color: $brushColor,
                                    width: $brushWidth
                                )
                                .id(idx)
                                .frame(height: 842) // A4 paper ratio
                                .onChange(of: file.drawings[idx]) { oldValue, newValue in
                                    if !newValue.bounds.isEmpty && idx == file.drawings.count - 1 {
                                        file.drawings.append(PKDrawing())
                                        scrollProxy.scrollTo(file.drawings.count - 1, anchor: .top)
                                    }
                                    debouncedSave()
                                }
                            }
                        }
                    }
                    .background(TrackScrollView(offset: $scrollOffset))
                }
                
                // Recognition results overlay
                if showRecognizedText {
                    VStack {
                        Text("Recognized Text:")
                            .font(.headline)
                        
                        Text(recognizedText)
                            .padding()
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(8)
                            .shadow(radius: 2)
                            .padding()
                        
                        Button("Dismiss") {
                            showRecognizedText = false
                        }
                        .padding()
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.5))
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)
                }
            }
        }
        .navigationTitle(file.name)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Saved", isPresented: $showingSaveAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your drawings have been saved.")
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background || newPhase == .inactive {
                saveDrawings()
            }
        }
    }

    private func debouncedSave() {
        saveWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { 
            // Save the current file first
            saveDrawings()
            
            // Then save all drawings to ensure everything is persisted
            // Using the global instance to ensure we're accessing the same store
            globalFolderStore.saveAllDrawings()
        }
        saveWorkItem = workItem
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }
    
    func recognizeCurrentDrawing() {
        guard !file.drawings.isEmpty else { return }
        
        isRecognizing = true
        
        // Get the current drawing (use the most recently drawn on page)
        let currentDrawingIndex = max(0, file.drawings.count - 2)
        let currentDrawing = file.drawings[currentDrawingIndex]
        
        recognitionService.recognizeText(from: currentDrawing) { result in
            DispatchQueue.main.async {
                isRecognizing = false
                
                switch result {
                case .success(let text):
                    recognizedText = text
                    withAnimation {
                        showRecognizedText = true
                    }
                    
                    // Print for debugging
                    print("Recognized text: \(text)")
                    
                case .failure(let error):
                    recognizedText = "Recognition failed: \(error.localizedDescription)"
                    withAnimation {
                        showRecognizedText = true
                    }
                    
                    // Print for debugging
                    print("Recognition error: \(error)")
                }
            }
        }
    }
    
    func saveDrawings() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        print("\n=== Saving drawings for file: \(file.name) ===")
        print("File UUID: \(file.id.uuidString)")
        print("Drawing file path: \(file.drawingFilePath)")
        print("Documents directory: \(docs.path)")
        
        // First, remove all existing drawing files for this document
        let fileManager = FileManager.default
        let prefix = "\(file.drawingFilePath)_page_"
        do {
            let existingFiles = try fileManager.contentsOfDirectory(at: docs, includingPropertiesForKeys: nil)
            for url in existingFiles where url.lastPathComponent.hasPrefix(prefix) {
                try fileManager.removeItem(at: url)
                print("✓ Removed existing file: \(url.lastPathComponent)")
            }
        } catch {
            print("✗ Error cleaning up existing files: \(error)")
        }
        
        // Then save all current drawings
        print("\nSaving \(file.drawings.count) drawings...")
        for (index, drawing) in file.drawings.enumerated() {
            let url = docs.appendingPathComponent("\(file.drawingFilePath)_page_\(index).drawing")
            do {
                let data = drawing.dataRepresentation()
                try data.write(to: url)
                print("✓ Saved drawing page \(index) to: \(url.lastPathComponent) (\(data.count) bytes)")
            } catch {
                print("✗ Failed to save drawing page \(index): \(error)")
            }
        }
        print("\nSave operation completed")
    }
}

// Helper to track scroll offset
struct TrackScrollView: UIViewRepresentable {
    @Binding var offset: CGFloat
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        return scrollView
    }
    func updateUIView(_ uiView: UIScrollView, context: Context) {}
    func makeCoordinator() -> Coordinator {
        Coordinator(offset: $offset)
    }
    class Coordinator: NSObject, UIScrollViewDelegate {
        var offset: Binding<CGFloat>
        init(offset: Binding<CGFloat>) {
            self.offset = offset
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            offset.wrappedValue = scrollView.contentOffset.y
        }
    }
}
