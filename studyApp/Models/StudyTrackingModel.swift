//  StudyTrackingModel.swift
//  studyApp
//
//  DEPRECATED: This file has been refactored for MVVM.
//  - Data models (StudySession, StudyBreak, SessionLocation) → Models/StudySession.swift
//  - ViewModel (StudyTrackingViewModel) → ViewModels/StudyTrackingViewModel.swift
//
//  This file provides backward compatibility and can be removed after verifying build success.

import Foundation
import Combine

// MARK: - Backward Compatibility Alias

typealias StudyTrackingModel = StudyTrackingViewModel
