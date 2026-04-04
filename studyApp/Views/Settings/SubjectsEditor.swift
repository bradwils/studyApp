import SwiftUI
import SwiftData

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
                Button(action: { isPresented.toggle() }) {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.glass)
                .clipShape(.circle)
                .shadow(radius: 10)
                .accessibilityLabel("Close editor")
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
                            Text("Date")
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
                            .padding(.trailing, 40)
                        
                        Text("\(newSubjectCode.trimmingCharacters(in: .whitespaces).count)/4")
                            .foregroundColor(newSubjectCode.count > 4 ? .red : .gray)
                            .font(.caption)
                            .padding(.trailing, 8)
                            .opacity(0.7)
                    }
                }
                .padding()
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            
            Button(action: doNothing) {
                Label("Add Subject", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            
            }
        .padding([.top, .horizontal])
    }
    func doNothing() {
        return
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
