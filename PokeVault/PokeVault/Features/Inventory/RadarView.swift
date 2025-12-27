import SwiftUI
import MultipeerConnectivity

struct RadarView: View {
    let peers: [MCPeerID]
    let onTapPeer: (MCPeerID) -> Void
    
    // 1. Detect System Theme
    @Environment(\.colorScheme) var colorScheme
    @State private var isRotating = false
    
    // 2. Define Colors based on Theme
    private var mainColor: Color {
        colorScheme == .dark ? .green : .blue
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.9) : Color.white
    }
    
    var body: some View {
        ZStack {
            // Radar Background (Concentric Circles)
            ZStack {
                backgroundColor // Dynamic Background
                
                ForEach(1...4, id: \.self) { i in
                    Circle()
                        .stroke(mainColor.opacity(0.3), lineWidth: 1)
                        .frame(width: CGFloat(i * 70))
                }
                
                // Crosshairs
                Rectangle()
                    .fill(mainColor.opacity(0.3))
                    .frame(width: 1, height: 280)
                Rectangle()
                    .fill(mainColor.opacity(0.3))
                    .frame(width: 280, height: 1)
            }
            .clipShape(Circle())
            .frame(width: 300, height: 300)
            // Add a subtle shadow in light mode so the white circle stands out
            .shadow(color: colorScheme == .light ? .gray.opacity(0.2) : .clear, radius: 10)
            
            // The Rotating Scanner
            AngularGradient(
                gradient: Gradient(colors: [.clear, mainColor.opacity(0.1), mainColor.opacity(0.5)]),
                center: .center
            )
            .clipShape(Circle())
            .frame(width: 300, height: 300)
            .rotationEffect(.degrees(isRotating ? 360 : 0))
            .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: isRotating)
            .onAppear { isRotating = true }
            
            // The Peers (Simulated Locations)
            ForEach(Array(peers.enumerated()), id: \.element) { index, peer in
                let angle = Double(index * 137)
                let distance = CGFloat(60 + (index * 30) % 80)
                
                VStack(spacing: 4) {
                    Image(systemName: "iphone.gen3")
                        .font(.title2)
                        .foregroundColor(mainColor) // Dynamic Icon Color
                        .padding(8)
                        .background(mainColor.opacity(0.2))
                        .clipShape(Circle())
                        .shadow(color: mainColor, radius: 5)
                    
                    Text(peer.displayName)
                        .font(.caption)
                        .bold()
                        .foregroundColor(mainColor)
                        .padding(4)
                        .background(backgroundColor.opacity(0.8)) // Dynamic Text Background
                        .cornerRadius(4)
                }
                .offset(x: cos(angle) * distance, y: sin(angle) * distance)
                .onTapGesture {
                    onTapPeer(peer)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 320, height: 320)
    }
}
