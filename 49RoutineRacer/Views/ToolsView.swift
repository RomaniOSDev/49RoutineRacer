//
//  ToolsView.swift
//  49RoutineRacer
//
//  Created by Роман Главацкий on 11.01.2026.
//

import SwiftUI

struct ToolsView: View {
    @ObservedObject var viewModel: WorkshopViewModel
    @State private var selectedTool: Tool?
    
    var repairedTools: [Tool] {
        viewModel.tools.filter { $0.status == .repaired }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.primaryBackground
                    .ignoresSafeArea()
                
                if repairedTools.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "wrench.and.screwdriver")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("No Tools Available")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("Repair tools in the Workshop to unlock them here")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 20) {
                            ForEach(repairedTools) { tool in
                                ToolCardView(tool: tool) {
                                    selectedTool = tool
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("My Tools")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedTool) { tool in
                UtilityView(tool: tool)
            }
        }
    }
}

#Preview {
    ToolsView(viewModel: WorkshopViewModel())
}
