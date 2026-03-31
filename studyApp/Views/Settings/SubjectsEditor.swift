import SwiftUI

struct SubjectsEditor: View {
    @StateObject private var viewModel = SubjectsEditorViewModel()
    @FocusState private var isNameFocused: Bool
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 20) {

            HStack {
                Text("Edit Subjects")
                    .font(.title.weight(.bold))
                    
                Spacer()
                Button(action: { isPresented.toggle() }) {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.glass)
                .clipShape(.circle)
                .shadow(radius: 10)
                .accessibilityLabel("Close editor")
            }
            
            List {
                if viewModel.subjects.isEmpty {
                    Text("No subjects")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(viewModel.subjects) { subject in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(subject.name)
                                    .font(.headline)
                                Text(subject.code)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(viewModel.relativeCreatedDate(for: subject.createdAt))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(Color.clear)
                    }
                    .onDelete { indexSet in
                        withAnimation(.easeInOut) {
                            viewModel.removeSubjects(at: indexSet)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            
            ZStack {
                
                VStack(spacing: 12) {
                    TextField("Subject name", text: $viewModel.newSubjectName)
                        .textContentType(.givenName)
                        .submitLabel(.next)
                        .focused($isNameFocused)
                        
                    ZStack(alignment: .trailing) {
                        TextField("Subject code (e.g. MATH101)", text: $viewModel.newSubjectCode)
                            .autocorrectionDisabled()
                            .submitLabel(.done)
                            .onSubmit(addSubject)
                            .padding(.trailing, 40)

                        Text("\(viewModel.trimmedSubjectCodeCount)/4")
                            .foregroundColor(viewModel.trimmedSubjectCodeCount > 4 ? .red : .gray)
                            .font(.caption)
                            .padding(.trailing, 8)
                            .opacity(0.7)
                    }
                }
                .padding()
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            
            Button(action: addSubject) {
                Label("Add Subject", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canAddSubject)
            .opacity(viewModel.canAddSubject ? 1 : 0.5)
        }
        .padding([.top, .horizontal])
    }

    private func addSubject() {
        if viewModel.addSubject() {
            isNameFocused = true
        }
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
