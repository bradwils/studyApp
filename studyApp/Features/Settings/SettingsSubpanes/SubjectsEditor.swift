import SwiftUI

struct SubjectsEditor: View {
    @StateObject private var subjectStore = SubjectStore() // persistent source of truth for subjects
    @State private var newSubjectName = ""
    @State private var newSubjectCode = ""
    @FocusState private var isNameFocused: Bool
    @Binding var isPresented: Bool  // Binding to control sheet dismissal


    private var canAddSubject: Bool {
        !newSubjectName.trimmingCharacters(in: .whitespaces).isEmpty && //name cant be empty
        newSubjectCode.trimmingCharacters(in: .whitespaces).count <= 4 && //subject code max 4 chars
        !newSubjectCode.trimmingCharacters(in: .whitespaces).isEmpty //code cant be empty

    }

    var body: some View {
        VStack(spacing: 20) {

            HStack {
                Text("Edit Subjects")
                    .font(.title.weight(.bold))
                    
                Spacer()
                Button(action: { isPresented.toggle() }) {
//                    Text ("Close")
                    Image(systemName: "xmark")
                    
                }
                .buttonStyle(.glass)
//                .buttonStyle(.close)
                .clipShape(.circle)
                .shadow(radius: 10)

                
                
                
                .accessibilityLabel("Close editor")
            }
            
            // list existing subjects with inline delete controls
            ScrollView {
                LazyVStack(spacing: 12) {
                    if subjectStore.subjects.isEmpty {
                        Text("No subjects")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(.thinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    } else {
                        ForEach(subjectStore.subjects) { subject in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(subject.name)
                                        .font(.headline)
                                    Text(subject.code)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                
                                Button {
                                    withAnimation(.easeInOut) {
                                        subjectStore.remove(id: subject.id)
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Delete \(subject.name)")
                            }
                            .padding()
                            .background(.thinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            
                        }
                    }
                }
            }
            
            // capture new subject details before appending to the store
            
            
            ZStack {
                
                VStack(spacing: 12) {
                    TextField("Subject name", text: $newSubjectName)
                        .textContentType(.givenName)
                        .submitLabel(.next)
                        .focused($isNameFocused)
                        
                    ZStack(alignment: .trailing) {  // Overlay count on the right


                        TextField("Subject code (e.g. MATH101)", text: $newSubjectCode)
                            .autocorrectionDisabled()
                            .submitLabel(.done)
                            .onSubmit(addSubject)
                            .padding(.trailing, 40)  // Add padding to avoid overlap with count

                        Text("\(newSubjectCode.trimmingCharacters(in: .whitespaces).count)/4")  // Character count (adjust max as needed)
                            .foregroundColor(newSubjectCode.count > 4 ? .red : .gray)  // Color based on limit
                            .font(.caption)
                            .padding(.trailing, 8)
                            .opacity(0.7)


                    }
                }
                .padding()
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                
            }
            
            // primary action for creating the subject
            
            Button(action: addSubject) {
                Label("Add Subject", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canAddSubject)
            .opacity(canAddSubject ? 1 : 0.5)
        }

        // sheet-style container with blur + lift
        
        .padding([.top, .horizontal])
    }

    private func addSubject() {
        guard canAddSubject else { return }
        let subject = Subject(name: newSubjectName, code: newSubjectCode.uppercased())
        subjectStore.add(subject) // persist immediately so UI reflects the change
        newSubjectName = ""
        newSubjectCode = ""
        isNameFocused = true
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2).ignoresSafeArea()
        VStack {
            Spacer()
            SubjectsEditor(isPresented: .constant(true))  // Creates a constant binding for preview
        }
    }
}
