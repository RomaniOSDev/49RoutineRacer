//
//  PixelElement.swift
//  49RoutineRacer
//
//  Created by Роман Главацкий on 11.01.2026.
//

import Foundation
import SwiftUI

struct PixelElement: Identifiable {
    let id: UUID
    let name: String
    var isBroken: Bool
    var repairType: RepairType?
    var position: CGPoint
    var size: CGSize
    
    init(id: UUID = UUID(), name: String, isBroken: Bool, repairType: RepairType? = nil, position: CGPoint, size: CGSize) {
        self.id = id
        self.name = name
        self.isBroken = isBroken
        self.repairType = repairType
        self.position = position
        self.size = size
    }
}
