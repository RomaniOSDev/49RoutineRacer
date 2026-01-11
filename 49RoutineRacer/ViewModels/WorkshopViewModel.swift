//
//  WorkshopViewModel.swift
//  49RoutineRacer
//
//  Created by Роман Главацкий on 11.01.2026.
//

import Foundation
import SwiftUI
import Combine

class WorkshopViewModel: ObservableObject {
    @Published var tools: [Tool] = []
    
    private let toolsKey = "SavedTools"
    
    init() {
        loadTools()
    }
    
    private func loadTools() {
        // Initialize default tools with sequential unlock
        tools = [
            Tool(
                name: "Calculator",
                icon: "number.square",
                status: .inProgress,
                elements: createCalculatorElements()
            ),
            Tool(
                name: "Compass",
                icon: "location.north",
                status: .locked,
                elements: createCompassElements()
            ),
            Tool(
                name: "Metronome",
                icon: "metronome",
                status: .locked,
                elements: createMetronomeElements()
            ),
            Tool(
                name: "Flashlight",
                icon: "flashlight.on.fill",
                status: .locked,
                elements: createFlashlightElements()
            ),
            Tool(
                name: "Timer",
                icon: "timer",
                status: .locked,
                elements: createTimerElements()
            ),
            Tool(
                name: "Stopwatch",
                icon: "stopwatch",
                status: .locked,
                elements: createStopwatchElements()
            )
        ]
        
        // Load saved progress
        loadSavedProgress()
        
        // Check which tools should be unlocked based on repaired tools
        checkUnlockedTools()
    }
    
    private func loadSavedProgress() {
        if let data = UserDefaults.standard.data(forKey: toolsKey),
           let savedToolIds = try? JSONDecoder().decode([UUID].self, from: data) {
            // Restore repaired status
            for toolId in savedToolIds {
                if let index = tools.firstIndex(where: { $0.id == toolId }) {
                    tools[index].status = .repaired
                }
            }
        }
    }
    
    private func saveProgress() {
        let repairedToolIds = tools.filter { $0.status == .repaired }.map { $0.id }
        if let encoded = try? JSONEncoder().encode(repairedToolIds) {
            UserDefaults.standard.set(encoded, forKey: toolsKey)
        }
    }
    
    func resetProgress() {
        // Reset all tools to initial state
        for i in tools.indices {
            if i == 0 {
                tools[i].status = .inProgress
            } else {
                tools[i].status = .locked
            }
        }
        saveProgress()
    }
    
    private func checkUnlockedTools() {
        // First tool is always unlocked
        // Each tool unlocks after previous one is repaired
        var previousRepaired = true
        
        for i in tools.indices {
            if i == 0 {
                // First tool starts as inProgress
                if tools[i].status == .repaired {
                    previousRepaired = true
                }
            } else {
                if previousRepaired && tools[i].status == .locked {
                    tools[i].status = .inProgress
                }
                previousRepaired = tools[i].status == .repaired
            }
        }
    }
    
    private func createCalculatorElements() -> [PixelElement] {
        // Create calculator button elements with 3-4 randomly broken ones
        var elements: [PixelElement] = []
        let buttonSize = CGSize(width: 70, height: 70)
        let spacing: CGFloat = 12
        let startX: CGFloat = 30
        let startY: CGFloat = 150
        
        let buttons = [
            ("7", CGPoint(x: startX, y: startY)),
            ("8", CGPoint(x: startX + buttonSize.width + spacing, y: startY)),
            ("9", CGPoint(x: startX + (buttonSize.width + spacing) * 2, y: startY)),
            ("÷", CGPoint(x: startX + (buttonSize.width + spacing) * 3, y: startY)),
            ("4", CGPoint(x: startX, y: startY + buttonSize.height + spacing)),
            ("5", CGPoint(x: startX + buttonSize.width + spacing, y: startY + buttonSize.height + spacing)),
            ("6", CGPoint(x: startX + (buttonSize.width + spacing) * 2, y: startY + buttonSize.height + spacing)),
            ("×", CGPoint(x: startX + (buttonSize.width + spacing) * 3, y: startY + buttonSize.height + spacing)),
            ("1", CGPoint(x: startX, y: startY + (buttonSize.height + spacing) * 2)),
            ("2", CGPoint(x: startX + buttonSize.width + spacing, y: startY + (buttonSize.height + spacing) * 2)),
            ("3", CGPoint(x: startX + (buttonSize.width + spacing) * 2, y: startY + (buttonSize.height + spacing) * 2)),
            ("-", CGPoint(x: startX + (buttonSize.width + spacing) * 3, y: startY + (buttonSize.height + spacing) * 2)),
            ("0", CGPoint(x: startX, y: startY + (buttonSize.height + spacing) * 3)),
            (".", CGPoint(x: startX + buttonSize.width + spacing, y: startY + (buttonSize.height + spacing) * 3)),
            ("=", CGPoint(x: startX + (buttonSize.width + spacing) * 2, y: startY + (buttonSize.height + spacing) * 3)),
            ("+", CGPoint(x: startX + (buttonSize.width + spacing) * 3, y: startY + (buttonSize.height + spacing) * 3))
        ]
        
        // Randomly select 3-4 buttons to break
        let brokenCount = Int.random(in: 3...4)
        var brokenIndices = Set<Int>()
        while brokenIndices.count < brokenCount {
            brokenIndices.insert(Int.random(in: 0..<buttons.count))
        }
        
        for (index, (label, position)) in buttons.enumerated() {
            let isBroken = brokenIndices.contains(index)
            let repairType: RepairType? = isBroken ? .stuckButton(tapsRequired: Int.random(in: 8...12)) : nil
            
            elements.append(PixelElement(
                name: label,
                isBroken: isBroken,
                repairType: repairType,
                position: position,
                size: buttonSize
            ))
        }
        
        return elements
    }
    
    private func createCompassElements() -> [PixelElement] {
        var elements: [PixelElement] = []
        // Use relative positions (0,0 = center), will be adjusted in view based on actual center
        let radius: CGFloat = 120
        
        // Create compass dial with connection points
        // Outer ring connection points - relative to center (0,0)
        let connectionPoints = [
            ("N", CGPoint(x: 0, y: -radius), CGPoint(x: 0, y: -radius + 40)),
            ("E", CGPoint(x: radius, y: 0), CGPoint(x: radius - 40, y: 0)),
            ("S", CGPoint(x: 0, y: radius), CGPoint(x: 0, y: radius - 40)),
            ("W", CGPoint(x: -radius, y: 0), CGPoint(x: -radius + 40, y: 0))
        ]
        
        // Randomly select 2-3 connections to break
        let brokenCount = Int.random(in: 2...3)
        var brokenIndices = Set<Int>()
        while brokenIndices.count < brokenCount {
            brokenIndices.insert(Int.random(in: 0..<connectionPoints.count))
        }
        
        for (index, (label, startPoint, endPoint)) in connectionPoints.enumerated() {
            let isBroken = brokenIndices.contains(index)
            let repairType: RepairType? = isBroken ? .brokenConnection(startPoint: startPoint, endPoint: endPoint) : nil
            
            elements.append(PixelElement(
                name: label,
                isBroken: isBroken,
                repairType: repairType,
                position: startPoint,
                size: CGSize(width: 30, height: 30)
            ))
        }
        
        // Add center compass needle (can be stuck)
        let needleBroken = Int.random(in: 0...1) == 0
        if needleBroken {
            elements.append(PixelElement(
                name: "Needle",
                isBroken: true,
                repairType: .stuckButton(tapsRequired: Int.random(in: 10...15)),
                position: CGPoint(x: 0, y: 0),
                size: CGSize(width: 60, height: 60)
            ))
        }
        
        return elements
    }
    
    private func createMetronomeElements() -> [PixelElement] {
        var elements: [PixelElement] = []
        // Use relative positions, will be adjusted in view
        let centerX: CGFloat = 0  // Will be calculated in view
        let centerY: CGFloat = 0
        
        // BPM display - relative to center
        let bpmDisplay = PixelElement(
            name: "BPM",
            isBroken: false,
            repairType: nil,
            position: CGPoint(x: centerX, y: centerY - 100),
            size: CGSize(width: 200, height: 80)
        )
        elements.append(bpmDisplay)
        
        // Slider track (broken connection) - relative to center
        let sliderStart = CGPoint(x: centerX - 120, y: centerY)
        let sliderEnd = CGPoint(x: centerX + 120, y: centerY)
        let sliderBroken = Int.random(in: 0...1) == 0
        
        if sliderBroken {
            elements.append(PixelElement(
                name: "Slider",
                isBroken: true,
                repairType: .brokenConnection(startPoint: sliderStart, endPoint: sliderEnd),
                position: sliderStart,
                size: CGSize(width: 240, height: 20)
            ))
        }
        
        // Play/Stop button
        let playButtonBroken = Int.random(in: 0...1) == 0
        elements.append(PixelElement(
            name: "Play",
            isBroken: playButtonBroken,
            repairType: playButtonBroken ? .stuckButton(tapsRequired: Int.random(in: 10...15)) : nil,
            position: CGPoint(x: centerX, y: centerY + 120),
            size: CGSize(width: 100, height: 100)
        ))
        
        // Minus button
        let minusBroken = Int.random(in: 0...1) == 0
        elements.append(PixelElement(
            name: "-",
            isBroken: minusBroken,
            repairType: minusBroken ? .stuckButton(tapsRequired: Int.random(in: 8...12)) : nil,
            position: CGPoint(x: centerX - 80, y: centerY + 50),
            size: CGSize(width: 60, height: 60)
        ))
        
        // Plus button
        let plusBroken = Int.random(in: 0...1) == 0
        elements.append(PixelElement(
            name: "+",
            isBroken: plusBroken,
            repairType: plusBroken ? .stuckButton(tapsRequired: Int.random(in: 8...12)) : nil,
            position: CGPoint(x: centerX + 80, y: centerY + 50),
            size: CGSize(width: 60, height: 60)
        ))
        
        return elements
    }
    
    private func createFlashlightElements() -> [PixelElement] {
        var elements: [PixelElement] = []
        // Use relative positions, will be adjusted in view
        let centerX: CGFloat = 0
        let centerY: CGFloat = 0
        
        // Main flashlight button (large circle) - relative to center
        let mainButtonBroken = Int.random(in: 0...1) == 0
        elements.append(PixelElement(
            name: "Flash",
            isBroken: mainButtonBroken,
            repairType: mainButtonBroken ? .stuckButton(tapsRequired: Int.random(in: 12...18)) : nil,
            position: CGPoint(x: centerX, y: centerY - 50),
            size: CGSize(width: 180, height: 180)
        ))
        
        // Brightness slider connection - relative to center
        let brightnessStart = CGPoint(x: centerX - 100, y: centerY + 100)
        let brightnessEnd = CGPoint(x: centerX + 100, y: centerY + 100)
        let brightnessBroken = Int.random(in: 0...1) == 0
        
        if brightnessBroken {
            elements.append(PixelElement(
                name: "Brightness",
                isBroken: true,
                repairType: .brokenConnection(startPoint: brightnessStart, endPoint: brightnessEnd),
                position: brightnessStart,
                size: CGSize(width: 200, height: 20)
            ))
        }
        
        // Mode buttons (Strobe, SOS, etc.)
        let modeButtons = [
            ("Strobe", CGPoint(x: centerX - 60, y: centerY + 180)),
            ("SOS", CGPoint(x: centerX + 60, y: centerY + 180))
        ]
        
        for (label, position) in modeButtons {
            let isBroken = Int.random(in: 0...2) == 0 // 33% chance
            elements.append(PixelElement(
                name: label,
                isBroken: isBroken,
                repairType: isBroken ? .stuckButton(tapsRequired: Int.random(in: 8...12)) : nil,
                position: position,
                size: CGSize(width: 80, height: 50)
            ))
        }
        
        return elements
    }
    
    func unlockTool(_ tool: Tool) {
        if let index = tools.firstIndex(where: { $0.id == tool.id }) {
            if tools[index].status == .locked {
                tools[index].status = .inProgress
            }
        }
    }
    
    func markToolAsRepaired(_ toolId: UUID) {
        if let index = tools.firstIndex(where: { $0.id == toolId }) {
            tools[index].status = .repaired
            // Unlock next tool
            checkUnlockedTools()
            // Save progress
            saveProgress()
        }
    }
    
    private func createTimerElements() -> [PixelElement] {
        var elements: [PixelElement] = []
        let screenWidth: CGFloat = UIScreen.main.bounds.width
        let screenHeight: CGFloat = UIScreen.main.bounds.height
        let centerX: CGFloat = screenWidth / 2
        let centerY: CGFloat = screenHeight / 2
        
        // Timer display
        let displayBroken = Int.random(in: 0...1) == 0
        elements.append(PixelElement(
            name: "Display",
            isBroken: displayBroken,
            repairType: displayBroken ? .overheatedContact(holdDuration: Double.random(in: 2.0...3.0)) : nil,
            position: CGPoint(x: centerX, y: centerY - 80),
            size: CGSize(width: 200, height: 100)
        ))
        
        // Start/Pause button
        let playBroken = Int.random(in: 0...1) == 0
        elements.append(PixelElement(
            name: "Start",
            isBroken: playBroken,
            repairType: playBroken ? .stuckButton(tapsRequired: Int.random(in: 10...15)) : nil,
            position: CGPoint(x: centerX, y: centerY + 80),
            size: CGSize(width: 80, height: 80)
        ))
        
        // Time adjustment buttons
        let buttons = [
            ("-1min", CGPoint(x: centerX - 80, y: centerY + 20)),
            ("+1min", CGPoint(x: centerX + 80, y: centerY + 20)),
            ("-10sec", CGPoint(x: centerX - 80, y: centerY + 100)),
            ("+10sec", CGPoint(x: centerX + 80, y: centerY + 100))
        ]
        
        for (label, position) in buttons {
            let isBroken = Int.random(in: 0...2) == 0
            elements.append(PixelElement(
                name: label,
                isBroken: isBroken,
                repairType: isBroken ? .stuckButton(tapsRequired: Int.random(in: 8...12)) : nil,
                position: position,
                size: CGSize(width: 60, height: 50)
            ))
        }
        
        return elements
    }
    
    private func createStopwatchElements() -> [PixelElement] {
        var elements: [PixelElement] = []
        let screenWidth: CGFloat = UIScreen.main.bounds.width
        let screenHeight: CGFloat = UIScreen.main.bounds.height
        let centerX: CGFloat = screenWidth / 2
        let centerY: CGFloat = screenHeight / 2
        
        // Stopwatch display
        let displayBroken = Int.random(in: 0...1) == 0
        elements.append(PixelElement(
            name: "Display",
            isBroken: displayBroken,
            repairType: displayBroken ? .logicError(equation: "2 + 2", answer: 4) : nil,
            position: CGPoint(x: centerX, y: centerY - 60),
            size: CGSize(width: 220, height: 120)
        ))
        
        // Start/Stop button
        let startBroken = Int.random(in: 0...1) == 0
        elements.append(PixelElement(
            name: "Start",
            isBroken: startBroken,
            repairType: startBroken ? .stuckButton(tapsRequired: Int.random(in: 12...18)) : nil,
            position: CGPoint(x: centerX - 60, y: centerY + 80),
            size: CGSize(width: 80, height: 80)
        ))
        
        // Lap/Reset button
        let lapBroken = Int.random(in: 0...1) == 0
        elements.append(PixelElement(
            name: "Lap",
            isBroken: lapBroken,
            repairType: lapBroken ? .stuckButton(tapsRequired: Int.random(in: 8...12)) : nil,
            position: CGPoint(x: centerX + 60, y: centerY + 80),
            size: CGSize(width: 80, height: 80)
        ))
        
        // Lap times list connection
        let lapListStart = CGPoint(x: centerX - 100, y: centerY + 20)
        let lapListEnd = CGPoint(x: centerX + 100, y: centerY + 20)
        let lapListBroken = Int.random(in: 0...1) == 0
        
        if lapListBroken {
            elements.append(PixelElement(
                name: "LapList",
                isBroken: true,
                repairType: .brokenConnection(startPoint: lapListStart, endPoint: lapListEnd),
                position: lapListStart,
                size: CGSize(width: 200, height: 30)
            ))
        }
        
        return elements
    }
}
