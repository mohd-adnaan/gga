//
//  SideMenuView.swift
//  GloveGuide
//
//  Created by Mohammad Adnaan on 2025-10-29.
//

import SwiftUI

struct SideMenuView: View {
    @Binding var isShowing: Bool
    @State private var selectedMenu: MenuOption? = nil
    
    var body: some View {
        ZStack {
            if isShowing {
                // Dimmed background
                Color.black
                    .opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            isShowing = false
                        }
                    }
                
                // Side menu
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header with logo
                        VStack(spacing: 16) {
                            Image(uiImage: UIImage(named: "logo-glove-guide") ?? UIImage())
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .cornerRadius(12)
                            
                            Text("Glove Guide")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                        .background(Color.blue.opacity(0.1))
                        
                        // Menu items
                        VStack(spacing: 0) {
                            MenuButton(
                                icon: "info.circle",
                                title: "About",
                                isSelected: selectedMenu == .about
                            ) {
                                selectedMenu = .about
                            }
                            
                            MenuButton(
                                icon: "doc.text",
                                title: "Terms and Conditions",
                                isSelected: selectedMenu == .terms
                            ) {
                                selectedMenu = .terms
                            }
                            
                            MenuButton(
                                icon: "questionmark.circle",
                                title: "Support",
                                isSelected: selectedMenu == .support
                            ) {
                                selectedMenu = .support
                            }
                        }
                        .padding(.top, 20)
                        
                        Spacer()
                        
                        // McGill Logo at bottom
                        VStack(spacing: 8) {
                            Image("mcgill-university-logo-png-transparent-cropped")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 50)
                            
                            Text("Designed and Developed by SRL")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                    .frame(width: 280)
                    .background(Color(.systemBackground))
                    .transition(.move(edge: .leading))
                    
                    Spacer()
                }
            }
        }
        .sheet(item: $selectedMenu) { menu in
            MenuDetailView(menuOption: menu)
        }
    }
}

// MARK: - Menu Button
struct MenuButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .blue : .primary)
                    .frame(width: 25)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(isSelected ? .blue : .primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Menu Options
enum MenuOption: Identifiable {
    case about
    case terms
    case support
    
    var id: String {
        switch self {
        case .about: return "about"
        case .terms: return "terms"
        case .support: return "support"
        }
    }
}

// MARK: - Menu Detail View
struct MenuDetailView: View {
    let menuOption: MenuOption
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch menuOption {
                    case .about:
                        aboutContent
                    case .terms:
                        termsContent
                    case .support:
                        supportContent
                    }
                }
                .padding(20)
            }
            .navigationTitle(menuOption.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - About Content
    private var aboutContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About Glove Guide")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Glove Guide is a haptic navigation system designed to enhance safety for cyclists and pedestrians during urban mobility.")
                .font(.body)
            
            Text("Problem Statement")
                .font(.headline)
                .padding(.top, 8)
            
            Text("Road environments are inherently unsafe, involving multiple agents such as pedestrians, runners, and vehicles. Digital maps on smartphones are the most common navigation tool, but they distract users from their surroundings, reducing situational awareness and heightening accident risk.")
                .font(.body)
            
            Text("Our Solution")
                .font(.headline)
                .padding(.top, 8)
            
            Text("Glove Guide uses haptic notifications to signal left and right turns, allowing users to navigate without consulting their phones. This approach enables users to maintain attention on the road while receiving intuitive turn-by-turn directions.")
                .font(.body)
            
            Text("Key Features")
                .font(.headline)
                .padding(.top, 8)
            
            VStack(alignment: .leading, spacing: 8) {
                FeatureRow(icon: "hand.raised.fill", text: "Haptic feedback navigation")
                FeatureRow(icon: "eye.slash.fill", text: "Hands-free, eyes-free guidance")
                FeatureRow(icon: "figure.walk", text: "Support for walking and cycling")
                FeatureRow(icon: "bluetooth", text: "Bluetooth glove connectivity")
                FeatureRow(icon: "shield.fill", text: "Enhanced safety and awareness")
            }
            
            Text("Version 1.0.0")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 16)
        }
    }
    
    // MARK: - Terms Content
    private var termsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Terms and Conditions")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Last Updated: October 29, 2025")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Group {
                Text("1. Acceptance of Terms")
                    .font(.headline)
                    .padding(.top, 8)
                
                Text("By using Glove Guide, you agree to these Terms and Conditions. If you do not agree, please discontinue use of the application.")
                    .font(.body)
                
                Text("2. Use of Service")
                    .font(.headline)
                    .padding(.top, 8)
                
                Text("Glove Guide is designed to provide haptic navigation assistance. While we strive for accuracy, navigation systems may have limitations. Users are responsible for their own safety and must remain aware of their surroundings at all times.")
                    .font(.body)
                
                Text("3. Safety Disclaimer")
                    .font(.headline)
                    .padding(.top, 8)
                
                Text("IMPORTANT: Always prioritize your safety and the safety of others. Glove Guide is an assistive tool and does not replace your judgment. Always obey traffic laws, check your surroundings, and maintain situational awareness while cycling or walking.")
                    .font(.body)
                    .foregroundColor(.red)
            }
            
            Group {
                Text("4. Bluetooth Connectivity")
                    .font(.headline)
                    .padding(.top, 8)
                
                Text("The haptic feedback requires connection to compatible Bluetooth-enabled gloves. We are not responsible for connectivity issues or hardware malfunctions.")
                    .font(.body)
                
                Text("5. Data Collection")
                    .font(.headline)
                    .padding(.top, 8)
                
                Text("Glove Guide uses location services to provide navigation. Location data is used only for navigation purposes and is not stored or shared with third parties.")
                    .font(.body)
                
                Text("6. Limitation of Liability")
                    .font(.headline)
                    .padding(.top, 8)
                
                Text("Glove Guide and its developers are not liable for any accidents, injuries, or damages resulting from the use of this application. Use at your own risk.")
                    .font(.body)
            }
            
            Group {
                Text("7. Research Project")
                    .font(.headline)
                    .padding(.top, 8)
                
                Text("This application is developed as part of a research project at McGill University. Participation in testing is voluntary, and participants assume normal biking risks.")
                    .font(.body)
                
                Text("8. Changes to Terms")
                    .font(.headline)
                    .padding(.top, 8)
                
                Text("We reserve the right to modify these terms at any time. Continued use of the application constitutes acceptance of revised terms.")
                    .font(.body)
            }
        }
    }
    
    // MARK: - Support Content
    private var supportContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Support")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Need help? We're here to assist you!")
                .font(.body)
            
            Text("Contact Information")
                .font(.headline)
                .padding(.top, 8)
            
            VStack(alignment: .leading, spacing: 12) {
                SupportRow(icon: "person.fill", title: "Developer", value: "Mohammad Adnaan")
                SupportRow(icon: "envelope.fill", title: "Email", value: "mohammad.adnaan@mail.mcgill.ca")
                SupportRow(icon: "building.2.fill", title: "Institution", value: "McGill University")
            }
            
            Text("Frequently Asked Questions")
                .font(.headline)
                .padding(.top, 16)
            
            FAQItem(
                question: "How do I connect my gloves?",
                answer: "Go to Settings and tap 'Connect' under Bluetooth Connection. Make sure your gloves are in pairing mode."
            )
            
            FAQItem(
                question: "What transport modes are supported?",
                answer: "Glove Guide supports both Walking and Cycling modes. Select your preferred mode before starting navigation."
            )
            
            FAQItem(
                question: "How does haptic feedback work?",
                answer: "Left glove vibrates for left turns, right glove for right turns. Vibrations occur before intersections based on your lead time settings."
            )
            
            FAQItem(
                question: "Is it safe to use while cycling?",
                answer: "Glove Guide is designed to reduce distraction, but always prioritize safety. Stay aware of your surroundings and follow traffic laws."
            )
            
            Text("Technical Support")
                .font(.headline)
                .padding(.top, 16)
            
            Text("For technical issues, bug reports, or feature requests, please contact us via email. We appreciate your feedback!")
                .font(.body)
            
            Button(action: {
                if let url = URL(string: "mailto:mohammad.adnaan@mail.mcgill.ca") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Image(systemName: "envelope.fill")
                    Text("Send Email")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Helper Views
struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 25)
            Text(text)
                .font(.body)
        }
    }
}

struct SupportRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 25)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
            }
        }
        .padding(.vertical, 4)
    }
}

struct FAQItem: View {
    let question: String
    let answer: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(answer)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

extension MenuOption {
    var title: String {
        switch self {
        case .about: return "About"
        case .terms: return "Terms and Conditions"
        case .support: return "Support"
        }
    }
}
