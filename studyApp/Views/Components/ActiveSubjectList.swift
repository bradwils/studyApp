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

    // A deleted subject leaves the view model holding a stale reference; fall back to the first one.
    private func repairSelection() {
        guard isEnabled else { return }
        if let selectedSubject, subjects.contains(selectedSubject) { return }
        selectedSubject = subjects.first
        logger.log("Repaired subject selection, is now \(selectedSubject?.name ?? "nil")")
    }

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
                .onAppear(perform: repairSelection)
                .onChange(of: subjects) { repairSelection() }
                .onChange(of: isEnabled) { repairSelection() }
            }
        }
    }
}
