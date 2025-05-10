//
//  File.swift
//  MathNotes
//
//  Created by Ayush Vattoli on 2025-05-10.
//

import SwiftUI

import Foundation

class File: Identifiable, ObservableObject, Hashable {
    let id = UUID()
    @Published var name: String
    let drawingFilePath: String

    init(name: String) {
        self.name = name
        self.drawingFilePath = "\(UUID().uuidString).drawing"
    }

    static func == (lhs: File, rhs: File) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}





