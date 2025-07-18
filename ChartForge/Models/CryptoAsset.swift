import Foundation

struct CryptoAsset: Identifiable, Codable, Equatable {
    var id = UUID()
    var symbol: String
    var name: String
    var price: Double
    var lastUpdated: Date
    // New stats
    var change24h: Double? = nil
    var high24h: Double? = nil
    var low24h: Double? = nil
    var volume24h: Double? = nil
}

struct OrderBookEntry: Identifiable, Codable {
    var id = UUID()
    var price: Double
    var amount: Double
    var isBid: Bool // true = bid, false = ask
}

struct TradeEntry: Identifiable, Codable {
    var id = UUID()
    var price: Double
    var amount: Double
    var isBuy: Bool // true = buy, false = sell
    var time: Date
}

struct NewsArticle: Identifiable, Codable {
    var id = UUID()
    var title: String
    var url: String
    var source: String
    var publishedAt: Date
}

struct ChartForgeCoinTransaction: Identifiable, Codable {
    var id = UUID()
    var amount: Double
    var isEarn: Bool // true = earn, false = spend
    var reason: String
    var date: Date
}
