//
//  UtilityView.swift
//  49RoutineRacer
//
//  Created by Роман Главацкий on 11.01.2026.
//

import SwiftUI
import Combine

struct UtilityView: View {
    let tool: Tool
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.primaryBackground
                    .ignoresSafeArea()
                
                Group {
                    switch tool.name {
                    case "Calculator":
                        CalculatorUtilityView()
                    case "Compass":
                        CompassUtilityView()
                    case "Metronome":
                        MetronomeUtilityView()
                    case "Flashlight":
                        FlashlightUtilityView()
                    default:
                        Text("Utility not implemented")
                            .foregroundColor(.white)
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
        }
    }
}

struct CalculatorUtilityView: View {
    @State private var display = "0"
    @State private var currentNumber: Double = 0
    @State private var previousNumber: Double = 0
    @State private var operation: String?
    @State private var shouldResetDisplay = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Display
            HStack {
                Spacer()
                Text(display)
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.white)
                    .padding()
            }
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
            )
            .padding(.horizontal)
            
            // Buttons
            VStack(spacing: 12) {
                ForEach(buttonRows, id: \.self) { row in
                    HStack(spacing: 12) {
                        ForEach(row, id: \.self) { button in
                            CalculatorButton(
                                title: button,
                                onTap: { handleButtonTap(button) }
                            )
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private let buttonRows = [
        ["C", "±", "%", "÷"],
        ["7", "8", "9", "×"],
        ["4", "5", "6", "-"],
        ["1", "2", "3", "+"],
        ["0", ".", "="]
    ]
    
    private func handleButtonTap(_ button: String) {
        if button == "C" {
            display = "0"
            currentNumber = 0
            previousNumber = 0
            operation = nil
            shouldResetDisplay = false
        } else if ["÷", "×", "-", "+"].contains(button) {
            if let op = operation {
                performCalculation(op)
            }
            previousNumber = Double(display) ?? 0
            operation = button
            shouldResetDisplay = true
        } else if button == "=" {
            if let op = operation {
                performCalculation(op)
                operation = nil
            }
        } else {
            if shouldResetDisplay {
                display = button
                shouldResetDisplay = false
            } else {
                if display == "0" {
                    display = button
                } else {
                    display += button
                }
            }
            currentNumber = Double(display) ?? 0
        }
    }
    
    private func performCalculation(_ op: String) {
        let current = Double(display) ?? 0
        
        switch op {
        case "+":
            display = formatNumber(previousNumber + current)
        case "-":
            display = formatNumber(previousNumber - current)
        case "×":
            display = formatNumber(previousNumber * current)
        case "÷":
            display = current != 0 ? formatNumber(previousNumber / current) : "Error"
        default:
            break
        }
        
        currentNumber = Double(display) ?? 0
    }
    
    private func formatNumber(_ number: Double) -> String {
        if number.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(number))
        } else {
            return String(number)
        }
    }
}

struct CalculatorButton: View {
    let title: String
    let onTap: () -> Void
    
    var isOperator: Bool {
        ["÷", "×", "-", "+", "="].contains(title)
    }
    
    var isZero: Bool {
        title == "0"
    }
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
                .frame(width: isZero ? 150 : 70, height: 70)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isOperator ? AppColors.successAccent : Color.white.opacity(0.2))
                )
        }
    }
}

struct CompassUtilityView: View {
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        VStack(spacing: 40) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    .frame(width: 250, height: 250)
                
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    .frame(width: 200, height: 200)
                
                VStack {
                    Image(systemName: "location.north.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppColors.successAccent)
                        .rotationEffect(.degrees(locationManager.heading))
                    
                    Text("\(Int(locationManager.heading))°")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            Text("Heading: \(Int(locationManager.heading))°")
                .font(.title2)
                .foregroundColor(.white)
        }
    }
}

class LocationManager: NSObject, ObservableObject {
    @Published var heading: Double = 0
    
    override init() {
        super.init()
        // Simulate compass heading
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.heading = (self.heading + 0.5).truncatingRemainder(dividingBy: 360)
        }
    }
}

struct MetronomeUtilityView: View {
    @State private var isPlaying = false
    @State private var bpm: Double = 120
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: 40) {
            Text("\(Int(bpm)) BPM")
                .font(.system(size: 64, weight: .bold))
                .foregroundColor(.white)
            
            Slider(value: $bpm, in: 40...200)
                .tint(AppColors.successAccent)
                .padding(.horizontal, 40)
            
            Button(action: toggleMetronome) {
                ZStack {
                    Circle()
                        .fill(isPlaying ? AppColors.errorAccent : AppColors.successAccent)
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private func toggleMetronome() {
        isPlaying.toggle()
        
        if isPlaying {
            let interval = 60.0 / bpm
            timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
                // Metronome tick
            }
        } else {
            timer?.invalidate()
            timer = nil
        }
    }
}

struct FlashlightUtilityView: View {
    @State private var isOn = false
    @State private var brightness: Double = 1.0
    
    var body: some View {
        VStack(spacing: 40) {
            ZStack {
                Circle()
                    .fill(isOn ? AppColors.successAccent : Color.white.opacity(0.2))
                    .frame(width: 200, height: 200)
                    .shadow(color: isOn ? AppColors.successAccent.opacity(0.5) : .clear, radius: 50)
                
                Image(systemName: "flashlight.on.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
            }
            
            Toggle("Flashlight", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: AppColors.successAccent))
                .padding(.horizontal, 40)
            
            if isOn {
                VStack(spacing: 12) {
                    Text("Brightness")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Slider(value: $brightness, in: 0.1...1.0)
                        .tint(AppColors.successAccent)
                        .padding(.horizontal, 40)
                }
            }
        }
    }
}

#Preview {
    UtilityView(tool: Tool(name: "Calculator", icon: "number.square", status: .repaired))
}
