//
//  File.swift
//  MathNotes
//
//  Created by Ayush Vattoli on 2025-05-10.
//

import SwiftUI
import Foundation
import PencilKit

class File: Identifiable, ObservableObject, Hashable, Codable {
    let id: UUID
    @Published var name: String
    let drawingFilePath: String
    @Published var drawings: [PKDrawing] {
        didSet {
            // Save drawings whenever they change
            // Using a slight delay to avoid excessive saves during rapid changes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("Drawing changed in file \(self.name) - triggering save")
                self.saveDrawingsToDisk()
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case drawingFilePath
        // Note: drawings are stored separately in the filesystem
    }
    
    init(name: String) {
        print("Creating new File with name: \(name)")
        self.id = UUID()
        self.name = name
        self.drawingFilePath = "\(id.uuidString).drawing"
        self.drawings = [PKDrawing()]
        print("File initialized with drawingFilePath: \(drawingFilePath)")
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        drawingFilePath = try container.decode(String.self, forKey: .drawingFilePath)
        drawings = [PKDrawing()] // Initialize with empty drawing
        print("Decoded File: id=\(id.uuidString), name=\(name), path=\(drawingFilePath)")
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(drawingFilePath, forKey: .drawingFilePath)
        print("Encoded File: id=\(id.uuidString), name=\(name), path=\(drawingFilePath)")
    }
    
    static func == (lhs: File, rhs: File) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    
    func loadDrawingsFromDisk() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var loadedDrawings: [PKDrawing] = []
        var page = 0

        while true {
            let url = docs.appendingPathComponent("\(self.drawingFilePath)_page_\(page).drawing")
            if FileManager.default.fileExists(atPath: url.path),
               let data = try? Data(contentsOf: url),
               let drawing = try? PKDrawing(data: data) {
                loadedDrawings.append(drawing)
                page += 1
            } else {
                break
            }
        }

        self.drawings = loadedDrawings.isEmpty ? [PKDrawing()] : loadedDrawings
    }

    func saveDrawingsToDisk() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        print("\n=== Saving drawings for file: \(name) from property observer ===")
        print("File UUID: \(id.uuidString)")
        print("Drawing file path: \(drawingFilePath)")
        
        // First, remove all existing drawing files for this document
        let prefix = "\(drawingFilePath)_page_"
        do {
            let existingFiles = try FileManager.default.contentsOfDirectory(at: docs, includingPropertiesForKeys: nil)
            for url in existingFiles where url.lastPathComponent.hasPrefix(prefix) {
                try FileManager.default.removeItem(at: url)
                print("✓ Removed existing file: \(url.lastPathComponent)")
            }
        } catch {
            print("✗ Error cleaning up existing files: \(error)")
        }
        
        // Then save all current drawings
        print("Saving \(drawings.count) drawings...")
        for (index, drawing) in drawings.enumerated() {
            let url = docs.appendingPathComponent("\(drawingFilePath)_page_\(index).drawing")
            do {
                let data = drawing.dataRepresentation()
                try data.write(to: url)
                print("✓ Saved drawing page \(index) to: \(url.lastPathComponent)")
            } catch {
                print("✗ Failed to save drawing page \(index): \(error)")
            }
        }
    }
}





