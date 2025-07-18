import Foundation

class AssetDetailViewModel: ObservableObject {
    @Published var asset: CryptoAsset?
    @Published var orderBook: [OrderBookEntry] = []
    @Published var recentTrades: [TradeEntry] = []
    @Published var newsArticles: [NewsArticle] = []
    // Add properties for chart data, etc.
    
    init(asset: CryptoAsset? = nil) {
        self.asset = asset
        // TODO: Fetch additional details or chart data
        fetchMockOrderBookAndTrades()
        fetchNews()
    }
    
    func fetchMockOrderBookAndTrades() {
        guard let asset = asset else { return }
        // Generate mock order book (5 bids, 5 asks)
        let price = asset.price
        orderBook = (1...5).map { i in
            OrderBookEntry(price: price - Double(i) * 10, amount: Double.random(in: 0.1...2), isBid: true)
        } + (1...5).map { i in
            OrderBookEntry(price: price + Double(i) * 10, amount: Double.random(in: 0.1...2), isBid: false)
        }
        // Generate mock recent trades (10 entries)
        recentTrades = (1...10).map { i in
            let isBuy = Bool.random()
            return TradeEntry(
                price: price + Double.random(in: -20...20),
                amount: Double.random(in: 0.05...1.5),
                isBuy: isBuy,
                time: Date().addingTimeInterval(-Double(i) * 60)
            )
        }
    }
    
    func fetchNews() {
        guard let asset = asset else { return }
        let symbol = asset.symbol.replacingOccurrences(of: "USDT", with: "")
        let url = URL(string: "https://cryptopanic.com/api/v1/posts/?auth_token=demo&currencies=\(symbol)&public=true")!
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let results = json["results"] as? [[String: Any]] else {
                // Fallback to mock data
                DispatchQueue.main.async {
                    self?.newsArticles = [
                        NewsArticle(title: "Bitcoin hits new high!", url: "https://cryptonews.com", source: "CryptoNews", publishedAt: Date()),
                        NewsArticle(title: "Ethereum upgrade coming soon", url: "https://cryptonews.com", source: "CryptoNews", publishedAt: Date().addingTimeInterval(-3600))
                    ]
                }
                return
            }
            let articles: [NewsArticle] = results.compactMap { dict in
                guard let title = dict["title"] as? String,
                      let url = dict["url"] as? String,
                      let source = dict["source"] as? String,
                      let published = dict["published_at"] as? String,
                      let date = ISO8601DateFormatter().date(from: published) else { return nil }
                return NewsArticle(title: title, url: url, source: source, publishedAt: date)
            }
            DispatchQueue.main.async {
                self?.newsArticles = articles
            }
        }
        task.resume()
    }
}
