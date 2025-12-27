//
//  RadarView.swift
//  PokeVault
//
//  Created by Samuel Luis Štúber on 27.12.2025.
//


import SwiftUI
import MultipeerConnectivity

struct RadarView: View {
    let peers: [MCPeerID]
    let onTapPeer: (MCPeerID) -> Void
    
    @State private var isRotating = false
    
    var body: some View {
        ZStack {
            // 1. Radar Background (Concentric Circles)
            ZStack {
                Color.black.opacity(0.9)
                
                ForEach(1...4, id: \.self) { i in
                    Circle()
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        .frame(width: CGFloat(i * 70))
                }
                
                // Crosshairs
                Rectangle()
                    .fill(Color.green.opacity(0.3))
                    .frame(width: 1, height: 280)
                Rectangle()
                    .fill(Color.green.opacity(0.3))
                    .frame(width: 280, height: 1)
            }
            .clipShape(Circle())
            .frame(width: 300, height: 300)
            
            // 2. The Rotating Scanner
            AngularGradient(
                gradient: Gradient(colors: [.clear, .green.opacity(0.1), .green.opacity(0.5)]),
                center: .center
            )
            .clipShape(Circle())
            .frame(width: 300, height: 300)
            .rotationEffect(.degrees(isRotating ? 360 : 0))
            .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: isRotating)
            .onAppear { isRotating = true }
            
            // 3. The Peers (Simulated Locations)
            ForEach(Array(peers.enumerated()), id: \.element) { index, peer in
                // Generate a consistent pseudo-random position based on index
                let angle = Double(index * 137) // Golden angle to spread them out
                let distance = CGFloat(60 + (index * 30) % 80) // Randomize distance from center
                
                VStack(spacing: 4) {
                    Image(systemName: "iphone.gen3")
                        .font(.title2)
                        .foregroundColor(.green)
                        .padding(8)
                        .background(Color.green.opacity(0.2))
                        .clipShape(Circle())
                        .shadow(color: .green, radius: 5)
                    
                    Text(peer.displayName)
                        .font(.caption)
                        .bold()
                        .foregroundColor(.green)
                        .padding(4)
                        .background(Color.black.opacity(0.7))
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