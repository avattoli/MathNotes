//
//  FolderStore.swift
//  MathNotes
//
//  Created by Ayush Vattoli on 2025-05-10.
//


import Foundation

class FolderStore: ObservableObject {
    @Published var folders: [Folder] = [
        Folder(name: "Math"),
        Folder(name: "Physics")
    ]
}
