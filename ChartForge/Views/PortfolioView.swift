import SwiftUI

struct PortfolioView: View {
    @StateObject private var portfolioVM = PortfolioViewModel()
    @State private var showEarnSheet = false
    @State private var showSpendSheet = false
    @State private var earnAmount: String = ""
    @State private var spendAmount: String = ""
    @State private var spendReason: String = ""
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Label("ChartForge Coin Wallet", systemImage: "bitcoinsign.circle").font(.headline)) {
                    HStack {
                        Text("Balance:")
                        Spacer()
                        Text("\(portfolioVM.coinBalance, specifier: "%.2f") CFC")
                            .font(.title2.bold())
                            .foregroundColor(.accentColor)
                    }
                    HStack(spacing: 16) {
                        Button(action: { showEarnSheet = true }) {
                            Label("Earn", systemImage: "plus.circle")
                        }
                        .buttonStyle(.borderedProminent)
                        Button(action: { showSpendSheet = true }) {
                            Label("Spend", systemImage: "minus.circle")
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 4)
                    if portfolioVM.coinTransactions.isEmpty {
                        Text("No transactions yet.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(portfolioVM.coinTransactions) { tx in
                            HStack {
                                Image(systemName: tx.isEarn ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                                    .foregroundColor(tx.isEarn ? .green : .red)
                                Text(tx.isEarn ? "+" : "-")
                                    .font(.headline)
                                    .foregroundColor(tx.isEarn ? .green : .red)
                                Text("\(tx.amount, specifier: "%.2f") CFC")
                                    .font(.body)
                                Spacer()
                                Text(tx.reason)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(tx.date, style: .relative)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                Section(header: Label("Holdings", systemImage: "wallet.pass").font(.headline)) {
                    if portfolioVM.holdings.isEmpty {
                        Text("No holdings yet. Place a trade to get started!")
                            .foregroundColor(.secondary)
                            .accessibilityLabel("No holdings yet. Place a trade to get started!")
                    } else {
                        ForEach(Array(portfolioVM.holdings.sorted(by: { $0.key < $1.key })), id: \ .key) { symbol, amount in
                            HStack {
                                Image(systemName: "bitcoinsign.circle")
                                    .foregroundColor(.accentColor)
                                Text(symbol)
                                    .font(.headline)
                                    .accessibilityLabel(symbol)
                                Spacer()
                                Text("\(amount, specifier: "%.4f")")
                                    .font(.body)
                                    .accessibilityLabel("\(amount, specifier: "%.4f") \(symbol)")
                            }
                            .listRowBackground(Color(.systemBackground))
                        }
                    }
                }
                Section(header: Label("Open Orders", systemImage: "clock.badge.exclamationmark").font(.headline)) {
                    if portfolioVM.openOrders.isEmpty {
                        Text("No open limit/stop orders.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(portfolioVM.openOrders) { order in
                            HStack {
                                Image(systemName: order.isBuy ? "arrow.up.circle" : "arrow.down.circle")
                                    .foregroundColor(order.isBuy ? .green : .red)
                                Text(order.orderType == .limit ? "Limit" : order.orderType == .stop ? "Stop" : "Market")
                                    .font(.caption2)
                                    .foregroundColor(.accentColor)
                                Text(order.isBuy ? "Buy" : "Sell")
                                    .font(.caption2)
                                Text(order.symbol)
                                    .font(.caption2)
                                if let lim = order.limitPrice, order.orderType == .limit {
                                    Text("@ $\(lim, specifier: "%.2f")")
                                        .font(.caption2)
                                }
                                if let stop = order.stopPrice, order.orderType == .stop {
                                    Text("@ $\(stop, specifier: "%.2f")")
                                        .font(.caption2)
                                }
                                Text("\(order.amount, specifier: "%.3f")")
                                    .font(.caption2)
                                Spacer()
                                Button(action: { portfolioVM.removeOpenOrder(order) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                Section(header: Label("Order History", systemImage: "clock.arrow.circlepath").font(.headline)) {
                    if portfolioVM.orders.isEmpty {
                        Text("No orders yet.")
                            .foregroundColor(.secondary)
                            .accessibilityLabel("No orders yet.")
                    } else {
                        ForEach(portfolioVM.orders) { order in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(order.isBuy ? "Buy" : "Sell") \(order.amount, specifier: "%.4f") \(order.symbol) @ $\(order.price, specifier: "%.2f")")
                                    .font(.body)
                                    .accessibilityLabel("\(order.isBuy ? "Buy" : "Sell") \(order.amount, specifier: "%.4f") \(order.symbol) at $\(order.price, specifier: "%.2f")")
                                Text(order.date, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .accessibilityLabel("Order date: \(order.date.formatted(date: .abbreviated, time: .shortened))")
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(Color(.systemGroupedBackground))
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Portfolio")
            .sheet(isPresented: $showEarnSheet) {
                VStack(spacing: 16) {
                    Text("Earn ChartForge Coin")
                        .font(.headline)
                    TextField("Amount", text: $earnAmount)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("Earn") {
                        if let amt = Double(earnAmount), amt > 0 {
                            portfolioVM.earnCoin(amount: amt, reason: "Manual earn")
                            showEarnSheet = false
                            earnAmount = ""
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    Button("Cancel") { showEarnSheet = false }
                        .foregroundColor(.red)
                }
                .padding()
            }
            .sheet(isPresented: $showSpendSheet) {
                VStack(spacing: 16) {
                    Text("Spend ChartForge Coin")
                        .font(.headline)
                    TextField("Amount", text: $spendAmount)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Reason", text: $spendReason)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("Spend") {
                        if let amt = Double(spendAmount), amt > 0 {
                            portfolioVM.spendCoin(amount: amt, reason: spendReason.isEmpty ? "Manual spend" : spendReason)
                            showSpendSheet = false
                            spendAmount = ""
                            spendReason = ""
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    Button("Cancel") { showSpendSheet = false }
                        .foregroundColor(.red)
                }
                .padding()
            }
        }
    }
}

struct PortfolioView_Previews: PreviewProvider {
    static var previews: some View {
        PortfolioView()
    }
} 