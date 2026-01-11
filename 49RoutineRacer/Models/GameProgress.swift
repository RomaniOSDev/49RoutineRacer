//
//  GameProgress.swift
//  49RoutineRacer
//
//  Created by Роман Главацкий on 11.01.2026.
//

import Foundation

struct GameProgress: Codable {
    var totalRepairs: Int = 0
    var perfectRepairs: Int = 0
    var totalPlayTime: TimeInterval = 0
    var fastestRepair: TimeInterval?
    var toolsRepaired: Set<UUID> = []
    var achievements: Set<UUID> = []
    var lastPlayedDate: Date = Date()
    
    mutating func addRepair(toolId: UUID, time: TimeInterval, isPerfect: Bool) {
        totalRepairs += 1
        if isPerfect {
            perfectRepairs += 1
        }
        toolsRepaired.insert(toolId)
        
        if fastestRepair == nil || time < fastestRepair! {
            fastestRepair = time
        }
    }
}
