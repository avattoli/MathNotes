//
//  FrontPageView.swift
//  MathNotes
//
//  Created by Ayush Vattoli on 2025-05-10.
//

import SwiftUI

struct FrontPageView: View {
    @StateObject private var folderStore = FolderStore()
    @State private var selectedFolderIndex: Int? = nil
    @State private var selectedFile: File?
    @State private var isCreatingFile = false
    @State private var newFileName = ""

    var body: some View {
        NavigationStack {
            HStack {
                // Left: Folder List
                List(selection: $selectedFolderIndex) {
                    ForEach(Array(folderStore.folders.enumerated()), id: \.element.id) { index, folder in
                        Text(folder.name)
                            .tag(index)
                    }
                }
                .frame(width: 200)
                .listStyle(SidebarListStyle())

                // Right: Files Grid
                VStack {
                    if let index = selectedFolderIndex {
                        let folder = folderStore.folders[index]

                        HStack {
                            Text("Files in \(folder.name)")
                                .font(.headline)
                            Spacer()
                            Button("+ New File") {
                                newFileName = ""
                                isCreatingFile = true
                            }
                        }
                        .padding()

                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                                ForEach(folder.files) { file in
                                    NavigationLink(destination: FileEditorView(file: file)) {
                                        VStack {
                                            Image(systemName: "doc.text")
                                            Text(file.name)
                                                .font(.caption)
                                        }
                                        .padding()
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                            .padding()
                        }
                    } else {
                        Text("Select a folder")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .alert("New File", isPresented: $isCreatingFile, actions: {
            TextField("File name", text: $newFileName)
            Button("Create", action: {
                guard let index = selectedFolderIndex,
                      !newFileName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                let newFile = File(name: newFileName)
                folderStore.folders[index].files.append(newFile)
            })
            Button("Cancel", role: .cancel) {}
        })
    }
}

