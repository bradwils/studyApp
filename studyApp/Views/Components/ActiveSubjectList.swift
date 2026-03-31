//  ActiveSubjectList.swift
//  studyApp
//
//  A picker component for selecting the active study subject.

import SwiftUI

struct ActiveSubjectList: View {
    var subjects: [Subject]
    @Binding var selection: Subject?
    var isEnabled: Bool

    var body: some View {
        Group {
            if subjects.isEmpty {
                Text("No subjects yet")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Picker("Subject", selection: selectionBinding) {
                    ForEach(subjects) { subject in
                        Text(subject.name)
                            .tag(subject)
                    }
                }
                .pickerStyle(.menu)
                .disabled(!isEnabled)
                .onAppear {
                    if selection == nil {
                        selection = subjects.first
                    }
                }
                .onChange(of: subjects) { _, new in
                    if selection == nil {
                        selection = new.first
                        return
                    }

                    if let selectedID = selection?.id,
                       !new.contains(where: { $0.id == selectedID }) {
                        selection = new.first
                    }
                }
            }
        }
    }

    private var selectionBinding: Binding<Subject> {
        Binding(
            get: { selection ?? subjects.first! },
            set: { selection = $0 }
        )
    }
}
