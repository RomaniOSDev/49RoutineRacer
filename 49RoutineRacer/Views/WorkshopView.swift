//
//  WorkshopView.swift
//  49RoutineRacer
//
//  Created by Роман Главацкий on 11.01.2026.
//

import SwiftUI

struct WorkshopView: View {
    @EnvironmentObject var viewModel: WorkshopViewModel
    @EnvironmentObject var progressViewModel: ProgressViewModel
    @State private var selectedTool: Tool?
    
    var repairedCount: Int {
        viewModel.tools.filter { $0.status == .repaired }.count
    }
    
    var totalCount: Int {
        viewModel.tools.count
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        AppColors.primaryBackground,
                        AppColors.primaryBackground.opacity(0.8),
                        Color(hex: "#023A6B")
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header stats
                        VStack(spacing: 16) {
                            Text("Pixel Fixer")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 30) {
                                StatBadge(
                                    icon: "wrench.fill",
                                    value: "\(repairedCount)",
                                    label: "Repaired",
                                    color: AppColors.successAccent
                                )
                                
                                StatBadge(
                                    icon: "lock.fill",
                                    value: "\(totalCount - repairedCount)",
                                    label: "Locked",
                                    color: Color.gray.opacity(0.6)
                                )
                                
                                StatBadge(
                                    icon: "star.fill",
                                    value: "\(progressViewModel.progress.totalRepairs)",
                                    label: "Total",
                                    color: AppColors.errorAccent
                                )
                            }
                        }
                        .padding(.top, 10)
                        .padding(.horizontal)
                        
                        // Tools grid
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 20) {
                            ForEach(viewModel.tools) { tool in
                                ToolCardView(tool: tool) {
                                    handleToolTap(tool)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Workshop")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .sheet(item: $selectedTool) { tool in
                if let currentTool = viewModel.tools.first(where: { $0.id == tool.id }) {
                    if currentTool.status == .repaired {
                        UtilityView(tool: currentTool)
                    } else {
                        PuzzleLevelView(tool: currentTool, viewModel: viewModel)
                            .environmentObject(progressViewModel)
                    }
                }
            }
        }
    }
    
    private func handleToolTap(_ tool: Tool) {
        switch tool.status {
        case .locked:
            // Show locked message
            break
        case .inProgress, .repaired:
            selectedTool = tool
        }
    }
}

struct ToolCardView: View {
    let tool: Tool
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                ZStack {
                    // Glow effect
                    if tool.status != .locked {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(borderColor.opacity(0.3))
                            .frame(width: 140, height: 140)
                            .blur(radius: 15)
                            .opacity(isPressed ? 0.5 : 0.8)
                    }
                    
                    // Main card background
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.05)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(borderColor, lineWidth: 3)
                        )
                        .shadow(color: borderColor.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    // Icon container
                    ZStack {
                        Circle()
                            .fill(borderColor.opacity(0.2))
                            .frame(width: 100, height: 100)
                        
                        if tool.status == .locked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 45))
                                .foregroundColor(.white.opacity(0.4))
                        } else {
                            Image(systemName: tool.icon)
                                .font(.system(size: 55))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 5)
                        }
                    }
                    
                    // Status indicator badge
                    VStack {
                        HStack {
                            Spacer()
                            statusBadge
                                .padding(8)
                        }
                        Spacer()
                    }
                }
                
                Text(tool.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .disabled(tool.status == .locked)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if tool.status != .locked {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
    
    private var borderColor: Color {
        switch tool.status {
        case .locked:
            return Color.gray.opacity(0.4)
        case .inProgress:
            return AppColors.errorAccent
        case .repaired:
            return AppColors.successAccent
        }
    }
    
    private var statusBadge: some View {
        Group {
            switch tool.status {
            case .locked:
                Image(systemName: "lock.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(6)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.3))
                    )
            case .inProgress:
                Circle()
                    .fill(AppColors.errorAccent)
                    .frame(width: 16, height: 16)
                    .shadow(color: AppColors.errorAccent.opacity(0.6), radius: 4)
            case .repaired:
                ZStack {
                    Circle()
                        .fill(AppColors.successAccent)
                        .frame(width: 20, height: 20)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
                .shadow(color: AppColors.successAccent.opacity(0.6), radius: 4)
            }
        }
    }
}

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    WorkshopView()
        .environmentObject(WorkshopViewModel())
}
