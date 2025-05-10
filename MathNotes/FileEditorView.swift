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
    @State private var drawings: [PKDrawing] = [PKDrawing()]
    @State private var brushColor: Color = .black
    @State private var brushWidth: CGFloat = 1.0
    @State private var showingSaveAlert = false
    @State private var toolbarMinimized = false
    @State private var scrollOffset: CGFloat = 0
    @State private var contentHeight: CGFloat = 0

    let colors: [Color] = [.black, .red, .blue, .green, .purple, .orange]
    let brushSizes: [CGFloat] = [1, 2, 3, 5, 8, 13]

    var body: some View {
        VStack(spacing: 0) {
            if toolbarMinimized {
                HStack {
                    Spacer()
                    Button(action: { toolbarMinimized = false }) {
                        Image(systemName: "chevron.down")
                            .padding(8)
                    }
                }
                .background(Color(.systemBackground).opacity(0.95))
            } else {
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
                    HStack(spacing: 8) {
                        Image(systemName: "scribble.variable")
                        Slider(value: $brushWidth, in: 1...20, step: 1)
                            .frame(width: 80)
                        ZStack {
                            Circle()
                                .fill(brushColor)
                                .frame(width: brushWidth, height: brushWidth)
                                .overlay(
                                    Circle().stroke(Color.gray, lineWidth: 1)
                                )
                        }
                        Text("\(Int(brushWidth))")
                            .font(.caption)
                            .frame(width: 24)
                    }
                    Spacer()
                    // Save button
                    Button(action: {
                        saveDrawings()
                        showingSaveAlert = true
                    }) {
                        Image(systemName: "square.and.arrow.down")
                    }
                    Spacer(minLength: 8)
                    // Minimize button
                    Button(action: { toolbarMinimized = true }) {
                        Image(systemName: "chevron.up")
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemBackground).opacity(0.95))
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color(.separator)),
                    alignment: .bottom
                )
            }
            // Pages ScrollView
            GeometryReader { geometry in
                ScrollViewReader { scrollProxy in
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: 0) {
                            ForEach(0..<drawings.count, id: \.self) { idx in
                                DrawingCanvasView(
                                    drawing: $drawings[idx],
                                    brushColor: brushColor,
                                    brushWidth: brushWidth,
                                    canvasSize: geometry.size
                                )
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .background(Color.white)
                                .id(idx)
                                .overlay(
                                    Text("Page \(idx + 1)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .padding(6), alignment: .topTrailing
                                )
                            }
                        }
                        .background(GeometryReader { geo -> Color in
                            DispatchQueue.main.async {
                                contentHeight = geo.size.height
                                // If user scrolls to the bottom, add a new page if the last page is not empty
                                if contentHeight - scrollOffset - geometry.size.height < 10 {
                                    if let last = drawings.last, !last.dataRepresentation().isEmpty {
                                        drawings.append(PKDrawing())
                                    }
                                }
                            }
                            return Color.clear
                        })
                    }
                    .onAppear {
                        // Scroll to last page on appear
                        scrollProxy.scrollTo(drawings.count - 1, anchor: .top)
                    }
                    .background(TrackScrollView(offset: $scrollOffset))
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
        .onAppear {
            loadDrawings()
        }
    }

    func loadDrawings() {
        // Load all pages if you want to persist them
        let url = getDrawingURL()
        if FileManager.default.fileExists(atPath: url.path),
           let data = try? Data(contentsOf: url),
           let loadedDrawing = try? PKDrawing(data: data) {
            drawings = [loadedDrawing]
        }
    }

    func saveDrawings() {
        // Save only the first page for now (expand as needed)
        let url = getDrawingURL()
        do {
            let data = drawings.first?.dataRepresentation() ?? Data()
            try data.write(to: url)
        } catch {
            print("Failed to save drawing:", error)
        }
    }

    private func getDrawingURL() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(file.drawingFilePath)
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
