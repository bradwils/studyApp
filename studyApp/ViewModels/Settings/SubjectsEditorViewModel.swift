import Foundation
import Combine

final class SubjectsEditorViewModel: ObservableObject {
    @Published var newSubjectName = ""
    @Published var newSubjectCode = ""
    @Published private(set) var subjects: [Subject] = []

    private let userProfileStore: UserProfileStore
    private var cancellables: Set<AnyCancellable> = []

    init(userProfileStore: UserProfileStore = .shared) {
        self.userProfileStore = userProfileStore

        userProfileStore.$profile
            .map(\.subjects)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.subjects = $0
            }
            .store(in: &cancellables)
    }

    var trimmedSubjectName: String {
        newSubjectName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedSubjectCode: String {
        newSubjectCode.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedSubjectCodeCount: Int {
        trimmedSubjectCode.count
    }

    var canAddSubject: Bool {
        !trimmedSubjectName.isEmpty &&
        !trimmedSubjectCode.isEmpty &&
        trimmedSubjectCodeCount <= 4
    }

    @discardableResult
    func addSubject() -> Bool {
        guard canAddSubject else { return false }

        let subject = Subject(name: trimmedSubjectName, code: trimmedSubjectCode.uppercased())
        userProfileStore.addSubject(subject)

        newSubjectName = ""
        newSubjectCode = ""
        return true
    }

    func removeSubjects(at offsets: IndexSet) {
        for index in offsets {
            guard subjects.indices.contains(index) else { continue }
            userProfileStore.removeSubject(id: subjects[index].id)
        }
    }

    func relativeCreatedDate(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
