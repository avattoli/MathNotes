//
//  MathNotesApp.swift
//  MathNotes
//
//  Created by Ayush Vattoli on 2025-05-10.
//

import SwiftUI
import PencilKit

// Create a global instance that can be accessed from anywhere
let globalFolderStore = FolderStore()

@main
struct MathNotesApp: App {
    // Use the global instance as the StateObject
    @StateObject private var folderStore = globalFolderStore
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            FrontPageView()
                .environmentObject(folderStore)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background || newPhase == .inactive {
                print("\n=== App entering background/inactive state ===")
                folderStore.saveAllDrawings()
            }
        }
    }
}
