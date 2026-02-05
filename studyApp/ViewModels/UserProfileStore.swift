//  UserProfileStore.swift
//  studyApp
//
//  Store responsible for managing the local user profile with persistence.

import Foundation
import Combine

final class UserProfileStore: ObservableObject {
    static let shared = UserProfileStore()

    @Published private(set) var profile: UserProfile
    private let fileURL: URL
    private let legacySubjectsURL: URL
    private let seedSampleData: Bool

    init(
        filename: String = "userProfile.json",
        legacySubjectsFilename: String = "subjectsList.json",
        directory: URL? = nil,
        seedSampleData: Bool = true
    ) {
        let documentsDirectory = directory ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = documentsDirectory.appendingPathComponent(filename)
        self.legacySubjectsURL = documentsDirectory.appendingPathComponent(legacySubjectsFilename)
        self.seedSampleData = seedSampleData

        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.profile = decoded
        } else {
            self.profile = UserProfileStore.defaultProfile()
            migrateLegacySubjectsIfNeeded()
            save()
        }

#if DEBUG
        if seedSampleData, profile.subjects.isEmpty {
            profile.subjects = [
                Subject(name: "Mathematics", code: "MATH101"),
                Subject(name: "Chemistry", code: "CHEM110"),
                Subject(name: "History", code: "HIST205")
            ]
            save()
        }
#endif
    }

    func addSubject(_ subject: Subject) {
        profile.subjects.append(subject)
        profile.lastActiveAt = Date()
        save()
    }

    func removeSubject(id: UUID) {
        profile.subjects.removeAll { $0.id == id }
        profile.lastActiveAt = Date()
        save()
    }

    func updateProfile(_ update: (inout UserProfile) -> Void) {
        update(&profile)
        profile.lastActiveAt = Date()
        save()
    }

    private func migrateLegacySubjectsIfNeeded() {
        guard let data = try? Data(contentsOf: legacySubjectsURL),
              let legacySubjects = try? JSONDecoder().decode([Subject].self, from: data),
              !legacySubjects.isEmpty
        else { return }

        profile.subjects = legacySubjects
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }

    private static func defaultProfile() -> UserProfile {
        let now = Date()
        return UserProfile(
            id: UUID(),
            userHandle: "",
            profileName: "",
            userProfilePicturePath: nil,
            auth: AuthState(service: .anon, lastSignInAt: nil),
            createdAt: now,
            lastActiveAt: now,
            subjects: []
        )
    }
}
