//
//  AchievementsView.swift
//  49RoutineRacer
//
//  Created by Роман Главацкий on 11.01.2026.
//

import SwiftUI

struct AchievementsView: View {
    @ObservedObject var viewModel: ProgressViewModel
    @EnvironmentObject var workshopViewModel: WorkshopViewModel
    @State private var showResetAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.primaryBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Statistics section
                        VStack(spacing: 16) {
                            Text("Statistics")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            HStack(spacing: 20) {
                                StatCard(
                                    title: "Total Repairs",
                                    value: "\(viewModel.progress.totalRepairs)",
                                    icon: "wrench.fill"
                                )
                                
                                StatCard(
                                    title: "Perfect Repairs",
                                    value: "\(viewModel.progress.perfectRepairs)",
                                    icon: "checkmark.circle.fill"
                                )
                            }
                            
                            if let fastest = viewModel.progress.fastestRepair {
                                StatCard(
                                    title: "Fastest Repair",
                                    value: String(format: "%.1fs", fastest),
                                    icon: "bolt.fill"
                                )
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.1))
                        )
                        .padding(.horizontal)
                        
                        // Achievements section
                        VStack(spacing: 16) {
                            Text("Achievements")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            ForEach(viewModel.achievements) { achievement in
                                AchievementRow(achievement: achievement)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Reset button
                        Button(action: {
                            showResetAlert = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 18))
                                Text("Reset Progress")
                                    .font(.headline)
                            }
                            .foregroundColor(AppColors.errorAccent)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(AppColors.errorAccent, lineWidth: 2)
                                    )
                            )
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
            .alert("Reset Progress", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    viewModel.resetProgress()
                    workshopViewModel.resetProgress()
                }
            } message: {
                Text("Are you sure you want to reset all progress? This will reset all repaired tools and achievements.")
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(AppColors.successAccent)
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
}

struct AchievementRow: View {
    let achievement: Achievement
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? AppColors.successAccent : Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 30))
                    .foregroundColor(achievement.isUnlocked ? .white : .white.opacity(0.5))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(achievement.description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            if achievement.isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppColors.successAccent)
                    .font(.system(size: 24))
            } else {
                Image(systemName: "lock.fill")
                    .foregroundColor(.gray)
                    .font(.system(size: 20))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(achievement.isUnlocked ? Color.white.opacity(0.1) : Color.white.opacity(0.05))
        )
    }
}

#Preview {
    AchievementsView(viewModel: ProgressViewModel())
}
