import SwiftUI
import SwiftData

struct SubjectsEditor: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm = SubjectsEditorVM()
    @FocusState private var isNameFocused: Bool
    
    @Binding var isPresented: Bool
    @Binding var currentDetent: PresentationDetent

    @Query var subjects: [Subject]

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
                if subjects.isEmpty {
                    Text("No subjects")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(subjects) { subject in
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
                                vm.removeSubject(subjects[index], context: modelContext)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)

            ZStack {
                VStack(spacing: 12) {
                    TextField("Subject name", text: $vm.newSubjectName)
                        .textContentType(.givenName)
                        .submitLabel(.next)
                        .focused($isNameFocused)
                    
                    DotStyleDivider(orientation: .horizontal)

                    ZStack(alignment: .trailing) {
                        TextField("Subject code (e.g. MATH101)", text: $vm.newSubjectCode)
                            .autocorrectionDisabled()
                            .submitLabel(.done)
                            .onSubmit { vm.addSubject(context: modelContext) }
                            .padding(.trailing, 40)

                        Text("\(vm.newSubjectCode.count)/4")
                            .foregroundColor(vm.newSubjectCode.count > 4 ? .red : .gray)
                            .font(.caption)
                            .padding(.trailing, 8)
                            .opacity(0.7)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            Button(action: { vm.addSubject(context: modelContext) }) {
                Label("Add Subject", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(Color(.red))

                    
            }
            .buttonStyle(.borderedProminent)
            .disabled(!vm.canAddSubject)
            .opacity(vm.canAddSubject ? 1 : 0.5)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))


        }
        .padding([.top, .horizontal])
    }

    private func formatCreatedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    
    @Previewable @State var currentDetent: PresentationDetent = .medium
    
    ZStack {
        Color.gray.opacity(0.2).ignoresSafeArea()
        VStack {
            Spacer()
            SubjectsEditor(isPresented: .constant(true), currentDetent: $currentDetent)
                
        }
    }
    .modelContainer(for: Subject.self, inMemory: true)
}
