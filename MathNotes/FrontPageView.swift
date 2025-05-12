//
//  FrontPageView.swift
//  MathNotes
//
//  Created by Ayush Vattoli on 2025-05-10.
//

import SwiftUI

struct FrontPageView: View {
    @EnvironmentObject var folderStore: FolderStore
    @State private var selectedFolderIndex: Int? = nil
    @State private var selectedFile: File?
    @State private var isCreatingFile = false
    @State private var newFileName = ""
    @State private var isCreatingFolder = false
    @State private var newFolderName = ""

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                // Left: Folder List
                VStack(spacing: 0) {
                    HStack {
                        Text("Folders")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        Button(action: {
                            newFolderName = ""
                            isCreatingFolder = true
                        }) {
                            Image(systemName: "folder.badge.plus")
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black)
                    
                    List {
                        ForEach(Array(folderStore.folders.enumerated()), id: \.element.id) { index, folder in
                            Button(action: {
                                selectedFolderIndex = index
                            }) {
                                HStack {
                                    Text(folder.name)
                                        .padding(.vertical, 6)
                                        .foregroundColor(selectedFolderIndex == index ? .white : .primary)
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .listRowBackground(selectedFolderIndex == index ? Color.blue : Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .background(Color(UIColor.systemBackground))
                }
                .frame(width: 200)
                .frame(maxHeight: .infinity)
                .background(Color.black.opacity(0.1))
                
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
                folderStore.addFile(to: folderStore.folders[index], file: newFile)
            })
            Button("Cancel", role: .cancel) {}
        })
        .alert("New Folder", isPresented: $isCreatingFolder, actions: {
            TextField("Folder name", text: $newFolderName)
            Button("Create", action: {
                guard !newFolderName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                folderStore.addFolder(name: newFolderName)
            })
            Button("Cancel", role: .cancel) {}
        })
        .onAppear {
            if selectedFolderIndex == nil && !folderStore.folders.isEmpty {
                selectedFolderIndex = 0 // Select first folder by default
            }
            folderStore.loadDrawingsForAllFiles()
        }
    }
}

