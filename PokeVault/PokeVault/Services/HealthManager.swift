//
//  HealthManager.swift
//  PokeVault
//
//  Created by Samuel Luis Štúber on 27.12.2025.
//


import Foundation
import HealthKit
import Combine

class HealthManager: ObservableObject {
    static let shared = HealthManager()
    let healthStore = HKHealthStore()
    
    @Published var currentStepCount: Int = 0
    @Published var isAuthorized = false
    
    func requestAuthorization() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let types: Set = [stepType]
        
        healthStore.requestAuthorization(toShare: nil, read: types) { success, error in
            DispatchQueue.main.async {
                self.isAuthorized = success
                if success { self.fetchTodaySteps() }
            }
        }
    }
    
    func fetchTodaySteps() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else { return }
            
            let steps = Int(sum.doubleValue(for: HKUnit.count()))
            DispatchQueue.main.async {
                self.currentStepCount = steps
            }
        }
        
        healthStore.execute(query)
    }
}
