import MultipeerConnectivity
import SwiftUI
import Combine

class P2PManager: NSObject, ObservableObject {
    static let shared = P2PManager()
    
    private let serviceType = "pokevault-app"
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    
    private var serviceAdvertiser: MCNearbyServiceAdvertiser?
    private var serviceBrowser: MCNearbyServiceBrowser?
    
    private lazy var session: MCSession = {
        let session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        return session
    }()

    // UI State
    @Published var availablePeers: [MCPeerID] = []
    @Published var peerDetails: [MCPeerID: [String: String]] = [:] // Avatar/Name map
    
    @Published var connectedPeer: MCPeerID? = nil
    @Published var transferStatus: String = "Idle"
    @Published var showReceivedAlert = false
    @Published var receivedAlertMessage = ""
    @Published var shouldCloseTradeSheet = false
    
    var batchToSend: [TradeItem] = []
    
    override init() {
        super.init()
        self.startHosting()
    }
    
    // MARK: - Hosting & Browsing (No changes needed here except startHosting logic)
    func startHosting() {
        let avatar = UserDefaults.standard.string(forKey: "userAvatar") ?? "avatar_1"
        let name = UserDefaults.standard.string(forKey: "userName") ?? UIDevice.current.name
        
        let discoveryInfo = ["avatar": avatar, "name": name]
        
        serviceAdvertiser?.stopAdvertisingPeer()
        serviceAdvertiser = MCNearbyServiceAdvertiser(
            peer: myPeerId,
            discoveryInfo: discoveryInfo,
            serviceType: serviceType
        )
        serviceAdvertiser?.delegate = self
        serviceAdvertiser?.startAdvertisingPeer()
    }
    
    func stopHosting() { serviceAdvertiser?.stopAdvertisingPeer() }
    
    func restartHosting() {
        stopHosting()
        startHosting()
    }
    
    func startBrowsing() {
        serviceBrowser?.stopBrowsingForPeers()
        availablePeers.removeAll()
        peerDetails.removeAll()
        
        serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        serviceBrowser?.delegate = self
        serviceBrowser?.startBrowsingForPeers()
    }
    
    func stopBrowsing() { serviceBrowser?.stopBrowsingForPeers() }

    func connectTo(peer: MCPeerID) {
        serviceBrowser?.invitePeer(peer, to: session, withContext: nil, timeout: 30)
        transferStatus = "Connecting to \(peer.displayName)..."
    }

    // MARK: - Trade Logic (UPDATED)
    private func sendBatch() {
        guard let peer = connectedPeer, !batchToSend.isEmpty else { return }

        DispatchQueue.main.async {
            self.transferStatus = "Sending \(self.batchToSend.count) items..."
        }

        do {
            // 1. Get MY custom name to send inside the package
            let myName = UserDefaults.standard.string(forKey: "userName") ?? UIDevice.current.name
            
            // 2. Create Batch with Sender Name
            let batch = TradeBatch(items: batchToSend, senderName: myName)
            
            let data = try JSONEncoder().encode(batch)
            try session.send(data, toPeers: [peer], with: .reliable)

            DispatchQueue.main.async {
                for item in self.batchToSend {
                    for _ in 0..<item.quantity {
                        StorageManager.shared.decrementPokemon(id: item.pokemonID)
                    }
                }

                self.transferStatus = "Sent Successfully!"

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.session.disconnect()
                    self.connectedPeer = nil
                    self.transferStatus = "Idle"
                    self.batchToSend = []
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
                if !self.batchToSend.isEmpty {
                    self.transferStatus = "Connected! Preparing transfer..."
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.sendBatch()
                    }
                } else {
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
                    for _ in 0..<item.quantity {
                        _ = StorageManager.shared.incrementPokemon(id: item.pokemonID)
                    }
                    receivedNames.append("\(item.quantity)x \(item.name)")
                }
                
                // FIX: Use the name embedded in the package!
                // This guarantees we see "Ash" instead of "iPhone 15"
                let senderName = batch.senderName
                
                let summary = receivedNames.joined(separator: ", ")
                self.receivedAlertMessage = "You just received:\n\n\(summary)\n\nfrom \(senderName)!"
                self.showReceivedAlert = true
                self.transferStatus = "Received: \(summary)"
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    self.transferStatus = "Idle"
                }
            }
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - Browser Delegates (FIXED SELF DETECTION)
extension P2PManager: MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, self.session)
    }

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        // FIX: Ignore ourselves!
        guard peerID != myPeerId else { return }
        
        DispatchQueue.main.async {
            if let info = info {
                self.peerDetails[peerID] = info
            }
            if !self.availablePeers.contains(peerID) {
                self.availablePeers.append(peerID)
            }
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            if let index = self.availablePeers.firstIndex(of: peerID) {
                self.availablePeers.remove(at: index)
            }
            self.peerDetails.removeValue(forKey: peerID)
        }
    }
}
