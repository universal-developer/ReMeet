//
//  Notifications+Name.swift
//  ReMeet
//
//  Created by Artush on 01/05/2025.
//

import Foundation

extension Notification.Name {
    static let mapDidBecomeVisible = Notification.Name("mapDidBecomeVisible")
    static let zoomOnUser = Notification.Name("zoomOnUser")
    static let didTapUserAnnotation = Notification.Name("didTapUserAnnotation")
    static let shouldUpdateUserAnnotation = Notification.Name("shouldUpdateUserAnnotation")
    static let didToggleGhostMode = Notification.Name("didToggleGhostMode")
    static let didExternallyUpdateGhostStatus = Notification.Name("didExternallyUpdateGhostStatus")
    static let didUpdateMainProfilePhoto = Notification.Name("didUpdateMainProfilePhoto")
}

