//
//  Tool.swift
//  49RoutineRacer
//
//  Created by Роман Главацкий on 11.01.2026.
//

import Foundation
import SwiftUI

struct Tool: Identifiable {
    let id: UUID
    let name: String
    let icon: String
    var status: ToolStatus
    var elements: [PixelElement]
    
    init(id: UUID = UUID(), name: String, icon: String, status: ToolStatus = .locked, elements: [PixelElement] = []) {
        self.id = id
        self.name = name
        self.icon = icon
        self.status = status
        self.elements = elements
    }
}
