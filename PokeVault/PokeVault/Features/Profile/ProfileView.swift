//
//  ProfileView.swift
//  PokeVault
//
//  Created by Samuel Luis Štúber on 28.12.2025.
//


import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    
    // We use AppStorage to persist this data automatically
    @AppStorage("userName") private var userName = "Trainer"
    @AppStorage("userAvatar") private var userAvatar = "avatar_1"
    
    // The list of available avatar names (You need to add these images to Assets!)
    let avatars = ["avatar_1", "avatar_2", "avatar_3", "avatar_4", "avatar_5", "avatar_6"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Current Preview
                VStack {
                    Image(userAvatar)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .shadow(radius: 10)
                        .overlay(Circle().stroke(Color.blue, lineWidth: 3))
                    
                    Text("Hello, \(userName)!")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 40)
                
                // Name Field
                TextField("Enter your name", text: $userName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 40)
                    .multilineTextAlignment(.center)
                
                // Avatar Grid
                Text("Choose your Avatar")
                    .font(.caption)
                    .bold()
                    .padding(.top)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 20) {
                    ForEach(avatars, id: \.self) { avatar in
                        Image(avatar)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 70, height: 70)
                            .clipShape(Circle())
                            // Highlight selected
                            .overlay(
                                Circle()
                                    .stroke(Color.blue, lineWidth: userAvatar == avatar ? 4 : 0)
                            )
                            .opacity(userAvatar == avatar ? 1.0 : 0.6)
                            .onTapGesture {
                                userAvatar = avatar
                            }
                    }
                }
                .padding()
                
                Spacer()
                
                Button("Save Profile") {
                    // We need to restart hosting to broadcast the new name/avatar
                    P2PManager.shared.restartHosting()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom)
            }
            .navigationTitle("Trainer Card")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}