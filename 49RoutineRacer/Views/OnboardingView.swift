//
//  OnboardingView.swift
//  49RoutineRacer
//
//  Created by Роман Главацкий on 11.01.2026.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            AppColors.primaryBackground
                .ignoresSafeArea()
            
            TabView(selection: $currentPage) {
                OnboardingPage(
                    icon: "wrench.and.screwdriver.fill",
                    title: "Welcome to Pixel Fixer",
                    description: "Repair broken digital tools by solving puzzles and mini-games. Each fixed tool becomes a real utility you can use!",
                    pageIndex: 0
                )
                .tag(0)
                
                OnboardingPage(
                    icon: "puzzlepiece.fill",
                    title: "Fix Broken Tools",
                    description: "Tap broken elements, follow hints, and complete mini-games to repair each tool. Stuck buttons, broken connections, and logic errors await!",
                    pageIndex: 1
                )
                .tag(1)
                
                OnboardingPage(
                    icon: "star.fill",
                    title: "Unlock Utilities",
                    description: "Once repaired, tools become fully functional utilities. Use your calculator, compass, metronome, and more in real life!",
                    pageIndex: 2
                )
                .tag(2)
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            
            // Skip/Get Started button
            VStack {
                HStack {
                    Spacer()
                    if currentPage < 2 {
                        Button("Skip") {
                            completeOnboarding()
                        }
                        .foregroundColor(.white.opacity(0.7))
                        .padding()
                    }
                }
                
                Spacer()
                
                if currentPage == 2 {
                    Button(action: completeOnboarding) {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColors.successAccent)
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                }
            }
        }
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        isPresented = false
    }
}

struct OnboardingPage: View {
    let icon: String
    let title: String
    let description: String
    let pageIndex: Int
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon with animation
            ZStack {
                Circle()
                    .fill(AppColors.successAccent.opacity(0.2))
                    .frame(width: 200, height: 200)
                
                Image(systemName: icon)
                    .font(.system(size: 80))
                    .foregroundColor(AppColors.successAccent)
            }
            .padding(.bottom, 20)
            
            // Text content
            VStack(spacing: 16) {
                Text(title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
}
