//
//  FolderStore.swift
//  MathNotes
//
//  Created by Ayush Vattoli on 2025-05-10.
//


import Foundation
import PencilKit

class FolderStore: ObservableObject {
    @Published var folders: [Folder] {
        didSet {
            saveFolders()
        }
    }
    
    private let foldersKey = "SavedFolders"
    
    init() {
        print("Initializing FolderStore...")
        if let data = UserDefaults.standard.data(forKey: foldersKey) {
            print("Found saved folders data")
            do {
                let decodedFolders = try JSONDecoder().decode([Folder].self, from: data)
                print("Successfully decoded \(decodedFolders.count) folders")
                self.folders = decodedFolders
            } catch {
                print("Error decoding folders: \(error)")
                self.folders = Self.createDefaultFolders()
            }
        } else {
            print("No saved folders found, creating defaults")
            self.folders = Self.createDefaultFolders()
        }
        
        for folderIndex in folders.indices {
            for fileIndex in folders[folderIndex].files.indices {
                folders[folderIndex].files[fileIndex].loadDrawingsFromDisk()
            }
        }
    }
    
    private static func createDefaultFolders() -> [Folder] {
        print("Creating default folders")
        return [
            Folder(name: "Math"),
            Folder(name: "Physics")
        ]
    }
    
    private func saveFolders() {
        print("Saving folders to UserDefaults...")
        do {
            let encoded = try JSONEncoder().encode(folders)
            UserDefaults.standard.set(encoded, forKey: foldersKey)
            print("Successfully saved \(folders.count) folders")
            
            // Also save all drawings to ensure everything is in sync
            // Use a slight delay to avoid immediately calling this after initialization
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.saveAllDrawings()
            }
        } catch {
            print("Error saving folders: \(error)")
        }
    }
    
    func addFile(to folder: Folder, file: File) {
        print("Adding file \(file.name) to folder \(folder.name)")
        if let index = folders.firstIndex(where: { $0.id == folder.id }) {
            folders[index].files.append(file)
            saveFolders()
            print("File added successfully")
        } else {
            print("Error: Folder not found")
        }
    }
    
    func addFolder(name: String) {
        print("Adding new folder: \(name)")
        let newFolder = Folder(name: name)
        folders.append(newFolder)
        saveFolders()
        print("Folder added successfully")
    }
    
    func loadDrawingsForAllFiles() {
        print("\n=== Loading drawings for all files ===")
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        print("Documents directory: \(docs.path)")
        
        for folderIndex in folders.indices {
            let folder = folders[folderIndex]
            print("\nProcessing folder: \(folder.name)")
            
            for fileIndex in folder.files.indices {
                let file = folder.files[fileIndex]
                print("\nLoading drawings for file: \(file.name)")
                print("File UUID: \(file.id.uuidString)")
                print("Drawing file path: \(file.drawingFilePath)")
                
                let prefix = "\(file.drawingFilePath)_page_"
                
                do {
                    let existingFiles = try FileManager.default.contentsOfDirectory(at: docs, includingPropertiesForKeys: nil)
                    let matchingFiles = existingFiles.filter { $0.lastPathComponent.hasPrefix(prefix) }
                        .sorted { $0.lastPathComponent < $1.lastPathComponent }
                    
                    print("Found \(matchingFiles.count) drawing files")
                    
                    var drawings: [PKDrawing] = []
                    for url in matchingFiles {
                        do {
                            let data = try Data(contentsOf: url)
                            let drawing = try PKDrawing(data: data)
                            drawings.append(drawing)
                            print("✓ Loaded drawing: \(url.lastPathComponent) (\(data.count) bytes)")
                        } catch {
                            print("✗ Error loading drawing \(url.lastPathComponent): \(error)")
                        }
                    }
                    
                    if drawings.isEmpty {
                        print("No drawings found, initializing with empty drawing")
                        drawings = [PKDrawing()]
                    }
                    
                    folders[folderIndex].files[fileIndex].drawings = drawings
                    print("Total drawings loaded for \(file.name): \(drawings.count)")
                    
                } catch {
                    print("✗ Error loading drawings for file \(file.name): \(error)")
                    // Initialize with empty drawing if loading fails
                    folders[folderIndex].files[fileIndex].drawings = [PKDrawing()]
                }
            }
        }
        print("\n=== Completed loading drawings for all files ===")
    }
    
    func saveAllDrawings() {
        print("\n=== Saving all drawings ===")
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        print("Documents directory: \(docs.path)")
        
        for folderIndex in folders.indices {
            let folder = folders[folderIndex]
            print("\nProcessing folder: \(folder.name)")
            
            for fileIndex in folder.files.indices {
                let file = folder.files[fileIndex]
                print("\nSaving drawings for file: \(file.name)")
                print("File UUID: \(file.id.uuidString)")
                print("Drawing file path: \(file.drawingFilePath)")
                
                let prefix = "\(file.drawingFilePath)_page_"
                
                // First, remove all existing drawing files for this document
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
                let drawings = folder.files[fileIndex].drawings
                print("Saving \(drawings.count) drawings...")
                
                for (index, drawing) in drawings.enumerated() {
                    let url = docs.appendingPathComponent("\(file.drawingFilePath)_page_\(index).drawing")
                    do {
                        let data = drawing.dataRepresentation()
                        try data.write(to: url)
                        print("✓ Saved drawing page \(index) to: \(url.lastPathComponent) (\(data.count) bytes)")
                    } catch {
                        print("✗ Failed to save drawing page \(index): \(error)")
                    }
                }
            }
        }
        print("\n=== Completed saving all drawings ===")
    }
    
    
    
    
}
