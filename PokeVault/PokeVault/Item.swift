//
//  Item.swift
//  PokeVault
//
//  Created by Samuel Luis Štúber on 26.12.2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
