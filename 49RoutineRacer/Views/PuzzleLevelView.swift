//
//  PuzzleLevelView.swift
//  49RoutineRacer
//
//  Created by Роман Главацкий on 11.01.2026.
//

import SwiftUI

struct PuzzleLevelView: View {
    let tool: Tool
    @ObservedObject var workshopViewModel: WorkshopViewModel
    @EnvironmentObject var progressViewModel: ProgressViewModel
    @StateObject private var viewModel: PuzzleLevelViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showCompletionAnimation = false
    
    init(tool: Tool, viewModel: WorkshopViewModel) {
        self.tool = tool
        self.workshopViewModel = viewModel
        _viewModel = StateObject(wrappedValue: PuzzleLevelViewModel(tool: tool))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.primaryBackground
                    .ignoresSafeArea()
                
                // Show different interface based on tool type
                if tool.name == "Calculator" {
                    calculatorInterface
                } else if tool.name == "Compass" {
                    compassInterface
                } else if tool.name == "Metronome" {
                    metronomeInterface
                } else if tool.name == "Flashlight" {
                    flashlightInterface
                } else if tool.name == "Timer" {
                    timerInterface
                } else if tool.name == "Stopwatch" {
                    stopwatchInterface
                }
                
                // Repair popup - positioned at top
                VStack {
                    if viewModel.showRepairPopup, let activeRepair = viewModel.activeRepair {
                        RepairPopupView(
                            element: activeRepair,
                            viewModel: viewModel
                        )
                        .padding(.top, 10)
                    }
                    Spacer()
                }
                
                // Level completion animation
                if viewModel.isLevelComplete {
                    LevelCompleteAnimationView(showAnimation: $showCompletionAnimation) {
                        let repairTime = viewModel.getRepairTime()
                        let isPerfect = viewModel.isPerfectRepair()
                        
                        // Record statistics
                        progressViewModel.recordRepair(
                            toolId: tool.id,
                            time: repairTime,
                            isPerfect: isPerfect
                        )
                        
                        workshopViewModel.markToolAsRepaired(tool.id)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(tool.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .onChange(of: viewModel.isLevelComplete) { isComplete in
                if isComplete {
                    withAnimation {
                        showCompletionAnimation = true
                    }
                }
            }
        }
    }
    
    private var calculatorInterface: some View {
        VStack(spacing: 0) {
            // Display area
            HStack {
                Spacer()
                Text("0")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.white)
                    .padding()
            }
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
            )
            .padding(.horizontal, 30)
            .padding(.top, 20)
            
            // Calculator buttons grid
            VStack(spacing: 12) {
                ForEach(buttonRows, id: \.self) { row in
                    HStack(spacing: 12) {
                        ForEach(row, id: \.self) { buttonLabel in
                            if let element = viewModel.elements.first(where: { $0.name == buttonLabel }) {
                                CalculatorButtonView(
                                    element: element,
                                    viewModel: viewModel
                                )
                            }
                        }
                    }
                }
            }
            .padding(30)
        }
    }
    
    private var compassInterface: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2
            
            ZStack {
                // Compass background circle
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 3)
                    .frame(width: 280, height: 280)
                    .position(x: centerX, y: centerY)
                
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    .frame(width: 240, height: 240)
                    .position(x: centerX, y: centerY)
                
                // Draw connection paths
                ForEach(viewModel.elements) { element in
                    // Calculate actual position relative to center
                    let actualPosition = CGPoint(
                        x: centerX + element.position.x,
                        y: centerY + element.position.y
                    )
                    
                    if element.isBroken,
                       let repairType = element.repairType,
                       case .brokenConnection(let startPoint, let endPoint) = repairType {
                        
                        // Calculate actual connection points
                        let actualStart = CGPoint(x: centerX + startPoint.x, y: centerY + startPoint.y)
                        let actualEnd = CGPoint(x: centerX + endPoint.x, y: centerY + endPoint.y)
                        
                        // Draw broken connection line (red dashed)
                        Path { path in
                            path.move(to: actualStart)
                            path.addLine(to: actualEnd)
                        }
                        .stroke(AppColors.errorAccent, style: StrokeStyle(lineWidth: 3, dash: [5, 5]))
                        
                        // Draw player's connection attempt
                        if let path = viewModel.connectionPath[element.id], path.count > 1 {
                            Path { drawingPath in
                                drawingPath.move(to: path.first!)
                                for point in path.dropFirst() {
                                    drawingPath.addLine(to: point)
                                }
                            }
                            .stroke(AppColors.successAccent, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                        }
                        
                        // Start point
                        Circle()
                            .fill(AppColors.errorAccent)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .position(actualStart)
                            .onTapGesture {
                                if viewModel.isConnecting[element.id] != true {
                                    viewModel.tapElement(element)
                                }
                            }
                        
                        // End point
                        Circle()
                            .fill(AppColors.errorAccent)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .position(actualEnd)
                    }
                    
                    // Compass needle (center)
                    if element.name == "Needle" {
                        VStack {
                            Image(systemName: "location.north.fill")
                                .font(.system(size: 40))
                                .foregroundColor(element.isBroken ? AppColors.errorAccent : AppColors.successAccent)
                            
                            if element.isBroken {
                                Text("N")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .position(actualPosition)
                        .onTapGesture {
                            viewModel.tapElement(element)
                        }
                    }
                    
                    // Direction labels (N, E, S, W)
                    if ["N", "E", "S", "W"].contains(element.name) {
                        Text(element.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(element.isBroken ? AppColors.errorAccent : AppColors.successAccent)
                            .position(actualPosition)
                            .onTapGesture {
                                if element.isBroken {
                                    viewModel.tapElement(element)
                                }
                            }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        // Find active connecting element
                        if let connectingElement = viewModel.elements.first(where: { 
                            viewModel.isConnecting[$0.id] == true 
                        }) {
                            // Use geometry coordinates directly
                            viewModel.updateConnectionPathForCompass(
                                elementId: connectingElement.id,
                                point: value.location,
                                centerX: centerX,
                                centerY: centerY
                            )
                        }
                    }
                    .onEnded { value in
                        // Complete connection
                        if let connectingElement = viewModel.elements.first(where: { 
                            viewModel.isConnecting[$0.id] == true 
                        }) {
                            viewModel.completeConnectionForCompass(
                                element: connectingElement,
                                centerX: centerX,
                                centerY: centerY
                            )
                        }
                    }
            )
        }
        .padding()
    }
    
    private var metronomeInterface: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2
            
            ZStack {
                // BPM Display
                if let bpmElement = viewModel.elements.first(where: { $0.name == "BPM" }) {
                    let actualPosition = CGPoint(
                        x: centerX + bpmElement.position.x,
                        y: centerY + bpmElement.position.y
                    )
                    
                    VStack(spacing: 8) {
                        Text("BPM")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("120")
                            .font(.system(size: 64, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .position(actualPosition)
                }
                
                // Slider
                if let sliderElement = viewModel.elements.first(where: { $0.name == "Slider" }) {
                    if sliderElement.isBroken,
                       let repairType = sliderElement.repairType,
                       case .brokenConnection(let startPoint, let endPoint) = repairType {
                        
                        // Calculate actual positions
                        let actualStart = CGPoint(x: centerX + startPoint.x, y: centerY + startPoint.y)
                        let actualEnd = CGPoint(x: centerX + endPoint.x, y: centerY + endPoint.y)
                        
                        // Broken slider line
                        Path { path in
                            path.move(to: actualStart)
                            path.addLine(to: actualEnd)
                        }
                        .stroke(AppColors.errorAccent, style: StrokeStyle(lineWidth: 4, dash: [5, 5]))
                        
                        // Player's connection attempt
                        if let path = viewModel.connectionPath[sliderElement.id], path.count > 1 {
                            Path { drawingPath in
                                drawingPath.move(to: path.first!)
                                for point in path.dropFirst() {
                                    drawingPath.addLine(to: point)
                                }
                            }
                            .stroke(AppColors.successAccent, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        }
                        
                        // Start point
                        Circle()
                            .fill(AppColors.errorAccent)
                            .frame(width: 24, height: 24)
                            .position(actualStart)
                            .onTapGesture {
                                if viewModel.isConnecting[sliderElement.id] != true {
                                    viewModel.tapElement(sliderElement)
                                }
                            }
                        
                        // End point
                        Circle()
                            .fill(AppColors.errorAccent)
                            .frame(width: 24, height: 24)
                            .position(actualEnd)
                    } else {
                        // Working slider
                        let actualPosition = CGPoint(
                            x: centerX + sliderElement.position.x,
                            y: centerY + sliderElement.position.y
                        )
                        Path { path in
                            path.move(to: actualPosition)
                            path.addLine(to: CGPoint(x: actualPosition.x + 240, y: actualPosition.y))
                        }
                        .stroke(AppColors.successAccent, style: StrokeStyle(lineWidth: 4))
                    }
                }
                
                // Buttons
                ForEach(viewModel.elements) { element in
                    if ["Play", "-", "+"].contains(element.name) {
                        let actualPosition = CGPoint(
                            x: centerX + element.position.x,
                            y: centerY + element.position.y
                        )
                        
                        Button(action: {
                            if element.isBroken {
                                viewModel.tapElement(element)
                            }
                        }) {
                            ZStack {
                                if element.name == "Play" {
                                    Circle()
                                        .fill(element.isBroken ? AppColors.errorAccent : AppColors.successAccent)
                                        .frame(width: element.size.width, height: element.size.height)
                                    
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white)
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(element.isBroken ? AppColors.errorAccent : AppColors.successAccent)
                                        .frame(width: element.size.width, height: element.size.height)
                                    
                                    Text(element.name)
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                // Progress indicator
                                if element.isBroken, viewModel.isRepairing[element.id] == true {
                                    if let tapsRequired = element.repairType?.tapsRequired() {
                                        let progress = viewModel.getRepairProgress(for: element.id)
                                        let timeLeft = viewModel.getTimeRemaining(for: element.id)
                                        
                                        VStack {
                                            Spacer()
                                            VStack(spacing: 4) {
                                                Text("\(progress)/\(tapsRequired)")
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
                                                
                                                Text(String(format: "%.1fs", timeLeft))
                                                    .font(.caption2)
                                                    .foregroundColor(.white.opacity(0.8))
                                            }
                                            .padding(4)
                                            .background(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color.black.opacity(0.3))
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        .position(actualPosition)
                        .disabled(!element.isBroken)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if let connectingElement = viewModel.elements.first(where: {
                            viewModel.isConnecting[$0.id] == true
                        }) {
                            viewModel.updateConnectionPathForCompass(
                                elementId: connectingElement.id,
                                point: value.location,
                                centerX: centerX,
                                centerY: centerY
                            )
                        }
                    }
                    .onEnded { _ in
                        if let connectingElement = viewModel.elements.first(where: {
                            viewModel.isConnecting[$0.id] == true
                        }) {
                            viewModel.completeConnectionForCompass(
                                element: connectingElement,
                                centerX: centerX,
                                centerY: centerY
                            )
                        }
                    }
            )
        }
        .padding()
    }
    
    private var flashlightInterface: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2
            
            ZStack {
                // Main flashlight button
                if let flashElement = viewModel.elements.first(where: { $0.name == "Flash" }) {
                    let actualPosition = CGPoint(
                        x: centerX + flashElement.position.x,
                        y: centerY + flashElement.position.y
                    )
                    
                    Button(action: {
                        if flashElement.isBroken {
                            viewModel.tapElement(flashElement)
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(flashElement.isBroken ? AppColors.errorAccent : AppColors.successAccent)
                                .frame(width: flashElement.size.width, height: flashElement.size.height)
                                .shadow(color: flashElement.isBroken ? .clear : AppColors.successAccent.opacity(0.5), radius: 30)
                            
                            Image(systemName: "flashlight.on.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                            
                            // Progress indicator
                            if flashElement.isBroken, viewModel.isRepairing[flashElement.id] == true {
                                if let tapsRequired = flashElement.repairType?.tapsRequired() {
                                    let progress = viewModel.getRepairProgress(for: flashElement.id)
                                    let timeLeft = viewModel.getTimeRemaining(for: flashElement.id)
                                    
                                    VStack {
                                        Spacer()
                                        VStack(spacing: 4) {
                                            Text("\(progress)/\(tapsRequired)")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                            
                                            Text(String(format: "%.1fs", timeLeft))
                                                .font(.caption2)
                                                .foregroundColor(.white.opacity(0.8))
                                        }
                                        .padding(6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color.black.opacity(0.4))
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .position(actualPosition)
                    .disabled(!flashElement.isBroken)
                }
                
                // Brightness slider
                if let brightnessElement = viewModel.elements.first(where: { $0.name == "Brightness" }) {
                    if brightnessElement.isBroken,
                       let repairType = brightnessElement.repairType,
                       case .brokenConnection(let startPoint, let endPoint) = repairType {
                        
                        // Calculate actual positions
                        let actualStart = CGPoint(x: centerX + startPoint.x, y: centerY + startPoint.y)
                        let actualEnd = CGPoint(x: centerX + endPoint.x, y: centerY + endPoint.y)
                        
                        // Broken slider line
                        Path { path in
                            path.move(to: actualStart)
                            path.addLine(to: actualEnd)
                        }
                        .stroke(AppColors.errorAccent, style: StrokeStyle(lineWidth: 4, dash: [5, 5]))
                        
                        // Player's connection attempt
                        if let path = viewModel.connectionPath[brightnessElement.id], path.count > 1 {
                            Path { drawingPath in
                                drawingPath.move(to: path.first!)
                                for point in path.dropFirst() {
                                    drawingPath.addLine(to: point)
                                }
                            }
                            .stroke(AppColors.successAccent, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        }
                        
                        // Start point
                        Circle()
                            .fill(AppColors.errorAccent)
                            .frame(width: 24, height: 24)
                            .position(actualStart)
                            .onTapGesture {
                                if viewModel.isConnecting[brightnessElement.id] != true {
                                    viewModel.tapElement(brightnessElement)
                                }
                            }
                        
                        // End point
                        Circle()
                            .fill(AppColors.errorAccent)
                            .frame(width: 24, height: 24)
                            .position(actualEnd)
                    } else {
                        // Working slider
                        let actualPosition = CGPoint(
                            x: centerX + brightnessElement.position.x,
                            y: centerY + brightnessElement.position.y
                        )
                        Path { path in
                            path.move(to: actualPosition)
                            path.addLine(to: CGPoint(x: actualPosition.x + 200, y: actualPosition.y))
                        }
                        .stroke(AppColors.successAccent, style: StrokeStyle(lineWidth: 4))
                    }
                }
                
                // Mode buttons
                ForEach(viewModel.elements) { element in
                    if ["Strobe", "SOS"].contains(element.name) {
                        let actualPosition = CGPoint(
                            x: centerX + element.position.x,
                            y: centerY + element.position.y
                        )
                        
                        Button(action: {
                            if element.isBroken {
                                viewModel.tapElement(element)
                            }
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(element.isBroken ? AppColors.errorAccent : AppColors.successAccent)
                                    .frame(width: element.size.width, height: element.size.height)
                                
                                Text(element.name)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                // Progress indicator
                                if element.isBroken, viewModel.isRepairing[element.id] == true {
                                    if let tapsRequired = element.repairType?.tapsRequired() {
                                        let progress = viewModel.getRepairProgress(for: element.id)
                                        let timeLeft = viewModel.getTimeRemaining(for: element.id)
                                        
                                        VStack {
                                            Spacer()
                                            VStack(spacing: 2) {
                                                Text("\(progress)/\(tapsRequired)")
                                                    .font(.caption2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
                                                
                                                Text(String(format: "%.1fs", timeLeft))
                                                    .font(.caption2)
                                                    .foregroundColor(.white.opacity(0.8))
                                            }
                                            .padding(2)
                                            .background(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color.black.opacity(0.3))
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        .position(actualPosition)
                        .disabled(!element.isBroken)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if let connectingElement = viewModel.elements.first(where: {
                            viewModel.isConnecting[$0.id] == true
                        }) {
                            viewModel.updateConnectionPath(elementId: connectingElement.id, point: value.location)
                        }
                    }
                    .onEnded { _ in
                        if let connectingElement = viewModel.elements.first(where: {
                            viewModel.isConnecting[$0.id] == true
                        }) {
                            viewModel.completeConnection(element: connectingElement)
                        }
                    }
            )
        }
        .padding()
    }
    
    private var timerInterface: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2
            
            ZStack {
                // Display
                if let displayElement = viewModel.elements.first(where: { $0.name == "Display" }) {
                    VStack {
                        Text("00:00")
                            .font(.system(size: 64, weight: .bold))
                            .foregroundColor(displayElement.isBroken ? AppColors.errorAccent : .white)
                    }
                    .frame(width: displayElement.size.width, height: displayElement.size.height)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(displayElement.isBroken ? AppColors.errorAccent.opacity(0.3) : Color.white.opacity(0.1))
                    )
                    .position(displayElement.position)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if displayElement.isBroken {
                                    // Start holding when user presses
                                    if viewModel.isHolding[displayElement.id] != true {
                                        // First tap - show instructions if not shown yet
                                        if viewModel.showRepairPopup == false {
                                            viewModel.tapElement(displayElement)
                                        }
                                    }
                                    viewModel.updateHoldProgress(elementId: displayElement.id, isHolding: true)
                                }
                            }
                            .onEnded { _ in
                                if displayElement.isBroken {
                                    viewModel.updateHoldProgress(elementId: displayElement.id, isHolding: false)
                                }
                            }
                    )
                    
                    // Hold progress indicator
                    if displayElement.isBroken {
                        if let repairType = displayElement.repairType,
                           case .overheatedContact(let duration) = repairType {
                            if let progress = viewModel.holdProgress[displayElement.id] {
                                VStack {
                                    Spacer()
                                    VStack(spacing: 6) {
                                        // Progress bar
                                        GeometryReader { geometry in
                                            ZStack(alignment: .leading) {
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color.white.opacity(0.2))
                                                    .frame(height: 8)
                                                
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(AppColors.successAccent)
                                                    .frame(width: geometry.size.width * CGFloat(progress / duration), height: 8)
                                            }
                                        }
                                        .frame(height: 8)
                                        
                                        Text("\(Int(progress))/\(Int(duration))s")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    }
                                    .padding(6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.black.opacity(0.4))
                                    )
                                }
                                .position(x: displayElement.position.x, y: displayElement.position.y + 70)
                            } else {
                                // Show instruction
                                VStack {
                                    Spacer()
                                    Text("Hold to repair")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                        .padding(6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color.black.opacity(0.3))
                                        )
                                }
                                .position(x: displayElement.position.x, y: displayElement.position.y + 70)
                            }
                        }
                    }
                }
                
                // Buttons
                ForEach(viewModel.elements) { element in
                    if ["Start", "-1min", "+1min", "-10sec", "+10sec"].contains(element.name) {
                        Button(action: {
                            if element.isBroken {
                                viewModel.tapElement(element)
                            }
                        }) {
                            ZStack {
                                if element.name == "Start" {
                                    Circle()
                                        .fill(element.isBroken ? AppColors.errorAccent : AppColors.successAccent)
                                        .frame(width: element.size.width, height: element.size.height)
                                    
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.white)
                                } else {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(element.isBroken ? AppColors.errorAccent : AppColors.successAccent)
                                        .frame(width: element.size.width, height: element.size.height)
                                    
                                    Text(element.name)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                
                                // Progress indicator
                                if element.isBroken, viewModel.isRepairing[element.id] == true {
                                    if let tapsRequired = element.repairType?.tapsRequired() {
                                        let progress = viewModel.getRepairProgress(for: element.id)
                                        let timeLeft = viewModel.getTimeRemaining(for: element.id)
                                        
                                        VStack {
                                            Spacer()
                                            VStack(spacing: 2) {
                                                Text("\(progress)/\(tapsRequired)")
                                                    .font(.caption2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
                                                
                                                Text(String(format: "%.1fs", timeLeft))
                                                    .font(.caption2)
                                                    .foregroundColor(.white.opacity(0.8))
                                            }
                                            .padding(2)
                                            .background(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color.black.opacity(0.3))
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        .position(element.position)
                        .disabled(!element.isBroken)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding()
    }
    
    private var stopwatchInterface: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2
            
            ZStack {
                // Display
                if let displayElement = viewModel.elements.first(where: { $0.name == "Display" }) {
                    if displayElement.isBroken,
                       let repairType = displayElement.repairType,
                       case .logicError(let equation, let answer) = repairType {
                        VStack(spacing: 12) {
                            Text(equation)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Answer: ?")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .frame(width: displayElement.size.width, height: displayElement.size.height)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AppColors.errorAccent.opacity(0.3))
                        )
                        .position(displayElement.position)
                        .onTapGesture {
                            viewModel.tapElement(displayElement)
                        }
                    } else {
                        Text("00:00.00")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: displayElement.size.width, height: displayElement.size.height)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.1))
                            )
                            .position(displayElement.position)
                    }
                }
                
                // Answer input overlay - shown when logic error is active
                if let displayElement = viewModel.elements.first(where: { $0.name == "Display" }),
                   displayElement.isBroken,
                   viewModel.showLogicInput[displayElement.id] == true,
                   let repairType = displayElement.repairType,
                   case .logicError(let equation, let answer) = repairType {
                    VStack(spacing: 20) {
                        Text("Solve: \(equation)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Tap a number:")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                        
                        // Number pad
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                ForEach([1, 2, 3], id: \.self) { digit in
                                    NumberButton(digit: digit) {
                                        viewModel.submitLogicAnswer(element: displayElement, answer: digit)
                                    }
                                }
                            }
                            
                            HStack(spacing: 12) {
                                ForEach([4, 5, 6], id: \.self) { digit in
                                    NumberButton(digit: digit) {
                                        viewModel.submitLogicAnswer(element: displayElement, answer: digit)
                                    }
                                }
                            }
                            
                            HStack(spacing: 12) {
                                ForEach([7, 8, 9], id: \.self) { digit in
                                    NumberButton(digit: digit) {
                                        viewModel.submitLogicAnswer(element: displayElement, answer: digit)
                                    }
                                }
                            }
                            
                            HStack(spacing: 12) {
                                NumberButton(digit: 0) {
                                    viewModel.submitLogicAnswer(element: displayElement, answer: 0)
                                }
                            }
                        }
                    }
                    .padding(30)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(AppColors.primaryBackground.opacity(0.95))
                            .shadow(color: .black.opacity(0.5), radius: 20)
                    )
                    .padding(.horizontal, 20)
                    .position(x: centerX, y: centerY + 100)
                }
                
                // Lap list connection
                if let lapListElement = viewModel.elements.first(where: { $0.name == "LapList" }) {
                    if lapListElement.isBroken,
                       let repairType = lapListElement.repairType,
                       case .brokenConnection(let startPoint, let endPoint) = repairType {
                        
                        Path { path in
                            path.move(to: startPoint)
                            path.addLine(to: endPoint)
                        }
                        .stroke(AppColors.errorAccent, style: StrokeStyle(lineWidth: 3, dash: [5, 5]))
                        
                        if let path = viewModel.connectionPath[lapListElement.id], path.count > 1 {
                            Path { drawingPath in
                                drawingPath.move(to: path.first!)
                                for point in path.dropFirst() {
                                    drawingPath.addLine(to: point)
                                }
                            }
                            .stroke(AppColors.successAccent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        }
                        
                        Circle()
                            .fill(AppColors.errorAccent)
                            .frame(width: 20, height: 20)
                            .position(startPoint)
                            .onTapGesture {
                                if viewModel.isConnecting[lapListElement.id] != true {
                                    viewModel.tapElement(lapListElement)
                                }
                            }
                        
                        Circle()
                            .fill(AppColors.errorAccent)
                            .frame(width: 20, height: 20)
                            .position(endPoint)
                    }
                }
                
                // Buttons
                ForEach(viewModel.elements) { element in
                    if ["Start", "Lap"].contains(element.name) {
                        Button(action: {
                            if element.isBroken {
                                viewModel.tapElement(element)
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(element.isBroken ? AppColors.errorAccent : AppColors.successAccent)
                                    .frame(width: element.size.width, height: element.size.height)
                                
                                Image(systemName: element.name == "Start" ? "play.fill" : "flag.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                                
                                // Progress indicator
                                if element.isBroken, viewModel.isRepairing[element.id] == true {
                                    if let tapsRequired = element.repairType?.tapsRequired() {
                                        let progress = viewModel.getRepairProgress(for: element.id)
                                        let timeLeft = viewModel.getTimeRemaining(for: element.id)
                                        
                                        VStack {
                                            Spacer()
                                            VStack(spacing: 2) {
                                                Text("\(progress)/\(tapsRequired)")
                                                    .font(.caption2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
                                                
                                                Text(String(format: "%.1fs", timeLeft))
                                                    .font(.caption2)
                                                    .foregroundColor(.white.opacity(0.8))
                                            }
                                            .padding(2)
                                            .background(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color.black.opacity(0.3))
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        .position(element.position)
                        .disabled(!element.isBroken)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if let connectingElement = viewModel.elements.first(where: {
                            viewModel.isConnecting[$0.id] == true
                        }) {
                            viewModel.updateConnectionPath(elementId: connectingElement.id, point: value.location)
                        }
                    }
                    .onEnded { _ in
                        if let connectingElement = viewModel.elements.first(where: {
                            viewModel.isConnecting[$0.id] == true
                        }) {
                            viewModel.completeConnection(element: connectingElement)
                        }
                    }
            )
        }
        .padding()
    }
    
    private let buttonRows = [
        ["7", "8", "9", "÷"],
        ["4", "5", "6", "×"],
        ["1", "2", "3", "-"],
        ["0", ".", "=", "+"]
    ]
}

struct CalculatorButtonView: View {
    let element: PixelElement
    @ObservedObject var viewModel: PuzzleLevelViewModel
    
    var body: some View {
        Button(action: {
            viewModel.tapElement(element)
        }) {
            ZStack {
                // Button background
                RoundedRectangle(cornerRadius: 8)
                    .fill(element.isBroken ? AppColors.errorAccent : AppColors.successAccent)
                    .frame(width: element.size.width, height: element.size.height)
                
                // Button text
                Text(element.name)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                
                // Repair progress indicator
                if element.isBroken, viewModel.isRepairing[element.id] == true {
                    VStack {
                        Spacer()
                        if let tapsRequired = element.repairType?.tapsRequired() {
                            let progress = viewModel.getRepairProgress(for: element.id)
                            let timeLeft = viewModel.getTimeRemaining(for: element.id)
                            
                            VStack(spacing: 4) {
                                Text("\(progress)/\(tapsRequired)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text(String(format: "%.1fs", timeLeft))
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(4)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.black.opacity(0.3))
                            )
                        }
                    }
                }
            }
        }
        .disabled(!element.isBroken)
    }
}

struct RepairPopupView: View {
    let element: PixelElement
    @ObservedObject var viewModel: PuzzleLevelViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            if let repairType = element.repairType {
                switch repairType {
                case .stuckButton(let tapsRequired):
                    VStack(spacing: 8) {
                        Text("Stuck Pixel Detected!")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Tap \(tapsRequired) times in 3 seconds")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                        
                        if viewModel.isRepairing[element.id] == true {
                            let timeLeft = viewModel.getTimeRemaining(for: element.id)
                            let progress = viewModel.getRepairProgress(for: element.id)
                            
                            VStack(spacing: 6) {
                                // Timer bar
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.white.opacity(0.2))
                                            .frame(height: 6)
                                        
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(AppColors.successAccent)
                                            .frame(width: geometry.size.width * CGFloat(timeLeft / 3.0), height: 6)
                                    }
                                }
                                .frame(height: 6)
                                
                                Text("\(progress)/\(tapsRequired)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: 200)
                        } else {
                            Text("Tap the broken button below!")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                case .brokenConnection:
                    VStack(spacing: 8) {
                        Text("Broken Connection Detected!")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Drag from start point to end point")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                        
                        if viewModel.isConnecting[element.id] == true {
                            Text("Keep your finger on screen!")
                                .font(.caption)
                                .foregroundColor(AppColors.successAccent)
                                .fontWeight(.bold)
                        } else {
                            Text("Tap the red point to start")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                case .logicError(let equation, let answer):
                    VStack(spacing: 8) {
                        Text("Logic Error Detected!")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Solve: \(equation)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text("Tap to enter answer: \(answer)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                case .overheatedContact(let duration):
                    VStack(spacing: 8) {
                        Text("Overheated Contact!")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Hold for \(Int(duration)) seconds")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                        
                        if viewModel.isHolding[element.id] == true {
                            if let progress = viewModel.holdProgress[element.id] {
                                VStack(spacing: 6) {
                                    GeometryReader { geometry in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.white.opacity(0.2))
                                                .frame(height: 6)
                                            
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(AppColors.successAccent)
                                                .frame(width: geometry.size.width * CGFloat(progress / duration), height: 6)
                                        }
                                    }
                                    .frame(height: 6)
                                    
                                    Text("\(Int(progress))/\(Int(duration))s")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: 200)
                            }
                        } else {
                            Text("Keep holding!")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                case .stuckSlider:
                    VStack(spacing: 8) {
                        Text("Stuck Slider!")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Follow the path with your finger")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.primaryBackground.opacity(0.95))
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 20)
        .allowsHitTesting(false)
    }
}

struct LevelCompleteAnimationView: View {
    @Binding var showAnimation: Bool
    let onComplete: () -> Void
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Animated checkmark
                ZStack {
                    Circle()
                        .fill(AppColors.successAccent)
                        .frame(width: 120, height: 120)
                        .scaleEffect(scale)
                        .opacity(opacity)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(scale)
                        .opacity(opacity)
                }
                
                // "Tool is alive!" text
                VStack(spacing: 12) {
                    Text("Tool is Alive!")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(opacity)
                    
                    Text("This tool is now available in your utilities")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .opacity(opacity)
                }
            }
            .padding(40)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                onComplete()
            }
        }
    }
}

struct NumberButton: View {
    let digit: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("\(digit)")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 70, height: 70)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.successAccent)
                )
        }
    }
}

#Preview {
    PuzzleLevelView(
        tool: Tool(name: "Calculator", icon: "number.square", status: .inProgress),
        viewModel: WorkshopViewModel()
    )
}
