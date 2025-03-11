//
//  Country.swift
//  ReMeet
//
//  Created by Artush on 11/03/2025.
//

import Foundation

struct Country: Identifiable, Comparable {
    let id = UUID()
    let code: String      // e.g., "US"
    let name: String      // e.g., "United States"
    let phoneCode: String // e.g., "1"
    
    static func < (lhs: Country, rhs: Country) -> Bool {
        return lhs.name < rhs.name
    }
}
