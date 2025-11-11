//  SocialFeed.swift
//  studyApp
//
//  Models for the social feed feature.

import Foundation

struct ListItem: Identifiable {
    let id = UUID()
    var name: String
    var subject: String
    var subjectCode: String
    var isLocked: Bool
    var timer: String
    var photo: String
    var dailyTotalTime: String
}
