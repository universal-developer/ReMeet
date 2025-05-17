//
//  TagData.swift
//  ReMeet
//
//  Created by Artush on 16/05/2025.
//


import Foundation

enum TagData {
    static let personality = [
        SelectableTag(label: "Introvert", iconName: "moon"),
        SelectableTag(label: "Funny", iconName: "face.smiling"),
        SelectableTag(label: "Open-minded", iconName: "sparkles"),
        SelectableTag(label: "Extrovert", iconName: "sun.max")
    ]

    static let languages = [
        SelectableTag(label: "French", iconName: "f.circle"),
        SelectableTag(label: "English", iconName: "e.circle"),
        SelectableTag(label: "Russian", iconName: "r.circle"),
        SelectableTag(label: "Spanish", iconName: "s.circle")
    ]

    static let lifestyle = [
        SelectableTag(label: "Smokes", iconName: "flame"),
        SelectableTag(label: "Doesn't drink", iconName: "drop"),
        SelectableTag(label: "Night owl", iconName: "moon.stars"),
        SelectableTag(label: "Early bird", iconName: "sunrise")
    ]
}
