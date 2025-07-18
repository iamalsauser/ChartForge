import Foundation
import Combine

class AssetListViewModel: ObservableObject {
    @Published var assets: [CryptoAsset] = []
    private var webSocketService = WebSocketService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        webSocketService.$assets
            .receive(on: DispatchQueue.main)
            .assign(to: &$assets)
        webSocketService.connect()
    }
    
    deinit {
        webSocketService.disconnect()
    }
}
