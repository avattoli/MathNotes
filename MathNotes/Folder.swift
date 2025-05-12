//
//  Folder.swift
//  MathNotes
//
//  Created by Ayush Vattoli on 2025-05-10.
//

import SwiftUI
import Foundation

class Folder: Identifiable, ObservableObject, Hashable, Codable {
    let id: UUID
    @Published var name: String
    @Published var files: [File]
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case files
    }
    
    init(name: String, files: [File] = []) {
        print("Creating new Folder with name: \(name)")
        self.id = UUID()
        self.name = name
        self.files = files
        print("Folder initialized with \(files.count) files")
    }
    
    required init(from decoder: Decoder) throws {
        print("Decoding Folder...")
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        files = try container.decode([File].self, forKey: .files)
        print("Decoded Folder: id=\(id.uuidString), name=\(name), files=\(files.count)")
    }
    
    func encode(to encoder: Encoder) throws {
        print("Encoding Folder: \(name)...")
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(files, forKey: .files)
        print("Encoded Folder: id=\(id.uuidString), name=\(name), files=\(files.count)")
    }
    
    static func == (lhs: Folder, rhs: Folder) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
