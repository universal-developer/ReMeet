//
//  SupabaseManager.swift
//  ReMeet
//
//  Created by Artush on 14/03/2025.
//

import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        let supabaseURL = URL(string: "https://qquleedmyqrpznddhsbv.supabase.co")!
        let supabaseKey = "https://qquleedmyqrpznddhsbv.supabase.co"
        
        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey
        )
    }
}
