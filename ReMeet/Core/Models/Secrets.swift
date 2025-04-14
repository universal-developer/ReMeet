//
//  Secrets.swift
//  ReMeet
//
//  Created by Artush on 03/04/2025.
//

import Foundation

struct Secrets {
    static var supabaseURL: String {
        getValue(for: "SUPABASE_URL")
    }

    static var supabaseKey: String {
        getValue(for: "SUPABASE_KEY")
    }
    
    static var mapboxToken: String {
        getValue(for: "MAPBOX_PUBLIC_TOKEN")
    }

    private static func getValue(for key: String) -> String {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let value = dict[key] as? String else {
            fatalError("Missing key: \(key) in Secrets.plist")
        }
        return value
    }
}
