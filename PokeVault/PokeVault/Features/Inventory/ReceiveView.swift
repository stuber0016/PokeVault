import SwiftUI

struct ReceiveView: View {
    @EnvironmentObject var p2pManager: P2PManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    // Animation State
    @State private var isPulsing = false
    
    // Dynamic Colors
    private var mainColor: Color {
        colorScheme == .dark ? .yellow : .blue
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? .black : .white
    }
    
    private var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var body: some View {
        ZStack {
            // Adaptive Background
            backgroundColor.edgesIgnoringSafeArea(.all)
            
            // MARK: - Pulsing Waves Animation
            ZStack {
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(mainColor.opacity(0.5), lineWidth: 2)
                        .scaleEffect(isPulsing ? 2.5 : 0.5)
                        .opacity(isPulsing ? 0.0 : 1.0)
                        .animation(
                            .easeOut(duration: 3)
                            .repeatForever(autoreverses: false)
                            .delay(Double(i) * 0.8),
                            value: isPulsing
                        )
                }
                
                // Central Icon
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 50))
                    .foregroundColor(mainColor)
                    .padding(30)
                    .background(mainColor.opacity(0.2))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(mainColor, lineWidth: 2))
            }
            .onAppear {
                isPulsing = true
            }
            
            // Text Info
            VStack {
                Text("Waiting for Trade...")
                    .font(.title2)
                    .bold()
                    .foregroundColor(textColor)
                    .padding(.top, 50)
                
                Text("Keep this screen open to be visible")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.red)
                .padding(.bottom, 50)
            }
            
            // MARK: - Success Overlay
            if p2pManager.showReceivedAlert {
                TradeSuccessView(message: p2pManager.receivedAlertMessage) {
                    p2pManager.showReceivedAlert = false
                }
                .zIndex(100)
            }
        }
        // MARK: - Lifecycle Management
        .onAppear {
            p2pManager.startHosting()
        }
        .onDisappear {
            p2pManager.stopHosting()
            p2pManager.showReceivedAlert = false
        }
    }
}
