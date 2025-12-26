//
//  APIModels.swift
//  PokeVault
//
//  Created by Petr Herčko on 26.12.2025.
//

import Foundation

// 1. Matches the { "count": ..., "next": ..., "results": [...] } object
struct PokemonListResponse: Codable {
    let count: Int
    let next: String?      // This holds the link to the next page
    let previous: String?
    let results: [PokemonListEntry]
}

// 2. Matches the objects inside "results": [ { "name": "bulbasaur", "url": "..." } ]
struct PokemonListEntry: Codable {
    let name: String
    let url: String
    
    var id: Int {
        let urlString = url
        
        var cleanString = urlString
        if cleanString.hasSuffix("/") {
            cleanString.removeLast()
        }
        
        if let lastPart = cleanString.components(separatedBy: "/").last,
           let idNumber = Int(lastPart) {
            return idNumber
        }
        
        // Debugging: If this prints "0", we know exactly where the bug is
        print("⚠️ FAILED TO PARSE ID FROM: \(url)")
        return 0
    }
}
