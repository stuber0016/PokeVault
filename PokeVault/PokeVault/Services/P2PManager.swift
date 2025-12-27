import MultipeerConnectivity
import SwiftUI
import Combine

class P2PManager: NSObject, ObservableObject {
    private let serviceType = "pokevault-app"
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    private let serviceAdvertiser: MCNearbyServiceAdvertiser
    private let serviceBrowser: MCNearbyServiceBrowser
    
    private lazy var session: MCSession = {
        let session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        return session
    }()

    // UI State
    @Published var availablePeers: [MCPeerID] = []
    @Published var connectedPeer: MCPeerID? = nil
    @Published var transferStatus: String = "Idle" // To show "Sending...", "Received!"
    @Published var showReceivedAlert = false
    @Published var receivedAlertMessage = ""
    @Published var shouldCloseTradeSheet = false
    
    // The batch we intend to send (set by the UI)
    var batchToSend: [TradeItem] = []
    
    override init() {
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        super.init()
        
        self.serviceAdvertiser.delegate = self
        self.serviceBrowser.delegate = self
        
        // Always be ready to receive trades, even if not on the trade screen
        self.startHosting()
    }
    
    // MARK: - Hosting (Receiver)
    func startHosting() { serviceAdvertiser.startAdvertisingPeer() }
    func stopHosting() { serviceAdvertiser.stopAdvertisingPeer() }
    
    // MARK: - Browsing (Sender)
    func startBrowsing() {
        availablePeers.removeAll()
        serviceBrowser.startBrowsingForPeers()
    }
    
    func stopBrowsing() {
        serviceBrowser.stopBrowsingForPeers()
    }

    // Connect to a specific peer
    func connectTo(peer: MCPeerID) {
        serviceBrowser.invitePeer(peer, to: session, withContext: nil, timeout: 30)
        transferStatus = "Connecting to \(peer.displayName)..."
    }

    // MARK: - Trade Logic
    private func sendBatch() {
        guard let peer = connectedPeer, !batchToSend.isEmpty else { return }

        DispatchQueue.main.async {
            self.transferStatus = "Sending \(self.batchToSend.count) items..."
        }

        do {
            // 1. Wrap in batch
            let batch = TradeBatch(items: batchToSend)
            let data = try JSONEncoder().encode(batch)
            try session.send(data, toPeers: [peer], with: .reliable)

            // 2. Remove items from MY inventory
            DispatchQueue.main.async {
                for item in self.batchToSend {
                    // Decrement X times based on quantity sent
                    for _ in 0..<item.quantity {
                        StorageManager.shared.decrementPokemon(id: item.pokemonID)
                    }
                }

                self.transferStatus = "Sent Successfully!"

                // Wait 2 seconds, then trigger the sheet to close
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.session.disconnect()
                    self.connectedPeer = nil
                    self.transferStatus = "Idle"
                    self.batchToSend = []

                    // This triggers the UI to close
                    self.shouldCloseTradeSheet = true
                }
            }
        } catch {
            DispatchQueue.main.async { self.transferStatus = "Error: \(error.localizedDescription)" }
        }
    }
}

// MARK: - MCSessionDelegate
extension P2PManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                self.connectedPeer = peerID
                
                // ✅ FIX 1: Check if WE are the one sending (batch is NOT empty)
                if !self.batchToSend.isEmpty {
                    self.transferStatus = "Connected! Preparing transfer..."
                    
                    // ✅ FIX 2: Add a 0.5s delay.
                    // Sending immediately upon connection often fails silently.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.sendBatch()
                    }
                } else {
                    // We are the receiver
                    self.transferStatus = "Connected! Waiting for items..."
                }
                
            case .notConnected:
                if self.connectedPeer == peerID {
                    self.connectedPeer = nil
                    self.transferStatus = "Disconnected"
                }
            case .connecting:
                self.transferStatus = "Connecting..."
            @unknown default: break
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let batch = try? JSONDecoder().decode(TradeBatch.self, from: data) {
            DispatchQueue.main.async {
                var receivedNames: [String] = []

                for item in batch.items {
                    // 1. Save to DB immediately (Safety First!)
                    for _ in 0..<item.quantity {
                        _ = StorageManager.shared.incrementPokemon(id: item.pokemonID)
                    }
                    receivedNames.append("\(item.quantity)x \(item.name)")
                }

                // 2. Prepare the Alert Message
                let summary = receivedNames.joined(separator: ", ")
                self.receivedAlertMessage = "You just received:\n\n\(summary)\n\nfrom \(peerID.displayName)!"
                
                // 3. Trigger the Alert on UI
                self.showReceivedAlert = true
                
                // 4. Update internal status text (optional)
                self.transferStatus = "Received: \(summary)"
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    self.transferStatus = "Idle"
                }
            }
        }
    }

    // Boilerplate stubs
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - Advertiser & Browser Delegates
extension P2PManager: MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Auto-accept invitations
        invitationHandler(true, self.session)
    }

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        if !availablePeers.contains(peerID) {
            DispatchQueue.main.async { self.availablePeers.append(peerID) }
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        if let index = availablePeers.firstIndex(of: peerID) {
            DispatchQueue.main.async { self.availablePeers.remove(at: index) }
        }
    }
}
