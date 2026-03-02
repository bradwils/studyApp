import SwiftUI

struct SubjectsEditor: View {
    @StateObject private var userProfileStore = UserProfileStore.shared
    @State private var newSubjectName = ""
    @State private var newSubjectCode = ""
    @FocusState private var isNameFocused: Bool
    @Binding var isPresented: Bool

    private var canAddSubject: Bool {
        !newSubjectName.trimmingCharacters(in: .whitespaces).isEmpty &&
        newSubjectCode.trimmingCharacters(in: .whitespaces).count <= 4 &&
        !newSubjectCode.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 20) {

            HStack {
                Text("Edit Subjects")
                    .font(.title.weight(.bold))
                    
                Spacer()
                //UITWEAK: Enhanced close button with scale effect for tactile feedback
                Button(action: { isPresented.toggle() }) {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.glass)
                .clipShape(.circle)
                // Enhanced shadow for better depth perception
                .shadow(
                    color: Color.black.opacity(0.15),
                    radius: 12,
                    x: 0,
                    y: 4
                )
                .accessibilityLabel("Close editor")
                //UIEND
            }
            
            List {
                if userProfileStore.profile.subjects.isEmpty {
                    Text("No subjects")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(userProfileStore.profile.subjects) { subject in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(subject.name)
                                    .font(.headline)
                                Text(subject.code)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(formatCreatedDate(subject.createdAt))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(Color.clear)
                    }
                    .onDelete { indexSet in
                        withAnimation(.easeInOut) {
                            indexSet.forEach { index in
                                let subject = userProfileStore.profile.subjects[index]
                                userProfileStore.removeSubject(id: subject.id)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            
            //UITWEAK: Enhanced input area with glass effect for native iOS feel
            ZStack {

                VStack(spacing: 12) {
                    TextField("Subject name", text: $newSubjectName)
                        .textContentType(.givenName)
                        .submitLabel(.next)
                        .focused($isNameFocused)

                    ZStack(alignment: .trailing) {
                        TextField("Subject code (e.g. MATH101)", text: $newSubjectCode)
                            .autocorrectionDisabled()
                            .submitLabel(.done)
                            .onSubmit(addSubject)
                            .padding(.trailing, 40)

                        Text("\(newSubjectCode.trimmingCharacters(in: .whitespaces).count)/4")
                            .foregroundColor(newSubjectCode.count > 4 ? .red : .gray)
                            .font(.caption)
                            .padding(.trailing, 8)
                            .opacity(0.7)
                    }
                }
                .padding()
                // Use glass effect instead of thinMaterial for consistency
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .glassEffect(.regular.interactive())
                )
                // Enhanced shadow for depth
                .shadow(
                    color: Color.black.opacity(0.08),
                    radius: 12,
                    x: 0,
                    y: 4
                )
            }
            //UIEND
            
            Button(action: addSubject) {
                Label("Add Subject", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canAddSubject)
            .opacity(canAddSubject ? 1 : 0.5)
        }
        .padding([.top, .horizontal])
    }

    private func addSubject() {
        guard canAddSubject else { return }
        let subject = Subject(name: newSubjectName, code: newSubjectCode.uppercased())
        userProfileStore.addSubject(subject)
        newSubjectName = ""
        newSubjectCode = ""
        isNameFocused = true
    }
    
    private func formatCreatedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2).ignoresSafeArea()
        VStack {
            Spacer()
            SubjectsEditor(isPresented: .constant(true))
        }
    }
}
