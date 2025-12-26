import MultipeerConnectivity
import SwiftUI

class P2PManager: NSObject, ObservableObject {
    private let serviceType = "poketrade-app" // Must be < 15 chars
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    private let serviceAdvertiser: MCNearbyServiceAdvertiser
    private let serviceBrowser: MCNearbyServiceBrowser
    private lazy var session: MCSession = {
        let session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        return session
    }()

    @Published var availablePeers: [MCPeerID] = []
    @Published var connectedPeer: MCPeerID? = nil
    @Published var receivedPokemon: Pokemon? = nil // Trigger UI when card arrives

    override init() {
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        super.init()
        
        self.serviceAdvertiser.delegate = self
        self.serviceBrowser.delegate = self
    }

    func startHosting() { serviceAdvertiser.startAdvertisingPeer() }
    func stopHosting() { serviceAdvertiser.stopAdvertisingPeer() }
    
    func startBrowsing() { serviceBrowser.startBrowsingForPeers() }
    func stopBrowsing() { serviceBrowser.stopBrowsingForPeers() }

    func invite(peer: MCPeerID) {
        serviceBrowser.invitePeer(peer, to: session, withContext: nil, timeout: 30)
    }

    func send(pokemon: Pokemon) {
        guard let peer = connectedPeer else { return }
        do {
            let data = try JSONEncoder().encode(pokemon)
            try session.send(data, toPeers: [peer], with: .reliable)
        } catch {
            print("Error sending: \(error)")
        }
    }
}

// MARK: - MCSessionDelegate
extension P2PManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected: self.connectedPeer = peerID
            case .notConnected: self.connectedPeer = nil
            default: break
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // When we receive data, decode it and show/save it
        if let pokemon = try? JSONDecoder().decode(Pokemon.self, from: data) {
            DispatchQueue.main.async {
                self.receivedPokemon = pokemon
                // OPTIONAL: Auto-save immediately?
                // StorageManager.shared.addPokemon(pokemon) 
            }
        }
    }

    // Required stubs
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - Advertiser & Browser Delegates
extension P2PManager: MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Auto-accept everyone for this simple app
        invitationHandler(true, self.session)
    }

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        if !availablePeers.contains(peerID) {
            availablePeers.append(peerID)
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        if let index = availablePeers.firstIndex(of: peerID) {
            availablePeers.remove(at: index)
        }
    }
}