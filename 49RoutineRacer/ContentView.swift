//
//  ContentView.swift
//  49RoutineRacer
//
//  Created by Роман Главацкий on 11.01.2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var workshopViewModel = WorkshopViewModel()
    @StateObject private var progressViewModel = ProgressViewModel()
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    
    var body: some View {
        ZStack {
            if showOnboarding {
                OnboardingView(isPresented: $showOnboarding)
            } else {
                TabView {
                    WorkshopView()
                        .environmentObject(workshopViewModel)
                        .environmentObject(progressViewModel)
                        .tabItem {
                            Label("Workshop", systemImage: "wrench.and.screwdriver")
                        }
                    
                    ToolsView(viewModel: workshopViewModel)
                        .tabItem {
                            Label("Tools", systemImage: "app.badge")
                        }
                    
                    AchievementsView(viewModel: progressViewModel)
                        .environmentObject(workshopViewModel)
                        .tabItem {
                            Label("Achievements", systemImage: "star.fill")
                        }
                    
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gearshape.fill")
                        }
                }
                .accentColor(AppColors.successAccent)
                .preferredColorScheme(.dark)
            }
        }
    }
}

#Preview {
    ContentView()
}
