//  Subjects.swift
//  studyApp
//
//  This file defines enums and models related to study subjects.

import Foundation
import Combine

// Enum for study subjects
// Use this to categorize study sessions. It's Codable for easy storage/serialization,
// and CaseIterable to get all cases (e.g., for dropdown menus).




struct Subject: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var code: String

    init(id: UUID = UUID(), name: String, code: String) { // initializing when created
        self.id = id
        self.name = name
        self.code = code
    }
}


final class SubjectStore: ObservableObject {
    //object responsible for managing the saving, retrieveing, and editing of subjects to local storage.
    @Published var subjects: [Subject] = [] // start empty
    private let fileURL: URL

    init(filename: String = "subjectsList.json") {
        // Get the app's Documents directory URL (sandboxed storage for user data), and get the first one
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        // Create the full file URL by appending the filename (e.g., subjects.json)
        self.fileURL = documentsDirectory.appendingPathComponent(filename)
        // Load existing subjects from the file on initialization
        load() //this means subjects should have now been updated with the information we need
    }



    func add(_ subject: Subject) { // the _ means you don't need to name the parameter when calling it; instead of add(subject: something), you can just do add(something)
        subjects.append(subject) //append subjects to  array
        save()
    }

    func remove(id: UUID) {
        subjects.removeAll { $0.id == id } // remove subject
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return } // load data from file; if it fails, return
        subjects = (try? JSONDecoder().decode([Subject].self, from: data)) ?? [] // decode JSON data into an array of subjects; if it fails, return an empty array
    }

    private func save() { // write subjects to file
        guard let data = try? JSONEncoder().encode(subjects) else { return }
        //guard tries to encode the data and kills the proces if it fails
        try? data.write(to: fileURL, options: [.atomic])
    }
}

