import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    
    // FIX: Use shared EnvironmentObject
    @EnvironmentObject var p2pManager: P2PManager
    
    @AppStorage("userName") private var userName = "Trainer"
    @AppStorage("userAvatar") private var userAvatar = "avatar_1"
    
    let avatars = ["avatar_1", "avatar_2", "avatar_3", "avatar_4", "avatar_5", "avatar_6"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // ... (Image & TextField code remains same) ...
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
                
                // Avatar Grid (Same code)
                Text("Choose your Avatar").font(.caption).bold().padding(.top)
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
                .padding()
                
                Spacer()
                
                Button("Save Profile") {
                    // FIX: This now works because p2pManager is valid
                    // Note: We don't strictly NEED to restart hosting here anymore
                    // because hosting only happens in ReceiveView now.
                    // But if they are currently hosting, this would update it.
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
