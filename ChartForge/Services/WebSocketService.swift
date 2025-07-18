import Foundation
import SwiftUI
import UIKit
import Combine

let appGroupID = "group.parth.ChartForge"
let widgetPriceKey = "widget_prices"
let widgetHistoryKey = "widget_history"

class WebSocketService: ObservableObject {
    @Published var assets: [CryptoAsset] = []
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var cancellables = Set<AnyCancellable>()
    private let symbols = [
        (symbol: "BTCUSDT", name: "Bitcoin"),
        (symbol: "ETHUSDT", name: "Ethereum"),
        (symbol: "SOLUSDT", name: "Solana"),
        (symbol: "ADAUSDT", name: "Cardano"),
        (symbol: "XRPUSDT", name: "XRP"),
        (symbol: "DOGEUSDT", name: "Dogecoin"),
        (symbol: "BNBUSDT", name: "Binance Coin"),
        (symbol: "AVAXUSDT", name: "Avalanche"),
        (symbol: "MATICUSDT", name: "Polygon"),
        (symbol: "DOTUSDT", name: "Polkadot")
    ]
    private var assetMap: [String: String] { Dictionary(uniqueKeysWithValues: symbols.map { ($0.symbol, $0.name) }) }
    private var latestAssets: [String: CryptoAsset] = [:]
    private var priceHistory: [String: [Double]] = [:] // symbol -> [recent prices]
    private let historyLimit = 20
    
    private var url: URL {
        let streams = symbols.map { "\($0.symbol.lowercased())@ticker" }.joined(separator: "/")
        return URL(string: "wss://stream.binance.com:9443/stream?streams=\(streams)")!
    }
    
    func connect() {
        disconnect()
        fetch24hStats() // Fetch stats on connect
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        receive()
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }
    
    private func receive() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("WebSocket error: \(error)")
                self?.reconnectWithDelay()
            case .success(let message):
                switch message {
                case .data(let data):
                    self?.handleMessage(data: data)
                case .string(let text):
                    if let data = text.data(using: .utf8) {
                        self?.handleMessage(data: data)
                    }
                @unknown default:
                    break
                }
                self?.receive()
            }
        }
    }
    
    private func handleMessage(data: Data) {
        struct StreamWrapper: Decodable {
            let stream: String
            let data: BinanceTicker
        }
        struct BinanceTicker: Decodable {
            let s: String // symbol
            let c: String // last price
            let E: Int // event time (ms)
        }
        if let wrapper = try? JSONDecoder().decode(StreamWrapper.self, from: data),
           let price = Double(wrapper.data.c),
           let name = assetMap[wrapper.data.s] {
            let asset = CryptoAsset(
                symbol: wrapper.data.s,
                name: name,
                price: price,
                lastUpdated: Date(timeIntervalSince1970: Double(wrapper.data.E) / 1000)
            )
            latestAssets[asset.symbol] = asset
            // Update price history
            var history = priceHistory[asset.symbol] ?? []
            history.append(price)
            if history.count > historyLimit { history.removeFirst(history.count - historyLimit) }
            priceHistory[asset.symbol] = history
            DispatchQueue.main.async {
                self.assets = self.symbols.compactMap { self.latestAssets[$0.symbol] }
                self.saveWidgetData()
                // Fill open limit/stop orders if price is hit
                if let portfolioVM = self.getPortfolioViewModel() {
                    let priceMap = Dictionary(uniqueKeysWithValues: self.assets.map { ($0.symbol, $0.price) })
                    portfolioVM.checkAndFillOpenOrders(latestPrices: priceMap)
                }
            }
        }
    }
    
    private func saveWidgetData() {
        guard let userDefaults = UserDefaults(suiteName: appGroupID) else { return }
        // Save latest prices
        let priceDict = Dictionary(uniqueKeysWithValues: assets.map { asset in
            (asset.symbol, ["price": asset.price, "lastUpdated": asset.lastUpdated.timeIntervalSince1970])
        })
        userDefaults.set(priceDict, forKey: widgetPriceKey)
        // Save price history
        let historyDict = Dictionary(uniqueKeysWithValues: priceHistory.map { (symbol, history) in
            (symbol, history)
        })
        userDefaults.set(historyDict, forKey: widgetHistoryKey)
        userDefaults.synchronize()
    }
    
    private func reconnectWithDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.connect()
        }
    }
    
    private func fetch24hStats() {
        let url = URL(string: "https://api.binance.com/api/v3/ticker/24hr")!
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil,
                  let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return }
            var stats: [String: (change: Double, high: Double, low: Double, volume: Double)] = [:]
            for dict in arr {
                guard let symbol = dict["symbol"] as? String,
                      let change = Double(dict["priceChangePercent"] as? String ?? ""),
                      let high = Double(dict["highPrice"] as? String ?? ""),
                      let low = Double(dict["lowPrice"] as? String ?? ""),
                      let volume = Double(dict["quoteVolume"] as? String ?? "") else { continue }
                stats[symbol] = (change, high, low, volume)
            }
            DispatchQueue.main.async {
                for (symbol, asset) in self?.latestAssets ?? [:] {
                    if let s = stats[symbol] {
                        var updated = asset
                        updated.change24h = s.change
                        updated.high24h = s.high
                        updated.low24h = s.low
                        updated.volume24h = s.volume
                        self?.latestAssets[symbol] = updated
                    }
                }
                self?.assets = self?.symbols.compactMap { self?.latestAssets[$0.symbol] } ?? []
                self?.saveWidgetData()
            }
        }
        task.resume()
        // Refresh stats every 5 minutes
        DispatchQueue.main.asyncAfter(deadline: .now() + 300) { [weak self] in self?.fetch24hStats() }
    }
    
    // Helper to get PortfolioViewModel singleton (for demo)
    private func getPortfolioViewModel() -> PortfolioViewModel? {
        // This is a hack for demo; in a real app, use dependency injection or environment
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController?.children.compactMap { vc in
            (vc as? UIHostingController<AnyView>)?.rootView.environmentObject(PortfolioViewModel())
        }.first as? PortfolioViewModel
    }
}
