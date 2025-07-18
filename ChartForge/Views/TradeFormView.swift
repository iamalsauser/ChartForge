import SwiftUI

struct TradeFormView: View {
    var asset: CryptoAsset?
    @State private var amount: String = ""
    @State private var isBuying: Bool = true
    @State private var isLoading: Bool = false
    @State private var confirmationMessage: String?
    @State private var showConfirmation: Bool = false
    @State private var showCheckmark: Bool = false
    @State private var orderType: OrderType = .market
    @State private var limitPrice: String = ""
    @State private var stopPrice: String = ""
    @EnvironmentObject var portfolioVM: PortfolioViewModel
    @StateObject private var detailVM = AssetDetailViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let asset = asset {
                    HStack(spacing: 16) {
                        Image(systemName: "bitcoinsign.circle.fill")
                            .resizable()
                            .frame(width: 36, height: 36)
                            .foregroundColor(.accentColor)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading) {
                            Text(asset.name)
                                .font(.headline)
                                .accessibilityLabel(asset.name)
                            Text(asset.symbol)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .accessibilityLabel(asset.symbol)
                            Text("$\(asset.price, specifier: "%.2f")")
                                .font(.title3)
                                .accessibilityLabel("Price: $\(asset.price, specifier: "%.2f")")
                        }
                    }
                    .padding(.bottom)
                }
                Picker("Order Type", selection: $orderType) {
                    Text("Market").tag(OrderType.market)
                    Text("Limit").tag(OrderType.limit)
                    Text("Stop").tag(OrderType.stop)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                Picker("Action", selection: $isBuying) {
                    Text("Buy").tag(true)
                    Text("Sell").tag(false)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                TextField("Amount", text: $amount)
#if os(iOS)
                    .keyboardType(.decimalPad)
#endif
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                if orderType == .limit {
                    TextField("Limit Price", text: $limitPrice)
#if os(iOS)
                        .keyboardType(.decimalPad)
#endif
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                }
                if orderType == .stop {
                    TextField("Stop Price", text: $stopPrice)
#if os(iOS)
                        .keyboardType(.decimalPad)
#endif
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                }
                Button(action: submit) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Label(isBuying ? (orderType == .market ? "Buy" : "Place Buy Order") : (orderType == .market ? "Sell" : "Place Sell Order"), systemImage: isBuying ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isBuying ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                            .foregroundColor(isBuying ? .green : .red)
                            .cornerRadius(12)
                    }
                }
                .disabled(isLoading || amount.isEmpty || (orderType == .limit && limitPrice.isEmpty) || (orderType == .stop && stopPrice.isEmpty))
                .padding(.horizontal)
                if showCheckmark {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .frame(width: 48, height: 48)
                        .foregroundColor(.green)
                        .transition(.scale)
                        .padding(.top, 8)
                        .animation(.spring(), value: showCheckmark)
                }
                if showConfirmation, let message = confirmationMessage {
                    Text(message)
                        .foregroundColor(.blue)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.blue.opacity(0.08))
                        .cornerRadius(10)
                        .transition(.scale)
                        .accessibilityLabel(message)
                }
                // --- New: Live Order Book and Recent Trades ---
                if let asset = asset {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Order Book")
                            .font(.headline)
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Bids")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                ForEach(detailVM.orderBook.filter { $0.isBid }.prefix(5)) { entry in
                                    HStack(spacing: 4) {
                                        Text("$\(entry.price, specifier: "%.2f")")
                                            .font(.caption2)
                                        Text("\(entry.amount, specifier: "%.3f")")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Asks")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                ForEach(detailVM.orderBook.filter { !$0.isBid }.prefix(5)) { entry in
                                    HStack(spacing: 4) {
                                        Text("$\(entry.price, specifier: "%.2f")")
                                            .font(.caption2)
                                        Text("\(entry.amount, specifier: "%.3f")")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Trades")
                            .font(.headline)
                        ForEach(detailVM.recentTrades) { trade in
                            HStack(spacing: 8) {
                                Image(systemName: trade.isBuy ? "arrow.up.right" : "arrow.down.right")
                                    .foregroundColor(trade.isBuy ? .green : .red)
                                Text("$\(trade.price, specifier: "%.2f")")
                                    .font(.caption)
                                Text("\(trade.amount, specifier: "%.3f")")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(trade.time, style: .time)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding(.vertical, 4)
                    // --- User's Open Orders for this Asset ---
                    let openOrders = portfolioVM.openOrders.filter { $0.symbol == asset.symbol }
                    if !openOrders.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Open Orders")
                                .font(.headline)
                            ForEach(openOrders, id: \ .id) { order in
                                HStack(spacing: 8) {
                                    Image(systemName: order.isBuy ? "arrow.up.circle" : "arrow.down.circle")
                                        .foregroundColor(order.isBuy ? .green : .red)
                                    Text(order.isBuy ? "Buy" : "Sell")
                                        .font(.caption2)
                                    if order.orderType != .market {
                                        Text(order.orderType == .limit ? "Limit" : "Stop")
                                            .font(.caption2)
                                            .foregroundColor(.accentColor)
                                    }
                                    Text("\(order.amount, specifier: "%.3f")")
                                        .font(.caption2)
                                    if let lim = order.limitPrice, order.orderType == .limit {
                                        Text("@ $\(lim, specifier: "%.2f")")
                                            .font(.caption2)
                                    }
                                    if let stop = order.stopPrice, order.orderType == .stop {
                                        Text("@ $\(stop, specifier: "%.2f")")
                                            .font(.caption2)
                                    }
                                    Spacer()
                                    Button(action: { portfolioVM.removeOpenOrder(order) }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .padding(.top, 8)
                    }
                }
                // --- End Live Data ---
                // --- User's Past Trades for this Asset ---
                if let asset = asset {
                    let trades = portfolioVM.orders.filter { $0.symbol == asset.symbol }
                    if !trades.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Recent Trades")
                                .font(.headline)
                            ForEach(trades.suffix(5).reversed(), id: \ .id) { order in
                                HStack(spacing: 8) {
                                    Image(systemName: order.isBuy ? "arrow.up.circle" : "arrow.down.circle")
                                        .foregroundColor(order.isBuy ? .green : .red)
                                    Text(order.isBuy ? "Buy" : "Sell")
                                        .font(.caption2)
                                    if order.orderType != .market {
                                        Text(order.orderType == .limit ? "Limit" : "Stop")
                                            .font(.caption2)
                                            .foregroundColor(.accentColor)
                                    }
                                    Text("\(order.amount, specifier: "%.3f")")
                                        .font(.caption2)
                                    Text("@ $\(order.price, specifier: "%.2f")")
                                        .font(.caption2)
                                    Text(order.date, style: .time)
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .padding(.top, 8)
                    }
                }
                // --- End Past Trades ---
                Spacer(minLength: 40)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemBackground)).shadow(radius: 2))
            .padding(.horizontal)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Trade")
        .animation(.easeInOut, value: showConfirmation)
    }
    
    private func submit() {
        isLoading = true
        confirmationMessage = nil
        showConfirmation = false
        showCheckmark = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isLoading = false
            guard let asset = asset, let amt = Double(amount), amt > 0 else { return }
            let price = asset.price
            var order = TradeOrder(
                symbol: asset.symbol,
                name: asset.name,
                amount: amt,
                price: price,
                isBuy: isBuying,
                date: Date()
            )
            order.orderType = orderType
            if orderType == .limit, let lim = Double(limitPrice) { order.limitPrice = lim }
            if orderType == .stop, let stop = Double(stopPrice) { order.stopPrice = stop }
            if orderType == .market {
                portfolioVM.addOrder(order)
                confirmationMessage = isBuying ? "Buy order placed!" : "Sell order placed!"
            } else {
                portfolioVM.addOpenOrder(order)
                confirmationMessage = isBuying ? "Limit/Stop buy order placed!" : "Limit/Stop sell order placed!"
            }
            showConfirmation = true
            showCheckmark = true
            amount = ""
            limitPrice = ""
            stopPrice = ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                showCheckmark = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showConfirmation = false
            }
        }
    }
}

struct TradeFormView_Previews: PreviewProvider {
    static var previews: some View {
        TradeFormView(asset: CryptoAsset(symbol: "BTCUSDT", name: "Bitcoin", price: 50000, lastUpdated: Date()))
            .environmentObject(PortfolioViewModel())
    }
}
