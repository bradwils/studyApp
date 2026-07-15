//  ActiveSubjectList.swift
//  studyApp
//
//  A picker component for selecting the active study subject.

import SwiftUI
import SwiftData
import OSLog



struct ActiveSubjectList: View {
    var logger = Logger(subsystem: "com.studyApp", category: "ActiveSubjectList")
    

    @Environment(\.modelContext) private var modelContext

    @Query private var subjects: [Subject]

    var isEnabled: Bool

    @Binding var selectedSubject: Subject? // the selected subject

    var body: some View {
        Group {
            if subjects.isEmpty {
                Text("No subjects yet")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Picker("Subject", selection: $selectedSubject) {
                    ForEach(subjects) { subject in
                        Text(subject.name)
                            .tag(subject as Subject?)
                    }
                }
                .pickerStyle(.menu)
                .disabled(!isEnabled)
                .onAppear { //update the view before it appears
                    if selectedSubject == nil {
                        selectedSubject = subjects.first
                        logger.log("Overrode nil subject selection, is now \(selectedSubject?.name ?? "nil")")
                    }
                }
                .onChange(of: subjects) { old, new in
                    if selectedSubject == nil, let fallback = new.first {
                        selectedSubject = fallback
                    }
                }
            }
        }
    }
}
