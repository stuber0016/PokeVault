//
//  CurrencyManager.swift
//  PokeVault
//
//  Created by Samuel Luis Štúber on 27.12.2025.
//


import SwiftUI
import Combine

class CurrencyManager: ObservableObject {
    static let shared = CurrencyManager()
    
    @AppStorage("pokeCoins") var coins: Int = 100 // Start with 100 free coins
    @AppStorage("lastClaimedSteps") var lastClaimedSteps: Int = 0
    @AppStorage("lastClaimDate") var lastClaimDate: Double = Date().timeIntervalSince1970
    
    // Config: 100 Steps = 1 Coin
    let stepsPerCoin = 10
    
    func claimSteps(currentHealthKitSteps: Int) -> Int {
        // Reset counter if it's a new day
        if !Calendar.current.isDateInToday(Date(timeIntervalSince1970: lastClaimDate)) {
            lastClaimedSteps = 0
            lastClaimDate = Date().timeIntervalSince1970
        }
        
        let newSteps = currentHealthKitSteps - lastClaimedSteps
        
        if newSteps >= stepsPerCoin {
            let coinsToEarn = newSteps / stepsPerCoin
            let stepsUsed = coinsToEarn * stepsPerCoin
            
            coins += coinsToEarn
            lastClaimedSteps += stepsUsed
            
            return coinsToEarn
        }
        
        return 0
    }
}
