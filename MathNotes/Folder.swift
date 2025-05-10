//
//  Folder.swift
//  MathNotes
//
//  Created by Ayush Vattoli on 2025-05-10.
//

import SwiftUI

class Folder: Identifiable, ObservableObject, Hashable {
    let id = UUID()
    var name: String
    @Published var files: [File]

    init(name: String, files: [File] = []) {
        self.name = name
        self.files = files
    }

    static func == (lhs: Folder, rhs: Folder) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
