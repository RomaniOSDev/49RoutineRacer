//
//  RepairType.swift
//  49RoutineRacer
//
//  Created by Роман Главацкий on 11.01.2026.
//

import Foundation
import SwiftUI

enum RepairType {
    case stuckButton(tapsRequired: Int)
    case brokenConnection(startPoint: CGPoint, endPoint: CGPoint)
    case logicError(equation: String, answer: Int)
    case overheatedContact(holdDuration: Double)
    case stuckSlider(path: [CGPoint])
    
    var description: String {
        switch self {
        case .stuckButton(let tapsRequired):
            return "Stuck Button - Tap \(tapsRequired) times"
        case .brokenConnection:
            return "Broken Connection - Connect the points"
        case .logicError(let equation, _):
            return "Logic Error - Solve: \(equation)"
        case .overheatedContact(let duration):
            return "Overheated Contact - Hold for \(Int(duration))s"
        case .stuckSlider:
            return "Stuck Slider - Follow the path"
        }
    }
}
