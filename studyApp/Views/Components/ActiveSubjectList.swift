//  ActiveSubjectList.swift
//  studyApp
//
//  A picker component for selecting the active study subject.

import SwiftUI

struct ActiveSubjectList: View {
    @ObservedObject var studyTrackingModel: StudyTrackingViewModel
    var subjects: [Subject]
    var isEnabled: Bool

    @State private var subjectSelection: Subject?

    var body: some View {
        //UITWEAK
        // Apply glass effect to the subject picker for a cohesive, modern look
        // This makes the picker feel more integrated with other glass elements in the UI
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
                .onAppear { //update the view before it appears
                    if subjectSelection == nil {
                        subjectSelection = studyTrackingModel.selectedSubject ?? subjects.first
                    }
                    if studyTrackingModel.selectedSubject == nil, let fallback = subjectSelection {
                        studyTrackingModel.updateSubjectSelection(fallback)
                    }
                }
                .onChange(of: subjects) { old, new in
                    if subjectSelection == nil, let fallback = new.first {
                        subjectSelection = fallback
                        studyTrackingModel.updateSubjectSelection(fallback)
                    }
                }
                .onChange(of: subjectSelection) { old, new in //if selected subject changes,
                    studyTrackingModel.updateSubjectSelection(new)
                }
                .onChange(of: studyTrackingModel.selectedSubject) { old, new in //if subject changes elsewhere, update
                    if new != subjectSelection {
                        subjectSelection = new
                    }
                }
            }
        }
        .padding(.horizontal, 12) // Add horizontal padding for visual spacing
        .padding(.vertical, 8) // Add vertical padding for better touch target
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.06)) // Subtle background for glass effect
        )
        .glassEffect(.regular.interactive()) // Interactive glass effect for picker responsiveness
        //UIEND
    }

    private var selectionBinding: Binding<Subject> {
        Binding(
            get: { subjectSelection ?? subjects.first! },
            set: { subjectSelection = $0 }
        )
    }
}
