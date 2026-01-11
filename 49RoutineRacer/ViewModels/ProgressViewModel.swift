//
//  ProgressViewModel.swift
//  49RoutineRacer
//
//  Created by Роман Главацкий on 11.01.2026.
//

import Foundation
import SwiftUI
import Combine

class ProgressViewModel: ObservableObject {
    @Published var progress: GameProgress = GameProgress()
    @Published var achievements: [Achievement] = []
    
    private let progressKey = "GameProgress"
    private let achievementsKey = "Achievements"
    
    init() {
        loadProgress()
        initializeAchievements()
        checkAchievements()
    }
    
    private func loadProgress() {
        if let data = UserDefaults.standard.data(forKey: progressKey),
           let decoded = try? JSONDecoder().decode(GameProgress.self, from: data) {
            progress = decoded
        }
    }
    
    private func saveProgress() {
        if let encoded = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(encoded, forKey: progressKey)
        }
    }
    
    private func initializeAchievements() {
        achievements = [
            Achievement(
                title: "First Repair",
                description: "Repair your first tool",
                icon: "wrench.fill",
                requirement: .repairTools(count: 1)
            ),
            Achievement(
                title: "Master Repairman",
                description: "Repair 5 tools",
                icon: "star.fill",
                requirement: .repairTools(count: 5)
            ),
            Achievement(
                title: "Speed Demon",
                description: "Repair a tool in under 30 seconds",
                icon: "bolt.fill",
                requirement: .speedRepair(seconds: 30)
            ),
            Achievement(
                title: "Perfect Repair",
                description: "Repair a tool without any mistakes",
                icon: "checkmark.circle.fill",
                requirement: .perfectRepair(toolName: "")
            ),
            Achievement(
                title: "No Mistakes",
                description: "Repair 3 tools perfectly",
                icon: "checkmark.seal.fill",
                requirement: .noMistakes(count: 3)
            ),
            Achievement(
                title: "Veteran",
                description: "Repair 10 tools total",
                icon: "medal.fill",
                requirement: .totalRepairs(count: 10)
            )
        ]
        
        // Load unlocked achievements
        if let data = UserDefaults.standard.data(forKey: achievementsKey),
           let unlockedIds = try? JSONDecoder().decode(Set<UUID>.self, from: data) {
            for i in achievements.indices {
                if unlockedIds.contains(achievements[i].id) {
                    achievements[i].isUnlocked = true
                }
            }
        }
    }
    
    func recordRepair(toolId: UUID, time: TimeInterval, isPerfect: Bool) {
        progress.addRepair(toolId: toolId, time: time, isPerfect: isPerfect)
        saveProgress()
        checkAchievements()
    }
    
    private func checkAchievements() {
        var updated = false
        
        for i in achievements.indices {
            if achievements[i].isUnlocked { continue }
            
            let unlocked = checkAchievementRequirement(achievements[i].requirement)
            if unlocked {
                achievements[i].isUnlocked = true
                updated = true
            }
        }
        
        if updated {
            saveAchievements()
        }
    }
    
    private func checkAchievementRequirement(_ requirement: AchievementRequirement) -> Bool {
        switch requirement {
        case .repairTools(let count):
            return progress.toolsRepaired.count >= count
        case .perfectRepair:
            return progress.perfectRepairs > 0
        case .speedRepair(let seconds):
            if let fastest = progress.fastestRepair {
                return fastest <= Double(seconds)
            }
            return false
        case .noMistakes(let count):
            return progress.perfectRepairs >= count
        case .totalRepairs(let count):
            return progress.totalRepairs >= count
        }
    }
    
    private func saveAchievements() {
        let unlockedIds = Set(achievements.filter { $0.isUnlocked }.map { $0.id })
        if let encoded = try? JSONEncoder().encode(unlockedIds) {
            UserDefaults.standard.set(encoded, forKey: achievementsKey)
        }
    }
    
    func resetProgress() {
        progress = GameProgress()
        for i in achievements.indices {
            achievements[i].isUnlocked = false
        }
        saveProgress()
        saveAchievements()
    }
}
