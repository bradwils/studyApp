import SwiftData

@Observable
final class SubjectsEditorVM {

    // State is not needed in classes; only in structs.
    // @State is only needed for Views (value types) — not for ViewModels.
    var newSubjectCode: String = ""

    var canAddSubject: Bool {
        newSubjectName.count > 0 && newSubjectName.count <= 32 &&
        newSubjectCode.count > 0 && newSubjectCode.count <= 4
    }
    
    //recieve context as soon as called
    func addSubject(context: ModelContext) {
        guard canAddSubject else { return }
        context.insert(Subject(name: newSubjectName, code: newSubjectCode.uppercased()))
        newSubjectName = ""
        newSubjectCode = ""
    }

    func removeSubject(_ subject: Subject, context: ModelContext) {
        context.delete(subject)
    }
}
