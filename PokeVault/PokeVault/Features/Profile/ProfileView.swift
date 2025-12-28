import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    
    // FIX: Use shared EnvironmentObject
    @EnvironmentObject var p2pManager: P2PManager
    
    @AppStorage("userName") private var userName = "Trainer"
    @AppStorage("userAvatar") private var userAvatar = "avatar_1"
    @AppStorage("isDebugMode") private var isDebugMode = false
    
    let avatars = ["avatar_1", "avatar_2", "avatar_3", "avatar_4", "avatar_5", "avatar_6"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {

                    VStack {
                        Image(userAvatar)
                            .resizable().aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .shadow(radius: 10)
                            .overlay(Circle().stroke(Color.blue, lineWidth: 3))
                        
                        Text("Hello, \(userName)!")
                            .font(.headline).foregroundColor(.gray)
                    }
                    .padding(.top, 40)
                    
                    TextField("Enter your name", text: $userName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 40)
                        .multilineTextAlignment(.center)

                    VStack(spacing: 15) {
                        Text("Choose your Avatar").font(.caption).bold()
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 20) {
                            ForEach(avatars, id: \.self) { avatar in
                                Image(avatar)
                                    .resizable().aspectRatio(contentMode: .fit)
                                    .frame(width: 70, height: 70)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.blue, lineWidth: userAvatar == avatar ? 4 : 0))
                                    .opacity(userAvatar == avatar ? 1.0 : 0.6)
                                    .onTapGesture { userAvatar = avatar }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Divider().padding(.horizontal)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Developer Options")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading)
                        
                        Toggle(isOn: $isDebugMode) {
                            HStack {
                                Image(systemName: "ladybug.fill")
                                    .foregroundColor(.purple)
                                VStack(alignment: .leading) {
                                    Text("Debug Mode")
                                        .font(.headline)
                                    Text("Enable special tools")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    Spacer()

                    Button("Save Profile") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Trainer Card")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
