//
//  Achievement.swift
//  49RoutineRacer
//
//  Created by Роман Главацкий on 11.01.2026.
//

import Foundation

struct Achievement: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let icon: String
    var isUnlocked: Bool
    let requirement: AchievementRequirement
    
    init(id: UUID = UUID(), title: String, description: String, icon: String, isUnlocked: Bool = false, requirement: AchievementRequirement) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.isUnlocked = isUnlocked
        self.requirement = requirement
    }
}

enum AchievementRequirement: Codable {
    case repairTools(count: Int)
    case perfectRepair(toolName: String)
    case speedRepair(seconds: Int)
    case noMistakes(count: Int)
    case totalRepairs(count: Int)
}
