//
//  TradeSheetView.swift
//  PokeVault
//
//  Created by Samuel Luis Štúber on 27.12.2025.
//


import SwiftUI
import MultipeerConnectivity

struct TradeSheetView: View {
    @EnvironmentObject var p2pManager: P2PManager
    @Environment(\.dismiss) var dismiss
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            VStack {
                Text("Searching for Trainers")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.primary)
                
                Text(p2pManager.transferStatus)
                    .font(.caption)
                    .foregroundColor(colorScheme == .dark ? .green : .blue)
                    .monospaced()
            }
            .padding(.top, 30)
            
            Spacer()
            
            // MARK: - The Radar
            ZStack {
                if p2pManager.availablePeers.isEmpty {
                    Text("Scanning...")
                        .foregroundColor(colorScheme == .dark ? .green.opacity(0.5) : .blue.opacity(0.5))
                        .blinkEffect()
                }
                
                RadarView(peers: p2pManager.availablePeers, peerDetails: p2pManager.peerDetails) { selectedPeer in
                    p2pManager.connectTo(peer: selectedPeer)
                }
            }
            
            Spacer()
            
            VStack(spacing: 10) {
                Text("Offering:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(p2pManager.batchToSend) { item in
                            VStack {
                                AsyncImage(url: URL(string: item.spriteURL)) { i in i.resizable() } placeholder: { Color.gray }
                                    .frame(width: 40, height: 40)
                                    .background(Color.gray.opacity(0.2))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 50)
                
                Button("Cancel Trade") {
                    dismiss()
                }
                .foregroundColor(.red)
                .padding(.bottom)
            }
        }
        .background(Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all))
        .onAppear { p2pManager.startBrowsing() }
        .onDisappear { p2pManager.stopBrowsing() }
    }
}

struct BlinkModifier: ViewModifier {
    @State private var isBlinking = false
    func body(content: Content) -> some View {
        content
            .opacity(isBlinking ? 0.3 : 1.0)
            .animation(.easeInOut(duration: 1).repeatForever(), value: isBlinking)
            .onAppear { isBlinking = true }
    }
}

extension View {
    func blinkEffect() -> some View {
        modifier(BlinkModifier())
    }
}
