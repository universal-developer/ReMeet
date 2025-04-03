//
//  SupabaseManager.swift
//  ReMeet
//
//  Created by Artush on 14/03/2025.
//

import Supabase
import Foundation

class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        let url = URL(string: Secrets.supabaseURL)!
        client = SupabaseClient(supabaseURL: url, supabaseKey: Secrets.supabaseKey)
    }
}
