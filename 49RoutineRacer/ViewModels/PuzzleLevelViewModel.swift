//
//  PuzzleLevelViewModel.swift
//  49RoutineRacer
//
//  Created by Роман Главацкий on 11.01.2026.
//

import Foundation
import SwiftUI
import Combine

class PuzzleLevelViewModel: ObservableObject {
    @Published var elements: [PixelElement] = []
    @Published var isLevelComplete: Bool = false
    @Published var activeRepair: PixelElement?
    @Published var repairProgress: [UUID: Int] = [:]
    @Published var repairTimer: [UUID: Timer] = [:]
    @Published var timeRemaining: [UUID: Double] = [:]
    @Published var isRepairing: [UUID: Bool] = [:]
    @Published var showRepairPopup: Bool = false
    @Published var connectionPath: [UUID: [CGPoint]] = [:]
    @Published var isConnecting: [UUID: Bool] = [:]
    @Published var holdProgress: [UUID: Double] = [:]
    @Published var isHolding: [UUID: Bool] = [:]
    @Published var sliderPath: [UUID: [CGPoint]] = [:]
    @Published var isFollowingSlider: [UUID: Bool] = [:]
    @Published var levelStartTime: Date = Date()
    @Published var mistakesCount: Int = 0
    @Published var logicAnswer: [UUID: Int] = [:]
    @Published var showLogicInput: [UUID: Bool] = [:]
    
    let tool: Tool
    private var cancellables = Set<AnyCancellable>()
    
    init(tool: Tool) {
        self.tool = tool
        self.elements = tool.elements
        self.levelStartTime = Date()
    }
    
    func tapElement(_ element: PixelElement) {
        guard element.isBroken else { return }
        
        // If already repairing this element, count taps
        if isRepairing[element.id] == true {
            handleRepairTap(element)
            return
        }
        
        // Show repair popup and start mini-game
        activeRepair = element
        showRepairPopup = true
        
        if let repairType = element.repairType {
            switch repairType {
            case .stuckButton(let tapsRequired):
                startStuckPixelMiniGame(element: element, tapsRequired: tapsRequired)
            case .brokenConnection(let startPoint, let endPoint):
                startConnectionRepair(element: element, startPoint: startPoint, endPoint: endPoint)
            case .logicError(let equation, let answer):
                startLogicErrorRepair(element: element, answer: answer)
            case .overheatedContact(let duration):
                startOverheatedContactRepair(element: element, duration: duration)
            case .stuckSlider(let path):
                startStuckSliderRepair(element: element, path: path)
            }
        }
    }
    
    private func startStuckPixelMiniGame(element: PixelElement, tapsRequired: Int) {
        isRepairing[element.id] = true
        repairProgress[element.id] = 0
        timeRemaining[element.id] = 3.0
        
        // Close popup after a short delay to allow player to see instructions
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.showRepairPopup = false
        }
        
        // Start timer
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            if var timeLeft = self.timeRemaining[element.id] {
                timeLeft -= 0.1
                self.timeRemaining[element.id] = max(0, timeLeft)
                
                if timeLeft <= 0 {
                    // Time's up - check if repair was successful
                    self.checkRepairCompletion(element: element, tapsRequired: tapsRequired)
                    timer.invalidate()
                    self.repairTimer.removeValue(forKey: element.id)
                }
            }
        }
        
        repairTimer[element.id] = timer
    }
    
    private func handleRepairTap(_ element: PixelElement) {
        guard let tapsRequired = element.repairType?.tapsRequired(),
              isRepairing[element.id] == true else { return }
        
        let currentTaps = repairProgress[element.id] ?? 0
        repairProgress[element.id] = currentTaps + 1
        
        // Check if completed before time runs out
        if repairProgress[element.id]! >= tapsRequired {
            repairElement(element)
        }
    }
    
    private func checkRepairCompletion(element: PixelElement, tapsRequired: Int) {
        let currentTaps = repairProgress[element.id] ?? 0
        
        if currentTaps >= tapsRequired {
            repairElement(element)
        } else {
            // Failed - reset
            isRepairing[element.id] = false
            repairProgress[element.id] = 0
            timeRemaining[element.id] = nil
            showRepairPopup = false
            activeRepair = nil
        }
    }
    
    func repairElement(_ element: PixelElement) {
        if let index = elements.firstIndex(where: { $0.id == element.id }) {
            elements[index].isBroken = false
            elements[index].repairType = nil
            repairProgress.removeValue(forKey: element.id)
            repairTimer[element.id]?.invalidate()
            repairTimer.removeValue(forKey: element.id)
            timeRemaining.removeValue(forKey: element.id)
            isRepairing.removeValue(forKey: element.id)
            showRepairPopup = false
            activeRepair = nil
            
            checkLevelCompletion()
        }
    }
    
    func checkLevelCompletion() {
        isLevelComplete = elements.allSatisfy { !$0.isBroken }
    }
    
    func getRepairProgress(for elementId: UUID) -> Int {
        return repairProgress[elementId] ?? 0
    }
    
    func getTimeRemaining(for elementId: UUID) -> Double {
        return timeRemaining[elementId] ?? 0
    }
    
    private func startConnectionRepair(element: PixelElement, startPoint: CGPoint, endPoint: CGPoint) {
        isConnecting[element.id] = true
        showRepairPopup = true
        
        // Close popup after showing instructions
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.showRepairPopup = false
        }
    }
    
    func updateConnectionPath(elementId: UUID, point: CGPoint) {
        if isConnecting[elementId] == true {
            if connectionPath[elementId] == nil {
                // Find the element to get start point
                if let element = elements.first(where: { $0.id == elementId }),
                   let repairType = element.repairType,
                   case .brokenConnection(let startPoint, _) = repairType {
                    // For non-compass tools, use absolute coordinates
                    connectionPath[elementId] = [startPoint]
                } else {
                    connectionPath[elementId] = []
                }
            }
            // Only add point if it's different from last point (to avoid duplicates)
            if let lastPoint = connectionPath[elementId]?.last,
               distance(lastPoint, point) > 5 {
                connectionPath[elementId]?.append(point)
            }
        }
    }
    
    func updateConnectionPathForCompass(elementId: UUID, point: CGPoint, centerX: CGFloat, centerY: CGFloat) {
        if isConnecting[elementId] == true {
            if connectionPath[elementId] == nil {
                // Find the element to get start point
                if let element = elements.first(where: { $0.id == elementId }),
                   let repairType = element.repairType,
                   case .brokenConnection(let startPoint, _) = repairType {
                    // Calculate actual start point for compass (relative to center)
                    let actualStart = CGPoint(x: centerX + startPoint.x, y: centerY + startPoint.y)
                    connectionPath[elementId] = [actualStart]
                } else {
                    connectionPath[elementId] = []
                }
            }
            // Add point directly (already in correct coordinate system)
            if let lastPoint = connectionPath[elementId]?.last,
               distance(lastPoint, point) > 5 {
                connectionPath[elementId]?.append(point)
            }
        }
    }
    
    func completeConnection(element: PixelElement) {
        guard let repairType = element.repairType,
              case .brokenConnection(let startPoint, let endPoint) = repairType,
              var path = connectionPath[element.id],
              path.count > 5 else {
            // Reset if connection failed
            isConnecting[element.id] = false
            connectionPath[element.id] = nil
            return
        }
        
        // For non-compass tools, use absolute coordinates
        let actualStart = startPoint
        let actualEnd = endPoint
        
        // Add end point if close enough
        if let lastPoint = path.last, distance(lastPoint, actualEnd) > 30 {
            path.append(actualEnd)
        }
        
        // Check if path connects start and end points (with tolerance)
        let startDistance = distance(path.first ?? .zero, actualStart)
        let endDistance = distance(path.last ?? .zero, actualEnd)
        
        if startDistance < 40 && endDistance < 40 {
            repairElement(element)
        } else {
            // Reset if connection failed
            isConnecting[element.id] = false
            connectionPath[element.id] = nil
            mistakesCount += 1
        }
    }
    
    func completeConnectionForCompass(element: PixelElement, centerX: CGFloat, centerY: CGFloat) {
        guard let repairType = element.repairType,
              case .brokenConnection(let startPoint, let endPoint) = repairType,
              var path = connectionPath[element.id],
              path.count > 5 else {
            // Reset if connection failed
            isConnecting[element.id] = false
            connectionPath[element.id] = nil
            return
        }
        
        // Calculate actual points for compass (relative to center)
        let actualStart = CGPoint(x: centerX + startPoint.x, y: centerY + startPoint.y)
        let actualEnd = CGPoint(x: centerX + endPoint.x, y: centerY + endPoint.y)
        
        // Add end point if close enough
        if let lastPoint = path.last, distance(lastPoint, actualEnd) > 30 {
            path.append(actualEnd)
        }
        
        // Check if path connects start and end points (with tolerance)
        let startDistance = distance(path.first ?? .zero, actualStart)
        let endDistance = distance(path.last ?? .zero, actualEnd)
        
        if startDistance < 40 && endDistance < 40 {
            repairElement(element)
        } else {
            // Reset if connection failed
            isConnecting[element.id] = false
            connectionPath[element.id] = nil
            mistakesCount += 1
        }
    }
    
    func cancelConnection(elementId: UUID) {
        isConnecting[elementId] = false
        connectionPath[elementId] = nil
    }
    
    private func startOverheatedContactRepair(element: PixelElement, duration: Double) {
        holdProgress[element.id] = 0.0
        showRepairPopup = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.showRepairPopup = false
        }
    }
    
    func updateHoldProgress(elementId: UUID, isHolding: Bool) {
        guard let element = elements.first(where: { $0.id == elementId }),
              let repairType = element.repairType,
              case .overheatedContact(let duration) = repairType else {
            return
        }
        
        if isHolding {
            // Start holding
            if self.isHolding[elementId] != true {
                self.isHolding[elementId] = true
                holdProgress[elementId] = 0.0
                
                // Start timer to track progress
                let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
                    guard let self = self else {
                        timer.invalidate()
                        return
                    }
                    
                    if self.isHolding[elementId] == true {
                        let currentProgress = self.holdProgress[elementId] ?? 0.0
                        self.holdProgress[elementId] = min(currentProgress + 0.1, duration)
                        
                        if self.holdProgress[elementId]! >= duration {
                            self.repairElement(element)
                            timer.invalidate()
                            self.repairTimer.removeValue(forKey: elementId)
                        }
                    } else {
                        // Released - stop timer
                        timer.invalidate()
                        self.repairTimer.removeValue(forKey: elementId)
                    }
                }
                
                repairTimer[elementId] = timer
            }
        } else {
            // Release detected - reset if not complete
            if self.isHolding[elementId] == true {
                if let progress = holdProgress[elementId], progress < duration {
                    self.isHolding[elementId] = false
                    holdProgress[elementId] = 0.0
                    mistakesCount += 1
                    repairTimer[elementId]?.invalidate()
                    repairTimer.removeValue(forKey: elementId)
                }
            }
        }
    }
    
    private func startStuckSliderRepair(element: PixelElement, path: [CGPoint]) {
        isFollowingSlider[element.id] = true
        sliderPath[element.id] = []
        showRepairPopup = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.showRepairPopup = false
        }
    }
    
    func updateSliderPath(elementId: UUID, point: CGPoint) {
        if isFollowingSlider[elementId] == true {
            if sliderPath[elementId] == nil {
                sliderPath[elementId] = []
            }
            
            if let lastPoint = sliderPath[elementId]?.last,
               distance(lastPoint, point) > 5 {
                sliderPath[elementId]?.append(point)
                
                // Check if following the path correctly
                checkSliderPath(elementId: elementId)
            }
        }
    }
    
    private func checkSliderPath(elementId: UUID) {
        guard let element = elements.first(where: { $0.id == elementId }),
              let repairType = element.repairType,
              case .stuckSlider(let targetPath) = repairType,
              let currentPath = sliderPath[elementId],
              currentPath.count > 10 else {
            return
        }
        
        // Check if path follows target path (simplified check)
        var matches = 0
        for targetPoint in targetPath {
            for currentPoint in currentPath {
                if distance(targetPoint, currentPoint) < 30 {
                    matches += 1
                    break
                }
            }
        }
        
        // If matches most points, repair is successful
        if matches >= targetPath.count * 2 / 3 {
            repairElement(element)
        }
    }
    
    func completeSliderPath(elementId: UUID) {
        if let element = elements.first(where: { $0.id == elementId }) {
            checkSliderPath(elementId: elementId)
            if isFollowingSlider[elementId] == true {
                isFollowingSlider[elementId] = false
                sliderPath[elementId] = nil
            }
        }
    }
    
    func getRepairTime() -> TimeInterval {
        return Date().timeIntervalSince(levelStartTime)
    }
    
    func isPerfectRepair() -> Bool {
        return mistakesCount == 0
    }
    
    private func startLogicErrorRepair(element: PixelElement, answer: Int) {
        showLogicInput[element.id] = true
        showRepairPopup = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.showRepairPopup = false
        }
    }
    
    func submitLogicAnswer(element: PixelElement, answer: Int) {
        if let repairType = element.repairType,
           case .logicError(_, let correctAnswer) = repairType {
            if answer == correctAnswer {
                repairElement(element)
            } else {
                mistakesCount += 1
                showLogicInput[element.id] = false
            }
        }
    }
    
    private func distance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        let dx = p1.x - p2.x
        let dy = p1.y - p2.y
        return sqrt(dx * dx + dy * dy)
    }
    
    deinit {
        repairTimer.values.forEach { $0.invalidate() }
    }
}

extension RepairType {
    func tapsRequired() -> Int? {
        if case .stuckButton(let taps) = self {
            return taps
        }
        return nil
    }
}
