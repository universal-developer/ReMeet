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
    
    func checkUserExists(_ id: UUID) async -> Bool {
        do {
            let response = try await client
                .from("profiles")
                .select("id")
                .eq("id", value: id.uuidString)
                .limit(1)
                .execute()

            let rawData = response.data
            let json = try JSONSerialization.jsonObject(with: rawData, options: []) as? [[String: Any]]
            return (json?.isEmpty == false)
        } catch {
            print("❌ Error checking user existence: \(error)")
            return false
        }
    }


    private init() {
        supabaseURL = URL(string: Secrets.supabaseURL)!
        client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: Secrets.supabaseKey)
    }
}
