//
//  SettingsView.swift
//  49RoutineRacer
//
//  Created by Роман Главацкий on 11.01.2026.
//

import SwiftUI
import StoreKit

struct SettingsView: View {
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.primaryBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // App Info Section
                        VStack(spacing: 16) {
                            Image(systemName: "wrench.and.screwdriver.fill")
                                .font(.system(size: 60))
                                .foregroundColor(AppColors.successAccent)
                            
                            Text("Pixel Fixer")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Version 1.0.0")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.top, 20)
                        
                        // Settings Options
                        VStack(spacing: 12) {
                            SettingsButton(
                                icon: "star.fill",
                                title: "Rate Us",
                                color: AppColors.successAccent
                            ) {
                                rateApp()
                            }
                            
                            SettingsButton(
                                icon: "lock.shield.fill",
                                title: "Privacy Policy",
                                color: AppColors.primaryBackground
                            ) {
                                openPrivacyPolicy()
                            }
                            
                            SettingsButton(
                                icon: "doc.text.fill",
                                title: "Terms of Service",
                                color: AppColors.primaryBackground
                            ) {
                                openTermsOfService()
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 30)
                        
                        Spacer()
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
    
    private func openPrivacyPolicy() {
        if let url = URL(string: "https://www.termsfeed.com/live/31fecd54-a8a1-4a2b-8ff6-7530c8a0fb32") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openTermsOfService() {
        if let url = URL(string: "https://www.termsfeed.com/live/a6180473-bcb4-4e12-b48e-26934f8e2594") {
            UIApplication.shared.open(url)
        }
    }
}

struct SettingsButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 30)
                
                Text(title)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
            )
        }
    }
}

#Preview {
    SettingsView()
}
