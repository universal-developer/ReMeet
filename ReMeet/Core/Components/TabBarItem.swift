//
//  TabBarItem.swift
//  ReMeet
//
//  Created by Artush on 08/04/2025.
//

import Foundation

enum TabBarItem: CaseIterable, Hashable {
    case home
    case explore
    case qr
    case messages
    case profile

    var iconName: String {
        switch self {
        case .home: return "tab_map"
        case .explore: return "tab_search"
        case .qr: return "tab_plus" // if you only have one version
        case .messages: return "tab_chat"
        case .profile: return "tab_profile"
        }
    }

    var filledIconName: String {
        switch self {
        case .home: return "tab_map_filled"
        case .explore: return "tab_search" // assuming you only have outline
        case .qr: return "tab_plus"          // same as above
        case .messages: return "tab_chat_filled"
        case .profile: return "tab_profile_filled"
        }
    }
}
