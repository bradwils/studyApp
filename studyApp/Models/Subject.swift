//  Subject.swift
//  studyApp
//
//  Model representing a study subject.

import Foundation
import SwiftData

@Model
final class Subject {
    var id: UUID
    var name: String
    var code: String
    var createdAt: Date
    var educationLevel: standardEducationLevel?
    var remoteID: Int?
    

    init(id: UUID = UUID(), name: String, code: String, createdAt: Date = Date(), educationLevel: standardEducationLevel?) {
        self.id = id
        self.name = name
        self.code = code
        self.createdAt = createdAt
        self.educationLevel = educationLevel
        self.remoteID = nil
        
    }
    
    enum standardEducationLevel: String, CaseIterable, Codable {
        //caseiteraible -> for each in standardEduationlevel.allCases { print(each) } // Prints all cases
        case hsc = "HSC"
        case vce = "VCE"
        case qce = "QCE"
        case wave = "WACE"
        case sace = "SACE"
        case tce = "TCE"
        case actssc = "ACT Senior Secondary Certificate"
        case ntce = "NTCE"
    }
}
