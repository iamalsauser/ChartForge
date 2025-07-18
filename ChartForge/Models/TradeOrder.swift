import Foundation

enum OrderType: String, Codable {
    case market, limit, stop
}

struct TradeOrder: Identifiable, Codable {
    var id = UUID()
    var symbol: String
    var name: String
    var amount: Double
    var price: Double
    var isBuy: Bool
    var date: Date
    // Advanced order fields
    var orderType: OrderType = .market
    var limitPrice: Double? = nil
    var stopPrice: Double? = nil
} 