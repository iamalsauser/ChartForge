import Foundation

class PortfolioViewModel: ObservableObject {
    @Published private(set) var orders: [TradeOrder] = []
    @Published private(set) var holdings: [String: Double] = [:]
    // ChartForge Coin
    @Published private(set) var coinBalance: Double = 0
    @Published private(set) var coinTransactions: [ChartForgeCoinTransaction] = []
    @Published private(set) var openOrders: [TradeOrder] = []
    static let ordersKey = "TradeOrders"
    static let coinKey = "ChartForgeCoinBalance"
    static let coinTxKey = "ChartForgeCoinTxs"
    
    init() {
        loadOrders()
        recalculateHoldings()
        loadCoin()
        loadOpenOrders()
    }
    
    func addOrder(_ order: TradeOrder) {
        orders.append(order)
        saveOrders()
        recalculateHoldings()
        earnCoin(amount: 2, reason: "Trade completed")
    }
    
    private func recalculateHoldings() {
        var newHoldings: [String: Double] = [:]
        for order in orders {
            let delta = order.isBuy ? order.amount : -order.amount
            newHoldings[order.symbol, default: 0] += delta
        }
        holdings = newHoldings
    }
    
    private func saveOrders() {
        if let data = try? JSONEncoder().encode(orders) {
            UserDefaults.standard.set(data, forKey: Self.ordersKey)
        }
    }
    
    private func loadOrders() {
        if let data = UserDefaults.standard.data(forKey: Self.ordersKey),
           let decoded = try? JSONDecoder().decode([TradeOrder].self, from: data) {
            orders = decoded
        }
    }
    // ChartForge Coin
    func earnCoin(amount: Double, reason: String) {
        coinBalance += amount
        let tx = ChartForgeCoinTransaction(amount: amount, isEarn: true, reason: reason, date: Date())
        coinTransactions.insert(tx, at: 0)
        saveCoin()
    }
    func spendCoin(amount: Double, reason: String) {
        guard coinBalance >= amount else { return }
        coinBalance -= amount
        let tx = ChartForgeCoinTransaction(amount: amount, isEarn: false, reason: reason, date: Date())
        coinTransactions.insert(tx, at: 0)
        saveCoin()
    }
    private func saveCoin() {
        UserDefaults.standard.set(coinBalance, forKey: Self.coinKey)
        if let data = try? JSONEncoder().encode(coinTransactions) {
            UserDefaults.standard.set(data, forKey: Self.coinTxKey)
        }
    }
    private func loadCoin() {
        coinBalance = UserDefaults.standard.double(forKey: Self.coinKey)
        if let data = UserDefaults.standard.data(forKey: Self.coinTxKey),
           let decoded = try? JSONDecoder().decode([ChartForgeCoinTransaction].self, from: data) {
            coinTransactions = decoded
        }
    }
    func addOpenOrder(_ order: TradeOrder) {
        openOrders.append(order)
        saveOpenOrders()
    }
    func removeOpenOrder(_ order: TradeOrder) {
        openOrders.removeAll { $0.id == order.id }
        saveOpenOrders()
    }
    private func saveOpenOrders() {
        if let data = try? JSONEncoder().encode(openOrders) {
            UserDefaults.standard.set(data, forKey: "OpenOrders")
        }
    }
    private func loadOpenOrders() {
        if let data = UserDefaults.standard.data(forKey: "OpenOrders"),
           let decoded = try? JSONDecoder().decode([TradeOrder].self, from: data) {
            openOrders = decoded
        }
    }
    // Call this periodically or after price update
    func checkAndFillOpenOrders(latestPrices: [String: Double]) {
        var filled: [TradeOrder] = []
        for order in openOrders {
            let price = latestPrices[order.symbol] ?? 0
            switch order.orderType {
            case .limit:
                if let lim = order.limitPrice, (order.isBuy && price <= lim) || (!order.isBuy && price >= lim) {
                    filled.append(order)
                }
            case .stop:
                if let stop = order.stopPrice, (order.isBuy && price >= stop) || (!order.isBuy && price <= stop) {
                    filled.append(order)
                }
            default: break
            }
        }
        for order in filled {
            addOrder(order)
            removeOpenOrder(order)
        }
    }
} 