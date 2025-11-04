//  Subjects.swift
//  studyApp
//
//  This file defines enums and models related to study subjects.

import Foundation

// Enum for study subjects
// Use this to categorize study sessions. It's Codable for easy storage/serialization,
// and CaseIterable to get all cases (e.g., for dropdown menus).
enum Subject: String, Codable, CaseIterable {
    case math = "Math"
    case science = "Science"
    case history = "History"
    case english = "English"
    case art = "Art"
    case other = "Other"
    
    // Optional: Add a display name or icon if needed
    var displayName: String {
        switch self {
        case .math: return "Mathematics"
        case .science: return "Science"
        case .history: return "History"
        case .english: return "English"
        case .art: return "Art"
        case .other: return "Other"
        }
    }
}
