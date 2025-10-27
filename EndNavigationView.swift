//
//  EndNavigationView.swift
//  GloveGuide
//
//  Created by Mohammad Adnaan on 2025-10-26.
//

import SwiftUI

struct EndNavigationView: View {
    @ObservedObject var coordinator: AppCoordinator
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            // Icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            // Title
            Text("END of Navigation")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // Subtitle
            Text("You have reached your destination")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
                .frame(maxHeight: 50)
            
            // Buttons
            VStack(spacing: 16) {
                // OK Button
                Button(action: {
                    coordinator.endNavigation()
                    isPresented = false
                }) {
                    Text("OK")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                
                // Cancel Button
                Button(action: {
                    isPresented = false
                }) {
                    Text("Cancel")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                }
            }
            .padding(.horizontal, 40)
        }
        .padding(40)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding(40)
    }
}

#Preview {
    EndNavigationView(coordinator: AppCoordinator(), isPresented: .constant(true))
        .background(Color.black.opacity(0.3))
}