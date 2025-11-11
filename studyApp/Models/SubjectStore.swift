//  SubjectStore.swift
//  studyApp
//
//  Store responsible for managing subjects with local persistence.

import Foundation
import Combine

final class SubjectStore: ObservableObject {
    @Published var subjects: [Subject] = []
    private let fileURL: URL

    init(filename: String = "subjectsList.json") {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = documentsDirectory.appendingPathComponent(filename)
        load()

#if DEBUG
        if subjects.isEmpty {
            subjects = [
                Subject(name: "Mathematics", code: "MATH101"),
                Subject(name: "Chemistry", code: "CHEM110"),
                Subject(name: "History", code: "HIST205")
            ]
        }
#endif
    }

    func add(_ subject: Subject) {
        subjects.append(subject)
        save()
    }

    func remove(id: UUID) {
        subjects.removeAll { $0.id == id }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        subjects = (try? JSONDecoder().decode([Subject].self, from: data)) ?? []
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(subjects) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }
}
