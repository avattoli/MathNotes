//
//  FileEditorView.swift
//  MathNotes
//
//  Created by Ayush Vattoli on 2025-05-10.
//

import SwiftUI
import PencilKit
import UIKit

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
    @State private var isEraserActive: Bool = false
    @State private var eraserWidth: CGFloat = 20.0
    @State private var showImagePicker: Bool = false
    @State private var inputImage: UIImage? = nil
    @Environment(\.scenePhase) private var scenePhase
    @State private var showCropOverlay: Bool = false
    @State private var cropRect: CGRect = .zero
    @State private var isCropping: Bool = false
    
    private let recognitionService = HandwritingRecognitionService()
    let pix2textURL = URL(string: "http://192.168.1.35:5050/recognize") //NEED TO FIX THIS WITH A PROPER SERVER!!
    
    let colors: [Color] = [.black, .red, .blue, .green, .purple, .orange]
    let brushSizes: [CGFloat] = [1, 2, 3, 5, 8, 13]
    let eraserSizes: [CGFloat] = [10, 20, 30, 50]

    var body: some View {
        VStack(spacing: 0) {
            if !toolbarMinimized {
                VStack(spacing: 8) {
                    HStack {
                        // Tools selection
                        HStack(spacing: 12) {
                            // Pen button
                            Button(action: {
                                isEraserActive = false
                            }) {
                                Image(systemName: "pencil")
                                    .foregroundColor(isEraserActive ? .gray : .blue)
                                    .padding(8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(isEraserActive ? Color.clear : Color.blue.opacity(0.2))
                                    )
                            }
                            
                            // Eraser button
                            Button(action: {
                                isEraserActive = true
                            }) {
                                Image(systemName: "eraser")
                                    .foregroundColor(isEraserActive ? .blue : .gray)
                                    .padding(8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(isEraserActive ? Color.blue.opacity(0.2) : Color.clear)
                                    )
                            }
                        }
                        
                        Divider()
                            .frame(height: 24)
                        
                        // Color picker (only visible when pen is active)
                        if !isEraserActive {
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
                        }
                        
                        Spacer()
                        
                        // Size selector (for either pen or eraser)
                        HStack {
                            Text(isEraserActive ? "Eraser Size" : "Pen Size")
                            if isEraserActive {
                                Picker("Eraser Size", selection: $eraserWidth) {
                                    ForEach(eraserSizes, id: \.self) { size in
                                        Text("\(Int(size))")
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .frame(width: 180)
                            } else {
                                Picker("Pen Size", selection: $brushWidth) {
                                    ForEach(brushSizes, id: \.self) { size in
                                        Text("\(Int(size))")
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .frame(width: 180)
                            }
                        }
                        
                        Spacer()
                        
                        // Math recognition button (now uses camera)
                        Button(action: {
                            showImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: "camera")
                                Text("Recognize Math")
                            }
                            .padding(8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .disabled(isRecognizing)
                        
                        Spacer()
                        
                        // Crop & Recognize Math button
                        Button(action: {
                            isCropping = true
                        }) {
                            HStack {
                                Image(systemName: "crop")
                                Text("Crop & Recognize Math")
                            }
                            .padding(8)
                            .background(Color.green.opacity(0.1))
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
                                    width: $brushWidth,
                                    isEraser: isEraserActive,
                                    eraserWidth: eraserWidth
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
                if isCropping {
                    CropOverlayView(isCropping: $isCropping, cropRect: $cropRect, onCrop: { rect in
                        cropRect = rect
                        isCropping = false
                        cropAndRecognize(rect: rect)
                    })
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
        .sheet(isPresented: $showImagePicker, onDismiss: processInputImage) {
            ImagePicker(image: $inputImage)
        }
        .alert("Recognized LaTeX", isPresented: $showRecognizedText) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(recognizedText)
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

    // MARK: - Pix2Text
    func processInputImage() {
        guard let image = inputImage else { return }
        isRecognizing = true
        uploadImageToPix2Text(image: image) { result in
            DispatchQueue.main.async {
                isRecognizing = false
                switch result {
                case .success(let latex):
                    recognizedText = latex
                case .failure(let error):
                    recognizedText = "Recognition failed: \(error.localizedDescription)"
                }
                showRecognizedText = true
            }
        }
    }

    func uploadImageToPix2Text(image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = pix2textURL else {
            completion(.failure(NSError(domain: "Pix2Text", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid server URL"])))
            return
        }
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "Pix2Text", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not convert image to JPEG"])))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "Pix2Text", code: 2, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let latex = json["latex"] as? String {
                completion(.success(latex))
            } else {
                completion(.failure(NSError(domain: "Pix2Text", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"])))
            }
        }.resume()
    }

    // MARK: - Crop & Recognize
    func cropAndRecognize(rect: CGRect) {
        // 1) Find the index of the last non-empty PKDrawing
        guard let pageIndex = file.drawings.lastIndex(where: { !$0.bounds.isEmpty }) else {
            print("No non-empty drawing found – nothing to recognize.")
            return
        }
        let currentDrawing = file.drawings[pageIndex]
        print("Using drawing at index \(pageIndex) (bounds: \(currentDrawing.bounds))")
        
        // 2) Debug: log the crop rectangle
        print("Crop rect: \(rect)")
        
        // 3) Render the crop
        let image = currentDrawing.image(from: rect, scale: UIScreen.main.scale)
        print("Cropped image size: \(image.size)")
        
        // 4) (Optional) Save it out so you can inspect it on the simulator/device
        if let data = image.pngData() {
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("test-crop.png")
            do {
                try data.write(to: url)
                print("🔍 Saved cropped image to: \(url.path)")
            } catch {
                print("❌ Failed saving cropped image: \(error)")
            }
        }
        
        // 5) Kick off the recognition
        isRecognizing = true
        uploadImageToPix2Text(image: image) { result in
            DispatchQueue.main.async {
                self.isRecognizing = false
                switch result {
                case .success(let latex):
                    print("Recognized LaTeX: \(latex)")
                    self.recognizedText = latex
                case .failure(let error):
                    print("Recognition failed: \(error.localizedDescription)")
                    self.recognizedText = "Recognition failed: \(error.localizedDescription)"
                }
                self.showRecognizedText = true
            }
        }
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

// MARK: - ImagePicker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - CropOverlayView
struct CropOverlayView: View {
    @Binding var isCropping: Bool
    @Binding var cropRect: CGRect
    var onCrop: (CGRect) -> Void
    @State private var startLocation: CGPoint? = nil
    @State private var currentRect: CGRect = .zero
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .gesture(DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if startLocation == nil {
                                startLocation = value.startLocation
                            }
                            let origin = startLocation ?? .zero
                            let size = CGSize(width: value.location.x - origin.x, height: value.location.y - origin.y)
                            currentRect = CGRect(origin: origin, size: size)
                        }
                        .onEnded { value in
                            let origin = startLocation ?? .zero
                            let size = CGSize(width: value.location.x - origin.x, height: value.location.y - origin.y)
                            let rect = CGRect(origin: origin, size: size).standardized
                            cropRect = rect
                            onCrop(rect)
                            startLocation = nil
                            currentRect = .zero
                        }
                    )
                if currentRect != .zero {
                    Rectangle()
                        .stroke(Color.green, lineWidth: 2)
                        .frame(width: abs(currentRect.width), height: abs(currentRect.height))
                        .position(x: currentRect.midX, y: currentRect.midY)
                }
                VStack {
                    HStack {
                        Spacer()
                        Button("Cancel") {
                            isCropping = false
                        }
                        .padding()
                    }
                    Spacer()
                }
            }
        }
    }
}
