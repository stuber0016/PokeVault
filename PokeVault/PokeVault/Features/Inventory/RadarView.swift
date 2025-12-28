import SwiftUI
import MultipeerConnectivity

struct RadarView: View {
    let peers: [MCPeerID]
    // We pass the details map to look up avatars
    let peerDetails: [MCPeerID: [String: String]]
    let onTapPeer: (MCPeerID) -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @State private var isRotating = false
    
    private var mainColor: Color { colorScheme == .dark ? .green : .blue }
    private var backgroundColor: Color { colorScheme == .dark ? Color.black.opacity(0.9) : Color.white }
    
    var body: some View {
        ZStack {
            // ... (Background Circles code remains same) ...
            ZStack {
                backgroundColor
                ForEach(1...4, id: \.self) { i in
                    Circle()
                        .stroke(mainColor.opacity(0.3), lineWidth: 1)
                        .frame(width: CGFloat(i * 70))
                }
                Rectangle().fill(mainColor.opacity(0.3)).frame(width: 1, height: 280)
                Rectangle().fill(mainColor.opacity(0.3)).frame(width: 280, height: 1)
            }
            .clipShape(Circle())
            .frame(width: 300, height: 300)
            .shadow(color: colorScheme == .light ? .gray.opacity(0.2) : .clear, radius: 10)
            
            // Scanner
            AngularGradient(gradient: Gradient(colors: [.clear, mainColor.opacity(0.1), mainColor.opacity(0.5)]), center: .center)
                .clipShape(Circle())
                .frame(width: 300, height: 300)
                .rotationEffect(.degrees(isRotating ? 360 : 0))
                .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: isRotating)
                .onAppear { isRotating = true }
            
            // Peers
            ForEach(Array(peers.enumerated()), id: \.element) { index, peer in
                let angle = Double(index * 137)
                let distance = CGFloat(60 + (index * 30) % 80)
                
                // Get Info
                let details = peerDetails[peer]
                let avatarName = details?["avatar"] ?? "avatar_1"
                let displayName = details?["name"] ?? peer.displayName
                
                VStack(spacing: 4) {
                    // Render Avatar Image
                    Image(avatarName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(mainColor, lineWidth: 2))
                        .shadow(color: mainColor.opacity(0.5), radius: 5)
                        // Fallback if image not found in assets (prevents crash)
                        .background(Color.gray.opacity(0.2).clipShape(Circle()))
                    
                    Text(displayName)
                        .font(.caption)
                        .bold()
                        .foregroundColor(mainColor)
                        .padding(4)
                        .background(backgroundColor.opacity(0.8))
                        .cornerRadius(4)
                }
                .offset(x: cos(angle) * distance, y: sin(angle) * distance)
                .onTapGesture { onTapPeer(peer) }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 320, height: 320)
    }
}
