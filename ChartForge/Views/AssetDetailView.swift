import SwiftUI
import WebKit

#if os(iOS)
struct TradingViewWidgetView: UIViewRepresentable {
    let symbol: String
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        let html = """
        <html><head><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"></head><body style=\"margin:0;padding:0;\">
        <div id=\"tradingview_widget\"></div>
        <script type=\"text/javascript\" src=\"https://s3.tradingview.com/tv.js\"></script>
        <script type=\"text/javascript\">
        new TradingView.widget({
            \"width\": \"100%\",
            \"height\": 300,
            \"symbol\": \"\(symbol)\",
            \"interval\": \"1\",
            \"timezone\": \"Etc/UTC\",
            \"theme\": \"light\",
            \"style\": \"1\",
            \"locale\": \"en\",
            \"toolbar_bg\": \"#f1f3f6\",
            \"enable_publishing\": false,
            \"hide_top_toolbar\": true,
            \"hide_legend\": true,
            \"save_image\": false,
            \"container_id\": \"tradingview_widget\"
        });
        </script></body></html>
        """
        webView.loadHTMLString(html, baseURL: nil)
        return webView
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
#endif

struct AssetDetailView: View {
    @StateObject var viewModel: AssetDetailViewModel
    @State private var showTradeForm = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let asset = viewModel.asset {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 16) {
                            Image(systemName: "bitcoinsign.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.accentColor)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading) {
                                Text(asset.name)
                                    .font(.largeTitle.bold())
                                    .accessibilityLabel(asset.name)
                                Text(asset.symbol)
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                    .accessibilityLabel(asset.symbol)
                            }
                        }
                        .padding(.bottom, 8)
                        Text("$\(asset.price, specifier: "%.2f")")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .accessibilityLabel("Price: $\(asset.price, specifier: "%.2f")")
                        // 24h stats
                        HStack(spacing: 20) {
                            if let change = asset.change24h {
                                HStack(spacing: 4) {
                                    Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                                        .foregroundColor(change >= 0 ? .green : .red)
                                    Text("\(change >= 0 ? "+" : "")\(change, specifier: "%.2f")%")
                                        .foregroundColor(change >= 0 ? .green : .red)
                                        .font(.headline)
                                }
                            }
                            if let high = asset.high24h {
                                VStack(spacing: 2) {
                                    Text("High")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("$\(high, specifier: "%.2f")")
                                        .font(.subheadline)
                                }
                            }
                            if let low = asset.low24h {
                                VStack(spacing: 2) {
                                    Text("Low")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("$\(low, specifier: "%.2f")")
                                        .font(.subheadline)
                                }
                            }
                            if let vol = asset.volume24h {
                                VStack(spacing: 2) {
                                    Text("Volume")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("$\(vol, specifier: "%.0f")")
                                        .font(.subheadline)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        Divider()
                        // Order Book
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Order Book")
                                .font(.headline)
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Bids")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                    ForEach(viewModel.orderBook.filter { $0.isBid }.prefix(5)) { entry in
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
                                    ForEach(viewModel.orderBook.filter { !$0.isBid }.prefix(5)) { entry in
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
                        // Recent Trades
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recent Trades")
                                .font(.headline)
                            ForEach(viewModel.recentTrades) { trade in
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
                        Divider()
                        // News Feed
                        VStack(alignment: .leading, spacing: 8) {
                            Text("News Feed")
                                .font(.headline)
                            if viewModel.newsArticles.isEmpty {
                                Text("No news available.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(viewModel.newsArticles) { article in
                                    Button(action: {
                                        if let url = URL(string: article.url) {
                                            UIApplication.shared.open(url)
                                        }
                                    }) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(article.title)
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                                .lineLimit(2)
                                            HStack(spacing: 8) {
                                                Text(article.source)
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                Text(article.publishedAt, style: .relative)
                                                    .font(.caption2)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        Divider()
                        #if os(iOS)
                        TradingViewWidgetView(symbol: tradingViewSymbol(for: asset.symbol))
                            .frame(height: 300)
                            .cornerRadius(16)
                            .padding(.vertical)
                        #else
                        Text("TradingView chart is only available on iOS.")
                            .frame(height: 300)
                            .foregroundColor(.gray)
                        #endif
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            showTradeForm = true
                        }) {
                            Label("Trade", systemImage: "arrow.left.arrow.right")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor.opacity(0.15))
                                .foregroundColor(.accentColor)
                                .cornerRadius(12)
                        }
                        .accessibilityLabel("Trade \(asset.symbol)")
                        .padding(.top)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemBackground)).shadow(radius: 2))
                    .padding(.horizontal)
                } else {
                    Text("No asset selected.")
                        .foregroundColor(.secondary)
                        .padding()
                }
                Spacer(minLength: 40)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Asset Detail")
        .sheet(isPresented: $showTradeForm) {
            if let asset = viewModel.asset {
                TradeFormView(asset: asset)
            } else {
                TradeFormView()
            }
        }
    }
    
    private func tradingViewSymbol(for symbol: String) -> String {
        // Map Binance symbol to TradingView format, e.g., BTCUSDT -> BINANCE:BTCUSDT
        return "BINANCE:\(symbol)"
    }
}

struct AssetDetailView_Previews: PreviewProvider {
    static var previews: some View {
        AssetDetailView(viewModel: AssetDetailViewModel(asset: CryptoAsset(symbol: "BTCUSDT", name: "Bitcoin", price: 50000, lastUpdated: Date())))
    }
}
