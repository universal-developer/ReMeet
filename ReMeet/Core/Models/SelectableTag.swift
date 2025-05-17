//
//  SelectableTag.swift
//  ReMeet
//
//  Created by Artush on 16/05/2025.
//


import Foundation

struct SelectableTag: Identifiable, Hashable {
    let id = UUID()
    let label: String
    let iconName: String
}
