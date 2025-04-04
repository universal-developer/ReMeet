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
    let supabaseURL: URL

    var publicStorageUrlBase: String {
        return "\(supabaseURL.absoluteString)/storage/v1/object/public"
    }

    private init() {
        supabaseURL = URL(string: Secrets.supabaseURL)!
        client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: Secrets.supabaseKey)
    }
}
